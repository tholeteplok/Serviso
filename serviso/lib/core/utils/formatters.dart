import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

bool _localeReady = false;

void _ensureIdLocale() {
  if (_localeReady) return;
  initializeDateFormatting('id_ID');
  _localeReady = true;
}

String rupiah(num value) {
  final formatted = NumberFormat('#,##0', 'id_ID').format(value.abs());
  return value < 0 ? '-Rp$formatted' : 'Rp$formatted';
}

String dateTimeId(DateTime value) {
  _ensureIdLocale();
  return DateFormat('d MMM yyyy, HH.mm', 'id_ID').format(value);
}

String dateShortId(DateTime value) {
  _ensureIdLocale();
  return DateFormat('d MMM yyyy', 'id_ID').format(value);
}

String timeId(DateTime value) {
  _ensureIdLocale();
  return DateFormat('HH.mm', 'id_ID').format(value);
}

String plate(String raw) =>
    raw.trim().replaceAll(RegExp(r'\s+'), ' ').toUpperCase();
