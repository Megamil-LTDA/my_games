import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Minha Coleção de Jogos'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Adaptar o layout com base no tamanho da tela
                  final crossAxisCount =
                      constraints.maxWidth < 600
                          ? 2
                          : constraints.maxWidth < 900
                          ? 3
                          : 4;

                  return GridView.count(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: isSmallScreen ? 1.0 : 1.3,
                    children: [
                      _buildMenuCard(
                        context,
                        'Consoles',
                        Icons.videogame_asset,
                        Colors.blue,
                        () => Navigator.pushNamed(context, '/consoles'),
                        isSmallScreen,
                      ),
                      _buildMenuCard(
                        context,
                        'Jogos',
                        Icons.sports_esports,
                        Colors.red,
                        () => Navigator.pushNamed(context, '/jogos'),
                        isSmallScreen,
                      ),
                      _buildMenuCard(
                        context,
                        'Acessórios',
                        Icons.cable,
                        Colors.green,
                        () => Navigator.pushNamed(context, '/acessorios'),
                        isSmallScreen,
                      ),
                      _buildMenuCard(
                        context,
                        'Importar/Exportar',
                        Icons.import_export,
                        Colors.purple,
                        () => Navigator.pushNamed(context, '/import_export'),
                        isSmallScreen,
                      ),
                    ],
                  );
                },
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 16.0),
              child: Text(
                'Gerenciador de coleção de jogos',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
    bool isSmallScreen,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(isSmallScreen ? 16.0 : 12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: isSmallScreen ? 48 : 36, color: color),
              SizedBox(height: isSmallScreen ? 8 : 4),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
