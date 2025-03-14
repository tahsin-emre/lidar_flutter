import 'package:get_it/get_it.dart';
import 'package:lidar_flutter/product/services/scanner_service.dart';
import 'package:lidar_flutter/product/services/model_service.dart';
import 'package:lidar_flutter/feature/scanner/cubit/scanner_cubit.dart';

final locator = GetIt.instance;

void setupLocator() {
  // Services
  locator.registerLazySingleton<ScannerService>(() => ScannerService());
  locator.registerLazySingleton<ModelService>(() => ModelService());

  // Cubits
  locator.registerFactory<ScannerCubit>(() => ScannerCubit());
}
