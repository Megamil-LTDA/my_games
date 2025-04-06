import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../models/console.dart';
import '../models/jogo.dart';
import '../models/acessorio.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('my_games.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE consoles (
        id TEXT PRIMARY KEY,
        nome TEXT NOT NULL,
        foto TEXT,
        dataLancamento TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE jogos (
        id TEXT PRIMARY KEY,
        nome TEXT NOT NULL,
        capa TEXT,
        dataLancamento TEXT,
        consoleId TEXT NOT NULL,
        notaPessoal REAL,
        dataCompra TEXT,
        dataFinalizado TEXT,
        ultimaVezJogado TEXT,
        isOriginal INTEGER DEFAULT 1,
        bomEstado INTEGER DEFAULT 1,
        temCapaEAcessorios INTEGER DEFAULT 1,
        FOREIGN KEY (consoleId) REFERENCES consoles (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE acessorios (
        id TEXT PRIMARY KEY,
        nome TEXT NOT NULL,
        consoleId TEXT NOT NULL,
        descricao TEXT,
        foto TEXT,
        ultimaVezTestado TEXT,
        FOREIGN KEY (consoleId) REFERENCES consoles (id)
      )
    ''');
  }

  // CRUD para Consoles
  Future<String> criarConsole(Console console) async {
    final db = await database;
    final id = const Uuid().v4();
    final novoConsole = Console(
      id: id,
      nome: console.nome,
      foto: console.foto,
      dataLancamento: console.dataLancamento,
    );

    await db.insert('consoles', novoConsole.toMap());
    return id;
  }

  Future<List<Console>> buscarConsoles() async {
    final db = await database;
    final maps = await db.query('consoles', orderBy: 'nome');
    return List.generate(maps.length, (i) => Console.fromMap(maps[i]));
  }

  Future<Console?> buscarConsole(String id) async {
    final db = await database;
    final maps = await db.query('consoles', where: 'id = ?', whereArgs: [id]);

    if (maps.isNotEmpty) {
      return Console.fromMap(maps.first);
    }
    return null;
  }

  Future<int> atualizarConsole(Console console) async {
    final db = await database;
    return await db.update(
      'consoles',
      console.toMap(),
      where: 'id = ?',
      whereArgs: [console.id],
    );
  }

  Future<int> deletarConsole(String id) async {
    final db = await database;
    return await db.delete('consoles', where: 'id = ?', whereArgs: [id]);
  }

  // CRUD para Jogos
  Future<String> criarJogo(Jogo jogo) async {
    final db = await database;
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
    );

    await db.insert('jogos', novoJogo.toMap());
    return id;
  }

  Future<List<Jogo>> buscarJogos() async {
    final db = await database;
    final maps = await db.query('jogos', orderBy: 'nome');
    return List.generate(maps.length, (i) => Jogo.fromMap(maps[i]));
  }

  Future<List<Jogo>> buscarJogosPorConsole(String consoleId) async {
    final db = await database;
    final maps = await db.query(
      'jogos',
      where: 'consoleId = ?',
      whereArgs: [consoleId],
      orderBy: 'nome',
    );
    return List.generate(maps.length, (i) => Jogo.fromMap(maps[i]));
  }

  Future<Jogo?> buscarJogo(String id) async {
    final db = await database;
    final maps = await db.query('jogos', where: 'id = ?', whereArgs: [id]);

    if (maps.isNotEmpty) {
      return Jogo.fromMap(maps.first);
    }
    return null;
  }

  Future<int> atualizarJogo(Jogo jogo) async {
    final db = await database;
    return await db.update(
      'jogos',
      jogo.toMap(),
      where: 'id = ?',
      whereArgs: [jogo.id],
    );
  }

  Future<int> deletarJogo(String id) async {
    final db = await database;
    return await db.delete('jogos', where: 'id = ?', whereArgs: [id]);
  }

  // CRUD para Acessórios
  Future<String> criarAcessorio(Acessorio acessorio) async {
    final db = await database;
    final id = const Uuid().v4();
    final novoAcessorio = Acessorio(
      id: id,
      nome: acessorio.nome,
      consoleId: acessorio.consoleId,
      descricao: acessorio.descricao,
      foto: acessorio.foto,
      ultimaVezTestado: acessorio.ultimaVezTestado,
    );

    await db.insert('acessorios', novoAcessorio.toMap());
    return id;
  }

  Future<List<Acessorio>> buscarAcessorios() async {
    final db = await database;
    final maps = await db.query('acessorios', orderBy: 'nome');
    return List.generate(maps.length, (i) => Acessorio.fromMap(maps[i]));
  }

  Future<List<Acessorio>> buscarAcessoriosPorConsole(String consoleId) async {
    final db = await database;
    final maps = await db.query(
      'acessorios',
      where: 'consoleId = ?',
      whereArgs: [consoleId],
      orderBy: 'nome',
    );
    return List.generate(maps.length, (i) => Acessorio.fromMap(maps[i]));
  }

  Future<Acessorio?> buscarAcessorio(String id) async {
    final db = await database;
    final maps = await db.query('acessorios', where: 'id = ?', whereArgs: [id]);

    if (maps.isNotEmpty) {
      return Acessorio.fromMap(maps.first);
    }
    return null;
  }

  Future<int> atualizarAcessorio(Acessorio acessorio) async {
    final db = await database;
    return await db.update(
      'acessorios',
      acessorio.toMap(),
      where: 'id = ?',
      whereArgs: [acessorio.id],
    );
  }

  Future<int> deletarAcessorio(String id) async {
    final db = await database;
    return await db.delete('acessorios', where: 'id = ?', whereArgs: [id]);
  }

  // Importação e Exportação de Dados
  Future<Map<String, dynamic>> exportarDados() async {
    final consoles = await buscarConsoles();
    final jogos = await buscarJogos();
    final acessorios = await buscarAcessorios();

    return {
      'consoles': consoles.map((c) => c.toMap()).toList(),
      'jogos': jogos.map((j) => j.toMap()).toList(),
      'acessorios': acessorios.map((a) => a.toMap()).toList(),
    };
  }

  Future<String> exportarParaArquivo() async {
    final dados = await exportarDados();
    final jsonString = json.encode(dados);
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/my_games_backup.json';
    final file = File(path);
    await file.writeAsString(jsonString);
    return path;
  }

  Future<bool> importarDados(Map<String, dynamic> dados) async {
    final db = await database;
    await db.transaction((txn) async {
      // Limpar tabelas
      await txn.delete('acessorios');
      await txn.delete('jogos');
      await txn.delete('consoles');

      // Importar consoles
      if (dados.containsKey('consoles')) {
        for (var item in dados['consoles']) {
          await txn.insert('consoles', item as Map<String, dynamic>);
        }
      }

      // Importar jogos
      if (dados.containsKey('jogos')) {
        for (var item in dados['jogos']) {
          await txn.insert('jogos', item as Map<String, dynamic>);
        }
      }

      // Importar acessórios
      if (dados.containsKey('acessorios')) {
        for (var item in dados['acessorios']) {
          await txn.insert('acessorios', item as Map<String, dynamic>);
        }
      }
    });
    return true;
  }

  Future<bool> importarDeArquivo(String path) async {
    try {
      final file = File(path);
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
}
