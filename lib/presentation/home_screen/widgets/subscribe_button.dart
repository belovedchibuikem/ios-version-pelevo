import 'package:flutter/material.dart';

class SubscribeButton extends StatelessWidget {
  final bool isSubscribed;
  final bool isLoading;
  final VoidCallback? onPressed;

  const SubscribeButton({
    super.key,
    required this.isSubscribed,
    required this.isLoading,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 25,
      height: 25,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkResponse(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(12.5),
          splashColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, animation) =>
                  ScaleTransition(scale: animation, child: child),
              child: isLoading
                  ? SizedBox(
                      key: const ValueKey('loading'),
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      isSubscribed
                          ? Icons.check_circle
                          : Icons.add_circle_outline,
                      key: ValueKey(isSubscribed),
                      color: isSubscribed
                          ? Colors.green
                          : Theme.of(context).colorScheme.primary,
                      size: 18,
                      semanticLabel: isSubscribed ? 'Unsubscribe' : 'Subscribe',
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
