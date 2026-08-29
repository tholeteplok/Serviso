import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/section_card.dart';
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
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
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
      setState(() => _error = 'Pengaturan gagal diperbarui');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = AppTypography.textTheme();
    final isAdmin = ref.watch(isAdminProvider);

    if (!isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pengaturan Toko')),
        body: const Center(
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
      appBar: AppBar(title: const Text('Pengaturan Toko')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Profil toko tampil di struk pembayaran',
            style: textTheme.bodyMedium?.copyWith(color: AppColors.inkMuted),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Informasi Bengkel',
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nama toko'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: 'Alamat'),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Telepon'),
                  keyboardType: TextInputType.phone,
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
                style: textTheme.bodyMedium?.copyWith(color: AppColors.action),
              ),
            ),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: Icon(AppIcons.check, size: 18),
              onPressed: _saving ? null : _save,
              label: _saving
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.surface,
                      ),
                    )
                  : const Text('Simpan Pengaturan'),
            ),
          ),
        ],
      ),
    );
  }
}
