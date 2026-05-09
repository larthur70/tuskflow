import 'package:flutter/material.dart';
import 'package:tuskflow/utils/space.dart';

class InstructionCard extends StatelessWidget {
  final String text;
  final Icon icon;
  const InstructionCard({super.key,required this.text,required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
     
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(30)
      ),
      child: Row(
        children: [
          icon,
          Space.horizontal(8),
          Expanded(child: Text(text))
        ],
      ),
    );
  }
}