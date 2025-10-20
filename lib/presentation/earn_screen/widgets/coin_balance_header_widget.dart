import 'package:flutter/material.dart';

import '../../../core/app_export.dart';

class CoinBalanceHeaderWidget extends StatelessWidget {
  final int currentCoins;
  final double conversionRate;
  final Animation<double> animation;

  const CoinBalanceHeaderWidget({
    super.key,
    required this.currentCoins,
    required this.conversionRate,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.lightTheme.colorScheme.primary,
            AppTheme.lightTheme.colorScheme.primaryContainer,
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40), // Account for app bar
            Row(
              children: [
                AnimatedBuilder(
                  animation: animation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: animation.value,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.lightTheme.colorScheme.secondary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: CustomIconWidget(
                          iconName: 'monetization_on',
                          color: AppTheme.lightTheme.colorScheme.onSecondary,
                          size: 24,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Balance',
                        style:
                            AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.onPrimary
                              .withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 4),
                      AnimatedBuilder(
                        animation: animation,
                        builder: (context, child) {
                          final animatedCoins =
                              (currentCoins * animation.value).round();
                          return Text(
                            '$animatedCoins Coins',
                            style: AppTheme.lightTheme.textTheme.headlineSmall
                                ?.copyWith(
                              color: AppTheme.lightTheme.colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 2),
                      AnimatedBuilder(
                        animation: animation,
                        builder: (context, child) {
                          final nairaValue =
                              (currentCoins * conversionRate * animation.value);
                          return Text(
                            '≈ ₦${nairaValue.toStringAsFixed(2)}',
                            style: AppTheme.lightTheme.textTheme.bodySmall
                                ?.copyWith(
                              color: AppTheme.lightTheme.colorScheme.onPrimary
                                  .withValues(alpha: 0.7),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.lightTheme.colorScheme.secondary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '1 coin = ₦${conversionRate.toStringAsFixed(2)}',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
