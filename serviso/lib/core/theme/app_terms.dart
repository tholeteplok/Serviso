import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/controllers/session_controller.dart';

/// Dua sumbu independen — jangan digabung jadi satu keputusan:
/// - [businessType] ('barang' | 'jasa' | 'keduanya'): apakah toko jual barang,
///   sediakan jasa, atau dua-duanya. Mempengaruhi istilah NAV/INVENTORI —
///   bukan sifat pekerjaan servisnya.
/// - [serviceMode] ('otomotif' | 'umum'): apakah pekerjaan jasa toko itu
///   berbasis kendaraan atau tidak. Mempengaruhi field TARGET SERVIS.
///   Contoh: bengkel servis murni tanpa jual sparepart = businessType 'jasa'
///   + serviceMode 'otomotif' — BUKAN otomatis non-kendaraan hanya karena
///   tidak jual barang.
class AppTerms {
  const AppTerms._({
    required this.businessType,
    required this.serviceMode,
    required this.targetLabel,
    required this.targetHint,
    required this.complaintLabel,
    required this.complaintHint,
    required this.hasOdometer,
    required this.manualTargetLabel,
    required this.manualTargetHint,
    required this.registeredTargetTab,
    required this.manualTargetTab,
    required this.woListLabel,
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
  final String serviceMode;

  // Ditentukan oleh serviceMode
  final String targetLabel;
  final String targetHint;
  final String complaintLabel;
  final String complaintHint;
  final bool hasOdometer;
  final String manualTargetLabel;
  final String manualTargetHint;
  final String registeredTargetTab;
  final String manualTargetTab;

  // Ditentukan oleh businessType
  final String woListLabel;
  final String partNoun;
  final String addPartLabel;
  final String editPartLabel;
  final String detailPartLabel;
  final String emptyPartTitle;
  final String emptyPartSubtitle;
  final String deletePartTitle;
  final String deletePartConfirm;

  /// Jalur mana yang jadi tampilan DEFAULT di Wizard WO — ditentukan murni
  /// dari [serviceMode] (keputusan sekali di Pengaturan Toko), bukan pilihan
  /// yang diulang tiap transaksi.
  bool get primaryPathIsVehicle => serviceMode == 'otomotif';

  /// Label link escape-hatch di bawah jalur utama — de-emphasized, bukan
  /// pilihan setara seperti toggle. Selalu ditawarkan (kecuali toko 'barang'
  /// murni, yang tidak pernah masuk ke Wizard WO sama sekali) karena kombinasi
  /// apa pun tetap bisa punya kasus tepi di luar mode default toko.
  String? get alternatePathLinkLabel {
    if (businessType == 'barang') return null;
    return primaryPathIsVehicle
        ? '+ Servis tanpa kendaraan terdaftar'
        : '+ Ada data kendaraan terdaftar?';
  }

  factory AppTerms.forShop({String? businessType, String? serviceMode}) {
    final resolvedBusinessType =
        (businessType == 'barang' || businessType == 'jasa') ? businessType! : 'keduanya';
    final resolvedServiceMode = serviceMode == 'umum' ? 'umum' : 'otomotif';
    final isOtomotif = resolvedServiceMode == 'otomotif';

    // --- Sumbu 1: field target servis, ikut serviceMode ---
    final targetLabel = isOtomotif ? 'Kendaraan' : 'Objek / Layanan';
    final targetHint = isOtomotif
        ? 'Cari plat nomor...'
        : 'mis. AC Split Kamar 1, Baju 5kg, iPhone 13, dll';
    final complaintLabel = isOtomotif ? 'Keluhan' : 'Instruksi / Catatan Layanan';
    final complaintHint = isOtomotif
        ? 'Tuliskan keluhan atau kendala kendaraan...'
        : 'Tuliskan catatan pengerjaan atau permintaan pelanggan...';
    final manualTargetLabel = isOtomotif ? 'Layanan / Objek Servis' : 'Objek / Layanan';
    final manualTargetHint = isOtomotif
        ? 'mis. Servis Dinamo, Las Knalpot, Genset, AC Toko, dll'
        : 'mis. AC Split Kamar 1, Baju 5kg, iPhone 13, dll';
    final registeredTargetTab = isOtomotif ? 'Kendaraan Terdaftar' : 'Data Terdaftar';

    // --- Sumbu 2: istilah nav/inventori, ikut businessType ---
    String woListLabel;
    switch (resolvedBusinessType) {
      case 'jasa':
        woListLabel = 'Antrian Pesanan';
        break;
      case 'barang':
        woListLabel = 'Pesanan';
        break;
      default:
        woListLabel = 'Antrian Servis';
    }

    return AppTerms._(
      businessType: resolvedBusinessType,
      serviceMode: resolvedServiceMode,
      targetLabel: targetLabel,
      targetHint: targetHint,
      complaintLabel: complaintLabel,
      complaintHint: complaintHint,
      hasOdometer: isOtomotif,
      manualTargetLabel: manualTargetLabel,
      manualTargetHint: manualTargetHint,
      registeredTargetTab: registeredTargetTab,
      manualTargetTab: 'Tulis Manual',
      woListLabel: woListLabel,
      partNoun: 'Barang',
      addPartLabel: 'Tambah Barang',
      editPartLabel: 'Ubah Barang',
      detailPartLabel: 'Detail Barang',
      emptyPartTitle: 'Belum ada barang di inventori',
      emptyPartSubtitle: 'Tambahkan barang atau perlengkapan untuk mencatat stok toko.',
      deletePartTitle: 'Hapus Barang',
      deletePartConfirm:
          'Hapus barang ini beserta seluruh kartu stoknya? Tindakan tidak dapat dibatalkan.',
    );
  }

  /// Backward-compatible factory method for existing callers
  factory AppTerms.forBusinessType(String? businessType, [String? serviceMode]) {
    return AppTerms.forShop(businessType: businessType, serviceMode: serviceMode);
  }
}

final appTermsProvider = Provider<AppTerms>((ref) {
  final session = ref.watch(sessionProvider).valueOrNull;
  return AppTerms.forShop(
    businessType: session?.shopBusinessType,
    serviceMode: session?.shopServiceMode,
  );
});
