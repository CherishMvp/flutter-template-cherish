import 'dart:developer';

import 'package:com.cherish.mingji/components/common/cherish_appbar.dart';
import 'package:com.cherish.mingji/components/errorAndLoading/empty_result.dart';
import 'package:com.cherish.mingji/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class Frequency extends StatefulWidget {
  const Frequency({super.key});

  @override
  State<Frequency> createState() => _FrequencyState();
}

class _FrequencyState extends State<Frequency> {
  final List<Map<String, dynamic>> writingData = [];
  final List<Map<String, dynamic>> writingData2 = [];

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    final sql = SQLHelper();
    sql.countItemsByDay(null).then((value) {
      setState(() {
        writingData.addAll(value);
      });
      // log(" writingData:$writingData");
    });
    sql.countItemsByDay2(null).then((value) {
      setState(() {
        writingData2.addAll(value);
        // writingData2.add({"date": "2022-11-11:12:45:00", "count": 12});
      });
    });

    log(" writingData:$writingData2");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CherishAppbar(
        title: "统计分析",
      ),
      body: frequencyBar(writingData, writingData2),
    );
  }

  Widget frequencyBar(List<Map<String, dynamic>> writingData,
      List<Map<String, dynamic>> writingData2) {
    return SingleChildScrollView(
      child: Column(
        children: [
          WritingFrequencyChart(writingData: writingData),
          if (writingData2.isNotEmpty) PieChartFrequency(results: writingData2),
        ],
      ),
    );
  }
}

class WritingFrequencyChart extends StatefulWidget {
  final List<Map<String, dynamic>> writingData; // 每日写作次数数据
  const WritingFrequencyChart({super.key, required this.writingData});

  @override
  _WritingFrequencyChartState createState() => _WritingFrequencyChartState();
}

class _WritingFrequencyChartState extends State<WritingFrequencyChart> {
  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6),
        child: SizedBox(
          height: 220,
          child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              child: widget.writingData.isNotEmpty
                  ? Stack(children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Container(
                          width: 500, // 设置一个合适的宽度
                          child: BarChart(BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              groupsSpace: 22,
                              maxY: widget.writingData
                                      .map((e) => e['value'] as int)
                                      .reduce((a, b) => a > b ? a : b) +
                                  5,
                              barGroups: _generateBarGroups(),
                              titlesData: _buildTitlesData(),
                              gridData: FlGridData(show: false),
                              borderData: FlBorderData(show: false),
                              // barTouchData: BarTouchData(enabled: true),
                              barTouchData: BarTouchData(
                                touchTooltipData: BarTouchTooltipData(
                                  getTooltipColor: (BarChartGroupData group) =>
                                      Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withOpacity(0.9), // 设置弹出框背景色
                                  getTooltipItem:
                                      (group, groupIndex, rod, rodIndex) {
                                    // 访问 Y 坐标值
                                    final yValue = rod.toY.toInt();
                                    return BarTooltipItem(
                                      '数量：$yValue',
                                      textAlign: TextAlign.center,
                                      TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    );
                                  },
                                ),
                              ))),
                        ),
                      ),
                      // 标题
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8),
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Text('每日频率', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                    ])
                  : EmptyResult()),
        ));
  }

  // 创建每个柱状条的数据
  List<BarChartGroupData> _generateBarGroups() {
    return widget.writingData.asMap().entries.map((entry) {
      int index = entry.key;
      int value = entry.value['value'];
      // debugPrint('response data is ${entry.value['value']}  ');

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: value.toDouble(),
            color: Theme.of(context).colorScheme.primary,
            width: 18,
            borderRadius: BorderRadius.circular(6), // 圆角
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: widget.writingData
                      .map((e) => e['value'] as int)
                      .reduce((a, b) => a > b ? a : b)
                      .toDouble() +
                  3,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
            ),
          ),
        ],
      );
    }).toList();
  }

