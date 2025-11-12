import 'package:http/http.dart' as http;
import 'dart:convert';

class CloudService{
  final String baseurl;
  final String username;
  final String senha;

  CloudService({required this.baseurl, required this.username, required this.senha});

  Future<void> salvarDesenho(String drawdata, int weekNumber) async{
    String urlEndpoint = "${baseurl}save-draw";
    Uri finalUrl = Uri.parse(urlEndpoint);
    Map<String, dynamic> payload = {
      "username": username,
      "password": senha,
      "weekNumber": weekNumber,
      "drawData": drawdata,
    };
    try{
      final response = await http.post(
        finalUrl,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Dados enviados com sucesso!');
      } else {
        print('Erro no envio: ${response.statusCode}');
        print('Erro no envio: ${response.body}');
      }
    } catch (error){
      print('Error  erro: $error');
    }
  }

  Future<String> carregarDesenho(int weekNumber) async{
    String urlEndpoint = "${baseurl}get-draw";
    Uri finalUrl = Uri.parse(urlEndpoint);
    Map<String, dynamic> payload = {
      "username": username,
      "password": senha,
      "weekNumber": weekNumber,
    };
    try{
      final response = await http.post(
        finalUrl,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Dados carregados com sucesso!');
        print('response body: ${response.body}');
        return response.body;
      } else {
        print('Erro no envio: ${response.statusCode}');
        print('Erro no envio: ${response.body}');
        return "";
      }
    } catch (error){
      print('Error  erro: $error');
      return "";
    }
  }

  Future<void> apagarDesenho(int weekNumber) async{
    String urlEndpoint = "${baseurl}delete-draw";
    Uri finalUrl = Uri.parse(urlEndpoint);
    Map<String, dynamic> payload = {
      "username": username,
      "password": senha,
      "weekNumber": weekNumber,
    };
    try{
      final response = await http.post(
        finalUrl,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Dados Apagados com sucesso!');
      } else {
        print('Erro no envio: ${response.statusCode}');
        print('Erro no envio: ${response.body}');
      }
    } catch (error){
      print('Error  erro: $error');
    }
  }
}