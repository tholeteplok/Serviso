import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_brand_icon.dart';
import '../../../core/widgets/neo_card.dart';
import '../../../core/widgets/neo_text_field.dart';
import '../../../core/widgets/thick_bottom_border_button.dart';
import '../controllers/session_controller.dart';
import '../data/auth_repository.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _shopSlugController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadShopSlug();
  }

  Future<void> _loadShopSlug() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('saved_shop_slug');
    if (saved != null && mounted) {
      _shopSlugController.text = saved;
    }
  }

  @override
  void dispose() {
    _shopSlugController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(sessionProvider.notifier).login(
            username: _usernameController.text,
            password: _passwordController.text,
            shopSlug: _shopSlugController.text,
          );
    final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_shop_slug', _shopSlugController.text.trim());
    } catch (e) {
      setState(() {
        _error = e is AuthException ? e.message : 'Terjadi kesalahan. Coba lagi.';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = AppTypography.textTheme();
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: NeoCard(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppBrandIcon(
                      size: 60,
                      iconSize: 36,
                      shadowOffset: 2.5,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'SERVISO',
                      style: AppTypography.chakra(
                        fontSize: 32,
                        color: AppColors.ink900,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Masuk untuk mengelola bengkel',
                      style: textTheme.bodyMedium
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 24),
                    NeoTextField(
                      key: const Key('shop_slug'),
                      controller: _shopSlugController,
                      labelText: 'Kode Toko',
                      prefixIcon: AppIcons.storefront,
                      textInputAction: TextInputAction.next,
                      validator: (value) => value == null || value.trim().isEmpty
                          ? 'Kode Toko wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    NeoTextField(
                      key: const Key('username'),
                      controller: _usernameController,
                      keyboardType: TextInputType.emailAddress,
                      labelText: 'Username atau Email',
                      prefixIcon: AppIcons.user,
                      textInputAction: TextInputAction.next,
                      validator: (value) => value == null || value.trim().isEmpty
                          ? 'Username atau email wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    NeoTextField(
                      key: const Key('password'),
                      controller: _passwordController,
                      obscureText: _obscure,
                      labelText: 'Password',
                      prefixIcon: AppIcons.shieldCheck,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure ? AppIcons.eye : AppIcons.eyeSlash,
                          size: 18,
                          color: AppColors.ink900,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Password wajib diisi'
                          : null,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: textTheme.bodyMedium
                            ?.copyWith(color: AppColors.statusDanger),
                      ),
                    ],
                    const SizedBox(height: 20),
                    ThickBottomBorderButton(
                      isFullWidth: true,
                      isLoading: _loading,
                      variant: ThickButtonVariant.primary,
                      onPressed: _loading ? null : _submit,
                      icon: Icon(AppIcons.check, size: 18, color: AppColors.ink900),
                      child: const Text('Masuk'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

