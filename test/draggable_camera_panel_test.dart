import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_timer/models/camera_display_settings.dart';
import 'package:gym_timer/widgets/draggable_camera_panel.dart';

void main() {
  testWidgets(
    'multiple pointer moves before a frame retain the whole distance',
    (tester) async {
      var settings = const CameraDisplaySettings(y: .4);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 400,
                height: 700,
                child: StatefulBuilder(
                  builder: (context, update) => DraggableCameraPanel(
                    settings: settings,
                    onChanged: (value) => update(() => settings = value),
                    onChangeEnd: () {},
                    child: const ColoredBox(color: Colors.green),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      final panel = find.byKey(const Key('draggable-camera-panel'));
      final finger = await tester.startGesture(tester.getCenter(panel));
      await finger.moveBy(const Offset(0, 30));
      await tester.pump();
      final before = tester.getTopLeft(panel);
      await finger.moveBy(const Offset(0, 30));
      await finger.moveBy(const Offset(0, 30));
      await finger.moveBy(const Offset(0, 30));
      await tester.pump();
      expect(tester.getTopLeft(panel).dy - before.dy, closeTo(90, .01));
      await finger.up();
      expect(tester.takeException(), isNull);
    },
  );
}
