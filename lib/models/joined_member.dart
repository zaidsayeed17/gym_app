import 'member.dart';
import 'membership.dart';
import 'plan.dart';

class JoinedMember {
  final Member member;
  final Membership? currentMembership;
  final Plan? currentPlan;
  final double totalFee;
  final double totalPaid;
  final double remainingAmount;
  final String status;
  final int daysUntilExpiry;

  JoinedMember({
    required this.member,
    this.currentMembership,
    this.currentPlan,
    this.totalFee = 0.0,
    this.totalPaid = 0.0,
    this.remainingAmount = 0.0,
    required this.status,
    this.daysUntilExpiry = 999,
  });

  String get planName => currentPlan?.planName ?? 'No Plan';

  bool get isActive => status == 'Active';
  bool get isExpiringSoon => status == 'Expiring Soon';
  bool get isExpired => status == 'Expired';
}
