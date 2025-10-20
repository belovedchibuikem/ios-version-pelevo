import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';
import '../../../services/rating_service.dart';

class RatingWidget extends StatefulWidget {
  final String podcastId;
  final String podcastTitle;
  final double? currentRating;
  final int? totalRatings;
  final Function(double rating)? onRatingSubmitted;

  const RatingWidget({
    super.key,
    required this.podcastId,
    required this.podcastTitle,
    this.currentRating,
    this.totalRatings,
    this.onRatingSubmitted,
  });

  @override
  State<RatingWidget> createState() => _RatingWidgetState();
}

class _RatingWidgetState extends State<RatingWidget> {
  final RatingService _ratingService = RatingService();
  double _selectedRating = 0;
  bool _isLoading = false;
  bool _hasRated = false;
  double? _userRating;

  @override
  void initState() {
    super.initState();
    debugPrint('RatingWidget: Initialized with podcastId: ${widget.podcastId}');
    _loadUserRating();
  }

  Future<void> _loadUserRating() async {
    try {
      final result = await _ratingService.getUserRating(widget.podcastId);
      if (result['success'] == true && result['data']['has_rated'] == true) {
        final rating = result['data']['rating'];
        setState(() {
          _hasRated = true;
          _userRating = rating['rating'].toDouble();
          _selectedRating = _userRating!;
        });
      }
    } catch (e) {
      debugPrint('Error loading user rating: $e');
    }
  }

  Future<void> _submitRating(double rating) async {
    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('Submitting rating: $rating for podcast: ${widget.podcastId}');

      final result = await _ratingService.ratePodcast(
        podcastId: widget.podcastId,
        rating: rating.toInt(),
      );

      debugPrint('Rating result: $result');

      if (result['success'] == true) {
        setState(() {
          _hasRated = true;
          _userRating = rating;
          _selectedRating = rating;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.green,
          ),
        );

        widget.onRatingSubmitted?.call(rating);
      }
    } catch (e) {
      debugPrint('Error submitting rating: $e');
      String errorMessage = 'Failed to submit rating';

      // Extract just the message from the exception
      if (e is Exception) {
        String exceptionString = e.toString();
        debugPrint('RatingWidget: Exception string: $exceptionString');
        // Remove "Exception: " prefix if present
        if (exceptionString.startsWith('Exception: ')) {
          errorMessage = exceptionString.substring(11);
        } else {
          errorMessage = exceptionString;
        }
        debugPrint('RatingWidget: Final error message: $errorMessage');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errorMessage,
            style: TextStyle(fontSize: 14),
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Star rating selector
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final starRating = index + 1;
            return GestureDetector(
              onTap: _isLoading
                  ? null
                  : () => _submitRating(starRating.toDouble()),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 1.w),
                child: Icon(
                  index < _selectedRating ? Icons.star : Icons.star_border,
                  color: AppTheme.lightTheme.colorScheme.primary,
                  size: 28,
                ),
              ),
            );
          }),
        ),

        // Rating text
        if (_selectedRating > 0)
          Center(
            child: Padding(
              padding: EdgeInsets.only(top: 1.h),
              child: Text(
                _getRatingText(_selectedRating),
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

        // Loading indicator
        if (_isLoading)
          Center(
            child: Padding(
              padding: EdgeInsets.only(top: 1.h),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: AppTheme.lightTheme.colorScheme.primary,
                  strokeWidth: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }

  String _getRatingText(double rating) {
    switch (rating.toInt()) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return '';
    }
  }
}
