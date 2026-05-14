
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:tuskflow/features/tasks/ui/widgets/my_text_form.dart';
import 'package:tuskflow/utils/pickTime.dart';
import 'package:tuskflow/utils/space.dart';
import 'package:validatorless/validatorless.dart';

class ManualCreation extends StatefulWidget {

  final GlobalKey formKey;
  final TextEditingController dateController;
  final Function(DateTime?) onDateSelected;
  final TextEditingController titleController;
  const ManualCreation({super.key, required this.dateController,required this.titleController,required this.formKey,required this.onDateSelected});

  @override
  State<ManualCreation> createState() => _ManualCreationState();
}

class _ManualCreationState extends State<ManualCreation> {
  
  

  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  Future<void> getDate()async{
    selectedDate = await Picktime.pickDate(context: context,selectedDate: selectedDate);
    widget.onDateSelected(selectedDate);
    setState(() {
      if (selectedDate != null){
        
        widget.dateController.text = "${selectedDate?.day} / ${selectedDate?.month} / ${selectedDate?.year}";
      } else {
        selectedDate = null;

         widget.dateController.clear();
      }

    });
  }

 


  
  @override
  Widget build(BuildContext context) {
   
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: Colors.white
          ),
          child: Form(
            key: widget.formKey,
            child: Column(
              children: [
                MyTextForm(
                  validator: Validatorless.multiple([
                    Validatorless.required("Digite um título para tarefa"),
                    Validatorless.max(50, "Digite no máximo 50 caracteres")
                  ]),
                  titulo: "Título da tarefa",hintText: "Ex: Trabalho de biologia",controller: widget.titleController,),
                Space.vertical(16),
                MyTextForm(
                  validator: Validatorless.required("Selecione uma data válida"),
                  titulo: "Data de entrega",icon: Icons.calendar_month,controller: widget.dateController,isDate: true,onTap: getDate,hintText: "Selecione a data de entrega",),
                Space.vertical(16),
              ],
            ),
          ),
        ),
        
        
      ],
    );
  }
}