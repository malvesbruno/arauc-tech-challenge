import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/strokeModel.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:xml/xml.dart';
import './converter.dart';

// Classe do serviço responsável por gerenciar desenhos (traços e polígonos) sobre o mapa. 
class DrawingService extends ChangeNotifier {
  final List<Stroke> strokes = []; // lista de strokes
  final Set<Polygon> polygons = {}; // lista de polygons
  final Converter converter = Converter(); // objeto da classe Converter

  double eraseThresholdMeters = 15.0; // Distância máxima (em metros) para detectar e apagar polígonos próximos a um clique


  //Inicia um novo traço com base nas coordenadas locais e normalizadas do mapa

  /// - [id]: identificador único do traço.
  /// - [startLocal]: ponto inicial no sistema de coordenadas da tela.
  /// - [normalizedStart]: ponto inicial normalizado (proporcional à área visível do mapa).
  /// - [color]: cor do traço.
  /// - [width]: espessura do traço.
  /// - [visibleRegionAtStart]: região do mapa visível no início do traço.
  /// - [mapSizeAtStart]: tamanho do widget do mapa no início do traço.
  ///
  /// Retorna o [Stroke] criado.

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

  /// Adiciona um novo ponto (coordenada local) ao traço atual.
  void updateStrokeWithLocal(Offset local) {
    if (strokes.isEmpty) return;
    final last = strokes.last;
    last.points.add(local);
    notifyListeners();
  }

  /// Adiciona um novo ponto normalizado ao traço atual.
  void addNormalizedToLast(Offset normalized) {
    if (strokes.isEmpty) return;
    strokes.last.normalizedPoints.add(normalized);
    notifyListeners();
  }

  /// Finaliza o traço atual, removendo traços vazios por segurança.
  void finishLastStroke() {
    strokes.removeWhere((s) => s.points.isEmpty || s.normalizedPoints.isEmpty);
    notifyListeners();
  }

  /// Remove pontos próximos a uma posição local na tela (usado como borracha).
  ///
  /// [pixelThreshold] define a distância máxima, em pixels, para apagar pontos.
  void erasePointsAtLocal(Offset local, {double pixelThreshold = 20.0}) {
    for (var stroke in strokes) {
      stroke.points.removeWhere((p) => (p - local).distance < pixelThreshold);
    }
    strokes.removeWhere((s) => s.points.isEmpty);
    notifyListeners();
  }

  /// Converte um traço em um [Polygon] baseado na área visível do mapa.
  ///
  /// O traço precisa ter ao menos 3 pontos normalizados e informações de região visível
  /// e tamanho do mapa no momento do desenho.
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

  /// Converte todos os traços válidos para polígonos e limpa a lista de traços.
  void saveAllStrokes() {
    strokes.removeWhere((s) => s.normalizedPoints.isEmpty);
    for (final s in List<Stroke>.from(strokes)) {
      convertStrokeToPolygon(s);
    }
    strokes.clear();
    notifyListeners();
  }

   /// Apaga um polígono tocado no mapa, se o ponto [tapped] estiver dentro ou
  /// suficientemente próximo (≤ [eraseThresholdMeters]).
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

  /// Verifica se um ponto [point] está dentro de um [polygon] (algoritmo do raio ímpar).
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

  /// Calcula a menor distância (em metros) entre um ponto [p] e um segmento [a]-[b].
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

   // Utilitários gerais

    /// Limpa todos os traços e polígonos.
  void clearAll() {
    strokes.clear();
    polygons.clear();
    notifyListeners();
  }


  // Importação / Exportação


    /// Carrega um polígono a partir de um arquivo KML no [path].
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

/// Converte o conjunto atual de polígonos em JSON.
String savePolygonsToJson() => converter.polygonsToJson(polygons);


 /// Carrega polígonos a partir de um JSON e atualiza o estado.
void loadPolygonsFromJson(String jsonString) {
  polygons.clear();
  polygons.addAll( converter.polygonsFromJson(jsonString));
  notifyListeners();
}
}
