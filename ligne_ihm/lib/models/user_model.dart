class User {
  final String matricule;
  final String nom;
  final String prenom;

  User({
    required this.matricule,
    required this.nom,
    required this.prenom,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      matricule: json['matricule'] ?? '',
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'matricule': matricule,
      'nom': nom,
      'prenom': prenom,
    };
  }
}
