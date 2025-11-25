import { NextApiRequest, NextApiResponse } from 'next';

// Bookings are from booking service
const BOOKING_SERVICE_URL = process.env.BOOKING_SERVICE_URL || process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8004';

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  const { bookingId } = req.query;

  if (!bookingId || typeof bookingId !== 'string') {
    return res.status(400).json({ error: 'Booking ID is required' });
  }

  if (req.method === 'GET') {
    try {
      const response = await fetch(`${BOOKING_SERVICE_URL}/bookings/${bookingId}`, {
        headers: {
          'Content-Type': 'application/json',
        },
      });

      if (response.ok) {
        const data = await response.json();
        return res.status(200).json(data);
      } else {
        return res.status(response.status).json({ error: 'Failed to fetch booking' });
      }
    } catch (error) {
      console.error('Error fetching booking:', error);
      return res.status(500).json({ error: 'Internal server error' });
    }
  }

  if (req.method === 'PUT' || req.method === 'PATCH') {
    try {
      console.log(`🔄 [Booking API] Updating booking ${bookingId}:`, req.body);
      const response = await fetch(`${BOOKING_SERVICE_URL}/bookings/${bookingId}`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(req.body),
      });

      if (response.ok) {
        const data = await response.json();
        console.log(`✅ [Booking API] Booking ${bookingId} updated successfully`);
        return res.status(200).json(data);
      } else {
        const errorData = await response.json().catch(() => ({ detail: 'Failed to update booking' }));
        console.error(`❌ [Booking API] Failed to update booking ${bookingId}:`, response.status, errorData);
        return res.status(response.status).json({ error: errorData.detail || 'Failed to update booking' });
      }
    } catch (error) {
      console.error('Error updating booking:', error);
      return res.status(500).json({ error: 'Internal server error' });
    }
  }

  return res.status(405).json({ error: 'Method not allowed' });
}

