import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:convert';
import 'package:flutter/material.dart';


// Classe responsável por fazer a conversão de JSON para polygons e vice-versa
class Converter{

  // função que converte polygon para JSON
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


  // função que converte uma lista de polygons para json
String polygonsToJson(Set<Polygon> polygons) {
  final list = polygons.map((p) => polygonToJson(p)).toList();
  return jsonEncode(list);
}


// função que converte uma JSON para uma lista de polygons
Set<Polygon> polygonsFromJson(String jsonString) {
  if (jsonString == ""){
    // se o json estiver vazio retornamos um set vázio
    return {};
  } 
  final Map<String, dynamic> data = jsonDecode(jsonString); // decodifica como Map
  final List<dynamic> polygonList = data['drawData'] ?? []; // pega a lista dentro da chave 'drawData'
  final Set<Polygon> polygons = {}; // lista de polygons

  for (final p in polygonList) {
    // para cada polygons dentro do json
    // pegamos os pontos dele
    final points = (p['points'] as List<dynamic>)
        .map((pt) => LatLng(pt['lat'], pt['lng']))
        .toList();
    // e adicionamos ele à lista de polygons
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