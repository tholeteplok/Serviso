import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/neo_app_bar.dart';
import '../../../core/widgets/neo_text_field.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/thick_bottom_border_button.dart';
import '../../auth/controllers/session_controller.dart';
import '../data/settings_repository.dart';
import '../models/app_settings.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider).valueOrNull;
    if (settings != null) {
      _applySettings(settings);
    } else {
      ref.read(settingsRepositoryProvider).getSettings().then((value) {
        if (mounted) _applySettings(value);
      });
    }
  }

  void _applySettings(AppSettings settings) {
    _nameController.text = settings.shopName;
    _addressController.text = settings.address ?? '';
    _phoneController.text = settings.phone ?? '';
    _notesController.text = settings.receiptNotes ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Nama toko wajib diisi');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final updated = await ref.read(settingsRepositoryProvider).updateSettings(
            shopName: name,
            address: _addressController.text,
            phone: _phoneController.text,
            receiptNotes: _notesController.text,
          );
      ref.invalidate(settingsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pengaturan toko disimpan')),
        );
        Navigator.of(context).pop(updated);
      }
    } on SettingsException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Pengaturan gagal diperbarui: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = AppTypography.textTheme();
    final isAdmin = ref.watch(isAdminProvider);

    if (!isAdmin) {
      return const Scaffold(
        appBar: NeoAppBar(title: 'Pengaturan Toko'),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Hanya pemilik yang dapat mengubah pengaturan toko',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: const NeoAppBar(title: 'Pengaturan Toko'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Profil toko tampil di struk pembayaran',
            style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Informasi Bengkel',
            child: Column(
              children: [
                NeoTextField(
                  controller: _nameController,
                  labelText: 'Nama toko',
                  prefixIcon: AppIcons.storefront,
                ),
                const SizedBox(height: 12),
                NeoTextField(
                  controller: _addressController,
                  labelText: 'Alamat',
                  prefixIcon: AppIcons.mapPin,
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                NeoTextField(
                  controller: _phoneController,
                  labelText: 'Telepon',
                  prefixIcon: AppIcons.phone,
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Catatan Bawah Struk (Kebijakan / Garansi)',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Catatan ini akan dicetak pada bagian bawah struk/nota pembayaran (contoh: masa garansi servis, syarat klaim, atau kebijakan toko).',
                  style:
                      textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                NeoTextField(
                  key: const Key('receipt_notes_field'),
                  controller: _notesController,
                  labelText: 'Catatan Struk / Garansi',
                  prefixIcon: AppIcons.notepad,
                  hintText:
                      'Contoh: Garansi servis 7 hari. Barang yang sudah dibeli tidak dapat ditukar.',
                  maxLines: 3,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _error!,
                style: textTheme.bodyMedium?.copyWith(color: AppColors.statusDanger),
              ),
            ),
          ThickBottomBorderButton(
            isFullWidth: true,
            isLoading: _saving,
            onPressed: _saving ? null : _save,
            icon: Icon(AppIcons.check, size: 18, color: AppColors.ink900),
            child: const Text('Simpan Pengaturan'),
          ),
        ],
      ),
    );
  }
}
