import 'package:flutter/material.dart';
import 'package:tuskflow/utils/space.dart';

class MyTextForm extends StatelessWidget {
  final String titulo;
  final String? hintText;
  final bool isDate;
  final void Function()? onTap;
  final TextEditingController controller;

  final String? Function(String?)? validator;
  final IconData? icon;
  const MyTextForm({
    super.key,
    required this.titulo,
  
    this.hintText,
    this.isDate = false,
    this.icon,required this.controller,
    this.onTap,
    this.validator
    });

  

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo,style: TextStyle(fontWeight: FontWeight.bold,fontSize: 16),),
        Space.vertical(8),
        TextFormField(
       
          validator: validator,
          readOnly: isDate,
          controller: controller,
          onTap: onTap,
          decoration: InputDecoration(
            filled: true,
            
            fillColor: Color(0xFFeef1f4),
            hintText: hintText,
            suffixIcon: Icon(icon,color: colorScheme.primary,),
            hintStyle: TextStyle(color: Colors.grey.shade500),
            border: OutlineInputBorder(
              borderSide: BorderSide.none,
              borderRadius: BorderRadius.circular(30)
            )
          ),
        )
      ],
    );
  }
}