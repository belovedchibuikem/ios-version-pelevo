# Google Play Console Setup Guide for In-App Purchases

## Overview
This guide will help you set up in-app purchases in Google Play Console for your Pelevo podcast app using the `in_app_purchase ^3.2.3` plugin.

## Prerequisites
- Google Play Console account
- App uploaded to Google Play Console (at least in Internal Testing)
- App signed with the same certificate as uploaded to Play Console

## Step-by-Step Setup

### 1. Access Google Play Console
1. Go to [Google Play Console](https://play.google.com/console)
2. Select your app (Pelevo Podcast)
3. Navigate to **Monetize** → **Products** → **In-app products**

### 2. Create In-App Products

#### Product 1: Premium Monthly
1. Click **"Create product"**
2. Fill in the details:
   - **Product ID**: `premium_monthly_pelevo` (exact match, case-sensitive)
   - **Name**: `Premium Monthly Subscription`
   - **Description**: `Monthly premium subscription for Pelevo Podcast`
   - **Price**: Set your desired price (e.g., $4.99)
   - **Status**: `Active`
3. Click **"Save"**

#### Product 2: Premium Yearly
1. Click **"Create product"** again
2. Fill in the details:
   - **Product ID**: `premium_yearly_pelevo` (exact match, case-sensitive)
   - **Name**: `Premium Yearly Subscription`
   - **Description**: `Yearly premium subscription for Pelevo Podcast`
   - **Price**: Set your desired price (e.g., $49.99)
   - **Status**: `Active`
3. Click **"Save"**

### 3. Publish Products
1. Make sure both products are set to **"Active"** status
2. Click **"Publish"** for each product
3. Wait for the products to be published (usually takes a few minutes)

### 4. Set Up Test Accounts
1. Go to **Setup** → **License testing**
2. Add test accounts that will be used for testing
3. These accounts should have access to your app

### 5. Upload and Publish Your App
1. Make sure your app is uploaded to Google Play Console
2. At minimum, publish to **Internal Testing** track
3. Add your test accounts to the internal testing group

## Testing

### 1. Use Test Screen
1. Open your app
2. Go to **Profile** → **Test In-App Purchase (Debug)**
3. Check the status and available products
4. Use the debug buttons to test functionality

### 2. Check Logs
Look for these log messages:
- `🛒 IN-APP PURCHASE: Successfully loaded X products`
- `✅ GOOGLE PLAY DEBUG: Found products:`
- `🔴 GOOGLE PLAY DEBUG: Missing products:` (if products not found)

### 3. Common Issues and Solutions

#### Issue: "Product not found"
**Solution:**
- Verify Product ID matches exactly (case-sensitive)
- Check if products are published and active
- Ensure app is uploaded and published
- Verify app is signed with correct certificate

#### Issue: "In-app purchases not available"
**Solution:**
- Check if Google Play Services is installed
- Verify device has internet connection
- Ensure app is published (not just uploaded)

#### Issue: "Products not loading"
**Solution:**
- Wait a few minutes after publishing products
- Check Google Play Console for any errors
- Verify test account has access to the app

## Debug Commands

### Check Configuration
```dart
await GooglePlayDebugHelper.checkGooglePlayConfiguration();
```

### Print Setup Instructions
```dart
GooglePlayDebugHelper.printSetupInstructions();
```

## Product ID Reference

| Product | ID | Type |
|---------|----|----- |
| Premium Monthly | `premium_monthly_pelevo` | Subscription |
| Premium Yearly | `premium_yearly_pelevo` | Subscription |

## Important Notes

1. **Product IDs are case-sensitive** - must match exactly
2. **Products must be published** before they can be queried
3. **App must be published** (at least internal testing) before IAP works
4. **Test accounts** must be added to license testing
5. **Certificate** must match between uploaded app and testing device

## Troubleshooting

### Check Product Status
1. Go to Google Play Console → Your App → Monetize → Products → In-app products
2. Verify both products show "Active" status
3. Check if there are any error messages

### Verify App Status
1. Go to Google Play Console → Your App → Release → Testing
2. Ensure app is published to at least Internal Testing
3. Check if test accounts are added

### Test with Different Accounts
1. Try with different test accounts
2. Make sure accounts are added to license testing
3. Verify accounts have access to the app

## Support

If you continue to have issues:
1. Check the debug logs in your app
2. Use the test screen to diagnose problems
3. Verify all steps in this guide are completed
4. Check Google Play Console for any error messages

## Next Steps

Once products are working:
1. Set up your backend to verify purchases
2. Implement purchase verification
3. Test the complete purchase flow
4. Deploy to production
