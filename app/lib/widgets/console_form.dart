import 'package:flutter/material.dart';
import '../models/console.dart';
import '../services/api_service.dart';

/*
 * Formulário para cadastro e edição de consoles com recurso de autocompletar.
 * Ao digitar o nome do console, a aplicação busca na API do RAWG.io por plataformas
 * correspondentes e exibe sugestões. Ao selecionar uma sugestão, o formulário é
 * preenchido automaticamente com as informações da plataforma.
 */
class ConsoleForm extends StatefulWidget {
  final Function(Console) onSalvar;
  final Console? console;

  const ConsoleForm({Key? key, required this.onSalvar, this.console})
    : super(key: key);

  @override
  _ConsoleFormState createState() => _ConsoleFormState();
}

class _ConsoleFormState extends State<ConsoleForm> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _fotoController = TextEditingController();
  DateTime? _dataLancamento;
  bool _isSearching = false;
  List<dynamic> _plataformasEncontradas = [];
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    // Preencher o formulário se estiver editando
    if (widget.console != null) {
      _nomeController.text = widget.console!.nome;
      _fotoController.text = widget.console!.foto;
      _dataLancamento = widget.console!.dataLancamento;
    }
  }

  Future<void> _buscarConsole(String nome) async {
    if (nome.length < 3) {
      setState(() {
        _plataformasEncontradas = [];
      });
      return;
    }

    try {
      setState(() {
        _isSearching = true;
      });

      final resultados = await _apiService.buscarPlataformasPorNome(nome);

      setState(() {
        _plataformasEncontradas = resultados;
        _isSearching = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao buscar consoles: $e')));
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _selecionarConsole(dynamic plataforma) {
    setState(() {
      _nomeController.text = plataforma['name'];
      _fotoController.text = plataforma['image_background'] ?? '';
      if (plataforma['year_start'] != null) {
        try {
          _dataLancamento = DateTime(plataforma['year_start'], 1, 1);
        } catch (e) {
          // Ignora erro de data inválida
        }
      }
      _plataformasEncontradas = [];
    });
  }

  Future<void> _selecionarData(BuildContext context) async {
    final data = await showDatePicker(
      context: context,
      initialDate: _dataLancamento ?? DateTime.now(),
      firstDate: DateTime(1970),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (data != null) {
      setState(() {
        _dataLancamento = data;
      });
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _fotoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.console == null ? 'Novo Console' : 'Editar Console',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Column(
              children: [
                TextFormField(
                  controller: _nomeController,
                  decoration: InputDecoration(
                    labelText: 'Nome do Console',
                    border: const OutlineInputBorder(),
                    suffixIcon:
                        _isSearching
                            ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Icon(Icons.search),
                  ),
                  onChanged: _buscarConsole,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, informe o nome do console';
                    }
                    return null;
                  },
                ),
                if (_plataformasEncontradas.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _plataformasEncontradas.length,
                      itemBuilder: (context, index) {
                        final plataforma = _plataformasEncontradas[index];
                        return ListTile(
                          leading:
                              plataforma['image_background'] != null
                                  ? ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: Image.network(
                                      plataforma['image_background'],
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (_, __, ___) => const Icon(
                                            Icons.videogame_asset,
                                            size: 50,
                                          ),
                                    ),
                                  )
                                  : const Icon(Icons.videogame_asset, size: 50),
                          title: Text(plataforma['name']),
                          subtitle:
                              plataforma['year_start'] != null
                                  ? Text(
                                    'Lançamento: ${plataforma['year_start']}',
                                  )
                                  : null,
                          onTap: () => _selecionarConsole(plataforma),
                        );
                      },
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _fotoController,
              decoration: const InputDecoration(
                labelText: 'URL da Foto',
                border: OutlineInputBorder(),
                hintText: 'https://exemplo.com/imagem.jpg',
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () => _selecionarData(context),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Data de Lançamento',
                  border: OutlineInputBorder(),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _dataLancamento == null
                          ? 'Selecionar data'
                          : '${_dataLancamento!.day}/${_dataLancamento!.month}/${_dataLancamento!.year}',
                    ),
                    const Icon(Icons.calendar_today),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  final console = Console(
                    id:
                        widget.console?.id ??
                        '', // O ID será gerado no DatabaseService
                    nome: _nomeController.text,
                    foto: _fotoController.text,
                    dataLancamento: _dataLancamento,
                  );
                  widget.onSalvar(console);
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}
