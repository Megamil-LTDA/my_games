import 'package:flutter/material.dart';
import '../models/acessorio.dart';
import '../models/console.dart';
import '../services/storage_service.dart';
import '../widgets/acessorio_form.dart';

class AcessorioScreen extends StatefulWidget {
  const AcessorioScreen({Key? key}) : super(key: key);

  @override
  _AcessorioScreenState createState() => _AcessorioScreenState();
}

class _AcessorioScreenState extends State<AcessorioScreen> {
  List<Acessorio> _acessorios = [];
  Map<String, Console> _consoles = {};
  bool _isLoading = true;
  String? _consoleSelecionado;
  bool _isGridView = true; // Controla se a visualização é em grade ou lista

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final acessorios = await StorageService.instance.buscarAcessorios();
      final consoles = await StorageService.instance.buscarConsoles();
      final consolesMap = {for (var console in consoles) console.id: console};

      setState(() {
        _acessorios = acessorios;
        _consoles = consolesMap;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao carregar dados: $e')));
    }
  }

  void _exibirFormulario({Acessorio? acessorio}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (context) => SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: AcessorioForm(
              acessorio: acessorio,
              onSalvar: (Acessorio acessorioSalvo) async {
                if (acessorio == null) {
                  await StorageService.instance.salvarAcessorio(acessorioSalvo);
                } else {
                  await StorageService.instance.atualizarAcessorio(
                    acessorioSalvo,
                  );
                }
                _carregarDados();
              },
            ),
          ),
    );
  }

  Future<void> _confirmarExclusao(Acessorio acessorio) async {
    final confirmacao = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmar Exclusão'),
            content: Text(
              'Deseja realmente excluir o acessório ${acessorio.nome}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Excluir'),
              ),
            ],
          ),
    );

    if (confirmacao == true) {
      try {
        await StorageService.instance.deletarAcessorio(acessorio.id);
        _carregarDados();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Acessório excluído com sucesso')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir acessório: $e')),
        );
      }
    }
  }

  List<Acessorio> get _acessoriosFiltrados {
    if (_consoleSelecionado == null) {
      return _acessorios;
    }

    return _acessorios
        .where((a) => a.consoleId == _consoleSelecionado)
        .toList();
  }

  Widget _buildGridView() {
    final acessoriosFiltrados = _acessoriosFiltrados;

    return acessoriosFiltrados.isEmpty
        ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cable_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'Nenhum acessório cadastrado',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _exibirFormulario(),
                icon: const Icon(Icons.add),
                label: const Text('Adicionar Acessório'),
              ),
            ],
          ),
        )
        : GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.85,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: acessoriosFiltrados.length,
          itemBuilder: (context, index) {
            final acessorio = acessoriosFiltrados[index];
            final console = _consoles[acessorio.consoleId];

            return Card(
              clipBehavior: Clip.antiAlias,
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: InkWell(
                onTap: () => _exibirFormulario(acessorio: acessorio),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Foto do acessório
                    if (acessorio.foto.isNotEmpty)
                      Expanded(
                        flex: 2,
                        child: Image.network(
                          acessorio.foto,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) => Container(
                                color: Colors.green.shade100,
                                child: const Icon(
                                  Icons.cable,
                                  size: 36,
                                  color: Colors.green,
                                ),
                              ),
                        ),
                      )
                    else
                      Expanded(
                        flex: 2,
                        child: Container(
                          color: Colors.green.shade100,
                          child: const Icon(
                            Icons.cable,
                            size: 36,
                            color: Colors.green,
                          ),
                        ),
                      ),

                    // Informações do acessório
                    Expanded(
                      flex: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Nome do acessório
                            Text(
                              acessorio.nome,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            // Nome do console
                            if (console != null)
                              Text(
                                console.nome,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            const Spacer(),
                            // Botões de ação
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 16),
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.all(4),
                                  onPressed:
                                      () => _exibirFormulario(
                                        acessorio: acessorio,
                                      ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, size: 16),
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.all(4),
                                  onPressed:
                                      () => _confirmarExclusao(acessorio),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
  }

  Widget _buildListView() {
    final acessoriosFiltrados = _acessoriosFiltrados;

    return acessoriosFiltrados.isEmpty
        ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cable_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'Nenhum acessório cadastrado',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _exibirFormulario(),
                icon: const Icon(Icons.add),
                label: const Text('Adicionar Acessório'),
              ),
            ],
          ),
        )
        : ListView.builder(
          itemCount: acessoriosFiltrados.length,
          itemBuilder: (context, index) {
            final acessorio = acessoriosFiltrados[index];
            final console = _consoles[acessorio.consoleId];

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  if (acessorio.foto.isNotEmpty)
                    Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(acessorio.foto),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ListTile(
                    leading:
                        acessorio.foto.isEmpty
                            ? CircleAvatar(
                              backgroundColor: Colors.green.shade100,
                              child: const Icon(
                                Icons.cable,
                                color: Colors.green,
                              ),
                            )
                            : null,
                    title: Text(
                      acessorio.nome,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (console != null) Text('Console: ${console.nome}'),
                        if (acessorio.descricao.isNotEmpty)
                          Text('Descrição: ${acessorio.descricao}'),
                        if (acessorio.ultimaVezTestado != null)
                          Text(
                            'Último teste: ${acessorio.ultimaVezTestado!.day}/${acessorio.ultimaVezTestado!.month}/${acessorio.ultimaVezTestado!.year}',
                          ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed:
                              () => _exibirFormulario(acessorio: acessorio),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _confirmarExclusao(acessorio),
                        ),
                      ],
                    ),
                    onTap: () => _exibirFormulario(acessorio: acessorio),
                  ),
                ],
              ),
            );
          },
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Acessórios'),
        actions: [
          // Botão para alternar entre visualização em grade e lista
          IconButton(
            icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
            tooltip:
                _isGridView ? 'Visualizar em lista' : 'Visualizar em grade',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtro de console
          if (_consoles.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: DropdownButtonFormField<String?>(
                decoration: const InputDecoration(
                  labelText: 'Filtrar por Console',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                value: _consoleSelecionado,
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Todos os consoles'),
                  ),
                  ..._consoles.values.map(
                    (console) => DropdownMenuItem(
                      value: console.id,
                      child: Text(console.nome),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _consoleSelecionado = value;
                  });
                },
              ),
            ),
          // Lista de acessórios
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _isGridView
                    ? _buildGridView()
                    : _buildListView(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _exibirFormulario(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
