import { NextApiRequest, NextApiResponse } from 'next';
import { apiRequest } from '../../../lib/auth';

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  if (req.method === 'GET') {
    try {
      // Get auth token from request headers (sent by apiRequest from client)
      const authHeader = req.headers.authorization;
      const token = authHeader?.replace('Bearer ', '');

      const headers: HeadersInit = {
        'Content-Type': 'application/json',
      };

      if (token) {
        headers['Authorization'] = `Bearer ${token}`;
      }

      const response = await fetch(`${API_BASE_URL}/vehicles/`, {
        method: 'GET',
        headers,
      });

      if (response.ok) {
        const data = await response.json();
        return res.status(200).json(data);
      } else {
        // Return empty array if unauthorized or not found
        if (response.status === 401 || response.status === 404) {
          return res.status(200).json([]);
        }
        return res.status(response.status).json({ error: 'Failed to fetch vehicles' });
      }
    } catch (error) {
      console.error('Error fetching vehicles:', error);
      return res.status(200).json([]); // Return empty array on error
    }
  }

  return res.status(405).json({ error: 'Method not allowed' });
}

