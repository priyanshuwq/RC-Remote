import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../bluetooth/bluetooth_service.dart';
import '../voice/voice_commands.dart';
import '../theme/colors.dart';
import '../animations/animations.dart';
import '../widgets/arrow_button.dart';
import '../widgets/rounded_panel.dart';
import '../widgets/top_bar.dart';
import '../widgets/bluetooth_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _activeMode = 'Normal';
  bool _isDropdownOpen = false;
  bool _isModeRunning = false;

  bool _fwdActive = false;
  bool _backActive = false;
  bool _leftActive = false;
  bool _rightActive = false;

  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  final List<String> _modes = [
    'Normal',
    'Voice Control',
    'Obstacle Avoiding',
    'Human Following',
  ];

  void _cmd(String command, bool down) {
    final bt = context.read<BluetoothService>();
    final action = down ? 'press' : 'release';
    final outgoing = down ? command : BluetoothService.cmdStop;
    debugPrint(
      'HomeScreen._cmd: action=$action input=$command outgoing=$outgoing',
    );
    if (down) {
      bt.sendCommand(command);
    } else {
      bt.sendCommand(BluetoothService.cmdStop);
    }
  }

  void _toggleDropdown() {
    if (_isDropdownOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    final overlay = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder: (_) => Stack(
        children: [
          GestureDetector(
            onTap: _closeDropdown,
            behavior: HitTestBehavior.translucent,
            child: const SizedBox.expand(),
          ),
          CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            targetAnchor: Alignment.topCenter,
            followerAnchor: Alignment.bottomCenter,
            offset: const Offset(0, -8),
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 220,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _modes.map((m) {
                    final active = _activeMode == m;
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _activeMode = m;
                          _isModeRunning = false;
                        });
                        context.read<BluetoothService>().setMode(
                          RobotMode.manual,
                        );
                        _closeDropdown();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 13,
                        ),
                        child: Row(
                          children: [
                            Text(
                              m,
                              style: TextStyle(
                                color: active ? AppTheme.accentRed : Colors.white,
                                fontSize: 13,
                                fontWeight: active
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                              ),
                            ),
                            const Spacer(),
                            if (active)
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: AppTheme.accentRed,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    overlay.insert(_overlayEntry!);
    setState(() => _isDropdownOpen = true);
  }

  void _closeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() => _isDropdownOpen = false);
  }

  void _showBluetooth() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const BluetoothSheet(),
    );
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFF1A1A1A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppTheme.bg,
      body: Stack(
        children: [
          const Positioned.fill(child: DotGrid()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                children: [
                  TopBar(
                    onBluetoothTap: _showBluetooth,
                    onPowerTap: () {
                      final bt = context.read<BluetoothService>();
                      if (bt.isConnected) {
                        bt.disconnect();
                        _showSnack('Bluetooth disconnected');
                      } else {
                        _showSnack('Not connected');
                      }
                    },
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // LEFT PANEL: FWD / BACK
                        Expanded(flex: 5, child: _buildFwdBackPanel()),
                        const SizedBox(width: 20),

                        // CENTER: Animation + Mode
                        Expanded(
                          flex: 6,
                          child: Column(
                            children: [
                              Expanded(child: _centerCar()),
                              const SizedBox(height: 10),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _modeButton(),
                                    if (_activeMode == 'Obstacle Avoiding' ||
                                        _activeMode == 'Human Following') ...[
                                      const SizedBox(width: 12),
                                      _startStopButton(),
                                    ] else if (_activeMode == 'Voice Control') ...[
                                      const SizedBox(width: 12),
                                      _voiceMicButton(),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 20),
                        // RIGHT PANEL: LEFT / RIGHT
                        Expanded(flex: 5, child: _buildLeftRightPanel()),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // FWD / BACK PANEL
  Widget _buildFwdBackPanel() {
    return RoundedPanel(
      child: Column(
        children: [
          Expanded(
            child: ArrowButton(
              letter: 'FWD',
              pattern: PatternTokens.dotUpArrow,
              isActive: _fwdActive,
              isTopHalf: true,
              onDown: () {
                setState(() => _fwdActive = true);
                _cmd(BluetoothService.cmdForward, true);
              },
              onUp: () {
                setState(() => _fwdActive = false);
                _cmd(BluetoothService.cmdForward, false);
              },
            ),
          ),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            color: Colors.white.withValues(alpha: 0.06),
          ),
          Expanded(
            child: ArrowButton(
              letter: 'BACK',
              pattern: PatternTokens.dotDownArrow,
              isActive: _backActive,
              isTopHalf: false,
              onDown: () {
                setState(() => _backActive = true);
                _cmd(BluetoothService.cmdBackward, true);
              },
              onUp: () {
                setState(() => _backActive = false);
                _cmd(BluetoothService.cmdBackward, false);
              },
            ),
          ),
        ],
      ),
    );
  }

  // LEFT / RIGHT PANEL
  Widget _buildLeftRightPanel() {
    return RoundedPanel(
      child: Row(
        children: [
          Expanded(
            child: ArrowButton(
              letter: 'LEFT',
              pattern: PatternTokens.dotLeftArrow,
              isActive: _leftActive,
              isTopHalf: true,
              isHorizontal: true,
              onDown: () {
                setState(() => _leftActive = true);
                _cmd(BluetoothService.cmdLeft, true);
              },
              onUp: () {
                setState(() => _leftActive = false);
                _cmd(BluetoothService.cmdLeft, false);
              },
            ),
          ),
          Container(
            width: 1,
            margin: const EdgeInsets.symmetric(vertical: 16),
            color: Colors.white.withValues(alpha: 0.06),
          ),
          Expanded(
            child: ArrowButton(
              letter: 'RIGHT',
              pattern: PatternTokens.dotRightArrow,
              isActive: _rightActive,
              isHorizontal: true,
              isTopHalf: false,
              onDown: () {
                setState(() => _rightActive = true);
                _cmd(BluetoothService.cmdRight, true);
              },
              onUp: () {
                setState(() => _rightActive = false);
                _cmd(BluetoothService.cmdRight, false);
              },
            ),
          ),
        ],
      ),
    );
  }

  // CENTER ANIMATION
  Widget _centerCar() {
    return Consumer<VoiceCommandService>(
      builder: (context, voiceService, child) {
        final showVoiceWave =
            _activeMode == 'Voice Control' && voiceService.isListening;

        return Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: CustomPaint(painter: const RadialDotHaloPainter()),
            ),

            if (showVoiceWave)
              const DotMatrixVoiceAnimation()
            else if (_activeMode == 'Obstacle Avoiding')
              RadarDotAnimation(isActive: _isModeRunning)
            else if (_activeMode == 'Human Following')
              TrackerDotAnimation(isActive: _isModeRunning)
            else
              const NormalDotAnimation(),

            // Voice status text
            if (_activeMode == 'Voice Control' &&
                voiceService.statusMessage.isNotEmpty)
              Positioned(
                bottom: -20,
                child: Text(
                  voiceService.statusMessage.toUpperCase(),
                  style: const TextStyle(
                    color: AppTheme.accentRed,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.0,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  // MODE BUTTON
  Widget _modeButton() {
    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          _toggleDropdown();
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'MODE ${_activeMode.toUpperCase()}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _startStopButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          _isModeRunning = !_isModeRunning;
        });
        if (_activeMode == 'Obstacle Avoiding') {
          context.read<BluetoothService>().setMode(
            _isModeRunning ? RobotMode.obstacle : RobotMode.manual,
          );
        } else {
          context.read<BluetoothService>().setMode(
            _isModeRunning ? RobotMode.follow : RobotMode.manual,
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: _isModeRunning
              ? AppTheme.accentRed.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: _isModeRunning
                ? AppTheme.accentRed
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Text(
          _isModeRunning ? 'STOP' : 'START',
          style: TextStyle(
            color: _isModeRunning ? AppTheme.accentRed : Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _voiceMicButton() {
    return Consumer<VoiceCommandService>(
      builder: (context, voiceService, _) {
        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            if (voiceService.isListening) {
              voiceService.stopListening();
            } else {
              voiceService.startListening();
            }
          },
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: voiceService.isListening
                  ? AppTheme.accentRed.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.05),
              shape: BoxShape.circle,
              border: Border.all(
                color: voiceService.isListening
                    ? AppTheme.accentRed
                    : Colors.white.withValues(alpha: 0.08),
              ),
            ),
            child: Icon(
              voiceService.isListening ? Icons.mic : Icons.mic_none,
              color: voiceService.isListening ? AppTheme.accentRed : Colors.white,
              size: 18,
            ),
          ),
        );
      },
    );
  }
}
