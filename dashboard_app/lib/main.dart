import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'package:fl_chart/fl_chart.dart';

void main() {
  runApp(const MyApp());
}

class StepData {
  final DateTime date;
  final int steps;

  StepData(this.date, this.steps);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Dashboard App',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  } 
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
    List<HealthDataPoint> _healthDataList = [];
    final Health _health = Health();

    Future<void> fetchStepData() async {
    // Define the types of data you want to access
    final types = [HealthDataType.STEPS];

    // Request authorization to access the data types
    bool requested = await _health.requestAuthorization(types);

    if (requested) {
      // Define the time range for data retrieval
      DateTime endDate = DateTime.now();
      DateTime startDate = endDate.subtract(const Duration(days: 7));

      List<HealthDataPoint> healthData = await _health.getHealthDataFromTypes(
        types: types,
        startTime: startDate,
        endTime: endDate,
      );
      

      // Remove duplicates (if any)
      _healthDataList = _health.removeDuplicates(healthData);

      // Update the UI
      setState(() {});
    } else {
      // Handle the case when permissions are not granted
      debugPrint("Authorization not granted");

    }
  }
    @override
  void initState() {
    super.initState();
    fetchStepData();
  }

  List<StepData> _createStepData() {
  Map<DateTime, int> stepsPerDay = {};

  for (var dataPoint in _healthDataList) {
    // Round the date to remove time components
    DateTime date = DateTime(
      dataPoint.dateFrom.year,
      dataPoint.dateFrom.month,
      dataPoint.dateFrom.day,
    );

    // The value is a double; convert it to int
    int steps = (dataPoint.value as double).toInt();

    // Aggregate steps per day
    stepsPerDay.update(
      date,
      (existingSteps) => existingSteps + steps,
      ifAbsent: () => steps,
    );
  }

  // Convert the map to a list of StepData
  List<StepData> stepDataList = stepsPerDay.entries
      .map((entry) => StepData(entry.key, entry.value))
      .toList();

  // Sort the list by date
  stepDataList.sort((a, b) => a.date.compareTo(b.date));

  return stepDataList;
}

Widget _buildChart() {
  List<StepData> data = _createStepData();

  // Handle the case where there's no data
  if (data.isEmpty) {
    return const Text(
      'No step data available for the selected period.',
      style: TextStyle(fontSize: 16),
    );
  }

  // Create bar groups from the step data
  List<BarChartGroupData> barGroups = data.asMap().entries.map((entry) {
    int index = entry.key;
    StepData stepData = entry.value;

    return BarChartGroupData(
      x: index,
      barRods: [
        BarChartRodData(
          toY: stepData.steps.toDouble(),
          color: Colors.blue,
          width: 16,
          borderRadius: BorderRadius.circular(4),
        ),


      ],
      showingTooltipIndicators: [0],
    );
  }).toList();

  return BarChart(
    BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: data.map((e) => e.steps).reduce((a, b) => a > b ? a : b).toDouble() + 1000, // Adds padding
      barTouchData: BarTouchData(
        enabled: true,
        touchTooltipData: BarTouchTooltipData(
          
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            String date = '${data[group.x].date.month}/${data[group.x].date.day}';
            return BarTooltipItem(
              '$date\n',
             const  TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              children: <TextSpan>[
                TextSpan(
                  text: '${rod.toY.toInt()} steps',
                  style: const TextStyle(
                    color: Colors.yellow,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            );
          },
        ),
      ),
      titlesData: FlTitlesData(
  show: true,
  bottomTitles: AxisTitles(
    sideTitles: SideTitles(
      showTitles: true,
      getTitlesWidget: (double value, TitleMeta meta) {
        int index = value.toInt();
        if (index >= 0 && index < data.length) {
          DateTime date = data[index].date;
          return Text(
            '${date.month}/${date.day}',
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          );
        }
        return const SizedBox.shrink();
      },
      reservedSize: 32,
      interval: 1,
    ),
  ),
  leftTitles: AxisTitles(
    sideTitles: SideTitles(
      showTitles: true,
      getTitlesWidget: (double value, TitleMeta meta) {
        if (value % 1000 == 0) {
          return Text(
            '${value ~/ 1000}k',
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          );
        }
        return const SizedBox.shrink();
      },
      reservedSize: 40,
      interval: 1000,
    ),
  ),
),

      borderData: FlBorderData(
        show: false,
      ),
      barGroups: barGroups,
    ),
  );
}

DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
DateTime _endDate = DateTime.now();

Future<void> _selectDateRange() async {
  final DateTimeRange? picked = await showDateRangePicker(
    context: context,
    firstDate: DateTime(2020),
    lastDate: DateTime.now(),
    initialDateRange: DateTimeRange(
      start: _startDate,
      end: _endDate,
    ),
  );

  if (picked != null && picked != DateTimeRange(start: _startDate, end: _endDate)) {
    setState(() {
      _startDate = picked.start;
      _endDate = picked.end;
      fetchStepData(); // Fetch new data based on selected range
    });
  }
}

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Step Count Bar Chart'),
      actions: [
        IconButton(
          icon: const Icon(Icons.date_range),
          onPressed: _selectDateRange,
          tooltip: 'Select Date Range',
    ),
  ],
    ),
    body: Center(
      child: _healthDataList.isEmpty
          ? const CircularProgressIndicator()
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildChart(),
            ),
    ),
  );
}

}
