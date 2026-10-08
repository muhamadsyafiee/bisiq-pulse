import '../l10n/app_strings.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/material.dart';
import '../models/camera_display_settings.dart';

class DraggableCameraPanel extends StatefulWidget {
  const DraggableCameraPanel({
    super.key,
    required this.settings,
    required this.onChanged,
    required this.onChangeEnd,
    required this.child,
  });
  final CameraDisplaySettings settings;
  final ValueChanged<CameraDisplaySettings>? onChanged;
  final VoidCallback onChangeEnd;
  final Widget child;

  @override
  State<DraggableCameraPanel> createState() => _DraggableCameraPanelState();
}

class _DraggableCameraPanelState extends State<DraggableCameraPanel> {
  Offset? _dragOrigin;
  CameraDisplaySettings? _dragSettings;

  void _begin(DragStartDetails event) {
    _dragOrigin = event.globalPosition;
    _dragSettings = settings;
  }

  CameraDisplaySettings get settings => widget.settings;
  ValueChanged<CameraDisplaySettings>? get onChanged => widget.onChanged;
  VoidCallback get onChangeEnd => widget.onChangeEnd;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final width = box.maxWidth * CameraDisplaySettings.panelWidth;
      final height = width * CameraDisplaySettings.panelHeightRatio;
      final marginX = box.maxWidth * CameraDisplaySettings.margin;
      final marginY = box.maxHeight * CameraDisplaySettings.margin;
      final travelX = (box.maxWidth - width - 2 * marginX).clamp(
        0.0,
        double.infinity,
      );
      final travelY = (box.maxHeight - height - 2 * marginY).clamp(
        0.0,
        double.infinity,
      );
      void move(double x, double y) {
        onChanged?.call(settings.copyWith(x: x, y: y));
      }

      return Stack(
        children: [
          Positioned(
            left: marginX + settings.x * travelX,
            top: marginY + settings.y * travelY,
            width: width,
            height: height,
            child: Semantics(
              label: AppStrings.of(context).text('panelSemantics'),
              customSemanticsActions: onChanged == null
                  ? null
                  : {
                      CustomSemanticsAction(
                        label: AppStrings.of(context).text('panelTop'),
                      ): () {
                        move(settings.x, 0);
                        onChangeEnd();
                      },
                      CustomSemanticsAction(
                        label: AppStrings.of(context).text('panelMiddle'),
                      ): () {
                        move(.5, .5);
                        onChangeEnd();
                      },
                      CustomSemanticsAction(
                        label: AppStrings.of(context).text('panelBottom'),
                      ): () {
                        move(settings.x, 1);
                        onChangeEnd();
                      },
                    },
              child: GestureDetector(
                key: Key('draggable-camera-panel'),
                behavior: HitTestBehavior.opaque,
                // Separate axis recognizers win against the surrounding vertical
                // scroll view. Global deltas still allow free diagonal movement.
                onVerticalDragStart: onChanged == null ? null : _begin,
                onHorizontalDragStart: onChanged == null ? null : _begin,
                onVerticalDragUpdate: onChanged == null
                    ? null
                    : (event) {
                        final delta =
                            event.globalPosition -
                            (_dragOrigin ?? event.globalPosition);
                        move(
                          (_dragSettings ?? settings).x +
                              (travelX == 0 ? 0 : delta.dx / travelX),
                          (_dragSettings ?? settings).y +
                              (travelY == 0 ? 0 : delta.dy / travelY),
                        );
                      },
                onHorizontalDragUpdate: onChanged == null
                    ? null
                    : (event) {
                        final delta =
                            event.globalPosition -
                            (_dragOrigin ?? event.globalPosition);
                        move(
                          (_dragSettings ?? settings).x +
                              (travelX == 0 ? 0 : delta.dx / travelX),
                          (_dragSettings ?? settings).y +
                              (travelY == 0 ? 0 : delta.dy / travelY),
                        );
                      },
                onVerticalDragEnd: onChanged == null
                    ? null
                    : (_) => onChangeEnd(),
                onHorizontalDragEnd: onChanged == null
                    ? null
                    : (_) => onChangeEnd(),
                onVerticalDragCancel: onChanged == null ? null : onChangeEnd,
                onHorizontalDragCancel: onChanged == null ? null : onChangeEnd,
                child: widget.child,
              ),
            ),
          ),
        ],
      );
    },
  );
}
