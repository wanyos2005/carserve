import { useState, useEffect, useCallback } from 'react';
import { apiRequest } from '../lib/auth';

interface UseApiResult<T> {
  data: T | null;
  loading: boolean;
  error: string | null;
  refetch: () => Promise<void>;
}

export function useApi<T>(url: string): UseApiResult<T> {
  const [data, setData] = useState<T | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchData = useCallback(async () => {
    if (!url) {
      console.log('⚠️ [useApi] Empty URL, skipping fetch');
      setLoading(false);
      setData(null);
      setError(null);
      return;
    }

    try {
      console.log('🌐 [useApi] Fetching:', url);
      setLoading(true);
      setError(null);
      
      const response = await apiRequest(url);
      if (!response) {
        console.error('❌ [useApi] No response from apiRequest:', url);
        throw new Error('Authentication required');
      }
      
      console.log(`📡 [useApi] Response status for ${url}:`, response.status);
      
      if (!response.ok) {
        const errorText = await response.text().catch(() => 'Could not read error');
        console.error(`❌ [useApi] HTTP error for ${url}:`, response.status, errorText);
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      
      const result = await response.json();
      console.log(`✅ [useApi] Success for ${url}:`, result);
      setData(result);
    } catch (err) {
      console.error(`❌ [useApi] Error for ${url}:`, err);
      setError(err instanceof Error ? err.message : 'An error occurred');
      setData(null);
    } finally {
      setLoading(false);
    }
  }, [url]);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  return {
    data,
    loading,
    error,
    refetch: fetchData,
  };
}