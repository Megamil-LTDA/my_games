import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/storage_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';

// Importação condicional para evitar problemas em plataformas não-web
// ignore: uri_does_not_exist
import 'dart:html' if (dart.library.io) '../html_stub.dart' as html;

class ImportExportScreen extends StatefulWidget {
  const ImportExportScreen({Key? key}) : super(key: key);

  @override
  _ImportExportScreenState createState() => _ImportExportScreenState();
}

class _ImportExportScreenState extends State<ImportExportScreen> {
  bool _isLoading = false;
  String? _mensagem;
  bool _isSucesso = false;
  String? _exportPath;

  Future<void> _exportarDados() async {
    setState(() {
      _isLoading = true;
      _mensagem = null;
      _exportPath = null;
    });

    try {
      // Obtém os dados para exportação
      final dados = await StorageService.instance.exportarDados();
      final jsonString = json.encode(dados);

      if (kIsWeb) {
        // Versão para web - download direto usando JavaScript
        try {
          // Cria um blob para download
          final blob = html.Blob([jsonString], 'application/json');
          final url = html.Url.createObjectUrlFromBlob(blob);
          final anchor =
              html.AnchorElement(href: url)
                ..setAttribute('download', 'my_games_backup.json')
                ..click();

          // Limpa o URL do objeto
          html.Url.revokeObjectUrl(url);

          setState(() {
            _isLoading = false;
            _mensagem = 'Arquivo pronto para download!';
            _isSucesso = true;
          });
        } catch (e) {
          setState(() {
            _isLoading = false;
            _mensagem = 'Erro ao exportar no navegador: $e';
            _isSucesso = false;
          });
        }
      } else {
        // Versão para plataformas nativas
        final directory = await getApplicationDocumentsDirectory();
        final path = '${directory.path}/my_games_backup.json';
        final file = File(path);
        await file.writeAsString(jsonString);
        _exportPath = path;

        setState(() {
          _isLoading = false;
          _mensagem = 'Dados exportados com sucesso para: $path';
          _isSucesso = true;
        });

        // Oferece a opção de compartilhar o arquivo
        final resultado = await Share.shareXFiles([
          XFile(file.path),
        ], text: 'Backup da Minha Coleção de Jogos');

        if (resultado.status == ShareResultStatus.dismissed) {
          setState(() {
            _mensagem = 'Arquivo salvo em: $path';
          });
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _mensagem = 'Erro ao exportar dados: $e';
        _isSucesso = false;
      });
    }
  }

  Future<void> _exportarParaExcel() async {
    setState(() {
      _isLoading = true;
      _mensagem = null;
      _exportPath = null;
    });

    try {
      if (kIsWeb) {
        setState(() {
          _isLoading = false;
          _mensagem = 'Exportação para Excel não disponível na versão web';
          _isSucesso = false;
        });
        return;
      }

      // Exportar para Excel
      final path = await StorageService.instance.exportarParaExcel();
      _exportPath = path;

      setState(() {
        _isLoading = false;
        _mensagem = 'Dados exportados para Excel com sucesso: $path';
        _isSucesso = true;
      });

      // Oferece a opção de compartilhar o arquivo
      final resultado = await Share.shareXFiles([
        XFile(path),
      ], text: 'Coleção de Jogos em formato Excel');

      if (resultado.status == ShareResultStatus.dismissed) {
        setState(() {
          _mensagem = 'Arquivo Excel salvo em: $path';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _mensagem = 'Erro ao exportar para Excel: $e';
        _isSucesso = false;
      });
    }
  }

  Future<void> _importarDados() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        // Solicita explicitamente os bytes para a web
        withData: kIsWeb,
      );

      if (result != null) {
        setState(() {
          _isLoading = true;
          _mensagem = null;
        });

        bool sucesso = false;

        if (kIsWeb) {
          // Na web, usa os bytes em vez do path
          if (result.files.single.bytes != null) {
            final jsonString = String.fromCharCodes(result.files.single.bytes!);
            final dados = await json.decode(jsonString);
            sucesso = await StorageService.instance.importarDados(dados);
          }
        } else {
          // Em plataformas nativas, usa o path
          if (result.files.single.path != null) {
            final caminho = result.files.single.path!;
            sucesso = await StorageService.instance.importarDeArquivo(caminho);
          }
        }

        setState(() {
          _isLoading = false;
          if (sucesso) {
            _mensagem = 'Dados importados com sucesso!';
            _isSucesso = true;
          } else {
            _mensagem = 'Erro ao importar dados: formato inválido.';
            _isSucesso = false;
          }
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _mensagem = 'Erro ao importar dados: $e';
        _isSucesso = false;
      });
    }
  }

  // Método para abrir o arquivo no Finder
  Future<void> _mostrarNoFinder() async {
    if (_exportPath != null && !kIsWeb) {
      try {
        final Uri uri = Uri.file(_exportPath!);
        // Usando o Process.run no macOS
        if (Platform.isMacOS) {
          // Este comando abre o Finder e seleciona o arquivo
          await Process.run('open', ['-R', _exportPath!]);
        } else if (Platform.isWindows) {
          // No Windows, abre o Explorer e seleciona o arquivo
          await Process.run('explorer', ['/select,${_exportPath!}']);
        } else if (Platform.isLinux) {
          // No Linux, tenta abrir com o gerenciador de arquivos padrão
          await Process.run('xdg-open', [uri.toString()]);
        }
      } catch (e) {
        setState(() {
          _mensagem = 'Erro ao abrir o Finder: $e';
          _isSucesso = false;
        });
      }
    }
  }

  Widget _buildMensagem() {
    if (_mensagem == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isSucesso ? Colors.green.shade100 : Colors.red.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            _isSucesso ? Icons.check_circle : Icons.error,
            color: _isSucesso ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(_mensagem!)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Importar/Exportar')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.import_export,
                      size: 72,
                      color: Colors.purple,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Backup da sua coleção',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Exportar',
                            style: Theme.of(context).textTheme.titleMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _exportarDados,
                                  icon: const Icon(Icons.upload),
                                  label: const Text('JSON'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _exportarParaExcel,
                                  icon: const Icon(Icons.table_chart),
                                  label: const Text('Excel'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Importar',
                            style: Theme.of(context).textTheme.titleMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: _importarDados,
                            icon: const Icon(Icons.download),
                            label: const Text('Importar JSON'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildMensagem(),
                    if (_exportPath != null &&
                        !kIsWeb &&
                        (Platform.isMacOS ||
                            Platform.isWindows ||
                            Platform.isLinux))
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        child: ElevatedButton.icon(
                          onPressed: _mostrarNoFinder,
                          icon: Icon(
                            Platform.isMacOS ? Icons.folder : Icons.folder_open,
                          ),
                          label: Text(
                            Platform.isMacOS
                                ? 'Mostrar no Finder'
                                : 'Abrir pasta',
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    if (_mensagem != null && _isSucesso)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          children: [
                            const SizedBox(height: 16),
                            const Text(
                              'Recomendamos fazer backup regularmente para não perder seus dados.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontStyle: FontStyle.italic),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
    );
  }
}
