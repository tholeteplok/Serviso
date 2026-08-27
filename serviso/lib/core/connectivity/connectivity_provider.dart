import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final connectivityResultProvider =
    StreamProvider.autoDispose<ConnectivityResult>((ref) {
  final connectivity = Connectivity();
  return connectivity.onConnectivityChanged
      .map((list) => list.isEmpty ? ConnectivityResult.none : list.first);
});

final isOfflineProvider = Provider.autoDispose<bool>((ref) {
  final result = ref.watch(connectivityResultProvider);
  return result.when(
    data: (value) => value == ConnectivityResult.none,
    loading: () => false,
    error: (error, stack) => false,
  );
});
