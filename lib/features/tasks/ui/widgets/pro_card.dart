import 'package:flutter/material.dart';
import 'package:tuskflow/utils/space.dart';

class ProCard extends StatelessWidget {
  const ProCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
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
              );
  }
}