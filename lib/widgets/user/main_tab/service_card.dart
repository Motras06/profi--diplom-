import 'package:flutter/material.dart';
import '../../../screens/other/service_screen.dart';
import '../../../screens/other/specialist_profile.dart';

class ServiceCard extends StatelessWidget {
  final Map<String, dynamic> service;
  final bool isSaved;
  final VoidCallback onToggleSave;
  final VoidCallback onReport;

  const ServiceCard({
    super.key,
    required this.service,
    required this.isSaved,
    required this.onToggleSave,
    required this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    final specialist = service['profiles'] ?? {};
    final String? photoUrl = service['main_photo'];

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ServiceScreen(service: service)),
          );
        },
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (photoUrl != null)
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      photoUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) =>
                          progress == null ? child : const Center(child: CircularProgressIndicator()),
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.broken_image),
                      ),
                    ),
                  )
                else
                  Container(
                    height: 140,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image_not_supported, size: 48),
                  ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SpecialistProfileScreen(specialist: specialist),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundImage: specialist['photo_url'] != null
                                  ? NetworkImage(specialist['photo_url'])
                                  : null,
                              child: specialist['photo_url'] == null
                                  ? Text(
                                      (specialist['display_name'] as String?)?.substring(0, 1).toUpperCase() ?? 'М',
                                      style: const TextStyle(fontSize: 10),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                specialist['display_name'] ?? 'Мастер',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        service['name'],
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        service['price'] != null ? '${service['price']} BYN' : 'По договорённости',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Кнопка сохранить
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), shape: BoxShape.circle),
                child: IconButton(
                  iconSize: 18,
                  padding: const EdgeInsets.all(5),
                  constraints: const BoxConstraints(),
                  icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border, color: Colors.white, size: 18),
                  onPressed: onToggleSave,
                ),
              ),
            ),

            // Кнопка пожаловаться
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                decoration: BoxDecoration(color: Colors.red.withOpacity(0.7), shape: BoxShape.circle),
                child: IconButton(
                  iconSize: 16,
                  padding: const EdgeInsets.all(5),
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.flag, color: Colors.white, size: 16),
                  tooltip: 'Пожаловаться',
                  onPressed: onReport,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}