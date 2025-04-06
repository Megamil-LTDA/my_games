import 'package:flutter/material.dart';
import '../models/console.dart';
import '../models/jogo.dart';
import '../models/acessorio.dart';
import '../services/storage_service.dart';
import '../widgets/jogo_form.dart';
import '../widgets/acessorio_form.dart';

class ConsoleDetalhesScreen extends StatefulWidget {
  final Console console;

  const ConsoleDetalhesScreen({Key? key, required this.console})
    : super(key: key);

  @override
  _ConsoleDetalhesScreenState createState() => _ConsoleDetalhesScreenState();
}

class _ConsoleDetalhesScreenState extends State<ConsoleDetalhesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Jogo> _jogos = [];
  List<Acessorio> _acessorios = [];
  bool _isLoading = true;
  bool _isJogosGridView = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _carregarDados();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _carregarDados() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final jogos = await StorageService.instance.buscarJogosPorConsole(
        widget.console.id,
      );
      final acessorios = await StorageService.instance
          .buscarAcessoriosPorConsole(widget.console.id);

      setState(() {
        _jogos = jogos;
        _acessorios = acessorios;
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

  // Método para adicionar jogo
  void _adicionarJogo() {
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
              consolePreSelecionado: widget.console.id,
              onSalvar: (Jogo jogo) async {
                await StorageService.instance.salvarJogo(jogo);
                _carregarDados();
              },
            ),
          ),
    );
  }

  // Método para adicionar acessório
  void _adicionarAcessorio() {
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
              consolePreSelecionado: widget.console.id,
              onSalvar: (Acessorio acessorio) async {
                await StorageService.instance.salvarAcessorio(acessorio);
                _carregarDados();
              },
            ),
          ),
    );
  }

  // Método para excluir jogo
  Future<void> _confirmarExclusaoJogo(Jogo jogo) async {
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

  // Método para excluir acessório
  Future<void> _confirmarExclusaoAcessorio(Acessorio acessorio) async {
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

  // Método para editar jogo
  void _editarJogo(Jogo jogo) {
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
              onSalvar: (Jogo jogoAtualizado) async {
                await StorageService.instance.atualizarJogo(jogoAtualizado);
                _carregarDados();
              },
            ),
          ),
    );
  }

  // Método para editar acessório
  void _editarAcessorio(Acessorio acessorio) {
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
              onSalvar: (Acessorio acessorioAtualizado) async {
                await StorageService.instance.atualizarAcessorio(
                  acessorioAtualizado,
                );
                _carregarDados();
              },
            ),
          ),
    );
  }

  Widget _buildJogosGrid() {
    return _jogos.isEmpty
        ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.sports_esports_outlined,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              const Text(
                'Nenhum jogo cadastrado para este console',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _adicionarJogo,
                icon: const Icon(Icons.add),
                label: const Text('Adicionar Jogo'),
              ),
            ],
          ),
        )
        : GridView.builder(
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

            return Card(
              clipBehavior: Clip.antiAlias,
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: InkWell(
                onTap: () => _editarJogo(jogo),
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
                                child: const Icon(
                                  Icons.sports_esports,
                                  size: 50,
                                ),
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
                            const SizedBox(height: 4),
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
                            const SizedBox(height: 4),
                            // Indicadores visuais para as características
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
                            const Spacer(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 16),
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.all(4),
                                  onPressed: () => _editarJogo(jogo),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, size: 16),
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.all(4),
                                  onPressed: () => _confirmarExclusaoJogo(jogo),
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

  Widget _buildJogosList() {
    return _jogos.isEmpty
        ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.sports_esports_outlined,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              const Text(
                'Nenhum jogo cadastrado para este console',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _adicionarJogo,
                icon: const Icon(Icons.add),
                label: const Text('Adicionar Jogo'),
              ),
            ],
          ),
        )
        : ListView.builder(
          itemCount: _jogos.length,
          itemBuilder: (context, index) {
            final jogo = _jogos[index];

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
                        if (jogo.dataLancamento != null)
                          Text(
                            'Lançamento: ${jogo.dataLancamento!.day}/${jogo.dataLancamento!.month}/${jogo.dataLancamento!.year}',
                          ),
                        Text('Nota: ${jogo.notaPessoal.toStringAsFixed(1)}'),
                        const SizedBox(height: 4),
                        // Indicadores para as características
                        Row(
                          children: [
                            // Ícone de original
                            if (jogo.isOriginal)
                              Row(
                                children: [
                                  const Icon(
                                    Icons.verified,
                                    size: 16,
                                    color: Colors.blue,
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'Original',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                              ),
                            // Ícone de bom estado
                            if (jogo.bomEstado)
                              Row(
                                children: [
                                  const Icon(
                                    Icons.thumb_up,
                                    size: 16,
                                    color: Colors.green,
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'Bom estado',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                              ),
                            // Ícone de capa/acessórios
                            if (jogo.temCapaEAcessorios)
                              Row(
                                children: [
                                  const Icon(
                                    Icons.inventory_2,
                                    size: 16,
                                    color: Colors.orange,
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'Com capa/acessórios',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ],
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
                          onPressed: () => _editarJogo(jogo),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _confirmarExclusaoJogo(jogo),
                        ),
                      ],
                    ),
                    onTap: () => _editarJogo(jogo),
                  ),
                ],
              ),
            );
          },
        );
  }

  Widget _buildAcessoriosList() {
    return _acessorios.isEmpty
        ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cable_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'Nenhum acessório cadastrado para este console',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _adicionarAcessorio,
                icon: const Icon(Icons.add),
                label: const Text('Adicionar Acessório'),
              ),
            ],
          ),
        )
        : ListView.builder(
          itemCount: _acessorios.length,
          itemBuilder: (context, index) {
            final acessorio = _acessorios[index];

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
                          onPressed: () => _editarAcessorio(acessorio),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed:
                              () => _confirmarExclusaoAcessorio(acessorio),
                        ),
                      ],
                    ),
                    onTap: () => _editarAcessorio(acessorio),
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
        title: Text(widget.console.nome),
        actions: [
          if (_tabController.index == 0)
            IconButton(
              icon: Icon(_isJogosGridView ? Icons.list : Icons.grid_view),
              onPressed: () {
                setState(() {
                  _isJogosGridView = !_isJogosGridView;
                });
              },
              tooltip:
                  _isJogosGridView
                      ? 'Visualizar em lista'
                      : 'Visualizar em grade',
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          onTap: (index) {
            setState(() {});
          },
          tabs: const [
            Tab(icon: Icon(Icons.sports_esports), text: 'Jogos'),
            Tab(icon: Icon(Icons.cable), text: 'Acessórios'),
          ],
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  // Header com informações do console
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Imagem do console
                            if (widget.console.foto.isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  widget.console.foto,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (_, __, ___) => Container(
                                        width: 80,
                                        height: 80,
                                        color: Colors.blue.shade100,
                                        child: const Icon(
                                          Icons.videogame_asset,
                                          size: 40,
                                          color: Colors.blue,
                                        ),
                                      ),
                                ),
                              )
                            else
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.videogame_asset,
                                  size: 40,
                                  color: Colors.blue,
                                ),
                              ),
                            const SizedBox(width: 16),
                            // Informações do console
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.console.nome,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  if (widget.console.dataLancamento !=
                                      null) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      'Lançamento: ${widget.console.dataLancamento!.day}/${widget.console.dataLancamento!.month}/${widget.console.dataLancamento!.year}',
                                      style:
                                          Theme.of(
                                            context,
                                          ).textTheme.bodyMedium,
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Chip(
                                        label: Text('${_jogos.length} jogos'),
                                        backgroundColor: Colors.blue.shade100,
                                      ),
                                      const SizedBox(width: 8),
                                      Chip(
                                        label: Text(
                                          '${_acessorios.length} acessórios',
                                        ),
                                        backgroundColor: Colors.green.shade100,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // TabBarView com os conteúdos
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Aba de Jogos
                        _isJogosGridView
                            ? _buildJogosGrid()
                            : _buildJogosList(),

                        // Aba de Acessórios
                        _buildAcessoriosList(),
                      ],
                    ),
                  ),
                ],
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabController.index == 0) {
            _adicionarJogo();
          } else {
            _adicionarAcessorio();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
