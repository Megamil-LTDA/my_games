import 'package:flutter/material.dart';
import '../models/console.dart';
import '../services/storage_service.dart';
import '../widgets/console_form.dart';
import './console_detalhes_screen.dart';

class ConsoleScreen extends StatefulWidget {
  const ConsoleScreen({Key? key}) : super(key: key);

  @override
  _ConsoleScreenState createState() => _ConsoleScreenState();
}

class _ConsoleScreenState extends State<ConsoleScreen> {
  List<Console> _consoles = [];
  bool _isLoading = true;
  bool _isGridView = true; // Controla se a visualização é em grade ou lista

  @override
  void initState() {
    super.initState();
    _carregarConsoles();
  }

  Future<void> _carregarConsoles() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final consoles = await StorageService.instance.buscarConsoles();
      setState(() {
        _consoles = consoles;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao carregar consoles: $e')));
    }
  }

  void _exibirFormulario({Console? console}) {
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
            child: ConsoleForm(
              console: console,
              onSalvar: (Console consoleSalvo) async {
                if (console == null) {
                  await StorageService.instance.salvarConsole(consoleSalvo);
                } else {
                  await StorageService.instance.atualizarConsole(consoleSalvo);
                }
                _carregarConsoles();
              },
            ),
          ),
    );
  }

  Future<void> _confirmarExclusao(Console console) async {
    final confirmacao = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmar Exclusão'),
            content: Text(
              'Deseja realmente excluir o console ${console.nome}?',
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
        await StorageService.instance.deletarConsole(console.id);
        _carregarConsoles();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Console excluído com sucesso')),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao excluir console: $e')));
      }
    }
  }

  void _navegarParaDetalhes(Console console) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => ConsoleDetalhesScreen(console: console),
          ),
        )
        .then((_) => _carregarConsoles());
  }

  // Construir a visualização em grade
  Widget _buildGridView() {
    return _consoles.isEmpty
        ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.videogame_asset_outlined,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              const Text(
                'Nenhum console cadastrado',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _exibirFormulario(),
                icon: const Icon(Icons.add),
                label: const Text('Adicionar Console'),
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
          itemCount: _consoles.length,
          itemBuilder: (context, index) {
            final console = _consoles[index];

            return Card(
              clipBehavior: Clip.antiAlias,
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: InkWell(
                onTap: () => _navegarParaDetalhes(console),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Imagem do console
                          console.foto.isNotEmpty
                              ? Image.network(
                                console.foto,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (_, __, ___) => Container(
                                      color: Colors.blue.shade100,
                                      child: const Icon(
                                        Icons.videogame_asset,
                                        size: 50,
                                        color: Colors.blue,
                                      ),
                                    ),
                              )
                              : Container(
                                color: Colors.blue.shade100,
                                child: const Icon(
                                  Icons.videogame_asset,
                                  size: 50,
                                  color: Colors.blue,
                                ),
                              ),

                          // Menu de opções no canto superior direito
                          Positioned(
                            top: 0,
                            right: 0,
                            child: PopupMenuButton<String>(
                              icon: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black38,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.more_vert,
                                  color: Colors.white,
                                ),
                              ),
                              onSelected: (value) {
                                if (value == 'editar') {
                                  _exibirFormulario(console: console);
                                } else if (value == 'excluir') {
                                  _confirmarExclusao(console);
                                }
                              },
                              itemBuilder:
                                  (context) => [
                                    const PopupMenuItem(
                                      value: 'editar',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit),
                                          SizedBox(width: 8),
                                          Text('Editar'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'excluir',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete),
                                          SizedBox(width: 8),
                                          Text('Excluir'),
                                        ],
                                      ),
                                    ),
                                  ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              console.nome,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (console.dataLancamento != null)
                              Text(
                                '${console.dataLancamento!.year}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
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

  // Construir a visualização em lista
  Widget _buildListView() {
    return _consoles.isEmpty
        ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.videogame_asset_outlined,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              const Text(
                'Nenhum console cadastrado',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _exibirFormulario(),
                icon: const Icon(Icons.add),
                label: const Text('Adicionar Console'),
              ),
            ],
          ),
        )
        : ListView.builder(
          itemCount: _consoles.length,
          itemBuilder: (context, index) {
            final console = _consoles[index];

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: InkWell(
                onTap: () => _navegarParaDetalhes(console),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      // Imagem do console
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 80,
                          height: 80,
                          child:
                              console.foto.isNotEmpty
                                  ? Image.network(
                                    console.foto,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (_, __, ___) => Container(
                                          color: Colors.blue.shade100,
                                          child: const Icon(
                                            Icons.videogame_asset,
                                            size: 40,
                                            color: Colors.blue,
                                          ),
                                        ),
                                  )
                                  : Container(
                                    color: Colors.blue.shade100,
                                    child: const Icon(
                                      Icons.videogame_asset,
                                      size: 40,
                                      color: Colors.blue,
                                    ),
                                  ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Informações do console
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              console.nome,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            if (console.dataLancamento != null)
                              Text(
                                'Lançamento: ${console.dataLancamento!.day}/${console.dataLancamento!.month}/${console.dataLancamento!.year}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Botões de ação
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed:
                                () => _exibirFormulario(console: console),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _confirmarExclusao(console),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Consoles'),
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
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _isGridView
              ? _buildGridView()
              : _buildListView(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _exibirFormulario(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
