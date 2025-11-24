import { NextApiRequest, NextApiResponse } from 'next';

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  if (req.method !== 'GET') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const { plate } = req.query;

  if (!plate || typeof plate !== 'string') {
    return res.status(400).json({ error: 'Plate parameter is required' });
  }

  try {
    const response = await fetch(`${API_BASE_URL}/vehicles/search?plate=${encodeURIComponent(plate)}`, {
      headers: {
        'Content-Type': 'application/json',
      },
    });

    if (response.ok) {
      const data = await response.json();
      return res.status(200).json(data);
    } else {
      return res.status(response.status).json({ error: 'Failed to search vehicles' });
    }
  } catch (error) {
    console.error('Error searching vehicles:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
}

