import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  // Lê variáveis de ambiente do arquivo .env
  final String baseUrl = dotenv.get(
    'RAWG_API_BASE_URL',
    fallback: 'https://api.rawg.io/api',
  );
  final String apiKey = dotenv.get('RAWG_API_KEY');

  // Buscar jogos com opção de autocomplete
  Future<List<dynamic>> buscarJogos(String nome, {int limite = 10}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/games?search=$nome&page_size=$limite&key=$apiKey'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body)['results'];
      } else {
        throw Exception('Erro ao buscar jogos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Falha ao buscar jogos: $e');
    }
  }

  // Buscar plataformas (consoles)
  Future<List<dynamic>> buscarPlataformas({int limite = 20}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/platforms?page_size=$limite&key=$apiKey'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body)['results'];
      } else {
        throw Exception('Erro ao buscar plataformas: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Falha ao buscar plataformas: $e');
    }
  }

  // Buscar plataformas por nome (para autocomplete)
  Future<List<dynamic>> buscarPlataformasPorNome(
    String nome, {
    int limite = 5,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$baseUrl/platforms?search=$nome&page_size=$limite&key=$apiKey',
        ),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body)['results'];
      } else {
        throw Exception('Erro ao buscar plataformas: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Falha ao buscar plataformas: $e');
    }
  }

  Future<Map<String, dynamic>?> buscarDetalhesJogo(int jogoId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/games/$jogoId?key=$apiKey'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Erro ao buscar detalhes do jogo: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Falha ao buscar detalhes do jogo: $e');
    }
  }
}
