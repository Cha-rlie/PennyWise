import 'package:penny_wise/model/currency_conversion.dart';
import 'package:penny_wise/model/data_handling_util.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:money2/money2.dart';
import 'package:penny_wise/model/document_snapshot_wrappers.dart';
import 'package:penny_wise/styles.dart';
import 'package:provider/provider.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _showAddFriendForm = false;
  String _friendSearchError = "";
  List<Map<String, dynamic>> _friends = [];
  String _userPreferredCurrency = "";

  // Input controllers
  final TextEditingController _nameSearchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // Always watch these streams
    final friendships = Provider.of<Friendships?>(context);
    final private = Provider.of<PrivateUser?>(context);
    // Wait for the streams to load
    if (friendships == null || private == null) {
      // Return temporary loading UI while loading
      return Scaffold(
        backgroundColor: Styles.backgroundColor,
        body: Center(child: CircularProgressIndicator(color: Styles.accentColor)),
      );
    }
    // Always sync from provider
    _friends = friendships.friends;
    _userPreferredCurrency = (private.data["preferredCurrency"] as String?) ?? "USD";

    // Return UI
    return SizedBox.expand(
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.1),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              spacing: 10,
              children: [
                SizedBox(height: 105),
                Text("Friend Debts", style: Styles.subTitleFont.copyWith(fontSize: 36, height: 1.0)),
                Divider(color: Styles.grey, thickness: 3, height: 16),
                if (_friends.isEmpty) Text("No friends found! Add friends to your account to easily split expenses with them.", style: Styles.errorFont, textAlign: TextAlign.center),
                if (_friends.isNotEmpty) Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  spacing: 10,
                  children: [
                    for (Map<String, dynamic> friend in _friends) Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(friend["friendName"] ?? "Unknown", style: Styles.textFont),
                        // Change colour automatically based off if the debt is in the negative or not
                        Builder(
                          builder: (context) {
                            final balanceUSD = (friend["balanceUSD"] as num? ?? 0).toDouble();
                            return Text(
                              Money.fromNum(
                                CurrencyConversion.getInstance().convertFromUSD(balanceUSD, _userPreferredCurrency),
                                isoCode: _userPreferredCurrency,
                              ).toString(),
                              style: Styles.textFont.copyWith(
                                color: balanceUSD < 0 ? Styles.red : Styles.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                        )
                      ]
                    )
                  ]
                ),
                SizedBox(height: 30),
                // Button to add a friend
                ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    setState(() => _showAddFriendForm = true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Styles.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    side: BorderSide(color: Styles.accentColor, width: 3),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20)
                  ),
                  icon: Icon(Icons.add, color: Styles.accentColor),
                  label: Text("Friend", style: Styles.headingFont.copyWith(color: Styles.accentColor))
                )
              ]
            )
          ),
          if (_showAddFriendForm) Positioned.fill(
            child: Container(
              color: Styles.lighterBackgroundColor.withValues(alpha: 0.7),
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 32),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Styles.backgroundColor,
                      border: Border.all(color: Styles.white, width: 3),
                      borderRadius: BorderRadius.circular(20)
                    ),
                    padding: EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        spacing: 10,
                        children: [
                          Text("Find Friends", style: Styles.subTitleFont.copyWith(fontSize: 36, height: 1.0)),
                          TextFormField(
                            controller: _nameSearchController,
                            style: Styles.textFont,
                            decoration: Styles.textFieldDecoration.copyWith(labelText: "Search username"),
                            validator: (value) => (value != null && value.trim().isNotEmpty) ? null : "Please enter a username to search for",
                          ),
                          SizedBox(height: 5),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                icon: Icon(Icons.close, color: Styles.negativeColor),
                                label: Text("Cancel", style: Styles.textFont.copyWith(color: Styles.negativeColor)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Styles.lighterBackgroundColor,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  side: BorderSide(color: Styles.red, width: 3),
                                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20)
                                ),
                                onPressed: () => setState(() => _showAddFriendForm = false)
                              ),
                              SizedBox(width: 20),
                              ElevatedButton.icon(
                                icon: Icon(Icons.person_search, color: Styles.accentColor),
                                label: Text("Search", style: Styles.textFont.copyWith(color: Styles.accentColor)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Styles.primaryColor,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  side: BorderSide(color: Styles.accentColor, width: 3),
                                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20)
                                ),
                                onPressed: () async {
                                  if (_formKey.currentState!.validate()) {
                                    try {
                                      final usernameSearchQuery = await FirebaseFirestore.instance
                                        .collection("public-users")
                                        .where("username", isEqualTo: _nameSearchController.text.trim())
                                        .limit(1) // Ensure returned query only has 1 result since usernames are unique
                                        .get();
                                      if (usernameSearchQuery.docs.isEmpty) {
                                        // User not found
                                        setState(() => _friendSearchError = "No user found with that username! Try again!");
                                      } else {
                                        final newFriendUser = usernameSearchQuery.docs.first;
                                        final checkAlreadyFriend = await FirebaseFirestore.instance
                                          .collection("friendships")
                                          .where("membersKey", isEqualTo: DataHandlingUtil.generateFriendshipMembersKey(FirebaseAuth.instance.currentUser!.uid, newFriendUser.id))
                                          .get();
                                        if (checkAlreadyFriend.docs.isEmpty) { // Not already friends
                                          // Surround the checking of their acceptingNewFriends value with a catch just in case their field is missing
                                          final acceptingNewFriends = newFriendUser.data()["acceptingNewFriends"] as bool? ?? false;
                                          if (acceptingNewFriends) {
                                            await FirebaseFirestore.instance
                                              .collection("friendships")
                                              .doc()
                                              .set(
                                                {
                                                  "members": [FirebaseAuth.instance.currentUser!.uid, newFriendUser.id],
                                                  "membersKey": DataHandlingUtil.generateFriendshipMembersKey(FirebaseAuth.instance.currentUser!.uid, newFriendUser.id),
                                                  "createdAt": FieldValue.serverTimestamp(),
                                                  "totalDebt": {FirebaseAuth.instance.currentUser!.uid: 0.0, newFriendUser.id: 0.0},
                                                }
                                              );
                                            // User is found and friending is successful
                                            setState(() {
                                              _friendSearchError = "";
                                              _showAddFriendForm = false;
                                            });
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text("Friend added successfully!",
                                                style: Styles.textFont),
                                                showCloseIcon: true,
                                                duration: Duration(seconds: 3),
                                                backgroundColor: Styles.accentColor,
                                                behavior: SnackBarBehavior.floating,
                                                margin: EdgeInsets.all(20),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12),
                                                side: BorderSide(color: Styles.white, width: 3))
                                              )
                                            );
                                          } else {
                                            // User exists but not accepting new friends
                                            setState(() => _friendSearchError = "Sorry! That user is not accepting new friend requests right now.");
                                          }
                                        } else {
                                          // User is already a friend
                                          setState(() => _friendSearchError = "You are already friends with that user!");
                                        }
                                      }
                                    } catch (e) {
                                      setState(() {
                                        _friendSearchError = "An error occurred: ${e.toString()}";
                                      });
                                    }
                                  }
                                }
                              ),
                            ],
                          ),
                          if (_friendSearchError.isNotEmpty) Text(_friendSearchError, style: Styles.errorFont)
                        ],
                      )
                    )
                  )
                )
              )
            )
          )
        ]
      )
    );
  }

  @override
  void dispose() {
    _nameSearchController.dispose();
    super.dispose();
  }

}