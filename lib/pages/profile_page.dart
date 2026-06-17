import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:penny_wise/model/connectivity_util.dart';
import 'package:penny_wise/model/document_snapshot_wrappers.dart';
import 'package:penny_wise/model/reading_streams.dart';
import 'package:penny_wise/styles.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();

}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController _usernameController = TextEditingController();
  String _initialUsername = "";
  String? _errorText;
  bool _areStreamsLoaded = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // Wait for the streams to load
    if (!_areStreamsLoaded) {
      // Get initial values
      final public = Provider.of<PublicUser?>(context);
      if (public != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _initialUsername = public.username;
          _usernameController.text = _initialUsername;
          setState(() {
            _areStreamsLoaded = true;
          });
        });
        return Scaffold(
          backgroundColor: Styles.backgroundColor,
          body: Center(child: CircularProgressIndicator(color: Styles.accentColor)),
        );
      }
    }
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null) {
          } if (details.primaryVelocity! > 200) { // Swipe left
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          }
      },
      child: Scaffold(
        backgroundColor: Styles.backgroundColor,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final height = constraints.maxHeight;
              return Column(
                children: [
                  Container(
                    color: Styles.backgroundColor.withValues(alpha: 0.5),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        SizedBox(width: 25),
                        IconButton.filled(onPressed: () => Navigator.pop(context), icon: Icon(Icons.arrow_back, color: Styles.accentColor), style: IconButton.styleFrom(backgroundColor: Styles.primaryColor, side: BorderSide(color: Styles.accentColor, width: 2)), tooltip: "Profile Page"),
                        Expanded(child: Text("Penny Wise", style: Styles.titleFont, textAlign: TextAlign.center)),
                      ]
                    ),
                  ),
                  SingleChildScrollView(
                    child: Row(
                      children: [
                        SizedBox(width: MediaQuery.of(context).size.width*0.1), // Left padding
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisSize: MainAxisSize.max,
                            spacing: 10,
                            children: [
                              TextField(
                                controller: _usernameController,
                                onChanged: (value) {
                                  setState(() {
                                    _errorText = (value != "" && value.trim().isNotEmpty) ? null : "Please enter a complete username";
                                  });
                                },
                                decoration: Styles.textFieldDecoration.copyWith(labelText: "Username", errorText: _errorText),
                                style: Styles.textFont,
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  _saveProfile();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Styles.lighterBackgroundColor,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  side: BorderSide(color: Styles.white, width: 3),
                                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20)
                                ),
                                child: Text("Save", style: Styles.headingFont)
                              ),
                              SizedBox(height: height*0.3),
                              ElevatedButton(
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  _logOut();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Styles.lighterBackgroundColor,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  side: BorderSide(color: Styles.white, width: 3),
                                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20)
                                ),
                                child: Text("Log Out", style: Styles.headingFont)
                              )
                            ]
                          )
                        ),
                        SizedBox(width: MediaQuery.of(context).size.width*0.1), // Right padding
                      ]
                    )
                  )
                ]
              );
            }
          )
        )
      )
    );
  }

  Future<void> _saveProfile() async {
    // Do nothing if the username textfield has a validation error
    if (_errorText != null) {
      return;
    }
    if (_initialUsername == _usernameController.text) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No changes to save!", style: Styles.textFont), showCloseIcon: true, duration: Duration(seconds: 3), backgroundColor: Styles.grey, behavior: SnackBarBehavior.floating, margin: EdgeInsets.all(20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Styles.white, width: 3)))
      );
    } else {
      bool usernameAlreadyExists = await FirebaseFirestore.instance.collection("public-users").where("username", isEqualTo: _usernameController.text).get().then((value) => !value.docs.isEmpty);
      if (usernameAlreadyExists) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Username already exists! Try another one.", style: Styles.textFont), showCloseIcon: true, duration: Duration(seconds: 3), backgroundColor: Styles.red, behavior: SnackBarBehavior.floating, margin: EdgeInsets.all(20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Styles.white, width: 3)))
        );
      } else {
        await FirebaseFirestore.instance.collection("public-users").doc(ReadingStreams.getInstance().userId).update({
          "username": _usernameController.text
        });
        if (await checkInternertConnection() == false) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("No network connection. Your changes are saved locally, but connect to the internet soon please.", style: Styles.textFont), showCloseIcon: true, duration: Duration(seconds: 3), backgroundColor: Styles.red, behavior: SnackBarBehavior.floating, margin: EdgeInsets.all(20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Styles.white, width: 3)))
          );
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Settings saved successfully!", style: Styles.textFont), showCloseIcon: true, duration: Duration(seconds: 3), backgroundColor: Styles.accentColor, behavior: SnackBarBehavior.floating, margin: EdgeInsets.all(20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Styles.white, width: 3)))
          );
        }
      }
    }
  }

  Future<void> _logOut() async {
    // reset this flag to prevent next login skipping the loading page and going straight to the main app page without loading data correctly into Firestore
    ReadingStreams.isPostAuthDataComplete.value = false;
    ReadingStreams.dispose();
    await FirebaseAuth.instance.signOut();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

}