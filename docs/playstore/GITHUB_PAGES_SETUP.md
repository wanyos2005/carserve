# 🚀 GitHub Pages Setup for Privacy Policy

## Step-by-Step Instructions

### Step 1: Add and Commit the File

```bash
# Navigate to your project root
cd c:\systemc\car

# Add the privacy policy HTML file
git add docs/playstore/privacy-policy.html

# Commit it
git commit -m "Add privacy policy HTML for Play Store"

# Push to GitHub
git push origin main
```

---

### Step 2: Enable GitHub Pages

**Where to enable GitHub Pages:**

1. **Go to your GitHub repository** (on GitHub.com)
   - Navigate to: `https://github.com/yourusername/your-repo-name`

2. **Click on "Settings"** (top menu bar of your repository)
   - It's usually the rightmost tab in your repo navigation

3. **Scroll down to "Pages"** (left sidebar)
   - In the Settings page, look for "Pages" in the left sidebar menu
   - It's under the "Code and automation" section

4. **Configure GitHub Pages:**
   - **Source**: Select "Deploy from a branch"
   - **Branch**: Select `main` (or `master` if that's your default branch)
   - **Folder**: Select `/ (root)` or `/docs` depending on where you want to serve from
   - **Click "Save"**

5. **Wait 1-2 minutes** for GitHub to build and deploy

---

### Step 3: Get Your Privacy Policy URL

After enabling GitHub Pages, your privacy policy will be available at:

**If you selected `/ (root)` folder:**
```
https://yourusername.github.io/your-repo-name/docs/playstore/privacy-policy.html
```

**If you selected `/docs` folder:**
```
https://yourusername.github.io/your-repo-name/playstore/privacy-policy.html
```

**To find your exact URL:**
- Go back to Settings → Pages
- You'll see a green checkmark with your site URL
- Click the URL to verify it works

---

### Step 4: Alternative - Move File to Root for Cleaner URL

If you want a cleaner URL like `https://yourusername.github.io/your-repo-name/privacy-policy.html`, you can:

1. **Move the file to root:**
   ```bash
   git mv docs/playstore/privacy-policy.html privacy-policy.html
   git commit -m "Move privacy policy to root for cleaner URL"
   git push origin main
   ```

2. **Then your URL will be:**
   ```
   https://yourusername.github.io/your-repo-name/privacy-policy.html
   ```

---

### Step 5: Use in Play Console

1. Copy your privacy policy URL
2. Go to Google Play Console
3. Navigate to: **Store presence** → **Main store listing**
4. Scroll to **Privacy Policy** section
5. Paste your URL: `https://yourusername.github.io/your-repo-name/privacy-policy.html`
6. Click **Save**

---

## ✅ Quick Checklist

- [ ] File committed and pushed to GitHub
- [ ] GitHub Pages enabled in Settings → Pages
- [ ] Selected branch: `main` (or `master`)
- [ ] Selected folder: `/ (root)` or `/docs`
- [ ] Waited 1-2 minutes for deployment
- [ ] Verified URL works (opens in browser)
- [ ] Added URL to Play Console

---

## 🔍 Troubleshooting

### URL not working?
- Wait 2-3 minutes after enabling Pages
- Check that the file path in URL matches your file location
- Make sure the branch is `main` or `master` (not a different branch)
- Clear browser cache and try again

### Can't find Settings → Pages?
- Make sure you're logged into GitHub
- You need admin/write access to the repository
- Check you're on the correct repository

### Want HTTPS?
- GitHub Pages automatically provides HTTPS
- Your URL will use `https://` (secure)

---

## 📝 Example URLs

**If your repo is:** `github.com/johndoe/driveon-app`

**And you keep file at:** `docs/playstore/privacy-policy.html`

**Your URL will be:**
```
https://johndoe.github.io/driveon-app/docs/playstore/privacy-policy.html
```

**If you move file to root:** `privacy-policy.html`

**Your URL will be:**
```
https://johndoe.github.io/driveon-app/privacy-policy.html
```

---

**That's it! Your privacy policy will be live and ready for Play Store submission! 🎉**

