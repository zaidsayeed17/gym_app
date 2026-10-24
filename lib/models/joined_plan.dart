import 'plan.dart';

class JoinedPlan {
  final Plan plan;
  final int activeMemberCount;

  JoinedPlan({
    required this.plan,
    required this.activeMemberCount,
  });

  bool get isInUse => activeMemberCount > 0;
}
