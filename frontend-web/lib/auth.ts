import { useState, useEffect } from 'react';

export interface User {
  id: string;
  email: string;
  name: string;
  userType: 'carOwner' | 'provider' | 'admin';
  providerId?: string;
  isActive: boolean;
  createdAt: string;
  lastLogin?: string;
}

export interface AuthState {
  user: User | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  token: string | null;
}

export const useAuth = () => {
  const [authState, setAuthState] = useState<AuthState>({
    user: null,
    isAuthenticated: false,
    isLoading: true,
    token: null,
  });

  useEffect(() => {
    initializeAuth();
  }, []);

  const initializeAuth = async () => {
    try {
      const token = localStorage.getItem('token');
      if (token) {
        const user = await fetchUserProfile(token);
        if (user) {
          setAuthState({
            user,
            isAuthenticated: true,
            isLoading: false,
            token,
          });
        } else {
          clearAuth();
        }
      } else {
        setAuthState(prev => ({ ...prev, isLoading: false }));
      }
    } catch (error) {
      console.error('Auth initialization error:', error);
      clearAuth();
    }
  };

  const fetchUserProfile = async (token: string): Promise<User | null> => {
    try {
      const response = await fetch('/api/users/me', {
        headers: {
          'Authorization': `Bearer ${token}`,
        },
      });

      if (response.ok) {
        const userData = await response.json();
        console.log('👤 [Auth] User data from /api/users/me:', userData);
        console.log('👤 [Auth] provider_id from backend:', userData.provider_id);
        console.log('👤 [Auth] provider_id type:', typeof userData.provider_id);
        const mappedUser: User = {
          id: userData.id.toString(),
          email: userData.email,
          name: userData.name || userData.provider_name || 'User',
          userType: (userData.is_admin ? 'admin' : 
                   userData.provider_id ? 'provider' : 'carOwner') as 'carOwner' | 'provider' | 'admin',
          providerId: userData.provider_id?.toString(),
          isActive: userData.is_active !== false,
          createdAt: userData.created_at,
          lastLogin: userData.last_login,
        };
        console.log('👤 [Auth] Mapped user object:', mappedUser);
        console.log('👤 [Auth] Mapped providerId:', mappedUser.providerId);
        return mappedUser;
      }
      return null;
    } catch (error) {
      console.error('Error fetching user profile:', error);
      return null;
    }
  };

  const login = async (email: string, code: string): Promise<boolean> => {
    try {
      const response = await fetch('/api/users/verify-code', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ email, code }),
      });

      if (response.ok) {
        const data = await response.json();
        const token = data.access_token;
        
        localStorage.setItem('token', token);
        
        const user = await fetchUserProfile(token);
        if (user) {
          setAuthState({
            user,
            isAuthenticated: true,
            isLoading: false,
            token,
          });
          return true;
        }
      }
      return false;
    } catch (error) {
      console.error('Login error:', error);
      return false;
    }
  };

  const sendCode = async (email: string): Promise<boolean> => {
    try {
      const response = await fetch('/api/users/send-code', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ email }),
      });

      if (!response.ok) {
        const errorData = await response.json().catch(() => ({ error: 'Unknown error' }));
        console.error('Send code failed:', errorData);
      }

      return response.ok;
    } catch (error) {
      console.error('Send code error:', error);
      return false;
    }
  };

  const logout = () => {
    clearAuth();
  };

  const clearAuth = () => {
    localStorage.removeItem('token');
    setAuthState({
      user: null,
      isAuthenticated: false,
      isLoading: false,
      token: null,
    });
  };

  const refreshUser = async () => {
    if (authState.token) {
      const user = await fetchUserProfile(authState.token);
      if (user) {
        setAuthState(prev => ({ ...prev, user }));
      } else {
        clearAuth();
      }
    }
  };

  return {
    ...authState,
    login,
    sendCode,
    logout,
    refreshUser,
  };
};

// API helper function
export const apiRequest = async (url: string, options: RequestInit = {}) => {
  const token = localStorage.getItem('token');
  
  const response = await fetch(url, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...(token && { 'Authorization': `Bearer ${token}` }),
      ...options.headers,
    },
  });

  if (response.status === 401) {
    // Token expired or invalid
    localStorage.removeItem('token');
    window.location.href = '/login';
    return null;
  }

  return response;
};
