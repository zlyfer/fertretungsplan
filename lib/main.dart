import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_search_bar/flutter_search_bar.dart';

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
        canvasColor: Colors.white,
        textTheme: Typography.material2018().black,
        scaffoldBackgroundColor: Colors.white,
      ),
      darkTheme: ThemeData(
          primarySwatch: Colors.blue,
          canvasColor: Colors.black,
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
  Vertretungsplan createState() => Vertretungsplan();
}

class Vertretungsplan extends State<MyHomePage> {
  SearchBar searchBar;

  @override
  void initState() {
    super.initState();
    this.init();
  }

  AppBar buildAppBar(BuildContext context) {
    return new AppBar(
      title: Text(
        widget.title,
      ),
      // leading: IconButton(onPressed: () {}, icon: const Icon(Icons.menu)),
      actions: <Widget>[
        searchBar.getSearchAction(context),
        IconButton(
            onPressed: () {
              this.init();
            },
            icon: const Icon(Icons.refresh)),
        // PopupMenuButton<String>(
        //   onSelected: (String result) {
        //     setState(() {
        //       switch (result) {
        //         case "search":
        //           break;
        //         default:
        //           break;
        //       }
        //     });
        //   },
        //   itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        //     const PopupMenuItem<String>(
        //       value: "search",
        //       child: Text('Suche..'),
        //     ),
        //   ],
        // )
        // IconButton(
        //     onPressed: () {
        //       //
        //     },
        //     icon: const Icon(Icons.more_vert)),
      ],
    );
  }

  Vertretungsplan() {
    searchBar = new SearchBar(
        inBar: true,
        setState: setState,
        onCleared: () {
          this.search("");
        },
        onSubmitted: (searchText) {
          this.search(searchText);
        },
        onChanged: (searchText) {
          this.search(searchText);
        },
        buildDefaultAppBar: buildAppBar,
        hintText: "Suche..");
  }

  search(searchText) {
    setState(() {
      this.combination = [];
      this.combination.add(this.headerNames);
      if (searchText == "")
        this.combination.addAll(this.vplan);
      else {
        searchText = searchText.toLowerCase();
        this.combination.addAll(this
            .vplan
            .where((e) => (e["Kurs"].toLowerCase().contains(searchText) ||
                e["Wochentag"].toLowerCase().contains(searchText) ||
                e["Stunde"].toLowerCase().contains(searchText) ||
                e["Fach"].toLowerCase().contains(searchText) ||
                e["Lehrer"].toLowerCase().contains(searchText) ||
                e["Raum"].toLowerCase().contains(searchText) ||
                e["Info"].toLowerCase().contains(searchText) ||
                e["Vertretungstext"].toLowerCase().contains(searchText)))
            .toList());
      }
    });
  }

  bool loading = false;
  // Combination of header + vplan:
  List<dynamic> combination = [];
  // TODO: Option to make the order customizable:
  List<dynamic> header = [
    "Kurs",
    "Fach",
    "Stunde",
    "Info",
    "Lehrer",
    "Raum",
    "Vertretungstext",
    "Wochentag",
    // "Datum",
    // "ID"
  ];
  dynamic headerNames;
  List<dynamic> vplan;
  dynamic lastKurs;
  Color lastKursColor;
  List<dynamic> drawerList = [
    {
      "leading": Icons.table_chart,
      "title": Text('Vertretungsplan'),
      "onTap": () {
        print("hi");
      },
    },
  ];
  int selectedDay = 0;
  String firstDay = "Leer";
  String secondDay = "Leer";

