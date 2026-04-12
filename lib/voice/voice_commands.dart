import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../bluetooth/bluetooth_service.dart';

class VoiceCommandService extends ChangeNotifier {
  final BluetoothService _btService;
  final SpeechToText _speech = SpeechToText();

  bool _isListening = false;
  bool _isAvailable = false;
  bool _commandProcessed = false;

  String _lastWords = '';
  String _statusMessage = '';

  Timer? _actionTimer;

  VoiceCommandService(this._btService);

  bool get isListening => _isListening;
  bool get isAvailable => _isAvailable;
  String get lastWords => _lastWords;
  String get statusMessage => _statusMessage;

  static const Map<String, String> _voiceMap = {
    'forward': BluetoothService.cmdForward,
    'go forward': BluetoothService.cmdForward,
    'move forward': BluetoothService.cmdForward,
    'backward': BluetoothService.cmdBackward,
    'go backward': BluetoothService.cmdBackward,
    'move backward': BluetoothService.cmdBackward,
    'reverse': BluetoothService.cmdBackward,
    'left': BluetoothService.cmdLeft,
    'turn left': BluetoothService.cmdLeft,
    'go left': BluetoothService.cmdLeft,
    'right': BluetoothService.cmdRight,
    'turn right': BluetoothService.cmdRight,
    'go right': BluetoothService.cmdRight,
    'stop': BluetoothService.cmdStop,
    'halt': BluetoothService.cmdStop,
    'freeze': BluetoothService.cmdStop,
  };

  static const Map<String, RobotMode> _modeMap = {
    'manual': RobotMode.manual,
    'manual mode': RobotMode.manual,
    'obstacle': RobotMode.obstacle,
    'obstacle mode': RobotMode.obstacle,
    'avoid': RobotMode.obstacle,
    'obstacle avoidance': RobotMode.obstacle,
    'follow': RobotMode.follow,
    'follow mode': RobotMode.follow,
    'follow me': RobotMode.follow,
  };

  static final List<MapEntry<String, String>> _voiceEntriesBySpecificity =
      _voiceMap.entries.toList()
        ..sort((a, b) => b.key.length.compareTo(a.key.length));

  static final List<MapEntry<String, RobotMode>> _modeEntriesBySpecificity =
      _modeMap.entries.toList()
        ..sort((a, b) => b.key.length.compareTo(a.key.length));

  Future<void> initialise() async {
    try {
      _isAvailable = await _speech.initialize(
        onStatus: (status) {
          _statusMessage = status;
          if (status == 'notListening' || status == 'done') {
            _isListening = false;
          }
          notifyListeners();
        },
        onError: (err) {
          _statusMessage = err.errorMsg;
          _isListening = false;
          notifyListeners();
        },
      );
    } catch (e) {
      debugPrint('VoiceCommandService.initialise error: $e');
      _statusMessage = 'Voice unavailable';
      _isAvailable = false;
      _isListening = false;
    }
    notifyListeners();
  }

  Future<void> startListening() async {
    if (!_isAvailable) {
      await initialise();
    }
    if (!_isAvailable || _isListening) return;

    _isListening = true;
    _commandProcessed = false;
    _lastWords = '';
    _statusMessage = '';
    _actionTimer?.cancel();
    debugPrint('VoiceCommandService.startListening: started');
    notifyListeners();

    try {
      await _speech.listen(
        onResult: (result) {
          _lastWords = result.recognizedWords.toLowerCase().trim();
          notifyListeners();

          if (result.finalResult && !_commandProcessed) {
            _commandProcessed = true;
            unawaited(_speech.stop());
            _isListening = false;
            debugPrint(
              'VoiceCommandService.startListening: final_words="$_lastWords"',
            );
            _processWords(_lastWords);
            notifyListeners();
          }
        },
        listenFor: const Duration(seconds: 8),
        pauseFor: const Duration(seconds: 2),
        localeId: 'en_US',
      );
    } catch (e) {
      debugPrint('VoiceCommandService.startListening error: $e');
      _statusMessage = 'Listening failed';
      _isListening = false;
      notifyListeners();
    }
  }

  Future<void> stopListening() async {
    _commandProcessed = true;
    _actionTimer?.cancel();
    await _speech.stop();
    _isListening = false;
    debugPrint('VoiceCommandService.stopListening: stopped');
    notifyListeners();
  }

  void _processWords(String words) {
    for (final entry in _modeEntriesBySpecificity) {
      if (words.contains(entry.key)) {
        debugPrint(
          'VoiceCommandService.match mode: phrase="${entry.key}" mode=${entry.value}',
        );
        unawaited(_btService.setMode(entry.value));
        _statusMessage = 'Mode: ${entry.key}';
        notifyListeners();
        return;
      }
    }

    for (final entry in _voiceEntriesBySpecificity) {
      if (words.contains(entry.key)) {
        debugPrint(
          'VoiceCommandService.match command: phrase="${entry.key}" command=${entry.value}',
        );
        unawaited(_btService.sendCommand(entry.value));
        _statusMessage = 'Command: ${entry.key}';

        _actionTimer?.cancel();

        if (entry.value == BluetoothService.cmdStop) {
          notifyListeners();
          return;
        }

        final Duration duration =
            entry.value == BluetoothService.cmdForward ||
                entry.value == BluetoothService.cmdBackward
            ? const Duration(seconds: 2)
            : const Duration(milliseconds: 800);

        _actionTimer = Timer(duration, () {
          debugPrint(
            'VoiceCommandService.autoStop: command=${BluetoothService.cmdStop}',
          );
          unawaited(_btService.sendCommand(BluetoothService.cmdStop));
        });

        notifyListeners();
        return;
      }
    }

    _statusMessage = 'Not recognised: "$words"';
    debugPrint('VoiceCommandService.match none: words="$words"');
    notifyListeners();
  }

  @override
  void dispose() {
    _actionTimer?.cancel();
    _speech.cancel();
    super.dispose();
  }
}
