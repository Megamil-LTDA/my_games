import 'package:flutter/material.dart';
import '../models/jogo.dart';
import '../models/console.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import 'dart:async';

class JogoForm extends StatefulWidget {
  final Function(Jogo) onSalvar;
  final Jogo? jogo;
  final String? consolePreSelecionado;

  const JogoForm({
    Key? key,
    required this.onSalvar,
    this.jogo,
    this.consolePreSelecionado,
  }) : super(key: key);

  @override
  _JogoFormState createState() => _JogoFormState();
}

class _JogoFormState extends State<JogoForm> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _capaController = TextEditingController();
  final _notaPessoalController = TextEditingController();
  String _consoleId = '';
  DateTime? _dataLancamento;
  DateTime? _dataCompra;
  DateTime? _dataFinalizado;
  DateTime? _ultimaVezJogado;
  bool _isOriginal = true;
  bool _bomEstado = true;
  bool _temCapaEAcessorios = true;
  final ApiService _apiService = ApiService();
  List<Console> _consoles = [];
  bool _isLoading = false;
  bool _isSearching = false;
  List<dynamic> _jogosEncontrados = [];
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _carregarConsoles();

    if (widget.jogo != null) {
      _nomeController.text = widget.jogo!.nome;
      _capaController.text = widget.jogo!.capa;
      _consoleId = widget.jogo!.consoleId;
      _dataLancamento = widget.jogo!.dataLancamento;
      _dataCompra = widget.jogo!.dataCompra;
      _dataFinalizado = widget.jogo!.dataFinalizado;
      _ultimaVezJogado = widget.jogo!.ultimaVezJogado;
      _notaPessoalController.text = widget.jogo!.notaPessoal.toString();
      _isOriginal = widget.jogo!.isOriginal;
      _bomEstado = widget.jogo!.bomEstado;
      _temCapaEAcessorios = widget.jogo!.temCapaEAcessorios;
    } else if (widget.consolePreSelecionado != null) {
      _consoleId = widget.consolePreSelecionado!;
    }

    _nomeController.addListener(_onNomeChanged);
  }

  void _onNomeChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_nomeController.text.length >= 3) {
        _buscarJogo(_nomeController.text);
      } else {
        setState(() {
          _jogosEncontrados = [];
        });
      }
    });
  }

  Future<void> _carregarConsoles() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final consoles = await StorageService.instance.buscarConsoles();

      setState(() {
        _consoles = consoles;
        if (consoles.isNotEmpty && _consoleId.isEmpty) {
          _consoleId = consoles[0].id;
        }
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao carregar consoles: $e')));
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _buscarJogo(String nome) async {
    if (nome.length < 3) {
      setState(() {
        _jogosEncontrados = [];
      });
      return;
    }

    try {
      setState(() {
        _isSearching = true;
      });

      final resultados = await _apiService.buscarJogos(nome);

      setState(() {
        _jogosEncontrados = resultados;
        _isSearching = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao buscar jogo: $e')));
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _selecionarJogo(dynamic jogo) {
    setState(() {
      _nomeController.text = jogo['name'];
      _capaController.text = jogo['background_image'] ?? '';
      _dataLancamento =
          jogo['released'] != null ? DateTime.parse(jogo['released']) : null;
      _jogosEncontrados = [];
    });
  }

  Future<void> _selecionarData(
    BuildContext context,
    DateTime? data,
    Function(DateTime?) onSelect,
  ) async {
    final selecionado = await showDatePicker(
      context: context,
      initialDate: data ?? DateTime.now(),
      firstDate: DateTime(1970),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (selecionado != null) {
      setState(() {
        onSelect(selecionado);
      });
    }
  }

  Widget _buildDateField(
    String label,
    DateTime? data,
    Function(DateTime?) onSelect,
  ) {
    return InkWell(
      onTap: () => _selecionarData(context, data, onSelect),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              data == null
                  ? 'Selecionar data'
                  : '${data.day}/${data.month}/${data.year}',
            ),
            const Icon(Icons.calendar_today),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nomeController.removeListener(_onNomeChanged);
    _nomeController.dispose();
    _capaController.dispose();
    _notaPessoalController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.jogo == null ? 'Novo Jogo' : 'Editar Jogo',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Campo de nome com busca
              Column(
                children: [
                  TextFormField(
                    controller: _nomeController,
                    decoration: InputDecoration(
                      labelText: 'Nome do Jogo',
                      border: const OutlineInputBorder(),
                      suffixIcon:
                          _isSearching
                              ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Icon(Icons.search),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, informe o nome do jogo';
                      }
                      return null;
                    },
                  ),
                  if (_jogosEncontrados.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _jogosEncontrados.length,
                        itemBuilder: (context, index) {
                          final jogo = _jogosEncontrados[index];
                          return ListTile(
                            leading:
                                jogo['background_image'] != null
                                    ? ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: Image.network(
                                        jogo['background_image'],
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (_, __, ___) => const Icon(
                                              Icons.sports_esports,
                                              size: 50,
                                            ),
                                      ),
                                    )
                                    : const Icon(
                                      Icons.sports_esports,
                                      size: 50,
                                    ),
                            title: Text(jogo['name']),
                            subtitle:
                                jogo['released'] != null
                                    ? Text('Lançamento: ${jogo['released']}')
                                    : null,
                            onTap: () => _selecionarJogo(jogo),
                          );
                        },
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Dropdown de consoles
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _consoles.isEmpty
                  ? const Text(
                    'Nenhum console encontrado. Cadastre um console primeiro.',
                  )
                  : DropdownButtonFormField<String>(
                    value: _consoleId.isNotEmpty ? _consoleId : null,
                    decoration: const InputDecoration(
                      labelText: 'Console',
                      border: OutlineInputBorder(),
                    ),
                    items:
                        _consoles.map((console) {
                          return DropdownMenuItem<String>(
                            value: console.id,
                            child: Text(console.nome),
                          );
                        }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _consoleId = value;
                        });
                      }
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, selecione um console';
                      }
                      return null;
                    },
                  ),
              const SizedBox(height: 16),

              // Preview da capa, se disponível
              if (_capaController.text.isNotEmpty)
                Container(
                  height: 180,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: NetworkImage(_capaController.text),
                      fit: BoxFit.cover,
                      onError: (_, __) {},
                    ),
                  ),
                ),

              // URL da capa
              TextFormField(
                controller: _capaController,
                decoration: const InputDecoration(
                  labelText: 'URL da Capa',
                  border: OutlineInputBorder(),
                  hintText: 'https://exemplo.com/imagem.jpg',
                ),
              ),
              const SizedBox(height: 16),

              // Nota pessoal
              TextFormField(
                controller: _notaPessoalController,
                decoration: const InputDecoration(
                  labelText: 'Nota Pessoal (0-10)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final nota = double.tryParse(value);
                    if (nota == null || nota < 0 || nota > 10) {
                      return 'A nota deve ser entre 0 e 10';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Switches para características
              Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Características',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        title: const Text('É original'),
                        value: _isOriginal,
                        onChanged: (value) {
                          setState(() {
                            _isOriginal = value;
                          });
                        },
                        secondary: const Icon(Icons.verified),
                        dense: true,
                      ),
                      const Divider(),
                      SwitchListTile(
                        title: const Text('Está em bom estado'),
                        value: _bomEstado,
                        onChanged: (value) {
                          setState(() {
                            _bomEstado = value;
                          });
                        },
                        secondary: const Icon(Icons.thumb_up),
                        dense: true,
                      ),
                      const Divider(),
                      SwitchListTile(
                        title: const Text('Tem capa/acessórios'),
                        value: _temCapaEAcessorios,
                        onChanged: (value) {
                          setState(() {
                            _temCapaEAcessorios = value;
                          });
                        },
                        secondary: const Icon(Icons.inventory_2),
                        dense: true,
                      ),
                    ],
                  ),
                ),
              ),

              // Data de lançamento
              _buildDateField(
                'Data de Lançamento',
                _dataLancamento,
                (data) => _dataLancamento = data,
              ),
              const SizedBox(height: 16),

              // Data de compra
              _buildDateField(
                'Data de Compra',
                _dataCompra,
                (data) => _dataCompra = data,
              ),
              const SizedBox(height: 16),

              // Data de finalização
              _buildDateField(
                'Data de Finalização',
                _dataFinalizado,
                (data) => _dataFinalizado = data,
              ),
              const SizedBox(height: 16),

              // Última vez jogado
              _buildDateField(
                'Última vez que jogou',
                _ultimaVezJogado,
                (data) => _ultimaVezJogado = data,
              ),
              const SizedBox(height: 24),

              // Botão salvar
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final jogo = Jogo(
                      id:
                          widget.jogo?.id ??
                          '', // O ID será gerado no DatabaseService
                      nome: _nomeController.text,
                      capa: _capaController.text,
                      dataLancamento: _dataLancamento,
                      consoleId: _consoleId,
                      notaPessoal:
                          double.tryParse(_notaPessoalController.text) ?? 0.0,
                      dataCompra: _dataCompra,
                      dataFinalizado: _dataFinalizado,
                      ultimaVezJogado: _ultimaVezJogado,
                      isOriginal: _isOriginal,
                      bomEstado: _bomEstado,
                      temCapaEAcessorios: _temCapaEAcessorios,
                    );
                    widget.onSalvar(jogo);
                    Navigator.of(context).pop();
                  }
                },
                child: const Text('Salvar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
