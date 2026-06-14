import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:money2/money2.dart';
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
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _areStreamsLoaded = false;
  List<String> _trips = [];
  List<String> _friends = [];
  List<String> _selectedFriends = [];

  // Input controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _currencyController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime _expenseDate = DateTime.now();
  final TextEditingController _dateController = TextEditingController(text: DateFormat('dd/MM/yyyy').format(DateTime.now()));
  bool _isTripExpense = false;
  final TextEditingController _tripController = TextEditingController();
  final TextEditingController _friendsController = TextEditingController();
  final TextEditingController _expenseSplitStrategyController = TextEditingController();
  final Map<String, TextEditingController> _amountPerPersonControllers = {};
  // Preload all currencies
  final List<Currency> _currencies = Currencies().getRegistered().toList();

  @override
  Widget build(BuildContext context) {
    // Wait for the streams to load
    if (!_areStreamsLoaded) {
      // Get initial values
      final public = Provider.of<PublicUser?>(context);
      final private = Provider.of<PrivateUser?>(context);
      if (public != null && private != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            _nameController.text = "Name...";
            _amountController.text = "00";
            _currencyController.text = (private.data["preferredCurrency"] as String?) ?? "USD";
            _trips = List<String>.from(private.data["trips"] ?? []);
            _friends = List<String>.from(private.data["friends"] ?? []);
            _expenseSplitStrategyController.text = "Evenly";
            _areStreamsLoaded = true;
          });
        });
        return Scaffold(
          backgroundColor: Styles.backgroundColor,
          body: Center(child: CircularProgressIndicator(color: Styles.accentColor)),
        );
      }
    }
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.1),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            spacing: 10,
            children: [
              SizedBox(height: 90), // Top padding
              //Text("Add Expense", style: Styles.headingFont),
              Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUnfocus,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  spacing: MediaQuery.of(context).size.height*0.02,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      textAlign: TextAlign.center,
                      decoration: Styles.plainTextFieldDecoration,
                      style: Styles.subTitleFont,
                      validator: (value) {
                        return (value != null && value.trim().isNotEmpty) ? null : "Please enter a full name";
                      },
                    ),
                    Row(
                      children: [
                        // Symbol for the currency
                        Text(_currencies.firstWhere((currency) => currency.isoCode == (_currencyController.text.isNotEmpty ? _currencyController.text : "USD"), orElse: () => Currency.create((_currencyController.text.isNotEmpty ? _currencyController.text : "USD"), 2)).symbol, style: Styles.numberFont.copyWith(fontSize: 50)),
                        // Value of the expense
                        Expanded(child: TextFormField(
                          controller: _amountController,
                          decoration: Styles.plainTextFieldDecoration,
                          style: Styles.numberFont.copyWith(fontSize: 50),
                          validator: (value) {
                            return (value != null && value.trim().isNotEmpty && double.tryParse(value) != null && double.tryParse(value)! > 0) ? null : "Please enter a valid amount greater than 0";
                          },
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                        )),
                        // Dropdown for the currency
                        Flexible(child: DropdownMenuFormField(
                          controller: _currencyController,
                          dropdownMenuEntries: List<DropdownMenuEntry<String>>.from(
                            _currencies.map(
                              (currency) => DropdownMenuEntry(
                                value: currency.isoCode,
                                label: currency.isoCode,
                                labelWidget: Text("${currency.isoCode}: ${currency.name}", style: Styles.textFont.copyWith(color: Styles.accentColor)))
                            )
                          ),
                          initialSelection: _currencyController.text.isNotEmpty ? _currencyController.text : "USD",
                          menuHeight: 300,
                          requestFocusOnTap: true,
                          textStyle: Styles.textFont.copyWith(color: Styles.accentColor, fontWeight: FontWeight.bold),
                          inputDecorationTheme: Styles.smallDropdownMenuDecorationTheme,
                          menuStyle: Styles.smallDropdownMenuStyle,
                          trailingIcon: Icon(Icons.keyboard_arrow_down, color: Styles.accentColor),
                          selectedTrailingIcon: Icon(Icons.keyboard_arrow_up, color: Styles.accentColor),
                        )),
                      ],
                    ),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: Styles.textFieldDecoration.copyWith(labelText: "Expense Description"),
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
                          decoration: Styles.textFieldDecoration.copyWith(labelText: "Expense Date", suffixIcon: Icon(Icons.calendar_today, color: Styles.white)),
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
                                    colorScheme: ColorScheme.light(
                                      primary: Styles.accentColor,
                                      onPrimary: Styles.white,
                                      onSurface: Styles.lighterBackgroundColor,
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
                      width: MediaQuery.of(context).size.width*0.8,
                      child: SwitchListTile(
                        title: Text("Trip Expense?", style: Styles.headingFont),
                        subtitle: Text("Is this expense part of an existing trip with people?", style: Styles.textFont.copyWith(color: Styles.grey)),
                        value: _isTripExpense,
                        onChanged: (bool value) {
                          HapticFeedback.lightImpact();
                          setState(() {
                            _isTripExpense = value;
                          });
                        },
                        activeThumbColor: Styles.accentColor,
                        activeTrackColor: Styles.primaryColor,
                        inactiveThumbColor: Styles.white,
                        inactiveTrackColor: Styles.grey,
                      ),
                    ),
                    if (_isTripExpense && _trips.isEmpty) Text("No trips found! Add trips to your account to easily categorize expenses.", style: Styles.errorFont, textAlign: TextAlign.center),
                    if (_isTripExpense && _trips.isNotEmpty) DropdownMenu(
                      controller: _tripController,
                      label: Text("Trip", style: Styles.headingFont),
                      helperText: "Select the trip the expense was part of",
                      dropdownMenuEntries: List<DropdownMenuEntry<String>>.from(
                        _trips.map(
                          (trip) => DropdownMenuEntry(
                            value: trip,
                            label: trip,
                            leadingIcon: Icon(Icons.card_travel, color: Styles.white),
                            labelWidget: Text(trip, style: Styles.textFont))
                        )
                      ),
                      initialSelection: null,
                      menuHeight: 150,
                      requestFocusOnTap: true,
                      textStyle: Styles.textFont,
                      inputDecorationTheme: Styles.dropdownMenuDecorationTheme,
                      menuStyle: Styles.dropdownMenuStyle,
                      trailingIcon: Icon(Icons.keyboard_arrow_down, color: Styles.white),
                      selectedTrailingIcon: Icon(Icons.keyboard_arrow_up, color: Styles.white),
                      width: MediaQuery.of(context).size.width*0.8,
                    ),
                    if (!_isTripExpense) 
                    Column(
                      children: [
                        if (_friends.isEmpty) Text("No friends found! Add friends to your account to easily split expenses with them.", style: Styles.errorFont, textAlign: TextAlign.center),
                        if (_friends.isNotEmpty) DropdownMenu(
                          controller: _friendsController,
                          label: Text("Friends Involved", style: Styles.headingFont),
                          helperText: "Select friends involved in the expense",
                          dropdownMenuEntries: List<DropdownMenuEntry<String>>.from(
                            _friends.map(
                              (friend) => DropdownMenuEntry(
                                value: friend,
                                label: friend,
                                leadingIcon: Icon(Icons.person, color: Styles.white),
                                labelWidget: Text(friend, style: Styles.textFont))
                            )
                          ),
                          initialSelection: null,
                          requestFocusOnTap: true,
                          textStyle: Styles.textFont,
                          inputDecorationTheme: Styles.dropdownMenuDecorationTheme,
                          menuStyle: Styles.dropdownMenuStyle,
                          trailingIcon: Icon(Icons.keyboard_arrow_down, color: Styles.white),
                          selectedTrailingIcon: Icon(Icons.keyboard_arrow_up, color: Styles.white),
                          width: MediaQuery.of(context).size.width*0.8,
                          onSelected: (value) {
                            HapticFeedback.lightImpact();
                            if (value != null && !_selectedFriends.contains(value)) {
                              setState(() {
                                // If the selected friends do not already contain the newly selected friend,
                                // add the new friend to the list of selected friends
                                if (!_selectedFriends.contains(value)) {
                                  _selectedFriends.add(value);
                                  _amountPerPersonControllers[value] = TextEditingController();
                                  _friendsController.clear();
                                }
                              });
                            }
                          },
                        ),
                        if (_selectedFriends.isNotEmpty) Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _selectedFriends.map((friend) {
                            return Chip(
                              label: Text(friend, style: Styles.textFont),
                              deleteIcon: Icon(Icons.close, color: Styles.white),
                              backgroundColor: Styles.accentColor,
                              onDeleted: () {
                                HapticFeedback.lightImpact();
                                setState(() {
                                  // Dispose of the controller before disposing to prevent memory leaks
                                  _amountPerPersonControllers[friend]?.dispose();
                                  _amountPerPersonControllers.remove(friend);
                                  _selectedFriends.remove(friend);
                                });
                              },
                            );
                          }).toList(),
                        )
                      ],
                    ),
                    DropdownMenu(
                      controller: _expenseSplitStrategyController,
                      label: Text("Expense Split Strategy", style: Styles.headingFont),
                      helperText: "Select how the expense will be split",
                      dropdownMenuEntries: const [
                        DropdownMenuEntry(value: "Evenly", label: "Evenly", labelWidget: Text("Evenly", style: Styles.textFont)),
                        DropdownMenuEntry(value: "Percentages", label: "Percentages", labelWidget: Text("Percentages", style: Styles.textFont)),
                        DropdownMenuEntry(value: "Exact Values", label: "Exact Values", labelWidget: Text("Exact Values", style: Styles.textFont)),
                      ],
                      initialSelection: _expenseSplitStrategyController.text.isNotEmpty ? _expenseSplitStrategyController.text : "Evenly",
                      requestFocusOnTap: true,
                      textStyle: Styles.textFont,
                      inputDecorationTheme: Styles.dropdownMenuDecorationTheme,
                      menuStyle: Styles.dropdownMenuStyle,
                      trailingIcon: Icon(Icons.keyboard_arrow_down, color: Styles.white),
                      selectedTrailingIcon: Icon(Icons.keyboard_arrow_up, color: Styles.white),
                      width: MediaQuery.of(context).size.width*0.8,
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(_selectedFriends.length, (index) {
                        return ListTile(
                          shape: Border(bottom: BorderSide(color: Styles.grey, width: 1)),
                          title: Row(
                            children: [
                              Text(_selectedFriends[index], style: Styles.textFont),
                              Spacer(),
                              if (_expenseSplitStrategyController.text == "Exact Values" || _expenseSplitStrategyController.text == "Evenly")
                                Text(
                                  _currencies.firstWhere(
                                    (currency) => currency.isoCode == (_currencyController.text.isNotEmpty ? _currencyController.text : "USD"),
                                    orElse: () => Currency.create((_currencyController.text.isNotEmpty ? _currencyController.text : "USD"), 2)
                                  ).symbol,
                                  style: Styles.textFont
                                ),
                              if (_expenseSplitStrategyController.text != "Evenly")
                                SizedBox(
                                  width: 50,
                                  child: TextFormField(
                                    controller: _amountPerPersonControllers[_selectedFriends[index]],
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
                              if (_expenseSplitStrategyController.text == "Exact Values")
                                SizedBox(
                                  width: 50,
                                  child: Text(
                                    (num.tryParse(_amountController.text)! / _selectedFriends.length).toStringAsFixed(2),
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
                    ElevatedButton(
                      onPressed: () {
                          HapticFeedback.lightImpact();
                          // Check the form is valid, then attempt to add the expense to the database
                          if (_formKey.currentState != null && _formKey.currentState!.validate()) {
                            _addExpense();
                          }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Styles.lighterBackgroundColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: Styles.white, width: 3),
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20)
                      ),
                      child: Text("Save", style: Styles.headingFont)
                    ),
                    SizedBox(height: 30), // Spacing for the bottom of the page
                  ],
                )
              )
            ]
        ),
          //SizedBox(width: MediaQuery.of(context).size.width*0.1), // Right padding
      )
    );
  }

  Future<void> _addExpense() async {
    // Try to auto-add the exact values to get the sum as a convenience feature
    if (num.tryParse(_amountController.text) == null || num.tryParse(_amountController.text)! <= 0) {
      bool eachPersonHasValidAmount = true;
      num totalAmount = 0;
      for (var controller in _amountPerPersonControllers.values) {
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
      return;
    }

    if (!_tripController.text.isNotEmpty && _isTripExpense) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select a trip for the expense or mark it as a non-trip expense!", style: Styles.textFont), showCloseIcon: true, duration: Duration(seconds: 3), backgroundColor: Styles.red, behavior: SnackBarBehavior.floating, margin: EdgeInsets.all(20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Styles.white, width: 3)))
      );
      return;
    }

    if (_expenseSplitStrategyController.text == "Percentage") {
      num totalPercentage = 0;
      for (var controller in _amountPerPersonControllers.values) {
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
      for (var controller in _amountPerPersonControllers.values) {
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

    // Convert friend usernames to UIDs for database storage
    List<String> selectedFriendsUID = [];
    for (var friend in _selectedFriends) {
      // Get the UID of each selected friend from the public users collection
      final friendDoc = await FirebaseFirestore.instance.collection("public-users").where("username", isEqualTo: friend).get();
      if (friendDoc.docs.isNotEmpty) {
        selectedFriendsUID.add(friendDoc.docs.first.id);
      }
    }

    // Upload the expense to the database
    final expenseDoc = await FirebaseFirestore.instance.collection("expenses").add({
      "name": _nameController.text,
      "amount": num.tryParse(_amountController.text),
      "currency": _currencyController.text.substring(0, 3), // Extract ISO code from label
      "description": _descriptionController.text,
      "date": _expenseDate,
      "isTripExpense": _isTripExpense,
      "trip": _isTripExpense ? _tripController.text : null,
      "friendsInvolved": !_isTripExpense ? selectedFriendsUID : null,
      "expenseSplitStrategy": _expenseSplitStrategyController.text,
      "amountPerPerson": _amountPerPersonControllers.values.map((controller) => num.tryParse(controller.text)).toList(),
      "createdAt": FieldValue.serverTimestamp(),
    });

    // Add the expense ID to each involved party's pending expenses in the database using a batch write
    final batch = FirebaseFirestore.instance.batch();
    if (_isTripExpense) {
      // If it's a trip expense, add the expense ID to the trip document
      final tripDoc = FirebaseFirestore.instance.collection("trips").doc(_tripController.text);
      batch.update(tripDoc, {
        "expenses": FieldValue.arrayUnion([expenseDoc.id])
      });
    } else {
      // If it's not a trip expense, add the expense ID to each involved friend's pending expenses
      for (final friendUID in selectedFriendsUID) {
        final friendDoc = FirebaseFirestore.instance.collection("public-users").doc(friendUID);
        batch.update(friendDoc, {
          "pendingExpenses": FieldValue.arrayUnion([expenseDoc.id])
        });
      }
    }
    await batch.commit();

  }

  @override
  void dispose() {
    for (var controller in _amountPerPersonControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

}