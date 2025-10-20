# 🔐 Authentication Troubleshooting Guide

## ❌ **Issue: Backend Returning HTML Instead of JSON**

The authentication system is receiving HTML responses instead of the expected JSON, causing `FormatException: Unexpected character (at character 1)` errors.

## 🔍 **Problem Analysis:**

### **Current Error:**
```
❌ Login error: FormatException: Unexpected character (at character 1)
<!DOCTYPE html>
^
```

### **Root Cause:**
The backend is returning HTML content instead of JSON, which typically indicates:
1. **Incorrect API endpoint** - The URL is pointing to a web page instead of an API
2. **Backend not configured** - Authentication endpoints don't exist
3. **Server redirect** - The server is redirecting to a login page
4. **Wrong base URL** - API configuration is pointing to the wrong server

## 🔧 **Solutions:**

### **1. Verify API Endpoints** ✅

**Current Configuration:**
```dart
// ApiConfig.baseUrl = 'https://pelevo.com'
// AuthService calls: /api/auth/login and /api/auth/register
// Full URLs: https://pelevo.com/api/auth/login
```

**Check if these endpoints exist:**
- `https://pelevo.com/api/auth/login` (POST)
- `https://pelevo.com/api/auth/register` (POST)

**Test with curl or Postman:**
```bash
curl -X POST https://pelevo.com/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password"}'
```

### **2. Update API Configuration** ✅

**If endpoints are different, update `ApiConfig`:**
```dart
class ApiConfig {
  // Option 1: Different base URL
  static const String baseUrl = 'https://api.pelevo.com';
  
  // Option 2: Different endpoint paths
  static const String authLoginEndpoint = '/auth/login';  // instead of /api/auth/login
  static const String authRegisterEndpoint = '/auth/register';
  
  // Option 3: Custom API URL construction
  static String getAuthUrl(String endpoint) {
    return '$baseUrl/auth/$endpoint';  // without /api prefix
  }
}
```

### **3. Check Backend Status** ✅

**Verify backend is running and accessible:**
```bash
# Check if server is responding
curl -I https://pelevo.com/api/auth/login

# Check server status
curl -v https://pelevo.com/api/health  # if health endpoint exists
```

**Expected Response:**
```json
{
  "success": true,
  "data": {
    "token": "jwt_token_here",
    "refreshToken": "refresh_token_here",
    "user": {
      "id": "user_id",
      "email": "user@example.com"
    }
  }
}
```

### **4. Handle HTML Responses Gracefully** ✅

**The updated AuthService now includes:**
- **Content-Type validation** - Checks if response is JSON
- **Detailed logging** - Shows response status, headers, and body
- **Better error messages** - Explains what went wrong
- **Fallback handling** - Graceful error handling for non-JSON responses

## 🧪 **Testing Steps:**

### **Step 1: Check Current Endpoints**
1. **Open browser** and navigate to `https://pelevo.com/api/auth/login`
2. **Check response** - Should be JSON, not HTML
3. **Verify status** - Should not redirect to login page

### **Step 2: Test with Updated Logging**
1. **Run the app** and attempt login
2. **Check debug console** for detailed response information:
   ```
   🔐 Login: Attempting to authenticate at: https://pelevo.com/api/auth/login
   🔐 Login: Response status: 200
   🔐 Login: Response headers: {content-type: text/html, ...}
   🔐 Login: Response body preview: <!DOCTYPE html>...
   ```

### **Step 3: Identify the Issue**
Based on the logs, determine:
- **Status code**: 200, 404, 500, etc.
- **Content-Type**: application/json, text/html, etc.
- **Response body**: JSON data or HTML content

## 🚀 **Quick Fixes:**

### **Fix 1: Update Base URL**
```dart
// In ApiConfig
static const String baseUrl = 'https://api.pelevo.com';  // or your actual API server
```

### **Fix 2: Update Endpoint Paths**
```dart
// In ApiConfig
static String getAuthUrl(String endpoint) {
  return '$baseUrl/auth/$endpoint';  // remove /api prefix
}
```

### **Fix 3: Use Different Authentication Endpoints**
```dart
// If your backend uses different paths
static const String authLoginEndpoint = '/user/login';
static const String authRegisterEndpoint = '/user/register';
```

### **Fix 4: Add API Version**
```dart
// If your API has versioning
static String getAuthUrl(String endpoint) {
  return '$baseUrl/api/v1/auth/$endpoint';
}
```

## 🔍 **Debugging Commands:**

### **Check API Endpoints:**
```bash
# Test login endpoint
curl -X POST https://pelevo.com/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password"}' \
  -v

# Test with different content type
curl -X POST https://pelevo.com/api/auth/login \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "email=test@example.com&password=password" \
  -v
```

### **Check Server Response:**
```bash
# Check if endpoint exists
curl -I https://pelevo.com/api/auth/login

# Check server headers
curl -v https://pelevo.com/api/auth/login
```

## 📋 **Common Issues & Solutions:**

| Issue | Cause | Solution |
|-------|-------|----------|
| **HTML Response** | Wrong endpoint or server redirect | Update API configuration |
| **404 Not Found** | Endpoint doesn't exist | Check backend routes |
| **500 Server Error** | Backend error | Check server logs |
| **CORS Error** | Cross-origin issue | Configure backend CORS |
| **Authentication Required** | Missing auth headers | Add proper headers |

## 🎯 **Expected Results After Fix:**

### **Successful Login:**
```
🔐 Login: Attempting to authenticate at: https://api.pelevo.com/auth/login
🔐 Login: Response status: 200
🔐 Login: Response headers: {content-type: application/json, ...}
🔐 Login: Response body preview: {"success":true,"data":{"token":"jwt_token_here"...
🔐 Login: Parsed response data: {success: true, data: {token: jwt_token_here...}}
✅ Login successful with real token
```

### **Failed Login (Proper Error):**
```
🔐 Login: Response status: 401
🔐 Login: Error response is not JSON: {"error":"Invalid credentials"}
❌ Login: Login failed with status 401. Server returned: {"error":"Invalid credentials"}
```

## 🚀 **Next Steps:**

1. **✅ Check Backend**: Verify authentication endpoints exist and work
2. **✅ Update Configuration**: Fix API URLs if needed
3. **✅ Test Endpoints**: Use curl/Postman to verify responses
4. **✅ Run App**: Test authentication with updated logging
5. **✅ Monitor Logs**: Check debug console for detailed information

## 📚 **Additional Resources:**

- **ApiConfig**: `frontend/lib/core/config/api_config.dart`
- **AuthService**: `frontend/lib/core/services/auth_service.dart`
- **Backend API Documentation**: Check your backend team for correct endpoints
- **Network Testing**: Use Postman or curl to test API endpoints

---

**🔧 Use this guide to identify and fix the HTML response issue!**
