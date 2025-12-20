import { NextApiRequest, NextApiResponse } from 'next';

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

// Add timeout wrapper for fetch
async function fetchWithTimeout(url: string, options: RequestInit, timeout = 30000) {
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), timeout);
  
  try {
    const response = await fetch(url, {
      ...options,
      signal: controller.signal,
    });
    clearTimeout(timeoutId);
    return response;
  } catch (error) {
    clearTimeout(timeoutId);
    throw error;
  }
}

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const { email } = req.body;

    if (!email) {
      return res.status(400).json({ error: 'Email is required' });
    }

    // Validate API_BASE_URL is set
    if (!process.env.NEXT_PUBLIC_API_URL) {
      console.error('[send-code] NEXT_PUBLIC_API_URL environment variable is not set');
      return res.status(500).json({ 
        error: 'Server configuration error: API URL not configured',
        details: 'Please check environment variables',
      });
    }

    const url = `${API_BASE_URL}/users/send-code`;
    console.log(`[send-code] Attempting to fetch from: ${url}`);
    console.log(`[send-code] Request body:`, { email });
    console.log(`[send-code] Environment: ${process.env.NODE_ENV}`);
    
    const response = await fetchWithTimeout(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ email }),
    }, 30000); // 30 second timeout

    console.log(`[send-code] Response status: ${response.status}`);
    console.log(`[send-code] Response ok: ${response.ok}`);

    if (response.ok) {
      const data = await response.json().catch(() => ({ message: 'OTP sent' }));
      return res.status(200).json({ success: true, message: data.message || 'OTP sent successfully' });
    } else {
      let errorData;
      try {
        errorData = await response.json();
        console.error(`[send-code] Error response:`, errorData);
      } catch (e) {
        const text = await response.text();
        console.error(`[send-code] Non-JSON error response:`, text);
        errorData = { detail: `Backend returned ${response.status}: ${text.substring(0, 200)}` };
      }
      return res.status(response.status).json({ 
        error: errorData.detail || errorData.message || 'Failed to send code',
        status: response.status,
      });
    }
  } catch (error) {
    console.error('[send-code] Request error:', error);
    const errorMessage = error instanceof Error ? error.message : 'Unknown error';
    const errorName = error instanceof Error ? error.name : 'Unknown';
    
    // Check for specific error types
    if (errorName === 'AbortError' || errorMessage.includes('timeout')) {
      console.error('[send-code] Request timeout - backend may be unreachable');
      return res.status(504).json({ 
        error: 'Request timeout - backend server may be unreachable',
        details: 'The request took too long. Please check if the backend is accessible.',
      });
    }
    
    if (errorMessage.includes('ECONNREFUSED') || errorMessage.includes('ENOTFOUND')) {
      console.error('[send-code] Connection refused - backend may be down or unreachable');
      return res.status(503).json({ 
        error: 'Cannot connect to backend server',
        details: 'The backend server may be down or unreachable from this location.',
      });
    }
    
    console.error('[send-code] Error details:', {
      name: errorName,
      message: errorMessage,
      apiBaseUrl: API_BASE_URL,
      hasApiUrl: !!process.env.NEXT_PUBLIC_API_URL,
    });
    
    return res.status(500).json({ 
      error: 'Failed to send verification code',
      details: process.env.NODE_ENV === 'development' ? errorMessage : 'Please try again later or contact support',
    });
  }
}
