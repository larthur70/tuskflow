import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tuskflow/features/tasks/models/task_model.dart';
import 'package:tuskflow/features/tasks/services/firestore_task_service.dart';
import 'package:tuskflow/features/tasks/ui/widgets/my_button.dart';
import 'package:tuskflow/features/tasks/ui/widgets/my_text_form.dart';
import 'package:tuskflow/features/tasks/ui/widgets/positioned_color_ball.dart';
import 'package:tuskflow/utils/pickTime.dart';
import 'package:tuskflow/utils/space.dart';
import 'package:validatorless/validatorless.dart';

class EditTaskPopup extends StatefulWidget {
  final TaskModel task;
  const EditTaskPopup({super.key,required this.task});

  @override
  State<EditTaskPopup> createState() => _EditTaskPopupState();
}

class _EditTaskPopupState extends State<EditTaskPopup> {

  late TextEditingController _nameEditController;
  late TextEditingController _dateEditController;
  final _key = GlobalKey<FormState>();
  

  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  @override
  void dispose() {
    // TODO: implement dispose
    
    _nameEditController.dispose();
    _dateEditController.dispose();
    super.dispose();

  }

  @override
  void initState() {
    selectedDate = widget.task.dueDate;
    String dataFormatada = DateFormat("dd/MM/yyyy").format(widget.task.dueDate);
    _dateEditController = TextEditingController(text: dataFormatada);
    _nameEditController = TextEditingController(text: widget.task.title);
    // TODO: implement initState
    super.initState();

  }

  Future<void> getDate()async{
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final due = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
    );
    final firstDate = due.isBefore(today) ? due : today;

    DateTime? colhida = await Picktime.pickDate(
      context: context,
      selectedDate: selectedDate,
      firstDate: firstDate,
    );
    if(colhida != null){
      setState(() {
        selectedDate = colhida;
        _dateEditController.text = DateFormat("dd/MM/yyyy").format(colhida);
      });
    }
    

    
  }

  
  
  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      child: Dialog(
          
          insetPadding: EdgeInsets.symmetric(horizontal: 20,vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(28)),
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 100),
            padding: EdgeInsetsGeometry.only(bottom: bottomInset > 0 ? 10 : 0),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Stack(
                
                children: [
                  Container(
                    padding: EdgeInsets.all(32),
                  
                    child: Column(
                     
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Editar tarefa",style: TextStyle(
                          color: ColorScheme.of(context).primary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold
                          ),
                          
                          ),
                          Space.vertical(40),
                          //container sugestão do tusk
                          ClipRRect(
                            borderRadius: BorderRadiusGeometry.circular(24),
                            child: Stack(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(24),
                                    color: Colors.grey.shade200
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        
                                        child: Icon(Icons.person),
                                      ),
                                      Space.horizontal(16),
                                      Expanded(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text("Sugestão do tusk",style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16
                                            ),),
                                            
                                            Text("Não deixe para amanhã o que voce pode procrastinar hoje... Brincadeira, vamos terminar isso!",style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey.shade600
                                            ),)
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                PositionedColorBall(
                                  bottom: -20,
                                  right: -10,
                                ),
                                PositionedColorBall(
                                  bottom: 0,
                                  right: -30,
                                ),
                              ],
                            ),
                          ),
                          Space.vertical(32),
                          Form(
                            key: _key,
                            child: Column(
                              children: [
                                MyTextForm(
                                  validator: Validatorless.multiple([
                                    Validatorless.required("Digite um nome para a tarefa"),
                                    Validatorless.max(50, "O nome da sua tarefa deve conter no máximo 50 caracteres")
                                  ]),
                                  titulo: "NOME DA TAREFA", controller: _nameEditController,hintText: "Edite o nome do trabalho",),
                                  Space.vertical(8),
                            MyTextForm(
                              
                              titulo: "DATA", controller: _dateEditController,onTap: getDate,hintText: "Selecione a data de entrega",isDate: true,),
                              ],
                            ),
                          ),
                          
                          Space.vertical(32),
                          
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              TextButton(onPressed: (){
                                Navigator.pop(context);
                              }, child: Text("Cancelar",style: TextStyle(fontWeight: FontWeight.bold,color: Colors.grey.shade600,fontSize: 16),)),
                              Space.horizontal(12),
                              MyButton(text: "Salvar", width: 125,padding: EdgeInsets.all(12),fontSize: 14,onTap: (){
                                if(!_key.currentState!.validate()) return;
                                context.read<FirestoreTaskService>().editTask(widget.task.id, _nameEditController.text, selectedDate!,widget.task.initialized);
                                Navigator.pop(context);
                              },)
                            ],
                          )
                      ],
                    ),
                  ),
                  Positioned(
                    top: 32,
                    right: 32,
                    child: GestureDetector(
                      onTap: (){
                        Navigator.pop(context);
                      },
                      child: CircleAvatar(
                        backgroundColor: Colors.grey.shade300,
                        child: Icon(Icons.close,color: Colors.black,),
                      ),
                    )
                    )
              
                ],
              ),
            ),
          ),
        ),
    );
  }
}