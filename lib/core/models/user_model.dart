class UserModel {
  final int earlyStartsCount;
  final bool interestedInPro;
  final String? email;
  final String? displayName;

  UserModel({
    required this.earlyStartsCount,
    required this.interestedInPro,
    this.email,
    this.displayName,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      earlyStartsCount: (map['earlyStartsCount'] as num?)?.toInt() ?? 0,
      interestedInPro: (map['interestedInPro'] as bool?) ?? false,
      email: map['email'] as String?,
      displayName: map['displayName'] as String?,
    );
  }
}
