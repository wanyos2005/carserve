import { NextApiRequest, NextApiResponse } from 'next';

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  if (req.method === 'GET') {
    try {
      // Get query parameters for filtering
      const { service_ids, match_all, ...otherParams } = req.query;
      
      // Build query string
      const queryParams = new URLSearchParams();
      if (service_ids) {
        const ids = Array.isArray(service_ids) ? service_ids : [service_ids];
        ids.forEach(id => queryParams.append('service_ids', id as string));
      }
      if (match_all) {
        queryParams.append('match_all', match_all as string);
      }
      // Add any other query parameters
      Object.entries(otherParams).forEach(([key, value]) => {
        if (value) {
          queryParams.append(key, value as string);
        }
      });
      
      const queryString = queryParams.toString();
      // Match Flutter implementation: /service-providers/providers/?queryString
      const backendUrl = `${API_BASE_URL}/service-providers/providers/${queryString ? `?${queryString}` : ''}`;
      
      console.log(`📋 [Providers API] Fetching providers: ${backendUrl}`);
      console.log(`📋 [Providers API] Query params:`, { service_ids, match_all, otherParams });
      
      // Get auth token from request headers (forward from client)
      const authHeader = req.headers.authorization;
      const token = authHeader?.replace('Bearer ', '');
      
      const headers: HeadersInit = {
        'Content-Type': 'application/json',
      };
      
      if (token) {
        headers['Authorization'] = `Bearer ${token}`;
      }
      
      const response = await fetch(backendUrl, {
        headers,
      });

      console.log(`📋 [Providers API] Response status: ${response.status}`);

      if (response.ok) {
        const data = await response.json();
        console.log(`📋 [Providers API] Successfully fetched ${Array.isArray(data) ? data.length : 0} providers`);
        return res.status(200).json(data);
      } else {
        const errorText = await response.text().catch(() => 'Unknown error');
        console.error(`📋 [Providers API] Error ${response.status}: ${errorText}`);
        console.error(`📋 [Providers API] Failed URL: ${backendUrl}`);
        return res.status(response.status).json({ error: errorText || 'Failed to fetch providers' });
      }
    } catch (error) {
      console.error('📋 [Providers API] Exception:', error);
      return res.status(500).json({ error: 'Internal server error' });
    }
  }

  if (req.method === 'POST') {
    try {
      const { name } = req.body;

      if (!name || typeof name !== 'string') {
        return res.status(400).json({ error: 'Provider name is required' });
      }

      const backendUrl = `${API_BASE_URL}/service-providers/providers/`;
      
      console.log(`📋 [Providers API] Creating provider: ${backendUrl}`, { name });
      
      const response = await fetch(backendUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ name: name.trim() }),
      });

      if (response.ok) {
        const data = await response.json();
        return res.status(200).json(data);
      } else {
        const errorText = await response.text().catch(() => 'Failed to create provider');
        return res.status(response.status).json({ error: errorText });
      }
    } catch (error) {
      console.error('Error creating provider:', error);
      return res.status(500).json({ error: 'Internal server error' });
    }
  }

  return res.status(405).json({ error: 'Method not allowed' });
}

