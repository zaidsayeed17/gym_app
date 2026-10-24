import 'joined_payment.dart';

class ReportData {
  final double totalCollectionInRange;
  final int paymentsCountInRange;
  final Map<String, double> monthlyRevenueMap;
  final List<JoinedPayment> paymentsInRange;
  final int activeMembersCount;
  final int expiredMembersCount;
  final int expiringSoonCount;
  final double totalPendingBalance;

  ReportData({
    required this.totalCollectionInRange,
    required this.paymentsCountInRange,
    required this.monthlyRevenueMap,
    required this.paymentsInRange,
    required this.activeMembersCount,
    required this.expiredMembersCount,
    required this.expiringSoonCount,
    required this.totalPendingBalance,
  });
}
