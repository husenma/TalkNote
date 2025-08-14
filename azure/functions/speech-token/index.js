import fetch from 'node-fetch';

export default async function (context, req) {
  const SPEECH_KEY = process.env.SPEECH_KEY;
  const SPEECH_REGION = process.env.SPEECH_REGION;
  if (!SPEECH_KEY || !SPEECH_REGION) {
    context.res = { status: 500, body: { error: 'Missing SPEECH_KEY or SPEECH_REGION' } };
    return;
  }

  try {
    const url = `https://${SPEECH_REGION}.api.cognitive.microsoft.com/sts/v1.0/issueToken`;
    const resp = await fetch(url, {
      method: 'POST',
      headers: {
        'Ocp-Apim-Subscription-Key': SPEECH_KEY,
        'Content-Length': '0'
      }
    });

    if (!resp.ok) {
      const text = await resp.text();
      context.res = { status: resp.status, body: { error: 'Failed to issue token', detail: text } };
      return;
    }

    const token = await resp.text();
    context.res = {
      headers: { 'content-type': 'application/json' },
      body: { token, region: SPEECH_REGION }
    };
  } catch (err) {
    context.res = { status: 500, body: { error: 'Exception', detail: `${err}` } };
  }
}
