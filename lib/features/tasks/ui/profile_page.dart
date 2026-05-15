import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tuskflow/core/services/auth_service.dart';
import 'package:tuskflow/features/tasks/ui/widgets/my_filled_button.dart';
import 'package:tuskflow/utils/space.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  static final Uri _suggestionEmailUri = Uri(
    scheme: 'mailto',
    path: 'luizarthurbolzani@gmail.com',
    queryParameters: {'subject': 'Sugestão TuksFlow'},
  );

  Future<void> _openSuggestionEmail(BuildContext context) async {
    if (!await launchUrl(_suggestionEmailUri)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o e-mail.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthService>().auth.currentUser;
    final colorScheme = ColorScheme.of(context);
    return Scaffold(
      appBar: AppBar(
        actionsPadding: EdgeInsets.only(right: 16),
        centerTitle: false,
        title: Text("Perfil",style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 28
        ),),
        backgroundColor: Colors.white,
        foregroundColor: colorScheme.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
              // SizedBox(
              //   width: 100,
              //   height: 100,
              //   child: CircleAvatar(
                  
              //     child: Icon(Icons.person,size: 50,),
              //   ),
              // ),
              Space.vertical(16),
              Text("Olá, ${user?.displayName ?? "Estudante"}",style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold
              ),),
              Text("Faça login para ver seu e-mail",style: TextStyle(color: Colors.grey.shade600,fontSize: 16),),
              Space.vertical(32),
              
              Space.vertical(32),
              MyFilledButton(backgroundColor: Colors.black,svgPath: "assets/images/apple_white.svg",text: "Logar com a apple",textColor: Colors.white,),
              Space.vertical(16),
              MyFilledButton(backgroundColor: Colors.white,svgPath: "assets/images/google.svg",text: "Logar com Google",),
              Space.vertical(24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("AÇÕES DA CONTA"),
                  Space.vertical(8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(16)
                    ),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: (){
                            context.read<AuthService>().logOut();
                          },
                          child: ListTile(
                            leading: Icon(Icons.restore),
                            title: Text("Restaurar compra"),
                            trailing: Icon(Icons.arrow_right),
                          ),
                        )
                      ],
                    ),
                  )
                ],
              ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => _openSuggestionEmail(context),
                child: const Text(
                  'Envie uma sugestão para melhorar o app',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}