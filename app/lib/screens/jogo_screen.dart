import 'package:flutter/material.dart';
import '../models/jogo.dart';
import '../models/console.dart';
import '../services/storage_service.dart';
import '../widgets/jogo_form.dart';

class JogoScreen extends StatefulWidget {
  const JogoScreen({Key? key}) : super(key: key);

  @override
  _JogoScreenState createState() => _JogoScreenState();
}

class _JogoScreenState extends State<JogoScreen> {
  List<Jogo> _jogos = [];
  Map<String, Console> _consoles = {};
  bool _isLoading = true;
  String? _filtroConsoleId;
  bool _isGridView = true; // Por padrão usar grade

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
      // Carregar consoles primeiro
      final consoles = await StorageService.instance.buscarConsoles();
      final consolesMap = {for (var c in consoles) c.id: c};

      // Então carregar jogos
      final jogos =
          _filtroConsoleId != null
              ? await StorageService.instance.buscarJogosPorConsole(
                _filtroConsoleId!,
              )
              : await StorageService.instance.buscarJogos();

      setState(() {
        _consoles = consolesMap;
        _jogos = jogos;
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

  void _mostrarFormulario({Jogo? jogo}) {
    if (_consoles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cadastre pelo menos um console antes de adicionar jogos.',
          ),
        ),
      );
      return;
    }

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
            child: JogoForm(
              jogo: jogo,
              onSalvar: (Jogo jogoSalvo) async {
                if (jogo == null) {
                  // Novo jogo
                  await StorageService.instance.salvarJogo(jogoSalvo);
                } else {
                  // Editando jogo existente
                  await StorageService.instance.atualizarJogo(jogoSalvo);
                }
                _carregarDados();
              },
            ),
          ),
    );
  }

  Future<void> _confirmarExclusao(Jogo jogo) async {
    final confirmacao = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmar Exclusão'),
            content: Text('Deseja realmente excluir o jogo ${jogo.nome}?'),
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
        await StorageService.instance.deletarJogo(jogo.id);
        _carregarDados();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Jogo excluído com sucesso')),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao excluir jogo: $e')));
      }
    }
  }

  Widget _buildFiltroConsole() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String?>(
              decoration: const InputDecoration(
                labelText: 'Filtrar por Console',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              value: _filtroConsoleId,
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Todos os Consoles'),
                ),
                ..._consoles.values.map((console) {
                  return DropdownMenuItem<String?>(
                    value: console.id,
                    child: Text(console.nome),
                  );
                }).toList(),
              ],
              onChanged: (value) {
                setState(() {
                  _filtroConsoleId = value;
                });
                _carregarDados();
              },
            ),
          ),
          const SizedBox(width: 8),
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
    );
  }

  Widget _buildListaJogos() {
    return ListView.builder(
      itemCount: _jogos.length,
      itemBuilder: (context, index) {
        final jogo = _jogos[index];
        final console = _consoles[jogo.consoleId];

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              if (jogo.capa.isNotEmpty)
                Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(jogo.capa),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ListTile(
                title: Text(
                  jogo.nome,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (console != null) Text('Console: ${console.nome}'),
                    if (jogo.dataLancamento != null)
                      Text(
                        'Lançamento: ${jogo.dataLancamento!.day}/${jogo.dataLancamento!.month}/${jogo.dataLancamento!.year}',
                      ),
                    Text('Nota: ${jogo.notaPessoal.toStringAsFixed(1)}'),
                    const SizedBox(height: 4),
                    // Indicadores para as características
                    Wrap(
                      spacing: 8,
                      children: [
                        // Ícone de original
                        if (jogo.isOriginal)
                          Chip(
                            avatar: const Icon(
                              Icons.verified,
                              size: 14,
                              color: Colors.blue,
                            ),
                            label: const Text(
                              'Original',
                              style: TextStyle(fontSize: 12),
                            ),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                        // Ícone de bom estado
                        if (jogo.bomEstado)
                          Chip(
                            avatar: const Icon(
                              Icons.thumb_up,
                              size: 14,
                              color: Colors.green,
                            ),
                            label: const Text(
                              'Bom estado',
                              style: TextStyle(fontSize: 12),
                            ),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                        // Ícone de capa/acessórios
                        if (jogo.temCapaEAcessorios)
                          Chip(
                            avatar: const Icon(
                              Icons.inventory_2,
                              size: 14,
                              color: Colors.orange,
                            ),
                            label: const Text(
                              'Com capa/acessórios',
                              style: TextStyle(fontSize: 12),
                            ),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                      ],
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _mostrarFormulario(jogo: jogo),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _confirmarExclusao(jogo),
                    ),
                  ],
                ),
                onTap: () => _mostrarFormulario(jogo: jogo),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGradeJogos() {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _jogos.length,
      itemBuilder: (context, index) {
        final jogo = _jogos[index];
        final console = _consoles[jogo.consoleId];

        return Card(
          clipBehavior: Clip.antiAlias,
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: InkWell(
            onTap: () => _mostrarFormulario(jogo: jogo),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child:
                      jogo.capa.isNotEmpty
                          ? Image.network(
                            jogo.capa,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (_, __, ___) => Container(
                                  color: Colors.grey.shade300,
                                  child: const Icon(
                                    Icons.image_not_supported,
                                    size: 50,
                                  ),
                                ),
                          )
                          : Container(
                            color: Colors.grey.shade300,
                            child: const Icon(Icons.sports_esports, size: 50),
                          ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          jogo.nome,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
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
                        const SizedBox(height: 4),
                        // Indicadores para as características em modo grade
                        Row(
                          children: [
                            // Ícone de original
                            if (jogo.isOriginal)
                              const Padding(
                                padding: EdgeInsets.only(right: 8.0),
                                child: Tooltip(
                                  message: 'Original',
                                  child: Icon(
                                    Icons.verified,
                                    size: 16,
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                            // Ícone de bom estado
                            if (jogo.bomEstado)
                              const Padding(
                                padding: EdgeInsets.only(right: 8.0),
                                child: Tooltip(
                                  message: 'Bom estado',
                                  child: Icon(
                                    Icons.thumb_up,
                                    size: 16,
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                            // Ícone de capa/acessórios
                            if (jogo.temCapaEAcessorios)
                              const Tooltip(
                                message: 'Tem capa/acessórios',
                                child: Icon(
                                  Icons.inventory_2,
                                  size: 16,
                                  color: Colors.orange,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  size: 16,
                                  color: Colors.amber,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  jogo.notaPessoal.toStringAsFixed(1),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 16),
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.all(4),
                                  onPressed:
                                      () => _mostrarFormulario(jogo: jogo),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, size: 16),
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.all(4),
                                  onPressed: () => _confirmarExclusao(jogo),
                                ),
                              ],
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

  Widget _buildConteudoVazio() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.sports_esports_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            _filtroConsoleId != null
                ? 'Nenhum jogo cadastrado para este console'
                : 'Nenhum jogo cadastrado',
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _mostrarFormulario(),
            icon: const Icon(Icons.add),
            label: const Text('Adicionar Jogo'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Jogos')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  if (_consoles.isNotEmpty) _buildFiltroConsole(),
                  Expanded(
                    child:
                        _jogos.isEmpty
                            ? _buildConteudoVazio()
                            : _isGridView
                            ? _buildGradeJogos()
                            : _buildListaJogos(),
                  ),
                ],
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarFormulario(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
