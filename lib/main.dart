import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'bluetooth/bluetooth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF111111),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  final bluetoothService = BluetoothService();
  try {
    await bluetoothService.init();
    await bluetoothService.requestPermissions();
  } catch (e) {
    debugPrint('Startup Bluetooth initialization error: $e');
  }

  runApp(SmartRoverApp(bluetoothService: bluetoothService));
}