  void init() {
    setState(() {
      this.loading = true;
    });
    this.combination = [];
    this.vplan = [];
    this.lastKurs = "";
    this.lastKursColor = null;
    this.fillHeaderNames();
    var response = http.get(Uri.https('api.zlyfer.net', 'vplan/latest'));
    // var response = http.get(Uri.http('192.168.0.122', 'vplan/latest'));
    response.then((data) {
      var entriesJSON = jsonDecode(data.body)['entries'];
      this.vplan.addAll(List.from(entriesJSON));
      // Test Start
      // List<dynamic> testDay = jsonDecode(jsonEncode(this.vplan));
      // testDay.forEach((e) {
      //   e["Wochentag"] = "Samstag";
      // });
      // this.vplan.addAll(testDay);
      // Test End
      String tmpDay = "";
      this.vplan.forEach((element) {
        if (tmpDay == "") {
          tmpDay = element["Wochentag"];
          setState(() {
            this.firstDay = tmpDay;
          });
        } else if (tmpDay != element["Wochentag"]) {
          setState(() {
            this.secondDay = element["Wochentag"];
          });
        }
      });
      setState(() {
        this.combination.add(this.headerNames);
        this.combination.addAll(this.vplan);
        this.loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Laden erfolgreich'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: Duration(milliseconds: 1500),
        action: SnackBarAction(
          textColor: Colors.white,
          label: 'Okay',
          onPressed: () {},
        ),
      ));
    }).catchError((error) {
      setState(() {
        this.loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Fehler beim Laden'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: Duration(milliseconds: 2500),
        action: SnackBarAction(
          textColor: Colors.white,
          label: 'Okay',
          onPressed: () {},
        ),
      ));
    });
  }

  void fillHeaderNames() {
    this.headerNames = {};
    this.header.forEach((key) {
      this.headerNames[key] = key;
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

  List<dynamic> getCombinedFiltered() {
    // TODO: Option to only filter per Day:
    return this
        .combination
        .where((element) =>
            (this.selectedDay == 0
                ? element["Wochentag"] == this.firstDay
                : element["Wochentag"] == this.secondDay) ||
            element["Wochentag"] == "Wochentag")
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: searchBar.build(context),
      // drawer: Drawer(
      //   child: ListView(
      //     padding: EdgeInsets.zero,
      //     children: <Widget>[
      //       DrawerHeader(
      //         curve: Curves.fastOutSlowIn,
      //         decoration: BoxDecoration(
      //           color: Colors.blue,
      //         ),
      //         child: Text(
      //           'Vertretungsplan',
      //           style: TextStyle(
      //             color: Colors.white,
      //             fontSize: 24,
      //           ),
      //         ),
      //       ),
      //       for (var entry in this.drawerList)
      //         ListTileTheme(
      //           iconColor: Colors.grey,
      //           child: ListTile(
      //             leading: Icon(entry["leading"]),
      //             title: entry["title"],
      //             onTap: entry["onTap"],
      //           ),
      //         ),
      //     ],
      //   ),
      // ),
      body: this.loading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  CircularProgressIndicator(),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Row(
                children: <Widget>[
                  Column(
                    children: <Widget>[
                      for (var entry in this.getCombinedFiltered())
                        Row(
                          children: <Widget>[
                            Center(
                              child: Container(
                                height: 50,
                                alignment: Alignment.center,
                                // TODO: Option to use a different column instead:
                                width: this.getColumnWidth("Kurs"),
                                color: this.getKursColor(entry["Kurs"], context),
                                padding: const EdgeInsets.all(8),
                                child: Text(
                                  entry["Kurs"],
                                  style: const TextStyle(color: Colors.white),
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
                          for (var entry in this.getCombinedFiltered())
                            Row(
                              children: <Widget>[
                                for (var key in this.header)
                                  if (key != "Kurs")
                                    Center(
                                      child: Container(
                                        height: 50,
                                        width: this.getColumnWidth(key),
                                        alignment: Alignment.center,
                                        color: this.getCellBackgroundColor(entry, key, context),
                                        padding: const EdgeInsets.all(8),
                                        child: Text(
                                          entry[key] == "N/A" ? "Keine Information" : entry[key],
                                          style: TextStyle(
                                              color:
                                                  this.getCellForegroundColor(entry, key, context),
                                              fontStyle:
                                                  entry[key] == "N/A" ? FontStyle.italic : null),
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
      bottomNavigationBar: BottomNavigationBar(
        unselectedItemColor: this.isDarkMode(context) ? Colors.white : Colors.grey.shade700,
        elevation: 16,
        currentIndex: this.selectedDay,
        onTap: (day) {
          setState(() {
            this.selectedDay = day;
          });
        },
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: this.firstDay,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: this.secondDay,
          ),
        ],
      ),
    );
  }
}
