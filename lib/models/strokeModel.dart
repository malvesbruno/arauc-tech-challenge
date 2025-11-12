import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Stroke {
  final String id;
  final List<Offset> points; // Offsets em pixels (para CustomPaint)
  final List<Offset> normalizedPoints; // valores 0..1 relativos à largura/altura do mapa
  final Color color;
  final double width;

  // Guarda o bounds visível do mapa no início do stroke (usado na conversão)
  LatLngBounds? visibleRegionAtStart;
  Size? mapSizeAtStart;

  Stroke({
    required this.id,
    required this.points,
    required this.normalizedPoints,
    required this.color,
    required this.width,
    this.visibleRegionAtStart,
    this.mapSizeAtStart,
  });
}
