class Tournament {
  final String id;
  final String name;
  final String inviteCode;
  final List<String> participants;

  Tournament({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.participants,
  });
}
