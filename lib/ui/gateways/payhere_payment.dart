import 'dart:convert';
import 'dart:io';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:fluske/common/apipath.dart';
import 'package:fluske/common/global.dart';
import 'package:fluske/common/route_paths.dart';
import 'package:fluske/providers/app_config.dart';
import 'package:fluske/providers/payment_key_provider.dart';
import 'package:fluske/providers/user_profile_provider.dart';
import 'package:fluske/ui/screens/splash_screen.dart';
import 'package:fluske/ui/shared/appbar.dart';
import 'package:fluske/ui/shared/success_ticket.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

class PayHerePayment extends StatefulWidget {
  final int planIndex;
  final payAmount;

  PayHerePayment({required this.planIndex, this.payAmount});

  @override
  _PayHerePaymentState createState() => _PayHerePaymentState();
}

class _PayHerePaymentState extends State<PayHerePayment> {
  void loadData() {
    var planDetails = Provider.of<AppConfig>(context).planList;
    var userDetails = Provider.of<UserProfileProvider>(context, listen: false)
        .userProfileModel;
    setState(() {
      fName = lName = userDetails!.user!.name;
      email = userDetails.user!.email!;
      phone = userDetails.user!.mobile;
      merchantId = Provider.of<PaymentKeyProvider>(context, listen: false)
          .paymentKeyModel!
          .payhereMerchantId;
      merchantSecret = Provider.of<PaymentKeyProvider>(context, listen: false)
          .paymentKeyModel!
          .payhereAppSecret;
      currency = "${planDetails[widget.planIndex].currency}";
      amount = double.tryParse(widget.payAmount != null
          ? '${widget.payAmount}'
          : '${planDetails[widget.planIndex].amount}');
      isBack = true;
    });
  }

