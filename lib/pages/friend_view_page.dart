import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:money2/money2.dart';
import 'package:penny_wise/model/connectivity_util.dart';
import 'package:penny_wise/model/currency_conversion.dart';
import 'package:penny_wise/model/document_snapshot_wrappers.dart';
import 'package:penny_wise/model/reading_streams.dart';
import 'package:penny_wise/styles.dart';
import 'package:provider/provider.dart';

class FriendViewPage extends StatefulWidget {
  const FriendViewPage({super.key});

  @override
  State<FriendViewPage> createState() => _FriendViewPage();

}

class _FriendViewPage extends State<FriendViewPage> {
  // Values from arguments
  String? _friendId;
  bool _argumentsLoaded = false;
  
  // Values from streams
  List<Map<String, dynamic>> _friends = [];
  Map<String, dynamic> _currentFriendship = {};
  String _friendUserName = "";
  double _totalDebtUSD = 0.0;
  late Money _totalDebtPreferredCurrency;
  List<Map<String, dynamic>> _expensesWithFriend = [];
  String _userPreferredCurrency = "USD";

  // UI Values
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _showPayFriendForm = false;

  // Input controllers
  final TextEditingController _amountController = TextEditingController();


  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // Get values from the arguments
    if (!_argumentsLoaded) {
      _friendId = ModalRoute.of(context)!.settings.arguments as String?;
      _argumentsLoaded = true;
    }
    // Always watch these streams
    final friendships = Provider.of<Friendships?>(context);
    final expensesStream = Provider.of<Expenses?>(context);
    final private = Provider.of<PrivateUser?>(context);
    // Wait for the streams to load
    if (friendships == null || expensesStream == null || private == null) {
      // Return temporary loading UI while loading
      return Scaffold(
        backgroundColor: Styles.backgroundColor,
        body: Center(child: CircularProgressIndicator(color: Styles.accentColor)),
      );
    }
    // Always sync from provider
    _friends = friendships.friends;
    _currentFriendship = _friends.firstWhere((friendship) => friendship["friendId"] == _friendId);
    _friendUserName = _currentFriendship["friendName"];
    _userPreferredCurrency = (private.data["preferredCurrency"] as String?) ?? "USD";
    _totalDebtUSD = (_currentFriendship["balanceUSD"] as num? ?? 0).toDouble();
    _totalDebtPreferredCurrency = Money.fromNum(
      CurrencyConversion.getInstance().convertFromUSD(_totalDebtUSD, _userPreferredCurrency),
      isoCode: _userPreferredCurrency,
    );
    final friendExpensesFromStream = expensesStream.expenses.where((expense) => (expense["isTripExpense"] == false));
    _expensesWithFriend = friendExpensesFromStream.where((expense) => (expense["friendshipsId"] as List).contains(_currentFriendship["friendshipId"])).toList();
    // TODO: replace with quicksort
    _expensesWithFriend.sort((a, b) => DateTime.parse(a["date"]).compareTo(DateTime.parse(b["date"])));

