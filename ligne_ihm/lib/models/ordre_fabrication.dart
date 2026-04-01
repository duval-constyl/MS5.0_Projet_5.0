class OrdreFabrication {
  final String numeroOf;
  final String variante;
  final List<String> etapes;
  final int tempsAlloueSec;

  OrdreFabrication({
    required this.numeroOf,
    required this.variante,
    required this.etapes,
    required this.tempsAlloueSec,
  });

  factory OrdreFabrication.fromJson(Map<String, dynamic> json) {
    return OrdreFabrication(
      numeroOf: json['of'] ?? '-',
      variante: json['variante'] ?? '-',
      etapes: List<String>.from(json['etapes'] ?? []),
      tempsAlloueSec: json['temps_alloue'] ?? 60, // 60s par défaut si non précisé
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'of': numeroOf,
      'variante': variante,
      'etapes': etapes,
      'temps_alloue': tempsAlloueSec,
    };
  }
}
