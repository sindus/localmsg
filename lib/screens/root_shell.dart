import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../design/colors.dart';
import '../design/typography.dart';
import '../services/chat_store.dart';
import '../services/discovery_service.dart';
import '../widgets/avatar.dart';
import 'chat_screen.dart';
import 'conversations_screen.dart';
import 'nearby_screen.dart';
import 'settings_screen.dart';

/// Mobile: bottom-tab navigation between Messages / Nearby / Settings.
/// Desktop: persistent sidebar (conversations + "Nearby · N" strip) with
/// the selected conversation shown inline — Nearby/Settings are opened as
/// separate windows-ish pages, matching the design's "Add Device" dialog.
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _mobileTabIndex = 0;
  String? _selectedPeerId;
  String? _selectedPeerAlias;

  bool get _isDesktop =>
      Platform.isMacOS || Platform.isWindows || Platform.isLinux;

  @override
  Widget build(BuildContext context) {
    return _isDesktop ? _buildDesktop(context) : _buildMobile(context);
  }

  Widget _buildMobile(BuildContext context) {
    final screens = const [
      ConversationsScreen(),
      NearbyScreen(),
      SettingsScreen(),
    ];
    return Scaffold(
      body: IndexedStack(index: _mobileTabIndex, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _mobileTabIndex,
        onDestinationSelected: (i) => setState(() => _mobileTabIndex = i),
        backgroundColor: AppColors.panel,
        indicatorColor: AppColors.accentSoft,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Messages',
          ),
          NavigationDestination(
            icon: Icon(Icons.wifi_tethering),
            label: 'Nearby',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _buildDesktop(BuildContext context) {
    final discoveredCount = context.watch<DiscoveryService>().peers.length;
    final conversations = context.watch<ChatStore>().conversations;

    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 280,
            decoration: const BoxDecoration(
              border: Border(right: BorderSide(color: AppColors.border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 8, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'NEARBY · $discoveredCount',
                          style: AppTypography.eyebrow,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.add_circle_outline,
                          color: AppColors.accent,
                          size: 20,
                        ),
                        tooltip: 'Ajouter un appareil',
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NearbyScreen(),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.settings_outlined,
                          color: AppColors.textDim,
                          size: 20,
                        ),
                        tooltip: 'Réglages',
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SettingsScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: conversations.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(18),
                          child: Text(
                            'Aucune conversation',
                            style: AppTypography.body,
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          itemCount: conversations.length,
                          itemBuilder: (context, index) {
                            final c = conversations[index];
                            final active = c.peerId == _selectedPeerId;
                            return InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () => setState(() {
                                _selectedPeerId = c.peerId;
                                _selectedPeerAlias = c.alias;
                              }),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 10,
                                ),
                                margin: const EdgeInsets.symmetric(vertical: 2),
                                decoration: BoxDecoration(
                                  color: active
                                      ? AppColors.accentSoft
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    Avatar(
                                      id: c.peerId,
                                      name: c.alias,
                                      diameter: 38,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            c.alias,
                                            style: const TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.text,
                                            ),
                                          ),
                                          Text(
                                            c.lastText,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 12,
                                              color: AppColors.textDim,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _selectedPeerId == null
                ? Center(
                    child: Text(
                      'Sélectionnez une conversation',
                      style: AppTypography.body,
                    ),
                  )
                : ChatScreen(
                    key: ValueKey(_selectedPeerId),
                    peerId: _selectedPeerId!,
                    peerAlias: _selectedPeerAlias!,
                  ),
          ),
        ],
      ),
    );
  }
}
