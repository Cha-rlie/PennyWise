import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:money2/money2.dart';
import 'package:penny_wise/model/connectivity_util.dart';
import 'package:penny_wise/model/reading_streams.dart';

import 'package:penny_wise/styles.dart';
import 'package:penny_wise/model/document_snapshot_wrappers.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _defaultCurrencyController = TextEditingController();
  bool _defaultCurrencyChanged = false;
  final TextEditingController _paymentReminderController = TextEditingController();
  bool _paymentReminderChanged = false;
  bool _acceptingNewFriendsValue = false;
  bool _acceptingNewFriendsChanged = false;
  bool _automaticallyLogOutValue = false;
  bool _automaticallyLogOutChanged = false;
  bool _notificiationsValue = false;
  bool _notificationsChanged = false;

  bool _areStreamsLoaded = false;

  // Preload all currencies
  final List<Currency> _currencies = Currencies().getRegistered().toList();

  @override
  void initState() {
    super.initState();
  }

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
          _defaultCurrencyController.text = (private.data["preferredCurrency"] as String?) ?? "USD";
          _paymentReminderController.text = (private.data["paymentReminderFrequency"] as String?) ?? "Never";
          _acceptingNewFriendsValue = public.data["acceptingNewFriends"] as bool? ?? false;
          _automaticallyLogOutValue = private.data["automaticallyLogOut"] as bool? ?? false;
          _notificiationsValue = private.data["notifications"] as bool? ?? false;
          setState(() {
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
      child:Row(
        children: [
          SizedBox(width: MediaQuery.of(context).size.width*0.1), // Left padding
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            spacing: 10,
            children: [
              SizedBox(height: 90), // Top padding
              Text("Preferences", style: Styles.subTitleFont),
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
                onSelected: (value) => setState(() => _defaultCurrencyChanged = true),
                initialSelection: _defaultCurrencyController.text,
                menuHeight: 300,
                requestFocusOnTap: true,
                textStyle: Styles.textFont,
                inputDecorationTheme: Styles.dropdownMenuDecorationTheme,
                menuStyle: Styles.dropdownMenuStyle,
                trailingIcon: Icon(Icons.keyboard_arrow_down, color: Styles.white),
                selectedTrailingIcon: Icon(Icons.keyboard_arrow_up, color: Styles.white),
                width: MediaQuery.of(context).size.width*0.8,
                validator: (value) => _currencies.contains(Currency.create(_defaultCurrencyController.text.trim(), 2)) ? null : "Currency entered is not a valid currency! Use the drop down menu for convienience.",
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width*0.8,
                child: SwitchListTile(
                  title: Text("Notifications", style: Styles.headingFont),
                  subtitle: Text("Do you want to receive payment reminder notifications?", style: Styles.textFont.copyWith(color: Styles.grey)),
                  value: _notificiationsValue,
                  onChanged: (bool value) {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _notificiationsValue = value;
                      _notificationsChanged = true;
                    });
                  },
                  activeThumbColor: Styles.accentColor,
                  activeTrackColor: Styles.primaryColor,
                  inactiveThumbColor: Styles.white,
                  inactiveTrackColor: Styles.grey,
                ),
              ),
              DropdownMenu(
                controller: _paymentReminderController,
                enabled: _notificiationsValue,
                label: Text("Payment Reminders", style: Styles.headingFont),
                helperText: "Select frequency of reminders",
                dropdownMenuEntries: const [
                  DropdownMenuEntry(value: "Never", label: "Never", labelWidget: Text("Never", style: Styles.textFont)),
                  DropdownMenuEntry(value: "Daily", label: "Daily", labelWidget: Text("Daily", style: Styles.textFont)),
                  DropdownMenuEntry(value: "Weekly", label: "Weekly", labelWidget: Text("Weekly", style: Styles.textFont)),
                  DropdownMenuEntry(value: "Monthly", label: "Monthly", labelWidget: Text("Monthly", style: Styles.textFont)),
                ],
                onSelected: (value) => setState(() => _paymentReminderChanged = true),
                initialSelection: _paymentReminderController.text,
                requestFocusOnTap: true,
                textStyle: Styles.textFont,
                inputDecorationTheme: Styles.dropdownMenuDecorationTheme,
                menuStyle: Styles.dropdownMenuStyle,
                trailingIcon: Icon(Icons.keyboard_arrow_down, color: Styles.white),
                selectedTrailingIcon: Icon(Icons.keyboard_arrow_up, color: Styles.white),
                width: MediaQuery.of(context).size.width*0.8,
              ),
              Text("Privacy", style: Styles.subTitleFont),
              SizedBox(
                width: MediaQuery.of(context).size.width*0.8,
                child: SwitchListTile(
                  title: Text("New Friends", style: Styles.headingFont),
                  subtitle: Text("Do you want to accept new friend requests?", style: Styles.textFont.copyWith(color: Styles.grey)),
                  value: _acceptingNewFriendsValue,
                  onChanged: (bool value) {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _acceptingNewFriendsValue = value;
                      _acceptingNewFriendsChanged = true;
                    });
                  },
                  activeThumbColor: Styles.accentColor,
                  activeTrackColor: Styles.primaryColor,
                  inactiveThumbColor: Styles.white,
                  inactiveTrackColor: Styles.grey,
                ),
              ),
              SizedBox(
                width: MediaQuery.of(context).size.width*0.8,
                child: SwitchListTile(
                  title: Text("Log Out Automatically", style: Styles.headingFont),
                  subtitle: Text("You will be automatically logged out after a period of inactivity.", style: Styles.textFont.copyWith(color: Styles.grey)),
                  value: _automaticallyLogOutValue,
                  onChanged: (bool value) {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _automaticallyLogOutValue = value;
                      _automaticallyLogOutChanged = true;
                    });
                  },
                  activeThumbColor: Styles.accentColor,
                  activeTrackColor: Styles.primaryColor,
                  inactiveThumbColor: Styles.white,
                  inactiveTrackColor: Styles.grey,
                ),
              ),
              ElevatedButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                _saveSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Styles.lighterBackgroundColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                side: BorderSide(color: Styles.white, width: 3),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20)
              ),
              child: Text("Save", style: Styles.headingFont)),
              SizedBox(height: MediaQuery.of(context).size.height*0.03)
            ],
          ),
          SizedBox(width: MediaQuery.of(context).size.width*0.1), // Right padding
        ]
      )
    );
  }
  Future<void> _saveSettings() async {
    if (!_defaultCurrencyChanged && !_paymentReminderChanged && !_acceptingNewFriendsChanged && !_automaticallyLogOutChanged && !_notificationsChanged) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No changes to save!", style: Styles.textFont), showCloseIcon: true, duration: Duration(seconds: 3), backgroundColor: Styles.grey, behavior: SnackBarBehavior.floating, margin: EdgeInsets.all(20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Styles.white, width: 3)))
      );
      return;
    }
    if (_defaultCurrencyChanged) {
      await FirebaseFirestore.instance.collection("private-users").doc(FirebaseAuth.instance.currentUser!.uid).update({
        "preferredCurrency": _defaultCurrencyController.text.substring(0, 3) // Extract ISO code from label
      });
      _defaultCurrencyChanged = false;
    }
    if (_paymentReminderChanged) {
      await FirebaseFirestore.instance.collection("private-users").doc(FirebaseAuth.instance.currentUser!.uid).update({
        "paymentReminderFrequency": _paymentReminderController.text
      });
      _paymentReminderChanged = false;
    }
    if (_acceptingNewFriendsChanged) {
      await FirebaseFirestore.instance.collection("public-users").doc(FirebaseAuth.instance.currentUser!.uid).update({
        "acceptingNewFriends": _acceptingNewFriendsValue
      });
      _acceptingNewFriendsChanged = false;
    }
    if (_automaticallyLogOutChanged) {
      await FirebaseFirestore.instance.collection("private-users").doc(FirebaseAuth.instance.currentUser!.uid).update({
        "automaticallyLogOut": _automaticallyLogOutValue
      });
      _automaticallyLogOutChanged = false;
    }
     if (_notificationsChanged) {
      await FirebaseFirestore.instance.collection("private-users").doc(FirebaseAuth.instance.currentUser!.uid).update({
        "notifications": _notificiationsValue,
      });
      _notificationsChanged = false;
    }
    if (await checkInternertConnection() == false) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No network connection. Your changes are saved locally, but connect to the internet soon please.", style: Styles.textFont), showCloseIcon: true, duration: Duration(seconds: 3), backgroundColor: Styles.red, behavior: SnackBarBehavior.floating, margin: EdgeInsets.all(20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Styles.white, width: 3)))
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Settings saved successfully!", style: Styles.textFont), showCloseIcon: true, duration: Duration(seconds: 3), backgroundColor: Styles.accentColor, behavior: SnackBarBehavior.floating, margin: EdgeInsets.all(20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Styles.white, width: 3)))
      );
    }
  }

  @override
  void dispose() {
    _defaultCurrencyController.dispose();
    _paymentReminderController.dispose();
    super.dispose();
  }

}