import 'package:penny_wise/model/currency_conversion.dart';
import 'package:penny_wise/model/reading_streams.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:money2/money2.dart';
import 'package:penny_wise/model/document_snapshot_wrappers.dart';
import 'package:penny_wise/styles.dart';
import 'package:provider/provider.dart';

class TripsPage extends StatefulWidget {
  const TripsPage({super.key});

  @override
  State<TripsPage> createState() => _TripsPageState();
}

class _TripsPageState extends State<TripsPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _areStreamsLoaded = false;
  bool _showMakeTripForm = false;
  String _friendSearchError = "";
  String _tripFormError = "";
  List<Map<String, dynamic>> _trips = [];
  List<Map<String, dynamic>> _friends = [];

  // Input controllers
  final TextEditingController _tripNameController = TextEditingController();
  final TextEditingController _tripDescriptionController = TextEditingController();
  final TextEditingController _currencyController = TextEditingController();
  final TextEditingController _nameSearchController = TextEditingController();
  List<String> _friendsSelected = [];

  @override
  Widget build(BuildContext context) {
    // Wait for the streams to load
    if (!_areStreamsLoaded) {
      // Get initial values
      final rawTripsFromStream = Provider.of<Trips?>(context);
      final friendsStream = Provider.of<Friendships?>(context);
      final private = Provider.of<PrivateUser?>(context);
      if (rawTripsFromStream != null && private != null && friendsStream != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          // Fetch all usernames and trip info from friendships stream in advance
          final trips = await Future.wait(
            rawTripsFromStream.documents.map((document) async {
              final data = document.data() as Map<String, dynamic>;

              // Get the memberIds of everyone else except the current user
              final memberIds = List<String>.from((data["members"] as List).map((member) => member.toString()));
              memberIds.remove(ReadingStreams.getInstance().userId);
              
              // Get money and convert it to default currency
              final debtInUSD = ((data["totalDebt"] as Map?)?[FirebaseAuth.instance.currentUser!.uid] as num?)?.toDouble() ?? 0.0;
              final userPreferredCurrency = (private.data["preferredCurrency"] as String?) ?? "USD";
              final convertedDebt = CurrencyConversion.getInstance().convertFromUSD(debtInUSD, userPreferredCurrency);
              // Format using Money2
              final formattedConvertedDebt = Money.fromNum(convertedDebt, isoCode: userPreferredCurrency);
              return {
                "tripId": document.id,
                "tripName": data["name"],
                "balance": formattedConvertedDebt,
                "memberIds": memberIds
              };
            }).toList()
          );

          setState(() {
            _nameSearchController.text = "";
            _trips = trips;
            _friends = friendsStream.friends;
            _areStreamsLoaded = true;
          });
        });
        return Scaffold(
          backgroundColor: Styles.backgroundColor,
          body: Center(child: CircularProgressIndicator(color: Styles.accentColor)),
        );
      }
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
                        Text((trip["balance"] as Money).toString(), style: Styles.textFont.copyWith(color: (trip["balance"] as Money).isNegative ? Styles.red : Styles.primaryColor, fontWeight: FontWeight.bold))
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
          if (_showMakeTripForm) Positioned.fill(
            child: Container(
              color: Styles.lighterBackgroundColor.withValues(alpha: 0.7),
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 32),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.75,
                      maxWidth: 600,
                      minWidth: MediaQuery.of(context).size.width * 0.8
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
                            spacing: 10,
                            children: [
                              Text("Make a Trip", style: Styles.subTitleFont.copyWith(fontSize: 36, height: 1.0)),
                              TextFormField(
                                controller: _tripNameController,
                                decoration: Styles.textFieldDecoration.copyWith(labelText: "Trip Name"),
                                style: Styles.textFont,
                                validator: (value) => (value != null && value.trim().isNotEmpty) ? null : "Please enter a trip name!",
                              ),
                              TextFormField(
                                controller: _tripDescriptionController,
                                decoration: Styles.textFieldDecoration.copyWith(labelText: "Trip Description"),
                                style: Styles.textFont,
                                validator: (value) => (value != null && value.trim().isNotEmpty) ? null : "Please enter a trip description!",
                              ),
                              if (_friends.isEmpty) Text("You have no friends to add. Go add some in the Friends page!", style: Styles.errorFont),
                              if (_friends.isNotEmpty) Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(child:TextFormField(
                                    controller: _nameSearchController,
                                    style: Styles.textFont,
                                    decoration: Styles.textFieldDecoration.copyWith(labelText: "Search username"),
                                    validator: (value) => (value != null && value.trim().isNotEmpty) ? null : "Please enter a username to search for",
                                  )),
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
                              SizedBox(height: 5),
                              if (_friendsSelected.isNotEmpty) Container(
                                decoration: BoxDecoration(
                                  color: Styles.backgroundColor,
                                  border: Border.all(color: Styles.white, width: 1.5),
                                  borderRadius: BorderRadius.circular(20)
                                ),
                                padding: EdgeInsets.all(6),
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
                                  if (_tripFormError.isNotEmpty) Text(_tripFormError, style: Styles.errorFont)
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
    });
    return;
  }

  void saveNewTrip() {
    // Handle invalid input
    if (!_formKey.currentState!.validate()) {
      return;
    }
    // Handle insufficient friends selected
    if (_friendsSelected.length < 2) {
      setState(() => _tripFormError = "You need at least 2 friends to make a trip!");
      return;
    }
    if (_tripFormError != "") {
      // is setting a state ok while doing other stuff?
      setState(() => _tripFormError = "");
    }
    // friendId = _friends.firstWhere((friend) => friend["friendName"] == inputUsername)["friendId"];
  }

}