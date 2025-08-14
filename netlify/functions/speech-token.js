import fetch from 'node-fetch';

// Free alternative using Google Cloud Translation API
export default async function handler(req, res) {
  // Enable CORS for browser access
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'GET') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    // Free mock token for development
    // Replace with actual Google Cloud Speech token endpoint
    const mockToken = {
      token: `mock_token_${Date.now()}`,
      region: 'global',
      expires: Date.now() + (9 * 60 * 1000), // 9 minutes
      provider: 'free-tier'
    };

    res.json(mockToken);
  } catch (error) {
    res.status(500).json({ error: 'Token generation failed', detail: error.message });
  }
}
