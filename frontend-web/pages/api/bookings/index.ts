import { NextApiRequest, NextApiResponse } from 'next';

// Bookings are from booking service
const BOOKING_SERVICE_URL = process.env.BOOKING_SERVICE_URL || process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8004';

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  if (req.method === 'POST') {
    try {
      const bookingData = req.body;

      const response = await fetch(`${BOOKING_SERVICE_URL}/bookings/`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(bookingData),
      });

      if (response.ok) {
        const data = await response.json();
        return res.status(200).json(data);
      } else {
        const errorText = await response.text().catch(() => 'Failed to create booking');
        return res.status(response.status).json({ error: errorText });
      }
    } catch (error) {
      console.error('Error creating booking:', error);
      return res.status(500).json({ error: 'Internal server error' });
    }
  }

  return res.status(405).json({ error: 'Method not allowed' });
}

