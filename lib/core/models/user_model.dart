class UserModel {
  final String? email;
  final String? displayName;

  UserModel({
    this.email,
    this.displayName,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      email: map['email'] as String?,
      displayName: map['displayName'] as String?,
    );
  }
}
