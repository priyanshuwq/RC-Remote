import 'package:flutter_test/flutter_test.dart';

import 'package:remote/bluetooth/bluetooth_service.dart';
import 'package:remote/main.dart';

void main() {
  testWidgets('SmartRoverApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      SmartRoverApp(bluetoothService: BluetoothService()),
    );
    expect(find.byType(SmartRoverApp), findsOneWidget);
  });
}
