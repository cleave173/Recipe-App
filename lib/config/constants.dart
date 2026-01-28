class AppConstants {
  // API Configuration
  static const String apiBaseUrl = 'http://localhost:8080/api';
  
  // App Info
  static const String appName = 'Рецепттер';
  static const String appVersion = '1.0.0';
  
  // Pagination
  static const int defaultPageSize = 20;
  
  // Image
  static const int maxImageWidth = 1024;
  static const int maxImageHeight = 1024;
  static const int imageQuality = 85;
  
  // Cooking Time Ranges (minutes)
  static const int quickCookingTime = 30;
  static const int mediumCookingTime = 60;
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 350);
  static const Duration longAnimation = Duration(milliseconds: 500);
  
  // Cache Keys
  static const String userTokenKey = 'user_token';
  static const String userDataKey = 'user_data';
  static const String themeKey = 'app_theme';
  static const String languageKey = 'app_language';
  
  // Difficulty Levels
  static const String difficultyEasy = 'easy';
  static const String difficultyMedium = 'medium';
  static const String difficultyHard = 'hard';
  
  // User Roles
  static const String roleUser = 'USER';
  static const String roleAdmin = 'ADMIN';
}
