import 'dart:async';

import 'package:flutter/material.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tuskflow/features/notifications/notification_service.dart';
import 'package:tuskflow/features/onboarding/controllers/onboarding_controller.dart';
import 'package:tuskflow/features/onboarding/ui/tela1.dart';
import 'package:tuskflow/features/onboarding/ui/tela2.dart';
import 'package:tuskflow/utils/space.dart';

class OnBoardingPage extends StatefulWidget {
  const OnBoardingPage({super.key});

  @override
  State<OnBoardingPage> createState() => _OnBoardingPageState();
}

class _OnBoardingPageState extends State<OnBoardingPage> {
  final formKey = GlobalKey<FormState>();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController titleController = TextEditingController();
  DateTime? dueDate;
  
  int currentPage = 0;
  final PageController _controller = PageController();
 

  @override
  void dispose() {
    // TODO: implement dispose
    _controller.dispose();
    dateController.dispose();
    titleController.dispose();
    super.dispose();
    
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
   
  }

  Future<void> exitOnboarding(bool allFlux)async{
    final title = titleController.text;
    final overlay = context.loaderOverlay;

    if(allFlux && dueDate == null) return;
    
    overlay.show();
    try {
      await context.read<OnboardingController>().initializeUser(
        completedOnboarding: allFlux,
        title: title,
        dueDate: dueDate,
      );

      final String? uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        unawaited(NotificationService.instance.uploadFcmToken(uid));
      }
      // AuthWrapper already switches to HomePage after signInAnonymously().
    } catch (err) {
      print("erro no onboarding $err");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível concluir: $err')),
        );
      }
    } finally {
      // Must hide even when unmounted: sign-in rebuilds AuthWrapper and
      // disposes this page while the GlobalLoaderOverlay is still visible.
      overlay.hide();
    }
    
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final colorScheme = ColorScheme.of(context);
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text("TuskFlow",style: TextStyle(color: colorScheme.secondary,fontWeight: FontWeight.bold),),
        actions: [
          IconButton(onPressed: ()async{
            await exitOnboarding(false);
           
          }, icon: Icon(Icons.close,color: colorScheme.secondary,))
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: screenHeight * 0.65,
                child: PageView(
                  onPageChanged: (index) {
                    setState(() {
                      currentPage = index;
                    });
                  },
                  controller: _controller,
                  children: [
                    Tela1(),
                    Tela2(formKey: formKey,dateController: dateController,titleController: titleController,onDateSelected: (selectedDate){
                      dueDate = selectedDate;
                    },),
                   
                  ],
                ),
              ),
              
              SizedBox(
                width: double.infinity,
                child: FilledButton(onPressed: (){
                  if(currentPage == 1){
                    final validate = formKey.currentState!.validate();
                    if(!validate) return;
                
                    exitOnboarding(true);
                    
                    return;
                    
                  }
                  _controller.nextPage(duration: Duration(milliseconds: 200), curve: Curves.easeInOut);
                },
                style: ButtonStyle(
                  padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 24,vertical: 12))
                ), 
                child: currentPage == 0 ? 
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text("Vamos Começar",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 18),),
                    Space.horizontal(4),
                    Icon(Icons.keyboard_arrow_right,size: 24,)
                  ],
                ) : Text("Criar tarefa",style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18
                ),)),
              ),
              Space.vertical(12),
              SmoothPageIndicator(controller: _controller, count: 2,effect: ExpandingDotsEffect(),),
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom > 0 ? 50 : 20,)
            ],
          ),
        ),
      ),
    );
  }
}