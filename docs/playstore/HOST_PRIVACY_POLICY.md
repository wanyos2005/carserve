# 🔗 How to Host Your Privacy Policy for Play Store

Google Play Store requires a **publicly accessible URL** to your privacy policy. You cannot paste the content directly.

---

## ✅ **Quick Options (Choose One)**

### **Option 1: GitHub Pages (Recommended - Free & Easy)**

**Best for**: Quick setup, free hosting, no domain needed

#### Steps:
1. **Create a GitHub repository** (or use existing)
   ```bash
   # If you don't have a repo for this
   git init privacy-policy
   cd privacy-policy
   ```

2. **Create the privacy policy file**
   - Create `index.html` with your privacy policy content
   - Or create `privacy-policy.html`

3. **Enable GitHub Pages**
   - Go to your GitHub repository
   - Settings → Pages
   - Source: Deploy from a branch
   - Branch: `main` or `master`
   - Folder: `/ (root)`
   - Click Save

4. **Your URL will be**:
   ```
   https://yourusername.github.io/privacy-policy/
   ```
   or
   ```
   https://yourusername.github.io/repository-name/privacy-policy.html
   ```

#### Convert Markdown to HTML:
You can use the markdown file directly or convert it. Here's a simple HTML template:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>DriveOn Privacy Policy</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            line-height: 1.6;
            max-width: 800px;
            margin: 0 auto;
            padding: 20px;
            color: #333;
        }
        h1 { color: #2c3e50; }
        h2 { color: #34495e; margin-top: 30px; }
        h3 { color: #555; }
        a { color: #3498db; }
    </style>
</head>
<body>
    <!-- Paste your privacy policy content here, converted from markdown -->
    <!-- Or use a markdown-to-html converter -->
</body>
</html>
```

---

### **Option 2: Use Your Existing Website**

**Best for**: If you already have a website deployed

#### If you have a Next.js website (frontend-web):
1. Create a page at `frontend-web/pages/privacy.tsx` or `frontend-web/app/privacy/page.tsx`
2. Copy the privacy policy content
3. Deploy your website
4. Your URL: `https://yourdomain.com/privacy`

#### If you have any other website:
- Upload an HTML file to your web server
- Access it at: `https://yourdomain.com/privacy-policy.html`

---

### **Option 3: Free Static Hosting Services**

#### **Netlify Drop** (Easiest)
1. Go to [app.netlify.com/drop](https://app.netlify.com/drop)
2. Drag and drop a folder containing your `index.html`
3. Get instant URL: `https://random-name-123.netlify.app`
4. You can add a custom domain later

#### **Vercel** (If you use Vercel)
1. Create a simple HTML file
2. Deploy to Vercel
3. Get URL: `https://your-project.vercel.app`

#### **GitHub Gist** (Quick but less professional)
1. Create a Gist with your privacy policy
2. Use the raw URL: `https://gist.githubusercontent.com/username/gist-id/raw/privacy-policy.md`
3. Note: Less professional, but works for Play Store

---

### **Option 4: Google Sites (Very Easy)**

1. Go to [sites.google.com](https://sites.google.com)
2. Create a new site
3. Paste your privacy policy content
4. Publish the site
5. Your URL: `https://sites.google.com/view/your-site-name`

---

## 🚀 **Recommended: GitHub Pages Setup**

Here's a complete example for GitHub Pages:

### Step 1: Create HTML file
Create `privacy-policy.html`:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>DriveOn Privacy Policy</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            line-height: 1.8;
            max-width: 900px;
            margin: 0 auto;
            padding: 40px 20px;
            color: #333;
            background: #fff;
        }
        h1 {
            color: #2c3e50;
            border-bottom: 3px solid #3498db;
            padding-bottom: 10px;
        }
        h2 {
            color: #34495e;
            margin-top: 40px;
            margin-bottom: 15px;
        }
        h3 {
            color: #555;
            margin-top: 25px;
        }
        p {
            margin: 15px 0;
        }
        ul, ol {
            margin: 15px 0;
            padding-left: 30px;
        }
        li {
            margin: 8px 0;
        }
        strong {
            color: #2c3e50;
        }
        a {
            color: #3498db;
            text-decoration: none;
        }
        a:hover {
            text-decoration: underline;
        }
        .last-updated {
            color: #7f8c8d;
            font-style: italic;
            margin-bottom: 30px;
        }
    </style>
</head>
<body>
    <h1>DriveOn Privacy Policy</h1>
    <p class="last-updated"><strong>Last Updated: October 26, 2025</strong></p>

    <h2>1. Introduction</h2>
    <p>DriveOn ("we," "our," or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application and related services.</p>

    <h2>2. Information We Collect</h2>
    
    <h3>2.1 Personal Information</h3>
    <ul>
        <li><strong>Account Information</strong>: Name, email address, phone number, profile picture</li>
        <li><strong>Vehicle Information</strong>: Make, model, year, license plate, VIN</li>
        <li><strong>Service History</strong>: Maintenance records, service appointments, provider interactions</li>
        <li><strong>Payment Information</strong>: Billing address, payment method (processed securely by third-party providers)</li>
    </ul>

    <h3>2.2 Location Information</h3>
    <ul>
        <li><strong>Precise Location</strong>: GPS coordinates for service provider matching and navigation</li>
        <li><strong>Approximate Location</strong>: General area for service availability</li>
        <li><strong>Background Location</strong>: For service reminders and location-based notifications</li>
    </ul>

    <h3>2.3 Device Information</h3>
    <ul>
        <li><strong>Device Identifiers</strong>: Device ID, advertising ID</li>
        <li><strong>Technical Information</strong>: Operating system, app version, device model</li>
        <li><strong>Usage Data</strong>: App interactions, feature usage, crash reports</li>
    </ul>

    <h3>2.4 Communication Data</h3>
    <ul>
        <li><strong>Phone Calls</strong>: Direct calling to service providers (with your permission)</li>
        <li><strong>SMS Messages</strong>: Service confirmations and updates</li>
        <li><strong>Push Notifications</strong>: Service reminders, appointment updates, promotional content</li>
    </ul>

    <h2>3. How We Use Your Information</h2>
    
    <h3>3.1 Core Services</h3>
    <ul>
        <li><strong>Service Matching</strong>: Connect you with nearby service providers</li>
        <li><strong>Appointment Scheduling</strong>: Manage your service appointments</li>
        <li><strong>Payment Processing</strong>: Process payments for services</li>
        <li><strong>Communication</strong>: Facilitate communication with service providers</li>
    </ul>

    <h3>3.2 Location Services</h3>
    <ul>
        <li><strong>Provider Matching</strong>: Find service providers near your location</li>
        <li><strong>Navigation</strong>: Provide directions to service locations</li>
        <li><strong>Service Reminders</strong>: Send location-based maintenance reminders</li>
        <li><strong>Emergency Services</strong>: Locate your vehicle in case of emergency</li>
    </ul>

    <h3>3.3 Communication Features</h3>
    <ul>
        <li><strong>Direct Calling</strong>: Enable direct phone calls to service providers</li>
        <li><strong>SMS Notifications</strong>: Send service confirmations and updates</li>
        <li><strong>Push Notifications</strong>: Deliver important app updates and reminders</li>
    </ul>

    <h2>4. Information Sharing</h2>
    
    <h3>4.1 Service Providers</h3>
    <p>We share necessary information with service providers to:</p>
    <ul>
        <li>Schedule and complete services</li>
        <li>Process payments</li>
        <li>Provide customer support</li>
    </ul>

    <h3>4.2 Third-Party Services</h3>
    <ul>
        <li><strong>Firebase</strong>: Analytics, crash reporting, push notifications</li>
        <li><strong>Cloudflare R2</strong>: Media storage for social features</li>
        <li><strong>Payment Processors</strong>: Secure payment processing</li>
        <li><strong>Maps Services</strong>: Navigation and location services</li>
    </ul>

    <h3>4.3 Legal Requirements</h3>
    <p>We may disclose information when required by law or to:</p>
    <ul>
        <li>Comply with legal obligations</li>
        <li>Protect our rights and property</li>
        <li>Ensure user safety</li>
        <li>Prevent fraud or abuse</li>
    </ul>

    <h2>5. Data Security</h2>
    <p>We implement appropriate security measures to protect your information:</p>
    <ul>
        <li><strong>Encryption</strong>: Data encrypted in transit and at rest</li>
        <li><strong>Access Controls</strong>: Limited access to personal information</li>
        <li><strong>Regular Audits</strong>: Security assessments and updates</li>
        <li><strong>Secure Storage</strong>: Industry-standard data storage practices</li>
    </ul>

    <h2>6. Your Rights and Choices</h2>
    
    <h3>6.1 Location Permissions</h3>
    <ul>
        <li><strong>Grant/Revoke</strong>: You can enable or disable location services in device settings</li>
        <li><strong>Precision Control</strong>: Choose between precise or approximate location</li>
        <li><strong>Background Access</strong>: Control background location access</li>
    </ul>

    <h3>6.2 Communication Permissions</h3>
    <ul>
        <li><strong>Phone Access</strong>: Control phone calling features</li>
        <li><strong>SMS Access</strong>: Manage SMS notifications</li>
        <li><strong>Push Notifications</strong>: Enable/disable push notifications</li>
    </ul>

    <h3>6.3 Data Management</h3>
    <ul>
        <li><strong>Account Deletion</strong>: Request account deletion and data removal</li>
        <li><strong>Data Export</strong>: Request a copy of your personal data</li>
        <li><strong>Data Correction</strong>: Update or correct your information</li>
    </ul>

    <h2>7. Data Retention</h2>
    <p>We retain your information for as long as necessary to:</p>
    <ul>
        <li>Provide our services</li>
        <li>Comply with legal obligations</li>
        <li>Resolve disputes</li>
        <li>Enforce our agreements</li>
    </ul>
    
    <p><strong>Retention Periods</strong>:</p>
    <ul>
        <li>Account Information: Until account deletion</li>
        <li>Service History: 7 years (for warranty and legal purposes)</li>
        <li>Location Data: 30 days (unless longer retention required)</li>
        <li>Communication Logs: 1 year</li>
    </ul>

    <h2>8. Children's Privacy</h2>
    <p>DriveOn is not intended for children under 13. We do not knowingly collect personal information from children under 13. If we become aware of such collection, we will delete the information immediately.</p>

    <h2>9. International Data Transfers</h2>
    <p>Your information may be transferred to and processed in countries other than your own. We ensure appropriate safeguards are in place for such transfers.</p>

    <h2>10. Changes to This Policy</h2>
    <p>We may update this Privacy Policy periodically. We will notify you of significant changes through:</p>
    <ul>
        <li>App notifications</li>
        <li>Email notifications</li>
        <li>Updated policy in the app</li>
    </ul>

    <h2>11. Contact Information</h2>
    <p><strong>DriveOn Privacy Team</strong></p>
    <ul>
        <li>Email: privacy@driveon.com</li>
        <li>Address: [Your Business Address]</li>
        <li>Phone: [Your Contact Number]</li>
    </ul>
    
    <p><strong>Data Protection Officer</strong></p>
    <ul>
        <li>Email: dpo@driveon.com</li>
    </ul>

    <h2>12. Regional Privacy Rights</h2>
    
    <h3>12.1 California Residents (CCPA)</h3>
    <ul>
        <li>Right to know what personal information is collected</li>
        <li>Right to delete personal information</li>
        <li>Right to opt-out of sale of personal information</li>
        <li>Right to non-discrimination</li>
    </ul>

    <h3>12.2 European Union Residents (GDPR)</h3>
    <ul>
        <li>Right of access to personal data</li>
        <li>Right to rectification of inaccurate data</li>
        <li>Right to erasure ("right to be forgotten")</li>
        <li>Right to restrict processing</li>
        <li>Right to data portability</li>
        <li>Right to object to processing</li>
    </ul>

    <h2>13. Third-Party Services</h2>
    
    <h3>13.1 Firebase (Google)</h3>
    <ul>
        <li><strong>Purpose</strong>: Analytics, crash reporting, push notifications</li>
        <li><strong>Data</strong>: Device information, usage analytics, crash logs</li>
        <li><strong>Privacy Policy</strong>: <a href="https://policies.google.com/privacy" target="_blank">https://policies.google.com/privacy</a></li>
    </ul>

    <h3>13.2 Cloudflare R2</h3>
    <ul>
        <li><strong>Purpose</strong>: Media storage for social features</li>
        <li><strong>Data</strong>: User-uploaded images and videos</li>
        <li><strong>Privacy Policy</strong>: <a href="https://www.cloudflare.com/privacypolicy/" target="_blank">https://www.cloudflare.com/privacypolicy/</a></li>
    </ul>

    <h3>13.3 Payment Processors</h3>
    <ul>
        <li><strong>Purpose</strong>: Secure payment processing</li>
        <li><strong>Data</strong>: Payment information, transaction details</li>
        <li><strong>Privacy Policy</strong>: [Payment processor privacy policy]</li>
    </ul>

    <hr style="margin: 40px 0; border: none; border-top: 1px solid #ddd;">
    <p style="color: #7f8c8d; font-size: 14px;"><em>This Privacy Policy is effective as of the date listed above and applies to all users of the DriveOn application.</em></p>
</body>
</html>
```

### Step 2: Push to GitHub
```bash
git add privacy-policy.html
git commit -m "Add privacy policy"
git push origin main
```

### Step 3: Enable GitHub Pages
1. Go to repository Settings → Pages
2. Select branch: `main`
3. Select folder: `/ (root)`
4. Save

### Step 4: Get Your URL
Your privacy policy will be available at:
```
https://yourusername.github.io/repository-name/privacy-policy.html
```

---

## ✅ **Requirements for Play Store**

Your privacy policy URL must:
- ✅ Be publicly accessible (no login required)
- ✅ Use HTTPS (secure connection)
- ✅ Be accessible from any device/browser
- ✅ Not redirect to another page
- ✅ Be in a language your app supports

---

## 🎯 **Quick Decision Guide**

- **No website yet?** → Use **GitHub Pages** (5 minutes)
- **Have a website?** → Add privacy page to your site
- **Need it NOW?** → Use **Netlify Drop** (30 seconds)
- **Want professional?** → Use your domain with GitHub Pages or your website

---

## 📝 **After Hosting**

Once you have your URL, use it in Play Console:
1. Go to **Store presence** → **Main store listing**
2. Scroll to **Privacy Policy**
3. Enter your URL: `https://your-url.com/privacy-policy`
4. Save

---

**Need help?** Choose GitHub Pages for the easiest setup, or use Netlify Drop for instant hosting!

