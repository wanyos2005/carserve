import { NextApiRequest, NextApiResponse } from 'next';

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000';

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  const { templateId } = req.query;

  if (req.method === 'DELETE') {
    try {
      const response = await fetch(`${API_BASE_URL}/service-provider-service/templates/${templateId}`, {
        method: 'DELETE',
        headers: {
          'Content-Type': 'application/json',
        },
      });

      if (response.ok) {
        return res.status(200).json({ success: true });
      } else {
        const errorData = await response.json();
        return res.status(response.status).json({ error: errorData.detail || 'Failed to delete template' });
      }
    } catch (error) {
      console.error('Error deleting template:', error);
      return res.status(500).json({ error: 'Internal server error' });
    }
  }

  return res.status(405).json({ error: 'Method not allowed' });
}
