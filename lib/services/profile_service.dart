import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_stats.dart';

class ProfileService {
  final supabase = Supabase.instance.client;

  Future<Map<String, dynamic>> fetchProfile(String userId) async {
    final response = await supabase
        .from('profiles')
        .select('display_name, photo_url, role, specialty')
        .eq('id', userId)
        .single();

    return response;
  }

  Future<ProfileStats> fetchStats(String userId, String? role) async {
    final ordersCount = await supabase
        .from('orders')
        .count()
        .eq('user_id', userId);

    final savedCount = await supabase
        .from('saved_services')
        .count()
        .eq('user_id', userId);

    int reviewsCount = 0;
    double avgRating = 0.0;

    if (role == 'specialist') {
      final reviews = await supabase
          .from('reviews')
          .select('rating')
          .eq('specialist_id', userId);

      reviewsCount = reviews.length;

      if (reviews.isNotEmpty) {
        final ratings = reviews
            .map((e) => (e['rating'] as num).toDouble())
            .toList();

        avgRating = ratings.reduce((a, b) => a + b) / ratings.length;
      }
    } else {
      reviewsCount = await supabase
          .from('reviews')
          .count()
          .eq('user_id', userId);
    }

    return ProfileStats(
      ordersCount: ordersCount,
      reviewsCount: reviewsCount,
      savedServicesCount: savedCount,
      averageRating: avgRating,
    );
  }

  Future<void> updateProfile(
    String userId,
    String displayName,
    String? photoUrl,
  ) async {
    await supabase
        .from('profiles')
        .update({'display_name': displayName.trim(), 'photo_url': photoUrl})
        .eq('id', userId);
  }
}