  var merchantId, merchantSecret;
  var fName, lName, email, phone, address;
  var amount, currency;
  var paymentResponse, createdDate, createdTime;
  bool isShowing = true;
  bool isLoading = true;
  bool isBack = false;
  double progress = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: customAppBar(context, "PayHere Payment") as PreferredSizeWidget,
      body: Center(
        child: !isBack ? CircularProgressIndicator() : _body(),
      ),
    );
  }

  Widget logoContainer() {
    return Container(
      decoration: BoxDecoration(
          color: Theme.of(context).primaryColorLight,
          borderRadius: BorderRadius.circular(10.0)),
      child: ListView(
        shrinkWrap: true,
        scrollDirection: Axis.vertical,
        physics: ClampingScrollPhysics(),
        children: <Widget>[
          Padding(
            padding: EdgeInsets.all(50.0),
            child: Image.asset(
              "assets/payherelogo.png",
              scale: 1.0,
              width: 150.0,
            ),
          )
        ],
      ),
    );
  }

  Widget makeListTile() {
    var planDetails = Provider.of<AppConfig>(context, listen: false).planList;
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      leading: Container(
        padding: EdgeInsets.only(right: 20.0),
        decoration: new BoxDecoration(
          border: new Border(
            right: new BorderSide(
              width: 1.0,
              color: Colors.white24,
            ),
          ),
        ),
        child: Icon(
          FontAwesomeIcons.arrowDownShortWide,
          size: 20.0,
        ),
      ),
      title: Padding(
        padding: EdgeInsets.only(top: 10.0),
        child: Text(
          '${planDetails[widget.planIndex].name}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14.0,
          ),
        ),
      ),
      subtitle: Container(
        height: 40.0,
        child: Column(
          children: <Widget>[
            SizedBox(
              height: 8.0,
            ),
            Row(
              children: <Widget>[
                Expanded(
                  flex: 1,
                  child: Text(
                    'Min duration ' +
                        '${planDetails[widget.planIndex].intervalCount}' +
                        ' days',
                    style: TextStyle(
                      fontSize: 12.0,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      trailing: Column(children: <Widget>[
        widget.payAmount == null
            ? Text("Amount: " +
                '\n' +
                '${planDetails[widget.planIndex].amount} ' +
                '${planDetails[widget.planIndex].currency}')
            : Text("Amount: " +
                '\n' +
                '${widget.payAmount} ' +
                '${planDetails[widget.planIndex].currency}'),
      ]),
    );
  }

  Widget paymentDetailsCard() {
    return Card(
      elevation: 0.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      margin: new EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
      child: Container(
        decoration: BoxDecoration(
            color: Theme.of(context).primaryColorLight,
            borderRadius: BorderRadius.circular(10.0)),
        child: ListView(
          shrinkWrap: true,
          scrollDirection: Axis.vertical,
          physics: ClampingScrollPhysics(),
          children: <Widget>[makeListTile()],
        ),
      ),
    );
  }

  Widget payButtonRow() {
    return Row(
      children: <Widget>[
        Expanded(
          flex: 1,
          child: ButtonTheme(
            height: 45,
            child: ElevatedButton(
              style: ButtonStyle(
                shape: WidgetStateProperty.all<OutlinedBorder?>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                ),
                backgroundColor: WidgetStateProperty.all<Color?>(
                  Color.fromRGBO(72, 163, 198, 1.0),
                ),
              ),
              onPressed: () {
                if ((merchantId == null || merchantId == '') ||
                    (merchantSecret == null || merchantSecret == '')) {
                  Fluttertoast.showToast(
                      msg: "PayHere Merchant ID or Secret is not available.");
                  return;
                } else {
                  startOneTimePayment(context);
                }
              },
              child: Text(
                "Continue Pay",
                // style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        )
      ],
    );
  }

  Widget _body() {
    return Container(
      alignment: Alignment.center,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Container(
            height: 20.0,
          ),
          Card(
            elevation: 8.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            margin: new EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
            child: logoContainer(),
          ),
          SizedBox(
            height: 30.0,
          ),
          paymentDetailsCard(),
          SizedBox(
            height: 20.0,
          ),
          Padding(
            padding: EdgeInsets.only(left: 15.0, right: 15.0),
            child: payButtonRow(),
          )
        ],
      ),
    );
  }

  void showAlert(BuildContext context, String title, String msg) {
    // set up the button
    Widget okButton = TextButton(
      child: Text("OK"),
      onPressed: () {
        Navigator.pop(context);
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text(title),
      content: Text(msg),
      actions: [
        okButton,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  void startOneTimePayment(BuildContext context) async {
    Map paymentObject = {
      "sandbox": true, // true if using Sandbox Merchant ID
      "merchant_id": "$merchantId", // Replace your Merchant ID
      "merchant_secret": "$merchantSecret",
      "notify_url": "", // Pending
      "order_id": "${DateTime.now().millisecondsSinceEpoch}",
      "items": "Course Purchase",
      "amount": "$amount",
      "currency": "$currency",
      "first_name": "$fName",
      "last_name": "$lName",
      "email": "$email",
      "phone": "$phone",
      "address": "$address",
      "city": "",
      "country": "",
      "delivery_address": "",
      "delivery_city": "",
      "delivery_country": "",
      "custom_1": "",
      "custom_2": ""
    };

    var PayHere;
    PayHere.startPayment(paymentObject, (paymentId) {
      print("One Time Payment Success. Payment Id: $paymentId");
      sendPaymentDetails(paymentId, "PayHere");
      showAlert(context, "Payment Success!", "Payment Id: $paymentId");
    }, (error) {
      print("One Time Payment Failed. Error: $error");
      showAlert(context, "Payment Failed", "$error");
    }, () {
      print("One Time Payment Dismissed");
      showAlert(context, "Payment Dismissed", "");
    });
  }

  goToDialog2() {
    if (isShowing == true) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => PopScope(
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(25.0),
              ),
            ),
            backgroundColor: Colors.white,
            title: Text(
              "Saving Payment Info",
              style: TextStyle(color: Color(0xFF3F4654)),
            ),
            content: Container(
              height: 70.0,
              width: 150.0,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),
          canPop: false,
          onPopInvoked: (didPop) {
            if (didPop) {
              return;
            }
            isBack;
          },
        ),
      );
    } else {
      Navigator.pop(context);
    }
  }

  goToDialog(subDate, time, message) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => new GestureDetector(
        child: Container(
          color: Colors.white.withOpacity(0.05),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SuccessTicket(
                msgResponse: "$message",
                subDate: subDate,
                time: time,
                planAmount: widget.payAmount,
              ),
              SizedBox(
                height: 10.0,
              ),
              FloatingActionButton(
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.clear,
                  color: Colors.black,
                ),
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    RoutePaths.splashScreen,
                    arguments: SplashScreen(
                      token: authToken,
                    ),
                  );
                },
              )
            ],
          ),
        ),
      ),
    );
  }

  sendPaymentDetails(transactionId, paymentMethod) async {
    try {
      goToDialog2();
      var planDetails = Provider.of<AppConfig>(context, listen: false).planList;
      var amount = planDetails[widget.planIndex].amount;
      var planId = planDetails[widget.planIndex].id;

      var sendResponse = await http.post(
        Uri.parse(
          APIData.sendRazorDetails, // Pending
        ),
        body: {
          "reference": "$transactionId",
          "amount": "$amount",
          "plan_id": "$planId",
          "status": "1",
          "method": "$paymentMethod",
        },
        headers: {HttpHeaders.authorizationHeader: "Bearer $authToken"},
      );

      paymentResponse = json.decode(sendResponse.body);

      var msgResponse = paymentResponse['message'];
      var subscriptionResponse = paymentResponse['subscription'];
      var date = subscriptionResponse['created_at'];
      var time = subscriptionResponse['created_at'];
      createdDate = DateFormat('d MMM y').format(DateTime.parse(date));
      createdTime = DateFormat('HH:mm a').format(DateTime.parse(time));

      if (sendResponse.statusCode == 200) {
        setState(() {
          isShowing = false;
        });
        goToDialog(createdDate, createdTime, msgResponse);
      } else {
        Fluttertoast.showToast(msg: "Your transaction failed!");
        setState(() {
          isShowing = false;
        });
      }
    } catch (error) {}
  }
}
