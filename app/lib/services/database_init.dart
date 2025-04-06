import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'dart:io' as io;

/// Classe para inicialização das configurações do aplicativo
class DatabaseInit {
  /// Inicializa os recursos necessários para o aplicativo
  static Future<void> initialize() async {
    if (kIsWeb) {
      print(
        'Rodando na web - usando SharedPreferences e IndexedDB para armazenamento',
      );
      // Inicializa o SQLite para web
      databaseFactory = databaseFactoryFfiWeb;
    } else {
      print('Rodando em dispositivo nativo - usando SQLite para armazenamento');

      // Em ambientes desktop, inicializa o SQLite via FFI
      try {
        // Verificar se é desktop (não é Android nem iOS)
        if (!(io.Platform.isAndroid || io.Platform.isIOS)) {
          sqfliteFfiInit();
          databaseFactory = databaseFactoryFfi;
        }
      } catch (e) {
        print('Erro ao inicializar SQLite: $e');
      }
    }

    // Qualquer inicialização adicional pode ser feita aqui
  }
}
