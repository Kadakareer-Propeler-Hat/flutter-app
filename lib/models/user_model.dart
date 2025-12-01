// lib/models/user_model.dart
class UserModel {
  final String uid;
  final String email;
  final String firstName;
  final String lastName;
  final String salarySchedule;
  final String salaryIncome;   // ← Added
  final String idImageUrl;

  UserModel({
    required this.uid,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.salarySchedule,
    required this.salaryIncome,   // ← Added
    required this.idImageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      "uid": uid,
      "email": email,
      "firstName": firstName,
      "lastName": lastName,
      "salarySchedule": salarySchedule,
      "salaryIncome": salaryIncome,   // ← Added
      "idImageUrl": idImageUrl,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map["uid"],
      email: map["email"],
      firstName: map["firstName"],
      lastName: map["lastName"],
      salarySchedule: map["salarySchedule"],
      salaryIncome: map["salaryIncome"],   // ← Added
      idImageUrl: map["idImageUrl"],
    );
  }
}
