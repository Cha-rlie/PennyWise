import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:penny_wise/styles.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class LoadingPage extends StatefulWidget {
  const LoadingPage({super.key});

  @override
  State<LoadingPage> createState() => _LoadingPageState();

}

class _LoadingPageState extends State<LoadingPage> {
  bool cannotProceed = false;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(seconds: 3));
      if (_checkUser()) {
        if (!mounted) return;
        HapticFeedback.lightImpact();
        Navigator.pushReplacementNamed(context, '/mainApp');
      } else {
        if (await _checkInternertConnection()) {
          if (!mounted) return;
          HapticFeedback.lightImpact();
          Navigator.pushReplacementNamed(context, '/welcome_unathenticated');
        } else {
          if (!mounted) return;
          setState(() {
            cannotProceed = true;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: Styles.backgroundColor,
      body: SafeArea(
        child: Column( crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Positioned.fill(top: 0, child: Text("Penny Wise", style: Styles.titleFont, textAlign: TextAlign.center)),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(cannotProceed ? "Error: No internet connection" : "Loading...", style: Styles.headingFont.copyWith(color: Styles.accentColor)),
                  // TODO: Add loading gif animation here
                ],
              ),
            ),
        ]),
      ),
    );
  }

  bool _checkUser() {
    return FirebaseAuth.instance.currentUser != null;
  }

  Future<bool> _checkInternertConnection() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult[0] != ConnectivityResult.none;
  }

}