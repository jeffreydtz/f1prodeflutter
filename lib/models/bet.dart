class Bet {
  final String userId;
  final String raceId;
  final String poleman;
  final List<String> top10;
  final List<String> dnfs;

  Bet({
    required this.userId,
    required this.raceId,
    required this.poleman,
    required this.top10,
    required this.dnfs,
  });
}
