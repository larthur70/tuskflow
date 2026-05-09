

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tuskflow/features/tasks/models/task_model.dart';
import 'package:tuskflow/features/tasks/services/firestore_task_service.dart';
import 'package:tuskflow/features/tasks/ui/widgets/edit_task_popup.dart';
import 'package:tuskflow/features/tasks/ui/widgets/my_button.dart';
import 'package:tuskflow/utils/space.dart';

class TaskCard extends StatefulWidget {
  final TaskModel task;
  final bool unique;

  const TaskCard({super.key, required this.task, this.unique = false});


  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  double scale = 1.0;
  double _dragExtent = 0;
  bool isRemoving = false;
  bool _hasVibrated = false;

  String formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  Future<void> openPopup() async {
    await showGeneralDialog(
      barrierDismissible: true,
      barrierLabel: "Dialog",
      barrierColor: Colors.black54,
      transitionDuration: Duration(milliseconds: 150),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Material(color: Colors.transparent, child: EditTaskPopup(task: widget.task,)),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOutCubic,
        );
        final scale = Tween(begin: 0.8, end: 1.0).animate(curved);
        return Transform.scale(
          scale: scale.value,
          child: Opacity(opacity: animation.value, child: child),
        );
      },
      context: context,
    );
  }

  @override
  Widget build(BuildContext context) {
    final firestoreTask = context.read<FirestoreTaskService>();
    final colorScheme = ColorScheme.of(context);
    return AnimatedSize(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      
      child: isRemoving ? SizedBox(width: double.infinity,height: 0,) : GestureDetector(
        onLongPressStart: (_) {
          setState(() {
            scale = 1.08;
          });
        },
        onLongPressEnd: (_) {
          setState(() {
            scale = 1.0;
          });
          openPopup();
        },
      
        child: Dismissible(
          dismissThresholds: {
            DismissDirection.endToStart: 0.5
          },
          key: Key(widget.task.id),
          direction: DismissDirection.horizontal,
          onUpdate: (details){
            setState(() {
              _dragExtent = details.progress;
            });

            if(details.progress > 0.5 && !_hasVibrated){
              HapticFeedback.mediumImpact();
              _hasVibrated = true;
            } else if (details.progress < 0.5){
              _hasVibrated = false;
            }
          },
          confirmDismiss: (direction)async{
            
            final messenger = ScaffoldMessenger.of(context);
            final taskCopy = widget.task;

            setState(() {
              isRemoving = true;
            });
            if(direction == DismissDirection.startToEnd){
             
             
             
              await Future.delayed(Duration(milliseconds: 300));
              messenger.clearSnackBars();
              messenger.showSnackBar(
              SnackBar(
                content: Text("Tarefa concluída com sucesso! 🎉"),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
                action: SnackBarAction(label: "DESFAZER", onPressed: ()async{
                  await firestoreTask.editTaskStatus(taskCopy.id, false);
                }),
            ),
           );
              await firestoreTask.finishTask(widget.task.id);
              
              
              return true;
            } else {
    
              await Future.delayed(Duration(milliseconds: 300));
              messenger.clearSnackBars();
              messenger.showSnackBar(SnackBar(
                content: Text("Tarefa excluida"),
                backgroundColor: Colors.grey.shade900,
                action: SnackBarAction(label: "DESFAZER", textColor: Colors.blueAccent, onPressed: ()async{
                  await firestoreTask.createTask(taskCopy.title, taskCopy.dueDate,initialized: taskCopy.initialized);
                }),
                ));
              await firestoreTask.deleteTask(widget.task.id);

              
              return true;
            }
          },
          
          background: Container(
            padding: EdgeInsets.symmetric(horizontal: 20),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(16)
            ),
            child: Icon(Icons.check_circle_outline,color: Colors.white,size: 32,),
          ),
          secondaryBackground: Container(
            padding: EdgeInsets.symmetric(horizontal: 20),
            alignment: Alignment.centerRight,
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(16)
            ),
            child: Icon(Icons.delete,color: Colors.white,size: 32,),
          ),
        
          child: AnimatedScale(
            scale: scale,
            duration: Duration(milliseconds: 150),
            curve: Curves.easeInOut,
          
            child: _buildCardContent(colorScheme)
          ),
        ),
      ),
    );
  }

  Widget _buildCardContent(ColorScheme colorScheme){
    return Stack(
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: widget.task.initialized
                        ? Border.all(width: 2, color: colorScheme.secondary)
                        : null,
                    borderRadius: BorderRadius.circular(_dragExtent > 0 ? 0 : 16),
                  ),
                  child: Column(
                    crossAxisAlignment: widget.unique
                        ? CrossAxisAlignment.center
                        : CrossAxisAlignment.start,
                    children: [
                      if (widget.unique)
                        Column(
                          children: [
                            Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.task,
                                color: colorScheme.primary,
                                size: 40,
                              ),
                            ),
                            Space.vertical(16)
                          ],
                        ),
                      Text(
                        widget.task.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: widget.unique ? 30 : 20,
                        ),
                      ),
                      Space.vertical(8),
                      Row(
                        mainAxisAlignment: widget.unique ? MainAxisAlignment.center : MainAxisAlignment.start,
                        children: [
                          Icon(Icons.calendar_month, size: 20),
                          Space.horizontal(8),
                          Text(
                            widget.unique
                                ? "VENCE EM: ${formatDate(widget.task.dueDate)}"
                                : formatDate(widget.task.dueDate),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Space.vertical(12),
                      if (widget.unique)
                        Column(
                          children: [
                            Space.vertical(20),
                            SizedBox(
                              width: double.infinity,
                              child: MyButton(
                                onTap: () {
                                  Navigator.pushNamed(context, "/timer_page",arguments: widget.task);
                                },
                              
                                text: widget.task.initialized
                                    ? "+5 min🔥"
                                    : "Começar 5 min",
                               
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 12,
                                ),
                                fontSize: 18,
                              ),
                            ),
                          ],
                        )
                      else
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: widget.unique
                            ? MainAxisAlignment.center
                            : MainAxisAlignment.spaceBetween,
                        children: [
                          if (!widget.unique)
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: widget.task.statusColor.withAlpha(50),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Text(
                                widget.task.remainingTimeText,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: widget.task.statusColor,
                                ),
                              ),
                            ),
          
                          MyButton(
                            onTap: () {
                              Navigator.pushNamed(context, "/timer_page",arguments: widget.task);
                            },
                            text: widget.task.initialized
                                ? "+5 min🔥"
                                : "Começar 5 min",
                            width: 160,
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 12,
                            ),
                            fontSize: 18,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (widget.task.initialized)
                  Positioned(
                    left: 16,
                    top: 0,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                      child: Text(
                        "INICIADA",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            );
  }
}
