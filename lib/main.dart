// Import necessary Flutter packages
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// Import community-made packages

// https://pub.dev/packages/flutter_floating_bottom_bar/
// Import self-made custom styles and pages
import 'package:penny_wise/styles.dart';
import 'package:penny_wise/pages/pages_import.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Root widget of application
  @override
  Widget build(BuildContext context) {
    return MaterialApp( // Uses Google's Material Design system
      title: 'Penny Wise',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Styles.accentColor),
      ),
      home: const AppMainShell(title: 'Penny Wise'),
      // Official tutorial for routing with built-in Navigator class: https://api.flutter.dev/flutter/widgets/Navigator-class.html
      routes: <String, WidgetBuilder>{
        // Define named routes for navigation
        '/profile': (context) => const ProfilePage(),
      },
    );
  }
}

class AppMainShell extends StatefulWidget {
  const AppMainShell({super.key, required this.title});
  final String title;

  @override
  State<AppMainShell> createState() => _AppMainShellState();
}

class _AppMainShellState extends State<AppMainShell> {
  int _selectedPageIndex = 2; // Default to Home page
  final List<Widget> _pages = const [
    FriendsPage(),
    TripsPage(),
    HomePage(),
    AddExpensePage(),
    SettingsPage()
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea( child: Scaffold(
      body: Column(
        children: [
          Container(
            color: Styles.backgroundColor,
            child: Row(children: [
              Expanded(child: Text("Penny Wise", style: Styles.titleFont, textAlign: TextAlign.center)),
              IconButton.filled(onPressed: () => Navigator.pushNamed(context, '/profile'), icon: Icon(Icons.account_circle, color: Styles.accentColor), style: IconButton.styleFrom(backgroundColor: Styles.primaryColor, side: BorderSide(color: Styles.accentColor, width: 2)), tooltip: "Profile Page"),
              SizedBox(width: 25)
            ]),
          ),
          Expanded(
            child: IndexedStack(
              index: _selectedPageIndex,
              children: _pages,
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedPageIndex,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        destinations: const <Widget>[
          NavigationDestination(icon: Icon(Icons.group), label: "Friends"),
          NavigationDestination(icon: Icon(Icons.commute), label: "Trips"),
          NavigationDestination(icon: Icon(Icons.home), label: "Home"),
          NavigationDestination(icon: Icon(Icons.add), label: "Add"),
          NavigationDestination(icon: Icon(Icons.settings), label: "Settings")
        ],
        onDestinationSelected: (int index) {
          // On click of a nav item, update the selected page index with setState to trigger a rebuild and show the corresponding page
          HapticFeedback.lightImpact();
          setState(() {_selectedPageIndex = index;});
        },
        backgroundColor: Styles.primaryColor,
        indicatorColor: Styles.accentColor,
        labelTextStyle: WidgetStateProperty<TextStyle>.fromMap(<WidgetStatesConstraint, TextStyle>{
          WidgetState.selected: Styles.textFont.copyWith(color: Styles.accentColor),
          WidgetState.any: Styles.textFont.copyWith(color: Styles.black),
        }),
        elevation: 10,
      ),
    ));
  }
}
