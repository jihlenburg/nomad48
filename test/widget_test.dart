import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nomad48/models/cached_device.dart';
import 'package:nomad48/main.dart';

void main() {
  setUp(() async {
    final dir = Directory.systemTemp.createTempSync('nomad48_test_');
    Hive.init(dir.path);
    Hive.registerAdapter(CachedDeviceIdentificationAdapter());
    await Hive.openBox<CachedDeviceIdentification>('device_cache');
    await Hive.openBox<bool>('expansion_state');
  });

  tearDown(() async {
    await Hive.close();
  });

  testWidgets('App renders NOMAD48 title', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('NOMAD48'), findsOneWidget);
  });
}
