import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/console.dart';
import '../models/jogo.dart';
import '../models/acessorio.dart';
import 'database_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart';

/// Serviço de armazenamento que fornece uma interface uniforme independente da plataforma
class StorageService {
  static final StorageService instance = StorageService._init();

  StorageService._init();

  // Chaves para armazenamento em SharedPreferences
  static const String _consolesKey = 'consoles';
  static const String _jogosKey = 'jogos';
  static const String _acessoriosKey = 'acessorios';

  // Método para salvar um console
  Future<String> salvarConsole(Console console) async {
    if (kIsWeb) {
      return _salvarConsoleWeb(console);
    } else {
      return DatabaseService.instance.criarConsole(console);
    }
  }

  // Método para salvar um jogo
  Future<String> salvarJogo(Jogo jogo) async {
    if (kIsWeb) {
      return _salvarJogoWeb(jogo);
    } else {
      return DatabaseService.instance.criarJogo(jogo);
    }
  }

  // Método para salvar um acessório
  Future<String> salvarAcessorio(Acessorio acessorio) async {
    if (kIsWeb) {
      return _salvarAcessorioWeb(acessorio);
    } else {
      return DatabaseService.instance.criarAcessorio(acessorio);
    }
  }

  // Método para buscar todos os consoles
  Future<List<Console>> buscarConsoles() async {
    if (kIsWeb) {
      return _buscarConsolesWeb();
    } else {
      return DatabaseService.instance.buscarConsoles();
    }
  }

  // Método para buscar todos os jogos
  Future<List<Jogo>> buscarJogos() async {
    if (kIsWeb) {
      return _buscarJogosWeb();
    } else {
      return DatabaseService.instance.buscarJogos();
    }
  }

  // Método para buscar jogos por console
  Future<List<Jogo>> buscarJogosPorConsole(String consoleId) async {
    if (kIsWeb) {
      return _buscarJogosPorConsoleWeb(consoleId);
    } else {
      return DatabaseService.instance.buscarJogosPorConsole(consoleId);
    }
  }

  // Método para buscar todos os acessórios
  Future<List<Acessorio>> buscarAcessorios() async {
    if (kIsWeb) {
      return _buscarAcessoriosWeb();
    } else {
      return DatabaseService.instance.buscarAcessorios();
    }
  }

  // Método para buscar acessórios por console
  Future<List<Acessorio>> buscarAcessoriosPorConsole(String consoleId) async {
    if (kIsWeb) {
      return _buscarAcessoriosPorConsoleWeb(consoleId);
    } else {
      return DatabaseService.instance.buscarAcessoriosPorConsole(consoleId);
    }
  }

  // Método para atualizar um console
  Future<bool> atualizarConsole(Console console) async {
    if (kIsWeb) {
      return _atualizarConsoleWeb(console);
    } else {
      final result = await DatabaseService.instance.atualizarConsole(console);
      return result > 0;
    }
  }

  // Método para atualizar um jogo
  Future<bool> atualizarJogo(Jogo jogo) async {
    if (kIsWeb) {
      return _atualizarJogoWeb(jogo);
    } else {
      final result = await DatabaseService.instance.atualizarJogo(jogo);
      return result > 0;
    }
  }

  // Método para atualizar um acessório
  Future<bool> atualizarAcessorio(Acessorio acessorio) async {
    if (kIsWeb) {
      return _atualizarAcessorioWeb(acessorio);
    } else {
      final result = await DatabaseService.instance.atualizarAcessorio(
        acessorio,
      );
      return result > 0;
    }
  }

  // Método para deletar um console
  Future<bool> deletarConsole(String id) async {
    if (kIsWeb) {
      return _deletarConsoleWeb(id);
    } else {
      final result = await DatabaseService.instance.deletarConsole(id);
      return result > 0;
    }
  }

  // Método para deletar um jogo
  Future<bool> deletarJogo(String id) async {
    if (kIsWeb) {
      return _deletarJogoWeb(id);
    } else {
      final result = await DatabaseService.instance.deletarJogo(id);
      return result > 0;
    }
  }

  // Método para deletar um acessório
  Future<bool> deletarAcessorio(String id) async {
    if (kIsWeb) {
      return _deletarAcessorioWeb(id);
    } else {
      final result = await DatabaseService.instance.deletarAcessorio(id);
      return result > 0;
    }
  }

  // Método para exportar todos os dados
  Future<Map<String, dynamic>> exportarDados() async {
    if (kIsWeb) {
      return _exportarDadosWeb();
    } else {
      return DatabaseService.instance.exportarDados();
    }
  }

