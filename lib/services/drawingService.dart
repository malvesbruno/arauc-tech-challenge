import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/strokeModel.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:xml/xml.dart';
import './converter.dart';

class DrawingService extends ChangeNotifier {
  final List<Stroke> strokes = [];
  final Set<Polygon> polygons = {};
  final Converter converter = Converter();

  double eraseThresholdMeters = 15.0;

  Stroke startStroke({
    required String id,
    required Offset startLocal,
    required Offset normalizedStart,
    required Color color,
    required double width,
    dynamic visibleRegionAtStart,
    Size? mapSizeAtStart,
  }) {
    final stroke = Stroke(
      id: id,
      points: [startLocal],
      normalizedPoints: [normalizedStart],
      color: color,
      width: width,
      visibleRegionAtStart: visibleRegionAtStart,
      mapSizeAtStart: mapSizeAtStart,
    );
    strokes.add(stroke);
    notifyListeners();
    return stroke;
  }

  void updateStrokeWithLocal(Offset local) {
    if (strokes.isEmpty) return;
    final last = strokes.last;
    last.points.add(local);
    notifyListeners();
  }

  void addNormalizedToLast(Offset normalized) {
    if (strokes.isEmpty) return;
    strokes.last.normalizedPoints.add(normalized);
    notifyListeners();
  }

  void finishLastStroke() {
    // remove empty strokes defensively
    strokes.removeWhere((s) => s.points.isEmpty || s.normalizedPoints.isEmpty);
    notifyListeners();
  }

  // Remove points near a local position (used by eraser while editing strokes)
  void erasePointsAtLocal(Offset local, {double pixelThreshold = 20.0}) {
    for (var stroke in strokes) {
      stroke.points.removeWhere((p) => (p - local).distance < pixelThreshold);
    }
    strokes.removeWhere((s) => s.points.isEmpty);
    notifyListeners();
  }

  // --- Convert strokes to polygons (same logic do _saveDrawing) ---
  void convertStrokeToPolygon(Stroke stroke) {
    if (stroke.normalizedPoints.isEmpty) return;
    if (stroke.visibleRegionAtStart == null || stroke.mapSizeAtStart == null) return;
    if (stroke.normalizedPoints.length < 3) return;

    final bounds = stroke.visibleRegionAtStart!;
    final ne = bounds.northeast;
    final sw = bounds.southwest;
    final latSpan = ne.latitude - sw.latitude;
    final lngSpan = ne.longitude - sw.longitude;

    final coords = stroke.normalizedPoints.map((p) {
      final lat = ne.latitude - latSpan * p.dy;
      final lng = sw.longitude + lngSpan * p.dx;
      return LatLng(lat, lng);
    }).toList();

    polygons.add(Polygon(
      polygonId: PolygonId(stroke.id),
      points: coords,
      strokeWidth: 2,
      strokeColor: stroke.color,
      fillColor: stroke.color.withOpacity(0.35),
    ));
    notifyListeners();
  }

  // Convert all valid strokes and clear them
  void saveAllStrokes() {
    // remove invalid
    strokes.removeWhere((s) => s.normalizedPoints.isEmpty);
    for (final s in List<Stroke>.from(strokes)) {
      convertStrokeToPolygon(s);
    }
    strokes.clear();
    notifyListeners();
  }

  // --- Erase polygon by map tap (local->LatLng conversion done by caller or pass function) ---
  Future<void> erasePolygonAtLatLng(LatLng tapped) async {
    Polygon? toRemove;
    for (final poly in polygons) {
      if (_pointInPolygon(tapped, poly.points)) {
        toRemove = poly;
        break;
      }

      double minDist = double.infinity;
      for (int i = 0; i < poly.points.length; i++) {
        final a = poly.points[i];
        final b = poly.points[(i + 1) % poly.points.length];
        final d = _distancePointToSegmentMeters(tapped, a, b);
        if (d < minDist) minDist = d;
      }
      if (minDist <= eraseThresholdMeters) {
        toRemove = poly;
        break;
      }
    }

    if (toRemove != null) {
      polygons.remove(toRemove);
      notifyListeners();
    }
  }

  // --- Small helpers ---

  bool _pointInPolygon(LatLng point, List<LatLng> polygon) {
    final x = point.longitude;
    final y = point.latitude;
    var inside = false;
    for (int i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      final xi = polygon[i].longitude, yi = polygon[i].latitude;
      final xj = polygon[j].longitude, yj = polygon[j].latitude;
      final intersect = ((yi > y) != (yj > y)) &&
          (x < (xj - xi) * (y - yi) / (yj - yi + 0.0) + xi);
      if (intersect) inside = !inside;
    }
    return inside;
  }

  double _distancePointToSegmentMeters(LatLng p, LatLng a, LatLng b) {
    final meanLat = (p.latitude + a.latitude + b.latitude) / 3.0 * pi / 180.0;
    final mPerDegLat = 111132.92 - 559.82 * cos(2 * meanLat) + 1.175 * cos(4 * meanLat);
    final mPerDegLon = 111412.84 * cos(meanLat) - 93.5 * cos(3 * meanLat);

    final px = p.longitude * mPerDegLon;
    final py = p.latitude * mPerDegLat;
    final ax = a.longitude * mPerDegLon;
    final ay = a.latitude * mPerDegLat;
    final bx = b.longitude * mPerDegLon;
    final by = b.latitude * mPerDegLat;

    final vx = bx - ax;
    final vy = by - ay;
    final wx = px - ax;
    final wy = py - ay;
    final c1 = vx * wx + vy * wy;
    final c2 = vx * vx + vy * vy;
    double t = (c2 == 0) ? 0.0 : (c1 / c2);
    t = t.clamp(0.0, 1.0);
    final projx = ax + t * vx;
    final projy = ay + t * vy;
    final dx = px - projx;
    final dy = py - projy;
    return sqrt(dx * dx + dy * dy);
  }

  // utility: clear everything
  void clearAll() {
    strokes.clear();
    polygons.clear();
    notifyListeners();
  }

  Future<void> loadKmlPolygon(String path) async {
  final kmlString = await rootBundle.loadString(path);
  final xmlDoc = XmlDocument.parse(kmlString);

  final coordinatesString =
      xmlDoc.findAllElements('coordinates').first.text.trim();

  final coords = coordinatesString.split(' ').map((pair) {
    final parts = pair.split(',');
    return LatLng(double.parse(parts[1]), double.parse(parts[0]));
  }).toList();

  polygons.add(Polygon(
    polygonId: const PolygonId('fazenda'),
    points: coords,
    fillColor: Colors.green.withOpacity(0.3),
    strokeColor: Colors.green,
    strokeWidth: 2,
  ));
  notifyListeners();
}

String savePolygonsToJson() => converter.polygonsToJson(polygons);

void loadPolygonsFromJson(String jsonString) {
  polygons.clear();
  polygons.addAll( converter.polygonsFromJson(jsonString));
  notifyListeners();
}
}
