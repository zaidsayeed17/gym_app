class Payment {
  final String paymentId;
  final String memberId;
  final String membershipId;
  final DateTime? date;
  final double amountPaid;
  final double remainingAmount;
  final String method;

  Payment({
    required this.paymentId,
    required this.memberId,
    required this.membershipId,
    this.date,
    this.amountPaid = 0,
    this.remainingAmount = 0,
    this.method = 'Cash',
  });

  Map<String, dynamic> toMap() => {
    'PaymentID': paymentId,
    'MemberID': memberId,
    'MembershipID': membershipId,
    'Date': date?.toIso8601String() ?? '',
    'AmountPaid': amountPaid,
    'RemainingAmount': remainingAmount,
    'Method': method,
  };

  factory Payment.fromMap(Map<String, dynamic> map) => Payment(
    paymentId: map['PaymentID']?.toString() ?? '',
    memberId: map['MemberID']?.toString() ?? '',
    membershipId: map['MembershipID']?.toString() ?? '',
    date: map['Date'] != null && map['Date'].toString().isNotEmpty
        ? DateTime.tryParse(map['Date'].toString())
        : null,
    amountPaid: double.tryParse(map['AmountPaid']?.toString() ?? '0') ?? 0,
    remainingAmount: double.tryParse(map['RemainingAmount']?.toString() ?? '0') ?? 0,
    method: map['Method']?.toString() ?? 'Cash',
  );
}
