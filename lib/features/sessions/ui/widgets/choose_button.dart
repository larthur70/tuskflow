import 'package:flutter/material.dart';
import 'package:tuskflow/utils/space.dart';

// ignore: must_be_immutable
class ChooseButton extends StatefulWidget {
  int selected;
  void Function(int value) onChanged;
  ChooseButton({super.key,required this.selected,required this.onChanged});

  @override
  State<ChooseButton> createState() => _ChooseButtonState();
}

class _ChooseButtonState extends State<ChooseButton> {
  Widget _buildSegment(int index,String text,IconData icon){
  final colorScheme = ColorScheme.of(context);
  final isSelected = widget.selected == index;
  return Expanded(child: GestureDetector(
    onTap: (){
      setState(() {
        widget.selected = index;
      });
      widget.onChanged(index);
    },
    child: Container(
      padding: EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(30)
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon,color: isSelected ? colorScheme.primary : Colors.grey,),
          Space.horizontal(6),
          Text(text,style: TextStyle(
            color: isSelected ? colorScheme.primary : Colors.grey,
            fontWeight: FontWeight.w900
          ),)
        ],
      ),
    ),
  ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedAlign(alignment: widget.selected == 0 ? Alignment.centerLeft : Alignment.centerRight,
            duration: Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Container(
                width: MediaQuery.of(context).size.width / 2 - 8,
                //margin: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30)
                ),
              ),
            ),
            ),
          ),
          Row(
            children: [
              _buildSegment(0, "IA Input", Icons.auto_awesome),
              _buildSegment(1, "Manual", Icons.edit)
            ],
          )
        ],
      )
    );
  }
}

