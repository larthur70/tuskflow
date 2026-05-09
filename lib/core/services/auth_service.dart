import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final auth = FirebaseAuth.instance;

  Future<void> signIn()async{
    try{
      await auth.signInAnonymously();
      print("sign in feito com sucesso");
    } catch (e){
      print("erro no login silencioso $e");
    }
  }

  Future<void> logOut()async{
    try{
      auth.signOut();
      print("logou feito!");
    } catch (e) {
      print(e);
    }
  }

  Future<void> setDisplayName(String name)async{
    auth.currentUser?.updateDisplayName(name);
  }
}