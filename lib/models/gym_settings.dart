class GymSettings {
  final String gymName;
  final String logoPath;
  final String address;
  final String contactNumber;
  final String ownerName;
  final DateTime? lastBackupDate;

  GymSettings({
    required this.gymName,
    this.logoPath = '',
    this.address = '',
    this.contactNumber = '',
    this.ownerName = '',
    this.lastBackupDate,
  });

  factory GymSettings.defaultSettings() {
    return GymSettings(
      gymName: 'Indian Fitness Gym',
      address: 'Main Street, Gym Plaza',
      contactNumber: '9876543210',
      ownerName: 'Gym Owner',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'GymName': gymName,
      'LogoPath': logoPath,
      'Address': address,
      'ContactNumber': contactNumber,
      'OwnerName': ownerName,
      'LastBackupDate': lastBackupDate != null ? lastBackupDate!.toIso8601String() : '',
    };
  }

  factory GymSettings.fromMap(Map<String, dynamic> map) {
    return GymSettings(
      gymName: map['GymName']?.toString().isNotEmpty == true
          ? map['GymName'].toString()
          : 'Indian Fitness Gym',
      logoPath: map['LogoPath']?.toString() ?? '',
      address: map['Address']?.toString() ?? '',
      contactNumber: map['ContactNumber']?.toString() ?? '',
      ownerName: map['OwnerName']?.toString() ?? '',
      lastBackupDate: map['LastBackupDate']?.toString().isNotEmpty == true
          ? DateTime.tryParse(map['LastBackupDate'].toString())
          : null,
    );
  }
}
