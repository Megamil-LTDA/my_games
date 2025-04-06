class Acessorio {
  String id;
  String nome;
  String consoleId;
  String descricao;
  String foto;
  DateTime? ultimaVezTestado;

  Acessorio({
    required this.id,
    required this.nome,
    required this.consoleId,
    this.descricao = '',
    this.foto = '',
    this.ultimaVezTestado,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'consoleId': consoleId,
      'descricao': descricao,
      'foto': foto,
      'ultimaVezTestado': ultimaVezTestado?.toIso8601String(),
    };
  }

  factory Acessorio.fromMap(Map<String, dynamic> map) {
    return Acessorio(
      id: map['id'],
      nome: map['nome'],
      consoleId: map['consoleId'],
      descricao: map['descricao'] ?? '',
      foto: map['foto'] ?? '',
      ultimaVezTestado:
          map['ultimaVezTestado'] != null
              ? DateTime.parse(map['ultimaVezTestado'])
              : null,
    );
  }
}
