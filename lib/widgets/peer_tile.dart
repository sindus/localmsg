import 'package:flutter/material.dart';

import '../design/colors.dart';
import '../design/typography.dart';
import '../models/peer.dart';

/// Short mono-style identifier derived from a peer's UUID, e.g. "7F:3A:9C".
String shortPeerId(String id) {
  final hex = id.replaceAll('-', '').toUpperCase();
  final chars = hex.substring(0, hex.length < 6 ? hex.length : 6);
  return chars
      .replaceAllMapped(RegExp('.{2}'), (m) => '${m.group(0)}:')
      .replaceAll(RegExp(r':$'), '');
}

String deviceTypeFor(String platform) {
  switch (platform) {
    case 'android':
    case 'ios':
      return 'Mobile';
    default:
      return 'Desktop';
  }
}

class PeerTile extends StatelessWidget {
  final Peer peer;
  final VoidCallback onTap;

  const PeerTile({super.key, required this.peer, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.panel2,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.accent, width: 2),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(peer.alias, style: AppTypography.listTitle),
                  const SizedBox(height: 2),
                  Text(
                    '${deviceTypeFor(peer.platform)} · ${shortPeerId(peer.id)}',
                    style: AppTypography.monoCaption,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
