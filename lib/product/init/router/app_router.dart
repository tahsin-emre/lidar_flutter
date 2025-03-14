import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lidar_flutter/feature/home/view/home_view.dart';
import 'package:lidar_flutter/feature/scanner/view/scanner_view.dart';
import 'package:lidar_flutter/feature/model_viewer/view/model_viewer_view.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> rootNavigatorKey =
      GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeView(),
      ),
      GoRoute(
        path: '/scanner',
        name: 'scanner',
        builder: (context, state) => const ScannerView(),
      ),
      GoRoute(
        path: '/model-viewer',
        name: 'model-viewer',
        builder: (context, state) {
          final modelPath = state.uri.queryParameters['modelPath'] ?? '';
          final modelName = state.uri.queryParameters['modelName'] ?? 'Model';
          return ModelViewerView(
            modelPath: modelPath,
            modelName: modelName,
          );
        },
      ),
    ],
  );
}