// 获取x轴名称
  String getXAxisName(int index) {
    // debugPrint('response data is ${writingData[index]['key']}  ');

    return widget.writingData[index]['key'].toString();
  }

  // 创建坐标轴标题
  FlTitlesData _buildTitlesData() {
    return FlTitlesData(
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: false,
          reservedSize: 40,
          interval: 5,
          getTitlesWidget: (value, meta) {
            return Text(
              value.toInt().toString(),
              style: TextStyle(color: Colors.black, fontSize: 14),
            );
          },
        ),
      ),
      rightTitles: AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
      topTitles: AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 40,
          getTitlesWidget: (value, meta) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Text(
                getXAxisName(value.toInt()),
                style: TextStyle(color: Colors.black, fontSize: 12),
              ),
            );
          },
        ),
      ),
    );
  }
}

class PieChartFrequency extends StatelessWidget {
  const PieChartFrequency({super.key, required this.results});
  final List<Map<String, dynamic>> results;
  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> timeCategoryCounts = _categorizeTimes(results);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6),
      child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: 260,
            minWidth: double.infinity,
          ),
          child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              child: results.isNotEmpty
                  ? Stack(
                      children: [
                        Column(
                          children: [
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                maxHeight: 240,
                                maxWidth: 300,
                              ),
                              child: Container(
                                padding: EdgeInsets.only(top: 30),
                                child: PieChart(
                                  PieChartData(
                                    sections: _getPieChartSections(
                                        timeCategoryCounts),
                                    borderData: FlBorderData(show: false),
                                    centerSpaceRadius: 40, // 中间空心的半径
                                    sectionsSpace: 0, // 各部分之间的间隔
                                  ),
                                ),
                              ),
                            ),

                            Padding(
                              padding: const EdgeInsets.only(left: 16.0),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '总数 ${results.fold<int>(0, (sum, item) => sum + (item['count'] as int))}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                                padding: const EdgeInsets.only(
                                    top: 10.0, bottom: 10, left: 16.0),
                                child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: _buildLegend(
                                        timeCategoryCounts))), // 添加图例
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 16),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text('时段分布', style: TextStyle(fontSize: 16)),
                          ),
                        ),
                      ],
                    )
                  : EmptyResult())),
    );
  }

  Widget _buildLegend(Map<String, dynamic> timeCategoryCounts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: timeCategoryCounts.entries.map((entry) {
        String category = entry.key;
        Color color = _getColor(category);
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
                margin: EdgeInsets.only(right: 8),
              ),
            ),
            Text(
              '$category ${entry.value}',
              style: TextStyle(fontSize: 16),
            ),
          ],
        );
      }).toList(),
    );
  }

  Map<String, dynamic> _categorizeTimes(List<Map<String, dynamic>> data) {
    final Map<String, dynamic> timeCategories = {
      '上午': 0,
      '下午': 0,
      '夜间': 0,
    };
    debugPrint('response data is $data');

    for (var entry in data) {
      String date = entry['date'];
      DateTime parsedDate = DateFormat('yy-MM-dd:HH:mm').parse(date);
      log("parsedDate is $parsedDate");
      int hour = parsedDate.hour;
      debugPrint('hour ${hour.toString()}');

      if (hour < 12) {
        timeCategories['上午'] = timeCategories['上午']! + entry['count'].toInt();
      } else if (hour < 18) {
        timeCategories['下午'] = timeCategories['下午']! + entry['count'].toInt();
      } else {
        timeCategories['夜间'] = timeCategories['夜间']! + entry['count'].toInt();
      }
    }
    log("timeCategories$timeCategories");
    return timeCategories;
  }

  List<PieChartSectionData> _getPieChartSections(
      Map<String, dynamic> timeCategoryCounts) {
    return timeCategoryCounts.entries.map((entry) {
      String category = entry.key;
      int count = entry.value;

      return PieChartSectionData(
        color: _getColor(category), // 根据类别选择颜色
        value: count.toDouble(),
        title:
            '${(count / results.fold<int>(0, (sum, item) => sum + (item['count'] as int)) * 100).toStringAsFixed(1)}%',
        radius: 60, // 半径
        titleStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        // borderSide: BorderSide(
        //   color: Colors.white,
        //   width: 0,
        // ),
        // 添加阴影效果
      );
    }).toList();
  }

  Color _getColor(String category) {
    switch (category) {
      case '上午':
        return Colors.blue;
      case '下午':
        return Colors.orange;
      case '夜间':
        return const Color.fromARGB(255, 137, 17, 212);
      default:
        return Colors.grey;
    }
  }
}
