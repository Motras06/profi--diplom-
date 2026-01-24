// lib/widgets/user/profile_tab/profile_avatar.dart
import 'package:flutter/material.dart';

class ProfileAvatar extends StatelessWidget {
  final String? photoUrl;
  final String? displayName;

  const ProfileAvatar({
    super.key,
    this.photoUrl,
    this.displayName,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 70,
      backgroundColor: Colors.grey.shade200,
      backgroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
      child: photoUrl == null
          ? Text(
              (displayName?.substring(0, 1).toUpperCase()) ?? '?',
              style: const TextStyle(fontSize: 60, fontWeight: FontWeight.bold),
            )
          : null,
    );
  }
}