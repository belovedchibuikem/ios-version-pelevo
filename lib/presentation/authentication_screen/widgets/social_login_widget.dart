import 'package:flutter/material.dart';
import '../../../../core/app_export.dart';

class SocialLoginWidget extends StatelessWidget {
  // Temporarily disabled - keeping constructor for future re-enabling
  final Function(String) onError;
  final bool isLoading;

  const SocialLoginWidget({
    super.key,
    required SocialAuthService socialAuthService,
    required this.onError,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Or continue with',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Social login buttons temporarily disabled
            // _SocialButton(
            //   onPressed: isLoading
            //       ? null
            //       : () => _handleSocialLogin(
            //           context, _socialAuthService.signInWithGoogle, 'google'),
            //   icon: Icons.g_mobiledata,
            //   label: 'Google',
            //   isLoading: isLoading,
            //   color: Colors.red,
            // ),
            // _SocialButton(
            //   onPressed: isLoading
            //       ? null
            //       : () => _handleSocialLogin(
            //           context, _socialAuthService.signInWithApple, 'apple'),
            //   icon: Icons.apple,
            //   label: 'Apple',
            //   isLoading: isLoading,
            //   color: Colors.black,
            // ),
            // Spotify button commented out as requested
            // _SocialButton(
            //   onPressed: isLoading
            //       ? null
            //       : () => _handleSocialLogin(
            //           context, _socialAuthService.signInWithSpotify, 'spotify'),
            //   icon: Icons.music_note,
            //   label: 'Spotify',
            //   isLoading: isLoading,
            //   color: Colors.green,
            // ),

            // Placeholder text to indicate social login is disabled
            const Expanded(
              child: Text(
                'Social login temporarily disabled',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// _SocialButton class temporarily removed - will be restored when social login is re-enabled