  // Método para importar dados
  Future<bool> importarDados(Map<String, dynamic> dados) async {
    if (kIsWeb) {
      return _importarDadosWeb(dados);
    } else {
      return DatabaseService.instance.importarDados(dados);
    }
  }

  // Método para exportar dados para um arquivo
  Future<String> exportarParaArquivo() async {
    final dados = await exportarDados();
    final jsonString = json.encode(dados);
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/my_games_backup.json';
    final file = File(path);
    await file.writeAsString(jsonString);
    return path;
  }

  // Método para importar dados de um arquivo
  Future<bool> importarDeArquivo(String caminho) async {
    try {
      final file = File(caminho);
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final dados = json.decode(jsonString);
        return await importarDados(dados);
      }
      return false;
    } catch (e) {
      print('Erro ao importar dados: $e');
      return false;
    }
  }

  // Método para exportar dados para Excel
  Future<String> exportarParaExcel() async {
    final dados = await exportarDados();

    // Criar um novo documento Excel
    final excel = Excel.createExcel();

    // Remover a planilha padrão
    excel.delete('Sheet1');

    // Criar planilha de consoles
    final consolesSheet = excel['Consoles'];

    // Adicionar cabeçalhos
    consolesSheet.appendRow(
      [
        'ID',
        'Nome',
        'Data de Lançamento',
        'URL da Foto',
      ].map((header) => TextCellValue(header)).toList(),
    );

    // Adicionar dados de consoles
    for (var consoleMap in dados['consoles']) {
      consolesSheet.appendRow([
        TextCellValue(consoleMap['id']),
        TextCellValue(consoleMap['nome']),
        TextCellValue(consoleMap['dataLancamento'] ?? ''),
        TextCellValue(consoleMap['foto'] ?? ''),
      ]);
    }

    // Criar planilha de jogos
    final jogosSheet = excel['Jogos'];

    // Adicionar cabeçalhos
    jogosSheet.appendRow(
      [
        'ID',
        'Nome',
        'Console ID',
        'Data de Lançamento',
        'Data de Compra',
        'Data Finalizado',
        'Última Vez Jogado',
        'Nota Pessoal',
        'Original',
        'Bom Estado',
        'Tem Capa/Acessórios',
        'URL da Capa',
      ].map((header) => TextCellValue(header)).toList(),
    );

    // Adicionar dados de jogos
    for (var jogoMap in dados['jogos']) {
      jogosSheet.appendRow([
        TextCellValue(jogoMap['id']),
        TextCellValue(jogoMap['nome']),
        TextCellValue(jogoMap['consoleId']),
        TextCellValue(jogoMap['dataLancamento'] ?? ''),
        TextCellValue(jogoMap['dataCompra'] ?? ''),
        TextCellValue(jogoMap['dataFinalizado'] ?? ''),
        TextCellValue(jogoMap['ultimaVezJogado'] ?? ''),
        TextCellValue(jogoMap['notaPessoal']?.toString() ?? '0'),
        TextCellValue(jogoMap['isOriginal'] == true ? 'Sim' : 'Não'),
        TextCellValue(jogoMap['bomEstado'] == true ? 'Sim' : 'Não'),
        TextCellValue(jogoMap['temCapaEAcessorios'] == true ? 'Sim' : 'Não'),
        TextCellValue(jogoMap['capa'] ?? ''),
      ]);
    }

    // Criar planilha de acessórios
    final acessoriosSheet = excel['Acessórios'];

    // Adicionar cabeçalhos
    acessoriosSheet.appendRow(
      [
        'ID',
        'Nome',
        'Console ID',
        'Descrição',
        'Última Vez Testado',
        'URL da Foto',
      ].map((header) => TextCellValue(header)).toList(),
    );

    // Adicionar dados de acessórios
    for (var acessorioMap in dados['acessorios']) {
      acessoriosSheet.appendRow([
        TextCellValue(acessorioMap['id']),
        TextCellValue(acessorioMap['nome']),
        TextCellValue(acessorioMap['consoleId']),
        TextCellValue(acessorioMap['descricao'] ?? ''),
        TextCellValue(acessorioMap['ultimaVezTestado'] ?? ''),
        TextCellValue(acessorioMap['foto'] ?? ''),
      ]);
    }

    // Salvar o arquivo
    final bytes = excel.encode();

    if (bytes != null) {
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/my_games_export.xlsx';
      final file = File(path);
      await file.writeAsBytes(bytes);
      return path;
    }

    throw Exception('Falha ao gerar arquivo Excel');
  }

  // Implementações para Web usando SharedPreferences
  Future<String> _salvarConsoleWeb(Console console) async {
    final prefs = await SharedPreferences.getInstance();
    final consoles = await _buscarConsolesWeb();

    // Gerando um ID para o novo console
    final id = const Uuid().v4();
    final novoConsole = Console(
      id: id,
      nome: console.nome,
      foto: console.foto,
      dataLancamento: console.dataLancamento,
    );

    consoles.add(novoConsole);

    // Salvando a lista atualizada
    final consolesJson = consoles.map((c) => c.toMap()).toList();
    await prefs.setString(_consolesKey, jsonEncode(consolesJson));

    return id;
  }

  Future<String> _salvarJogoWeb(Jogo jogo) async {
    final prefs = await SharedPreferences.getInstance();
    final jogos = await _buscarJogosWeb();

    // Gerando um ID para o novo jogo
    final id = const Uuid().v4();
    final novoJogo = Jogo(
      id: id,
      nome: jogo.nome,
      capa: jogo.capa,
      dataLancamento: jogo.dataLancamento,
      consoleId: jogo.consoleId,
      notaPessoal: jogo.notaPessoal,
      dataCompra: jogo.dataCompra,
      dataFinalizado: jogo.dataFinalizado,
      ultimaVezJogado: jogo.ultimaVezJogado,
      isOriginal: jogo.isOriginal,
      bomEstado: jogo.bomEstado,
      temCapaEAcessorios: jogo.temCapaEAcessorios,
    );

    jogos.add(novoJogo);

    // Salvando a lista atualizada
    final jogosJson = jogos.map((j) => j.toMap()).toList();
    await prefs.setString(_jogosKey, jsonEncode(jogosJson));

    return id;
  }

  Future<String> _salvarAcessorioWeb(Acessorio acessorio) async {
    final prefs = await SharedPreferences.getInstance();
    final acessorios = await _buscarAcessoriosWeb();

    // Gerando um ID para o novo acessório
    final id = const Uuid().v4();
    final novoAcessorio = Acessorio(
      id: id,
      nome: acessorio.nome,
      consoleId: acessorio.consoleId,
      descricao: acessorio.descricao,
      foto: acessorio.foto,
      ultimaVezTestado: acessorio.ultimaVezTestado,
    );

    acessorios.add(novoAcessorio);

    // Salvando a lista atualizada
    final acessoriosJson = acessorios.map((a) => a.toMap()).toList();
    await prefs.setString(_acessoriosKey, jsonEncode(acessoriosJson));

    return id;
  }

  Future<List<Console>> _buscarConsolesWeb() async {
    final prefs = await SharedPreferences.getInstance();
    final consolesJson = prefs.getString(_consolesKey);

    if (consolesJson == null || consolesJson.isEmpty) {
      return [];
    }

    final List<dynamic> consolesMap = jsonDecode(consolesJson);
    return consolesMap.map((map) => Console.fromMap(map)).toList();
  }

  Future<List<Jogo>> _buscarJogosWeb() async {
    final prefs = await SharedPreferences.getInstance();
    final jogosJson = prefs.getString(_jogosKey);

    if (jogosJson == null || jogosJson.isEmpty) {
      return [];
    }

    final List<dynamic> jogosMap = jsonDecode(jogosJson);
    return jogosMap.map((map) => Jogo.fromMap(map)).toList();
  }

  Future<List<Jogo>> _buscarJogosPorConsoleWeb(String consoleId) async {
    final jogos = await _buscarJogosWeb();
    return jogos.where((jogo) => jogo.consoleId == consoleId).toList();
  }

  Future<List<Acessorio>> _buscarAcessoriosWeb() async {
    final prefs = await SharedPreferences.getInstance();
    final acessoriosJson = prefs.getString(_acessoriosKey);

    if (acessoriosJson == null || acessoriosJson.isEmpty) {
      return [];
    }

    final List<dynamic> acessoriosMap = jsonDecode(acessoriosJson);
    return acessoriosMap.map((map) => Acessorio.fromMap(map)).toList();
  }

  Future<List<Acessorio>> _buscarAcessoriosPorConsoleWeb(
    String consoleId,
  ) async {
    final acessorios = await _buscarAcessoriosWeb();
    return acessorios
        .where((acessorio) => acessorio.consoleId == consoleId)
        .toList();
  }

  Future<bool> _atualizarConsoleWeb(Console console) async {
    final prefs = await SharedPreferences.getInstance();
    final consoles = await _buscarConsolesWeb();

    // Encontrando o índice do console a ser atualizado
    final index = consoles.indexWhere((c) => c.id == console.id);
    if (index == -1) {
      return false;
    }

    // Atualizando o console na lista
    consoles[index] = console;

    // Salvando a lista atualizada
    final consolesJson = consoles.map((c) => c.toMap()).toList();
    await prefs.setString(_consolesKey, jsonEncode(consolesJson));

    return true;
  }

  Future<bool> _atualizarJogoWeb(Jogo jogo) async {
    final prefs = await SharedPreferences.getInstance();
    final jogos = await _buscarJogosWeb();

    // Encontrando o índice do jogo a ser atualizado
    final index = jogos.indexWhere((j) => j.id == jogo.id);
    if (index == -1) {
      return false;
    }

    // Atualizando o jogo na lista
    jogos[index] = jogo;

    // Salvando a lista atualizada
    final jogosJson = jogos.map((j) => j.toMap()).toList();
    await prefs.setString(_jogosKey, jsonEncode(jogosJson));

    return true;
  }

  Future<bool> _atualizarAcessorioWeb(Acessorio acessorio) async {
    final prefs = await SharedPreferences.getInstance();
    final acessorios = await _buscarAcessoriosWeb();

    // Encontrando o índice do acessório a ser atualizado
    final index = acessorios.indexWhere((a) => a.id == acessorio.id);
    if (index == -1) {
      return false;
    }

    // Atualizando o acessório na lista
    acessorios[index] = acessorio;

    // Salvando a lista atualizada
    final acessoriosJson = acessorios.map((a) => a.toMap()).toList();
    await prefs.setString(_acessoriosKey, jsonEncode(acessoriosJson));

    return true;
  }

  Future<bool> _deletarConsoleWeb(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final consoles = await _buscarConsolesWeb();

    // Removendo o console da lista
    final originalLength = consoles.length;
    consoles.removeWhere((c) => c.id == id);

    if (consoles.length == originalLength) {
      return false;
    }

    // Salvando a lista atualizada
    final consolesJson = consoles.map((c) => c.toMap()).toList();
    await prefs.setString(_consolesKey, jsonEncode(consolesJson));

    return true;
  }

  Future<bool> _deletarJogoWeb(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final jogos = await _buscarJogosWeb();

    // Removendo o jogo da lista
    final originalLength = jogos.length;
    jogos.removeWhere((j) => j.id == id);

    if (jogos.length == originalLength) {
      return false;
    }

    // Salvando a lista atualizada
    final jogosJson = jogos.map((j) => j.toMap()).toList();
    await prefs.setString(_jogosKey, jsonEncode(jogosJson));

    return true;
  }

  Future<bool> _deletarAcessorioWeb(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final acessorios = await _buscarAcessoriosWeb();

    // Removendo o acessório da lista
    final originalLength = acessorios.length;
    acessorios.removeWhere((a) => a.id == id);

    if (acessorios.length == originalLength) {
      return false;
    }

    // Salvando a lista atualizada
    final acessoriosJson = acessorios.map((a) => a.toMap()).toList();
    await prefs.setString(_acessoriosKey, jsonEncode(acessoriosJson));

    return true;
  }

  Future<Map<String, dynamic>> _exportarDadosWeb() async {
    final consoles = await _buscarConsolesWeb();
    final jogos = await _buscarJogosWeb();
    final acessorios = await _buscarAcessoriosWeb();

    return {
      'consoles': consoles.map((c) => c.toMap()).toList(),
      'jogos': jogos.map((j) => j.toMap()).toList(),
      'acessorios': acessorios.map((a) => a.toMap()).toList(),
    };
  }

  Future<bool> _importarDadosWeb(Map<String, dynamic> dados) async {
    final prefs = await SharedPreferences.getInstance();

    try {
      // Limpar dados existentes
      await prefs.remove(_consolesKey);
      await prefs.remove(_jogosKey);
      await prefs.remove(_acessoriosKey);

      // Importar novos dados
      if (dados.containsKey('consoles')) {
        await prefs.setString(_consolesKey, jsonEncode(dados['consoles']));
      }

      if (dados.containsKey('jogos')) {
        await prefs.setString(_jogosKey, jsonEncode(dados['jogos']));
      }

      if (dados.containsKey('acessorios')) {
        await prefs.setString(_acessoriosKey, jsonEncode(dados['acessorios']));
      }

      return true;
    } catch (e) {
      print('Erro ao importar dados: $e');
      return false;
    }
  }
}
