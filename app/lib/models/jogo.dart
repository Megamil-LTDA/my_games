class Jogo {
  String id;
  String nome;
  String capa;
  DateTime? dataLancamento;
  String consoleId;
  double notaPessoal;
  DateTime? dataCompra;
  DateTime? dataFinalizado;
  DateTime? ultimaVezJogado;
  bool isOriginal;
  bool bomEstado;
  bool temCapaEAcessorios;

  Jogo({
    required this.id,
    required this.nome,
    this.capa = '',
    this.dataLancamento,
    required this.consoleId,
    this.notaPessoal = 0.0,
    this.dataCompra,
    this.dataFinalizado,
    this.ultimaVezJogado,
    this.isOriginal = true,
    this.bomEstado = true,
    this.temCapaEAcessorios = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'capa': capa,
      'dataLancamento': dataLancamento?.toIso8601String(),
      'consoleId': consoleId,
      'notaPessoal': notaPessoal,
      'dataCompra': dataCompra?.toIso8601String(),
      'dataFinalizado': dataFinalizado?.toIso8601String(),
      'ultimaVezJogado': ultimaVezJogado?.toIso8601String(),
      'isOriginal': isOriginal,
      'bomEstado': bomEstado,
      'temCapaEAcessorios': temCapaEAcessorios,
    };
  }

  factory Jogo.fromMap(Map<String, dynamic> map) {
    return Jogo(
      id: map['id'],
      nome: map['nome'],
      capa: map['capa'] ?? '',
      dataLancamento:
          map['dataLancamento'] != null
              ? DateTime.parse(map['dataLancamento'])
              : null,
      consoleId: map['consoleId'],
      notaPessoal: map['notaPessoal'] ?? 0.0,
      dataCompra:
          map['dataCompra'] != null ? DateTime.parse(map['dataCompra']) : null,
      dataFinalizado:
          map['dataFinalizado'] != null
              ? DateTime.parse(map['dataFinalizado'])
              : null,
      ultimaVezJogado:
          map['ultimaVezJogado'] != null
              ? DateTime.parse(map['ultimaVezJogado'])
              : null,
      isOriginal: map['isOriginal'] ?? true,
      bomEstado: map['bomEstado'] ?? true,
      temCapaEAcessorios: map['temCapaEAcessorios'] ?? true,
    );
  }
}
