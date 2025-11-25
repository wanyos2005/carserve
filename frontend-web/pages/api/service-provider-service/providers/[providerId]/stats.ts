import { NextApiRequest, NextApiResponse } from 'next';

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  console.log('🚀 [Stats API] Handler called!');
  console.log('🚀 [Stats API] Method:', req.method);
  console.log('🚀 [Stats API] Query:', req.query);
  console.log('🚀 [Stats API] URL:', req.url);
  
  const { providerId } = req.query;
  console.log('🚀 [Stats API] Extracted providerId:', providerId);

  if (req.method !== 'GET') {
    console.log('❌ [Stats API] Method not allowed:', req.method);
    return res.status(405).json({ error: 'Method not allowed' });
  }

  if (!providerId || typeof providerId !== 'string') {
    console.log('❌ [Stats API] Invalid providerId:', providerId);
    return res.status(400).json({ error: 'Provider ID is required' });
  }

  try {
    console.log(`📊 [Stats API] Fetching stats for provider: ${providerId}`);
    // Use /service-providers/ as per nginx config
    // Backend route is /{provider_id}/stats (no /providers/ prefix)
    // Nginx strips /service-providers/ and forwards to backend
    const backendUrl = `${API_BASE_URL}/service-providers/${providerId}/stats`;
    console.log(`📊 [Stats API] API URL: ${backendUrl}`);
    
    const response = await fetch(backendUrl, {
      headers: {
        'Content-Type': 'application/json',
      },
    });

    console.log(`📊 [Stats API] Response status: ${response.status}`);

    if (response.ok) {
      const data = await response.json();
      console.log(`📊 [Stats API] Stats data received:`, JSON.stringify(data, null, 2));
      console.log(`📊 [Stats API] Provider type: ${data.provider_type}`);
      console.log(`📊 [Stats API] Stats keys:`, Object.keys(data));
      return res.status(200).json(data);
    } else {
      // Return empty object if not found rather than error
      if (response.status === 404) {
        console.log(`⚠️ [Stats API] Provider ${providerId} not found (404)`);
        return res.status(200).json({});
      }
      const errorText = await response.text();
      console.error(`❌ [Stats API] Failed to fetch provider stats: ${response.status} - ${errorText}`);
      return res.status(response.status).json({ error: 'Failed to fetch provider stats' });
    }
  } catch (error) {
    console.error('❌ [Stats API] Error fetching provider stats:', error);
    // Return empty object on error to prevent dashboard from breaking
    return res.status(200).json({});
  }
}

