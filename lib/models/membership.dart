class Membership {
  final String membershipId;
  final String memberId;
  final String planId;
  final DateTime? startDate;
  final DateTime? expiryDate;
  final double totalFee;
  final String status;

  Membership({
    required this.membershipId,
    required this.memberId,
    required this.planId,
    this.startDate,
    this.expiryDate,
    this.totalFee = 0,
    this.status = 'Active',
  });

  String computeStatus() {
    if (expiryDate == null) return 'Active';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiry = DateTime(expiryDate!.year, expiryDate!.month, expiryDate!.day);
    if (expiry.isBefore(today)) return 'Expired';
    if (expiry.difference(today).inDays <= 7) return 'Expiring Soon';
    return 'Active';
  }

  int get daysUntilExpiry {
    if (expiryDate == null) return 999;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiry = DateTime(expiryDate!.year, expiryDate!.month, expiryDate!.day);
    return expiry.difference(today).inDays;
  }

  Map<String, dynamic> toMap() => {
    'MembershipID': membershipId,
    'MemberID': memberId,
    'PlanID': planId,
    'StartDate': startDate?.toIso8601String() ?? '',
    'ExpiryDate': expiryDate?.toIso8601String() ?? '',
    'TotalFee': totalFee,
    'Status': status,
  };

  factory Membership.fromMap(Map<String, dynamic> map) => Membership(
    membershipId: map['MembershipID']?.toString() ?? '',
    memberId: map['MemberID']?.toString() ?? '',
    planId: map['PlanID']?.toString() ?? '',
    startDate: map['StartDate'] != null && map['StartDate'].toString().isNotEmpty
        ? DateTime.tryParse(map['StartDate'].toString())
        : null,
    expiryDate: map['ExpiryDate'] != null && map['ExpiryDate'].toString().isNotEmpty
        ? DateTime.tryParse(map['ExpiryDate'].toString())
        : null,
    totalFee: double.tryParse(map['TotalFee']?.toString() ?? '0') ?? 0,
    status: map['Status']?.toString() ?? 'Active',
  );
}
