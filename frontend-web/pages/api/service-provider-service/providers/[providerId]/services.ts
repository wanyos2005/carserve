import { NextApiRequest, NextApiResponse } from 'next';

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  const { providerId } = req.query;

  if (req.method === 'GET') {
    try {
      const response = await fetch(`${API_BASE_URL}/service-provider-service/providers/${providerId}/services`, {
        headers: {
          'Content-Type': 'application/json',
        },
      });

      if (response.ok) {
        const data = await response.json();
        return res.status(200).json(data);
      } else {
        return res.status(response.status).json({ error: 'Failed to fetch provider services' });
      }
    } catch (error) {
      console.error('Error fetching provider services:', error);
      return res.status(500).json({ error: 'Internal server error' });
    }
  }

  if (req.method === 'POST') {
    try {
      const response = await fetch(`${API_BASE_URL}/service-provider-service/providers/${providerId}/services`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(req.body),
      });

      if (response.ok) {
        const data = await response.json();
        return res.status(200).json(data);
      } else {
        const errorData = await response.json();
        return res.status(response.status).json({ error: errorData.detail || 'Failed to save services' });
      }
    } catch (error) {
      console.error('Error saving services:', error);
      return res.status(500).json({ error: 'Internal server error' });
    }
  }

  return res.status(405).json({ error: 'Method not allowed' });
}
