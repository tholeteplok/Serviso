import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/connectivity/connectivity_provider.dart';

class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOffline = ref.watch(isOfflineProvider);
    if (!isOffline) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      color: Colors.orange.shade700,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off, color: Colors.white, size: 16),
          SizedBox(width: 8),
          Text(
            'Offline — perubahan tersimpan saat daring',
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
