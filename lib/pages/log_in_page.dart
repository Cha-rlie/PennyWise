import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:penny_wise/model/reading_streams.dart';
import 'package:penny_wise/styles.dart';

class LogInPage extends StatefulWidget {
  const LogInPage({super.key});

  @override
  State<LogInPage> createState() => _LogInPageState();

}

class _LogInPageState extends State<LogInPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool isLoading = false;

  // Variables to track input
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null) {
          if (details.primaryVelocity! < -200) {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          } else if (details.primaryVelocity! > 200) {
            HapticFeedback.lightImpact();
            if (_formKey.currentState != null && _formKey.currentState!.validate()) {
              _logIn();
            }
          }
        }
      },
      child: Scaffold(backgroundColor: Styles.backgroundColor, body: SafeArea(child: LayoutBuilder(
        builder:(context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
        return SingleChildScrollView(child: ConstrainedBox(constraints: BoxConstraints(minHeight: constraints.maxHeight), child: IntrinsicHeight(child:Stack(alignment: Alignment.center,
          children: [
            Center(child: Image.asset(
              "assets/images/vault.png",
              width: width * 0.8,
              color: Styles.lighterBackgroundColor,
              colorBlendMode: BlendMode.srcIn,
            )),
            Positioned(top: 0, left: 0, right: 0, child: Row(mainAxisSize: MainAxisSize.max, mainAxisAlignment: MainAxisAlignment.start, children: [
                IconButton(onPressed: () {HapticFeedback.lightImpact(); Navigator.pop(context);}, icon: Icon(Icons.keyboard_arrow_left, color: Styles.lighterBackgroundColor, size: 90), style: IconButton.styleFrom(backgroundColor: Styles.backgroundColor),padding: EdgeInsets.symmetric(horizontal: 0, vertical: 0), tooltip: "Back Button"),
                Expanded(child:Text("Penny Wise", style: Styles.titleFont, textAlign: TextAlign.center)),
                SizedBox(width: width*0.1),
              ])),
              // Documentation on form: https://api.flutter.dev/flutter/widgets/Form-class.html
            Positioned(top: height * 0.41, child: Container(width: width * 0.8, child: Column(children: [
              Form(key:_formKey, autovalidateMode: AutovalidateMode.onUnfocus, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              TextFormField(
                controller: _emailController,
                decoration: Styles.textFieldDecoration.copyWith(labelText: "Email"),
                style: Styles.textFont,
                validator: (value) {
                  return (value != null && value.trim().isNotEmpty && value.contains("@")) ? null : "Please enter a valid email";
                },
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: height*0.05),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                style: Styles.textFont,
                decoration: Styles.textFieldDecoration.copyWith(labelText: "Password"),
                validator: (value) => (value != null && value.trim().isNotEmpty) ? null : "Don't forget to enter your password!",
              ),
              SizedBox(height: height*0.185),
              Stack(alignment: Alignment.center, clipBehavior: Clip.none, children: [
              ElevatedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    if (_formKey.currentState != null && _formKey.currentState!.validate()) {
                      _logIn();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Styles.lighterBackgroundColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: BorderSide(color: Styles.white, width: 3),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20)
                  ),
                  child: Text("Log In", style: Styles.headingFont)),
                Positioned(
                  left: 125,
                  child: Icon(Icons.keyboard_arrow_right, size: 100, color: Styles.lighterBackgroundColor),
                ),
              ]),
            ])),
            SizedBox(height: height*0.05),
            ElevatedButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                if (_formKey.currentState != null && _formKey.currentState!.validate()) {
                  _forgotPassword();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Styles.lighterBackgroundColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                side: BorderSide(color: Styles.white, width: 3),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20)
              ),
              child: Text("Forgot Password? Send Reset Email", style: Styles.textFont)
            ),
          ]))),
          // Loading animation but only when isLoading is true
          if (isLoading) Positioned.fill(child: Container(color: Styles.backgroundColor.withValues(alpha: 0.8), child: Center(child: CircularProgressIndicator(color: Styles.accentColor))))
        ]))));
      })
      ))
    );
  }

  // Documentation on Email-Password Firebase authentication: https://firebase.google.com/docs/auth/flutter/password-auth
  Future<void> _logIn() async {
    setState(() => isLoading = true);
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim().toLowerCase(),
        password: _passwordController.text
      );
      final user = credential.user!;

      // Check if the logged-in user has been linked to a data Firestore document yet
      // They should have been linked when signing-up, but this exists as a fail-safe
      // If their document does not exist, it is created here
      final publicSnapshot = await FirebaseFirestore.instance.collection("public-users").doc(user.uid).get();
      if (!publicSnapshot.exists) {
        await FirebaseFirestore.instance
        .collection("public-users")
        .doc(user.uid)
        .set({
          "email": user.email,
           // default username is the part of the email before the @
           //this can be changed in the Profile page after signing up
          "username": user.email!.split("@")[0],
          "acceptingNewFriends": false,
        },
        SetOptions(merge: true));
      }
      final privateSnapshot = await FirebaseFirestore.instance.collection("private-users").doc(user.uid).get();
      if (!privateSnapshot.exists) {
        await FirebaseFirestore.instance
        .collection("private-users")
        .doc(user.uid)
        .set({
          "totalDebt": 0.0,
          "preferredCurrency": "USD",
          "automaticallyLogOut": false,
          "notifications": false,
          "paymentReminderFrequency": "Never",
        },
        SetOptions(merge: true));
      }
      if (!mounted) return;
      // Pull exchange rates from API
      await ReadingStreams.getInstance().initExchangeRates();
      // Only once all the backend is finished, continue on
      //setState(() => isLoading = false);
      ReadingStreams.isPostAuthDataComplete.value = true;
    } on FirebaseAuthException catch (error) {
      setState(() => isLoading = false);
      switch (error.code) {
        case "invalid-credential":
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Invalid email or password. Please try again.", style: Styles.textFont), showCloseIcon: true, duration: Duration(seconds: 3), backgroundColor: Styles.red, behavior: SnackBarBehavior.floating, margin: EdgeInsets.all(20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Styles.white, width: 3))));
          break;
        // This error code and the one below should not occur due to email enumeration protection set to true for the server, but they are included here should this change to ensure proper error handling
        case "user-not-found":
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Invalid email or password. Please try again.", style: Styles.textFont), showCloseIcon: true, duration: Duration(seconds: 3), backgroundColor: Styles.red, behavior: SnackBarBehavior.floating, margin: EdgeInsets.all(20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Styles.white, width: 3))));
          break;
        case "wrong-password":
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Invalid email or password. Please try again.", style: Styles.textFont), showCloseIcon: true, duration: Duration(seconds: 3), backgroundColor: Styles.red, behavior: SnackBarBehavior.floating, margin: EdgeInsets.all(20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Styles.white, width: 3))));
          break;
        case "user-disabled":
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("This account has been disabled.", style: Styles.textFont), showCloseIcon: true, duration: Duration(seconds: 3), backgroundColor: Styles.red, behavior: SnackBarBehavior.floating, margin: EdgeInsets.all(20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Styles.white, width: 3))));
          break;
        case "invalid-email":
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("The email address is invalid. Please try again.", style: Styles.textFont), showCloseIcon: true, duration: Duration(seconds: 3), backgroundColor: Styles.red, behavior: SnackBarBehavior.floating, margin: EdgeInsets.all(20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Styles.white, width: 3))));
          break;
        // This error would occur if the network fails while trying to make this request
        case "network-request-failed":
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Network error. Please check your connection and try again.", style: Styles.textFont), showCloseIcon: true, duration: Duration(seconds: 3), backgroundColor: Styles.red, behavior: SnackBarBehavior.floating, margin: EdgeInsets.all(20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Styles.white, width: 3))));
          break;
        default:
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("An unexpected error occurred. Please try again later.", style: Styles.textFont), showCloseIcon: true, duration: Duration(seconds: 3), backgroundColor: Styles.red, behavior: SnackBarBehavior.floating, margin: EdgeInsets.all(20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Styles.white, width: 3))));
          break;
      }
    } catch (e, stackTrace) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("An unexpected error occurred. Please try again later.", style: Styles.textFont), showCloseIcon: true, duration: Duration(seconds: 3), backgroundColor: Styles.red, behavior: SnackBarBehavior.floating, margin: EdgeInsets.all(20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Styles.white, width: 3))));
      // Log the error and stack trace to the console for debugging
      debugPrint("Error during login: $e");
      debugPrint("Stack trace: $stackTrace");
    }
  }

  Future<void> _forgotPassword() async {
    if (_emailController.text.trim().isEmpty || !_emailController.text.trim().contains("@")) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please enter a valid email to reset your password.", style: Styles.textFont), showCloseIcon: true, duration: Duration(seconds: 3), backgroundColor: Styles.red, behavior: SnackBarBehavior.floating, margin: EdgeInsets.all(20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Styles.white, width: 3))));
      return;
    }
    setState(() => isLoading = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: _emailController.text.trim().toLowerCase());
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Password reset email sent if your email is registered! Please check your inbox.", style: Styles.textFont), showCloseIcon: true, duration: Duration(seconds: 3), backgroundColor: Styles.accentColor, behavior: SnackBarBehavior.floating, margin: EdgeInsets.all(20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Styles.white, width: 3))));
    } catch (error) {
      switch (error) {
        // This error means the email address is invalid
        case "invalid-email":
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("The email address is invalid. Please try again.", style: Styles.textFont), showCloseIcon: true, duration: Duration(seconds: 3), backgroundColor: Styles.red, behavior: SnackBarBehavior.floating, margin: EdgeInsets.all(20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Styles.white, width: 3))));
          break;
        // Since email enumeration protection is set to true for the server, the following error should not occur, but it is included here should this change to ensure proper error handling
        case "user-not-found":
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("No account found for that email. Please check your email and try again.", style: Styles.textFont), showCloseIcon: true, duration: Duration(seconds: 3), backgroundColor: Styles.red, behavior: SnackBarBehavior.floating, margin: EdgeInsets.all(20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Styles.white, width: 3))));
          break;
        // This error would occur if the network fails while trying to make this request
        case "network-request-failed":
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Network error. Please check your connection and try again.", style: Styles.textFont), showCloseIcon: true, duration: Duration(seconds: 3), backgroundColor: Styles.red, behavior: SnackBarBehavior.floating, margin: EdgeInsets.all(20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Styles.white, width: 3))));
          break;
        default:
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("An unexpected error occurred. Please try again later.", style: Styles.textFont), showCloseIcon: true, duration: Duration(seconds: 3), backgroundColor: Styles.red, behavior: SnackBarBehavior.floating, margin: EdgeInsets.all(20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Styles.white, width: 3))));
          break;
      }
    } finally {
      setState(() => isLoading = false);
    }

  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

}