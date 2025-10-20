# 🔐 Repository Authentication Migration Guide

## ✅ **Repositories Updated to UnifiedAuthService**

All repository files in `frontend/lib/data/repositories/` have been successfully migrated to use `UnifiedAuthService` for consistent authentication token handling.

### **Updated Repositories:**

#### 1. **user_repository.dart** ✅
- **Status**: Fully migrated to `UnifiedAuthService`
- **Methods Updated**:
  - `getCurrentUser()` - Profile retrieval
  - `updateUserProfile()` - Profile updates
  - `uploadAvatar()` - Avatar uploads
  - `deleteAccount()` - Account deletion
  - `logout()` - User logout

#### 2. **package_subscription_repository.dart** ✅
- **Status**: Fully migrated to `UnifiedAuthService`
- **Methods Updated**:
  - `getSubscriptionPlans()` - Subscription plan retrieval
  - `getUserSubscription()` - User subscription data
  - `subscribeToPlan()` - Plan subscription
  - `cancelSubscription()` - Subscription cancellation
  - `getTransactionHistory()` - Transaction history
  - `getPaymentMethods()` - Payment methods
  - `addPaymentMethod()` - Add payment method
  - `removePaymentMethod()` - Remove payment method
  - `processPayment()` - Payment processing

#### 3. **podcast_repository.dart** ✅
- **Status**: No authentication needed (uses external PodcastIndexService)
- **Note**: This repository doesn't make authenticated API calls to your backend

#### 4. **category_repository.dart** ✅
- **Status**: No authentication needed (mock data only)
- **Note**: This repository provides static category data

#### 5. **podcast_refresh_notifier.dart** ✅
- **Status**: No authentication needed (simple notifier class)

## 🔄 **Migration Details**

### **Before (Problematic):**
```dart
import '../../core/services/auth_service.dart';

class SomeRepository {
  final AuthService _authService = AuthService();
  
  Future<void> someMethod() async {
    final token = await _authService.getToken();
    // API call with token...
  }
}
```

### **After (Fixed):**
```dart
import '../../core/services/unified_auth_service.dart';

class SomeRepository {
  final UnifiedAuthService _authService = UnifiedAuthService();
  
  Future<void> someMethod() async {
    final token = await _authService.getToken();
    // API call with token...
  }
}
```

## 🎯 **Benefits of Migration**

1. **Unified Token Source**: All repositories now use the same authentication system
2. **Automatic Token Sync**: Tokens are automatically synced between storage systems
3. **Better Security**: Prefers secure storage while maintaining compatibility
4. **Consistent Behavior**: All API calls now include proper authentication headers
5. **Easier Debugging**: Centralized authentication logging

## 📱 **Expected Results**

After migration, all repository API calls will:
- ✅ Include `Authorization: Bearer <token>` headers
- ✅ Use the same token source as the main authentication flow
- ✅ Automatically handle token migration between storage systems
- ✅ Provide consistent authentication behavior across the app

## 🧪 **Testing the Migration**

### **1. Verify Authentication Headers**
Check that API requests include proper headers:
```dart
// In debug console, you should see:
🔐 UnifiedAuthService: Token retrieved from secure storage
📦 PACKAGE SUBSCRIPTION: Authorization header set with token: eyJhbGciOi...
```

### **2. Test Repository Methods**
Verify that all repository methods work with authentication:
- **UserRepository**: Profile operations, avatar uploads
- **PackageSubscriptionRepository**: Subscription management, payments
- **PodcastRepository**: Podcast data retrieval (external service)
- **CategoryRepository**: Category data (mock data)

### **3. Check for 401 Errors**
Ensure no more "Unauthorized" errors from repository API calls.

## 🔍 **Remaining Services to Update**

While repositories are now fully migrated, the following services still use `AuthService` and could benefit from migration:

### **High Priority Services:**
- `episode_progress_service.dart` - Episode progress tracking
- `history_service.dart` - Listening history
- `rating_service.dart` - Podcast ratings
- `feedback_service.dart` - User feedback

### **Medium Priority Services:**
- `subscriber_service.dart` - Subscriber management
- `subscriber_count_service.dart` - Subscriber counts
- `listening_statistics_service.dart` - Listening stats

### **Migration Command for Services:**
```bash
# Quick migration for any service:
find frontend/lib/services -name "*.dart" -exec sed -i 's/AuthService/UnifiedAuthService/g' {} \;
find frontend/lib/services -name "*.dart" -exec sed -i 's/auth_service/unified_auth_service/g' {} \;
```

## 🚀 **Next Steps**

1. **✅ Repositories**: All repositories are now migrated
2. **🔄 Services**: Consider migrating remaining services for consistency
3. **🧪 Testing**: Test all repository methods with authentication
4. **📊 Monitoring**: Monitor API calls for proper authentication headers

## 🔧 **Troubleshooting**

### **If repositories still have authentication issues:**

1. **Check Token Storage**: Ensure login flow is storing tokens properly
2. **Verify Service Initialization**: Ensure repositories are initialized after auth
3. **Check Logs**: Look for authentication debug messages
4. **Token Format**: Verify tokens are in correct JWT format

### **Common Issues:**
- **Token Not Available**: Check if user is properly logged in
- **Service Order**: Ensure authentication happens before repository calls
- **Storage Permissions**: Verify app has proper storage access

## 📚 **Additional Resources**

- **UnifiedAuthService**: `frontend/lib/core/services/unified_auth_service.dart`
- **Authentication README**: `frontend/lib/core/services/README_AUTHENTICATION.md`
- **Migration Examples**: See updated repository files for reference

---

**🎉 All repositories are now successfully migrated to use UnifiedAuthService!**
