import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'constants/app_constants.dart';
import 'models/cached_device.dart';
import 'screens/home_screen.dart';
import 'screens/nfc_screen.dart';
import 'services/theme_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(CachedDeviceIdentificationAdapter());
  await Hive.openBox<CachedDeviceIdentification>(HiveBoxNames.deviceCache);
  await Hive.openBox<bool>(HiveBoxNames.expansionState);
  await Hive.openBox<int>(HiveBoxNames.settings);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService.instance,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'NOMAD48',
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeMode,
          home: const MainScreen(),
        );
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _themeService = ThemeService.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NOMAD48'),
        actions: [
          ValueListenableBuilder<ThemeMode>(
            valueListenable: _themeService,
            builder: (context, mode, _) {
              return IconButton(
                icon: Icon(_themeService.icon),
                tooltip: 'Theme: ${_themeService.label}',
                onPressed: _themeService.cycle,
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.bluetooth), text: 'BLE'),
            Tab(icon: Icon(Icons.nfc), text: 'NFC'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          HomeScreen(),
          NfcScreen(),
        ],
      ),
    );
  }
}
