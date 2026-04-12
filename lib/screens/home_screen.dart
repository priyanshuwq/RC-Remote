import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:google_fonts/google_fonts.dart';

import '../bluetooth/bluetooth_service.dart';
import '../voice/voice_commands.dart';

// Design tokens and patterns
const Color _bg = Color(0xFF000000);
const Color _card = Color(0xFF181818);
const Color _accentRed = Color(0xFFD71921);
const Color _border = Color(0x14FFFFFF);

const List<List<int>> _dotUpArrow = [
  [2, 0],
  [1, 1],
  [2, 1],
  [3, 1],
  [0, 2],
  [2, 2],
  [4, 2],
  [2, 3],
  [2, 4],
];

const List<List<int>> _dotDownArrow = [
  [2, 4],
  [1, 3],
  [2, 3],
  [3, 3],
  [0, 2],
  [2, 2],
  [4, 2],
  [2, 1],
  [2, 0],
];

const List<List<int>> _dotLeftArrow = [
  [0, 2],
  [1, 1],
  [1, 2],
  [1, 3],
  [2, 0],
  [2, 2],
  [2, 4],
  [3, 2],
  [4, 2],
];

const List<List<int>> _dotRightArrow = [
  [4, 2],
  [3, 1],
  [3, 2],
  [3, 3],
  [2, 0],
  [2, 2],
  [2, 4],
  [1, 2],
  [0, 2],
];

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
                                color: active ? _accentRed : Colors.white,
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
                                  color: _accentRed,
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
      builder: (_) => const _BluetoothSheet(),
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
      backgroundColor: _bg,
      body: Stack(
        children: [
          const Positioned.fill(child: _DotGrid()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                children: [
                  _topBar(),
                  const SizedBox(height: 14),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        //  LEFT PANEL: FWD / BACK
                        Expanded(flex: 5, child: _buildFwdBackPanel()),

                        const SizedBox(width: 20),

                        //  CENTER: Animation + Mode
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
                                    ] else if (_activeMode ==
                                        'Voice Control') ...[
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

                        //  RIGHT PANEL: LEFT / RIGHT
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

  //  TOP BAR
  Widget _topBar() {
    return Row(
      children: [
        // Left side
        Expanded(
          child: Row(
            children: [
              _DotCluster(),
              const SizedBox(width: 10),
              Text(
                'RC REMOTE',
                style: GoogleFonts.dotGothic16(
                  color: _accentRed,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.5,
                ),
              ),
            ],
          ),
        ),

        // Center: connection badge + wifi icon
        Consumer<BluetoothService>(
          builder: (_, bt, _) {
            final connected = bt.isConnected;
            final connecting = bt.isConnecting;
            final label = connected
                ? 'CONNECTED'
                : connecting
                ? 'CONNECTING...'
                : 'DISCONNECTED';
            final dot = connected
                ? Colors.white
                : connecting
                ? Colors.orangeAccent
                : Colors.white38;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: _border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: dot,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(width: 14),
        Consumer<BluetoothService>(
          builder: (_, bt, _) => Icon(
            bt.isConnected ? Icons.wifi : Icons.wifi_off_rounded,
            color: Colors.white70,
            size: 19,
          ),
        ),

        // Right side
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _iconBtn(Icons.more_horiz, _showBluetooth),
              const SizedBox(width: 10),
              _iconBtn(Icons.power_settings_new, () {
                final bt = context.read<BluetoothService>();
                if (bt.isConnected) {
                  bt.disconnect();
                  _showSnack('Bluetooth disconnected');
                } else {
                  _showSnack('Not connected');
                }
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: _card,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  //  FWD / BACK PANEL
  Widget _buildFwdBackPanel() {
    return _RoundedPanel(
      child: Column(
        children: [
          Expanded(
            child: _ArrowButton(
              letter: 'FWD',
              pattern: _dotUpArrow,
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
            child: _ArrowButton(
              letter: 'BACK',
              pattern: _dotDownArrow,
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

  //  LEFT / RIGHT PANEL
  Widget _buildLeftRightPanel() {
    return _RoundedPanel(
      child: Row(
        children: [
          Expanded(
            child: _ArrowButton(
              letter: 'LEFT',
              pattern: _dotLeftArrow,
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
            child: _ArrowButton(
              letter: 'RIGHT',
              pattern: _dotRightArrow,
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

  //  CENTER ANIMATION
  Widget _centerCar() {
    return Consumer<VoiceCommandService>(
      builder: (context, voiceService, child) {
        final showVoiceWave =
            _activeMode == 'Voice Control' && voiceService.isListening;

        return Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _RadialDotHaloPainter()),
            ),

            if (showVoiceWave)
              const _DotMatrixVoiceAnimation()
            else if (_activeMode == 'Obstacle Avoiding')
              _RadarDotAnimation(isActive: _isModeRunning)
            else if (_activeMode == 'Human Following')
              _TrackerDotAnimation(isActive: _isModeRunning)
            else
              const _NormalDotAnimation(),

            // Voice status text
            if (_activeMode == 'Voice Control' &&
                voiceService.statusMessage.isNotEmpty)
              Positioned(
                bottom: -20,
                child: Text(
                  voiceService.statusMessage.toUpperCase(),
                  style: const TextStyle(
                    color: _accentRed,
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

  //  MODE BUTTON
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
              ? _accentRed.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: _isModeRunning
                ? _accentRed
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Text(
          _isModeRunning ? 'STOP' : 'START',
          style: TextStyle(
            color: _isModeRunning ? _accentRed : Colors.white,
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
                  ? _accentRed.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.05),
              shape: BoxShape.circle,
              border: Border.all(
                color: voiceService.isListening
                    ? _accentRed
                    : Colors.white.withValues(alpha: 0.08),
              ),
            ),
            child: Icon(
              voiceService.isListening ? Icons.mic : Icons.mic_none,
              color: voiceService.isListening ? _accentRed : Colors.white,
              size: 18,
            ),
          ),
        );
      },
    );
  }
}

// BLUETOOTH SHEET
class _BluetoothSheet extends StatelessWidget {
  const _BluetoothSheet();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (_, scrollCtrl) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF111111),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.07)),
                left: BorderSide(color: Colors.white.withValues(alpha: 0.07)),
                right: BorderSide(color: Colors.white.withValues(alpha: 0.07)),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Header with Scan Button
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _sheetHeader('DEVICES MANAGER'),
                      Consumer<BluetoothService>(
                        builder: (_, bt, _) => IconButton(
                          onPressed: bt.isDiscovering
                              ? null
                              : bt.startDiscovery,
                          icon: bt.isDiscovering
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white38,
                                  ),
                                )
                              : const Icon(
                                  Icons.radar_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                          tooltip: 'Scan for devices',
                          visualDensity: VisualDensity.compact,
                          splashRadius: 20,
                        ),
                      ),
                    ],
                  ),
                ),

                // Separated List
                Expanded(
                  child: Consumer<BluetoothService>(
                    builder: (_, bt, _) {
                      final savedDevices = bt.bondedDevices;
                      // Filter out already bonded devices from discovered list correctly
                      final discoveredDevices = bt.discoveredDevices
                          .where(
                            (r) => !savedDevices.any(
                              (sd) => sd.address == r.device.address,
                            ),
                          )
                          .map((r) => r.device)
                          .toList();

                      if (!bt.isConnected &&
                          savedDevices.isEmpty &&
                          discoveredDevices.isEmpty) {
                        return const Center(
                          child: Text(
                            'No devices found.\nTap scan icon above to search.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 13,
                            ),
                          ),
                        );
                      }
                      return ListView(
                        controller: scrollCtrl,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          if (savedDevices.isNotEmpty) ...[
                            _sectionTitle('SAVED DEVICES'),
                            ...savedDevices.map(
                              (d) => _DeviceTile(
                                device: d,
                                connected:
                                    bt.connectedDevice?.address == d.address &&
                                    bt.isConnected,
                                service: bt,
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          if (discoveredDevices.isNotEmpty) ...[
                            _sectionTitle('AVAILABLE DEVICES'),
                            ...discoveredDevices.map(
                              (d) => _DeviceTile(
                                device: d,
                                connected:
                                    bt.connectedDevice?.address == d.address &&
                                    bt.isConnected,
                                service: bt,
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sheetHeader(String t) => Text(
    t,
    style: const TextStyle(
      color: Colors.white70,
      fontSize: 14,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.2,
    ),
  );

  Widget _sectionTitle(String t) => Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 8, left: 4),
    child: Text(
      t,
      style: const TextStyle(
        color: _accentRed,
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
      ),
    ),
  );
}

// ── Radar Dot Matrix Animation (Obstacle Avoiding) ────────────────────────────
class _RadarDotAnimation extends StatefulWidget {
  final bool isActive;
  const _RadarDotAnimation({required this.isActive});

  @override
  State<_RadarDotAnimation> createState() => _RadarDotAnimationState();
}

class _RadarDotAnimationState extends State<_RadarDotAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    if (widget.isActive) _ctrl.repeat();
  }

  @override
  void didUpdateWidget(_RadarDotAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _ctrl.repeat();
      } else {
        _ctrl.stop();
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) => CustomPaint(
        painter: _RadarPainter(_ctrl.value, widget.isActive),
        size: const Size(140, 140),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final double sweep;
  final bool active;
  _RadarPainter(this.sweep, this.active);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;

    for (int ring = 1; ring <= 4; ring++) {
      final radius = ring * 16.0;
      final dotsCount = ring * 10;
      for (int i = 0; i < dotsCount; i++) {
        final angle = (i * 2 * math.pi) / dotsCount;
        double a = active ? 0.3 : 0.6;

        if (active) {
          double radarAngle = sweep * 2 * math.pi;
          double diff = angle - radarAngle;
          while (diff < 0) {
            diff += 2 * math.pi;
          }
          if (diff < math.pi / 2) {
            a = 1.0 - (diff / (math.pi / 2));
          }
        }

        final pt = Paint()
          ..color = active
              ? _accentRed.withValues(alpha: a)
              : Colors.white.withValues(alpha: 0.2);
        canvas.drawCircle(
          Offset(cx + radius * math.cos(angle), cy + radius * math.sin(angle)),
          1.8,
          pt,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_RadarPainter old) =>
      old.sweep != sweep || old.active != active;
}

// Tracker Dot Matrix Animation (Human Following)
class _TrackerDotAnimation extends StatefulWidget {
  final bool isActive;
  const _TrackerDotAnimation({required this.isActive});

  @override
  State<_TrackerDotAnimation> createState() => _TrackerDotAnimationState();
}

class _TrackerDotAnimationState extends State<_TrackerDotAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    if (widget.isActive) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_TrackerDotAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _ctrl.repeat(reverse: true);
      } else {
        _ctrl.stop();
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) => CustomPaint(
        painter: _TrackerPainter(_ctrl.value, widget.isActive),
        size: const Size(140, 140),
      ),
    );
  }
}

class _TrackerPainter extends CustomPainter {
  final double pulse;
  final bool active;
  _TrackerPainter(this.pulse, this.active);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final dotColor = active ? _accentRed : Colors.white.withValues(alpha: 0.2);
    final paint = Paint()..color = dotColor;

    final List<Offset> human = [
      Offset(cx, cy - 20),
      Offset(cx, cy - 5),
      Offset(cx, cy + 5),
      Offset(cx - 10, cy),
      Offset(cx + 10, cy),
      Offset(cx - 8, cy + 18),
      Offset(cx + 8, cy + 18),
    ];
    for (var o in human) {
      canvas.drawCircle(o, 2.5, paint);
    }

    if (active) {
      final lockSize = 40.0 + (pulse * 10);
      final alpha = (1.0 - pulse) * 0.8 + 0.2;
      final lockPaint = Paint()..color = _accentRed.withValues(alpha: alpha);

      canvas.drawCircle(Offset(cx - lockSize, cy - lockSize), 2, lockPaint);
      canvas.drawCircle(Offset(cx - lockSize + 6, cy - lockSize), 2, lockPaint);
      canvas.drawCircle(Offset(cx - lockSize, cy - lockSize + 6), 2, lockPaint);

      canvas.drawCircle(Offset(cx + lockSize, cy - lockSize), 2, lockPaint);
      canvas.drawCircle(Offset(cx + lockSize - 6, cy - lockSize), 2, lockPaint);
      canvas.drawCircle(Offset(cx + lockSize, cy - lockSize + 6), 2, lockPaint);

      canvas.drawCircle(Offset(cx - lockSize, cy + lockSize), 2, lockPaint);
      canvas.drawCircle(Offset(cx - lockSize + 6, cy + lockSize), 2, lockPaint);
      canvas.drawCircle(Offset(cx - lockSize, cy + lockSize - 6), 2, lockPaint);

      canvas.drawCircle(Offset(cx + lockSize, cy + lockSize), 2, lockPaint);
      canvas.drawCircle(Offset(cx + lockSize - 6, cy + lockSize), 2, lockPaint);
      canvas.drawCircle(Offset(cx + lockSize, cy + lockSize - 6), 2, lockPaint);
    }
  }

  @override
  bool shouldRepaint(_TrackerPainter old) =>
      old.pulse != pulse || old.active != active;
}

// Nothing OS Controller Dot Matrix (Normal Mode)
class _NormalDotAnimation extends StatelessWidget {
  const _NormalDotAnimation();

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(
      painter: _NormalCarPainter(),
      size: Size(140, 140),
    );
  }
}

class _NormalCarPainter extends CustomPainter {
  const _NormalCarPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    const double gridScale = 9.0;
    final double startX = cx - (5 * gridScale);
    final double startY = cy - (3.5 * gridScale);

    // Pure white dots — Nothing OS style controller
    final bodyPaint = Paint()..color = Colors.white;

    final List<List<int>> dots = [
      [2, 0],
      [3, 0],
      [7, 0],
      [8, 0],
      [1, 1],
      [2, 1],
      [3, 1],
      [4, 1],
      [5, 1],
      [6, 1],
      [7, 1],
      [8, 1],
      [9, 1],
      [0, 2],
      [1, 2],
      [3, 2],
      [4, 2],
      [5, 2],
      [6, 2],
      [7, 2],
      [9, 2],
      [10, 2],
      [0, 3],
      [4, 3],
      [5, 3],
      [6, 3],
      [8, 3],
      [10, 3],
      [0, 4],
      [1, 4],
      [3, 4],
      [4, 4],
      [5, 4],
      [6, 4],
      [7, 4],
      [9, 4],
      [10, 4],
      [0, 5],
      [1, 5],
      [2, 5],
      [3, 5],
      [7, 5],
      [8, 5],
      [9, 5],
      [10, 5],
      [0, 6],
      [1, 6],
      [2, 6],
      [8, 6],
      [9, 6],
      [10, 6],
      [1, 7],
      [2, 7],
      [8, 7],
      [9, 7],
    ];

    for (final dot in dots) {
      canvas.drawCircle(
        Offset(startX + (dot[0] * gridScale), startY + (dot[1] * gridScale)),
        3.5,
        bodyPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

//  Voice Wave Animation
class _DotMatrixVoiceAnimation extends StatefulWidget {
  const _DotMatrixVoiceAnimation();

  @override
  State<_DotMatrixVoiceAnimation> createState() =>
      _DotMatrixVoiceAnimationState();
}

class _DotMatrixVoiceAnimationState extends State<_DotMatrixVoiceAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(); // Smooth continuous cycle
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _NothingEqualizerPainter(_controller.value),
          size: const Size(140, 60),
        );
      },
    );
  }
}

class _NothingEqualizerPainter extends CustomPainter {
  final double animationValue;

  _NothingEqualizerPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    const dotSize = 3.0; // radius
    const cols = 15;
    const maxRows = 7; // max vertical dots
    const spacingX = 9.0;
    const spacingY = 9.0;

    final cx = size.width / 2;
    final cy = size.height / 2;

    // Start drawing from the left side so the 15 columns are perfectly centered
    final startX = cx - ((cols - 1) * spacingX) / 2;

    for (int col = 0; col < cols; col++) {
      // Combine 3 smooth intersecting sine waves to create a chaotic equalizer effect
      final wave1 = math.sin(animationValue * math.pi * 4 + (col * 0.5));
      final wave2 = math.sin(animationValue * math.pi * 6 - (col * 0.8));
      final wave3 = math.sin(animationValue * math.pi * 2 + (col * 0.2));

      final composite = ((wave1 + wave2 + wave3) / 3)
          .abs(); // ranges from 0.0 to approx 1.0

      // Calculate vertical dot count (forcing it to be odd so it's perfectly symmetrical)
      int dotsCount = (1 + (maxRows - 1) * composite).round();
      if (dotsCount % 2 == 0) dotsCount++;

      // Create a gradient mask for alpha based on distance from center
      final distFromCenter = (col - (cols / 2)).abs() / (cols / 2);
      final columnAlpha =
          1.0 - (distFromCenter * 0.5); // Fades out gently towards edges

      final paint = Paint()
        ..color = _accentRed.withValues(alpha: columnAlpha.clamp(0.0, 1.0));

      for (int i = 0; i < dotsCount; i++) {
        // Find exact center vertical position for each dot in this column
        final double dy = cy + (i - (dotsCount - 1) / 2) * spacingY;
        canvas.drawCircle(Offset(startX + col * spacingX, dy), dotSize, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_NothingEqualizerPainter old) =>
      old.animationValue != animationValue;
}

//  Background dot grid
class _DotGrid extends StatelessWidget {
  const _DotGrid();

  @override
  Widget build(BuildContext context) =>
      const CustomPaint(painter: _DotGridPainter());
}

class _DotGridPainter extends CustomPainter {
  const _DotGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.04);
    const spacing = 22.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.0, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

//  Radial dot halo (behind center animation)
class _RadialDotHaloPainter extends CustomPainter {
  const _RadialDotHaloPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final radii = [size.width * 0.32, size.width * 0.45, size.width * 0.58];
    final counts = [16, 22, 28];
    final opacities = [0.12, 0.07, 0.04];

    for (int ring = 0; ring < radii.length; ring++) {
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: opacities[ring]);
      final n = counts[ring];
      for (int i = 0; i < n; i++) {
        final angle = (2 * math.pi / n) * i;
        final dx = cx + radii[ring] * math.cos(angle);
        final dy = cy + radii[ring] * math.sin(angle);
        canvas.drawCircle(Offset(dx, dy), 1.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

//  Nothing-style dot cluster (top-left logo)
class _DotCluster extends StatelessWidget {
  const _DotCluster();

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 16,
    height: 14,
    child: const CustomPaint(painter: _DotClusterPainter()),
  );
}

class _DotClusterPainter extends CustomPainter {
  const _DotClusterPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.white;
    // ":·" style 2-column dot cluster (matches RC REMOTE logo in image)
    // Left column: 3 dots stacked
    canvas.drawCircle(const Offset(2.0, 1.5), 1.5, p);
    canvas.drawCircle(const Offset(2.0, 6.5), 1.5, p);
    canvas.drawCircle(const Offset(2.0, 11.5), 1.5, p);
    // Right column: 3 dots stacked
    canvas.drawCircle(const Offset(8.0, 1.5), 1.5, p);
    canvas.drawCircle(const Offset(8.0, 6.5), 1.5, p);
    canvas.drawCircle(const Offset(8.0, 11.5), 1.5, p);
  }

  @override
  bool shouldRepaint(_) => false;
}

//  Rounded square panel
class _RoundedPanel extends StatelessWidget {
  final Widget child;
  const _RoundedPanel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AspectRatio(
        aspectRatio: 1.0,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: CustomPaint(
              foregroundPainter: _NoisePainter(),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.02),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.06),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.03),
                      blurRadius: 15,
                      spreadRadius: 2,
                      offset: Offset.zero,
                      blurStyle: BlurStyle.inner,
                    ),
                  ],
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NoisePainter extends CustomPainter {
  const _NoisePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rand = math.Random(1337);
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.015)
      ..strokeWidth = 1.0;
    final points = <Offset>[];
    for (int i = 0; i < 2000; i++) {
      points.add(
        Offset(rand.nextDouble() * size.width, rand.nextDouble() * size.height),
      );
    }
    canvas.drawPoints(PointMode.points, points, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

//  Arrow button
class _ArrowButton extends StatelessWidget {
  final String letter;
  final List<List<int>> pattern;
  final bool isActive;
  final bool isTopHalf;
  final bool isHorizontal;
  final VoidCallback onDown;
  final VoidCallback onUp;

  const _ArrowButton({
    required this.letter,
    required this.pattern,
    required this.isActive,
    required this.isTopHalf,
    required this.onDown,
    required this.onUp,
    this.isHorizontal = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        onDown();
      },
      onTapUp: (_) => onUp(),
      onTapCancel: onUp,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: isActive
            ? BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(24),
              )
            : null,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Center(
                child: _DotArrow(pattern: pattern, active: isActive),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                letter,
                style: TextStyle(
                  color: isActive ? _accentRed : Colors.white38,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//  Dot arrow renderer
class _DotArrow extends StatelessWidget {
  final List<List<int>> pattern;
  final bool active;
  const _DotArrow({required this.pattern, required this.active});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DotArrowPainter(pattern, active),
      size: const Size(44, 44),
    );
  }
}

class _DotArrowPainter extends CustomPainter {
  final List<List<int>> pattern;
  final bool active;
  _DotArrowPainter(this.pattern, this.active);

  @override
  void paint(Canvas canvas, Size size) {
    const dotR = 2.8;
    const step = 8.0;
    final paint = Paint()
      ..color = active ? _accentRed : Colors.white.withValues(alpha: 0.55);
    for (final pt in pattern) {
      canvas.drawCircle(
        Offset(pt[0] * step + dotR, pt[1] * step + dotR),
        dotR,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DotArrowPainter old) => old.active != active;
}

// Device tile (in BT sheet)
class _DeviceTile extends StatelessWidget {
  final BluetoothDevice device;
  final bool connected;
  final BluetoothService service;

  const _DeviceTile({
    required this.device,
    required this.connected,
    required this.service,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = service.getDeviceName(device);

    return ListTile(
      onTap: () async {
        if (service.isConnected &&
            service.connectedDevice?.address == device.address) {
          await service.disconnect();
        } else {
          await service.connectToDevice(device);
        }
      },
      onLongPress: () => _showRenameDialog(context, displayName),
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Icon(
        connected ? Icons.bluetooth_connected_rounded : Icons.bluetooth_rounded,
        color: connected ? Colors.greenAccent : Colors.white70,
        size: 20,
      ),
      title: Text(
        displayName,
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
      subtitle: Text(
        device.address,
        style: const TextStyle(color: Colors.white38, fontSize: 11),
      ),
      trailing: connected
          ? const Icon(
              Icons.check_circle_rounded,
              color: Colors.greenAccent,
              size: 18,
            )
          : null,
    );
  }

  void _showRenameDialog(BuildContext context, String currentName) {
    final TextEditingController ctrl = TextEditingController(text: currentName);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        scrollable: true,
        title: const Text(
          'Rename Device',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Enter new alias',
            hintStyle: TextStyle(color: Colors.white38),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white38),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'CANCEL',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () {
              service.renameDevice(device.address, ctrl.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('SAVE', style: TextStyle(color: _accentRed)),
          ),
        ],
      ),
    );
  }
}
