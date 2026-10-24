class Member {
  final String memberId;
  final String name;
  final String mobileNumber;
  final String address;
  final String photoPath;
  final DateTime? joiningDate;

  Member({
    required this.memberId,
    required this.name,
    required this.mobileNumber,
    this.address = '',
    this.photoPath = '',
    this.joiningDate,
  });

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  Map<String, dynamic> toMap() => {
    'MemberID': memberId,
    'Name': name,
    'MobileNumber': mobileNumber,
    'Address': address,
    'PhotoPath': photoPath,
    'JoiningDate': joiningDate?.toIso8601String() ?? '',
  };

  factory Member.fromMap(Map<String, dynamic> map) => Member(
    memberId: map['MemberID']?.toString() ?? '',
    name: map['Name']?.toString() ?? '',
    mobileNumber: map['MobileNumber']?.toString() ?? '',
    address: map['Address']?.toString() ?? '',
    photoPath: map['PhotoPath']?.toString() ?? '',
    joiningDate: map['JoiningDate'] != null && map['JoiningDate'].toString().isNotEmpty
        ? DateTime.tryParse(map['JoiningDate'].toString())
        : null,
  );
}
