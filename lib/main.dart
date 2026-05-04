// Import necessary Flutter packages
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Import official Firebase packages for authentication and database
import 'package:firebase_core/firebase_core.dart';
import 'package:penny_wise/firebase_options.dart'; // Config file for Firebase
import 'package:firebase_auth/firebase_auth.dart';
import 'package:penny_wise/model/document_snapshot_wrappers.dart';
import 'package:penny_wise/model/reading_streams.dart';

// Import community-made packages
import 'package:provider/provider.dart';

// https://pub.dev/packages/flutter_floating_bottom_bar/
// Import self-made custom styles and pages
import 'package:penny_wise/styles.dart';
import 'package:penny_wise/pages/pages_import.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure Flutter bindings are initialized before starting async operations
  await Firebase.initializeApp( // Initialize Firebase with config options
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Root widget of application
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ReadingStreams.isPostAuthDataComplete,
      builder: (context, isPostAuthDataComplete, _) {
        return StreamBuilder<User?>( // Listen to authentication state changes
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              // While waiting for authentication state, show a loading indicator
              return MaterialApp(
                title: 'Penny Wise',
                theme: ThemeData(
                  colorScheme: ColorScheme.fromSeed(seedColor: Styles.accentColor),
                ),
                home: const LoadingPage()
              );
            }
            final user = snapshot.data;
            if (user == null) {
              return MaterialApp( // Uses Google's Material Design system
                title: 'Penny Wise',
                theme: ThemeData(
                  colorScheme: ColorScheme.fromSeed(seedColor: Styles.accentColor),
                ),
                home: const WelcomeUnauthenticatedPage(), // Initial page that checks for internet and handles user authentication
                routes: <String, WidgetBuilder>{
                  // Define named routes for navigation
                  '/welcome_unathenticated': (context) => const WelcomeUnauthenticatedPage(),
                  '/logIn': (context) => const LogInPage(),
                  '/signUp': (context) => const SignUpPage(),
                },
              );
            }
            ReadingStreams.initialize(user.uid);
            if (!isPostAuthDataComplete) {
              // While waiting for post-authentication data management
              return MaterialApp( // Uses Google's Material Design system
                title: 'Penny Wise',
                theme: ThemeData(
                  colorScheme: ColorScheme.fromSeed(seedColor: Styles.accentColor),
                ),
                home: const WelcomeUnauthenticatedPage(), // Initial page that checks for internet and handles user authentication
                routes: <String, WidgetBuilder>{
                  // Define named routes for navigation
                  '/welcome_unathenticated': (context) => const WelcomeUnauthenticatedPage(),
                  '/logIn': (context) => const LogInPage(),
                  '/signUp': (context) => const SignUpPage(),
                },
              );
            }
            return MultiProvider(
              providers: [
                StreamProvider<PublicUser?>(
                  initialData: null,
                  create: (context) => ReadingStreams.getInstance().publicUserStream
                    .map((snapshot) => snapshot.exists ? PublicUser(snapshot.data() as Map<String, dynamic>) : null),
                ),
                StreamProvider<PrivateUser?>(
                  initialData: null,
                  create: (context) => ReadingStreams.getInstance().privateUserStream
                    .map((snapshot) => snapshot.exists ? PrivateUser(snapshot.data() as Map<String, dynamic>) : null),
                ),
              ],
              child: MaterialApp( // Uses Google's Material Design system
                title: 'Penny Wise',
                theme: ThemeData(
                  colorScheme: ColorScheme.fromSeed(seedColor: Styles.accentColor),
                ),
                home: const AppMainShell(title: 'Penny Wise'), // Main page
                // Official tutorial for routing with built-in Navigator class: https://api.flutter.dev/flutter/widgets/Navigator-class.html
                routes: <String, WidgetBuilder>{
                  // Define named routes for navigation
                  '/profile': (context) => const ProfilePage(),
                },
              )
            );
          }
        );
      }
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
  // TODO: add gesture movement (only nav or...?)
  @override
  Widget build(BuildContext context) {
    // TODO: add log out after no gestures detected for 1 minute
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null) {
          if (details.primaryVelocity! < -200) {
            HapticFeedback.lightImpact();
            setState(() {
              _selectedPageIndex = min(4, _selectedPageIndex+1);
            });
          } else if (details.primaryVelocity! > 200) {
            HapticFeedback.lightImpact();
            setState(() {
              _selectedPageIndex = max(0, _selectedPageIndex-1);
            });
          }
        }
      },
      child: Scaffold(
        backgroundColor: Styles.backgroundColor,
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
        body: SafeArea(
          child: LayoutBuilder(builder:
          (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;
            return Stack(
              children: [
                Positioned.fill(
                  child: IndexedStack(
                    index: _selectedPageIndex,
                    children: _pages,
                  )
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      ClipRect(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 8.5, sigmaY: 8.5),
                          child: Container(
                            color: Styles.backgroundColor.withValues(alpha: 0.5),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Row(
                              children: [
                                Expanded(child: Text("Penny Wise", style: Styles.titleFont, textAlign: TextAlign.center)),
                                SizedBox(width: width*0.1),
                                IconButton.filled(onPressed: () {
                                  HapticFeedback.lightImpact();
                                  Navigator.pushNamed(context, '/profile');
                                }, icon: Icon(Icons.account_circle, color: Styles.accentColor), style: IconButton.styleFrom(backgroundColor: Styles.primaryColor, side: BorderSide(color: Styles.accentColor, width: 2)), tooltip: "Profile Page"),
                                SizedBox(width: width*0.05)
                              ]
                            ),
                          )
                        ),
                      ),
                      IgnorePointer(
                        child: Container(
                          height: 32,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Styles.backgroundColor.withValues(alpha: 0.5),
                                Styles.backgroundColor.withValues(alpha: 0.0)
                              ]
                            )
                          )
                        )
                      )
                    ]
                  )
                )
              ]
            );
          })
        )
      )
    );
  }
}
