import 'package:flutter/material.dart';
import '../models/strokeModel.dart';

/// Painter responsável por renderizar os traços desenhados sobre o mapa.
///
/// Essa classe é utilizada em conjunto com um [CustomPaint] para desenhar na tela
/// os traços ([Stroke]) capturados durante a interação do usuário.
///
/// Cada traço contém uma lista de pontos locais ([Offset]) que são percorridos
/// para formar linhas suaves com a espessura e cor definidas.
///
/// Exemplo de uso:
/// ```dart
/// CustomPaint(
///   painter: MapPainter(strokes: drawingService.strokes),
///   child: Container(), // ou o widget do mapa em si
/// )
/// ```
class MapPainter extends CustomPainter {
  /// Lista de traços a serem desenhados na tela.
  final List<Stroke> strokes;

  /// Cria uma instância de [MapPainter] com a lista de traços desejada.
  MapPainter({required this.strokes});

  @override
  void paint(Canvas canvas, Size size) {
    // Para cada traço desenhado...
    for (var stroke in strokes) {
      if (stroke.points.isEmpty) continue; // Ignora traços vazios

      // Define estilo visual do traço (cor, largura e formato das pontas)
      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.width / 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      // Cria um caminho conectando os pontos do traço
      final path = Path();
      path.moveTo(stroke.points.first.dx, stroke.points.first.dy);

      for (var point in stroke.points.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }

      // Desenha o caminho no canvas
      canvas.drawPath(path, paint);
    }
  }

  /// Indica se o canvas deve ser redesenhado quando o estado mudar.
  ///
  /// Como os traços mudam constantemente durante o desenho, retornamos `true`
  /// para garantir que o Flutter redesenhe a tela sempre que houver novos pontos.
  @override
  bool shouldRepaint(covariant MapPainter oldDelegate) => true;
}
