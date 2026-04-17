import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../bluetooth/bluetooth_service.dart';
import '../theme/colors.dart';

class DotCluster extends StatelessWidget {
  const DotCluster({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox(
    width: 16,
    height: 14,
    child: CustomPaint(painter: _DotClusterPainter()),
  );
}

class _DotClusterPainter extends CustomPainter {
  const _DotClusterPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.white;
    canvas.drawCircle(const Offset(2.0, 1.5), 1.5, p);
    canvas.drawCircle(const Offset(2.0, 6.5), 1.5, p);
    canvas.drawCircle(const Offset(2.0, 11.5), 1.5, p);
    canvas.drawCircle(const Offset(8.0, 1.5), 1.5, p);
    canvas.drawCircle(const Offset(8.0, 6.5), 1.5, p);
    canvas.drawCircle(const Offset(8.0, 11.5), 1.5, p);
  }

  @override
  bool shouldRepaint(_) => false;
}

class TopBar extends StatelessWidget {
  final VoidCallback onBluetoothTap;
  final VoidCallback onPowerTap;

  const TopBar({
    super.key,
    required this.onBluetoothTap,
    required this.onPowerTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Left side
        Expanded(
          child: Row(
            children: [
              const DotCluster(),
              const SizedBox(width: 10),
              Text(
                'RC REMOTE',
                style: GoogleFonts.dotGothic16(
                  color: AppTheme.accentRed,
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
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: AppTheme.border),
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
              _iconBtn(Icons.more_horiz, onBluetoothTap),
              const SizedBox(width: 10),
              _iconBtn(Icons.power_settings_new, onPowerTap),
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
          color: AppTheme.card,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}
