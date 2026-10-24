class Plan {
  final String planId;
  final String planName;
  final int durationMonths;
  final double price;

  Plan({
    required this.planId,
    required this.planName,
    required this.durationMonths,
    required this.price,
  });

  Map<String, dynamic> toMap() => {
    'PlanID': planId,
    'PlanName': planName,
    'DurationMonths': durationMonths,
    'Price': price,
  };

  factory Plan.fromMap(Map<String, dynamic> map) => Plan(
    planId: map['PlanID']?.toString() ?? '',
    planName: map['PlanName']?.toString() ?? '',
    durationMonths: int.tryParse(map['DurationMonths']?.toString() ?? '0') ?? 0,
    price: double.tryParse(map['Price']?.toString() ?? '0') ?? 0,
  );
}
