import 'package:flutter/material.dart';
import 'package:prowirksearch/models/profile_stats.dart';
import 'package:prowirksearch/widgets/user/profile_tab/profile_stat_card.dart';

class ProfileStatsRow extends StatelessWidget {
  final ProfileStats stats;
  final String? role;

  const ProfileStatsRow({super.key, required this.stats, this.role});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ProfileStatCard(
          icon: Icons.work_outline,
          value: '${stats.ordersCount}',
          label: 'Заказов',
        ),
        ProfileStatCard(
          icon: Icons.star_outline,
          value: role == 'specialist'
              ? stats.averageRating.toStringAsFixed(1)
              : '${stats.reviewsCount}',
          label: role == 'specialist' ? 'Рейтинг' : 'Отзывов',
        ),
        ProfileStatCard(
          icon: Icons.bookmark_border,
          value: '${stats.savedServicesCount}',
          label: 'Сохранено',
        ),
      ],
    );
  }
}
