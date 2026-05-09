import 'package:flutter/material.dart';
import 'package:tuskflow/utils/space.dart';

class Tela1 extends StatelessWidget {
  const Tela1({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16)
              ),
              child: Image.asset("assets/images/tusk_images/Geracao_de_Video_Sem_Sorriso-ezgif.com-video-to-gif-converter.gif",height: 250,)),
            Space.vertical(40),
            Text("Eu sou o Tusk 🐘",style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              
            ),),
            Space.vertical(24),
            Text("A parte mais difícil é começar, e eu vou te ajudar com isso",style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700
            ),
            textAlign: TextAlign.center,
            ),
            Space.vertical(24),
            Text("Somente 5 minutos é o suficiente para começar",style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
              fontSize: 14
            ),)
          ],
        ),
      ),
    );
  }
}