// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
//import 'package:provider/provider.dart';
import 'package:lidar_flutter/main.dart';
import 'package:lidar_flutter/state/scan_state.dart';

void main() {
  testWidgets('App başlık testi', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the app has the correct title
    expect(find.text('3D Scanner App'), findsOneWidget);
  });

  testWidgets('Anasayfada tarama butonu var mı', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Anasayfada "New Scan" butonunu kontrol et
    expect(find.text('New Scan'), findsOneWidget);
    expect(find.byIcon(Icons.camera), findsOneWidget);
  });

  test('ScanState test', () {
    final scanState = ScanState();

    // Başlangıç durumu kontrolü
    expect(scanState.status, ScanningStatus.notStarted);
    expect(scanState.progress, 0.0);
    expect(scanState.isScanning, false);

    // Tarama başlatma test
    scanState.startScan();
    expect(scanState.status, ScanningStatus.scanning);
    expect(scanState.isScanning, true);

    // Taramayı duraklat
    scanState.pauseScan();
    expect(scanState.status, ScanningStatus.paused);
    expect(scanState.isPaused, true);
  });
}
