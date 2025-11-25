import { NextApiRequest, NextApiResponse } from 'next';

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const userIds = req.body;
    
    if (!Array.isArray(userIds) || userIds.length === 0) {
      return res.status(400).json({ error: 'User IDs array is required' });
    }

    console.log('👤 [User Lookup API] Looking up users for IDs:', userIds);

    const token = req.headers.authorization?.replace('Bearer ', '') || null;

    const response = await fetch(`${API_BASE_URL}/users/lookup`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        ...(token ? { 'Authorization': `Bearer ${token}` } : {}),
      },
      body: JSON.stringify(userIds),
    });

    console.log(`👤 [User Lookup API] Response status: ${response.status}`);

    if (response.ok) {
      const data = await response.json();
      console.log(`👤 [User Lookup API] Received ${Array.isArray(data) ? data.length : 0} users`);
      return res.status(200).json(data);
    } else {
      const errorText = await response.text();
      console.error(`❌ [User Lookup API] Failed to lookup users: ${response.status} - ${errorText}`);
      return res.status(response.status).json({ error: 'Failed to lookup users' });
    }
  } catch (error) {
    console.error('❌ [User Lookup API] Error looking up users:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
}

