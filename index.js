const http = require('http');

const PORT = Number(process.env.PORT || 3000);
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
      if (raw.length > 1_000_000) {
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

async function handleHome(req, res) {
  await readBody(req);
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

  messages.push({ role: 'user', content: userMessage });

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

server.listen(PORT, () => {
  console.log(`Facey API server is running on http://localhost:${PORT}`);
});
