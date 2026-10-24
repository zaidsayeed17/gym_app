import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import '../models/member.dart';
import '../models/membership.dart';
import '../models/payment.dart';
import '../models/plan.dart';
import '../models/joined_member.dart';
import '../models/joined_payment.dart';
import 'package:intl/intl.dart';
import '../models/joined_plan.dart';
import '../models/report_data.dart';
import '../models/gym_settings.dart';

class ExcelService {
  static final ExcelService _instance = ExcelService._internal();
  factory ExcelService() => _instance;
  ExcelService._internal();

  String? _filePath;

  Future<String> get filePath async {
    if (_filePath != null) return _filePath!;
    final dir = await getApplicationDocumentsDirectory();
    _filePath = '${dir.path}/gym_data.xlsx';
    return _filePath!;
  }

  // ─── Sheet & Column Definitions ───
  static const String membersSheet = 'Members';
  static const String membershipsSheet = 'Memberships';
  static const String paymentsSheet = 'Payments';
  static const String plansSheet = 'Plans';
  static const String settingsSheet = 'Settings';

  static const List<String> memberColumns = [
    'MemberID', 'Name', 'MobileNumber', 'Address', 'PhotoPath', 'JoiningDate',
  ];
  static const List<String> membershipColumns = [
    'MembershipID', 'MemberID', 'PlanID', 'StartDate', 'ExpiryDate', 'TotalFee', 'Status',
  ];
  static const List<String> paymentColumns = [
    'PaymentID', 'MemberID', 'MembershipID', 'Date', 'AmountPaid', 'RemainingAmount', 'Method',
  ];
  static const List<String> planColumns = [
    'PlanID', 'PlanName', 'DurationMonths', 'Price',
  ];
  static const List<String> settingsColumns = [
    'GymName', 'LogoPath', 'Address', 'ContactNumber', 'OwnerName', 'LastBackupDate',
  ];

  // ─── Initialize Workbook ───
  Future<void> initialize() async {
    final path = await filePath;
    final file = File(path);

    if (!await file.exists()) {
      final excel = Excel.createExcel();

      // Create sheets with headers
      _createSheetWithHeaders(excel, membersSheet, memberColumns);
      _createSheetWithHeaders(excel, membershipsSheet, membershipColumns);
      _createSheetWithHeaders(excel, paymentsSheet, paymentColumns);
      _createSheetWithHeaders(excel, plansSheet, planColumns);
      _createSheetWithHeaders(excel, settingsSheet, settingsColumns);

      // Remove default 'Sheet1' if it exists
      if (excel.sheets.containsKey('Sheet1')) {
        excel.delete('Sheet1');
      }

      // Seed default plans
      _addRowToSheet(excel, plansSheet, planColumns, {
        'PlanID': 'PLN-001', 'PlanName': '1 Month', 'DurationMonths': 1, 'Price': 500,
      });
      _addRowToSheet(excel, plansSheet, planColumns, {
        'PlanID': 'PLN-002', 'PlanName': '3 Months', 'DurationMonths': 3, 'Price': 1400,
      });
      _addRowToSheet(excel, plansSheet, planColumns, {
        'PlanID': 'PLN-003', 'PlanName': '6 Months', 'DurationMonths': 6, 'Price': 2500,
      });
      _addRowToSheet(excel, plansSheet, planColumns, {
        'PlanID': 'PLN-004', 'PlanName': '12 Months', 'DurationMonths': 12, 'Price': 4500,
      });

      // Seed default settings
      _addRowToSheet(excel, settingsSheet, settingsColumns, GymSettings.defaultSettings().toMap());

      final bytes = excel.save();
      if (bytes != null) {
        await file.writeAsBytes(bytes);
      }
    } else {
      // Ensure Settings sheet exists in existing workbook
      final excel = await _readWorkbook();
      if (!excel.sheets.containsKey(settingsSheet)) {
        _createSheetWithHeaders(excel, settingsSheet, settingsColumns);
        _addRowToSheet(excel, settingsSheet, settingsColumns, GymSettings.defaultSettings().toMap());
        await _saveWorkbook(excel);
      }
    }
  }

