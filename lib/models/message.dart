class Message {
  final int id;
  final String titre;
  final String contenu;
  final String auteur;
  final DateTime datePoste;

  Message({
    required this.id,
    required this.titre,
    required this.contenu,
    required this.auteur,
    required this.datePoste,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      titre: json['titre'],
      contenu: json['contenu'],
      auteur: json['auteur'],
      datePoste: DateTime.parse(json['datePoste']),
    );
  }
}