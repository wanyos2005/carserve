import { NextApiRequest, NextApiResponse } from 'next';

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  if (req.method === 'GET') {
    try {
      // Use /service-providers/ as per nginx config
      // Backend route is /service-providers/services-with-categories (or /services)
      const backendUrl = `${API_BASE_URL}/service-providers/services-with-categories`;
      console.log(`📋 [Global Service API] Fetching all services: ${backendUrl}`);
      const response = await fetch(backendUrl, {
        headers: {
          'Content-Type': 'application/json',
        },
      });

      if (response.ok) {
        const data = await response.json();
        return res.status(200).json(data);
      } else {
        return res.status(response.status).json({ error: 'Failed to fetch global services' });
      }
    } catch (error) {
      console.error('Error fetching global services:', error);
      return res.status(500).json({ error: 'Internal server error' });
    }
  }

  return res.status(405).json({ error: 'Method not allowed' });
}
