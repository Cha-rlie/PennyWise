import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:money2/money2.dart';
import 'package:penny_wise/model/document_snapshot_wrappers.dart';
import 'package:penny_wise/model/currency_conversion.dart';
import 'package:penny_wise/styles.dart';
import 'package:provider/provider.dart';

class TripsPage extends StatefulWidget {
  const TripsPage({super.key});

  @override
  State<TripsPage> createState() => _TripsPageState();
}

class _TripsPageState extends State<TripsPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _showMakeTripForm = false;
  String _friendSearchError = "";
  String _tripFormError = "";
  String _userPreferredCurrency = "";
  List<Map<String, dynamic>> _trips = [];
  List<Map<String, dynamic>> _friends = [];

  // Input controllers
  final TextEditingController _tripNameController = TextEditingController();
  final TextEditingController _tripDescriptionController = TextEditingController();
  final TextEditingController _defaultCurrencyController = TextEditingController();
  final TextEditingController _nameSearchController = TextEditingController();
  List<String> _friendsSelected = [];

  // Preload all currencies
  final List<Currency> _currencies = Currencies().getRegistered().toList();

  @override
  Widget build(BuildContext context) {
    // Always watch these streams
    final tripsStream = Provider.of<Trips?>(context);
    final friendsStream = Provider.of<Friendships?>(context);
    final private = Provider.of<PrivateUser?>(context);
    // Wait for the streams to load
    if (tripsStream == null || friendsStream == null || private == null) {
      // Return temporary loading UI while loading
      return Scaffold(
        backgroundColor: Styles.backgroundColor,
        body: Center(child: CircularProgressIndicator(color: Styles.accentColor)),
      );
    }
    // Always sync from provider
    _trips = tripsStream.trips;
    _friends = friendsStream.friends;
    _userPreferredCurrency = (private.data["preferredCurrency"] as String?) ?? "USD";
    // Set the currency controller to be the initial selected currency, but only when it is empty on a build (1st time only likely)
    if (_defaultCurrencyController.text.isEmpty) {
      _defaultCurrencyController.text = _userPreferredCurrency;
    }
    
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
                Text("Trip Debts", style: Styles.subTitleFont.copyWith(fontSize: 36, height: 1.0)),
                Divider(color: Styles.grey, thickness: 3, height: 16),
                if (_trips.isEmpty) Text("No trips found! Make trips to easily split expenses with lots of friends.", style: Styles.errorFont, textAlign: TextAlign.center),
                if (_trips.isNotEmpty) Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  spacing: 10,
                  children: [
                    for (Map<String, dynamic> trip in _trips) Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(trip["tripName"] ?? "Unknown", style: Styles.textFont),
                        // Change colour automatically based off if the debt is in the negative or not
                        // Change colour automatically based off if the debt is in the negative or not
                        Builder(
                          builder: (context) {
                            final balanceUSD = (trip["balanceUSD"] as num? ?? 0).toDouble();
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
                    setState(() => _showMakeTripForm = true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Styles.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    side: BorderSide(color: Styles.accentColor, width: 3),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20)
                  ),
                  icon: Icon(Icons.add, color: Styles.accentColor),
                  label: Text("Trip", style: Styles.headingFont.copyWith(color: Styles.accentColor))
                )
              ]
            )
          ),
          if (_showMakeTripForm) Positioned(
            top: 100,
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Styles.lighterBackgroundColor.withValues(alpha: 0.7),
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 32),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.75,
                      maxWidth: 600,
                      minWidth: min(MediaQuery.of(context).size.width * 0.8, 600)
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Styles.backgroundColor,
                        border: Border.all(color: Styles.white, width: 3),
                        borderRadius: BorderRadius.circular(20)
                      ),
                      padding: EdgeInsets.all(24),
                      child: SingleChildScrollView(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            spacing: 24,
                            children: [
                              Text("Make a Trip", style: Styles.subTitleFont.copyWith(fontSize: 36, height: 1.0)),
                              TextFormField(
                                controller: _tripNameController,
                                decoration: Styles.textFieldDecoration.copyWith(labelText: "Trip Name", helperText: "Short memorable name for your trip"),
                                style: Styles.textFont,
                                validator: (value) => (value != null && value.trim().isNotEmpty) ? null : "Please enter a trip name!",
                              ),
                              TextFormField(
                                controller: _tripDescriptionController,
                                decoration: Styles.textFieldDecoration.copyWith(labelText: "Trip Description", helperText: "What is this trip for?"),
                                style: Styles.textFont,
                                validator: (value) => (value != null && value.trim().isNotEmpty) ? null : "Please enter a trip description!",
                              ),
                              // Default currency picker
                              DropdownMenuFormField(
                                controller: _defaultCurrencyController,
                                label: Text("Default Currency", style: Styles.headingFont),
                                helperText: "Select your default currency",
                                dropdownMenuEntries: List<DropdownMenuEntry<String>>.from(
                                  _currencies.map(
                                    (currency) => DropdownMenuEntry(
                                      value: currency.isoCode,
                                      label: currency.isoCode,
                                      labelWidget: Text("${currency.isoCode}: ${currency.name}", style: Styles.textFont))
                                  )
                                ),
                                initialSelection: _defaultCurrencyController.text,
                                menuHeight: 300,
                                requestFocusOnTap: true,
                                textStyle: Styles.textFont,
                                inputDecorationTheme: Styles.dropdownMenuDecorationTheme,
                                menuStyle: Styles.dropdownMenuStyle,
                                trailingIcon: Icon(Icons.keyboard_arrow_down, color: Styles.white),
                                selectedTrailingIcon: Icon(Icons.keyboard_arrow_up, color: Styles.white),
                                //width: MediaQuery.of(context).size.width*0.8,
                                validator: (value) => _currencies.map((currency) {
                                  return currency.isoCode;
                                }).contains(_defaultCurrencyController.text.trim()) ? null : "Currency entered is not a valid currency! Use the drop down menu for convienience."
                              ),
                              if (_friends.isEmpty) Text("You have no friends to add. Go add some in the Friends page!", style: Styles.errorFont),
                              if (_friends.isNotEmpty) Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(child:TextFormField(
                                    controller: _nameSearchController,
                                    style: Styles.textFont,
                                    decoration: Styles.textFieldDecoration.copyWith(labelText: "Search username", hintText: "Search for friends to add by usernames"),
                                  )),
                                  SizedBox(width: 10),
                                  IconButton.filled(
                                    icon: Icon(Icons.person_search, color: Styles.accentColor),
                                    style: IconButton.styleFrom(backgroundColor: Styles.primaryColor,
                                    side: BorderSide(color: Styles.accentColor, width: 2)),
                                    tooltip: "Search for friend",
                                    onPressed: () async {validateAndAddFriend();}
                                  )
                                ]
                              ),
                              if (_friendSearchError.isNotEmpty) Text(_friendSearchError, style: Styles.errorFont),
                              if (_friendsSelected.isNotEmpty) Container(
                                decoration: BoxDecoration(
                                  color: Styles.backgroundColor,
                                  border: Border.all(color: Styles.white, width: 1.5),
                                  borderRadius: BorderRadius.circular(20)
                                ),
                                padding: EdgeInsets.all(10),
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: _friendsSelected.map((friend) {
                                    return Chip(
                                      label: Text(friend, style: Styles.textFont),
                                      deleteIcon: Icon(Icons.close, color: Styles.white),
                                      backgroundColor: Styles.accentColor,
                                      onDeleted: () {
                                        HapticFeedback.lightImpact();
                                        setState(() {
                                          // Dispose of the controller before disposing to prevent memory leaks
                                          _friendsSelected.remove(friend);
                                        });
                                      },
                                    );
                                  }).toList(),
                                ),
                              ),
                              if (_tripFormError.isNotEmpty) Text(_tripFormError, style: Styles.errorFont),
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
                                    onPressed: () => setState(() => _showMakeTripForm = false)
                                  ),
                                  SizedBox(width: 20),
                                  ElevatedButton.icon(
                                    icon: Icon(Icons.group_add, color: Styles.accentColor),
                                    label: Text("Make", style: Styles.textFont.copyWith(color: Styles.accentColor)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Styles.primaryColor,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                      side: BorderSide(color: Styles.accentColor, width: 3),
                                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20)
                                    ),
                                    onPressed: () => saveNewTrip()
                                  ),
                                ],
                              ),
                            ],
                          )
                        )
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

  void validateAndAddFriend() {
    final inputUsername = _nameSearchController.text.trim();
    // Handle no input
    if (inputUsername.isEmpty) {
      setState(() => _friendSearchError = "Make sure you type a name!");
      return;
    }
    // Handle already selected to be in trip
    if (_friendsSelected.contains(inputUsername)) {
      setState(() => _friendSearchError = "This user is already in the trip!");
      return;
    }
    // Search for a friend with matching username
    // Handle not a friend
    if (!_friends.any((friend) => friend["friendName"] == inputUsername)) {
      setState(() => _friendSearchError = "This user is not in your friends list. Try again!");
      return;
    }
    // Handle they are a friend valid to be added to the trip
    setState(() {
      _friendsSelected.add(inputUsername);
      _friendSearchError = "";
      // Reset the text in the search bar
      _nameSearchController.text = "";
    });
    return;
  }

  Future<void> saveNewTrip() async {
    // Handle invalid input
    if (!_formKey.currentState!.validate()) {
      return;
    }
    // Handle insufficient friends selected
    if (_friendsSelected.length < 2) {
      setState(() => _tripFormError = "You need at least 2 friends to make a trip!");
      return;
    }
    // Handle all inputs valid
    if (_tripFormError != "") {
      // is setting a state ok while doing other stuff?
      setState(() => _tripFormError = "");
    }
    // Process and generate information in advance
    final memberIds = [
      FirebaseAuth.instance.currentUser!.uid, // Include current user
      ..._friendsSelected.map((friend) { // Include Ids from all the selected friends
        return _friends.firstWhere((friendFromStream) => friendFromStream["friendName"] == friend)["friendId"] as String;
      })
    ];
    final Map<String, double> debts = {
      for (var friendId in memberIds)
        friendId: 0.0
    };
    // Save trip to the database
    await FirebaseFirestore.instance
      .collection("trips")
      .doc()
      .set(
        {
          "name": _tripNameController.text.trim(),
          "description": _tripDescriptionController.text.trim(),
          "members": memberIds,
          "totalDebt": debts,
          "createdAt": FieldValue.serverTimestamp(),
        }
      );
    // User is found and friending is successful
    if (!mounted) return;
    setState(() {
      _friendSearchError = "";
      _showMakeTripForm = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Trip made successfully!",
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
  }

}