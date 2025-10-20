import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CustomImageWidget extends StatelessWidget {
  final String? imageUrl;
  final double width;
  final double height;
  final BoxFit fit;

  /// Optional widget to show when the image fails to load.
  /// If null, a default asset image is shown.
  final Widget? errorWidget;

  const CustomImageWidget({
    super.key,
    required this.imageUrl,
    this.width = 60,
    this.height = 60,
    this.fit = BoxFit.cover,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    // Handle empty URLs or explicit null values
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildFallbackImage();
    }

    // Check if the imageUrl is a network URL or a local asset
    if (imageUrl!.startsWith('http://') || imageUrl!.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: imageUrl!,
        width: width,
        height: height,
        fit: fit,
        errorWidget: (context, url, error) {
          debugPrint('Image error: $error for URL: $url');
          return errorWidget ?? _buildFallbackImage();
        },
        placeholder: (context, url) => Container(
          width: width,
          height: height,
          color: Colors.grey[200],
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    } else {
      // Handle local asset
      return Image.asset(
        imageUrl!,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Asset image error: $error');
          return errorWidget ?? _buildFallbackImage();
        },
      );
    }
  }

  Widget _buildFallbackImage() {
    return Image.asset(
      'assets/images/no-audio-image.jpg',
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('Fallback image error: $error');
        // If even the fallback image fails, show a grey container
        return Container(
          width: width,
          height: height,
          color: Colors.grey[300],
          child: const Icon(Icons.image_not_supported, color: Colors.grey),
        );
      },
    );
  }
}
