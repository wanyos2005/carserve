import { NextApiRequest, NextApiResponse } from 'next';

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const { email } = req.body;

    if (!email) {
      return res.status(400).json({ error: 'Email is required' });
    }

    console.log(`[send-code] Attempting to fetch from: ${API_BASE_URL}/users/send-code`);
    console.log(`[send-code] Request body:`, { email });
    
    const response = await fetch(`${API_BASE_URL}/users/send-code`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ email }),
    });

    console.log(`[send-code] Response status: ${response.status}`);
    console.log(`[send-code] Response ok: ${response.ok}`);

    if (response.ok) {
      return res.status(200).json({ success: true });
    } else {
      let errorData;
      try {
        errorData = await response.json();
        console.error(`[send-code] Error response:`, errorData);
      } catch (e) {
        const text = await response.text();
        console.error(`[send-code] Non-JSON error response:`, text);
        errorData = { detail: `Backend returned ${response.status}: ${text}` };
      }
      return res.status(response.status).json({ error: errorData.detail || errorData.message || 'Failed to send code' });
    }
  } catch (error) {
    console.error('Send code error:', error);
    const errorMessage = error instanceof Error ? error.message : 'Unknown error';
    const errorStack = error instanceof Error ? error.stack : undefined;
    console.error('Error details:', {
      message: errorMessage,
      stack: errorStack,
      apiBaseUrl: API_BASE_URL,
    });
    return res.status(500).json({ 
      error: 'Internal server error',
      details: process.env.NODE_ENV === 'development' ? errorMessage : undefined,
    });
  }
}
