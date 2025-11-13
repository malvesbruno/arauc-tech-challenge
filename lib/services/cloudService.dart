import 'package:http/http.dart' as http;
import 'dart:convert';


// Classe Cloud Service, responsável por ligar o app à API do AWS
/// [baseurl] url base da API
/// [username] username de credencial
/// [senha] password de credencial

class CloudService{
  // requer a baseurl, username e senha
  final String baseurl;
  final String username;
  final String senha;
  // inciamos a classe, passando esses parêmetros como requirementos para que sempre sejam pedidos
  CloudService({required this.baseurl, required this.username, required this.senha});

  // função responsável por salvar o desenho, recebe o JSON dos polygons e o número da semana
  Future<void> salvarDesenho(String drawdata, int weekNumber) async{
    String urlEndpoint = "${baseurl}save-draw"; // cria a url com end-point 'save-draw'
    Uri finalUrl = Uri.parse(urlEndpoint); // transforma a string da url em um um Uri
    // cria o payload para a requisição
    Map<String, dynamic> payload = {
      "username": username,
      "password": senha,
      "weekNumber": weekNumber,
      "drawData": drawdata,
    };
    try{
      // tenta fazer a requisição na API
      final response = await http.post(
        finalUrl,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );
      // caso a resposta for 200 ou 201, os dados foram enviados com sucesso
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Dados enviados com sucesso!');
      } else {
        // caso seja outra, temos um erro no envio
        print('Erro no envio: ${response.statusCode}');
        print('Erro no envio: ${response.body}');
      }
    } catch (error){
      // caso ocorra outro erro, printamos ele
      print('Error  erro: $error');
    }
  }


  // função responsável por carregar desenhos baseado em o número da semana, recebe o número da semana
  Future<String> carregarDesenho(int weekNumber) async{
    String urlEndpoint = "${baseurl}get-draw"; // cria a url com end-point 'get-draw'
    Uri finalUrl = Uri.parse(urlEndpoint); // transforma a string da url em um um Uri
    // cria o payload para a requisição
    Map<String, dynamic> payload = {
      "username": username,
      "password": senha,
      "weekNumber": weekNumber,
    };
    try{
      // tenta fazer a requisição na API
      final response = await http.post(
        finalUrl,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );
      // caso a resposta for 200 ou 201, os dados foram carregados com sucesso
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Dados carregados com sucesso!');
        print('response body: ${response.body}');
        // retornamos os dados da resposta da API
        return response.body;
      } else {
        // caso seja outra, temos um erro no envio
        print('Erro no envio: ${response.statusCode}');
        print('Erro no envio: ${response.body}');
        // retornamos uma string vazia
        return "";
      }
    } catch (error){
      // caso ocorra outro erro, printamos ele
      print('Error  erro: $error');
      // retornamos uma string vazia
      return "";
    }
  }


  // função responsável por apagar desenhos baseado em o número da semana, recebe o número da semana
  Future<void> apagarDesenho(int weekNumber) async{
    String urlEndpoint = "${baseurl}delete-draw"; // cria a url com end-point 'delete-draw'
    Uri finalUrl = Uri.parse(urlEndpoint);// transforma a string da url em um um Uri
    // cria o payload para a requisição
    Map<String, dynamic> payload = {
      "username": username,
      "password": senha,
      "weekNumber": weekNumber,
    };
    try{
      // tenta fazer a requisição na API
      final response = await http.post(
        finalUrl,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );
      // caso a resposta for 200 ou 201, os dados foram deletados com sucesso
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Dados Apagados com sucesso!');
      } else {
         // caso seja outra, temos um erro na remoção
        print('Erro no envio: ${response.statusCode}');
        print('Erro no envio: ${response.body}');
      }
    } catch (error){
      // caso ocorra outro erro, printamos ele
      print('Error  erro: $error');
    }
  }
}