
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tuskflow/core/services/auth_service.dart';
import 'package:tuskflow/features/onboarding/ui/onboarding_page.dart';
import 'package:tuskflow/features/tasks/ui/home_page.dart';

class AuthWrapper extends StatelessWidget {

  const AuthWrapper({super.key});

  

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    return StreamBuilder(stream: auth.auth.authStateChanges(), builder: (context,snapshot){
      if(snapshot.hasData){
        return HomePage();
      } 
      return OnBoardingPage();
    });
  }
}