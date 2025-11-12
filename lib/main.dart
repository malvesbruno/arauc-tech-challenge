import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/services.dart';
import 'package:teste_tecnico/widgets/weekNavigator.dart';
import './widgets/toolBox.dart';
import './widgets/drawingMap.dart';
import './services/drawingService.dart';
import 'controllers/drawingController.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import './services/cloudService.dart';


Future<void> main() async{
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
  
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String semana = "Semana 45 (03/11 - 09/11)";
  final Completer<GoogleMapController> _controller = Completer();
  static const LatLng _center = LatLng(-23.0737875, -46.5240538); // centro da fazenda
  bool isEditing = false;
  bool doencaSelected = false;
  bool pragasSelected = false;
  bool brushSelected = false;
  bool eraserSelected = false;
  
  Color selectedColor = Colors.transparent;
  final GlobalKey _paintKey = GlobalKey();
  final GlobalKey _mapKey = GlobalKey();
  final DrawingService drawingService = DrawingService();
  late DrawingController drawingController;
  late CloudService cloudService;
  int weekNumber = 0;
  String jsonDesenho = "";


    @override
  void initState() {
    super.initState();
    drawingController = DrawingController(
    drawingService: drawingService,
    mapKey: _mapKey,
    mapController: _controller,
  );


    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    String username = dotenv.get('USERNAME');
    String senha = dotenv.get('SENHA');
    String baseUrl = dotenv.get('BASEURL');

  cloudService = CloudService(baseurl: baseUrl, username: username, senha: senha);
  }


  Color getColor(){
    if (doencaSelected) return Colors.red;
    if (pragasSelected) return Colors.blue;
    return Colors.transparent;
  }


  void selectTag(String label){
    
    setState(() {
      if (label == 'Doenças'){
        doencaSelected = true;
        pragasSelected = false;
    } else{
      pragasSelected = true;
      doencaSelected = false;
    }
    });
  }

  void selectBrush(String type){
    setState(() {
      if(type == "brush"){
        brushSelected = true;
        eraserSelected = false;
        doencaSelected = true;
        pragasSelected = false;
      } else{
        brushSelected = false;
        eraserSelected = true;
        doencaSelected = false;
        pragasSelected = false;
      }
    });
  }


  void toggleEditing(){
    setState(() {

      if (isEditing){
        isEditing = false;
        doencaSelected = false;
        brushSelected = true;
        pragasSelected = false;
        eraserSelected = false;
        drawingService.saveAllStrokes();
      }
      else{
        isEditing= true;
        doencaSelected = true;
        brushSelected = true;
        pragasSelected = false;
        eraserSelected = false;
      }
    });
  }

  void saveDrawing(){
    setState(() {
      drawingService.saveAllStrokes();
      jsonDesenho = drawingService.savePolygonsToJson();
      print('DEBUG ${jsonDesenho}');
      print('DEBUG ${weekNumber}');
      //cloudService.salvarDesenho('hello', weekNumber);
      
    });
  }

  void attWeekNumber(int number){
    setState(() {
      weekNumber = number;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFFF1F5FF),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                "Mapa",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25, fontFamily: "overpass"),
              ),
            if (isEditing)
      Row(
        mainAxisAlignment: MainAxisAlignment.end, // Alinha à direita sem Spacer
        children: [
          GestureDetector(
            onTap: toggleEditing,
            child: Text(
              "Cancelar",
              style: TextStyle(
                fontSize: 20,
                color: Colors.black.withOpacity(0.2),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(width: 20),
          GestureDetector(
            onTap: saveDrawing,
            child: Text(
              "Salvar",
              style: const TextStyle(
                fontSize: 20,
                color: Color(0xFF004FFF),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      )
    else
      Row(
        mainAxisAlignment: MainAxisAlignment.end, // Alinha à direita
        children: [
          GestureDetector(
            onTap: toggleEditing,
            child: Text(
              "Editar",
              style: const TextStyle(
                fontSize: 20,
                color: Color(0xFF004FFF),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
            ],
          ),
        ),
        backgroundColor: const Color(0xFFF1F5FF), 
        body: Column(
          children: [
            const SizedBox(height: 40),
            WeekNavigator(attWeekNumber: attWeekNumber,),
            const SizedBox(height: 60),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0), 
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Expanded(child: ToolBox(isEditing: isEditing, doencaSelected: doencaSelected, pragasSelected: pragasSelected, brushSelected: brushSelected, eraserSelected: eraserSelected, onTagSelected: selectTag, onBrushSelected: selectBrush))
                ],
              ),
            ),
            SizedBox(height: 10,),
            Expanded(child: 
              DrawingMap(
  mapKey: _mapKey,
  paintKey: _paintKey,
  controllerCompleter: _controller,
  strokes: drawingService.strokes,
  polygons: drawingService.polygons,
  isEditing: isEditing,
  target: _center,
  eraserSelected: eraserSelected,
  onPanStart: (details) async {
    await drawingController.onPanStart(details, getColor);
    setState(() {});
  },
  onPanUpdate: (details) async {
    await drawingController.onPanUpdate(
      details,
      isEditing: isEditing,
      eraserSelected: eraserSelected,
    );
    setState(() {});
  },
  onPanEnd: (_) {
    drawingController.onPanEnd();
    setState(() {});
  },
  eraseAtLocalPosition: drawingController.onEraseTap,
),
                )
          ],
        ),
      ),
    );
  }
}