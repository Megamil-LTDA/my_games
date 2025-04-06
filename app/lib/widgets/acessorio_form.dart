import 'package:flutter/material.dart';
import '../models/acessorio.dart';
import '../models/console.dart';
import '../services/storage_service.dart';

class AcessorioForm extends StatefulWidget {
  final Function(Acessorio) onSalvar;
  final Acessorio? acessorio;
  final String? consolePreSelecionado;

  const AcessorioForm({
    Key? key,
    required this.onSalvar,
    this.acessorio,
    this.consolePreSelecionado,
  }) : super(key: key);

  @override
  _AcessorioFormState createState() => _AcessorioFormState();
}

class _AcessorioFormState extends State<AcessorioForm> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _fotoController = TextEditingController();
  String _consoleId = '';
  DateTime? _ultimaVezTestado;
  List<Console> _consoles = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _carregarConsoles();

    if (widget.acessorio != null) {
      _nomeController.text = widget.acessorio!.nome;
      _descricaoController.text = widget.acessorio!.descricao;
      _fotoController.text = widget.acessorio!.foto;
      _consoleId = widget.acessorio!.consoleId;
      _ultimaVezTestado = widget.acessorio!.ultimaVezTestado;
    } else if (widget.consolePreSelecionado != null) {
      _consoleId = widget.consolePreSelecionado!;
    }
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

  Future<void> _selecionarData(BuildContext context) async {
    final data = await showDatePicker(
      context: context,
      initialDate: _ultimaVezTestado ?? DateTime.now(),
      firstDate: DateTime(1970),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (data != null) {
      setState(() {
        _ultimaVezTestado = data;
      });
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
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
              widget.acessorio == null ? 'Novo Acessório' : 'Editar Acessório',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Nome do acessório
            TextFormField(
              controller: _nomeController,
              decoration: const InputDecoration(
                labelText: 'Nome do Acessório',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, informe o nome do acessório';
                }
                return null;
              },
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

            // Preview da foto, se disponível
            if (_fotoController.text.isNotEmpty)
              Container(
                height: 150,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: NetworkImage(_fotoController.text),
                    fit: BoxFit.cover,
                    onError: (_, __) {},
                  ),
                ),
              ),

            // URL da foto
            TextFormField(
              controller: _fotoController,
              decoration: const InputDecoration(
                labelText: 'URL da Foto',
                border: OutlineInputBorder(),
                hintText: 'https://exemplo.com/imagem.jpg',
              ),
            ),
            const SizedBox(height: 16),

            // Descrição do acessório
            TextFormField(
              controller: _descricaoController,
              decoration: const InputDecoration(
                labelText: 'Descrição',
                border: OutlineInputBorder(),
                hintText: 'Descreva o acessório...',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Última vez testado
            InkWell(
              onTap: () => _selecionarData(context),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Última vez testado',
                  border: OutlineInputBorder(),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _ultimaVezTestado == null
                          ? 'Selecionar data'
                          : '${_ultimaVezTestado!.day}/${_ultimaVezTestado!.month}/${_ultimaVezTestado!.year}',
                    ),
                    const Icon(Icons.calendar_today),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Botão salvar
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  final acessorio = Acessorio(
                    id:
                        widget.acessorio?.id ??
                        '', // O ID será gerado no DatabaseService
                    nome: _nomeController.text,
                    consoleId: _consoleId,
                    descricao: _descricaoController.text,
                    foto: _fotoController.text,
                    ultimaVezTestado: _ultimaVezTestado,
                  );
                  widget.onSalvar(acessorio);
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
