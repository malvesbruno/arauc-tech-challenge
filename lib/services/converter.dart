import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:convert';
import 'package:flutter/material.dart';


class Converter{
  Map<String, dynamic> polygonToJson(Polygon polygon) {
  return {
    'id': polygon.polygonId.value,
    'strokeColor': polygon.strokeColor.value, // cor como int
    'fillColor': polygon.fillColor.value,     // cor como int
    'strokeWidth': polygon.strokeWidth,
    'points': polygon.points
        .map((p) => {'lat': p.latitude, 'lng': p.longitude})
        .toList(),
  };
}

String polygonsToJson(Set<Polygon> polygons) {
  final list = polygons.map((p) => polygonToJson(p)).toList();
  return jsonEncode(list);
}

Set<Polygon> polygonsFromJson(String jsonString) {
  final List<dynamic> data = jsonDecode(jsonString);
  final Set<Polygon> polygons = {};

  for (final p in data) {
    final points = (p['points'] as List<dynamic>)
        .map((pt) => LatLng(pt['lat'], pt['lng']))
        .toList();

    polygons.add(Polygon(
      polygonId: PolygonId(p['id']),
      strokeColor: Color(p['strokeColor']),
      fillColor: Color(p['fillColor']),
      strokeWidth: p['strokeWidth'],
      points: points,
    ));
  }

  return polygons;
}

}