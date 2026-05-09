import 'package:flutter/material.dart';

class ControllTimerButton extends StatelessWidget {
  final Color? backgroundColor;
  final Icon icon;
  final Border? border;
  final void Function()? onTap;
  const ControllTimerButton({super.key,this.backgroundColor,required this.icon,this.border,this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
                  child: Container(
                   
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      shape: BoxShape.circle,
                      border: border
                    ),
                    child: icon,
                  ),
                );
  }
}