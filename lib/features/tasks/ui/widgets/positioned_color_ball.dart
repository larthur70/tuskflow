import 'package:flutter/material.dart';

class PositionedColorBall extends StatelessWidget {
  final double? bottom;
  final double? right;
  final double? top;
  final double? left;
  const PositionedColorBall({super.key,this.bottom,this.right,this.left,this.top});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: bottom,
      right: right,
      top: top,
      left: left,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.blue.shade200,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
