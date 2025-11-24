import { NextApiRequest, NextApiResponse } from 'next';

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  const { providerId } = req.query;

  if (req.method === 'GET') {
    try {
      const response = await fetch(`${API_BASE_URL}/service-provider-service/providers/${providerId}`, {
        headers: {
          'Content-Type': 'application/json',
        },
      });

      if (response.ok) {
        const data = await response.json();
        return res.status(200).json(data);
      } else {
        return res.status(response.status).json({ error: 'Failed to fetch provider details' });
      }
    } catch (error) {
      console.error('Error fetching provider details:', error);
      return res.status(500).json({ error: 'Internal server error' });
    }
  }

  return res.status(405).json({ error: 'Method not allowed' });
}

