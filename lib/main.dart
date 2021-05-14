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
  bool loading = false;
  bool canRefresh = true;
  List<dynamic> combination = [];
  SearchBar searchBar;
  String searchText = "";
  List<String> header = [
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
  // List<int> activeHeader;
  // List<String> header = [];
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
  int fixedColumn;
  var viewTranslator = {
    "vplan": {
      "appBarTitle": "Vertretungsplan",
    },
    "settings": {
      "appBarTitle": "Einstellungen",
    }
  };

  FPlanState() {
    this.searchBar = new SearchBar(
      inBar: true,
      setState: setState,
      controller: TextEditingController(text: this.searchText),
      closeOnSubmit: true,
      clearOnSubmit: false,
      onCleared: () {
        this.search("");
        setState(() => {this.searchText = ""});
      },
      onSubmitted: (searchText) {
        setState(() => {this.searchText = searchText});
        this.search(searchText);
      },
      onChanged: (searchText) {
        setState(() => {this.searchText = searchText});
        this.search(searchText);
      },
      buildDefaultAppBar: buildAppBar,
      hintText: "Suche..",
    );
  }

  AppBar buildAppBar(BuildContext context) {
    return new AppBar(
      backgroundColor: this.primary,
      title: Text(
        this.viewTranslator[this.showView]["appBarTitle"],
        style: TextStyle(color: Colors.white),
      ),
      iconTheme: IconThemeData(
        color: this.getTextColor(),
      ),
      actions: <Widget>[
        searchBar.getSearchAction(context),
        IconButton(
          onPressed: this.canRefresh
              ? () {
                  this.init(context: context);
                }
              : null,
          icon: const Icon(Icons.refresh),
        )
      ],
    );
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
        this.combination.addAll(
              this
                  .vplan
                  .where((e) => (e["Kurs"].toLowerCase().contains(searchText) ||
                      // e["Wochentag"].toLowerCase().contains(searchText) ||
                      e["Stunde"].toLowerCase().contains(searchText) ||
                      e["Fach"].toLowerCase().contains(searchText) ||
                      e["Lehrer"].toLowerCase().contains(searchText) ||
                      e["Raum"].toLowerCase().contains(searchText) ||
                      e["Info"].toLowerCase().contains(searchText) ||
                      e["Vertretungstext"].toLowerCase().contains(searchText)))
                  .toList(),
            );
      }
    });
  }

  loadAppPreferences() async {
    SharedPreferences appPrefs = await SharedPreferences.getInstance();
    this.manualDarkMode =
        appPrefs.containsKey("manualDarkMode") ? appPrefs.getBool("manualDarkMode") : true;
    this.autoDarkMode =
        appPrefs.containsKey("autoDarkMode") ? appPrefs.getBool("autoDarkMode") : true;
    if (appPrefs.containsKey("primary"))
      this.primary = Colors.primaries[appPrefs.getInt("primary")];
    else
      this.primary = Colors.blue;
    this.computeSecondary(this.primary);
    if (appPrefs.containsKey("fixedColumn"))
      this.fixedColumn = appPrefs.getInt("fixedColumn");
    else
      this.fixedColumn = 0;
    if (appPrefs.containsKey("header")) this.header = appPrefs.getStringList("header");

    // Init VPlan
    this.init();
  }

  setAPBool(String key, bool value) async {
    SharedPreferences appPrefs = await SharedPreferences.getInstance();
    appPrefs.setBool(key, value);
  }

  setAPString(String key, String value) async {
    SharedPreferences appPrefs = await SharedPreferences.getInstance();
    appPrefs.setString(key, value);
  }

  setAPStringList(String key, List<String> values) async {
    SharedPreferences appPrefs = await SharedPreferences.getInstance();
    appPrefs.setStringList(key, values);
  }

  setAPInt(String key, int value) async {
    SharedPreferences appPrefs = await SharedPreferences.getInstance();
    appPrefs.setInt(key, value);
  }

  setAPIntList(String key, List<int> values) async {
    List<String> stringValues = values.map((e) => e.toString()).toList();
    this.setAPStringList(key, stringValues);
  }

  @override
  void initState() {
    this.loadAppPreferences();
    super.initState();
  }

  void init({context}) {
    if (this.canRefresh) {
      setState(() {
        this.loading = true;
        this.canRefresh = false;
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
        List entries = List.from(entriesJSON);
        entries.sort((a, b) {
          return a["ID"].compareTo(b["ID"]);
        });
        this.vplan.addAll(entries);
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
        Future.delayed(Duration(milliseconds: 1500), () {
          setState(() {
            this.canRefresh = true;
          });
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: WillPopScope(
            onWillPop: () async {
              ScaffoldMessenger.of(context).removeCurrentSnackBar();
              return true;
            },
            child: Text('Laden erfolgreich', style: TextStyle(color: Colors.white)),
          ),
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
          this.canRefresh = false;
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
  }

  void computeSecondary(color) {
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

  Color getColumnColor(var columnName) {
    Color odd = this.primary;
    Color even = this.secondary;
    if (columnName == this.header[this.fixedColumn]) {
      this.lastKursColor = even;
      return even;
    }
    if (this.lastKurs != columnName) {
      this.lastKursColor = this.lastKursColor == even ? odd : even;
      this.lastKurs = columnName;
      return this.lastKursColor;
    } else
      return this.lastKursColor;
  }

  Color getCellBackgroundColor(var entry, var key, var context) {
    if (this.combination.indexOf(entry) == 0)
      return this.secondary;
    else if (entry[key] == "Entfall")
      return Colors.red.shade400;
    else
      return this.isDarkMode(context) ? Colors.black : Colors.white;
  }

  Color getTextColor({Color color}) {
    if (color != null)
      return color.computeLuminance() > 0.5 ? Colors.black : Colors.white;
    else if (this.primary != null)
      return this.primary.computeLuminance() > 0.5 ? Colors.black : Colors.white;
    else
      return Colors.grey;
  }

  List<dynamic> getCombinedFiltered() {
    return this
        .combination
        .where((element) =>
            (this.selectedDay == 0
                ? element["Wochentag"] == this.firstDay
                : element["Wochentag"] == this.secondDay) ||
            element[this.header[this.fixedColumn]] == this.header[this.fixedColumn])
        .toList();
  }

  bool isDarkMode(context) {
    return this.autoDarkMode
        ? MediaQuery.of(context).platformBrightness == Brightness.dark
        : this.manualDarkMode
            ? true
            : false;
  }

  Divider settingsDivier() {
    return Divider(
      color: this.secondary,
      indent: 15.0,
      endIndent: 15.0,
      height: 0,
      thickness: 1,
    );
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
        accentColor: this.primary,
        textTheme: Typography.material2018().black,
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        unselectedWidgetColor: this.getTextColor(),
        cardTheme: CardTheme(
          color: Colors.white,
          margin: EdgeInsets.all(15.0),
          elevation: 0,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: this.secondary, width: 1),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          selectedItemColor: this.getTextColor(),
          unselectedItemColor: this.getTextColor().withOpacity(0.5),
          backgroundColor: this.secondary,
          elevation: 16,
        ),
        appBarTheme: AppBarTheme(backgroundColor: this.primary, elevation: 0),
      ),
      darkTheme: ThemeData(
        primarySwatch: this.primary,
        canvasColor: Colors.black,
        accentColor: this.primary,
        textTheme: Typography.material2018().white,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        unselectedWidgetColor: this.getTextColor(),
        cardTheme: CardTheme(
          color: Colors.black,
          margin: EdgeInsets.all(15.0),
          elevation: 0,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: this.secondary, width: 1),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          selectedItemColor: this.getTextColor(),
          unselectedItemColor: this.getTextColor().withOpacity(0.5),
          backgroundColor: this.secondary,
          elevation: 16,
        ),
        appBarTheme: AppBarTheme(elevation: 0),
      ),
      home: Builder(
        builder: (context) => Scaffold(
          appBar: this.showView == "vplan"
              ? this.searchBar.build(context)
              : AppBar(
                  iconTheme: IconThemeData(color: this.primary),
                  backgroundColor: this.isDarkMode(context) ? Colors.black : Colors.white,
                  title: Text(
                    this.viewTranslator[this.showView]["appBarTitle"],
                    style: TextStyle(color: this.primary),
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
                                        width: this.getColumnWidth(this.header[this.fixedColumn]),
                                        color: this
                                            .getColumnColor(entry[this.header[this.fixedColumn]]),
                                        padding: const EdgeInsets.all(8),
                                        child: Text(
                                          entry[this.header[this.fixedColumn]],
                                          style: TextStyle(
                                              color: this.getTextColor(
                                                  color: this.getColumnColor(
                                            entry[this.header[this.fixedColumn]],
                                          ))),
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
                                        for (int key = 0; key < this.header.length; key++)
                                          if (this.header[key] != this.header[this.fixedColumn])
                                            Center(
                                              child: Container(
                                                height: 50,
                                                width: this.getColumnWidth(this.header[key]),
                                                alignment: Alignment.center,
                                                color: this.getCellBackgroundColor(
                                                    entry, this.header[key], context),
                                                padding: const EdgeInsets.all(8),
                                                child: Text(
                                                  entry[this.header[key]] == "N/A"
                                                      ? "Keine Information"
                                                      : entry[this.header[key]],
                                                  style: TextStyle(
                                                      color: this.getTextColor(
                                                          color: this.getCellBackgroundColor(
                                                              entry, this.header[key], context)),
                                                      fontStyle: entry[this.header[key]] == "N/A"
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
                      title: Text(
                        "Design",
                        style: TextStyle(color: this.secondary, fontWeight: FontWeight.bold),
                      ),
                      dense: true,
                    ),
                    Card(
                      child: Column(
                        children: [
                          ListTile(
                            leading: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  this.autoDarkMode
                                      ? Icons.brightness_auto
                                      : this.isDarkMode(context)
                                          ? Icons.brightness_2
                                          : Icons.brightness_high,
                                  color: this.primary,
                                ),
                              ],
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(10),
                                topRight: Radius.circular(10),
                              ),
                            ),
                            title: Text("App Thema"),
                            subtitle: Text(this.autoDarkMode
                                ? "Nach System"
                                : this.isDarkMode(context)
                                    ? "Dunkel"
                                    : "Hell"),
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (_) => SimpleDialog(
                                  backgroundColor: this.secondary,
                                  contentPadding: EdgeInsets.all(6.0),
                                  title: Row(
                                    children: [
                                      Icon(
                                        this.autoDarkMode
                                            ? Icons.brightness_auto
                                            : this.isDarkMode(context)
                                                ? Icons.brightness_2
                                                : Icons.brightness_high,
                                        size: 35,
                                        color: this.getTextColor(),
                                      ),
                                      Divider(
                                        indent: 10.0,
                                      ),
                                      Text(
                                        "App Thema",
                                        style: TextStyle(
                                          color: this.getTextColor(color: this.secondary),
                                        ),
                                      ),
                                    ],
                                  ),
                                  children: [
                                    SimpleDialogOption(
                                      child: Text(
                                        "Automatisch",
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: this.getTextColor(color: this.secondary),
                                        ),
                                      ),
                                      padding:
                                          EdgeInsets.symmetric(vertical: 12.0, horizontal: 15.0),
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
                                      child: Text(
                                        "Hell",
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: this.getTextColor(color: this.secondary),
                                        ),
                                      ),
                                      padding:
                                          EdgeInsets.symmetric(vertical: 12.0, horizontal: 15.0),
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
                                      child: Text(
                                        "Dunkel",
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: this.getTextColor(color: this.secondary),
                                        ),
                                      ),
                                      padding:
                                          EdgeInsets.symmetric(vertical: 12.0, horizontal: 15.0),
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
                          this.settingsDivier(),
                          ListTile(
                            leading: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.color_lens,
                                  color: this.primary,
                                ),
                              ],
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(10),
                                bottomRight: Radius.circular(10),
                              ),
                            ),
                            title: Text("App Farbe"),
                            subtitle: Text("Accentfarbe der App"),
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  backgroundColor: this.secondary,
                                  contentPadding: EdgeInsets.all(6.0),
                                  title: Row(
                                    children: [
                                      Icon(
                                        Icons.color_lens,
                                        size: 35,
                                        color: this.getTextColor(),
                                      ),
                                      Divider(
                                        indent: 10.0,
                                      ),
                                      Text(
                                        "App Farbe",
                                        style: TextStyle(
                                          color: this.getTextColor(color: this.secondary),
                                        ),
                                      ),
                                    ],
                                  ),
                                  content: Container(
                                    width: 100,
                                    height: (Colors.primaries.length / 6 * 50).roundToDouble(),
                                    child: GridView.count(
                                      crossAxisCount: 6,
                                      childAspectRatio: 1,
                                      crossAxisSpacing: 0,
                                      padding: EdgeInsets.all(8),
                                      children: [
                                        for (var i = 0; i < Colors.primaries.length; i++)
                                          Container(
                                            padding: EdgeInsets.all(4),
                                            child: GestureDetector(
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
                                                elevation: 2,
                                                color: Colors.primaries[i],
                                                child: this.primary == Colors.primaries[i]
                                                    ? Icon(Icons.check,
                                                        color: this.getTextColor(
                                                            color: Colors.primaries[i]))
                                                    : null,
                                              ),
                                            ),
                                          )
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    ListTile(
                      title: Text(
                        "Anzeige",
                        style: TextStyle(color: this.secondary, fontWeight: FontWeight.bold),
                      ),
                      dense: true,
                    ),
                    Card(
                      child: Column(
                        children: [
                          ListTile(
                            leading: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.pivot_table_chart,
                                  color: this.primary,
                                )
                              ],
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(10),
                                topRight: Radius.circular(10),
                              ),
                            ),
                            title: Text("Feste Spalte"),
                            subtitle: Text(this.header[this.fixedColumn]),
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (_) => SimpleDialog(
                                  backgroundColor: this.secondary,
                                  contentPadding: EdgeInsets.all(6.0),
                                  title: Row(
                                    children: [
                                      Icon(
                                        Icons.pivot_table_chart,
                                        size: 35,
                                        color: this.getTextColor(),
                                      ),
                                      Divider(
                                        indent: 10.0,
                                      ),
                                      Text(
                                        "Feste Spalte",
                                        style: TextStyle(
                                          color: this.getTextColor(color: this.secondary),
                                        ),
                                      ),
                                    ],
                                  ),
                                  children: [
                                    for (int i = 0; i < this.header.length; i++)
                                      SimpleDialogOption(
                                        padding: EdgeInsets.all(0),
                                        child: RadioListTile(
                                          activeColor: this.getTextColor(),
                                          value: i,
                                          groupValue: this.fixedColumn,
                                          title: Text(
                                            this.header[i],
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: this.getTextColor(color: this.secondary),
                                            ),
                                          ),
                                          onChanged: (value) {
                                            setState(() {
                                              this.fixedColumn = value;
                                            });
                                            this.setAPInt("fixedColumn", value);
                                            Navigator.pop(context);
                                          },
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                          this.settingsDivier(),
                          ListTile(
                            leading: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.table_chart,
                                  color: this.primary,
                                ),
                              ],
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(10),
                                bottomRight: Radius.circular(10),
                              ),
                            ),
                            title: Text("Spalten"),
                            subtitle: Text("Anzeige der Spalten"),
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (_) => Scaffold(
                                  appBar: AppBar(
                                    iconTheme: IconThemeData(
                                      color: this.primary,
                                    ),
                                    backgroundColor:
                                        this.isDarkMode(context) ? Colors.black : Colors.white,
                                    title: Text(
                                      "Spalten",
                                      style: TextStyle(
                                        color: this.primary,
                                      ),
                                    ),
                                  ),
                                  body: ReorderableListView(
                                    onReorder: (int oldIndex, int newIndex) {
                                      List<String> headerCopy = List.from(this.header);
                                      String item = headerCopy.removeAt(oldIndex);
                                      List<String> headerTail = List.from(headerCopy
                                          .sublist(oldIndex > newIndex ? newIndex : newIndex - 1));
                                      headerCopy.removeRange(
                                          oldIndex > newIndex ? newIndex : newIndex - 1,
                                          headerCopy.length);
                                      headerCopy.add(item);
                                      headerCopy.addAll(headerTail);
                                      setState(() {
                                        this.header = headerCopy;
                                      });
                                      setAPStringList("header", this.header);
                                    },
                                    children: [
                                      for (int key = 0; key < this.header.length; key++)
                                        // CheckboxListTile(
                                        ListTile(
                                          title: Text(
                                            this.header[key],
                                            style: TextStyle(
                                              color: this.getTextColor(),
                                            ),
                                          ),
                                          tileColor: this.secondary,
                                          // controlAffinity: ListTileControlAffinity.leading,
                                          trailing: Icon(
                                            Icons.drag_handle,
                                            color: this.getTextColor(),
                                          ),
                                          // secondary: Icon(Icons.drag_handle),
                                          // checkColor: this.secondary,
                                          // activeColor: this.getTextColor(),
                                          // value: this.header.contains(
                                          //       this.header[key],
                                          //     ),
                                          key: Key(
                                            this.header[key],
                                          ),
                                          // onChanged: (value) {
                                          //   if (key != this.fixedColumn)
                                          //     setState(() {
                                          //       if (!value) {
                                          //         int index = this.activeHeader.indexOf(key);
                                          //         this.activeHeader.remove(index);
                                          //       } else
                                          //         this
                                          //             .activeHeader
                                          //             .insert(this.activeHeader.length, key);
                                          //       this.generateHeader();
                                          //     });
                                          //   print("hi");
                                          //   this.activeHeader.forEach((element) {
                                          //     print(element);
                                          //   });
                                          //   setAPIntList("activeHeader", this.activeHeader);
                                          // },
                                        )
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    )
                  ],
                ),
          bottomNavigationBar: this.showView == "vplan"
              ? BottomNavigationBar(
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

  bool isExpanded = true;
}
