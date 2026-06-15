import 'package:flutter_test/flutter_test.dart';

import 'package:remote/bluetooth/bluetooth_service.dart';
import 'package:remote/app.dart';

void main() {
  testWidgets('RCRemoteApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      RCRemoteApp(bluetoothService: BluetoothService()),
    );
    expect(find.byType(RCRemoteApp), findsOneWidget);
  });
}
