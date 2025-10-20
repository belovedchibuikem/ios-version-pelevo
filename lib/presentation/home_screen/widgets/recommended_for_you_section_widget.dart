import 'package:flutter/material.dart';

class RecommendedForYouSectionWidget extends StatelessWidget {
  final VoidCallback? onSeeAll;

  const RecommendedForYouSectionWidget({Key? key, this.onSeeAll})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'View All',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.blue[700],
                  fontWeight: FontWeight.w500,
                ),
          ),
          SizedBox(width: 6),
          Icon(
            Icons.arrow_forward_ios,
            color: Colors.blue[700],
            size: 14,
          ),
        ],
      ),
    );
  }
}
