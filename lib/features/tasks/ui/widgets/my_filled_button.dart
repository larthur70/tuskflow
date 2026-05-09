import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tuskflow/utils/space.dart';

class MyFilledButton extends StatelessWidget {
  final Color backgroundColor;
  final String svgPath;
  final String text;
  final Color textColor;
  
  const MyFilledButton({super.key,required this.backgroundColor,required this.svgPath,required this.text,this.textColor = Colors.black});

  @override
  Widget build(BuildContext context) {
    return FilledButton(
                style: ButtonStyle(
                  padding: WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 16)),
                  backgroundColor: WidgetStatePropertyAll(
                    backgroundColor
                  )
                ),
                onPressed: (){}, child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(svgPath,height: 30,),
                    Space.horizontal(8),
                    Text(text,style: TextStyle(
                      color: textColor,
                      fontSize: 16
                    ),)
                  ],
                ));
  }
}