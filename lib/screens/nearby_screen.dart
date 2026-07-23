import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../design/colors.dart';
import '../design/typography.dart';
import '../l10n/app_localizations.dart';
import '../services/discovery_service.dart';
import '../services/network_info_service.dart';
import '../widgets/peer_tile.dart';
import '../widgets/radar_pulse.dart';
import 'chat_screen.dart';

/// Discovery screen: scans the LAN and lists devices found, so the user can
/// start a new conversation. Renamed/repurposed from the original
/// device_list_screen — conversation history now lives in ConversationsScreen.
class NearbyScreen extends StatefulWidget {
  const NearbyScreen({super.key});

  @override
  State<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends State<NearbyScreen> {
  final _networkInfo = NetworkInfoService();
  String? _networkName;

  @override
  void initState() {
    super.initState();
    _networkInfo.currentNetworkName().then((name) {
      if (mounted) setState(() => _networkName = name);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final peers = context.watch<DiscoveryService>().peers;

    return Scaffold(
      appBar: AppBar(title: const Text('')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          Text(l10n.navNearby, style: AppTypography.screenTitle),
          const SizedBox(height: 4),
          Text(
            _networkName != null
                ? l10n.nearbySearchingNetwork(_networkName!)
                : l10n.nearbySearchingGeneric,
            style: AppTypography.body,
          ),
          const SizedBox(height: 24),
          const Center(child: RadarPulse()),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              l10n.nearbyDevicesFound(peers.length).toUpperCase(),
              style: AppTypography.eyebrow,
            ),
          ),
          if (peers.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(l10n.nearbyEmpty, style: AppTypography.body),
              ),
            ),
          for (final peer in peers) ...[
            PeerTile(
              peer: peer,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ChatScreen(peerId: peer.id, peerAlias: peer.alias),
                ),
              ),
            ),
            const Divider(color: AppColors.borderSubtle, height: 1),
          ],
        ],
      ),
    );
  }
}
