import 'package:flutter/material.dart';
import 'package:tuskflow/utils/space.dart';

class CongratsCard extends StatelessWidget {
  final Icon icon;
  final String title;
  final String subtitle;
  final Border border;
  final double titleFontSize;
  final double subtitleFontSize;

  const CongratsCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.border,
    this.titleFontSize = 13,
    this.subtitleFontSize = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
                height: 150,
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            border: border,
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20)
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              icon,
                              Space.vertical(8),
                              Text(
                                title,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: titleFontSize,
                                  fontWeight: FontWeight.w600,
                                  height: 1.2,
                                ),
                                maxLines: 3,
                              ),
                              Space.vertical(4),
                              Text(
                                subtitle,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: subtitleFontSize,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
    );
  }
}