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
  await dotenv.load(fileName: ".env"); // liga o código ao .env
  runApp(const MyApp());
  
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final Completer<GoogleMapController> _controller = Completer(); // cria o controller para o mapa
  static const LatLng _center = LatLng(-23.0737875, -46.5240538); // centro da fazenda
  bool isEditing = false; // define o estado isEditing para falso
  bool doencaSelected = false; // define o estado da tag doenças para falso
  bool pragasSelected = false; // define o estado da tag pragas para falso
  bool brushSelected = false; // define o estado do brush para falso
  bool eraserSelected = false; // define o estado da borracha para falso
  
  Color selectedColor = Colors.transparent; // inicia a cor do brush como transparente
  final GlobalKey _paintKey = GlobalKey(); // cria uma key para o sistema de desenho 
  final GlobalKey _mapKey = GlobalKey();// cria uma key para o mapa
  final DrawingService drawingService = DrawingService(); // cria um objeto da classe DrawingService responsável por todas as funcionalidades de desenho
  late DrawingController drawingController; // cria um objeto da classe DrawingController responsável por ligar o app ao DrawingService 
  late CloudService cloudService; // cria um objeto da classe CloudService responsável por ligar o app à API da AWS
  int weekNumber = 0; // cria a variável do número da semana 
  String jsonDesenho = ""; // cria a variável que guarda o desenho como json antes de salvá-lo 
  bool isLoading = false; //define o estado do loading para falso


    @override
  void initState() {
    super.initState();

    // inicia o objeto da classe DrawingController
    drawingController = DrawingController(
    drawingService: drawingService,
    mapKey: _mapKey,
    mapController: _controller,
  );


    // define que o app só podera ser acessado na vertical
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    // esconde a barra de navegação do celular para uma melhor interação com o mapa
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // carrega as variáveis do .env
    String username = dotenv.get('USERNAME');
    String senha = dotenv.get('SENHA');
    String baseUrl = dotenv.get('BASEURL');

  // inicia o objeto do cludService
  cloudService = CloudService(baseurl: baseUrl, username: username, senha: senha);
  }


  // função que define a cor do brush baseado na tag selecionada
  Color getColor(){
    if (doencaSelected) return Colors.red;
    if (pragasSelected) return Colors.blue;
    return Colors.transparent;
  }


  // função que permite a mudança da tag selecionada
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

  // função que permite a mudança do brush para a borracha e vice-versa
  void selectBrush(String type){
    setState(() {
      if(type == "brush"){
        brushSelected = true;
        eraserSelected = false;
        doencaSelected = true;
        pragasSelected = false;
      } else{
        // não deixa uma tag selecionada enquanto a borracha estiver ativa
        brushSelected = false;
        eraserSelected = true;
        doencaSelected = false;
        pragasSelected = false;
      }
    });
  }



