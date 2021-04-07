import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_search_bar/flutter_search_bar.dart';

void main() async {
  runApp(FPlan());
}

class FPlan extends StatefulWidget {
  @override
  FPlanState createState() => FPlanState();
}

class FPlanState extends State<FPlan> {
  // vplan settings
  String showView = "vplan";
  SearchBar searchBar;
  bool loading = false;
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
    // "Wochentag",
    // "Datum",
    // "ID"
  ];
  dynamic headerNames;
  List<dynamic> vplan;
  dynamic lastKurs;
  Color lastKursColor;
  int selectedDay = 0;
  String firstDay = "Leer";
  String secondDay = "Leer";
  bool autoDarkMode = false;
  bool manualDarkMode = true;
  Color primary;
  Color secondary = Colors.blue.shade400;

  AppBar buildAppBar(BuildContext context) {
    return new AppBar(
      backgroundColor: this.primary,
      title: Text(
        "Vertretungsplan",
      ),
      actions: <Widget>[
        searchBar.getSearchAction(context),
        IconButton(
            onPressed: () {
              this.init(context: context);
            },
            icon: const Icon(Icons.refresh)),
      ],
    );
  }

  FPlanState() {
    this.searchBar = new SearchBar(
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
        // TODO: Search for all activated columns:
        this.combination.addAll(this
            .vplan
            .where((e) => (e["Kurs"].toLowerCase().contains(searchText) ||
                // e["Wochentag"].toLowerCase().contains(searchText) ||
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

  loadAppPreferences() async {
    SharedPreferences appPrefs = await SharedPreferences.getInstance();
    this.manualDarkMode =
        appPrefs.containsKey("manualDarkMode") ? appPrefs.getBool("manualDarkMode") : false;
    appPrefs.setBool("manualDarkMode", this.manualDarkMode);
    this.autoDarkMode =
        appPrefs.containsKey("autoDarkMode") ? appPrefs.getBool("autoDarkMode") : false;
    appPrefs.setBool("autoDarkMode", this.autoDarkMode);
    if (appPrefs.containsKey("primary")) {
      this.primary = Colors.primaries[appPrefs.getInt("primary")];
    } else
      this.primary = Colors.blue;
    this.computeSecondary(this.primary);
  }

  setAPBool(String key, bool value) async {
    SharedPreferences appPrefs = await SharedPreferences.getInstance();
    appPrefs.setBool(key, value);
  }

  setAPString(String key, String value) async {
    SharedPreferences appPrefs = await SharedPreferences.getInstance();
    appPrefs.setString(key, value);
  }

  setAPInt(String key, int value) async {
    SharedPreferences appPrefs = await SharedPreferences.getInstance();
    appPrefs.setInt(key, value);
  }

  @override
  void initState() {
    this.init();
    this.loadAppPreferences();
    super.initState();
  }

  void init({context}) {
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
        content: Text('Laden erfolgreich', style: TextStyle(color: Colors.white)),
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
        content: Text('Fehler beim Laden', style: TextStyle(color: Colors.white)),
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

  computeSecondary(color) {
    double div = 1.2;
    this.secondary =
        color.withRed(color.red ~/ div).withGreen(color.green ~/ div).withBlue(color.blue ~/ div);
  }

  void fillHeaderNames() {
    this.headerNames = {};
    this.header.forEach((key) {
      this.headerNames[key] = key;
    });
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

  Color getKursColor(var kursName) {
    Color even = this.primary;
    Color odd = this.secondary;
    if (kursName == "Kurs") {
      this.lastKursColor = even;
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
      return this.primary;
    else if (entry[key] == "Entfall")
      return Colors.red.shade400;
    else
      return this.isDarkMode(context) ? Colors.black : Colors.white;
  }

  Color getTextColor({Color color}) {
    if (color != null)
      return color.computeLuminance() > 0.5 ? Colors.black : Colors.white;
    else
      return this.primary.computeLuminance() > 0.5 ? Colors.black : Colors.white;
  }

  List<dynamic> getCombinedFiltered() {
    // TODO: Option to only filter per Day:
    return this
        .combination
        .where((element) =>
            (this.selectedDay == 0
                ? element["Wochentag"] == this.firstDay
                : element["Wochentag"] == this.secondDay) ||
            element["Kurs"] == "Kurs")
        .toList();
  }

  var viewTranslator = {
    "vplan": {
      "appBarTitle": "Vertretungsplan",
    },
    "settings": {
      "appBarTitle": "Einstellungen",
    }
  };

  bool isDarkMode(context) {
    return this.autoDarkMode
        ? MediaQuery.of(context).platformBrightness == Brightness.dark
        : this.manualDarkMode
            ? true
            : false;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vertretungsplan',
      debugShowCheckedModeBanner: false,
      themeMode: this.autoDarkMode
          ? ThemeMode.system
          : this.manualDarkMode
              ? ThemeMode.dark
              : ThemeMode.light,
      theme: ThemeData(
        primarySwatch: this.primary,
        canvasColor: Colors.white,
        textTheme: Typography.material2018().black,
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
      ),
      darkTheme: ThemeData(
        primarySwatch: this.primary,
        canvasColor: Colors.black,
        textTheme: Typography.material2018().white,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
      ),
      home: Builder(
        builder: (context) => Scaffold(
          appBar: this.showView == "vplan"
              ? this.searchBar.build(context)
              : AppBar(
                  backgroundColor: this.primary,
                  title: Text(
                    this.viewTranslator[this.showView]["appBarTitle"],
                  ),
                ),
          drawer: Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                DrawerHeader(
                  margin: EdgeInsets.zero,
                  curve: Curves.fastOutSlowIn,
                  decoration: BoxDecoration(
                    color: this.primary,
                  ),
                  child: Text(
                    "Fertretungsplan",
                    style: TextStyle(
                      color: this.getTextColor(),
                      fontSize: 24,
                    ),
                  ),
                ),
                ListTileTheme(
                  child: ListTile(
                    leading: Icon(
                      Icons.table_chart,
                      color: this.showView == "vplan" ? this.secondary : Colors.grey,
                    ),
                    title: Text("Vertretungsplan",
                        style: TextStyle(color: this.showView == "vplan" ? this.secondary : null)),
                    onTap: () {
                      setState(() {
                        this.showView = "vplan";
                      });
                      Navigator.of(context).pop(context);
                    },
                  ),
                ),
                ListTileTheme(
                  child: ListTile(
                    leading: Icon(
                      Icons.settings,
                      color: this.showView == "settings" ? this.secondary : Colors.grey,
                    ),
                    title: Text("Einstellungen",
                        style:
                            TextStyle(color: this.showView == "settings" ? this.secondary : null)),
                    onTap: () {
                      setState(() {
                        this.showView = "settings";
                      });
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ),
          body: this.showView == "vplan"
              ? !this.loading
                  ? SingleChildScrollView(
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
                                        color: this.getKursColor(entry["Kurs"]),
                                        padding: const EdgeInsets.all(8),
                                        child: Text(
                                          entry["Kurs"],
                                          style: TextStyle(color: this.getTextColor()),
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
                                                color: this
                                                    .getCellBackgroundColor(entry, key, context),
                                                padding: const EdgeInsets.all(8),
                                                child: Text(
                                                  entry[key] == "N/A"
                                                      ? "Keine Information"
                                                      : entry[key],
                                                  style: TextStyle(
                                                      color: this.getTextColor(
                                                          color: this.getCellBackgroundColor(
                                                              entry, key, context)),
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
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          CircularProgressIndicator(),
                        ],
                      ),
                    )
              : ListView(
                  children: [
                    ListTile(
                      tileColor: this.secondary,
                      title: Text(
                        "Design",
                        style: TextStyle(color: this.getTextColor()),
                      ),
                      dense: true,
                    ),
                    ListTile(
                      leading: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(this.autoDarkMode
                              ? Icons.brightness_auto
                              : this.isDarkMode(context)
                                  ? Icons.brightness_2
                                  : Icons.brightness_high),
                        ],
                      ),
                      title: Text("App Thema"),
                      subtitle: Text(this.autoDarkMode
                          ? "Automatisch"
                          : this.isDarkMode(context)
                              ? "Dunkel"
                              : "Hell"),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => SimpleDialog(
                            title: Text("App Thema"),
                            children: [
                              SimpleDialogOption(
                                child: Text("Automatisch", style: TextStyle(fontSize: 16)),
                                padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 15.0),
                                onPressed: () {
                                  setState(() {
                                    this.autoDarkMode = true;
                                    // this.manualDarkMode = false;
                                  });
                                  this.setAPBool("autoDarkMode", true);
                                  Navigator.pop(context);
                                },
                              ),
                              SimpleDialogOption(
                                child: Text("Hell", style: TextStyle(fontSize: 16)),
                                padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 15.0),
                                onPressed: () {
                                  setState(() {
                                    this.autoDarkMode = false;
                                    this.manualDarkMode = false;
                                  });
                                  this.setAPBool("autoDarkMode", false);
                                  this.setAPBool("manualDarkMode", false);
                                  Navigator.pop(context);
                                },
                              ),
                              SimpleDialogOption(
                                child: Text("Dunkel", style: TextStyle(fontSize: 16)),
                                padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 15.0),
                                onPressed: () {
                                  setState(() {
                                    this.autoDarkMode = false;
                                    this.manualDarkMode = true;
                                  });
                                  this.setAPBool("autoDarkMode", false);
                                  this.setAPBool("manualDarkMode", true);
                                  Navigator.pop(context);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.brightness_1,
                            color: this.primary,
                          ),
                        ],
                      ),
                      title: Text("App Farbe"),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            contentPadding: EdgeInsets.all(6.0),
                            title: Text("App Farbe"),
                            content: Container(
                              width: 100,
                              height: (Colors.primaries.length / 5 * 45).roundToDouble(),
                              child: GridView.count(
                                crossAxisCount: Colors.primaries.length ~/ 3,
                                childAspectRatio: 1,
                                crossAxisSpacing: 0,
                                padding: EdgeInsets.all(15),
                                children: [
                                  for (var i = 0; i < Colors.primaries.length; i++)
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          this.primary = Colors.primaries[i];
                                          this.computeSecondary(Colors.primaries[i]);
                                        });
                                        setAPInt("primary", i);
                                        Navigator.pop(context);
                                      },
                                      child: Material(
                                        shape: CircleBorder(),
                                        elevation: 5,
                                        child: CircleAvatar(
                                          backgroundColor: Colors.primaries[i],
                                          radius: 0.5,
                                          child: this.primary == Colors.primaries[i]
                                              ? Icon(Icons.check,
                                                  color:
                                                      this.getTextColor(color: Colors.primaries[i]))
                                              : null,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    Divider(
                      thickness: 2,
                      indent: 18,
                      endIndent: 18,
                      color: this.secondary,
                    )
                  ],
                ),
          bottomNavigationBar: this.showView == "vplan"
              ? BottomNavigationBar(
                  selectedItemColor: this.getTextColor(),
                  unselectedItemColor: this.getTextColor().withOpacity(0.5),
                  backgroundColor: this.secondary,
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
                )
              : null,
        ),
      ),
    );
  }
}
