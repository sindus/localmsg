import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../design/colors.dart';
import '../design/typography.dart';
import '../l10n/app_localizations.dart';
import '../services/chat_store.dart';
import '../services/device_identity_service.dart';
import '../services/locale_service.dart';
import '../services/network_info_service.dart';
import '../services/notification_service.dart';
import '../widgets/avatar.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/peer_tile.dart';
import 'language_screen.dart';

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
      if (mounted) setState(() => _networkName = name);
    });
    context.read<ChatStore>().storageBytesUsed().then((bytes) {
      if (mounted) setState(() => _storageBytes = bytes);
    });
  }

  String _formatBytes(AppLocalizations l10n, int? bytes) {
    if (bytes == null) return '…';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(0)} ${l10n.storageUnitKB}';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} ${l10n.storageUnitMB}';
  }

  Future<void> _editAlias(
    AppLocalizations l10n,
    DeviceIdentityService identity,
  ) async {
    final controller = TextEditingController(text: identity.alias);
    final newAlias = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.renameDialogTitle),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    if (newAlias != null && newAlias.trim().isNotEmpty) {
      await identity.updateAlias(newAlias);
    }
  }

  Future<void> _deleteAllConversations(AppLocalizations l10n) async {
    final confirmed = await confirmDelete(
      context,
      title: l10n.deleteAllTitle,
      body: l10n.deleteAllBody,
    );
    if (!confirmed || !mounted) return;
    final chatStore = context.read<ChatStore>();
    await chatStore.deleteAllConversations();
    final bytes = await chatStore.storageBytesUsed();
    if (mounted) setState(() => _storageBytes = bytes);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final identity = context.watch<DeviceIdentityService>();
    final notifications = context.watch<NotificationService>();
    final localeService = context.watch<LocaleService>();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navSettings, style: AppTypography.screenTitle),
      ),
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
                        l10n.settingsDeviceIdLabel(shortPeerId(identity.id)),
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
                  label: l10n.settingsDeviceName,
                  value: identity.alias,
                  onTap: () => _editAlias(l10n, identity),
                ),
                _divider(),
                _row(
                  label: l10n.settingsLanguage,
                  value: languageDisplayName(localeService.locale),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LanguageScreen()),
                  ),
                ),
                _divider(),
                _row(
                  label: l10n.settingsNetwork,
                  value: _networkName ?? l10n.settingsUnavailable,
                ),
                _divider(),
                _switchRow(
                  label: l10n.settingsNotifications,
                  value: notifications.enabled,
                  onChanged: (v) => notifications.setEnabled(v),
                ),
                _divider(),
                _row(
                  label: l10n.settingsStorage,
                  value: l10n.settingsStorageUsed(
                    _formatBytes(l10n, _storageBytes),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              color: AppColors.panel,
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => _deleteAllConversations(l10n),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Text(
                  l10n.deleteAllSettingsLabel,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    color: Colors.redAccent,
                  ),
                ),
              ),
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
