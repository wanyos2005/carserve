import { NextApiRequest, NextApiResponse } from 'next';

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  if (req.method !== 'GET') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const { vehicleId } = req.query;

  if (!vehicleId || typeof vehicleId !== 'string') {
    return res.status(400).json({ error: 'Vehicle ID is required' });
  }

  try {
    console.log(`🚗 [Vehicle Public API] Fetching vehicle: ${vehicleId}`);
    console.log(`🚗 [Vehicle Public API] API URL: ${API_BASE_URL}/vehicles/public/${vehicleId}`);
    
    const token = req.headers.authorization?.replace('Bearer ', '') || null;

    const response = await fetch(`${API_BASE_URL}/vehicles/public/${vehicleId}`, {
      headers: {
        'Content-Type': 'application/json',
        ...(token ? { 'Authorization': `Bearer ${token}` } : {}),
      },
    });

    console.log(`🚗 [Vehicle Public API] Response status: ${response.status}`);

    if (response.ok) {
      const data = await response.json();
      console.log(`🚗 [Vehicle Public API] Vehicle data received:`, JSON.stringify(data, null, 2));
      return res.status(200).json(data);
    } else {
      const errorText = await response.text();
      console.error(`❌ [Vehicle Public API] Failed to fetch vehicle: ${response.status} - ${errorText}`);
      if (response.status === 404) {
        return res.status(404).json({ error: 'Vehicle not found' });
      }
      return res.status(response.status).json({ error: 'Failed to fetch vehicle' });
    }
  } catch (error) {
    console.error('❌ [Vehicle Public API] Error fetching vehicle:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
}

