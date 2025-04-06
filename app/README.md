# My Games - Gerenciador de Coleção de Jogos

Aplicativo Flutter para gerenciar uma coleção de jogos, consoles e acessórios.

## Funcionalidades

- Gerenciamento de consoles, jogos e acessórios
- Integração com a API RAWG.io para busca automática de informações
- Autocomplete ao digitar nomes de consoles e jogos
- Suporte a múltiplas plataformas (Web, Android, iOS, desktop)
- Importação e exportação de dados

## Recursos Técnicos

- Interface responsiva que se adapta a diferentes tamanhos de tela
- Armazenamento local usando SQLite em dispositivos móveis/desktop
- Armazenamento usando SharedPreferences e SQLite (via web) em navegadores
- Design moderno com Material 3

## Como executar

1. Certifique-se de ter o Flutter instalado (versão 3.7.2 ou superior)
2. Clone este repositório
3. Execute `flutter pub get` para instalar as dependências
4. Execute `flutter run` para iniciar o aplicativo

## API do RAWG

O aplicativo usa a API RAWG.io para buscar informações sobre jogos e consoles. 
Para usar a API, é necessário:

1. Criar uma conta em https://rawg.io
2. Obter uma chave de API em https://rawg.io/apidocs
3. Inserir a chave no arquivo `lib/services/api_service.dart`

## Licença

Este projeto é distribuído sob a licença MIT.
