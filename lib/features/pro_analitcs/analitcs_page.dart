import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';
import 'package:tuskflow/features/pro_analitcs/widgets/title_card.dart';
import 'package:tuskflow/features/pro_analitcs/widgets/white_container.dart';
import 'package:tuskflow/utils/space.dart';

class AnaliticsPage extends StatelessWidget {
  const AnaliticsPage({super.key});

  BarChartGroupData _criarBarra(int x,double y, {required bool isDestaque}){
    return BarChartGroupData(x: x,barRods: [
      BarChartRodData(toY: y,
      color: isDestaque ? Colors.blue : Colors.blueGrey,
      width: 40,
      
      borderRadius: BorderRadius.circular(4)
      )
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    return 
      Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Seu Progresso",style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold
                ),),
                Space.vertical(12),
                Text("Veja como seus 5 minutos estão combatendo a procrastinação",style: TextStyle(fontSize: 20),),
                Space.vertical(32),
                Container(
                  padding: EdgeInsets.all(22),
                  
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: colorScheme.secondary  
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 150,
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          color: Colors.blue.shade500
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.local_fire_department,color: Colors.white,size: 20,),
                            Space.horizontal(8),
                            Text("STREAK ATUAL",style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold,fontSize: 12),)
                          ],
                        ),
                        
                      ),
                      Space.vertical(16),
                      Text("7 dias",style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 50,
                        color: Colors.white
                      ),),
                      Text("Você está construindo consistência! Continue assim.",style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white
                      ),),
                      Space.vertical(22),
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.blue.shade600
                        ),
                        child: Icon(Icons.local_fire_department,color: Colors.white,size: 60,))
                    ],
                  ),
                ),
                Space.vertical(32),
                //heatmap
                WhiteContainer(
                  
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text("VEJA SUA CONSISTÊNCIA!",style: TextStyle(fontWeight: FontWeight.bold,),)),
                          Text("Ultimos 45 dias",style: TextStyle(color: Colors.blueAccent),)
                        ],
                      ),
                      Space.vertical(12),
                      HeatMap(
                        
                        size: 30,
                        startDate: DateTime.now().subtract(Duration(days: 45)),
                        endDate: DateTime.now(),
                        colorsets: {
                        1: Colors.blue.shade400,
                   
                        10: Colors.blue.shade700,
                      
                      },
                      colorTipCount: 2,
                      showColorTip: true,
                      colorTipSize: 18,
                      colorTipHelper: [
                        Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: Text("5 min",style: TextStyle(fontWeight: FontWeight.bold),),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: Text("10 min",style: TextStyle(fontWeight: FontWeight.bold),),
                        )
                      ],
                      colorMode: ColorMode.color,
                      defaultColor: Colors.grey[200],
                      
                      ),
                    ],
                  ),
                ),
                Space.vertical(32),
                WhiteContainer(
                  height: 200,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TitleCard(text: "SESSÕES INICIADAS ESSA SEMANA"),
                    Space.vertical(8),
                    Text("12",style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 36
                    ),),
                    Space.vertical(22),
                    Expanded(
                      child: BarChart(
                        BarChartData(
                          
                          barTouchData: BarTouchData(
                            enabled: false,
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipColor: (group) => Colors.transparent,
                              tooltipPadding: EdgeInsets.zero,
                              tooltipMargin: 8,
                              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                return BarTooltipItem(rod.toY.round().toString(), TextStyle(
                                  color: Colors.blueGrey,
                                  fontWeight: FontWeight.bold
                                ));
                              },
                            ),
                            
                          ),
                          titlesData: FlTitlesData(
                            show: false
                          ),
                          barGroups: [
                            _criarBarra(0, 5, isDestaque: false),
                            _criarBarra(1, 8, isDestaque: false),
                            _criarBarra(2, 4, isDestaque: false),
                            _criarBarra(3, 10, isDestaque: false),
                            _criarBarra(4, 6, isDestaque: true),
                            _criarBarra(5, 12, isDestaque: false),
                            _criarBarra(6, 10, isDestaque: true),
                          ],
                          borderData: FlBorderData(show: false),
                          gridData: FlGridData(show: false)
                        )
                      ),
                    )
                  ],
                )),
                Space.vertical(22),
                WhiteContainer(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TitleCard(text: "TAXA DE CONTINUAÇÃO"),
                    Row(
                      children: [
                        Text("68%",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 36),),
                        Space.horizontal(22),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8,vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade200,
                            borderRadius: BorderRadius.circular(30)
                          ),
                          child: Text("+12% vs ontem"),
                        )
                      ],
                    ),
                    Space.vertical(16),
                    LinearProgressIndicator(
                      value: 0.68,
                      minHeight: 16,
                      borderRadius: BorderRadius.circular(16),
                      backgroundColor: Colors.grey.shade300,
                      color: Colors.blue,
                    ),
                    Space.vertical(12),
                    Text('"Você continuou além dos 5 min em 68% das vezes"')
                  ],
                )),
                Space.vertical(22),
                WhiteContainer(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TitleCard(text: "TEMPO TOTAL FOCADO"),
                    Space.vertical(12),
                    Row(
                     
                      children: [
                        Text("2h 35min",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 36),),
                        Space.horizontal(4),
                        Padding(
                          padding: const EdgeInsets.only(top: 14),
                          child: Text("esta semana",style: TextStyle(fontSize: 16),),
                        )
                      ],
                    )
                  ],
                ))
              ],
            ),
          ),
        ),
      );
    
  }
}