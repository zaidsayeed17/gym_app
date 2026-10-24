import 'package:flutter/material.dart';
import '../models/member.dart';
import '../models/membership.dart';
import '../models/payment.dart';
import '../models/plan.dart';
import '../models/joined_member.dart';
import '../models/joined_payment.dart';
import '../models/joined_plan.dart';
import '../services/excel_service.dart';

class AppDataProvider extends ChangeNotifier {
  final ExcelService _excelService = ExcelService();

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool _isMembersLoading = false;
  bool get isMembersLoading => _isMembersLoading;

  Map<String, dynamic> _dashboardStats = {
    'totalMembers': 0,
    'activeMembers': 0,
    'expiringSoon': 0,
    'expiredMembers': 0,
    'todaysCollection': 0.0,
    'pendingPayments': 0.0,
    'newThisMonth': 0,
  };
  Map<String, dynamic> get dashboardStats => _dashboardStats;

  List<Map<String, dynamic>> _expiringSoonMembers = [];
  List<Map<String, dynamic>> get expiringSoonMembers => _expiringSoonMembers;

  List<JoinedMember> _allJoinedMembers = [];
  List<JoinedMember> get allJoinedMembers => _allJoinedMembers;

  List<JoinedPayment> _allJoinedPayments = [];
  List<JoinedPayment> get allJoinedPayments => _allJoinedPayments;

  List<JoinedPlan> _allJoinedPlans = [];
  List<JoinedPlan> get allJoinedPlans => _allJoinedPlans;

  bool _isPaymentsLoading = false;
  bool get isPaymentsLoading => _isPaymentsLoading;

  bool _isPlansLoading = false;
  bool get isPlansLoading => _isPlansLoading;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  String _selectedStatusFilter = 'All'; // All, Active, Expiring Soon, Expired
  String get selectedStatusFilter => _selectedStatusFilter;

  String _paymentSearchQuery = '';
  String get paymentSearchQuery => _paymentSearchQuery;

  String _selectedPaymentMethodFilter = 'All'; // All, Cash, UPI, Card
  String get selectedPaymentMethodFilter => _selectedPaymentMethodFilter;

  DateTimeRange? _selectedDateRange;
  DateTimeRange? get selectedDateRange => _selectedDateRange;

