import { NextApiRequest, NextApiResponse } from 'next';

// Service logs are from booking service
const BOOKING_SERVICE_URL = process.env.BOOKING_SERVICE_URL || process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8004';

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  const { userId } = req.query;

  if (req.method !== 'GET') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  if (!userId || typeof userId !== 'string') {
    return res.status(400).json({ error: 'User ID is required' });
  }

  try {
    const response = await fetch(`${BOOKING_SERVICE_URL}/service-logs/user/${userId}`, {
      headers: {
        'Content-Type': 'application/json',
      },
    });

    if (response.ok) {
      const data = await response.json();
      return res.status(200).json(data);
    } else {
      // Return empty array if not found rather than error
      if (response.status === 404) {
        return res.status(200).json([]);
      }
      return res.status(response.status).json({ error: 'Failed to fetch service logs' });
    }
  } catch (error) {
    console.error('Error fetching user service logs:', error);
    // Return empty array on error to prevent frontend from breaking
    return res.status(200).json([]);
  }
}

