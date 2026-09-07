import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/neo_app_bar.dart';
import '../../../core/widgets/neo_dialog.dart';
import '../../../core/widgets/neo_radio_card_group.dart';
import '../../../core/widgets/neo_text_field.dart';
import '../../../core/widgets/section_card.dart';
import '../../../core/widgets/thick_bottom_border_button.dart';
import '../../auth/controllers/session_controller.dart';
import '../data/settings_repository.dart';
import '../models/app_settings.dart';

class ShopSettingsScreen extends ConsumerStatefulWidget {
  const ShopSettingsScreen({super.key});

  @override
  ConsumerState<ShopSettingsScreen> createState() => _ShopSettingsScreenState();
}

class _ShopSettingsScreenState extends ConsumerState<ShopSettingsScreen> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  String _businessType = 'keduanya';
  String _initialBusinessType = 'keduanya';
  String _serviceMode = 'otomotif';
  bool _loading = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final session = ref.read(sessionProvider).valueOrNull;
    if (session != null) {
      _businessType = session.shopBusinessType;
      _initialBusinessType = session.shopBusinessType;
      _serviceMode = session.shopServiceMode;
      if (session.shopName != null && session.shopName!.isNotEmpty) {
        _nameController.text = session.shopName!;
      }
    }

    final settings = ref.read(settingsProvider).valueOrNull;
    if (settings != null) {
      _applySettings(settings);
    } else {
      _loading = true;
      ref.read(settingsRepositoryProvider).getSettings().then((value) {
        if (mounted) {
          setState(() {
            _loading = false;
            _applySettings(value);
          });
        }
      }).catchError((_) {
        if (mounted) setState(() => _loading = false);
      });
    }
  }

  void _applySettings(AppSettings settings) {
    _nameController.text = settings.shopName;
    _addressController.text = settings.address ?? '';
    _phoneController.text = settings.phone ?? '';
    _notesController.text = settings.receiptNotes ?? '';
    setState(() {
      _businessType = settings.businessType;
      _initialBusinessType = settings.businessType;
      _serviceMode = settings.serviceMode;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onBusinessTypeChanged(String newType) {
    if (newType == _businessType) return;
    setState(() => _businessType = newType);
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Nama toko wajib diisi');
      return;
    }

    if (_businessType == 'barang' && _initialBusinessType != 'barang') {
      final confirmed = await showNeoConfirmDialog(
        context: context,
        title: 'Ubah Jenis Usaha?',
        message:
            'Mengubah ke Jual Barang akan menyembunyikan menu antrian order dan mengalihkan kasir langsung sebagai fokus utama. Data antrian sebelumnya tidak dihapus.',
        confirmLabel: 'Ubah & Simpan',
      );
      if (confirmed != true) return;
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
            businessType: _businessType,
            serviceMode: _serviceMode,
          );
      ref.read(sessionProvider.notifier).updateShopSettings(
            businessType: _businessType,
            serviceMode: _serviceMode,
            shopName: name,
          );
      ref.invalidate(settingsProvider);
      ref.invalidate(sessionProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pengaturan toko berhasil disimpan')),
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
              'Hanya pemilik yang dapat mengubah pengaturan toko.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    if (_loading) {
      return const Scaffold(
        appBar: NeoAppBar(title: 'Pengaturan Toko'),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: const NeoAppBar(title: 'Pengaturan Toko'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SectionCard(
            title: 'Jenis Usaha',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Menentukan menu, alur kerja transaksi, dan istilah yang ditampilkan di seluruh aplikasi.',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                NeoRadioCardGroup<String>(
                  selectedValue: _businessType,
                  onValueChanged: _onBusinessTypeChanged,
                  options: const [
                    NeoRadioOption(
                      value: 'barang',
                      title: 'Jual Barang',
                      subtitle: 'Mode Retail: Fokus pada penjualan kasir langsung dan manajemen stok barang.',
                    ),
                    NeoRadioOption(
                      value: 'jasa',
                      title: 'Jasa',
                      subtitle: 'Mode Jasa: Antrian pesanan/servis umum (laundry, AC, salon, dll).',
                    ),
                    NeoRadioOption(
                      value: 'keduanya',
                      title: 'Barang & Jasa',
                      subtitle: 'Mode Campuran: Cocok untuk bengkel otomotif atau toko dengan perbaikan & retail.',
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_businessType != 'barang') ...[
            const SizedBox(height: 16),
            SectionCard(
              title: 'Mode Jasa',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Menentukan jalur default saat membuat order jasa — dipilih sekali di sini, '
                    'bukan tiap kali bikin order. Toko tetap bisa memasukkan pengecualian sesekali '
                    'lewat opsi alternatif yang muncul di form order.',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  NeoRadioCardGroup<String>(
                    selectedValue: _serviceMode,
                    onValueChanged: (v) => setState(() => _serviceMode = v),
                    options: const [
                      NeoRadioOption(
                        value: 'otomotif',
                        title: 'Otomotif (Kendaraan)',
                        subtitle: 'Target order default berupa plat kendaraan dan jarak tempuh (odometer).',
                      ),
                      NeoRadioOption(
                        value: 'umum',
                        title: 'Umum (Non-Kendaraan)',
                        subtitle: 'Target order default berupa barang/objek umum tanpa nomor plat (mis. AC, laundry, elektronik, dll).',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          SectionCard(
            title: 'Informasi Toko',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NeoTextField(
                  controller: _nameController,
                  labelText: 'Nama Toko *',
                  hintText: 'Nama usaha / bengkel',
                  prefixIcon: AppIcons.storefront,
                ),
                const SizedBox(height: 12),
                NeoTextField(
                  controller: _addressController,
                  labelText: 'Alamat',
                  hintText: 'Alamat lengkap toko',
                  prefixIcon: AppIcons.mapPin,
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                NeoTextField(
                  controller: _phoneController,
                  labelText: 'Nomor Telepon',
                  hintText: '08xxxxxxxxxx',
                  prefixIcon: AppIcons.phone,
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Catatan Struk (Opsional)',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Teks ini akan dicetak di bagian bawah struk pembayaran.',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                NeoTextField(
                  key: const Key('receipt_notes_field'),
                  controller: _notesController,
                  hintText: 'Contoh: Garansi servis 7 hari. Barang yang sudah dibeli tidak dapat ditukar.',
                  prefixIcon: AppIcons.receipt,
                  maxLines: 3,
                ),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(
              _error!,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.statusDanger,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 24),
          ThickBottomBorderButton(
            key: const Key('save_settings_button'),
            onPressed: _saving ? null : _save,
            isFullWidth: true,
            isLoading: _saving,
            child: const Text('Simpan Pengaturan'),
          ),
        ],
      ),
    );
  }
}
