import 'package:flutter/material.dart';

class TitleCard extends StatelessWidget {
  final String text;
  const TitleCard({super.key,required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(text,style: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.bold,
    
    ),);
  }
}