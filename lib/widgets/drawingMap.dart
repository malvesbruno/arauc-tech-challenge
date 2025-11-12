import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/strokeModel.dart';
import '../widgets/mapPainter.dart';

class DrawingMap extends StatefulWidget {
  final GlobalKey mapKey;
  final GlobalKey paintKey;
  final List<Stroke> strokes;
  final Set<Polygon> polygons;
  final Completer<GoogleMapController> controllerCompleter;
  final bool isEditing;
  final LatLng target;
  final bool eraserSelected;
  final void Function(DragStartDetails) onPanStart;
  final void Function(Offset) eraseAtLocalPosition;
  final void Function(DragUpdateDetails) onPanUpdate;
  final void Function(DragEndDetails) onPanEnd;

  DrawingMap({super.key, required this.eraseAtLocalPosition, required this.eraserSelected, required this.mapKey, required this.paintKey, required this.controllerCompleter, required this.strokes, required this.polygons, required this.isEditing, required this.target, required this.onPanEnd, required this.onPanStart, required this.onPanUpdate});
  @override
  State<DrawingMap> createState() => _DrawinMapState();
}

class _DrawinMapState extends State<DrawingMap>{
  @override 
  Widget build(BuildContext context) {
    return Stack(children: [
                GoogleMap(
                  key: widget.mapKey,
                initialCameraPosition: CameraPosition(target: widget.target, zoom: 16.8),
                polygons: widget.polygons,
                onMapCreated: (controller) => widget.controllerCompleter.complete(controller),
                mapType: MapType.satellite,),
                IgnorePointer(
                ignoring: !widget.isEditing,
                child: GestureDetector(
                  onPanStart: widget.onPanStart,
                  onPanUpdate:  (details) async {
  if (!widget.isEditing) return;

  final RenderBox mapBox = widget.mapKey.currentContext!.findRenderObject() as RenderBox;
  final localPosition = mapBox.globalToLocal(details.globalPosition);

  if (widget.eraserSelected) {
    if (widget.strokes.isNotEmpty) {
      // Apaga pontos do stroke atual
      setState(() {
  for (var stroke in widget.strokes) {
    stroke.points.removeWhere((p) => (p - localPosition).distance < 20);
  }
  // remove strokes sem pontos
  widget.strokes.removeWhere((s) => s.points.isEmpty);
});

    } else {
      // Apaga polígonos já salvos
      widget.eraseAtLocalPosition(localPosition);
    }
  } else {
    widget.onPanUpdate(details); // continua desenhando normalmente
  }
},
                  onPanEnd: widget.onPanEnd,
                  child: CustomPaint(
                    key: widget.paintKey,
                    painter: MapPainter(strokes: widget.strokes),
                    child: Container(), // camada transparente
                  ),
                ),
              ),
              ],);
  }
}
