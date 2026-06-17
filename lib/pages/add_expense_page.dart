import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:money2/money2.dart';
import 'package:penny_wise/model/currency_conversion.dart';
import 'package:penny_wise/model/document_snapshot_wrappers.dart';
import 'package:penny_wise/styles.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class AddExpensePage extends StatefulWidget {
  const AddExpensePage({super.key});

  @override
  State<AddExpensePage> createState() => _AddExpensePageState();

}

class _AddExpensePageState extends State<AddExpensePage> {
  // Form key used given to all form widgets to validate entire form in one go
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Number formatter
  var numberFormatter = NumberFormat("#,###.##");

  // Lists that will be filled by streams
  List<Map<String, dynamic>> _trips = [];
  List<Map<String, dynamic>> _friends = [];

  // Values that need to be kept track of
  List<String> _selectedFriends = [];
  List<String> _expenseParticipants = ["You"];
  List<String> _tripMemberIds = [];
  Map<String, String> _fetchedTripNonFriendIdUsernameMap = {};
  bool _isTripExpense = false;
  String _userPreferredCurrency = "";
  bool _firstBuild = true;
  DateTime _expenseDate = DateTime.now();

  // Error message values
  String _friendSearchError = "";

  // Input controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _defaultCurrencyController = TextEditingController(text: "USD");
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _dateController = TextEditingController(text: DateFormat('dd/MM/yyyy').format(DateTime.now()));
  final TextEditingController _tripController = TextEditingController();
  final TextEditingController _nameSearchController = TextEditingController();
  final TextEditingController _expenseSplitStrategyController = TextEditingController(text: "Evenly");
  final TextEditingController _payingParticipantController = TextEditingController();
  final Map<String, TextEditingController> _amountPerParticipantControllers = {};
  
  // Preload all currencies
  final List<Currency> _currencies = Currencies().getRegistered().toList();

  @override
  void initState() {
    super.initState();
    // Create listeners so updates are instant on value changes to these controllers
    _nameController.addListener(() => setState(() {}));
    _amountController.addListener(() => setState(() {}));
    _expenseSplitStrategyController.addListener(() => setState(() {}));
    _defaultCurrencyController.addListener(() => setState(() {}));
    _tripController.addListener(updateExpenseParticipants);
  }

