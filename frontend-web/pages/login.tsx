import React, { useState, useEffect } from 'react';
import { useRouter } from 'next/router';
import Link from 'next/link';
import { Mail, ArrowRight, CheckCircle, AlertCircle } from 'lucide-react';
import { useAuth } from '../lib/auth';

const LoginPage: React.FC = () => {
  const router = useRouter();
  const { sendCode, login, user, isAuthenticated } = useAuth();
  const [step, setStep] = useState<'email' | 'code'>('email');
  const [email, setEmail] = useState('');
  const [code, setCode] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  const handleSendCode = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email.trim()) {
      setError('Email is required');
      return;
    }

    setIsLoading(true);
    setError('');
    setSuccess('');

    try {
      const success = await sendCode(email.trim());
      if (success) {
        setSuccess('Verification code sent to your email');
        setStep('code');
      } else {
        setError('Failed to send verification code. Please try again.');
      }
    } catch (error) {
      setError('An error occurred. Please try again.');
    } finally {
      setIsLoading(false);
    }
  };

  // Redirect after successful login when user is available
  useEffect(() => {
    if (isAuthenticated && user) {
      console.log('🔍 [Login] Redirect check - user:', user);
      console.log('🔍 [Login] Redirect check - providerId:', user.providerId);
      console.log('🔍 [Login] Redirect check - userType:', user.userType);
      console.log('🔍 [Login] Redirect check - isAuthenticated:', isAuthenticated);
      
      // Determine redirect path based on user type
      let redirectPath = '/home'; // Default to car owner home
      
      if (user.providerId || user.userType === 'provider') {
        // Redirect to provider dashboard with user's providerId
        redirectPath = `/provider/dashboard?providerId=${user.providerId}`;
        console.log('✅ [Login] Redirecting provider to:', redirectPath);
      } else if (user.userType === 'carOwner' || (!user.providerId && user.userType !== 'admin')) {
        // Redirect car owners to their home page
        redirectPath = '/home';
        console.log('✅ [Login] Redirecting car owner to:', redirectPath);
      } else if (user.userType === 'admin') {
        // Admins can stay on marketing page or redirect to admin dashboard
        redirectPath = '/';
        console.log('✅ [Login] Redirecting admin to:', redirectPath);
      } else {
        // Default: redirect to home for car owners
        redirectPath = '/home';
        console.log('✅ [Login] Default redirect to:', redirectPath);
      }
      
      // Perform redirect
      if (redirectPath) {
        router.push(redirectPath).catch(err => {
          console.error('❌ [Login] Redirect error:', err);
        });
      }
    }
  }, [isAuthenticated, user, router]);

  const handleVerifyCode = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!code.trim()) {
      setError('Verification code is required');
      return;
    }

    setIsLoading(true);
    setError('');
    setSuccess('');

    try {
      const success = await login(email.trim(), code.trim());
      if (!success) {
        setError('Invalid verification code. Please try again.');
        setIsLoading(false);
        return;
      }
      // Wait a bit for auth state to update, then check redirect
      // The useEffect will handle the redirect, but we can also do it here as a fallback
      setTimeout(() => {
        // This is a fallback - the useEffect should handle it, but just in case
        console.log('⏱️ [Login] Fallback redirect check after login');
      }, 500);
      // Don't set loading to false here - let the redirect happen
    } catch (error) {
      setError('An error occurred. Please try again.');
      setIsLoading(false);
    }
  };

  const handleBackToEmail = () => {
    setStep('email');
    setCode('');
    setError('');
    setSuccess('');
  };

  return (
    <div className="min-h-screen bg-white flex flex-col justify-center">
      <div className="max-w-md mx-auto px-6 py-8">
        <div className="text-center mb-8">
          <h1 className="text-3xl font-bold text-gray-900 mb-2">DriveOn</h1>
          <h2 className="text-2xl font-semibold text-gray-900 mb-2">
            {step === 'email' ? 'Ready to Browse?' : 'Enter verification code'}
          </h2>
          <p className="text-gray-600">
            {step === 'email' 
              ? 'Just enter your email for a seamless one-time signup'
              : 'We sent a verification code to your email address'
            }
          </p>
        </div>

        <div className="bg-white">
          {step === 'email' ? (
            <form onSubmit={handleSendCode} className="space-y-6">
              <div>
                <label htmlFor="email" className="block text-sm font-medium text-gray-700 mb-2">
                  Email
                </label>
                <input
                  id="email"
                  name="email"
                  type="email"
                  autoComplete="email"
                  required
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  className="w-full px-3 py-3 border-b-2 border-red-600 rounded-none bg-transparent focus:outline-none focus:border-red-700 text-base"
                  placeholder="Enter your email"
                />
              </div>

              {error && (
                <div className="text-red-600 text-sm">
                  {error}
                </div>
              )}

              {success && (
                <div className="text-green-600 text-sm">
                  {success}
                </div>
              )}

              <div>
                {isLoading ? (
                  <div className="w-full flex justify-center py-3">
                    <div className="animate-spin rounded-full h-6 w-6 border-b-2 border-red-600"></div>
                  </div>
                ) : (
                  <button
                    type="submit"
                    className="w-full bg-red-600 text-white py-3 px-4 rounded-lg font-semibold hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-red-500 transition-colors"
                  >
                    Send Code
                  </button>
                )}
              </div>
            </form>
          ) : (
            <form onSubmit={handleVerifyCode} className="space-y-6">
              <div>
                <label htmlFor="code" className="block text-sm font-medium text-gray-700 mb-2">
                  Verification code
                </label>
                <input
                  id="code"
                  name="code"
                  type="text"
                  required
                  value={code}
                  onChange={(e) => setCode(e.target.value)}
                  className="w-full px-3 py-3 border-b-2 border-red-600 rounded-none bg-transparent focus:outline-none focus:border-red-700 text-base"
                  placeholder="Enter 6-digit code"
                  maxLength={6}
                />
                <p className="mt-2 text-sm text-gray-600">
                  Code sent to <span className="font-medium">{email}</span>
                </p>
              </div>

              {error && (
                <div className="text-red-600 text-sm">
                  {error}
                </div>
              )}

              <div className="flex space-x-3">
                <button
                  type="button"
                  onClick={handleBackToEmail}
                  className="flex-1 py-3 px-4 border border-gray-300 rounded-lg text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-primary-500 font-medium transition-colors"
                >
                  Back
                </button>
                {isLoading ? (
                  <div className="flex-1 flex justify-center py-3">
                    <div className="animate-spin rounded-full h-6 w-6 border-b-2 border-red-600"></div>
                  </div>
                ) : (
                  <button
                    type="submit"
                    className="flex-1 bg-red-600 text-white py-3 px-4 rounded-lg font-semibold hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-red-500 transition-colors"
                  >
                    Verify Code
                  </button>
                )}
              </div>
            </form>
          )}

          <div className="mt-8 text-center">
            <Link href="/">
              <span className="text-red-600 hover:text-red-500 text-sm font-medium">
                Learn more about DriveOn
              </span>
            </Link>
          </div>
        </div>
      </div>
    </div>
  );
};

export default LoginPage;