  double dailyGoal = 5000.0; // Default daily collection goal in INR

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    await _excelService.initialize();
    await refreshDashboard();
    await loadMembers();
    await loadPayments();
    await loadPlans();
  }

  Future<void> refreshDashboard() async {
    try {
      _dashboardStats = await _excelService.getDashboardStats();
      _expiringSoonMembers = await _excelService.getExpiringSoonMembers();
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadMembers() async {
    _isMembersLoading = true;
    notifyListeners();

    try {
      _allJoinedMembers = await _excelService.getJoinedMembers();
    } catch (e) {
      debugPrint('Error loading members: $e');
    }

    _isMembersLoading = false;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setStatusFilter(String filter) {
    _selectedStatusFilter = filter;
    notifyListeners();
  }

  Future<void> loadPlans() async {
    _isPlansLoading = true;
    notifyListeners();

    try {
      _allJoinedPlans = await _excelService.getPlansWithMemberCount();
    } catch (e) {
      debugPrint('Error loading plans: $e');
    }

    _isPlansLoading = false;
    notifyListeners();
  }

  Future<String> savePlan(Plan plan) async {
    final planId = await _excelService.savePlan(plan);
    await loadPlans();
    await loadMembers();
    return planId;
  }

  Future<bool> deletePlan(String planId) async {
    final deleted = await _excelService.deletePlan(planId);
    if (deleted) {
      await loadPlans();
      await loadMembers();
    }
    return deleted;
  }

  Future<void> loadPayments() async {
    _isPaymentsLoading = true;
    notifyListeners();

    try {
      _allJoinedPayments = await _excelService.getAllPaymentsWithMemberDetails();
    } catch (e) {
      debugPrint('Error loading payments: $e');
    }

    _isPaymentsLoading = false;
    notifyListeners();
  }

  void setPaymentSearchQuery(String query) {
    _paymentSearchQuery = query;
    notifyListeners();
  }

  void setPaymentMethodFilter(String method) {
    _selectedPaymentMethodFilter = method;
    notifyListeners();
  }

  void setDateRangeFilter(DateTimeRange? range) {
    _selectedDateRange = range;
    notifyListeners();
  }

  List<JoinedPayment> get filteredPayments {
    return _allJoinedPayments.where((jp) {
      // 1. Search Query filter (Member Name, Mobile Number, or Member ID)
      if (_paymentSearchQuery.isNotEmpty) {
        final q = _paymentSearchQuery.toLowerCase();
        final nameMatch = jp.member.name.toLowerCase().contains(q);
        final mobileMatch = jp.member.mobileNumber.contains(q);
        final idMatch = jp.member.memberId.toLowerCase().contains(q);
        if (!nameMatch && !mobileMatch && !idMatch) return false;
      }

      // 2. Payment Method filter
      if (_selectedPaymentMethodFilter != 'All') {
        if (jp.payment.method != _selectedPaymentMethodFilter) return false;
      }

      // 3. Date Range filter
      if (_selectedDateRange != null && jp.payment.date != null) {
        final date = DateTime(jp.payment.date!.year, jp.payment.date!.month, jp.payment.date!.day);
        final start = DateTime(_selectedDateRange!.start.year, _selectedDateRange!.start.month, _selectedDateRange!.start.day);
        final end = DateTime(_selectedDateRange!.end.year, _selectedDateRange!.end.month, _selectedDateRange!.end.day);
        if (date.isBefore(start) || date.isAfter(end)) return false;
      }

      return true;
    }).toList();
  }

  Future<String> addStandalonePayment({
    required String memberId,
    required double amountPaid,
    required String paymentMethod,
    DateTime? date,
  }) async {
    final paymentId = await _excelService.addStandalonePayment(
      memberId: memberId,
      amountPaid: amountPaid,
      paymentMethod: paymentMethod,
      date: date,
    );

    await refreshDashboard();
    await loadMembers();
    await loadPayments();
    return paymentId;
  }

  List<JoinedMember> get filteredMembers {
    return _allJoinedMembers.where((jm) {
      // 1. Search Query filter (Name, MobileNumber, or MemberID)
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final nameMatch = jm.member.name.toLowerCase().contains(q);
        final mobileMatch = jm.member.mobileNumber.contains(q);
        final idMatch = jm.member.memberId.toLowerCase().contains(q);
        if (!nameMatch && !mobileMatch && !idMatch) return false;
      }

      // 2. Status filter
      if (_selectedStatusFilter != 'All') {
        if (_selectedStatusFilter == 'Active' && jm.status != 'Active') return false;
        if (_selectedStatusFilter == 'Expiring Soon' && jm.status != 'Expiring Soon') return false;
        if (_selectedStatusFilter == 'Expired' && jm.status != 'Expired') return false;
      }

      return true;
    }).toList();
  }

  Future<String> addMember({
    required Member member,
    required Membership membership,
    Payment? payment,
  }) async {
    final memberId = await _excelService.saveNewMemberWithMembershipAndPayment(
      member: member,
      membership: membership,
      payment: payment,
    );

    await refreshDashboard();
    await loadMembers();
    await loadPayments();
    return memberId;
  }

  Future<void> updateMember({
    required Member member,
    required Membership membership,
    String? oldMemberId,
  }) async {
    await _excelService.updateMemberAndMembership(
      member: member,
      membership: membership,
      oldMemberId: oldMemberId,
    );

    await refreshDashboard();
    await loadMembers();
    await loadPayments();
  }

  Future<String> renewMembership({
    required String memberId,
    required String planId,
    required DateTime startDate,
    required DateTime expiryDate,
    required double totalFee,
    required double amountPaid,
    required String paymentMethod,
  }) async {
    final membershipId = await _excelService.renewMembership(
      memberId: memberId,
      planId: planId,
      startDate: startDate,
      expiryDate: expiryDate,
      totalFee: totalFee,
      amountPaid: amountPaid,
      paymentMethod: paymentMethod,
    );

    await refreshDashboard();
    await loadMembers();
    return membershipId;
  }

  Future<void> deleteMember(String memberId) async {
    await _excelService.deleteMemberCascade(memberId);
    await refreshDashboard();
    await loadMembers();
  }

  double get collectionProgress {
    final collection = (_dashboardStats['todaysCollection'] as num?)?.toDouble() ?? 0;
    if (dailyGoal <= 0) return 0;
    return (collection / dailyGoal).clamp(0.0, 1.0);
  }

  int get collectionPercentage => (collectionProgress * 100).round();
}
