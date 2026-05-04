import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:penny_wise/model/reading_streams.dart';
import 'package:penny_wise/styles.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:penny_wise/model/connectivity_util.dart';

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
      await Future.delayed(const Duration(seconds: 2));
      if (await checkInternertConnection() != true) {
        if (!mounted) return;
        setState(() {
          cannotProceed = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: Styles.backgroundColor,
      body: SafeArea(
        child: Row(mainAxisSize: MainAxisSize.max, mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
              Text("Penny Wise", style: Styles.titleFont, textAlign: TextAlign.center),
              Text(cannotProceed ? "Error: No internet connection" : "Loading...", style: Styles.headingFont.copyWith(color: Styles.accentColor)),
              CircularProgressIndicator(color: Styles.accentColor),
            ])
        ]),
      ),
    );
  }

}