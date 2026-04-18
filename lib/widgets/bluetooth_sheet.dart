import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

import '../bluetooth/bluetooth_service.dart';
import '../theme/colors.dart';

class BluetoothSheet extends StatefulWidget {
  const BluetoothSheet({super.key});

  @override
  State<BluetoothSheet> createState() => _BluetoothSheetState();
}

class _BluetoothSheetState extends State<BluetoothSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<BluetoothService>().loadBondedDevices();
    });
  }

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
                              (d) => DeviceTile(
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
                              (d) => DeviceTile(
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
        color: AppTheme.accentRed,
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
      ),
    ),
  );
}

class DeviceTile extends StatelessWidget {
  final BluetoothDevice device;
  final bool connected;
  final BluetoothService service;

  const DeviceTile({
    super.key,
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
            child: const Text('SAVE', style: TextStyle(color: AppTheme.accentRed)),
          ),
        ],
      ),
    );
  }
}
