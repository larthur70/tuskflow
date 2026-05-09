import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tuskflow/core/services/auth_service.dart';
import 'package:tuskflow/features/tasks/ui/widgets/my_filled_button.dart';
import 'package:tuskflow/utils/space.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(22),
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
              Text(user?.displayName ?? "Estudante",style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold
              ),),
              Text("Faça login para ver seu e-mail",style: TextStyle(color: Colors.grey.shade600,fontSize: 16),),
              Space.vertical(32),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  //color: Colors.red,
                  borderRadius: BorderRadius.circular(16),
                  image: DecorationImage(image: AssetImage("assets/images/background_container_pro.png"))
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          
                          padding: EdgeInsets.symmetric(horizontal: 12,vertical: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            color: Color(0xFF3B82F6)
                          ),
                          child: Text("PRO",style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Colors.white
                          ),),
                        ),
                        Space.horizontal(12),
                        Text("Tusk unlimited",style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900
                        ),)
                      ],
                    ),
                    Space.vertical(16),
                    Text("Trefas ilimitadas e o Tusk\nfica ainda mais engraçado",style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white
                    ),),
                    Space.vertical(16),
                    ElevatedButton(onPressed: (){}, child: Text("Assinar agora",style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: Colors.blueAccent
                    ),))
                  ],
                ),
              ),
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
              )
            ],
          ),
        ),
      ),
    );
  }
}