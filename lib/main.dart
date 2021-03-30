import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vertretungsplan',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: Typography.material2018().black,
        scaffoldBackgroundColor: Colors.white,
      ),
      darkTheme: ThemeData(
          primarySwatch: Colors.blue,
          textTheme: Typography.material2018().white,
          scaffoldBackgroundColor: Colors.black),
      home: MyHomePage(title: 'Vertretungsplan'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // Combination of header + vplan:
  List<dynamic> combination = [];
  List<dynamic> header = [
    "Kurs",
    "Wochentag",
    "Stunde",
    "Fach",
    "Lehrer",
    "Raum",
    "Info",
    "Vertretungstext",
    // "Datum",
    // "ID"
  ];
  List<dynamic> vplan;
  dynamic lastKurs;
  Color lastKursColor;

  void init() {
    this.combination = [];
    this.vplan = [];
    this.lastKurs = "";
    this.lastKursColor = null;
    dynamic headerNames = {};
    this.header.forEach((key) => {headerNames[key] = key});
    var response = http.get(Uri.https('api.zlyfer.net', 'vplan/latest'));
    // var response = http.get(Uri.http('192.168.0.122', 'vplan/latest'));
    response.then((data) {
      var entriesJSON = jsonDecode(data.body)['entries'];
      this.vplan.addAll(List.from(entriesJSON));
      setState(() {
        this.combination.add(headerNames);
        this.combination.addAll(this.vplan);
      });
    });
  }

  bool isDarkMode(context) {
    return MediaQuery.of(context).platformBrightness == Brightness.dark;
  }

  double getColumnWidth(var columnName) {
    switch (columnName) {
      case "Kurs":
        return 105.0;
        break;
      case "Wochentag":
        return 100.0;
        break;
      case "Stunde":
        return 70.0;
        break;
      case "Fach":
        return 80.0;
        break;
      case "Lehrer":
        return 85.0;
        break;
      case "Raum":
        return 100.0;
        break;
      case "Info":
        return 140.0;
        break;
      case "Vertretungstext":
        return 300.0;
        break;
      case "Datum":
        return 170.0;
        break;
      case "ID":
        return 50.0;
        break;
      default:
        return 100.0;
        break;
    }
  }

  Color getKursColor(var kursName, var context) {
    Color even = Colors.blue;
    Color odd = Colors.blue.shade400;
    if (kursName == "Kurs") {
      this.lastKursColor = this.lastKursColor == even ? odd : even;
      return even;
    }
    if (this.lastKurs != kursName) {
      this.lastKursColor = this.lastKursColor == even ? odd : even;
      this.lastKurs = kursName;
      return this.lastKursColor;
    } else
      return this.lastKursColor;
  }

  Color getCellBackgroundColor(var entry, var key, var context) {
    if (this.combination.indexOf(entry) == 0)
      return Colors.blue.shade400;
    else if (entry[key] == "Entfall")
      return Colors.red.shade400;
    else
      return null;
  }

  Color getCellForegroundColor(var entry, var key, var context) {
    if (this.header.contains(entry[key]))
      return Colors.white;
    else if (entry[key] == "Entfall")
      return Colors.white;
    else
      return this.isDarkMode(context) ? Colors.white : Colors.grey.shade600;
  }

  @override
  void initState() {
    super.initState();
    this.init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
        ),
      ),
      body: SingleChildScrollView(
        child: Row(
          children: <Widget>[
            Column(
              children: <Widget>[
                for (var entry in this.combination)
                  Row(
                    children: <Widget>[
                      Center(
                        child: Container(
                          height: 50,
                          width: this.getColumnWidth("Kurs"),
                          alignment: Alignment.center,
                          color: this.getKursColor(entry["Kurs"], context),
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            entry["Kurs"],
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            Flexible(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    for (var entry in this.combination)
                      Row(
                        children: <Widget>[
                          for (var key in this.header)
                            if (key != "Kurs")
                              Center(
                                child: Container(
                                  height: 50,
                                  width: this.getColumnWidth(key),
                                  alignment: Alignment.center,
                                  color: this.getCellBackgroundColor(
                                      entry, key, context),
                                  padding: const EdgeInsets.all(8),
                                  child: Text(
                                    entry[key] == "N/A"
                                        ? "Keine Information"
                                        : entry[key],
                                    style: TextStyle(
                                        color: this.getCellForegroundColor(
                                            entry, key, context),
                                        fontStyle: entry[key] == "N/A"
                                            ? FontStyle.italic
                                            : null),
                                  ),
                                ),
                              ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: this.init,
        tooltip: 'Aktualisieren',
        child: Icon(Icons.refresh),
      ),
    );
  }
}
