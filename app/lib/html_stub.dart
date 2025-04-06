// Este arquivo funciona apenas como um stub para permitir compilação em plataformas não-web
// Estas classes não serão usadas na prática, pois o código que as utiliza é condicional para web

class Blob {
  Blob(List<dynamic> data, String type) {}
}

class Url {
  static String createObjectUrlFromBlob(dynamic blob) => '';
  static void revokeObjectUrl(String url) {}
}

class AnchorElement {
  AnchorElement({String? href}) {}

  void setAttribute(String name, String value) {}
  void click() {}
}