    // Return UI once loading is complete
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
              return Stack(
                children: [
                  if (_friendId != null) Positioned.fill(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.1),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          spacing: 10,
                          children: [
                            SizedBox(height: 105),
                            Text(_friendUserName, style: Styles.subTitleFont.copyWith(fontSize: 36, height: 1.0)),
                            Divider(color: Styles.grey, thickness: 3, height: 16),
                            if (_expensesWithFriend.isEmpty) Text("No expenses with this friend yet!", style: Styles.errorFont, textAlign: TextAlign.center),
                            if (_expensesWithFriend.isNotEmpty) ListView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: _expensesWithFriend.length,
                              itemBuilder: (context, index) {
                                final expense = _expensesWithFriend[index];
                                return ListTile(
                                  leading: Text(expense["name"] ?? "Unknown", style: Styles.textFont),
                                  // Change colour automatically based off if the debt is in the negative or not
                                  trailing:  Builder(
                                    builder: (context) {
                                      final balanceUSD = (expense["amountUSD"] as num? ?? 0).toDouble();
                                      return Text(
                                        Money.fromNum(
                                          CurrencyConversion.getInstance().convertFromUSD(balanceUSD, _userPreferredCurrency),
                                          isoCode: _userPreferredCurrency,
                                        ).toString(),
                                        style: Styles.textFont.copyWith(
                                          color: balanceUSD < 0 ? Styles.negativeColor : Styles.primaryColor,
                                          fontWeight: FontWeight.bold,
                                        )
                                      );
                                    }
                                  ),
                                  onTap: () {
                                    // Navigator.of(context).pushNamed(
                                    //   '/expenseView',
                                    //   arguments: expense["expenseId"]
                                    // );
                                  },
                                );
                              },
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // This button deletes the friendship
                                ElevatedButton.icon(
                                  onPressed: () async {await _deleteFriendship();},
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Styles.lighterBackgroundColor,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    side: BorderSide(color: Styles.red, width: 3),
                                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20)
                                  ),
                                  icon: Icon(Icons.delete, color: Styles.negativeColor,),
                                  label: Text("Delete Friendship", style: Styles.textFont.copyWith(color: Styles.negativeColor))
                                ),
                                SizedBox(width: 20),
                                ElevatedButton.icon(
                                  onPressed: () async {
                                      HapticFeedback.lightImpact();
                                      if (_totalDebtPreferredCurrency.isPositive) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text("You can't pay $_friendUserName, because they owe you!", style: Styles.textFont),
                                            showCloseIcon: true,
                                            duration: Duration(seconds: 3),
                                            backgroundColor: Styles.red,
                                            behavior: SnackBarBehavior.floating, margin: EdgeInsets.all(20),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              side: BorderSide(color: Styles.white, width: 3)
                                            )
                                          )
                                        );
                                      } else {
                                        setState(() {
                                            _showPayFriendForm = true;
                                        });
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Styles.primaryColor,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    side: BorderSide(color: Styles.accentColor, width: 3),
                                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20)
                                  ),
                                  icon: Icon(Icons.payments, color: Styles.accentColor),
                                  label: Text("Pay Friend", style: Styles.textFont.copyWith(color: Styles.accentColor))
                                ),
                              ]
                            )
                          ]
                        )
                      )
                    )
                  ),
                  if (_showPayFriendForm) Positioned.fill(
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
                                  Text("Pay $_friendUserName", style: Styles.subTitleFont.copyWith(fontSize: 36, height: 1.0)),
                                  TextFormField(
                                    controller: _amountController,
                                    decoration: Styles.textFieldDecoration.copyWith(labelText: "Payment Amount" , hintText: "00.00", hintStyle: Styles.numberFont.copyWith(fontSize: 50, color: Styles.grey)),
                                    style: Styles.textFont,
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty || double.tryParse(value) == null && double.tryParse(value)! <= 0) {
                                        return "Please enter a valid amount greater than 0!";
                                      } else if (((num.tryParse(value)) ?? 0.00).toDouble() > _totalDebtPreferredCurrency.toDouble()) {
                                        return "Too much! Please enter an amount less than the ${_totalDebtPreferredCurrency.amount.toString()} you owe!!";
                                      }
                                      return null;
                                    },
                                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                                    // Only allow digits and a decimal point followed by 0 to 2 other digits
                                    inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp(r"^\d+\.?\d{0,2}"))],
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
                                        onPressed: () => setState(() => _showPayFriendForm = false)
                                      ),
                                      SizedBox(width: 20),
                                      ElevatedButton.icon(
                                        icon: Icon(Icons.payments, color: Styles.accentColor),
                                        label: Text("Pay", style: Styles.textFont.copyWith(color: Styles.accentColor)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Styles.primaryColor,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                          side: BorderSide(color: Styles.accentColor, width: 3),
                                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20)
                                        ),
                                        onPressed: () async {
                                          if (_formKey.currentState!.validate()) {
                                            await _payFriend();
                                          }
                                        }
                                      )
                                    ]
                                  )
                                ]
                              )
                            )
                          )
                        )
                      )
                    )
                  ),
                  // If given friendId is null
                  if (_friendId == null) Center(child: Text("No friend selected!", style: Styles.headingFont.copyWith(color: Styles.negativeColor))),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Column(
                      children: [
                        ClipRect(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 8.5, sigmaY: 8.5),
                            child: Container(
                              color: Styles.backgroundColor.withValues(alpha: 0.5),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Row(
                                children: [
                                  SizedBox(width: 25),
                                  IconButton.filled(onPressed: () => Navigator.pop(context), icon: Icon(Icons.arrow_back, color: Styles.accentColor), style: IconButton.styleFrom(backgroundColor: Styles.primaryColor, side: BorderSide(color: Styles.accentColor, width: 2)), tooltip: "Profile Page"),
                                  Expanded(child: Text("Penny Wise", style: Styles.titleFont, textAlign: TextAlign.center)),
                                ]
                              ),
                            )
                          ),
                        ),
                        IgnorePointer(
                          child: Container(
                            height: 20,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                // Smooth fade out effect
                                stops: [0.0, 0.3, 0.6, 0.8, 1.0],
                                colors: [
                                  Styles.backgroundColor.withValues(alpha: 0.6),
                                  Styles.backgroundColor.withValues(alpha: 0.4),
                                  Styles.backgroundColor.withValues(alpha: 0.2),
                                  Styles.backgroundColor.withValues(alpha: 0.05),
                                  Styles.backgroundColor.withValues(alpha: 0.0)
                                ]
                              )
                            )
                          )
                        )
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

  Future<void> _deleteFriendship() async {
    // TODO: DELETE FROM FRIENDSHIPS COLLECTION
    // TODO: DELETE FROM ALL FIELDS IN EXPENSES
    await FirebaseFirestore.instance
      .collection("friendships")
      .doc(_currentFriendship["friendId"])
      .delete();
  }

  Future<void> _payFriend() async {
    final amountPaid = (num.tryParse(_amountController.text.trim()) ?? 0.0).toDouble();
    final amountPaidUSD = CurrencyConversion.getInstance().convertToUSD(amountPaid, _userPreferredCurrency);
    await FirebaseFirestore.instance
      .collection("friendships")
      .doc(_currentFriendship["friendId"])
      .update({"balanceUSD" : {
        FirebaseAuth.instance.currentUser!.uid : _totalDebtUSD + amountPaidUSD,
        _friendId : -1*_totalDebtUSD - amountPaidUSD
      }});
    if (await checkInternertConnection() == false) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No network connection. Your changes are saved locally, but connect to the internet soon please.", style: Styles.textFont), showCloseIcon: true, duration: Duration(seconds: 3), backgroundColor: Styles.red, behavior: SnackBarBehavior.floating, margin: EdgeInsets.all(20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Styles.white, width: 3)))
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Payment successful!", style: Styles.textFont), showCloseIcon: true, duration: Duration(seconds: 3), backgroundColor: Styles.accentColor, behavior: SnackBarBehavior.floating, margin: EdgeInsets.all(20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Styles.white, width: 3)))
      );
    }
    setState(() {
      _showPayFriendForm = false;
      _amountController.text = "";
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

}