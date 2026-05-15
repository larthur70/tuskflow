class UserModel {
  final int earlyStartsCount;
  final bool interestedInPro;

  UserModel({
    required this.earlyStartsCount,
    required this.interestedInPro,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      earlyStartsCount: (map['earlyStartsCount'] as num?)?.toInt() ?? 0,
      interestedInPro: (map['interestedInPro'] as bool?) ?? false,
    );
  }
}
