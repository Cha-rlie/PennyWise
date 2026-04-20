import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:penny_wise/styles.dart';

class WelcomeUnauthenticatedPage extends StatefulWidget {
  const WelcomeUnauthenticatedPage({super.key});

  @override
  State<WelcomeUnauthenticatedPage> createState() => _WelcomeUnauthenticatedPageState();

}

class _WelcomeUnauthenticatedPageState extends State<WelcomeUnauthenticatedPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold( body: Container(color: Styles.backgroundColor,
      child: GestureDetector(onVerticalDragEnd: (details) {
        if (details.primaryVelocity != null) {
          if (details.primaryVelocity! < -200) {
            HapticFeedback.lightImpact();
            Navigator.pushNamed(context, '/logIn');
          } else if (details.primaryVelocity! > 200) {
            HapticFeedback.lightImpact();
            Navigator.pushNamed(context, '/signUp');
          }
        }
      },
      child:SafeArea(child: Stack(alignment: Alignment.center,
        children: [
          // Background color split
          SizedBox.expand(
            child: Column(children: [
              Expanded(child:Container(color: Styles.backgroundColor)),
              Expanded(child:Container(color: Styles.accentColor)),
            ],)
          ),
          // Title at the top
          Positioned(top: 0, child: Text("Penny Wise", style: Styles.titleFont)),
          // Vault image in the middle
          Center(child: ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0.5, 0.5],
              colors: [Styles.lighterBackgroundColor, Styles.primaryColor],
            ).createShader(bounds),
            child: Image.asset(
              'assets/images/vault.png',
              width: MediaQuery.of(context).size.width * 0.8,
              color: Styles.white, // must be white for shader mask to work as intended
              colorBlendMode: BlendMode.srcIn // ensures only non-transparent parts of the image are colored,
            ),
          )),
          // Buttons in the middle
          SizedBox.expand(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.keyboard_arrow_up, size: 100, color: Styles.lighterBackgroundColor),
                SizedBox(height: MediaQuery.of(context).size.height*0.15),
                ElevatedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.pushNamed(context, '/logIn');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Styles.lighterBackgroundColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: BorderSide(color: Styles.white, width: 3),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20)
                  ),
                  child: Text("Log In", style: Styles.headingFont)),
                  SizedBox(height: MediaQuery.of(context).size.height*0.05),
                  ElevatedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.pushNamed(context, '/signUp');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Styles.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: BorderSide(color: Styles.black, width: 3),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20)
                  ),
                  child: Text("Sign Up", style: Styles.headingFont.copyWith(color: Styles.black))),
                  SizedBox(height: MediaQuery.of(context).size.height*0.15),
                  Icon(Icons.keyboard_arrow_down, size: 100, color: Styles.primaryColor)
              ],
            ),
          ),
        ],
      ),
    ))));
  }
}