import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../design/colors.dart';
import '../design/typography.dart';
import '../services/chat_store.dart';
import '../services/device_identity_service.dart';
import '../services/network_info_service.dart';
import '../services/notification_service.dart';
import '../widgets/avatar.dart';
import '../widgets/peer_tile.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _networkInfo = NetworkInfoService();
  String? _networkName;
  int? _storageBytes;

  @override
  void initState() {
    super.initState();
    _networkInfo.currentNetworkName().then((name) {
      if (mounted) setState(() => _networkName = name ?? 'Indisponible');
    });
    context.read<ChatStore>().storageBytesUsed().then((bytes) {
      if (mounted) setState(() => _storageBytes = bytes);
    });
  }

  String _formatBytes(int? bytes) {
    if (bytes == null) return '…';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} Ko';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} Mo';
  }

  Future<void> _editAlias(DeviceIdentityService identity) async {
    final controller = TextEditingController(text: identity.alias);
    final newAlias = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nom de cet appareil'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    if (newAlias != null && newAlias.trim().isNotEmpty) {
      await identity.updateAlias(newAlias);
    }
  }

  @override
  Widget build(BuildContext context) {
    final identity = context.watch<DeviceIdentityService>();
    final notifications = context.watch<NotificationService>();

    return Scaffold(
      appBar: AppBar(title: Text('Settings', style: AppTypography.screenTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: AppColors.panel,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Avatar(id: identity.id, name: identity.alias, diameter: 52),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(identity.alias, style: AppTypography.profileName),
                      const SizedBox(height: 2),
                      Text(
                        'device: ${shortPeerId(identity.id)}',
                        style: AppTypography.monoCaption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.panel,
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _row(
                  label: 'Device Name',
                  value: identity.alias,
                  onTap: () => _editAlias(identity),
                ),
                _divider(),
                _row(label: 'Network', value: _networkName ?? '…'),
                _divider(),
                _switchRow(
                  label: 'Notifications',
                  value: notifications.enabled,
                  onChanged: (v) => notifications.setEnabled(v),
                ),
                _divider(),
                _row(
                  label: 'Storage',
                  value: '${_formatBytes(_storageBytes)} utilisés',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => const Divider(
    color: AppColors.borderSubtle,
    height: 1,
    indent: 16,
    endIndent: 16,
  );

  Widget _row({
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  color: AppColors.text,
                ),
              ),
            ),
            Text(value, style: AppTypography.body),
            if (onTap != null) ...[
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: AppColors.border,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _switchRow({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                color: AppColors.text,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.accent,
          ),
        ],
      ),
    );
  }
}
