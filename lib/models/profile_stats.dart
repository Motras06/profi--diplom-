// lib/models/profile_stats.dart
class ProfileStats {
  final int ordersCount;
  final int reviewsCount;
  final int savedServicesCount;
  final double averageRating;

  ProfileStats({
    this.ordersCount = 0,
    this.reviewsCount = 0,
    this.savedServicesCount = 0,
    this.averageRating = 0.0,
  });

  ProfileStats copyWith({
    int? ordersCount,
    int? reviewsCount,
    int? savedServicesCount,
    double? averageRating,
  }) {
    return ProfileStats(
      ordersCount: ordersCount ?? this.ordersCount,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      savedServicesCount: savedServicesCount ?? this.savedServicesCount,
      averageRating: averageRating ?? this.averageRating,
    );
  }
}