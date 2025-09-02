class Bet {
  final String? id;
  final String season;
  final String round;
  final String raceName;
  final String date;
  final String circuit;
  final bool hasSprint;
  final String poleman;
  final List<String> top10;
  final String dnf; // Single DNF prediction
  final String fastestLap;
  final List<String>? sprintTop10;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isSubmitted;

  Bet({
    this.id,
    required this.season,
    required this.round,
    required this.raceName,
    required this.date,
    required this.circuit,
    this.hasSprint = false,
    required this.poleman,
    required this.top10,
    required this.dnf,
    required this.fastestLap,
    this.sprintTop10,
    this.createdAt,
    this.updatedAt,
    this.isSubmitted = false,
  });

  factory Bet.fromJson(Map<String, dynamic> json) {
    return Bet(
      id: json['id']?.toString(),
      season: json['season']?.toString() ?? '',
      round: json['round']?.toString() ?? '',
      raceName: json['race_name'] ?? json['raceName'] ?? '',
      date: json['date'] ?? '',
      circuit: json['circuit'] ?? '',
      hasSprint: json['has_sprint'] ?? json['hasSprint'] ?? false,
      poleman: json['poleman'] ?? '',
      top10: List<String>.from(json['top10'] ?? []),
      dnf: json['dnf'] ?? '',
      fastestLap: json['fastest_lap'] ?? json['fastestLap'] ?? '',
      sprintTop10: json['sprint_top10'] != null 
          ? List<String>.from(json['sprint_top10']) 
          : null,
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at']) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.tryParse(json['updated_at']) 
          : null,
      isSubmitted: json['is_submitted'] ?? json['submitted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'season': season,
      'round': round,
      'race_name': raceName,
      'date': date,
      'circuit': circuit,
      'has_sprint': hasSprint,
      'poleman': poleman,
      'top10': top10,
      'dnf': dnf,
      'fastest_lap': fastestLap,
      if (sprintTop10 != null) 'sprint_top10': sprintTop10,
    };
  }

  Bet copyWith({
    String? id,
    String? season,
    String? round,
    String? raceName,
    String? date,
    String? circuit,
    bool? hasSprint,
    String? poleman,
    List<String>? top10,
    String? dnf,
    String? fastestLap,
    List<String>? sprintTop10,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSubmitted,
  }) {
    return Bet(
      id: id ?? this.id,
      season: season ?? this.season,
      round: round ?? this.round,
      raceName: raceName ?? this.raceName,
      date: date ?? this.date,
      circuit: circuit ?? this.circuit,
      hasSprint: hasSprint ?? this.hasSprint,
      poleman: poleman ?? this.poleman,
      top10: top10 ?? this.top10,
      dnf: dnf ?? this.dnf,
      fastestLap: fastestLap ?? this.fastestLap,
      sprintTop10: sprintTop10 ?? this.sprintTop10,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSubmitted: isSubmitted ?? this.isSubmitted,
    );
  }

  bool get isValid {
    return poleman.isNotEmpty &&
           top10.length == 10 &&
           dnf.isNotEmpty &&
           fastestLap.isNotEmpty &&
           (!hasSprint || (sprintTop10?.length == 10));
  }
}
