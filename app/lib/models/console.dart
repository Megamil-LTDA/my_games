class Console {
  String id;
  String nome;
  String foto;
  DateTime? dataLancamento;

  Console({
    required this.id,
    required this.nome,
    this.foto = '',
    this.dataLancamento,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'foto': foto,
      'dataLancamento': dataLancamento?.toIso8601String(),
    };
  }

  factory Console.fromMap(Map<String, dynamic> map) {
    return Console(
      id: map['id'],
      nome: map['nome'],
      foto: map['foto'] ?? '',
      dataLancamento:
          map['dataLancamento'] != null
              ? DateTime.parse(map['dataLancamento'])
              : null,
    );
  }
}
