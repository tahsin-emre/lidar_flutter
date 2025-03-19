// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lidar_flutter/main.dart';
import 'package:lidar_flutter/bloc/scan_cubit.dart';

void main() {
  testWidgets('App başlık testi', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the app has the correct title
    expect(find.text('3D Scanner'), findsOneWidget);
  });

  testWidgets('Anasayfada tarama butonu var mı', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Anasayfada "New Scan" butonunu kontrol et
    expect(find.text('New Scan'), findsOneWidget);
    expect(find.byIcon(Icons.camera), findsOneWidget);
  });

  test('ScanCubit test', () {
    final cubit = ScanCubit();

    // Başlangıç durumu kontrolü
    expect(cubit.state.status, ScanningStatus.notStarted);
    expect(cubit.state.progress, 0.0);
    expect(cubit.state.isScanning, false);

    // Tarama başlatma test
    cubit.startScan();
    expect(cubit.state.status, ScanningStatus.scanning);
    expect(cubit.state.isScanning, true);

    // Taramayı duraklat
    cubit.pauseScan();
    expect(cubit.state.status, ScanningStatus.paused);
    expect(cubit.state.isPaused, true);
  });
}
