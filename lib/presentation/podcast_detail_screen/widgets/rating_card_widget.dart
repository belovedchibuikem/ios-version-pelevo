import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';
import '../../../services/rating_service.dart';

class RatingCardWidget extends StatefulWidget {
  final String podcastId;
  final String podcastTitle;

  const RatingCardWidget({
    super.key,
    required this.podcastId,
    required this.podcastTitle,
  });

  @override
  State<RatingCardWidget> createState() => _RatingCardWidgetState();
}

class _RatingCardWidgetState extends State<RatingCardWidget> {
  final RatingService _ratingService = RatingService();
  bool _isLoading = true;
  double _averageRating = 0;
  int _totalRatings = 0;
  List<Map<String, dynamic>> _recentRatings = [];
  Map<String, int> _ratingDistribution = {};

  @override
  void initState() {
    super.initState();
    _loadRatingData();
  }

  Future<void> _loadRatingData() async {
    try {
      final ratingResult =
          await _ratingService.getPodcastRating(widget.podcastId);
      final recentResult =
          await _ratingService.getRecentRatings(widget.podcastId);

      if (ratingResult['success'] == true) {
        final data = ratingResult['data'];
        setState(() {
          _averageRating = data['average_rating']?.toDouble() ?? 0;
          _totalRatings = data['total_ratings'] ?? 0;
          _ratingDistribution =
              Map<String, int>.from(data['rating_distribution'] ?? {});
        });
      }

      if (recentResult['success'] == true) {
        setState(() {
          _recentRatings = List<Map<String, dynamic>>.from(
              recentResult['data']['ratings'] ?? []);
        });
      }
    } catch (e) {
      debugPrint('Error loading rating data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppTheme.lightTheme.colorScheme.shadow,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: CircularProgressIndicator(
            color: AppTheme.lightTheme.colorScheme.primary,
          ),
        ),
      );
    }

    if (_totalRatings == 0) {
      return Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppTheme.lightTheme.colorScheme.shadow,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                CustomIconWidget(
                  iconName: 'star',
                  color: AppTheme.lightTheme.colorScheme.primary,
                  size: 20,
                ),
                SizedBox(width: 2.w),
                Text(
                  'Ratings',
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.lightTheme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Text(
              'No ratings yet',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.lightTheme.colorScheme.shadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'star',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 20,
              ),
              SizedBox(width: 2.w),
              Text(
                'Ratings',
                style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.lightTheme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),

          // Average rating display
          Row(
            children: [
              Text(
                '${_averageRating.toStringAsFixed(1)}',
                style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.lightTheme.colorScheme.primary,
                ),
              ),
              SizedBox(width: 2.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        index < _averageRating ? Icons.star : Icons.star_border,
                        color: AppTheme.lightTheme.colorScheme.primary,
                        size: 16,
                      );
                    }),
                  ),
                  Text(
                    '$_totalRatings ratings',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),

          SizedBox(height: 2.h),

          // Rating distribution
          if (_ratingDistribution.isNotEmpty) ...[
            Text(
              'Rating Distribution',
              style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.lightTheme.colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 1.h),
            ...List.generate(5, (index) {
              final rating = 5 - index;
              final count = _ratingDistribution[rating.toString()] ?? 0;
              final percentage =
                  _totalRatings > 0 ? (count / _totalRatings) * 100 : 0;

              return Padding(
                padding: EdgeInsets.only(bottom: 1.h),
                child: Row(
                  children: [
                    Text(
                      '$rating',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor:
                            AppTheme.lightTheme.colorScheme.surfaceVariant,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.lightTheme.colorScheme.primary,
                        ),
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      '$count',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],

          // Recent ratings
          if (_recentRatings.isNotEmpty) ...[
            SizedBox(height: 2.h),
            Text(
              'Recent Ratings',
              style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.lightTheme.colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 1.h),
            ..._recentRatings.take(3).map((rating) {
              final userName = rating['user']?['name'] ?? 'Anonymous';
              final userRating = rating['rating'] ?? 0;
              final comment = rating['comment'];
              final createdAt = DateTime.tryParse(rating['created_at'] ?? '');

              return Container(
                margin: EdgeInsets.only(bottom: 1.h),
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.surfaceVariant
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          userName,
                          style:
                              AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.lightTheme.colorScheme.onSurface,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: List.generate(5, (index) {
                            return Icon(
                              index < userRating
                                  ? Icons.star
                                  : Icons.star_border,
                              color: AppTheme.lightTheme.colorScheme.primary,
                              size: 12,
                            );
                          }),
                        ),
                      ],
                    ),
                    if (comment != null && comment.isNotEmpty) ...[
                      SizedBox(height: 0.5.h),
                      Text(
                        comment,
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color:
                              AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (createdAt != null) ...[
                      SizedBox(height: 0.5.h),
                      Text(
                        _formatDate(createdAt),
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color:
                              AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
