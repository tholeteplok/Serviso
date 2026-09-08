import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/neo_app_bar.dart';
import '../../../core/widgets/neo_radio_card_group.dart';
import '../../../core/widgets/neo_text_field.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/thick_bottom_border_button.dart';

/// Screen dedicated to creating a new tenant shop and its owner credentials.
/// Migrated from a cramped floating dialog to a full-featured screen with
/// structured cards and full keyboard compatibility.
class CreateShopScreen extends ConsumerStatefulWidget {
  const CreateShopScreen({super.key});

  @override
  ConsumerState<CreateShopScreen> createState() => _CreateShopScreenState();
}

class _CreateShopScreenState extends ConsumerState<CreateShopScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _slugCtrl = TextEditingController();
  final _fullNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  String _selectedBusinessType = 'keduanya';
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _slugCtrl.dispose();
    _fullNameCtrl.dispose();
    _emailCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final shopName = _nameCtrl.text.trim();
    final shopSlug = _slugCtrl.text.trim().toLowerCase();
    final ownerFullName = _fullNameCtrl.text.trim();
    final ownerEmail = _emailCtrl.text.trim().toLowerCase();
    final ownerUsername = _usernameCtrl.text.trim().toLowerCase();
    final ownerPassword = _passwordCtrl.text.trim();

    setState(() => _isLoading = true);
    try {
      final client = Supabase.instance.client;
      try {
        final session = client.auth.currentSession;
        if (session != null && session.isExpired) {
          await client.auth.refreshSession();
        }
      } catch (_) {}

      final token = client.auth.currentSession?.accessToken;
      final res = await client.functions.invoke(
        'create-shop',
        headers: token != null ? {'Authorization': 'Bearer $token'} : null,
        body: {
          'shop_name': shopName,
          'shop_slug': shopSlug,
          'business_type': _selectedBusinessType,
          'owner_full_name': ownerFullName,
          'owner_email': ownerEmail,
          'owner_username': ownerUsername,
          'owner_password': ownerPassword,
        },
      );

      if (res.status == 200 || res.status == 201) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Toko dan owner berhasil dibuat!')),
        );
        Navigator.pop(context, true);
      } else {
        final data = res.data;
        final errorMsg = data is Map ? data['error'] : 'Gagal membuat toko.';
        throw Exception(errorMsg ?? 'Gagal membuat toko.');
      }
    } on FunctionException catch (fe) {
      if (!mounted) return;
      final details = fe.details;
      String? msg;
      if (details is Map) {
        msg = details['error']?.toString() ?? details['message']?.toString();
      } else if (details is String && details.isNotEmpty) {
        msg = details;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg ?? fe.reasonPhrase ?? 'Gagal membuat toko (${fe.status}).'),
          backgroundColor: AppColors.action,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.action,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const NeoAppBar(
        title: 'Buat Toko Baru',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Identitas Toko
              SectionCard(
                title: 'Identitas Toko',
                child: Column(
                  children: [
                    NeoTextField(
                      controller: _nameCtrl,
                      labelText: 'Nama Toko *',
                      hintText: 'Misal: Serviso Pusat, Bengkel Jaya',
                      prefixIcon: AppIcons.storefront,
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Nama toko wajib diisi';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    NeoTextField(
                      controller: _slugCtrl,
                      labelText: 'Kode Toko / Subdomain *',
                      hintText: 'Misal: serviso-pusat (tanpa spasi)',
                      prefixIcon: AppIcons.tag,
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Kode toko wajib diisi';
                        }
                        if (v.trim().contains(' ')) {
                          return 'Kode toko tidak boleh mengandung spasi';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 2. Jenis Usaha
              SectionCard(
                title: 'Model / Jenis Usaha',
                child: NeoRadioCardGroup<String>(
                  selectedValue: _selectedBusinessType,
                  onValueChanged: (val) {
                    setState(() => _selectedBusinessType = val);
                  },
                  options: [
                    NeoRadioOption(
                      value: 'keduanya',
                      title: 'Bengkel & Toko (Barang + Jasa)',
                      subtitle: 'Pencatatan barang fisik sekaligus pengerjaan jasa servis',
                      icon: Icon(AppIcons.wrench, size: 20, color: AppColors.ink900),
                    ),
                    NeoRadioOption(
                      value: 'jasa',
                      title: 'Hanya Jasa / Servis',
                      subtitle: 'Fokus pada jasa mekanik, cuci, atau perbaikan tanpa stok barang',
                      icon: Icon(AppIcons.clock, size: 20, color: AppColors.ink900),
                    ),
                    NeoRadioOption(
                      value: 'barang',
                      title: 'Hanya Barang / Retail',
                      subtitle: 'Toko retail, barang/produk, oli, dan penjualan langsung tanpa servis',
                      icon: Icon(AppIcons.cart, size: 20, color: AppColors.ink900),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 3. Akun Pemilik Toko
              SectionCard(
                title: 'Akun Pemilik Toko',
                child: Column(
                  children: [
                    NeoTextField(
                      controller: _fullNameCtrl,
                      labelText: 'Nama Lengkap Pemilik *',
                      hintText: 'Misal: Budi Santoso',
                      prefixIcon: AppIcons.user,
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Nama lengkap pemilik wajib diisi';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    NeoTextField(
                      controller: _emailCtrl,
                      labelText: 'Email Aktif Pemilik *',
                      hintText: 'pemilik@gmail.com',
                      prefixIcon: AppIcons.envelope,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Email pemilik wajib diisi';
                        }
                        final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
                        if (!emailRegex.hasMatch(v.trim())) {
                          return 'Format email tidak valid (contoh: user@gmail.com)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    NeoTextField(
                      controller: _usernameCtrl,
                      labelText: 'Username Pemilik *',
                      hintText: 'Misal: budi_jaya',
                      prefixIcon: AppIcons.user,
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Username pemilik wajib diisi';
                        }
                        if (v.trim().contains(' ')) {
                          return 'Username tidak boleh mengandung spasi';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    NeoTextField(
                      controller: _passwordCtrl,
                      labelText: 'Password Pemilik * (min. 6 karakter)',
                      prefixIcon: AppIcons.lock,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? AppIcons.eyeSlash : AppIcons.eye,
                          size: 20,
                          color: AppColors.inkMuted,
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Password wajib diisi';
                        }
                        if (v.trim().length < 6) {
                          return 'Password minimal 6 karakter';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: const BoxDecoration(
          color: AppColors.canvas,
          border: Border(
            top: BorderSide(color: AppColors.borderHairline, width: 1),
          ),
        ),
        child: SafeArea(
          child: ThickBottomBorderButton(
            onPressed: _isLoading ? null : _submit,
            isLoading: _isLoading,
            isFullWidth: true,
            variant: ThickButtonVariant.primary,
            child: Text(
              'Buat Toko',
              style: AppTypography.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.ink900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
