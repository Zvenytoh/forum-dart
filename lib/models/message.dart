class Message {
  final int? id;
  final String titre;
  final String contenu;
  final String envoyer;
  final String repondre;
  final List<String> messages;
  final List<String> votes;
  final int score;
  final DateTime datePoste;

  Message({
    this.id,
    required this.titre,
    required this.contenu,
    required this.envoyer,
    required this.repondre,
    required this.messages,
    required this.votes,
    required this.score,
    required this.datePoste,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      titre: json['titre'],
      contenu: json['contenu'],
      envoyer: json['envoyer'],
      repondre: json['repondre'],
      messages: List<String>.from(json['messages'] ?? []),
      votes: List<String>.from(json['votes'] ?? []),
      score: json['score'],
      datePoste: DateTime.parse(json['datePoste']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "titre": titre,
      "datePoste": datePoste.toIso8601String(),
      "contenu": contenu,
      "envoyer": envoyer,
      "repondre": repondre,
      "messages": messages,
      "votes": votes,
      "score": score,
    };
  }
}
