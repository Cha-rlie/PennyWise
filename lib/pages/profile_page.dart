import 'package:flutter/material.dart';
import 'package:penny_wise/styles.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();

}
// TODO: add gesture to go back :D
class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    return SafeArea( child: Scaffold(backgroundColor: Styles.backgroundColor,
      body: Column(
        children: [
          Row(children: [
              SizedBox(width: 25),
              IconButton.filled(onPressed: () => Navigator.pop(context), icon: Icon(Icons.arrow_back, color: Styles.accentColor), style: IconButton.styleFrom(backgroundColor: Styles.primaryColor, side: BorderSide(color: Styles.accentColor, width: 2)), tooltip: "Profile Page"),
              Expanded(child: Text("Penny Wise", style: Styles.titleFont, textAlign: TextAlign.center)),
            ]),
          Expanded(
            child: Text("Profile Page", style: Styles.titleFont)
          ),
        ],
      ),
    ));
  }
}