  @override
  Widget build(BuildContext context) {
    // Always watch these streams
    final tripsStream = Provider.of<Trips?>(context);
    final friendsStream = Provider.of<Friendships?>(context);
    final private = Provider.of<PrivateUser?>(context);

    // Wait for the streams to load
    if (tripsStream == null || friendsStream == null || private == null) {
      // Return temporary loading UI while loading streams
      return Scaffold(
          backgroundColor: Styles.backgroundColor,
          body: Center(child: CircularProgressIndicator(color: Styles.accentColor)),
      );
    }

    // Set some controllers to have initial values on the first build
    if (_firstBuild) {
      _firstBuild = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _userPreferredCurrency = (private.data["preferredCurrency"] as String?) ?? "USD";
        _defaultCurrencyController.text = _userPreferredCurrency;
      });
    }

    // Always sync from provider
    _trips = tripsStream.trips;
    _friends = friendsStream.friends;
    _userPreferredCurrency = (private.data["preferredCurrency"] as String?) ?? "USD";

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.1),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            spacing: 10,
            children: [
              SizedBox(height: 100), // Top padding
              Text("Create Expense", style: Styles.subTitleFont.copyWith(fontSize: 36, height: 1.0)),
              Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUnfocus,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  spacing: 24,
                  children: [
                    Column(
                      children: [
                        IntrinsicWidth(
                          child: TextFormField(
                            controller: _nameController,
                            textAlign: TextAlign.center,
                            decoration: Styles.plainTextFieldDecoration.copyWith(hintText: "Name..."),
                            style: Styles.subTitleFont,
                            validator: (value) {
                              return (value != null && value.trim().isNotEmpty) ? null : "Please enter a full name";
                            },
                          )
                        ),
                        // Underline for the text that automatically adjusts to text size
                        AnimatedContainer(
                          duration: Duration(milliseconds: 200),
                          height: 2.0,
                          width: (() {
                            final textPainter = TextPainter(
                              text: TextSpan(text: _nameController.text.isEmpty ? "Name..." : _nameController.text, style: Styles.subTitleFont),
                              textDirection: ui.TextDirection.ltr
                            )..layout();
                            return textPainter.width + 14;
                          })(),
                          color: _nameController.text.isEmpty ? Styles.grey : Styles.accentColor
                        )
                      ]
                    ),
                    Row(
                      children: [
                        // Symbol for the currency
                        Text(
                          _currencies.firstWhere((currency) => currency.isoCode == (_defaultCurrencyController.text.isNotEmpty ? _defaultCurrencyController.text : "USD"), orElse: () => Currency.create((_defaultCurrencyController.text.isNotEmpty ? _defaultCurrencyController.text : "USD"), 2)).symbol,
                          style: Styles.numberFont.copyWith(fontSize: 50, color: (_amountController.text.trim().isEmpty) ? Styles.grey : Styles.accentColor)
                        ),
                        // Value of the expense
                        Expanded(child: TextFormField(
                          controller: _amountController,
                          decoration: Styles.plainTextFieldDecoration.copyWith(hintText: "00.00", hintStyle: Styles.numberFont.copyWith(fontSize: 50, color: Styles.grey)),
                          style: Styles.numberFont.copyWith(fontSize: 50),
                          validator: (value) {
                            return (value != null && value.trim().isNotEmpty && double.tryParse(value) != null && double.tryParse(value)! > 0) ? null : "Please enter a valid amount greater than 0";
                          },
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          // Only allow digits and a decimal point followed by 0 to 2 other digits
                          inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp(r"^\d+\.?\d{0,2}"))],
                        )),
                        // Dropdown for the currency
                        Flexible(child: DropdownMenuFormField(
                          controller: _defaultCurrencyController,
                          dropdownMenuEntries: List<DropdownMenuEntry<String>>.from(
                            _currencies.map(
                              (currency) => DropdownMenuEntry(
                                value: currency.isoCode,
                                label: currency.isoCode,
                                labelWidget: Text("${currency.isoCode}: ${currency.name}", style: Styles.textFont.copyWith(color: Styles.accentColor)))
                            )
                          ),
                          menuHeight: 300,
                          requestFocusOnTap: true,
                          textStyle: Styles.textFont.copyWith(color: Styles.accentColor, fontWeight: FontWeight.bold),
                          inputDecorationTheme: Styles.smallDropdownMenuDecorationTheme,
                          menuStyle: Styles.smallDropdownMenuStyle,
                          trailingIcon: Icon(Icons.keyboard_arrow_down, color: Styles.accentColor),
                          selectedTrailingIcon: Icon(Icons.keyboard_arrow_up, color: Styles.accentColor),
                          validator: (value) => _currencies.map((currency) {
                            return currency.isoCode;
                          }).contains(_defaultCurrencyController.text.trim()) ? null : "Currency entered is not a valid currency! Use the drop down menu for convienience."
                        )),
                      ],
                    ),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: Styles.textFieldDecoration.copyWith(labelText: "Expense Description", helperText: "What is this expense for?"),
                      style: Styles.textFont,
                      validator: (value) {
                        return (value != null && value.trim().isNotEmpty) ? null : "Please enter a description";
                      },
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width*0.8,
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          inputDecorationTheme: Styles.textFieldDecorationTheme
                        ),
                        child: TextFormField(
                          controller: _dateController,
                          readOnly: true,
                          decoration: Styles.textFieldDecoration.copyWith(labelText: "Expense Date", suffixIcon: Icon(Icons.calendar_today, color: Styles.white), helperText: "When was the expense?"),
                          style: Styles.textFont,
                          onTap: () async {
                            final DateTime? datePicked = await showDatePicker(
                              context: context,
                              initialDate: _expenseDate,
                              firstDate: DateTime.now().subtract(Duration(days: 365 * 2)),
                              lastDate: DateTime.now().add(Duration(days: 365)),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    datePickerTheme: DatePickerThemeData(
                                      backgroundColor: Styles.backgroundColor,
                                      headerBackgroundColor: Styles.lighterBackgroundColor,
                                      headerForegroundColor: Styles.white,
                                      surfaceTintColor: Colors.transparent,
                                      subHeaderForegroundColor: Styles.white,
                                      todayForegroundColor: WidgetStateColor.resolveWith((states) {
                                        if (states.contains(WidgetState.selected)) {
                                          return Styles.accentColor;
                                        }
                                        return Styles.white;
                                      }),
                                      todayBackgroundColor: WidgetStateColor.resolveWith((states) {
                                        if (states.contains(WidgetState.selected)) {
                                          return Styles.primaryColor;
                                        }
                                        return Colors.transparent;
                                      }),
                                      yearForegroundColor: WidgetStateColor.resolveWith((states) {
                                        if (states.contains(WidgetState.selected)) {
                                          return Styles.accentColor;
                                        }
                                        return Styles.white;
                                      }),
                                      yearBackgroundColor: WidgetStateColor.resolveWith((states) {
                                        if (states.contains(WidgetState.selected)) {
                                          return Styles.primaryColor;
                                        }
                                        return Colors.transparent;
                                      }),
                                      dayForegroundColor: WidgetStateColor.resolveWith((states) {
                                        if (states.contains(WidgetState.selected)) {
                                          return Styles.accentColor;
                                        }
                                        return Styles.white;
                                      }),
                                      dayBackgroundColor: WidgetStateColor.resolveWith((states) {
                                        if (states.contains(WidgetState.selected)) {
                                          return Styles.primaryColor;
                                        }
                                        return Colors.transparent;
                                      }),
                                    ),
                                    textButtonTheme: TextButtonThemeData(
                                      style: TextButton.styleFrom(
                                        foregroundColor: Styles.accentColor,
                                      ),
                                    ),
                                  ),
                                  child: child!,
                                );
                              }
                            );
                            if (datePicked != null) {
                              setState(() {
                                _expenseDate = datePicked;
                                _dateController.text = DateFormat('dd/MM/yyyy').format(datePicked);
                              });
                            }
                          },
                          validator: (value) {
                            return (value != null && value.isNotEmpty) ? null : "Please select a date";
                          },
                        )
                      )
                    ),
                    SizedBox(
                      //width: MediaQuery.of(context).size.width*0.8,
                      child: SwitchListTile(
                        title: Text("Trip Expense?", style: Styles.headingFont),
                        subtitle: Text("Is this expense part of an existing trip with people?", style: Styles.textFont.copyWith(color: Styles.grey)),
                        value: _isTripExpense,
                        onChanged: (bool value) {
                          HapticFeedback.lightImpact();
                          setState(() {
                            _isTripExpense = value;
                          });
                          updateExpenseParticipants();
                        },
                        activeThumbColor: Styles.accentColor,
                        activeTrackColor: Styles.primaryColor,
                        inactiveThumbColor: Styles.white,
                        inactiveTrackColor: Styles.grey,
                      ),
                    ),
                    if (_isTripExpense && _trips.isEmpty) Text("No trips found! Add trips to your account to easily categorize expenses.", style: Styles.errorFont, textAlign: TextAlign.center),
                    if (_isTripExpense && _trips.isNotEmpty) DropdownMenuFormField(
                      controller: _tripController,
                      label: Text("Trip", style: Styles.headingFont),
                      helperText: "Select the trip the expense was part of",
                      dropdownMenuEntries: List<DropdownMenuEntry<String>>.from(
                        _trips.map(
                          (trip) => DropdownMenuEntry(
                            value: trip["tripName"] as String,
                            label: trip["tripName"] as String,
                            leadingIcon: Icon(Icons.card_travel, color: Styles.white),
                            labelWidget: Text(trip["tripName"], style: Styles.textFont))
                        )
                      ),
                      menuHeight: 150,
                      requestFocusOnTap: true,
                      textStyle: Styles.textFont,
                      inputDecorationTheme: Styles.dropdownMenuDecorationTheme,
                      menuStyle: Styles.dropdownMenuStyle,
                      trailingIcon: Icon(Icons.keyboard_arrow_down, color: Styles.white),
                      selectedTrailingIcon: Icon(Icons.keyboard_arrow_up, color: Styles.white),
                      width: MediaQuery.of(context).size.width*0.8,
                      validator: (value) => tripExists() ? null : "Trip entered is not a valid trip of yours!",
                    ),
                    if (!_isTripExpense) Column(
                      children: [
                        if (_friends.isEmpty) Text("No friends found! Add friends to your account to easily split expenses with them.", style: Styles.errorFont, textAlign: TextAlign.center),
                        if (_friends.isNotEmpty) Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child:TextFormField(
                              controller: _nameSearchController,
                              style: Styles.textFont,
                              decoration: Styles.textFieldDecoration.copyWith(labelText: "Search username", helperText: "Search for friends to add"),
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
                        if (_selectedFriends.isNotEmpty) SizedBox(height: 8),
                        if (_selectedFriends.isNotEmpty) Container(
                          decoration: BoxDecoration(
                            color: Styles.backgroundColor,
                            border: Border.all(color: Styles.white, width: 1.5),
                            borderRadius: BorderRadius.circular(20)
                          ),
                          padding: EdgeInsets.all(10),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _selectedFriends.map((friend) {
                              return Chip(
                                label: Text(friend, style: Styles.textFont.copyWith(color: Styles.accentColor)),
                                deleteIcon: Icon(Icons.close, color: Styles.accentColor),
                                backgroundColor: Styles.primaryColor,
                                onDeleted: () {
                                  HapticFeedback.lightImpact();
                                  setState(() {
                                    // Dispose of the controller before disposing to prevent memory leaks
                                    _selectedFriends.remove(friend);
                                  });
                                  updateExpenseParticipants();
                                },
                              );
                            }).toList(),
                          ),
                        ),
                      ]
                    ),
                    DropdownMenuFormField(
                      controller: _expenseSplitStrategyController,
                      label: Text("Expense Split Strategy", style: Styles.headingFont),
                      helperText: "Select how the expense will be split",
                      dropdownMenuEntries: const [
                        DropdownMenuEntry(value: "Evenly", label: "Evenly", labelWidget: Text("Evenly", style: Styles.textFont)),
                        DropdownMenuEntry(value: "Percentages", label: "Percentages", labelWidget: Text("Percentages", style: Styles.textFont)),
                        DropdownMenuEntry(value: "Exact Values", label: "Exact Values", labelWidget: Text("Exact Values", style: Styles.textFont)),
                      ],
                      requestFocusOnTap: true,
                      textStyle: Styles.textFont,
                      inputDecorationTheme: Styles.dropdownMenuDecorationTheme,
                      menuStyle: Styles.dropdownMenuStyle,
                      trailingIcon: Icon(Icons.keyboard_arrow_down, color: Styles.white),
                      selectedTrailingIcon: Icon(Icons.keyboard_arrow_up, color: Styles.white),
                      width: MediaQuery.of(context).size.width*0.8,
                      validator: (value) => ["Evenly", "Percentages", "Exact Values"].contains(value) ? null : "Not a valid option. Use drop-down!",
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(_expenseParticipants.length, (index) {
                        return ListTile(
                          shape: Border(bottom: BorderSide(color: Styles.grey, width: 1)),
                          title: Row(
                            children: [
                              Text(_expenseParticipants[index], style: Styles.textFont),
                              Spacer(),
                              if (_expenseSplitStrategyController.text == "Exact Values" || _expenseSplitStrategyController.text == "Evenly")
                                Text(
                                  _currencies.firstWhere(
                                    (currency) => currency.isoCode == (_defaultCurrencyController.text.isNotEmpty ? _defaultCurrencyController.text : "USD"),
                                    orElse: () => Currency.create((_defaultCurrencyController.text.isNotEmpty ? _defaultCurrencyController.text : "USD"), 2)
                                  ).symbol,
                                  style: Styles.textFont
                                ),
                              if (_expenseSplitStrategyController.text != "Evenly")
                                SizedBox(
                                  width: 50,
                                  child: TextFormField(
                                    controller: _amountPerParticipantControllers[_expenseParticipants[index]],
                                    decoration: Styles.plainTextFieldDecoration,
                                    style: Styles.textFont,
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) return "Please enter a value";
                                      if (_expenseSplitStrategyController.text == "Percentages") {
                                        final num? percentage = num.tryParse(value);
                                        if (percentage == null) return "Please enter a valid number";
                                        if (percentage <= 0 || percentage >= 100) return "Please enter a percentage between 0 and 100";
                                      } else if (_expenseSplitStrategyController.text == "Exact Values") {
                                        final num? amount = num.tryParse(value);
                                        if (amount == null) return "Please enter a valid number";
                                        if (amount <= 0) return "Please enter an amount greater than or equal to 0";
                                      }
                                      return null;
                                    },
                                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                                  ),
                                ),
                              if (_expenseSplitStrategyController.text == "Evenly")
                                ConstrainedBox(
                                  constraints: BoxConstraints(maxWidth: 200),
                                  child: Text(
                                    num.tryParse(_amountController.text) == null ? "00.00" : numberFormatter.format(num.tryParse(_amountController.text)! / _expenseParticipants.length),
                                    style: Styles.textFont
                                  ),
                                ),
                              if (_expenseSplitStrategyController.text == "Percentages")
                                Text("%", style: Styles.textFont),
                            ],
                          ),
                        );
                      }),
                    ),
                    SizedBox(height: 8),
                    DropdownMenuFormField(
                      controller: _payingParticipantController,
                      label: Text("Payee", style: Styles.headingFont),
                      helperText: "Select the person paying",
                      dropdownMenuEntries: List<DropdownMenuEntry<String>>.from(
                        _expenseParticipants.map(
                          (participant) => DropdownMenuEntry(
                            value: participant,
                            label: participant,
                            labelWidget: Text(participant, style: Styles.textFont))
                        )
                      ),
                      menuHeight: 150,
                      requestFocusOnTap: true,
                      textStyle: Styles.textFont,
                      inputDecorationTheme: Styles.dropdownMenuDecorationTheme,
                      menuStyle: Styles.dropdownMenuStyle,
                      trailingIcon: Icon(Icons.keyboard_arrow_down, color: Styles.white),
                      selectedTrailingIcon: Icon(Icons.keyboard_arrow_up, color: Styles.white),
                      width: MediaQuery.of(context).size.width*0.8,
                      validator: (value) => _expenseParticipants.contains(value) ? null : "Person not valid. Use drop-down!",
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // This button clears all the values
                        ElevatedButton(
                          onPressed: () 
                            {
                              final controllersToDisposeFromMap = _amountPerParticipantControllers.values;
                              setState(() {
                                // Reset the form
                                _dateController.text = "";
                                _nameController.text = "";
                                _tripController.text = "";
                                _amountController.text = "";
                                _nameSearchController.text = "";
                                _descriptionController.text = "";
                                _defaultCurrencyController.text = _userPreferredCurrency;
                                _expenseSplitStrategyController.text = "Evenly";
                                _amountPerParticipantControllers.clear();
                                _selectedFriends = [];
                                _expenseParticipants = ["You"];
                                _payingParticipantController.text = "";
                                _tripMemberIds = [];
                                _fetchedTripNonFriendIdUsernameMap.clear();
                              });
                              for (var controller in controllersToDisposeFromMap) {
                                controller.dispose();
                              }
                            },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Styles.lighterBackgroundColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            side: BorderSide(color: Styles.red, width: 3),
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20)
                          ),
                          child: Text("Clear", style: Styles.headingFont.copyWith(color: Styles.negativeColor))
                        ),
                        SizedBox(width: 20),
                        ElevatedButton(
                          onPressed: () async {
                              HapticFeedback.lightImpact();
                              // Check the form is valid, then attempt to add the expense to the database
                              await _addExpense();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Styles.lighterBackgroundColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            side: BorderSide(color: Styles.white, width: 3),
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20)
                          ),
                          child: Text("Save", style: Styles.headingFont)
                        ),
                      ]
                    ),
                    SizedBox(height: 30), // Spacing for the bottom of the page
                  ],
                )
              )
            ]
        ),
      )
    );
  }

  Future<void> _addExpense() async {
    // Try to auto-add the exact values to get the sum as a convenience feature
    if (_expenseSplitStrategyController.text == "Exact Values" && _amountController.text.isEmpty) {
      bool eachPersonHasValidAmount = true;
      num totalAmount = 0;
      for (var controller in _amountPerParticipantControllers.values) {
        if (num.tryParse(controller.text) == null || num.tryParse(controller.text)! <= 0) {
          eachPersonHasValidAmount = false;
          break;
        }
        totalAmount += num.tryParse(controller.text) ?? 0;
      }
      if (eachPersonHasValidAmount) {
        setState(() {
          _amountController.text = totalAmount.toStringAsFixed(2);
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Amount automatically added up to be ${totalAmount.toStringAsFixed(2)}!", style: Styles.textFont), showCloseIcon: true, duration: Duration(seconds: 3), backgroundColor: Styles.accentColor, behavior: SnackBarBehavior.floating, margin: EdgeInsets.all(20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Styles.white, width: 3)))
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Hit save again if the amount is right!", style: Styles.textFont), showCloseIcon: true, duration: Duration(seconds: 3), backgroundColor: Styles.accentColor, behavior: SnackBarBehavior.floating, margin: EdgeInsets.all(20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Styles.white, width: 3)))
        );
        return;
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please enter a valid amount greater than 0 for each person!", style: Styles.textFont), showCloseIcon: true, duration: Duration(seconds: 3), backgroundColor: Styles.red, behavior: SnackBarBehavior.floating, margin: EdgeInsets.all(20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Styles.white, width: 3)))
        );
        return;
      }
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedFriends.isEmpty && !_isTripExpense) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select at least one friend involved in the expense or mark it as a trip expense!", style: Styles.textFont), showCloseIcon: true, duration: Duration(seconds: 3), backgroundColor: Styles.red, behavior: SnackBarBehavior.floating, margin: EdgeInsets.all(20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Styles.white, width: 3)))
      );
      setState(() => _friendSearchError = "Select at least one friend here!");
      return;
    }

    if (!_tripController.text.isNotEmpty && _isTripExpense) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select a trip for the expense or mark it as a non-trip expense!", style: Styles.textFont), showCloseIcon: true, duration: Duration(seconds: 3), backgroundColor: Styles.red, behavior: SnackBarBehavior.floating, margin: EdgeInsets.all(20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Styles.white, width: 3)))
      );
      return;
    }

    if (_expenseSplitStrategyController.text == "Percentages") {
      num totalPercentage = 0;
      for (var controller in _amountPerParticipantControllers.values) {
        totalPercentage += num.tryParse(controller.text) ?? 0;
      }
      if (totalPercentage != 100) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please ensure the percentages add up to 100%!", style: Styles.textFont), showCloseIcon: true, duration: Duration(seconds: 3), backgroundColor: Styles.red, behavior: SnackBarBehavior.floating, margin: EdgeInsets.all(20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Styles.white, width: 3)))
        );
        return;
      }
    }

    if (_expenseSplitStrategyController.text == "Exact Values") {
      num totalAmount = 0;
      for (var controller in _amountPerParticipantControllers.values) {
        totalAmount += num.tryParse(controller.text) ?? 0;
      }
      if (totalAmount != num.tryParse(_amountController.text)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please ensure the amounts add up to the total expense amount!", style: Styles.textFont), showCloseIcon: true, duration: Duration(seconds: 3), backgroundColor: Styles.red, behavior: SnackBarBehavior.floating, margin: EdgeInsets.all(20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Styles.white, width: 3)))
        );
        return;
      }
    }

    // Get UIDs for database storage
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    String? tripId;
    List<String> participantIds = [currentUserId];
    List<String> friendshipIds;
    if (_isTripExpense) {
      final trip = _trips.firstWhere((t) => t["tripName"] == _tripController.text.trim());
      tripId = trip["tripId"] as String;
      participantIds.addAll(trip["memberIds"] as List<String>);
      friendshipIds = [];
    } else {
      for (var friendName in _selectedFriends) {
        final friend = _friends.firstWhere((f) => f["friendName"] == friendName);
        participantIds.add(friend["friendId"] as String);
      }
      friendshipIds = !_isTripExpense
        ? _selectedFriends.map((name) =>
            _friends.firstWhere((f) => f["friendName"] == name)["friendshipId"] as String,
          ).toList()
        : <String>[];
    }

    final amount = num.tryParse(_amountController.text)!.toDouble();
    final currency = _defaultCurrencyController.text.substring(0, 3);
    final amountUSD = CurrencyConversion.getInstance().convertToUSD(amount, currency);

    // Build per-person split amounts keyed by uid
    final splitAmounts = <String, double>{};
    
    // Split amounts for all three different strategies for splitting
    if (_expenseSplitStrategyController.text.trim() == "Exact Amounts") {
      for (var participant in _amountPerParticipantControllers.keys) {
        final amountForParticipant = num.tryParse(_amountPerParticipantControllers[participant]!.text)?.toDouble() ?? 0.0;
        final percent = amountForParticipant/amount;
        splitAmounts[getIdFromName(participant)] = percent*amountUSD;
      }
    } else if (_expenseSplitStrategyController.text.trim() == "Percentages") {
      for (var participant in _amountPerParticipantControllers.keys) {
        final percentForParticipant = num.tryParse(_amountPerParticipantControllers[participant]!.text)?.toDouble() ?? 0.0;
        splitAmounts[getIdFromName(participant)] = amountUSD*percentForParticipant;
      }
    } else {
      for (var participantId in participantIds) {
        splitAmounts[participantId] = amountUSD / participantIds.length;
      }
    }

    // Find UID of paying participant
    final paidByName = _payingParticipantController.text;
    String payingParticipantId;
    payingParticipantId = getIdFromName(paidByName);

    // Upload the expense to the database
    final expenseDoc = await FirebaseFirestore.instance.collection("expenses").add({
      "name": _nameController.text,
      "amountUSD": amountUSD,
      "originalAmount": num.tryParse(_amountController.text),
      "originalCurrency": _defaultCurrencyController.text.substring(0, 3), // Extract ISO code from label
      "description": _descriptionController.text,
      "date": _expenseDate,
      "isTripExpense": _isTripExpense,
      "tripId": _isTripExpense ? tripId : null,
      "friendshipsId": !_isTripExpense ? friendshipIds : null,
      "participants": participantIds,
      "expenseSplitStrategy": _expenseSplitStrategyController.text,
      "amountPerPerson": splitAmounts,
      "paidBy": payingParticipantId,
      "createdAt": FieldValue.serverTimestamp(),
    });

    // Update running total balances with batches
    final batch = FirebaseFirestore.instance.batch();

    if (_isTripExpense) {
      final tripDocumentFromStream = FirebaseFirestore.instance.collection("trips").doc(tripId);
      for (var id in participantIds) {
        final theirSplit = splitAmounts[id] ?? 0.0;
        final changeInDebt = (id == payingParticipantId) 
            // If id is the payer's, they are owed everything except their part
            ? amountUSD - theirSplit
            // Non-paying participants owe their part
            : -theirSplit;
        batch.update(tripDocumentFromStream, {"totalDebt.$id": FieldValue.increment(changeInDebt)});
      }
    } else { // Expense with friends
      for (String friendName in _selectedFriends) {
        // Get the current friend's object from the stream
        final friend = _friends.firstWhere((f) => f["friendName"] == friendName);
        // Get the Id of the current friend
        final friendId = friend["friendId"] as String;
        var currentUserChangeInDebt = 0.0;
        // Figure out each person's change in debt for this friendship
        if (currentUserId == payingParticipantId) {
          currentUserChangeInDebt = splitAmounts[friendId]!;
        } else if (currentUserId == payingParticipantId) {
          currentUserChangeInDebt = -1*splitAmounts[friendId]!;
        }

        // If either of the cases leading to a change between the user and the current friend are true:
        // Then update their running totals on their friendship document
        if (currentUserId == payingParticipantId || currentUserId == payingParticipantId) {
          // Get the document of the friendship between the current user and the current friend
          final friendshipDocumentReference = FirebaseFirestore.instance
              .collection("friendships")
              .doc(friend["friendshipId"] as String);
          // Update as a batch so that they fail and succeed collectively
          batch.update(friendshipDocumentReference, {
            "totalDebt.$currentUserId": FieldValue.increment(currentUserChangeInDebt),
            "totalDebt.$friendId": FieldValue.increment(-1*currentUserChangeInDebt),
          });
        }
      }
    }
    await batch.commit();

    if (!mounted) return;
    final controllersToDisposeFromMap = _amountPerParticipantControllers.values;
    setState(() {
      // Reset the form
      _dateController.text = "";
      _nameController.text = "";
      _tripController.text = "";
      _amountController.text = "";
      _nameSearchController.text = "";
      _descriptionController.text = "";
      _defaultCurrencyController.text = _userPreferredCurrency;
      _expenseSplitStrategyController.text = "Evenly";
      _amountPerParticipantControllers.clear();
      _selectedFriends = [];
      _expenseParticipants = ["You"];
      _payingParticipantController.text = "";
      _tripMemberIds = [];
      _fetchedTripNonFriendIdUsernameMap.clear();
    });
    for (var controller in controllersToDisposeFromMap) {
      controller.dispose();
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Expense added successfully!",
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

  @override
  void dispose() {
    for (var controller in _amountPerParticipantControllers.values) {
      controller.dispose();
    }
    _nameController.dispose();
    _amountController.dispose();
    _expenseSplitStrategyController.dispose();
    _defaultCurrencyController.dispose();
    _tripController.dispose();
    super.dispose();
  }

  void validateAndAddFriend() {
    final inputUsername = _nameSearchController.text.trim();
    // Handle no input
    if (inputUsername.isEmpty) {
      setState(() => _friendSearchError = "Make sure you type a name!");
      return;
    }
    // Handle already selected to be in trip
    if (_selectedFriends.contains(inputUsername)) {
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
      _selectedFriends.add(inputUsername);
      _friendSearchError = "";
      // Reset the text in the search bar
      _nameSearchController.text = "";
    });
    updateExpenseParticipants();
    return;
  }

  bool tripExists() {
    return _trips.map((trip) {
      return trip["tripName"];
    }).contains(_tripController.text.trim());
  }

  void updateExpenseParticipants() async {
    // Update the expense's participants when the trip or selected friends changes
    final expenseParticipantsProcessed = ["You"];
    final fetchedUsernames = <String, String>{};
    if (_isTripExpense && _tripController.text.trim().isNotEmpty && tripExists()) {
      final trip = _trips.firstWhere((tripFromStream) => tripFromStream["tripName"] == _tripController.text.trim());
      _tripMemberIds = trip["memberIds"];
      // Use ids to get usernames
      // Separate those already known by being friends from those that need database queries
      final knownIds = _friends.map((friend) => friend["friendId"] as String).toSet();
      final unknownIds = _tripMemberIds.where((id) => !knownIds.contains(id)).toList();

      // Get only unknown usernames from database
      if (unknownIds.isNotEmpty) {
        final documents = await Future.wait(
          unknownIds.map((id) => FirebaseFirestore.instance
            .collection("public-users")
            .doc(id)
            .get())
        );
        for (var i = 0; i < unknownIds.length; i++) {
          fetchedUsernames[unknownIds[i]] = documents[i].data()?["username"] as String? ?? unknownIds[i];
        }
      }

      final tripMemberNames = _tripMemberIds.map((id) {
      final friend = _friends.firstWhere(
          (f) => f["friendId"] == id,
          orElse: () => {},
        );
        return friend["friendName"] as String? ?? fetchedUsernames[id] ?? id;
      }).toList();

      expenseParticipantsProcessed.addAll(tripMemberNames);

    } else if (_selectedFriends.isNotEmpty) {
      expenseParticipantsProcessed.addAll(_selectedFriends);
    }
    // Update the amountControllers per participant
    // 1) Find all the participants that are no longer needed
    final participantsToRemove = _amountPerParticipantControllers.keys
      .where((participant) => !expenseParticipantsProcessed.contains(participant))
      .toList();

    // 2) Get all the controllers to remove
    final controllersToDispose = participantsToRemove
      .map((p) => _amountPerParticipantControllers[p]!)
      .toList();

    if (!mounted) return;
    setState(() {
      _expenseParticipants = expenseParticipantsProcessed;
      if (_isTripExpense) {_fetchedTripNonFriendIdUsernameMap = fetchedUsernames;}
      // 3) Add participants that do not yet have a controller
      for (var participant in expenseParticipantsProcessed) {
        _amountPerParticipantControllers.putIfAbsent(participant, () => TextEditingController());
      }
      // 4) Remove all the participants that need to be removed
      for (var participant in participantsToRemove) {
        _amountPerParticipantControllers.remove(participant);
      }
    });
    // 5) Safely dispose of all the controllers
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (var controller in controllersToDispose) {
        controller.dispose();
      }
    });
  }

  String getIdFromName(String username) {
    // Return current user's id if the current user paid
    if (username == "You") {
      return FirebaseAuth.instance.currentUser!.uid;
    } else {
      // Try getting the id from the list of friends
      final friendFromId = _friends.firstWhere((f) => f["friendName"] == username);
      if (friendFromId.isNotEmpty) {
        return friendFromId["friendId"] as String;
      } else {
        // Get the id from the fetched list that is made for trips
        // where not every member is a friend of the current user
        return _fetchedTripNonFriendIdUsernameMap.entries
          .firstWhere((idUsernamePair) => idUsernamePair.value == username).key;
      }
    }
  }

}