const http = require('http');

const PORT = Number(process.env.PORT || 3000);
const HOST = process.env.HOST || '0.0.0.0';
const OPENAI_API_KEY = process.env.OPENAI_API_KEY || '';
const OPENAI_MODEL = process.env.OPENAI_MODEL || 'gpt-4.1';

function sendJson(res, statusCode, payload) {
  res.writeHead(statusCode, {
    'Content-Type': 'application/json; charset=utf-8',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET,POST,OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type,Authorization',
  });
  res.end(JSON.stringify(payload));
}

function normalizeText(content) {
  if (typeof content === 'string') return content.trim();
  if (Array.isArray(content)) {
    return content
      .map((part) => (typeof part?.text === 'string' ? part.text : ''))
      .join('\n')
      .trim();
  }
  return '';
}

async function readBody(req) {
  return new Promise((resolve, reject) => {
    let raw = '';
    req.on('data', (chunk) => {
      raw += chunk;
      if (raw.length > 30_000_000) {
        reject(new Error('Request body too large'));
      }
    });
    req.on('end', () => {
      if (!raw) {
        resolve({});
        return;
      }
      try {
        resolve(JSON.parse(raw));
      } catch {
        reject(new Error('Invalid JSON body'));
      }
    });
    req.on('error', reject);
  });
}

function parseJsonObject(text) {
  let parsed;
  try {
    parsed = JSON.parse(text);
  } catch {
    throw new Error('OpenAI did not return valid JSON');
  }
  if (!parsed || typeof parsed !== 'object' || Array.isArray(parsed)) {
    throw new Error('OpenAI JSON is not an object');
  }
  return parsed;
}

function clampScore(value, fallback = 50) {
  const n = Number.isFinite(value) ? Math.round(value) : fallback;
  return Math.max(0, Math.min(100, n));
}

function sanitizeMetric(metric, fallbackLabel) {
  const label =
    typeof metric?.label === 'string' && metric.label.trim()
      ? metric.label.trim()
      : fallbackLabel;
  const value = clampScore(Number(metric?.value), 50);
  return { label, value };
}

function sanitizeAnalysis(raw) {
  const metricLabels = ['ポテンシャル', '性的魅力', '印象', '清潔感', '骨格', '肌'];
  const detailLabels = [
    '男性らしさ',
    '自信',
    '親しみやすさ',
    '髪の毛',
    'シャープさ',
    '目力',
    '顎ライン',
    '眉',
  ];
  const rawMetrics = Array.isArray(raw?.metrics) ? raw.metrics : [];
  const rawDetailMetrics = Array.isArray(raw?.detailMetrics)
    ? raw.detailMetrics
    : [];

  const metrics = metricLabels.map((label, index) =>
    sanitizeMetric(rawMetrics[index], label),
  );
  const detailMetrics = detailLabels.map((label, index) =>
    sanitizeMetric(rawDetailMetrics[index], label),
  );
  const overall = clampScore(Number(raw?.overall), 50);

  const strengthsSummary =
    typeof raw?.strengthsSummary === 'string'
      ? raw.strengthsSummary.trim()
      : '';
  const improvementsSummary =
    typeof raw?.improvementsSummary === 'string'
      ? raw.improvementsSummary.trim()
      : '';
  const nextAction =
    typeof raw?.nextAction === 'string' ? raw.nextAction.trim() : '';

  return {
    overall,
    metrics,
    detailMetrics,
    strengthsSummary:
      strengthsSummary ||
      '目元にやわらかい印象があり、親しみやすさがしっかり出ています。顔全体のバランスが良く、清潔感につながっています。',
    improvementsSummary:
      improvementsSummary ||
      '肌の質感と眉の輪郭を少し整えると、全体印象がさらに安定します。髪のボリューム位置を調整すると輪郭もより綺麗に見えます。',
    nextAction:
      nextAction ||
      '1週間は保湿・眉・前髪の3点を固定して比較撮影し、変化を確認してください。',
  };
}

