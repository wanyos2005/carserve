import { NextApiRequest, NextApiResponse } from 'next';

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  const { providerId } = req.query;

  if (req.method === 'GET') {
    try {
      // Use /service-providers/ as per nginx config
      // Backend route is /{provider_id}/services (no /providers/ prefix)
      // Nginx strips /service-providers/ and forwards to backend
      const backendUrl = `${API_BASE_URL}/service-providers/${providerId}/services`;
      console.log(`⚙️ [Services API] Fetching services: ${backendUrl}`);
      const response = await fetch(backendUrl, {
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
      // Use /service-providers/ as per nginx config (same as GET)
      const backendUrl = `${API_BASE_URL}/service-providers/${providerId}/services`;
      console.log(`⚙️ [Services API] Saving services: ${backendUrl}`);
      const response = await fetch(backendUrl, {
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
        const errorData = await response.json().catch(() => ({ detail: 'Failed to save services' }));
        console.error(`❌ [Services API] Failed to save services: ${response.status}`, errorData);
        return res.status(response.status).json({ error: errorData.detail || 'Failed to save services' });
      }
    } catch (error) {
      console.error('Error saving services:', error);
      return res.status(500).json({ error: 'Internal server error' });
    }
  }

  return res.status(405).json({ error: 'Method not allowed' });
}
