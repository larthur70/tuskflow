import 'package:flutter/material.dart';

class WhiteContainer extends StatelessWidget {
  final Widget child;
  final double? height;
  final BoxBorder? border;
  const WhiteContainer({super.key,required this.child,this.height,this.border});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: border,
        color: Colors.white,
        borderRadius: BorderRadius.circular(35)
      ),
      child: child,
    );
  }
}