async function completeWithGpt(messages) {
  if (!OPENAI_API_KEY) {
    throw new Error('OPENAI_API_KEY is not configured');
  }

  const response = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${OPENAI_API_KEY}`,
    },
    body: JSON.stringify({
      model: OPENAI_MODEL,
      temperature: 0.7,
      messages,
    }),
  });

  const data = await response.json();

  if (!response.ok) {
    const apiMessage = data?.error?.message || 'OpenAI API request failed';
    throw new Error(apiMessage);
  }

  const text = normalizeText(data?.choices?.[0]?.message?.content);
  if (!text) {
    throw new Error('OpenAI response did not include text');
  }

  return text;
}

async function analyzeHomeFaceWithGpt({
  frontImageBase64,
  sideImageBase64 = '',
  gender = '',
}) {
  if (!OPENAI_API_KEY) {
    throw new Error('OPENAI_API_KEY is not configured');
  }

  const frontImageDataUrl = `data:image/jpeg;base64,${frontImageBase64}`;
  const userContent = [
    {
      type: 'text',
      text:
        `顔画像を分析し、0-100の整数スコアで評価してください。` +
        `性別情報: ${gender || 'unknown'}。` +
        `各サマリーは日本語で2-3文、具体的で実行可能な内容にしてください。`,
    },
    { type: 'image_url', image_url: { url: frontImageDataUrl } },
  ];

  if (sideImageBase64) {
    userContent.push({
      type: 'image_url',
      image_url: { url: `data:image/jpeg;base64,${sideImageBase64}` },
    });
  }

  const response = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${OPENAI_API_KEY}`,
    },
    body: JSON.stringify({
      model: OPENAI_MODEL,
      temperature: 0.2,
      messages: [
        {
          role: 'system',
          content:
            'You are Facey Home analysis engine. Evaluate appearance from uploaded face photos and return strict JSON only.',
        },
        {
          role: 'user',
          content: userContent,
        },
      ],
      response_format: {
        type: 'json_schema',
        json_schema: {
          name: 'face_home_analysis',
          strict: true,
          schema: {
            type: 'object',
            additionalProperties: false,
            required: [
              'overall',
              'metrics',
              'detailMetrics',
              'strengthsSummary',
              'improvementsSummary',
              'nextAction',
            ],
            properties: {
              overall: { type: 'integer', minimum: 0, maximum: 100 },
              metrics: {
                type: 'array',
                minItems: 6,
                maxItems: 6,
                items: {
                  type: 'object',
                  additionalProperties: false,
                  required: ['label', 'value'],
                  properties: {
                    label: { type: 'string' },
                    value: { type: 'integer', minimum: 0, maximum: 100 },
                  },
                },
              },
              detailMetrics: {
                type: 'array',
                minItems: 8,
                maxItems: 8,
                items: {
                  type: 'object',
                  additionalProperties: false,
                  required: ['label', 'value'],
                  properties: {
                    label: { type: 'string' },
                    value: { type: 'integer', minimum: 0, maximum: 100 },
                  },
                },
              },
              strengthsSummary: { type: 'string' },
              improvementsSummary: { type: 'string' },
              nextAction: { type: 'string' },
            },
          },
        },
      },
    }),
  });

  const data = await response.json();
  if (!response.ok) {
    const apiMessage = data?.error?.message || 'OpenAI API request failed';
    throw new Error(apiMessage);
  }

  const text = normalizeText(data?.choices?.[0]?.message?.content);
  if (!text) {
    throw new Error('OpenAI response did not include analysis JSON');
  }

  return sanitizeAnalysis(parseJsonObject(text));
}

