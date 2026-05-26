import 'package:flutter/material.dart';
import 'package:tuskflow/core/widgets/text_card.dart';
import 'package:tuskflow/features/onboarding/widgets/instruction_cards.dart';
import 'package:tuskflow/utils/space.dart';

class Tela3 extends StatelessWidget {
  const Tela3({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Viu como é fácil",style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold
          ),),
          Space.vertical(12),
          Text(
            "5 minutos é o que você precisa para vencer a procrastinação",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600
            ),
          ),
          
          TextCard(
            top: 10,
            right: 0,
            margin: 70,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 60),
                  child: Text(
                    'Esse é um exemplo de tarefa ou trabalho que você pode criar',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
                Space.vertical(16),
                Container(
                  decoration: BoxDecoration(
                    
                    borderRadius: BorderRadius.circular(16)
                  ),
                  child: Image.asset("assets/images/cardimage.png",)),
                
                
              ],
            ),
          ),
          Space.vertical(22),
          InstructionCard(text: "Deslize para a esquerda para concluir a tarefa",icon: Icon(Icons.swipe_left_outlined,color: Colors.green,)),
          Space.vertical(8),
          InstructionCard(text: "Deslize para a direita para deletar a tarefa",icon: Icon(Icons.swipe_right_outlined,color: Colors.red,)),
          Space.vertical(8),
          InstructionCard(text: "Pressione e segure para editar a tarefa",icon: Icon(Icons.touch_app_outlined,color: Colors.blue,)),
        ],
      ),
    );
  }
}
