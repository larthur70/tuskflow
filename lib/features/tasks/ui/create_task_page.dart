import 'package:flutter/material.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:provider/provider.dart';
import 'package:tuskflow/core/utils/critical_operation_timeout.dart';
import 'package:tuskflow/core/widgets/text_card.dart';
import 'package:tuskflow/features/analytics/services/analytics_service.dart';
import 'package:tuskflow/features/tasks/models/task_model.dart';
import 'package:tuskflow/features/tasks/services/firestore_task_service.dart';
import 'package:tuskflow/features/tasks/ui/widgets/manual_creation.dart';
import 'package:tuskflow/features/tasks/ui/widgets/my_button.dart';
import 'package:tuskflow/utils/space.dart';

class CreateTask extends StatefulWidget {
  const CreateTask({super.key});

  @override
  State<CreateTask> createState() => _CreateTaskState();
}

class _CreateTaskState extends State<CreateTask> {

  final formKey = GlobalKey<FormState>();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController titleController = TextEditingController();
  DateTime? dueDate;

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    dateController.dispose();
    titleController.dispose();
  }

  Future<TaskModel?> _createTask() async {
    if (!formKey.currentState!.validate()) return null;
    final taskService = context.read<FirestoreTaskService>();
    final analytics = context.read<AnalyticsService>();
    try {
      final taskId =
          await taskService.createTask(titleController.text, dueDate!);
      if (!mounted) return null;
      if (taskId == null) {
        throw Exception('Não foi possível criar a tarefa.');
      }
      final task = await taskService.getTaskById(taskId);
      if (!mounted) return null;
      if (task == null) {
        throw Exception('Tarefa criada, mas não foi possível carregá-la.');
      }
      await analytics.logTaskCreated();
      return task;
    } catch (err) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(criticalOperationErrorMessage(err))),
      );
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    
    final colorScheme = ColorScheme.of(context);
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: false,
        foregroundColor: colorScheme.primary,
        title: Text(
          "Nova tarefa",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.close),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              
              children: [
                //card de frase
        
                TextCard(
                  top: -15,
                  margin: 50,
                  right: 0,
                  child: Text(
                        '"O Tusk te ajuda a começar. Só 5 minutos já fazem diferença."',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),),
                Space.vertical(32),
                ManualCreation(
                  
                  dateController: dateController,titleController: titleController,formKey: formKey,onDateSelected: (date){
                    dueDate = date;
                  },),
                Space.vertical(32),
                MyButton(text: "Criar tarefa", width: double.infinity,onTap: ()async{
                  print("botao");
                  final validator = formKey.currentState!.validate();
                  print("validado? $validator");
                  if(!validator) return;
                  final overlay = context.loaderOverlay;
                  overlay.show();
                  try {
                    await _createTask();
                    overlay.hide();
                    if (!context.mounted) return;
                    Navigator.of(context).pop();
                  } catch (err) {
                    overlay.hide();
                  }
                  
                  
                  
                },)
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }
}
