# OTP/Passcode Sending Troubleshooting Guide

## Issue: OTP works locally but fails on Vercel deployment

### Common Causes & Solutions

#### 1. **Wrong Port/URL Configuration** ⚠️ MOST COMMON

**Problem:** Using the wrong port or URL for the production backend.

**Important:** In production, services run in Docker and are only accessible through nginx on port 80. Ports 8000-8009 are NOT exposed externally.

**Solution:**
1. Go to your Vercel project dashboard
2. Navigate to **Settings** → **Environment Variables**
3. Add `NEXT_PUBLIC_API_URL` with value: `http://16.16.143.243` (port 80, no port number needed)
4. **DO NOT use** `http://16.16.143.243:8000` - port 8000 is not exposed externally
5. Make sure it's set for **Production**, **Preview**, and **Development** environments
6. **Redeploy** your application after adding the variable

**Why this matters:**
- **Local dev**: `http://localhost:8000` works because you run the service directly
- **Production**: Services run in Docker on ports 8001-8009, only accessible through nginx on port 80
- **Flutter app**: Uses `http://16.16.143.243` (port 80) - this is correct!

**How to verify:**
- Check Vercel build logs - you should see the API URL being used
- Check browser console for errors mentioning API URL

---

#### 2. **Backend Server Not Accessible from Vercel** 🌐

**Problem:** Vercel's servers cannot reach your backend at `http://16.16.143.243` (port 80)

**Possible causes:**
- Backend server is down
- Firewall blocking Vercel's IP addresses
- Backend only allows connections from specific IPs
- Network routing issues

**Solution:**
1. **Test backend accessibility:**
   ```bash
   # From your local machine, test if backend is reachable through nginx (port 80)
   curl http://16.16.143.243/health
   
   # Test the user service endpoint
   curl http://16.16.143.243/users/send-code \
     -X POST \
     -H "Content-Type: application/json" \
     -d '{"email":"test@example.com"}'
   ```

2. **Check backend logs** when Vercel tries to connect
   - Look for connection attempts from Vercel IPs
   - Check for firewall blocks

3. **Allow Vercel IPs in firewall:**
   - Vercel uses dynamic IPs, so you may need to allow all IPs or use a proxy
   - Consider using a service like Cloudflare or AWS API Gateway as a proxy

4. **Use HTTPS if available:**
   - If your backend supports HTTPS, use `https://` instead of `http://`
   - This is more secure and may have better connectivity

---

#### 3. **Request Timeout** ⏱️

**Problem:** Backend takes too long to respond (>30 seconds)

**Solution:**
- Check backend performance
- Ensure email service (for sending OTP) is working
- Check backend logs for slow queries or operations
- Consider increasing timeout in `send-code.ts` if needed

---

#### 4. **CORS Issues** 🔒

**Problem:** Backend CORS configuration blocking requests

**Solution:**
- Verify backend CORS allows requests from your Vercel domain
- Check `nginx.conf` or backend CORS settings
- Ensure `Access-Control-Allow-Origin` includes your Vercel domain

---

### Debugging Steps

#### Step 1: Check Vercel Logs
1. Go to Vercel dashboard → Your project → **Deployments**
2. Click on the latest deployment → **Functions** tab
3. Look for `/api/users/send-code` function logs
4. Check for error messages like:
   - "Cannot connect to backend server"
   - "Request timeout"
   - "API URL not configured"

#### Step 2: Check Browser Console
1. Open your deployed site
2. Open browser DevTools (F12)
3. Go to **Console** tab
4. Try to send OTP
5. Look for error messages

#### Step 3: Test API Route Directly
1. Use a tool like Postman or curl to test:
   ```bash
   curl -X POST https://your-vercel-app.vercel.app/api/users/send-code \
     -H "Content-Type: application/json" \
     -d '{"email":"test@example.com"}'
   ```
2. Check the response and error messages

#### Step 4: Verify Environment Variable
1. Add temporary logging in `send-code.ts`:
   ```typescript
   console.log('API_BASE_URL:', process.env.NEXT_PUBLIC_API_URL);
   ```
2. Check Vercel function logs to see if the variable is set

---

### Quick Fixes to Try

1. **Redeploy after setting environment variable:**
   - Environment variables require a new deployment to take effect
   - Don't just add the variable - trigger a new deployment

2. **Check backend is running:**
   ```bash
   # Test from your local machine (use port 80, not 8000)
   curl http://16.16.143.243/users/send-code \
     -X POST \
     -H "Content-Type: application/json" \
     -d '{"email":"test@example.com"}'
   ```

3. **Verify backend email configuration:**
   - OTP sending requires email service to be configured
   - Check backend logs for email sending errors

4. **Check Vercel function timeout:**
   - Vercel free tier has 10-second timeout for serverless functions
   - Hobby tier has 60 seconds
   - If your backend is slow, consider upgrading or optimizing

---

### Improved Error Messages

The updated code now provides more detailed error messages:

- **"Server configuration error: API URL not configured"** → Set `NEXT_PUBLIC_API_URL` in Vercel
- **"Request timeout"** → Backend is too slow or unreachable
- **"Cannot connect to backend server"** → Network/firewall issue
- **"Connection error"** → Network problem from client side

---

### Next Steps

1. ✅ Set `NEXT_PUBLIC_API_URL` in Vercel environment variables
2. ✅ Redeploy your application
3. ✅ Check Vercel function logs for detailed error messages
4. ✅ Verify backend is accessible from the internet
5. ✅ Test the API route directly using curl/Postman

If issues persist, check:
- Vercel function logs (most detailed)
- Backend server logs
- Browser console errors
- Network tab in browser DevTools

