import 'dart:core';
import 'package:flutter/material.dart';
import 'package:fluske/common/apipath.dart';
import '/ui/gateways/paypal/paypal_screen.dart';
import '/ui/shared/appbar.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'PaypalServices.dart';

class PaypalPayment extends StatefulWidget {
  final Function? onFinish;
  final String? currency;
  final String? userFirstName;
  final String? userLastName;
  final String? userEmail;
  final String? payAmount;
  final String? planName;
  final planIndex;

  PaypalPayment(
      {this.onFinish,
      this.currency,
      this.userFirstName,
      this.userLastName,
      this.userEmail,
      this.payAmount,
      this.planName,
      this.planIndex});

  @override
  State<StatefulWidget> createState() {
    return PaypalPaymentState();
  }
}

class PaypalPaymentState extends State<PaypalPayment> {
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String? checkoutUrl;
  String? executeUrl;
  String? accessToken;
  PaypalServices services = PaypalServices();
  var paymentResponse;
  List<String>? payResponse = [];

  // you can change default currency according to your need
  Map<dynamic, dynamic> defaultCurrency = {
    "symbol": "USD",
    "decimalDigits": 2,
    "symbolBeforeTheNumber": true,
    "currency": "USD"
  };

  bool isEnableShipping = false;
  bool isEnableAddress = false;

  String returnURL = APIData.domainLink;
  String cancelURL = 'cancel.example.com';

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () async {
      try {
        accessToken = await services.getAccessToken(context);
        print(accessToken);
        final transactions = getOrderParams(widget.userFirstName,
            widget.userLastName, widget.planName, widget.payAmount);

        print(transactions);
        print(widget.payAmount);
        final res =
            await services.createPaypalPayment(transactions, accessToken);
        if (res != null) {
          setState(() {
            checkoutUrl = res["approvalUrl"];
            executeUrl = res["executeUrl"];
          });
        }
      } catch (e) {
        print('exception: ' + e.toString());
        final snackBar = SnackBar(
          content: Text(e.toString()),
          duration: Duration(seconds: 10),
          action: SnackBarAction(
            label: 'Close',
            onPressed: () {
              // Some code to undo the change.
            },
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    });
  }

  int quantity = 1;

  Map<String, dynamic> getOrderParams(
      userFirstName, userLastName, itemName, itemPrice) {
    List items = [
      {
        "name": itemName,
        "quantity": quantity,
        "price": itemPrice,
        "currency": widget.currency
      }
    ];

    // checkout invoice details
    String shippingCost = '0';
    int shippingDiscountCost = 0;
    String addressCity = 'test';
    String addressStreet = 'test';
    String addressZipCode = '880056';
    String addressCountry = 'India';
    String addressState = 'State';
    String addressPhoneNumber = '+918866886688';

    Map<String, dynamic> params = {
      "intent": "sale",
      "payer": {"payment_method": "paypal"},
      "transactions": [
        {
          "amount": {
            "total": itemPrice,
            "currency": widget.currency,
            "details": {
              "subtotal": itemPrice,
              "shipping": shippingCost,
              "shipping_discount": ((-1.0) * shippingDiscountCost).toString()
            }
          },
          "description": "The payment transaction description.",
          "payment_options": {
            "allowed_payment_method": "INSTANT_FUNDING_SOURCE"
          },
          "item_list": {
            "items": items,
            if (isEnableShipping && isEnableAddress)
              "shipping_address": {
                "recipient_name": userFirstName + " " + userLastName,
                "line1": addressStreet,
                "line2": "",
                "city": addressCity,
                "country_code": addressCountry,
                "postal_code": addressZipCode,
                "phone": addressPhoneNumber,
                "state": addressState
              },
          }
        }
      ],
      "note_to_payer": "Contact us for any questions on your order.",
      "redirect_urls": {"return_url": returnURL, "cancel_url": cancelURL}
    };
    return params;
  }

  Widget appBar(title, mode) {
    return AppBar(
      iconTheme: IconThemeData(color: Colors.black),
      elevation: 0.0,
      centerTitle: true,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios),
        onPressed: () => Navigator.pop(context),
      ),
      backgroundColor: Colors.white,
      title: Text(
        title,
        style: TextStyle(
          fontSize: 18.0,
          color: mode.notificationIconColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (checkoutUrl != null) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        appBar: customAppBar(context, "Paypal Payment") as PreferredSizeWidget?,
        body: WebView(
          initialUrl: checkoutUrl,
          javascriptMode: JavascriptMode.unrestricted,
          navigationDelegate: (NavigationRequest request) {
            if (request.url.contains(returnURL)) {
              final uri = Uri.parse(request.url);
              final payerID = uri.queryParameters['PayerID'];
              if (payerID != null) {
                services
                    .executePayment(executeUrl, payerID, accessToken)
                    .then((List<String>? ls) {
                  print("paymentMethod: " +
                      payerID +
                      "  " +
                      accessToken! +
                      " " +
                      ls![0]);
                  setState(() {
                    payResponse = ls;
                  });
                  widget.onFinish!(ls[0]);
                  Navigator.of(context).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PaypalScreen(
                        payId: ls[0],
                        saleId: ls[1],
                        method: "Paypal",
                        amount: widget.payAmount,
                        planIndex: widget.planIndex,
                      ),
                    ),
                  );
                });
              } else {
                Navigator.of(context).pop();
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PaypalScreen(
                    payId: payResponse![0],
                    saleId: payResponse![1],
                    method: "Paypal",
                    amount: widget.payAmount,
                    planIndex: widget.planIndex,
                  ),
                ),
              );
              Navigator.of(context).pop();
            }
            if (request.url.contains(cancelURL)) {
              Navigator.of(context).pop();
            }
            return NavigationDecision.navigate;
          },
        ),
      );
    } else {
      return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          leading: IconButton(
              icon: Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.of(context).pop();
              }),
          backgroundColor: Colors.black12,
          elevation: 0.0,
        ),
        body: Center(
          child: Container(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }
  }
}
