import 'package:flutter/material.dart';
import 'package:tuskflow/features/tasks/ui/widgets/manual_creation.dart';
import 'package:tuskflow/utils/space.dart';

class Tela2 extends StatelessWidget {
  final TextEditingController dateController;
  final TextEditingController titleController;
  final Function(DateTime?) onDateSelected;
  final GlobalKey formKey;

  const Tela2({super.key,required this.formKey,required this.dateController,required this.titleController,required this.onDateSelected});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Color(0xff9ed9ff)
            ),
            child: Icon(Icons.hourglass_empty,color: colorScheme.secondary,size: 40,),),
            Space.vertical(16),
            Text("O que você está procrastinando?",style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 32
            ),),
            Space.vertical(16),
            Text('"Crie sua primeira tarefa e começe por 5 minutos para quebrar a procrastinação"',style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.grey.shade600
            ),),
            Space.vertical(32),
            ManualCreation(titleController: titleController,dateController: dateController,formKey: formKey,onDateSelected: onDateSelected),
            Space.vertical(24),
           
        ],
      ),
    );
  }
}