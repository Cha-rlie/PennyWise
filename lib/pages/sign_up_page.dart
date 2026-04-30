import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:penny_wise/styles.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();

}

class _SignUpPageState extends State<SignUpPage> {
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
              _signUp();
            }
          }
        }
      },
      child: Scaffold(backgroundColor: Styles.accentColor, body: SafeArea(child: LayoutBuilder(
        builder:(context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
        return SingleChildScrollView(child: ConstrainedBox(constraints: BoxConstraints(minHeight: constraints.maxHeight), child: IntrinsicHeight(child:Stack(alignment: Alignment.center,
          children: [
            Center(child: Image.asset(
              "assets/images/vault.png",
              width: width * 0.8,
              color: Styles.primaryColor,
              colorBlendMode: BlendMode.srcIn,
            )),
            Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Positioned.fill(top: 0, child: Row(mainAxisSize: MainAxisSize.max, mainAxisAlignment: MainAxisAlignment.start, children: [
                IconButton(onPressed: () {HapticFeedback.lightImpact(); Navigator.pop(context);}, icon: Icon(Icons.keyboard_arrow_left, color: Styles.primaryColor, size: 90), style: IconButton.styleFrom(backgroundColor: Styles.accentColor),padding: EdgeInsets.symmetric(horizontal: 0, vertical: 0), tooltip: "Back Button"),
                Expanded(child:Text("Penny Wise", style: Styles.titleFont, textAlign: TextAlign.center)),
                SizedBox(width: width*0.1),
              ]))]),
              // Documentation on form: https://api.flutter.dev/flutter/widgets/Form-class.html
            Positioned(top: height * 0.41, child: Container(width: width * 0.8, child: Column(children: [
              Form(key:_formKey, autovalidateMode: AutovalidateMode.onUnfocus, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              TextFormField(
                controller: _emailController,
                decoration: Styles.blackTextFieldDecoration.copyWith(labelText: "Email"),
                style: Styles.textFont.copyWith(color: Styles.black),
                validator: (value) {
                  return (value != null && value.trim().isNotEmpty && value.contains("@")) ? null : "Please enter a valid email";
                },
              ),
              SizedBox(height: height*0.05),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                style: Styles.textFont.copyWith(color: Styles.black),
                decoration: Styles.blackTextFieldDecoration.copyWith(labelText: "Password"),
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    if (value.trim().length >= 6) {
                      if (value.contains(RegExp(r'[A-Z]'))) {
                        if (value.contains(RegExp(r'[a-z]'))) {
                          if (value.contains(RegExp(r'[0-9]'))) {
                            if (value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
                            return null;
                          } else {return "Password must contain at least one special character";}
                        } else {return "Password must contain at least one number";}
                      } else {return "Password must contain at least one lowercase letter";}
                    } else {return "Password must contain at least one uppercase letter";}
                  } else {return "Password must be at least 6 characters long";}
                } else {return "Don't forget to enter your password!";}
              },
              ),
              SizedBox(height: height*0.175),
              Stack(alignment: Alignment.center, clipBehavior: Clip.none, children: [
              ElevatedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    if (_formKey.currentState != null && _formKey.currentState!.validate()) {
                      _signUp();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Styles.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: BorderSide(color: Styles.black, width: 3),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20)
                  ),
                  child: Text("Sign Up", style: Styles.headingFont.copyWith(color: Styles.black))),
                Positioned(
                  left: 125,
                  child: Icon(Icons.keyboard_arrow_right, size: 100, color: Styles.primaryColor),
                ),
              ]),
            ])),
            ]),
        // TODO: Animation but only when isLoading is true
        ))]))));
      })
      ))
    );
  }

  // Documentation on Email-Password Firebase authentication: https://firebase.google.com/docs/auth/flutter/password-auth
  Future<void> _signUp() async {
    setState(() => isLoading = true);
    try {
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim().toLowerCase(),
        password: _passwordController.text
      );
      final user = credential.user!;
      await FirebaseFirestore.instance
        .collection("public-users")
        .doc(user.uid)
        .set({
          "email": user.email,
           // default username is the part of the email before the @
           //this can be changed in the Profile page after signing up
          "username": user.email!.split("@")[0],
          "requireFriendApproval": false,
        });
      await FirebaseFirestore.instance
        .collection("private-users")
        .doc(user.uid)
        .set({
          "totalDebt": 0.0,
          "preferredCurrency": "USD"
        });  
      setState(() => isLoading = false);
      Navigator.popAndPushNamed(context, "/mainApp");
    } on FirebaseAuthException catch (error) {
      setState(() => isLoading = false);
      switch (error.code) {
        case "invalid-email":
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("The email address is invalid. Please try again.", style: Styles.textFont), showCloseIcon: true, duration: Duration(seconds: 3), backgroundColor: Styles.red, behavior: SnackBarBehavior.floating, margin: EdgeInsets.all(20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Styles.white, width: 3))));
          break;
        // This error would occur if the network fails while trying to make this request
        case "network-request-failed":
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Network error. Please check your connection and try again.", style: Styles.textFont), showCloseIcon: true, duration: Duration(seconds: 3), backgroundColor: Styles.red, behavior: SnackBarBehavior.floating, margin: EdgeInsets.all(20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Styles.white, width: 3))));
          break;
        case "weak-password":
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("The password is too weak. Please choose a stronger password and try again.", style: Styles.textFont), showCloseIcon: true, duration: Duration(seconds: 3), backgroundColor: Styles.red, behavior: SnackBarBehavior.floating, margin: EdgeInsets.all(20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Styles.white, width: 3))));
          break;
        case "email-already-in-use":
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("An account with this email already exists. Please log in or use a different email to sign up.", style: Styles.textFont), showCloseIcon: true, duration: Duration(seconds: 3), backgroundColor: Styles.red, behavior: SnackBarBehavior.floating, margin: EdgeInsets.all(20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Styles.white, width: 3))));
          break;
        default:
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("An unexpected error occurred. Please try again later.", style: Styles.textFont), showCloseIcon: true, duration: Duration(seconds: 3), backgroundColor: Styles.red, behavior: SnackBarBehavior.floating, margin: EdgeInsets.all(20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Styles.white, width: 3))));
          break;
      }
    }
  }
}