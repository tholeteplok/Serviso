import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/widgets/neo_card.dart';

class PlatformAdminScreen extends ConsumerStatefulWidget {
  const PlatformAdminScreen({super.key});

  @override
  ConsumerState<PlatformAdminScreen> createState() => _PlatformAdminScreenState();
}

class _PlatformAdminScreenState extends ConsumerState<PlatformAdminScreen> {
  final _client = Supabase.instance.client;
  bool _loading = false;
  List<dynamic> _shops = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchShops();
  }

  Future<void> _fetchShops() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _client.from('shops').select().order('created_at', ascending: false);
      setState(() {
        _shops = res;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _createShop() async {
    final nameCtrl = TextEditingController();
    final slugCtrl = TextEditingController();
    final usernameCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Buat Toko Baru'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nama Toko (ex: Serviso Pusat)'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: slugCtrl,
                decoration: const InputDecoration(labelText: 'Kode Toko (ex: serviso)'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: usernameCtrl,
                decoration: const InputDecoration(labelText: 'Username Pemilik (ex: admin)'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: passwordCtrl,
                decoration: const InputDecoration(labelText: 'Password Pemilik'),
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Buat'),
          ),
        ],
      ),
    );

    if (result != true || !mounted) return;

    setState(() => _loading = true);
    try {
      final res = await _client.functions.invoke(
        'create-shop',
        body: {
          'name': nameCtrl.text.trim(),
          'slug': slugCtrl.text.trim(),
          'adminUsername': usernameCtrl.text.trim(),
          'adminPassword': passwordCtrl.text.trim(),
        },
      );
      if (res.status == 200 || res.status == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Toko berhasil dibuat!')),
          );
        }
        _fetchShops();
      } else {
        throw Exception('Gagal membuat toko: ');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Manajemen Toko (Platform)'),
        actions: [
          IconButton(
            icon: Icon(AppIcons.add),
            onPressed: _createShop,
            tooltip: 'Buat Toko Baru',
          ),
        ],
      ),
      body: _loading && _shops.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _fetchShops,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _shops.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final shop = _shops[index];
                      return NeoCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              shop['name'] ?? '-',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text('Kode Toko: ${shop['slug'] ?? '-'}'),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
