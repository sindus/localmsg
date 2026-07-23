import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/root_shell.dart';
import 'services/chat_repository.dart';
import 'services/chat_server.dart';
import 'services/chat_store.dart';
import 'services/device_identity_service.dart';
import 'services/discovery_service.dart';
import 'services/notification_service.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final identity = DeviceIdentityService();
  await identity.load();

  final chatRepository = ChatRepository();
  await chatRepository.init();

  final chatStore = ChatStore(chatRepository);
  chatStore.loadSummaries();

  final notificationService = NotificationService();
  await notificationService.init();

  final chatServer = ChatServer(
    chatStore: chatStore,
    notificationService: notificationService,
  );
  await chatServer.start();

  final discovery = DiscoveryService(
    identity: identity,
    servicePort: () => chatServer.port,
  );
  await discovery.start();

  runApp(
    LocalMsgApp(
      identity: identity,
      discovery: discovery,
      chatStore: chatStore,
      notificationService: notificationService,
    ),
  );
}

class LocalMsgApp extends StatelessWidget {
  final DeviceIdentityService identity;
  final DiscoveryService discovery;
  final ChatStore chatStore;
  final NotificationService notificationService;

  const LocalMsgApp({
    super.key,
    required this.identity,
    required this.discovery,
    required this.chatStore,
    required this.notificationService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: identity),
        ChangeNotifierProvider.value(value: discovery),
        ChangeNotifierProvider.value(value: chatStore),
        ChangeNotifierProvider.value(value: notificationService),
      ],
      child: MaterialApp(
        title: 'LocalMsg',
        theme: buildAppTheme(),
        darkTheme: buildAppTheme(),
        themeMode: ThemeMode.dark,
        home: const RootShell(),
      ),
    );
  }
}