async function handleHome(req, res) {
  const body = await readBody(req);
  const frontImageBase64 =
    typeof body?.frontImageBase64 === 'string'
      ? body.frontImageBase64.trim()
      : '';
  const sideImageBase64 =
    typeof body?.sideImageBase64 === 'string' ? body.sideImageBase64.trim() : '';
  const gender = typeof body?.gender === 'string' ? body.gender.trim() : '';

  if (frontImageBase64) {
    const analysis = await analyzeHomeFaceWithGpt({
      frontImageBase64,
      sideImageBase64,
      gender,
    });
    sendJson(res, 200, { ok: true, analysis });
    return;
  }

  const text = await completeWithGpt([
    {
      role: 'system',
      content:
        'You are a concise beauty and self-improvement assistant for Facey app users. Reply in Japanese with 1 short paragraph.',
    },
    {
      role: 'user',
      content: 'Home画面の初期表示用に、今日の行動ヒントを1つください。',
    },
  ]);

  sendJson(res, 200, { ok: true, message: text });
}

async function handleCondition(req, res) {
  await readBody(req);
  const text = await completeWithGpt([
    {
      role: 'system',
      content:
        'You are a concise skin and condition coach for Facey app users. Reply in Japanese with 1 short paragraph.',
    },
    {
      role: 'user',
      content: 'Condition画面の初期表示用に、体調管理のアドバイスを1つください。',
    },
  ]);

  sendJson(res, 200, { ok: true, message: text });
}

async function handleChat(req, res) {
  const body = await readBody(req);
  const userMessage = String(body?.message || '').trim();
  const history = Array.isArray(body?.history) ? body.history : [];
  const imagesBase64 = Array.isArray(body?.imagesBase64)
    ? body.imagesBase64
        .filter((item) => typeof item === 'string')
        .map((item) => item.trim())
        .filter(Boolean)
        .slice(0, 5)
    : [];

  if (!userMessage) {
    sendJson(res, 400, { ok: false, error: 'message is required' });
    return;
  }

  const messages = [
    {
      role: 'system',
      content:
        'You are Facey Chat, a practical appearance and self-improvement coach. Reply in natural Japanese. Keep advice concrete and actionable.',
    },
  ];

  for (const item of history) {
    const role = item?.role === 'assistant' ? 'assistant' : 'user';
    const text = String(item?.text || '').trim();
    if (!text) continue;
    messages.push({ role, content: text });
  }

  if (imagesBase64.length > 0) {
    const userContent = [{ type: 'text', text: userMessage }];
    for (const imageBase64 of imagesBase64) {
      userContent.push({
        type: 'image_url',
        image_url: { url: `data:image/jpeg;base64,${imageBase64}` },
      });
    }
    messages.push({ role: 'user', content: userContent });
  } else {
    messages.push({ role: 'user', content: userMessage });
  }

  const reply = await completeWithGpt(messages);
  sendJson(res, 200, { ok: true, reply });
}

const server = http.createServer(async (req, res) => {
  try {
    if (!req.url || !req.method) {
      sendJson(res, 400, { ok: false, error: 'Bad request' });
      return;
    }

    if (req.method === 'OPTIONS') {
      res.writeHead(204, {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET,POST,OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type,Authorization',
      });
      res.end();
      return;
    }

    if (req.method === 'GET' && req.url === '/api/health') {
      sendJson(res, 200, {
        ok: true,
        ready: OPENAI_API_KEY.length > 0,
        model: OPENAI_MODEL,
      });
      return;
    }

    if (req.method === 'POST' && req.url === '/api/home') {
      await handleHome(req, res);
      return;
    }

    if (req.method === 'POST' && req.url === '/api/condition') {
      await handleCondition(req, res);
      return;
    }

    if (req.method === 'POST' && req.url === '/api/chat') {
      await handleChat(req, res);
      return;
    }

    sendJson(res, 404, { ok: false, error: 'Not found' });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error';
    sendJson(res, 500, { ok: false, error: message });
  }
});

server.listen(PORT, HOST, () => {
  console.log(`Facey API server is running on http://${HOST}:${PORT}`);
});