// função que permite sair e entrar do modo edição
  void toggleEditing(){
    setState(() {
      if (isEditing){
        isEditing = false;
        doencaSelected = false;
        brushSelected = false;
        pragasSelected = false;
        eraserSelected = false;
        // salva os strokes (linhas), para que o user possa navegar pelo mapa e adicionar mais em outras partes
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

// função que salva o desenho pela API da AWS
  void saveDrawing(){
    setState(() {
      // salva os Strokes (linhas) em polygons (linhas usadas no map)
      drawingService.saveAllStrokes();
      // transforma a lista de polygons em um JSON
      jsonDesenho = drawingService.savePolygonsToJson();
      // salva os dados no banco de dados da AWS
      cloudService.salvarDesenho(jsonDesenho, weekNumber);
      // sai do modo edição
      isEditing = false;
    });
  }

    // carrega desenhos já salvos na nuvem, baseado no número da semana
   Future<void> loadDrawing(int weekNumber) async{
    // ele muda o loading para true, enquanto faz a requisição para a api
    setState(() { isLoading = true; });
    try{
      // ele tenta acessar o item no banco de dados com o número da semana dele
      String resposta = await cloudService.carregarDesenho(weekNumber);
      // caso ele encontre, o drawingService carrega os polygons vindos do JSON
      setState(() {
        drawingService.loadPolygonsFromJson(resposta);
      });
    } catch(e){
      // caso der erro, ele printa o erro  
      print("error $e");
    }
    finally{
      // em ambos os casos, ele retorna o loading para false
      setState(() {
        isLoading = false;
      });
    }
  }


  // deleta um desenho do banco de dados baseado no número da semana
  Future<void> deleteDrawing(int weekNumber) async{
    try{
      // tenta deletar o item do banco de dados
      await cloudService.apagarDesenho(weekNumber);
      // se conseguir apaga os polygons e strokes da tela e sai do modo editar
      setState(() {
        drawingService.clearAll();
        toggleEditing();
      });
    } catch (e){
      print('error $e');
    }
  }

  // unção que atualiza o número da semana
  void attWeekNumber(int number){
    setState(() {
      weekNumber = number;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
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
              // caso esteja editando, mostra o elemento "Cancelar" e "Salvar"
            if (isEditing)
      Row(
        mainAxisAlignment: MainAxisAlignment.end, 
        children: [
          GestureDetector(
            onTap: toggleEditing, //sai do modo editar
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
            onTap: saveDrawing, // salva o desenho
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
       // caso não, somente o elemento "Editar"
    else
      Row(
        mainAxisAlignment: MainAxisAlignment.end, // Alinha à direita
        children: [
          GestureDetector(
            onTap: toggleEditing, // entra no modo editar
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
            // Widget do navegador de semanas, responsável por atualizar o número da semana e carregar os desenhos
            WeekNavigator(attWeekNumber: attWeekNumber, loadDrawing: loadDrawing,),
            const SizedBox(height: 60),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0), 
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Expanded(
                    child:
                    // Widget da "caixa de ferramentas", responsável pela escolha das tags e do brush ou borracha 
                    ToolBox(isEditing: isEditing, doencaSelected: doencaSelected, pragasSelected: pragasSelected, brushSelected: brushSelected, eraserSelected: eraserSelected, onTagSelected: selectTag, onBrushSelected: selectBrush)
                    )
                ],
              ),
            ),
            SizedBox(height: 10,),
            Expanded(child: 
              // Widget do mapa e da funcionalidade de desenho
              DrawingMap(
                apagarDesenho: deleteDrawing, // passamos a função de deletar desenhos
                weekNumber: weekNumber, // o dia da semana
                isLoading: isLoading, // se estamos carregando um desenho
                mapKey: _mapKey, // a global key para o mapa
                paintKey: _paintKey, // a glopal key para o desenho
                controllerCompleter: _controller, // passamos o controller do mapa
                strokes: drawingService.strokes, // passamos os strokes (linhas)
                polygons: drawingService.polygons, // passamos os polygons (linhas usadas pelo mapa)
                isEditing: isEditing, // passamos o estado do editing
                target: _center, // passamos as cordenadas do centro da fazenda
                eraserSelected: eraserSelected, // passamos o estado do eraserSelected
                // função quando iniciamos um traço
                onPanStart: (details) async {
                  await drawingController.onPanStart(details, getColor);
                  setState(() {}); // atualiza o estado da tela
                },
                // função a cada novo traço realizado
                onPanUpdate: (details) async {
                  await drawingController.onPanUpdate(
                    details,
                    isEditing: isEditing,
                    eraserSelected: eraserSelected,
                  );
                  setState(() {}); // atualiza o estado da tela
                },
                // função quando terminamos os traços
                onPanEnd: (_) {
                  drawingController.onPanEnd();
                  setState(() {}); // atualiza o estado da tela
                },
                eraseAtLocalPosition: drawingController.onEraseTap, //função que apaga polygons ao clicar
              ),
                ),
          ],
        ),
      ),
    );
  }
}