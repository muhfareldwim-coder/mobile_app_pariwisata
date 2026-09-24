class Booking {
  const Booking({
    required this.id,
    required this.destinationId,
    required this.visitDate,
    required this.adultCount,
    required this.childCount,
    required this.leaderName,
    required this.leaderEmail,
    required this.leaderPhone,
    required this.memberNames,
    this.status = 'pending',
  });

  final String id;
  final String destinationId;
  final DateTime visitDate;
  final int adultCount;
  final int childCount;
  final String leaderName;
  final String leaderEmail;
  final String leaderPhone;
  final List<String> memberNames;
  final String status;

  int get quantity => adultCount + childCount;
}