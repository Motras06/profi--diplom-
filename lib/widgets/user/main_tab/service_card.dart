import 'package:flutter/material.dart';
import '../../../screens/other/service_screen.dart';
import '../../../screens/other/specialist_profile.dart';

class ServiceCard extends StatefulWidget {
  final Map<String, dynamic> service;
  final bool isSaved;
  final VoidCallback onToggleSave;

  const ServiceCard({
    super.key,
    required this.service,
    required this.isSaved,
    required this.onToggleSave,
  });

  @override
  State<ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<ServiceCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _saveController;
  late Animation<double> _saveScaleAnimation;

  @override
  void initState() {
    super.initState();

    _saveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _saveScaleAnimation = Tween<double>(begin: 1.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _saveController,
        curve: Curves.elasticOut, 
      ),
    );
  }

  @override
  void didUpdateWidget(covariant ServiceCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSaved != oldWidget.isSaved && widget.isSaved) {
      _saveController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _saveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final specialist = widget.service['profiles'] ?? {};
    final String? photoUrl = widget.service['main_photo'] as String?;
    final String? specialistPhoto = specialist['photo_url'] as String?;
    final String specialistName =
        (specialist['display_name'] as String?) ?? 'Мастер';

    final serviceName = (widget.service['name'] as String?) ?? 'Без названия';
    final price = widget.service['price'];
    final priceText = price != null ? '$price BYN' : 'По договорённости';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.24),
            blurRadius: 32,
            spreadRadius: 8,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.12),
            blurRadius: 16,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        color: colorScheme.surfaceContainerLow,
        margin: EdgeInsets.zero,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ServiceScreen(service: widget.service),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 3 / 2,
                    child: Image.network(
                      photoUrl ?? '',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: colorScheme.surfaceContainerHighest,
                        child: Center(
                          child: Icon(
                            Icons.broken_image_rounded,
                            size: 52,
                            color: colorScheme.onSurfaceVariant.withOpacity(
                              0.6,
                            ),
                          ),
                        ),
                      ),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: colorScheme.surfaceContainerHighest,
                          child: Center(
                            child: SizedBox(
                              width: 44,
                              height: 44,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                value:
                                    loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                    : null,
                                color: colorScheme.primary.withOpacity(0.7),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  Positioned(
                    top: 16,
                    right: 16,
                    child: ScaleTransition(
                      scale: _saveScaleAnimation,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.55),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.30),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(
                            widget.isSaved
                                ? Icons.bookmark
                                : Icons.bookmark_border_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                          padding: const EdgeInsets.all(10),
                          constraints: const BoxConstraints(),
                          onPressed: widget.onToggleSave,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                SpecialistProfileScreen(specialist: specialist),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: colorScheme.surfaceContainerHigh,
                            backgroundImage: specialistPhoto != null
                                ? NetworkImage(specialistPhoto)
                                : null,
                            child: specialistPhoto == null
                                ? Text(
                                    specialistName.isNotEmpty
                                        ? specialistName[0].toUpperCase()
                                        : 'М',
                                    style: TextStyle(
                                      color: colorScheme.onSurfaceVariant,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              specialistName,
                              style: textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.primary,
                                height: 1.1,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      serviceName,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                        letterSpacing: -0.1,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 8),

                    Container(
                      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        priceText,
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
