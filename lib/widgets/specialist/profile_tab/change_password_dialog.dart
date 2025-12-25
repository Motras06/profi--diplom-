// lib/widgets/specialist/profile_tab/change_password_dialog.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/supabase_service.dart';

class ChangePasswordDialog {
  static void show(BuildContext parentContext) {
    final currentPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();

    bool currentVisible = false;
    bool newVisible = false;
    bool confirmVisible = false;

    bool isLoading = false;

    showDialog(
      context: parentContext,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Смена пароля'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentPassCtrl,
                  obscureText: !currentVisible,
                  decoration: InputDecoration(
                    labelText: 'Текущий пароль',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(currentVisible ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setDialogState(() => currentVisible = !currentVisible),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newPassCtrl,
                  obscureText: !newVisible,
                  decoration: InputDecoration(
                    labelText: 'Новый пароль',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(newVisible ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setDialogState(() => newVisible = !newVisible),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmPassCtrl,
                  obscureText: !confirmVisible,
                  decoration: InputDecoration(
                    labelText: 'Подтвердите новый пароль',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(confirmVisible ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setDialogState(() => confirmVisible = !confirmVisible),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (newPassCtrl.text != confirmPassCtrl.text) {
                        ScaffoldMessenger.of(parentContext).showSnackBar(
                          const SnackBar(content: Text('Новые пароли не совпадают')),
                        );
                        return;
                      }
                      if (newPassCtrl.text.length < 6) {
                        ScaffoldMessenger.of(parentContext).showSnackBar(
                          const SnackBar(content: Text('Пароль должен быть ≥6 символов')),
                        );
                        return;
                      }

                      setDialogState(() => isLoading = true);
                      try {
                        // Reauthenticate
                        await supabase.auth.signInWithPassword(
                          email: supabase.auth.currentUser!.email!,
                          password: currentPassCtrl.text,
                        );

                        // Update password
                        await supabase.auth.updateUser(UserAttributes(password: newPassCtrl.text));

                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                          ScaffoldMessenger.of(parentContext).showSnackBar(
                            const SnackBar(content: Text('Пароль успешно изменён!')),
                          );
                        }
                      } on AuthException catch (e) {
                        ScaffoldMessenger.of(parentContext).showSnackBar(
                          SnackBar(content: Text(e.message)),
                        );
                      } finally {
                        if (dialogContext.mounted) {
                          setDialogState(() => isLoading = false);
                        }
                      }
                    },
              child: isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Сменить'),
            ),
          ],
        ),
      ),
    );
  }
}