import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum BtConnectionState { disconnected, connecting, connected }

enum RobotMode { manual, obstacle, follow }

class BluetoothService extends ChangeNotifier {
  static const String cmdForward = 'U';
  static const String cmdBackward = 'D';
  static const String cmdLeft = 'L';
  static const String cmdRight = 'R';
  static const String cmdStop = 'S';
  static const String cmdModeManual = 'MODE_MANUAL';
  static const String cmdModeObstacle = 'MODE_OBSTACLE';
  static const String cmdModeFollow = 'MODE_FOLLOW';
  static const String cmdReset = 'RESET';
  static const String cmdPowerOn = 'POWER_ON';
  static const String cmdPowerOff = 'POWER_OFF';

  final FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;
  BluetoothConnection? _connection;

  BtConnectionState _connectionState = BtConnectionState.disconnected;
  RobotMode _currentMode = RobotMode.manual;

  List<BluetoothDevice> _bondedDevices = [];
  final List<BluetoothDiscoveryResult> _discoveredDevices = [];
  BluetoothDevice? _connectedDevice;

  // Custom aliases map
  late SharedPreferences _prefs;
  bool _prefsReady = false;
  Map<String, String> _aliases = {};

  StreamSubscription<BluetoothDiscoveryResult>? _discoverySubscription;
  bool _isDiscovering = false;

  // Initialization
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _prefsReady = true;
    _loadAliases();
  }

  void _loadAliases() {
    if (!_prefsReady) {
      return;
    }
    final keys = _prefs.getKeys();
    _aliases = {};
    for (var k in keys) {
      if (k.startsWith('alias_')) {
        _aliases[k.replaceFirst('alias_', '')] = _prefs.getString(k) ?? '';
      }
    }
    notifyListeners();
  }

  String getDeviceName(BluetoothDevice d) {
    return _aliases[d.address] ?? d.name ?? 'Unknown Device';
  }

  Future<void> renameDevice(String address, String newName) async {
    if (!_prefsReady) {
      if (newName.isEmpty) {
        _aliases.remove(address);
      } else {
        _aliases[address] = newName;
      }
      notifyListeners();
      return;
    }

    if (newName.isEmpty) {
      _aliases.remove(address);
      await _prefs.remove('alias_$address');
    } else {
      _aliases[address] = newName;
      await _prefs.setString('alias_$address', newName);
    }
    notifyListeners();
  }

  // Getters
  BtConnectionState get connectionState => _connectionState;
  RobotMode get currentMode => _currentMode;
  bool get isConnected => _connectionState == BtConnectionState.connected;
  bool get isConnecting => _connectionState == BtConnectionState.connecting;
  BluetoothDevice? get connectedDevice => _connectedDevice;
  List<BluetoothDevice> get bondedDevices => List.unmodifiable(_bondedDevices);
  List<BluetoothDiscoveryResult> get discoveredDevices =>
      List.unmodifiable(_discoveredDevices);
  bool get isDiscovering => _isDiscovering;

  // Permissions
  Future<bool> requestPermissions() async {
    final statuses = await [
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.location,
      Permission.microphone,
    ].request();

    return statuses.values.every(
      (s) => s == PermissionStatus.granted || s == PermissionStatus.limited,
    );
  }

  // Device discovery
  Future<void> loadBondedDevices() async {
    try {
      _bondedDevices = await _bluetooth.getBondedDevices();
      notifyListeners();
    } catch (e) {
      debugPrint('BluetoothService.loadBondedDevices error: $e');
    }
  }

  Future<void> startDiscovery() async {
    await loadBondedDevices();
    _discoveredDevices.clear();
    _isDiscovering = true;
    notifyListeners();

    _discoverySubscription?.cancel();
    _discoverySubscription = _bluetooth.startDiscovery().listen(
      (result) {
        final idx = _discoveredDevices.indexWhere(
          (r) => r.device.address == result.device.address,
        );
        if (idx >= 0) {
          _discoveredDevices[idx] = result;
        } else {
          _discoveredDevices.add(result);
        }
        notifyListeners();
      },
      onDone: () {
        _isDiscovering = false;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('BluetoothService.startDiscovery error: $e');
        _isDiscovering = false;
        notifyListeners();
      },
    );
  }

  void stopDiscovery() {
    _discoverySubscription?.cancel();
    _isDiscovering = false;
    notifyListeners();
  }

  // Connection
  Future<void> connectToDevice(BluetoothDevice device) async {
    if (_connectionState == BtConnectionState.connecting) return;
    if (_isDiscovering) {
      stopDiscovery();
    }

    _connectionState = BtConnectionState.connecting;
    notifyListeners();

    try {
      final conn = await BluetoothConnection.toAddress(device.address);
      _connection = conn;
      _connectedDevice = device;
      _connectionState = BtConnectionState.connected;
      notifyListeners();

      conn.input?.listen(
        null,
        onDone: () => _onDisconnected(),
        onError: (e) {
          debugPrint('BluetoothService.connection stream error: $e');
          _onDisconnected();
        },
      );
    } catch (e) {
      debugPrint('BluetoothService.connect error: $e');
      _connectionState = BtConnectionState.disconnected;
      notifyListeners();
    }
  }

  Future<void> disconnect() async {
    try {
      await _connection?.finish();
    } catch (_) {}
    _onDisconnected();
  }

  void _onDisconnected() {
    _connection = null;
    _connectedDevice = null;
    _connectionState = BtConnectionState.disconnected;
    notifyListeners();
  }

  // Commands
  Future<void> sendCommand(String command) async {
    debugPrint('BluetoothService.sendCommand request: command=$command');

    if (_connection == null) {
      debugPrint(
        'BluetoothService.sendCommand dropped: command=$command reason=no_connection',
      );
      return;
    }
    if (!_connection!.isConnected) {
      debugPrint(
        'BluetoothService.sendCommand dropped: command=$command reason=socket_not_connected',
      );
      return;
    }

    final deviceName =
        _connectedDevice?.name ?? _connectedDevice?.address ?? 'unknown';

    try {
      _connection!.output.add(Uint8List.fromList(utf8.encode('$command\n')));
      await _connection!.output.allSent;
      debugPrint(
        'BluetoothService.sendCommand sent: command=$command device=$deviceName',
      );
    } catch (e) {
      debugPrint(
        'BluetoothService.sendCommand failed: command=$command error=$e',
      );
      _onDisconnected();
    }
  }

  Future<void> setMode(RobotMode mode) async {
    debugPrint('BluetoothService.setMode: mode=$mode');
    _currentMode = mode;
    switch (mode) {
      case RobotMode.manual:
        await sendCommand(cmdModeManual);
      case RobotMode.obstacle:
        await sendCommand(cmdModeObstacle);
      case RobotMode.follow:
        await sendCommand(cmdModeFollow);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _discoverySubscription?.cancel();
    _connection?.finish();
    super.dispose();
  }
}
