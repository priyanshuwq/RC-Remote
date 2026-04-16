import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'bluetooth/bluetooth_service.dart';
import 'voice/voice_commands.dart';
import 'screens/home_screen.dart';

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
