import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:neuroup/app/theme/app_theme.dart';
import 'package:neuroup/app/theme/colors.dart';
import 'package:neuroup/shared/models/user_profile.dart';
import 'package:neuroup/features/auth/presentation/providers/auth_providers.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  UserRole _role = UserRole.student;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(authStateProvider.notifier)
        .registerWithEmail(
          email: _email.text.trim(),
          password: _password.text,
          displayName: _name.text.trim(),
          role: _role,
        );
    if (!mounted) return;
    final state = ref.read(authStateProvider);
    if (state.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.error!)),
      );
    } else if (state.isAuthenticated) {
      context.go('/lessons');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authStateProvider.select((s) => s.isLoading));
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
              decoration: const BoxDecoration(
                gradient: AppColors.accentGradient,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(36),
                  bottomRight: Radius.circular(36),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    tooltip: 'Geri',
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Aramıza katıl!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Hesap oluştur',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Ad Soyad',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _name,
                      decoration: const InputDecoration(
                        hintText: 'Adın Soyadın',
                        prefixIcon: Icon(
                          Icons.person_outline_rounded,
                          size: 20,
                        ),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Ad gerekli' : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'E-posta',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        hintText: 'ornek@email.com',
                        prefixIcon: Icon(
                          Icons.alternate_email_rounded,
                          size: 20,
                        ),
                      ),
                      validator: (v) => (v == null || !v.contains('@'))
                          ? 'Geçersiz e-posta'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Şifre',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _password,
                      obscureText: true,
                      decoration: const InputDecoration(
                        hintText: 'En az 6 karakter',
                        prefixIcon: Icon(Icons.lock_outline_rounded, size: 20),
                      ),
                      validator: (v) =>
                          v == null || v.length < 6 ? 'En az 6 karakter' : null,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Hesap türü',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _RoleChip(
                          label: 'Öğrenci',
                          icon: Icons.school_rounded,
                          selected: _role == UserRole.student,
                          onTap: () => setState(() => _role = UserRole.student),
                        ),
                        _RoleChip(
                          label: 'Öğretmen',
                          icon: Icons.co_present_rounded,
                          selected: _role == UserRole.teacher,
                          onTap: () => setState(() => _role = UserRole.teacher),
                        ),
                        _RoleChip(
                          label: 'Veli',
                          icon: Icons.family_restroom_rounded,
                          selected: _role == UserRole.parent,
                          onTap: () => setState(() => _role = UserRole.parent),
                        ),
                        _RoleChip(
                          label: 'Moderatör',
                          icon: Icons.support_agent_rounded,
                          selected: _role == UserRole.moderator,
                          onTap: () =>
                              setState(() => _role = UserRole.moderator),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      height: 56,
                      child: FilledButton(
                        onPressed: isLoading ? null : _submit,
                        child: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Hesap Oluştur'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.full),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.full),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : AppColors.border.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
