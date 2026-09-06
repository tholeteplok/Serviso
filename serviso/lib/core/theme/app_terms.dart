import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/controllers/session_controller.dart';

/// Centralized dynamic terms resolver based on shop business_type:
/// - 'barang' (Retail)
/// - 'jasa' (General Services: Laundry, AC, Salon, Electronics, etc.)
/// - 'keduanya' (Automotive Workshop / Multi-service)
class AppTerms {
  const AppTerms._({
    required this.businessType,
    required this.targetLabel,
    required this.targetHint,
    required this.complaintLabel,
    required this.complaintHint,
    required this.woListLabel,
    required this.hasOdometer,
    required this.manualTargetLabel,
    required this.manualTargetHint,
    required this.registeredTargetTab,
    required this.manualTargetTab,
    required this.partNoun,
    required this.addPartLabel,
    required this.editPartLabel,
    required this.detailPartLabel,
    required this.emptyPartTitle,
    required this.emptyPartSubtitle,
    required this.deletePartTitle,
    required this.deletePartConfirm,
  });

  final String businessType;
  final String targetLabel;
  final String targetHint;
  final String complaintLabel;
  final String complaintHint;
  final String woListLabel;
  final bool hasOdometer;

  // Work Order Target Dinamis
  final String manualTargetLabel;
  final String manualTargetHint;
  final String registeredTargetTab;
  final String manualTargetTab;

  // Inventori Universal (Barang / Produk)
  final String partNoun;
  final String addPartLabel;
  final String editPartLabel;
  final String detailPartLabel;
  final String emptyPartTitle;
  final String emptyPartSubtitle;
  final String deletePartTitle;
  final String deletePartConfirm;

  factory AppTerms.forBusinessType(String? businessType) {
    switch (businessType) {
      case 'jasa':
        return const AppTerms._(
          businessType: 'jasa',
          targetLabel: 'Objek / Layanan',
          targetHint: 'mis. AC Split Kamar 1, Baju 5kg, iPhone 13, dll',
          complaintLabel: 'Instruksi / Catatan Layanan',
          complaintHint: 'Tuliskan catatan pengerjaan atau permintaan pelanggan...',
          woListLabel: 'Antrian Pesanan',
          hasOdometer: false,
          manualTargetLabel: 'Objek / Layanan',
          manualTargetHint: 'mis. AC Split Kamar 1, Baju 5kg, iPhone 13, dll',
          registeredTargetTab: 'Data Terdaftar',
          manualTargetTab: 'Tulis Manual',
          partNoun: 'Barang',
          addPartLabel: 'Tambah Barang',
          editPartLabel: 'Ubah Barang',
          detailPartLabel: 'Detail Barang',
          emptyPartTitle: 'Belum ada barang di inventori',
          emptyPartSubtitle: 'Tambahkan barang atau perlengkapan untuk mencatat stok toko.',
          deletePartTitle: 'Hapus Barang',
          deletePartConfirm: 'Hapus barang ini beserta seluruh kartu stoknya? Tindakan tidak dapat dibatalkan.',
        );
      case 'barang':
        return const AppTerms._(
          businessType: 'barang',
          targetLabel: 'Barang / Layanan',
          targetHint: 'Nama barang atau rincian pesanan...',
          complaintLabel: 'Catatan Transaksi',
          complaintHint: 'Catatan tambahan...',
          woListLabel: 'Pesanan',
          hasOdometer: false,
          manualTargetLabel: 'Barang / Layanan',
          manualTargetHint: 'Nama barang atau rincian pesanan...',
          registeredTargetTab: 'Data Terdaftar',
          manualTargetTab: 'Tulis Manual',
          partNoun: 'Barang',
          addPartLabel: 'Tambah Barang',
          editPartLabel: 'Ubah Barang',
          detailPartLabel: 'Detail Barang',
          emptyPartTitle: 'Belum ada barang di inventori',
          emptyPartSubtitle: 'Tambahkan barang untuk mulai mencatat stok toko Anda.',
          deletePartTitle: 'Hapus Barang',
          deletePartConfirm: 'Hapus barang ini beserta seluruh kartu stoknya? Tindakan tidak dapat dibatalkan.',
        );
      case 'keduanya':
      default:
        return const AppTerms._(
          businessType: 'keduanya',
          targetLabel: 'Kendaraan',
          targetHint: 'Cari plat nomor...',
          complaintLabel: 'Keluhan',
          complaintHint: 'Tuliskan keluhan atau kendala kendaraan...',
          woListLabel: 'Antrian Servis',
          hasOdometer: true,
          manualTargetLabel: 'Layanan / Objek Servis',
          manualTargetHint: 'mis. Servis Dinamo, Las Knalpot, Genset, AC Toko, dll',
          registeredTargetTab: 'Kendaraan Terdaftar',
          manualTargetTab: 'Tulis Manual',
          partNoun: 'Barang',
          addPartLabel: 'Tambah Barang',
          editPartLabel: 'Ubah Barang',
          detailPartLabel: 'Detail Barang',
          emptyPartTitle: 'Belum ada barang di inventori',
          emptyPartSubtitle: 'Tambahkan barang untuk mulai mencatat stok toko Anda.',
          deletePartTitle: 'Hapus Barang',
          deletePartConfirm: 'Hapus barang ini beserta seluruh kartu stoknya? Tindakan tidak dapat dibatalkan.',
        );
    }
  }
}

final appTermsProvider = Provider<AppTerms>((ref) {
  final session = ref.watch(sessionProvider).valueOrNull;
  return AppTerms.forBusinessType(session?.shopBusinessType);
});
