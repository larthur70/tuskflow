import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:tuskflow/features/notifications/notification_service.dart';
import 'package:tuskflow/features/pro_analitcs/analitcs_page.dart';
import 'package:tuskflow/features/sessions/services/timer_persistence_service.dart';
import 'package:tuskflow/features/tasks/models/task_model.dart';
import 'package:tuskflow/features/tasks/services/firestore_task_service.dart';
import 'package:tuskflow/features/tasks/ui/task_list.dart';





class HomePage extends StatefulWidget {
  
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  Future<void> _checkActiveSession()async{
    final persistence = TimerPersistenceService();
    final sessionData = await persistence.getActiveSession();

    if(sessionData != null){
      final String taskId = sessionData['taskId'];
      TaskModel? task = await context.read<FirestoreTaskService>().getTaskById(taskId);

      if (mounted){
        Navigator.pushNamed(context, "/timer_page",arguments: task);
      }
    } 
     
    
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _checkActiveSession();
    final user = FirebaseAuth.instance.currentUser;
    if(user != null){
      NotificationService().uploadFcmToken(user.uid);
      
    }
   verBundleId();
  }

  verBundleId()async{
     final info = await PackageInfo.fromPlatform();
    print(info.packageName);
  }

  @override
  Widget build(BuildContext context) {

    final colorScheme = ColorScheme.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        actionsPadding: EdgeInsets.only(right: 16),
        actions: [
          SizedBox(
            width: 30,
            height: 30,
            child: GestureDetector(
              onTap: (){
                Navigator.pushNamed(context, "/profile_page");
              },
              child: Icon(Icons.person_outline_rounded,size: 35,),
            ),
          )
        ],
        centerTitle: false,
        title: Text("TuskFlow",style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 28
        ),),
        backgroundColor: Colors.white,
        foregroundColor: colorScheme.primary,
      ),

      body: PageView(
        controller: _pageController,
        onPageChanged: (index){
          setState(() {
            _selectedIndex = index;
          });
        },
        children: [
          TaskList(),
          AnaliticsPage()
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(onPressed: (){
        Navigator.pushNamed(context, "/create_task");
      },backgroundColor: colorScheme.primary,shape: CircleBorder(),child: Icon(Icons.add),),
      bottomNavigationBar: BottomAppBar(
        padding: EdgeInsets.zero,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        clipBehavior: Clip.antiAlias,
        child: BottomNavigationBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          currentIndex: _selectedIndex,
          onTap: (index){
            _pageController.animateToPage(index, duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
          },
          items: [
          BottomNavigationBarItem(icon: Icon(Icons.list_alt),label: 'Lista de tarefas'),
          BottomNavigationBarItem(icon: Icon(Icons.insights),label: 'Progresso')
        ]),
      ),
    );
  }
}