// lib/models/onboarding_content.dart

class OnboardingContent {
  final int id;
  final String title;
  final String description;
  final String imageUrl;
  final String buttonText;

  const OnboardingContent({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.buttonText,
  });

  factory OnboardingContent.fromJson(Map<String, dynamic> json) {
    return OnboardingContent(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      imageUrl: json['image'] as String,
      buttonText: json['buttonText'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'image': imageUrl,
      'buttonText': buttonText,
    };
  }
}
