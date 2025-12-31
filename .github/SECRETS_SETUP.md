# 🔐 GitHub Secrets Setup Guide

## Quick Setup Checklist

Before your CI/CD workflows can run successfully, you must configure these secrets in your GitHub repository.

### ✅ Required Secrets (3 total)

| Secret Name | Description | Where to Find |
|------------|-------------|---------------|
| `SUPABASE_URL` | Your Supabase project URL | Supabase Dashboard → Settings → API |
| `SUPABASE_PUBLISHABLE_KEY` | Supabase anon/public key | Supabase Dashboard → Settings → API |
| `POWERSYNC_URL` | PowerSync instance URL | PowerSync Dashboard |

**Note:** `DEV_USERNAME` and `DEV_PASSWORD` are only used for local development and are not required in CI/CD.

### 📝 How to Add Secrets

1. **Go to Repository Settings**
   ```
   https://github.com/sebastianHobby/taskly_bloc/settings/secrets/actions
   ```

2. **Click "New repository secret"**

3. **Add each secret:**
   - Name: Copy exactly from the table above (case-sensitive)
   - Value: Paste your actual value
   - Click "Add secret"

4. **Repeat for all 3 secrets**

### 🧪 Testing the Setup

After adding all secrets, test by:

1. **Push to main branch** or **create a PR**
2. **Go to Actions tab**: Check if workflows run without errors
3. **Check build logs**: Should see "Create .env file" step pass
4. **Verify deployment**: Web app should deploy to GitHub Pages

### ❌ Common Issues

**Issue**: Build fails with "Missing environment variable"
- **Solution**: Double-check all 3 secrets are added
- **Check**: Secret names are EXACT match (uppercase, underscores)

**Issue**: "Secrets not found" error
- **Solution**: Ensure you have write access to repository
- **Contact**: Repository admin to grant access

**Issue**: "Invalid credentials" in build
- **Solution**: Verify secret values are correct
- **Test**: Try values locally in your `.env` file first

### 🔒 Security Notes

- ✅ Secrets are encrypted by GitHub
- ✅ Never exposed in logs or workflow files
- ✅ Only accessible during workflow runs
- ⚠️ Use different credentials for CI/CD vs production
- ⚠️ Rotate secrets regularly (every 90 days)

### 🎯 Next Steps

Once secrets are configured:

1. ✅ Push to main → Triggers deployment workflow
2. ✅ Check Actions tab → All jobs should pass
3. ✅ Visit GitHub Pages → App should be live
4. ✅ Monitor first deployment → Fix any issues

### 📚 Related Documentation

- [Full CI/CD Documentation](./CICD.md)
- [Quick Reference Guide](./QUICKREF.md)
- [GitHub Secrets Documentation](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
