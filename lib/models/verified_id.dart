class VerifiedID {
  final String id;
  final String extractedName;
  final String documentType;
  final String documentNumber;
  final String dateOfExpiry;
  final String dateOfBirth;
  final String personalNumber;
  final String nationality;
  final String sex;
  final String age;
  final String mrz;
  final String? documentPhotoBase64;
  final DateTime createdAt;

  VerifiedID({
    required this.id,
    required this.extractedName,
    required this.documentType,
    required this.documentNumber,
    required this.dateOfExpiry,
    required this.dateOfBirth,
    required this.personalNumber,
    required this.nationality,
    required this.sex,
    required this.age,
    required this.mrz,
    this.documentPhotoBase64,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'extractedName': extractedName,
      'documentType': documentType,
      'documentNumber': documentNumber,
      'dateOfExpiry': dateOfExpiry,
      'dateOfBirth': dateOfBirth,
      'personalNumber': personalNumber,
      'nationality': nationality,
      'sex': sex,
      'age': age,
      'mrz': mrz,
      'documentPhotoBase64': documentPhotoBase64,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory VerifiedID.fromJson(Map<String, dynamic> json) {
    return VerifiedID(
      id: json['id'],
      extractedName: json['extractedName'],
      documentType: json['documentType'],
      documentNumber: json['documentNumber'],
      dateOfExpiry: json['dateOfExpiry'],
      dateOfBirth: json['dateOfBirth'],
      personalNumber: json['personalNumber'],
      nationality: json['nationality'],
      sex: json['sex'],
      age: json['age'],
      mrz: json['mrz'],
      documentPhotoBase64: json['documentPhotoBase64'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
} 