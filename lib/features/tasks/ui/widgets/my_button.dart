import 'package:flutter/material.dart';

class MyButton extends StatelessWidget {
  final String text;
  final double? width;
  final EdgeInsets padding;
  final void Function()? onTap;
  final double fontSize;
  const MyButton({super.key,required this.text,this.width,this.padding = const EdgeInsets.symmetric(horizontal: 60,vertical: 16,),
  this.fontSize = 20,
  this.onTap
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
            
            width: width,
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100),
              gradient: RadialGradient(
                center: Alignment.bottomRight,
                radius: 3,
                colors: [
                  Colors.blue,
                  Colors.blue.shade800,
                  Colors.blue.shade500
                ],
                
              )
            ),
            child: Text(text,style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
              color: Colors.white,
              
            ),textAlign: TextAlign.center,),
          ),
    );
  }
}