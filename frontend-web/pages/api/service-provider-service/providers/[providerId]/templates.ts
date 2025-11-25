import { NextApiRequest, NextApiResponse } from 'next';

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  const { providerId } = req.query;

  if (req.method === 'GET') {
    try {
      // Use /service-providers/ as per nginx config (same as POST)
      const backendUrl = `${API_BASE_URL}/service-providers/${providerId}/templates`;
      console.log(`📄 [Templates API] Fetching templates: ${backendUrl}`);
      const response = await fetch(backendUrl, {
        headers: {
          'Content-Type': 'application/json',
        },
      });

      if (response.ok) {
        const data = await response.json();
        return res.status(200).json(data);
      } else {
        const errorText = await response.text();
        console.error(`❌ [Templates API] Failed to fetch templates: ${response.status} - ${errorText}`);
        return res.status(response.status).json({ error: 'Failed to fetch templates' });
      }
    } catch (error) {
      console.error('Error fetching templates:', error);
      return res.status(500).json({ error: 'Internal server error' });
    }
  }

  if (req.method === 'POST') {
    try {
      // Use /service-providers/ as per nginx config
      const backendUrl = `${API_BASE_URL}/service-providers/${providerId}/templates`;
      console.log(`📄 [Templates API] Creating template: ${backendUrl}`);
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
        const errorData = await response.json();
        return res.status(response.status).json({ error: errorData.detail || 'Failed to create template' });
      }
    } catch (error) {
      console.error('Error creating template:', error);
      return res.status(500).json({ error: 'Internal server error' });
    }
  }

  return res.status(405).json({ error: 'Method not allowed' });
}
