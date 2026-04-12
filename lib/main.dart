import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'bluetooth/bluetooth_service.dart';
import 'screens/home_screen.dart';
import 'voice/voice_commands.dart';

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

class SmartRoverApp extends StatelessWidget {
  final BluetoothService bluetoothService;

  const SmartRoverApp({super.key, required this.bluetoothService});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: bluetoothService),
        ChangeNotifierProxyProvider<BluetoothService, VoiceCommandService>(
          create: (_) => VoiceCommandService(bluetoothService),
          update: (_, bt, prev) => prev ?? VoiceCommandService(bt),
        ),
      ],
      child: MaterialApp(
        title: 'Smart Rover',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: const ColorScheme.dark(
            surface: Color(0xFF1A1A1A),
            onSurface: Colors.white,
            primary: Color(0xFF3B7BE8),
            onPrimary: Colors.white,
          ),
          scaffoldBackgroundColor: const Color(0xFF161616),
          fontFamily: 'Roboto',
          useMaterial3: true,
          splashFactory: NoSplash.splashFactory,
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
