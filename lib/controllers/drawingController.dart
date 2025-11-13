import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/drawingService.dart';


// controla as funções de desenho
/// [drawingService] service que criar os desenhos
/// [mapKey] key do map
/// [mapController] controlador do map

class DrawingController {
  final DrawingService drawingService;
  final GlobalKey mapKey;
  final Completer<GoogleMapController> mapController;

  DrawingController({
    required this.drawingService,
    required this.mapKey,
    required this.mapController,
  });

  // === ERASER ===
  // apaga os polygons próximos ao clicar
  Future<void> onEraseTap(Offset localPosition) async {
    final controller = await mapController.future;
    final mapBox = mapKey.currentContext!.findRenderObject() as RenderBox;
    final mapSize = mapBox.size;

    final normalized = Offset(
      (localPosition.dx / mapSize.width).clamp(0.0, 1.0),
      (localPosition.dy / mapSize.height).clamp(0.0, 1.0),
    );

    final bounds = await controller.getVisibleRegion();
    final ne = bounds.northeast;
    final sw = bounds.southwest;

    final lat = ne.latitude - (ne.latitude - sw.latitude) * normalized.dy;
    final lng = sw.longitude + (ne.longitude - sw.longitude) * normalized.dx;
    final touchedLatLng = LatLng(lat, lng);

    await drawingService.erasePolygonAtLatLng(touchedLatLng);
  }

  // === DRAW START ===
  // inicia o desenho
  Future<void> onPanStart(
    DragStartDetails details,
    Color Function() getColor,
  ) async {
    final controller = await mapController.future;
    final mapBox = mapKey.currentContext!.findRenderObject() as RenderBox;
    final localPosition = mapBox.globalToLocal(details.globalPosition);
    final mapSize = mapBox.size;
    final visibleRegion = await controller.getVisibleRegion();

    final normalized = Offset(
      (localPosition.dx / mapSize.width).clamp(0.0, 1.0),
      (localPosition.dy / mapSize.height).clamp(0.0, 1.0),
    );

    final color = getColor();

    drawingService.startStroke(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      startLocal: localPosition,
      normalizedStart: normalized,
      color: color,
      width: 10,
      visibleRegionAtStart: visibleRegion,
      mapSizeAtStart: mapSize,
    );
  }

  // === DRAW UPDATE ===
  // atualiza o desenho ao mover do dedo
  Future<void> onPanUpdate(
    DragUpdateDetails details, {
    required bool isEditing,
    required bool eraserSelected,
  }) async {
    if (!isEditing) return;

    final mapBox = mapKey.currentContext!.findRenderObject() as RenderBox;
    final localPosition = mapBox.globalToLocal(details.globalPosition);

    if (eraserSelected) {
      drawingService.erasePointsAtLocal(localPosition);
    } else {
      drawingService.updateStrokeWithLocal(localPosition);
      final mapSize = mapBox.size;
      final normalized = Offset(
        (localPosition.dx / mapSize.width).clamp(0.0, 1.0),
        (localPosition.dy / mapSize.height).clamp(0.0, 1.0),
      );
      drawingService.addNormalizedToLast(normalized);
    }
  }

  // === DRAW END ===
  // finaliza o desenho
  void onPanEnd() {
    drawingService.finishLastStroke();
  }
}
