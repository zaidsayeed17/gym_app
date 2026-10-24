import 'member.dart';
import 'membership.dart';
import 'payment.dart';
import 'plan.dart';

class JoinedPayment {
  final Payment payment;
  final Member member;
  final Membership? membership;
  final Plan? plan;

  JoinedPayment({
    required this.payment,
    required this.member,
    this.membership,
    this.plan,
  });

  String get planName => plan?.planName ?? 'General Membership';
}
