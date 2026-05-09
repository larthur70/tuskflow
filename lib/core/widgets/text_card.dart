import 'package:flutter/material.dart';

class TextCard extends StatelessWidget {
  final Widget child;
  final double margin;
  final double top;
  final double right;
  const TextCard({super.key,required this.child,this.margin = 40,required this.top,required this.right});

  @override
  Widget build(BuildContext context) {
    return Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    margin: EdgeInsets.only(top: margin),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(20),
                    ),

                    child: child
                  ),
                  Positioned(
                    top: top,
                    right: right,
                    child: Image.asset(
                      "assets/images/tusk_images/tusk_container.png",
                      height: 100,
                    ),
                  ),
                ],
              );
  }
}