class UserModel {
  final int earlyStartsCount;

  UserModel({
    required this.earlyStartsCount,
  });
  factory UserModel.fromMap(Map<String,dynamic> map){
    return UserModel(earlyStartsCount: map['earlyStartsCount']);
  }
}