  void _createSheetWithHeaders(Excel excel, String sheetName, List<String> columns) {
    final sheet = excel[sheetName];
    for (int i = 0; i < columns.length; i++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0)).value =
          TextCellValue(columns[i]);
    }
  }

  void _addRowToSheet(Excel excel, String sheetName, List<String> columns, Map<String, dynamic> data) {
    final sheet = excel[sheetName];
    final rowIndex = sheet.maxRows;
    for (int i = 0; i < columns.length; i++) {
      final value = data[columns[i]];
      if (value is int) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: rowIndex)).value =
            IntCellValue(value);
      } else if (value is double) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: rowIndex)).value =
            DoubleCellValue(value);
      } else {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: rowIndex)).value =
            TextCellValue(value?.toString() ?? '');
      }
    }
  }

  // ─── Read Workbook ───
  Future<Excel> _readWorkbook() async {
    final path = await filePath;
    final file = File(path);
    final bytes = await file.readAsBytes();
    return Excel.decodeBytes(bytes);
  }

  // ─── Save Workbook ───
  Future<void> _saveWorkbook(Excel excel) async {
    final path = await filePath;
    final file = File(path);
    final bytes = excel.save();
    if (bytes != null) {
      await file.writeAsBytes(bytes);
    }
  }

  // ─── Generic Read All Rows ───
  List<Map<String, dynamic>> _readSheet(Excel excel, String sheetName, List<String> columns) {
    final sheet = excel[sheetName];
    final rows = <Map<String, dynamic>>[];

    for (int rowIndex = 1; rowIndex < sheet.maxRows; rowIndex++) {
      final map = <String, dynamic>{};
      bool hasData = false;
      for (int colIndex = 0; colIndex < columns.length; colIndex++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: colIndex, rowIndex: rowIndex));
        final value = cell.value;
        if (value != null) hasData = true;
        if (value is IntCellValue) {
          map[columns[colIndex]] = value.value;
        } else if (value is DoubleCellValue) {
          map[columns[colIndex]] = value.value;
        } else if (value is TextCellValue) {
          map[columns[colIndex]] = value.value;
        } else {
          map[columns[colIndex]] = value?.toString() ?? '';
        }
      }
      if (hasData) rows.add(map);
    }
    return rows;
  }

  // ─── Get All Records ───
  Future<List<Member>> getAllMembers() async {
    final excel = await _readWorkbook();
    final rows = _readSheet(excel, membersSheet, memberColumns);
    return rows.map((m) => Member.fromMap(m)).toList();
  }

  Future<List<Membership>> getAllMemberships() async {
    final excel = await _readWorkbook();
    final rows = _readSheet(excel, membershipsSheet, membershipColumns);
    return rows.map((m) => Membership.fromMap(m)).toList();
  }

  Future<List<Payment>> getAllPayments() async {
    final excel = await _readWorkbook();
    final rows = _readSheet(excel, paymentsSheet, paymentColumns);
    return rows.map((p) => Payment.fromMap(p)).toList();
  }

  Future<List<Plan>> getAllPlans() async {
    final excel = await _readWorkbook();
    final rows = _readSheet(excel, plansSheet, planColumns);
    return rows.map((p) => Plan.fromMap(p)).toList();
  }

  // ─── Joined Members Query ───
  Future<List<JoinedMember>> getJoinedMembers() async {
    final excel = await _readWorkbook();
    final memberRows = _readSheet(excel, membersSheet, memberColumns);
    final membershipRows = _readSheet(excel, membershipsSheet, membershipColumns);
    final planRows = _readSheet(excel, plansSheet, planColumns);
    final paymentRows = _readSheet(excel, paymentsSheet, paymentColumns);

    final members = memberRows.map((m) => Member.fromMap(m)).toList();
    final memberships = membershipRows.map((m) => Membership.fromMap(m)).toList();
    final plans = planRows.map((p) => Plan.fromMap(p)).toList();
    final payments = paymentRows.map((p) => Payment.fromMap(p)).toList();

    final result = <JoinedMember>[];

    for (final member in members) {
      // Find latest membership for this member
      final mList = memberships.where((ms) => ms.memberId == member.memberId).toList();
      mList.sort((a, b) {
        if (a.startDate == null) return 1;
        if (b.startDate == null) return -1;
        return b.startDate!.compareTo(a.startDate!);
      });

      final currentMs = mList.isNotEmpty ? mList.first : null;
      Plan? currentPlan;
      double totalFee = 0.0;
      double totalPaid = 0.0;
      String computedStatus = 'Active';
      int daysLeft = 999;

      if (currentMs != null) {
        totalFee = currentMs.totalFee;
        computedStatus = currentMs.computeStatus();
        daysLeft = currentMs.daysUntilExpiry;

        final matchingPlans = plans.where((p) => p.planId == currentMs.planId).toList();
        if (matchingPlans.isNotEmpty) {
          currentPlan = matchingPlans.first;
        }

        // Sum payments for this membership
        final msPayments = payments.where((p) => p.membershipId == currentMs.membershipId);
        for (final p in msPayments) {
          totalPaid += p.amountPaid;
        }
      }

      final remaining = (totalFee - totalPaid).clamp(0.0, double.infinity);

      result.add(JoinedMember(
        member: member,
        currentMembership: currentMs,
        currentPlan: currentPlan,
        totalFee: totalFee,
        totalPaid: totalPaid,
        remainingAmount: remaining,
        status: computedStatus,
        daysUntilExpiry: daysLeft,
      ));
    }

    return result;
  }

  // ─── Member Profile Details Query ───
  Future<Map<String, dynamic>?> getMemberProfileDetails(String memberId) async {
    final joinedMembers = await getJoinedMembers();
    final matching = joinedMembers.where((jm) => jm.member.memberId == memberId).toList();
    if (matching.isEmpty) return null;

    final jm = matching.first;
    final allPayments = await getAllPayments();
    final memberPayments = allPayments.where((p) => p.memberId == memberId).toList();
    memberPayments.sort((a, b) {
      if (a.date == null) return 1;
      if (b.date == null) return -1;
      return b.date!.compareTo(a.date!);
    });

    return {
      'joinedMember': jm,
      'payments': memberPayments,
    };
  }

  // ─── Generate Next ID ───
  String _generateNextId(List<Map<String, dynamic>> existingRows, String idColumn, String prefix) {
    int maxNum = 0;
    for (final row in existingRows) {
      final id = row[idColumn]?.toString() ?? '';
      if (id.startsWith('$prefix-')) {
        final numStr = id.substring(prefix.length + 1);
        final num = int.tryParse(numStr) ?? 0;
        if (num > maxNum) maxNum = num;
      }
    }
    return '$prefix-${(maxNum + 1).toString().padLeft(3, '0')}';
  }

  // ─── Check if Member ID Exists (Case-Insensitive) ───
  Future<bool> isMemberIdExists(String memberId, {String? excludeMemberId}) async {
    final excel = await _readWorkbook();
    final memberRows = _readSheet(excel, membersSheet, memberColumns);
    final target = memberId.trim().toLowerCase();
    final exclude = excludeMemberId?.trim().toLowerCase();

    for (final m in memberRows) {
      final mId = m['MemberID']?.toString().trim().toLowerCase() ?? '';
      if (mId.isEmpty) continue;
      if (exclude != null && mId == exclude) continue;
      if (mId == target) return true;
    }
    return false;
  }

  // ─── Atomic Save New Member + Membership + Payment ───
  Future<String> saveNewMemberWithMembershipAndPayment({
    required Member member,
    required Membership membership,
    Payment? payment,
  }) async {
    final excel = await _readWorkbook();
    final memberId = member.memberId.trim();

    // 0. Check uniqueness
    final existingMembers = _readSheet(excel, membersSheet, memberColumns);
    final isDuplicate = existingMembers.any(
      (m) => m['MemberID']?.toString().trim().toLowerCase() == memberId.toLowerCase(),
    );
    if (isDuplicate) {
      throw Exception('Member ID "$memberId" is already in use.');
    }

    // 1. Add Member
    final memberData = member.toMap();
    memberData['MemberID'] = memberId;
    _addRowToSheet(excel, membersSheet, memberColumns, memberData);

    // 2. Add Membership
    final existingMemberships = _readSheet(excel, membershipsSheet, membershipColumns);
    final membershipId = _generateNextId(existingMemberships, 'MembershipID', 'MSH');
    final membershipData = membership.toMap();
    membershipData['MembershipID'] = membershipId;
    membershipData['MemberID'] = memberId;
    _addRowToSheet(excel, membershipsSheet, membershipColumns, membershipData);

    // 3. Add Optional Payment
    if (payment != null && payment.amountPaid > 0) {
      final existingPayments = _readSheet(excel, paymentsSheet, paymentColumns);
      final paymentId = _generateNextId(existingPayments, 'PaymentID', 'PAY');
      final paymentData = payment.toMap();
      paymentData['PaymentID'] = paymentId;
      paymentData['MemberID'] = memberId;
      paymentData['MembershipID'] = membershipId;
      _addRowToSheet(excel, paymentsSheet, paymentColumns, paymentData);
    }

    await _saveWorkbook(excel);
    return memberId;
  }

  // ─── Renew Membership (Atomic append new Membership & Payment) ───
  Future<String> renewMembership({
    required String memberId,
    required String planId,
    required DateTime startDate,
    required DateTime expiryDate,
    required double totalFee,
    required double amountPaid,
    required String paymentMethod,
  }) async {
    final excel = await _readWorkbook();

    // 1. Add new Membership
    final existingMemberships = _readSheet(excel, membershipsSheet, membershipColumns);
    final membershipId = _generateNextId(existingMemberships, 'MembershipID', 'MSH');

    final newMs = Membership(
      membershipId: membershipId,
      memberId: memberId,
      planId: planId,
      startDate: startDate,
      expiryDate: expiryDate,
      totalFee: totalFee,
      status: 'Active',
    );

    _addRowToSheet(excel, membershipsSheet, membershipColumns, newMs.toMap());

    // 2. Add new Payment if amountPaid > 0
    if (amountPaid > 0) {
      final existingPayments = _readSheet(excel, paymentsSheet, paymentColumns);
      final paymentId = _generateNextId(existingPayments, 'PaymentID', 'PAY');

      final newPay = Payment(
        paymentId: paymentId,
        memberId: memberId,
        membershipId: membershipId,
        date: DateTime.now(),
        amountPaid: amountPaid,
        remainingAmount: (totalFee - amountPaid).clamp(0.0, double.infinity),
        method: paymentMethod,
      );

      _addRowToSheet(excel, paymentsSheet, paymentColumns, newPay.toMap());
    }

    await _saveWorkbook(excel);
    return membershipId;
  }

  // ─── Add Standalone Payment (Against Active Membership) ───
  Future<String> addStandalonePayment({
    required String memberId,
    required double amountPaid,
    required String paymentMethod,
    DateTime? date,
  }) async {
    final excel = await _readWorkbook();

    // 1. Find member's latest active membership
    final membershipRows = _readSheet(excel, membershipsSheet, membershipColumns);
    final memberMsList = membershipRows
        .map((m) => Membership.fromMap(m))
        .where((m) => m.memberId == memberId)
        .toList();

    memberMsList.sort((a, b) {
      if (a.startDate == null) return 1;
      if (b.startDate == null) return -1;
      return b.startDate!.compareTo(a.startDate!);
    });

    final activeMs = memberMsList.isNotEmpty ? memberMsList.first : null;
    final membershipId = activeMs?.membershipId ?? '';
    final totalFee = activeMs?.totalFee ?? 0.0;

    // 2. Sum existing payments for this membership
    final paymentRows = _readSheet(excel, paymentsSheet, paymentColumns);
    final existingPayments = paymentRows.map((p) => Payment.fromMap(p)).toList();

    double paidSoFar = 0.0;
    for (final p in existingPayments) {
      if (p.membershipId == membershipId && membershipId.isNotEmpty) {
        paidSoFar += p.amountPaid;
      }
    }

    final newTotalPaid = paidSoFar + amountPaid;
    final remaining = (totalFee - newTotalPaid).clamp(0.0, double.infinity);

    // 3. Add Payment row
    final paymentId = _generateNextId(paymentRows, 'PaymentID', 'PAY');
    final newPay = Payment(
      paymentId: paymentId,
      memberId: memberId,
      membershipId: membershipId,
      date: date ?? DateTime.now(),
      amountPaid: amountPaid,
      remainingAmount: remaining,
      method: paymentMethod,
    );

    _addRowToSheet(excel, paymentsSheet, paymentColumns, newPay.toMap());
    await _saveWorkbook(excel);
    return paymentId;
  }

  // ─── Get All Payments Joined With Member & Plan Details ───
  Future<List<JoinedPayment>> getAllPaymentsWithMemberDetails() async {
    final excel = await _readWorkbook();
    final memberRows = _readSheet(excel, membersSheet, memberColumns);
    final membershipRows = _readSheet(excel, membershipsSheet, membershipColumns);
    final planRows = _readSheet(excel, plansSheet, planColumns);
    final paymentRows = _readSheet(excel, paymentsSheet, paymentColumns);

    final members = memberRows.map((m) => Member.fromMap(m)).toList();
    final memberships = membershipRows.map((m) => Membership.fromMap(m)).toList();
    final plans = planRows.map((p) => Plan.fromMap(p)).toList();
    final payments = paymentRows.map((p) => Payment.fromMap(p)).toList();

    final result = <JoinedPayment>[];

    for (final p in payments) {
      final matchingMembers = members.where((m) => m.memberId == p.memberId).toList();
      if (matchingMembers.isEmpty) continue;
      final member = matchingMembers.first;

      final matchingMs = memberships.where((ms) => ms.membershipId == p.membershipId).toList();
      final membership = matchingMs.isNotEmpty ? matchingMs.first : null;

      Plan? plan;
      if (membership != null) {
        final matchingPlans = plans.where((pl) => pl.planId == membership.planId).toList();
        if (matchingPlans.isNotEmpty) plan = matchingPlans.first;
      }

      result.add(JoinedPayment(
        payment: p,
        member: member,
        membership: membership,
        plan: plan,
      ));
    }

    result.sort((a, b) {
      if (a.payment.date == null) return 1;
      if (b.payment.date == null) return -1;
      return b.payment.date!.compareTo(a.payment.date!);
    });

    return result;
  }

  // ─── Get Single Payment Receipt Details ───
  Future<JoinedPayment?> getPaymentReceiptDetails(String paymentId) async {
    final allJoined = await getAllPaymentsWithMemberDetails();
    final matching = allJoined.where((jp) => jp.payment.paymentId == paymentId).toList();
    if (matching.isNotEmpty) return matching.first;
    return null;
  }

  // ─── Update Member and Membership ───
  Future<void> updateMemberAndMembership({
    required Member member,
    required Membership membership,
    String? oldMemberId,
  }) async {
    final excel = await _readWorkbook();
    final targetMemberId = (oldMemberId != null && oldMemberId.isNotEmpty) ? oldMemberId : member.memberId;

    // 0. Check uniqueness if ID was changed
    if (oldMemberId != null && oldMemberId.isNotEmpty && oldMemberId.toLowerCase() != member.memberId.toLowerCase()) {
      final existingMembers = _readSheet(excel, membersSheet, memberColumns);
      final isDuplicate = existingMembers.any(
        (m) => m['MemberID']?.toString().trim().toLowerCase() == member.memberId.trim().toLowerCase() &&
            m['MemberID']?.toString().trim().toLowerCase() != oldMemberId.toLowerCase(),
      );
      if (isDuplicate) {
        throw Exception('Member ID "${member.memberId}" is already in use.');
      }
    }

    // 1. Update Member Sheet
    final mSheet = excel[membersSheet];
    for (int rowIndex = 1; rowIndex < mSheet.maxRows; rowIndex++) {
      final cellVal = mSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value;
      if (cellVal?.toString() == targetMemberId) {
        final mData = member.toMap();
        for (int colIndex = 0; colIndex < memberColumns.length; colIndex++) {
          final colName = memberColumns[colIndex];
          if (mData.containsKey(colName)) {
            mSheet.cell(CellIndex.indexByColumnRow(columnIndex: colIndex, rowIndex: rowIndex)).value =
                TextCellValue(mData[colName]?.toString() ?? '');
          }
        }
        break;
      }
    }

    // 2. Cascade update Memberships and Payments if MemberID was edited
    if (oldMemberId != null && oldMemberId.isNotEmpty && oldMemberId != member.memberId) {
      // Cascade Memberships
      final msSheet = excel[membershipsSheet];
      for (int r = 1; r < msSheet.maxRows; r++) {
        final mIdVal = msSheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: r)).value;
        if (mIdVal?.toString() == oldMemberId) {
          msSheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: r)).value =
              TextCellValue(member.memberId);
        }
      }

      // Cascade Payments
      final pSheet = excel[paymentsSheet];
      for (int r = 1; r < pSheet.maxRows; r++) {
        final mIdVal = pSheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: r)).value;
        if (mIdVal?.toString() == oldMemberId) {
          pSheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: r)).value =
              TextCellValue(member.memberId);
        }
      }
    }

    // 3. Update Current Membership row
    if (membership.membershipId.isNotEmpty) {
      final msSheet = excel[membershipsSheet];
      for (int rowIndex = 1; rowIndex < msSheet.maxRows; rowIndex++) {
        final cellVal = msSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value;
        if (cellVal?.toString() == membership.membershipId) {
          final msData = membership.toMap();
          msData['MemberID'] = member.memberId;
          for (int colIndex = 0; colIndex < membershipColumns.length; colIndex++) {
            final colName = membershipColumns[colIndex];
            if (msData.containsKey(colName)) {
              final val = msData[colName];
              if (val is double) {
                msSheet.cell(CellIndex.indexByColumnRow(columnIndex: colIndex, rowIndex: rowIndex)).value =
                    DoubleCellValue(val);
              } else {
                msSheet.cell(CellIndex.indexByColumnRow(columnIndex: colIndex, rowIndex: rowIndex)).value =
                    TextCellValue(val?.toString() ?? '');
              }
            }
          }
          break;
        }
      }
    }

    await _saveWorkbook(excel);
  }

  // ─── Delete Member Cascade ───
  Future<void> deleteMemberCascade(String memberId) async {
    final excel = await _readWorkbook();

    // 1. Find photo path to clean up
    final mRows = _readSheet(excel, membersSheet, memberColumns);
    final targetM = mRows.firstWhere((r) => r['MemberID']?.toString() == memberId, orElse: () => {});
    final photoPath = targetM['PhotoPath']?.toString() ?? '';

    // Delete photo file if it exists locally
    if (photoPath.isNotEmpty && File(photoPath).existsSync()) {
      try {
        await File(photoPath).delete();
      } catch (_) {}
    }

    // 2. Remove Member row
    final mSheet = excel[membersSheet];
    for (int r = mSheet.maxRows - 1; r >= 1; r--) {
      final val = mSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: r)).value;
      if (val?.toString() == memberId) {
        mSheet.removeRow(r);
        break;
      }
    }

    // 3. Remove linked Memberships
    final msSheet = excel[membershipsSheet];
    for (int r = msSheet.maxRows - 1; r >= 1; r--) {
      final val = msSheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: r)).value; // MemberID is col 1
      if (val?.toString() == memberId) {
        msSheet.removeRow(r);
      }
    }

    // 4. Remove linked Payments
    final pSheet = excel[paymentsSheet];
    for (int r = pSheet.maxRows - 1; r >= 1; r--) {
      final val = pSheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: r)).value; // MemberID is col 1
      if (val?.toString() == memberId) {
        pSheet.removeRow(r);
      }
    }

    await _saveWorkbook(excel);
  }

  // ─── Dashboard Statistics ───
  Future<Map<String, dynamic>> getDashboardStats() async {
    final joinedMembers = await getJoinedMembers();
    final excel = await _readWorkbook();
    final payments = _readSheet(excel, paymentsSheet, paymentColumns);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final firstOfMonth = DateTime(now.year, now.month, 1);

    int activeCount = 0;
    int expiringCount = 0;
    int expiredCount = 0;
    double pendingPayments = 0;

    for (final jm in joinedMembers) {
      if (jm.status == 'Active') {
        activeCount++;
      } else if (jm.status == 'Expiring Soon') {
        expiringCount++;
      } else if (jm.status == 'Expired') {
        expiredCount++;
      }
      pendingPayments += jm.remainingAmount;
    }

    // Today's collection
    double todaysCollection = 0;
    for (final p in payments) {
      final dateStr = p['Date']?.toString() ?? '';
      if (dateStr.isEmpty) continue;
      final payDate = DateTime.tryParse(dateStr);
      if (payDate == null) continue;
      final payDay = DateTime(payDate.year, payDate.month, payDate.day);
      if (payDay.isAtSameMomentAs(today)) {
        todaysCollection += double.tryParse(p['AmountPaid']?.toString() ?? '0') ?? 0;
      }
    }

    // New members this month
    int newThisMonth = 0;
    for (final jm in joinedMembers) {
      if (jm.member.joiningDate != null && !jm.member.joiningDate!.isBefore(firstOfMonth)) {
        newThisMonth++;
      }
    }

    return {
      'totalMembers': joinedMembers.length,
      'activeMembers': activeCount,
      'expiringSoon': expiringCount,
      'expiredMembers': expiredCount,
      'todaysCollection': todaysCollection,
      'pendingPayments': pendingPayments,
      'newThisMonth': newThisMonth,
    };
  }

  // ─── Expiring Soon Members ───
  Future<List<Map<String, dynamic>>> getExpiringSoonMembers() async {
    final joinedMembers = await getJoinedMembers();
    final expiring = joinedMembers.where((jm) => jm.status == 'Expiring Soon').toList();

    final result = expiring.map((jm) {
      return {
        'name': jm.member.name,
        'memberId': jm.member.memberId,
        'daysLeft': jm.daysUntilExpiry,
        'expiryDate': jm.currentMembership?.expiryDate?.toIso8601String() ?? '',
      };
    }).toList();

    result.sort((a, b) => (a['daysLeft'] as int).compareTo(b['daysLeft'] as int));
    return result;
  }

  // ─── Get Plans With Active Member Count ───
  Future<List<JoinedPlan>> getPlansWithMemberCount() async {
    final excel = await _readWorkbook();
    final planRows = _readSheet(excel, plansSheet, planColumns);
    final membershipRows = _readSheet(excel, membershipsSheet, membershipColumns);

    final plans = planRows.map((p) => Plan.fromMap(p)).toList();
    final memberships = membershipRows.map((m) => Membership.fromMap(m)).toList();

    final result = <JoinedPlan>[];

    for (final plan in plans) {
      final count = memberships.where((ms) => ms.planId == plan.planId).length;
      result.add(JoinedPlan(plan: plan, activeMemberCount: count));
    }

    return result;
  }

  // ─── Save / Update Plan ───
  Future<String> savePlan(Plan plan) async {
    final excel = await _readWorkbook();
    final existingPlans = _readSheet(excel, plansSheet, planColumns);

    if (plan.planId.isEmpty) {
      // New Plan
      final newId = _generateNextId(existingPlans, 'PlanID', 'PLN');
      final pData = plan.toMap();
      pData['PlanID'] = newId;
      _addRowToSheet(excel, plansSheet, planColumns, pData);
      await _saveWorkbook(excel);
      return newId;
    } else {
      // Update Plan
      final sheet = excel[plansSheet];
      for (int rowIndex = 1; rowIndex < sheet.maxRows; rowIndex++) {
        final cellVal = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value;
        if (cellVal?.toString() == plan.planId) {
          final pData = plan.toMap();
          for (int colIndex = 0; colIndex < planColumns.length; colIndex++) {
            final colName = planColumns[colIndex];
            if (pData.containsKey(colName)) {
              final val = pData[colName];
              if (val is int) {
                sheet.cell(CellIndex.indexByColumnRow(columnIndex: colIndex, rowIndex: rowIndex)).value =
                    IntCellValue(val);
              } else if (val is double) {
                sheet.cell(CellIndex.indexByColumnRow(columnIndex: colIndex, rowIndex: rowIndex)).value =
                    DoubleCellValue(val);
              } else {
                sheet.cell(CellIndex.indexByColumnRow(columnIndex: colIndex, rowIndex: rowIndex)).value =
                    TextCellValue(val?.toString() ?? '');
              }
            }
          }
          break;
        }
      }
      await _saveWorkbook(excel);
      return plan.planId;
    }
  }

  // ─── Check If Plan Can Be Deleted ───
  Future<bool> canDeletePlan(String planId) async {
    final excel = await _readWorkbook();
    final membershipRows = _readSheet(excel, membershipsSheet, membershipColumns);
    final count = membershipRows.where((ms) => ms['PlanID']?.toString() == planId).length;
    return count == 0;
  }

  // ─── Delete Plan ───
  Future<bool> deletePlan(String planId) async {
    final canDelete = await canDeletePlan(planId);
    if (!canDelete) return false;

    final excel = await _readWorkbook();
    final sheet = excel[plansSheet];

    for (int rowIndex = 1; rowIndex < sheet.maxRows; rowIndex++) {
      final cellVal = sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value;
      if (cellVal?.toString() == planId) {
        sheet.removeRow(rowIndex);
        break;
      }
    }
    await _saveWorkbook(excel);
    return true;
  }

  // ─── Get Report Data ───
  Future<ReportData> getReportData({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final start = DateTime(startDate.year, startDate.month, startDate.day, 0, 0, 0);
    final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);

    final allPayments = await getAllPaymentsWithMemberDetails();
    final stats = await getDashboardStats();

    final paymentsInRange = allPayments.where((jp) {
      if (jp.payment.date == null) return false;
      return jp.payment.date!.isAfter(start.subtract(const Duration(seconds: 1))) &&
          jp.payment.date!.isBefore(end.add(const Duration(seconds: 1)));
    }).toList();

    double totalCollectionInRange = 0.0;
    for (final p in paymentsInRange) {
      totalCollectionInRange += p.payment.amountPaid;
    }

    // Compute monthly breakdown
    final Map<String, double> monthlyRevenueMap = {};
    final monthFormat = DateFormat('MMM yyyy');

    for (final p in paymentsInRange) {
      if (p.payment.date != null) {
        final key = monthFormat.format(p.payment.date!);
        monthlyRevenueMap[key] = (monthlyRevenueMap[key] ?? 0.0) + p.payment.amountPaid;
      }
    }

    return ReportData(
      totalCollectionInRange: totalCollectionInRange,
      paymentsCountInRange: paymentsInRange.length,
      monthlyRevenueMap: monthlyRevenueMap,
      paymentsInRange: paymentsInRange,
      activeMembersCount: (stats['activeMembers'] as num?)?.toInt() ?? 0,
      expiredMembersCount: (stats['expiredMembers'] as num?)?.toInt() ?? 0,
      expiringSoonCount: (stats['expiringSoon'] as num?)?.toInt() ?? 0,
      totalPendingBalance: (stats['pendingPayments'] as num?)?.toDouble() ?? 0.0,
    );
  }

  // ─── Export Generated Report to XLSX File ───
  Future<File> exportReportToExcel({
    required DateTime startDate,
    required DateTime endDate,
    required ReportData reportData,
  }) async {
    final excel = Excel.createExcel();
    final dateFormat = DateFormat('dd MMM yyyy');
    final startStr = dateFormat.format(startDate);
    final endStr = dateFormat.format(endDate);

    final settings = await getSettings();
    final gymNameTitle = settings.gymName.toUpperCase();

    // Sheet 1: Summary Report
    final summarySheet = excel['Summary Report'];
    excel.setDefaultSheet('Summary Report');

    summarySheet.appendRow([TextCellValue('$gymNameTitle - BUSINESS PERFORMANCE REPORT')]);
    summarySheet.appendRow([TextCellValue('Report Period: $startStr to $endStr')]);
    summarySheet.appendRow([TextCellValue('Generated On: ${dateFormat.format(DateTime.now())}')]);
    summarySheet.appendRow([]);

    summarySheet.appendRow([TextCellValue('METRIC'), TextCellValue('VALUE')]);
    summarySheet.appendRow([TextCellValue('Total Revenue Collected in Range'), TextCellValue('₹${reportData.totalCollectionInRange.toStringAsFixed(2)}')]);
    summarySheet.appendRow([TextCellValue('Total Transactions in Range'), TextCellValue('${reportData.paymentsCountInRange}')]);
    summarySheet.appendRow([TextCellValue('Active Members (As of Today)'), TextCellValue('${reportData.activeMembersCount}')]);
    summarySheet.appendRow([TextCellValue('Expired Members (As of Today)'), TextCellValue('${reportData.expiredMembersCount}')]);
    summarySheet.appendRow([TextCellValue('Total Pending Due Balance'), TextCellValue('₹${reportData.totalPendingBalance.toStringAsFixed(2)}')]);

    // Sheet 2: Detailed Transactions
    final paymentsSheet = excel['Transactions Detail'];
    paymentsSheet.appendRow([
      TextCellValue('Payment ID'),
      TextCellValue('Member ID'),
      TextCellValue('Member Name'),
      TextCellValue('Mobile Number'),
      TextCellValue('Plan Name'),
      TextCellValue('Date'),
      TextCellValue('Amount Paid (₹)'),
      TextCellValue('Payment Method'),
      TextCellValue('Remaining Balance (₹)'),
    ]);

    for (final p in reportData.paymentsInRange) {
      paymentsSheet.appendRow([
        TextCellValue(p.payment.paymentId),
        TextCellValue(p.member.memberId),
        TextCellValue(p.member.name),
        TextCellValue(p.member.mobileNumber),
        TextCellValue(p.planName),
        TextCellValue(p.payment.date != null ? dateFormat.format(p.payment.date!) : ''),
        DoubleCellValue(p.payment.amountPaid),
        TextCellValue(p.payment.method),
        DoubleCellValue(p.payment.remainingAmount),
      ]);
    }

    final tempDir = await getTemporaryDirectory();
    final fileName = 'Gym_Report_${startDate.day}_${startDate.month}_${startDate.year}_to_${endDate.day}_${endDate.month}_${endDate.year}.xlsx';
    final file = File('${tempDir.path}/$fileName');

    final bytes = excel.encode();
    if (bytes != null) {
      await file.writeAsBytes(bytes, flush: true);
    }

    return file;
  }

  // ─── Get Gym Settings ───
  Future<GymSettings> getSettings() async {
    final excel = await _readWorkbook();
    final rows = _readSheet(excel, settingsSheet, settingsColumns);
    if (rows.isNotEmpty) {
      return GymSettings.fromMap(rows.first);
    }
    return GymSettings.defaultSettings();
  }

  // ─── Save / Update Gym Settings ───
  Future<void> saveSettings(GymSettings settings) async {
    final excel = await _readWorkbook();
    final sheet = excel[settingsSheet];

    // If sheet has data rows (row index 1+), update row 1, else append
    final sData = settings.toMap();
    if (sheet.maxRows > 1) {
      for (int colIndex = 0; colIndex < settingsColumns.length; colIndex++) {
        final colName = settingsColumns[colIndex];
        if (sData.containsKey(colName)) {
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: colIndex, rowIndex: 1)).value =
              TextCellValue(sData[colName]?.toString() ?? '');
        }
      }
    } else {
      _addRowToSheet(excel, settingsSheet, settingsColumns, sData);
    }
    await _saveWorkbook(excel);
  }

  // ─── Update Last Backup Timestamp ───
  Future<void> updateLastBackupTimestamp() async {
    final current = await getSettings();
    final updated = GymSettings(
      gymName: current.gymName,
      logoPath: current.logoPath,
      address: current.address,
      contactNumber: current.contactNumber,
      ownerName: current.ownerName,
      lastBackupDate: DateTime.now(),
    );
    await saveSettings(updated);
  }
}
