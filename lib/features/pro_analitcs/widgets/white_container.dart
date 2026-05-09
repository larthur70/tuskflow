import 'package:flutter/material.dart';

class WhiteContainer extends StatelessWidget {
  final Widget child;
  final double? height;
  const WhiteContainer({super.key,required this.child,this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16)
      ),
      child: child,
    );
  }
}