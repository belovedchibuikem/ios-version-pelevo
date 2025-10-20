import '../models/category.dart';

// lib/data/repositories/category_repository.dart

class CategoryRepository {
  static final CategoryRepository _instance = CategoryRepository._internal();
  factory CategoryRepository() => _instance;
  CategoryRepository._internal();

  // This repository uses the same mock data as PodcastRepository for now
  // In a real app, this would make API calls to get category data

  Future<List<Category>> getAllCategories() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 600));
    return _getMockCategories();
  }

  Future<Category?> getCategoryByName(String name) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 400));
    try {
      return _getMockCategories()
          .firstWhere((category) => category.name == name);
    } catch (e) {
      return null;
    }
  }

  // Helper method to generate mock category data
  List<Category> _getMockCategories() {
    return [
      Category(
        id: '1',
        name: "Comedy",
        icon: "sentiment_very_satisfied",
        count: 245,
        gradientStart: "0xFFFF6B6B",
        gradientEnd: "0xFFFF8E8E",
      ),
      Category(
        id: '2',
        name: "True Crime",
        icon: "gavel",
        count: 189,
        gradientStart: "0xFF4ECDC4",
        gradientEnd: "0xFF44B3AA",
      ),
      Category(
        id: '3',
        name: "Education",
        icon: "school",
        count: 312,
        gradientStart: "0xFF45B7D1",
        gradientEnd: "0xFF3A9BC1",
      ),
      Category(
        id: '4',
        name: "News",
        icon: "newspaper",
        count: 156,
        gradientStart: "0xFF96CEB4",
        gradientEnd: "0xFF85B8A3",
      ),
      Category(
        id: '5',
        name: "Business",
        icon: "business",
        count: 198,
        gradientStart: "0xFFFECF6F",
        gradientEnd: "0xFFF9BF3B",
      ),
      Category(
        id: '6',
        name: "Science",
        icon: "science",
        count: 143,
        gradientStart: "0xFFBB8FCE",
        gradientEnd: "0xFFA569BD",
      ),
      Category(
        id: '7',
        name: "Technology",
        icon: "computer",
        count: 267,
        gradientStart: "0xFF58D68D",
        gradientEnd: "0xFF4CAF50",
      ),
      Category(
        id: '8',
        name: "Sports",
        icon: "sports_soccer",
        count: 134,
        gradientStart: "0xFFFF9FF3",
        gradientEnd: "0xFFFF69B4",
      ),
    ];
  }
}
