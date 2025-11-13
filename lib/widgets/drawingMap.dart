import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/strokeModel.dart';
import '../widgets/mapPainter.dart';


//widget responsável por mostrar o mapa, e permitir o desenho por cima dele
///[mapKey] global key do map
///[paintKey] global key do paint
///[strokes] linhas
///[polygons] linhas usadas no map
///[isLoading] estado de loading 
///[controllerCompleter] controller do map
///[isEditing] estado de edição
///[target] local que o map deve procurar
///[weekNumber] número da semana
///[eraserSelected] estado se a borracha está selecionada
///[onPanStart] função de iniciar um desenho
///[onPanUpdate] função de continuar o desenho
///[onPanEnd] função de terminar o desenho
///[apagarDesenho] função para apagar o desenho da nuvem
///[eraseAtLocalPosition] função para apagar polygons ao clicar neles

class DrawingMap extends StatefulWidget {
  final GlobalKey mapKey;
  final GlobalKey paintKey;
  final List<Stroke> strokes;
  final Set<Polygon> polygons;
  final bool isLoading;
  final Completer<GoogleMapController> controllerCompleter;
  final bool isEditing;
  final LatLng target;
  final int weekNumber;
  final bool eraserSelected;
  final void Function(DragStartDetails) onPanStart;
  final void Function(Offset) eraseAtLocalPosition;
  final void Function(DragUpdateDetails) onPanUpdate;
  final void Function(DragEndDetails) onPanEnd;
  final Future<void> Function(int) apagarDesenho; 

  DrawingMap({super.key, required this.apagarDesenho, required this.weekNumber, required this.isLoading, required this.eraseAtLocalPosition, required this.eraserSelected, required this.mapKey, required this.paintKey, required this.controllerCompleter, required this.strokes, required this.polygons, required this.isEditing, required this.target, required this.onPanEnd, required this.onPanStart, required this.onPanUpdate});
  @override
  State<DrawingMap> createState() => _DrawinMapState();
}

class _DrawinMapState extends State<DrawingMap>{
  @override 
  Widget build(BuildContext context) {
    return Stack(
      children: [
            //mapa do google
            GoogleMap(
              key: widget.mapKey,
              // incia a camêra no centro da fazenda
              initialCameraPosition: CameraPosition(target: widget.target, zoom: 16.8),
              // adiciona os polygons ao mapa
              polygons: widget.polygons,
              // adiciona o controller assim q o mapa for criado
              onMapCreated: (controller) => widget.controllerCompleter.complete(controller),
              // define o tipo de mapa como satélite
              mapType: MapType.satellite,
              ),
              // ignora o painter se o isEditing for falso
              IgnorePointer(
                ignoring: !widget.isEditing,
                child: GestureDetector(
                  onPanStart: widget.onPanStart,
                  onPanUpdate:  (details) async {
                      if (!widget.isEditing) return;

                      final RenderBox mapBox = widget.mapKey.currentContext!.findRenderObject() as RenderBox;
                      final localPosition = mapBox.globalToLocal(details.globalPosition);

                      // se a borracha estiver selecionada
                      if (widget.eraserSelected) {
                        // se os strokes não estiverem vazios, ele deleta os strokes
                        if (widget.strokes.isNotEmpty) {
                          // Apaga pontos do stroke atual
                          setState(() {
                            for (var stroke in widget.strokes) {
                              stroke.points.removeWhere((p) => (p - localPosition).distance < 20);
                            }
                          // remove strokes sem pontos
                          widget.strokes.removeWhere((s) => s.points.isEmpty);
                    });
                        //se estiverem, deleta os poligonos já salvos
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
              // se estivemos editando adicionamos a botão de apagar o desenho
              if (widget.isEditing)
              Positioned(
                right: 10,
                top: 10,
                child: ElevatedButton(
                  style: ButtonStyle(backgroundColor: WidgetStatePropertyAll(Colors.red),
                  shape: MaterialStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20), // bordas arredondadas
                      ),
                    ),
                    minimumSize: WidgetStatePropertyAll(const Size(30, 40)),
                  ),
                  onPressed: () async {
                    // adicionamos um dialog para melhor UI, assim o user não apaga o desenho sem querer
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Deletar desenho?'),
                        content: const Text('Tem certeza que quer apagar este desenho da nuvem?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Deletar')),
                        ],
                      ),
                    );
                    // caso ele confirme, ele apaga os dados da nuvem do desenho
                    if (confirm == true) {
                      widget.apagarDesenho(widget.weekNumber);
                    }
                    },
                  child: Icon(Icons.delete, color: Colors.white,),
                  )),
              // se o estado de loading estiver como true, criamos um conatiner por cima do mapa com um spinner indicando que as informações estão sendo carregadas
              if (widget.isLoading)
                  Container(
                    color: Colors.black38, // leve overlay
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white,),
                    ),
                  ),
              ],);
  }
}
