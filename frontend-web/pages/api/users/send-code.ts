import { NextApiRequest, NextApiResponse } from 'next';

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const { email } = req.body;

    if (!email) {
      return res.status(400).json({ error: 'Email is required' });
    }

    const response = await fetch(`${API_BASE_URL}/users/send-code`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ email }),
    });

    if (response.ok) {
      return res.status(200).json({ success: true });
    } else {
      const errorData = await response.json();
      return res.status(response.status).json({ error: errorData.detail || 'Failed to send code' });
    }
  } catch (error) {
    console.error('Send code error:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
}
