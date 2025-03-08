import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:http/http.dart' as http;
import '../../common/apipath.dart';
import '../../common/global.dart';
import '../../common/route_paths.dart';
import '../../providers/phonepe_base.dart';
import 'package:phonepe_payment_sdk/phonepe_payment_sdk.dart';

import '../screens/splash_screen.dart';

class PhonePeCheckoutViewModel extends BaseModel {
  String jsonString = "";
  Object? result;
  String environmentValue = 'PRODUCTION';
  String appId = "";
  String callBackUrl =
      "https://templatecookies.com/clickplay/public/callback-url";
  String merchantId = "M1PAPUAXSOUZ";
  bool enableLog = true;
  String packageName = "com.clicktventertainment.clicknplays";
  void phonepeInit() {
    PhonePePaymentSdk.init(environmentValue, appId, merchantId, enableLog)
        .then((val) {
      result = 'PhonePe SDK Initialized - $val';
      updateUI();
    }).catchError((error) {
      handleError(error);
    });
  }

  startTransaction(callbackUrl, packageName, context, amount, merchantId,
      saltKey, planDetails) async {
    phonepeInit();
    final data = {
      "merchantId": merchantId,
      "merchantTransactionId": "MT${getRandomNumber()}",
      "merchantUserId": "MU${getRandomNumber()}",
      "amount": amount * 100,
      "callbackUrl": callbackUrl,
      "mobileNumber": "9602645856",
      "paymentInstrument": {"type": "PAY_PAGE"}
      // "deviceContext": {"deviceOS": "ANDROID"}
    };
    jsonString = jsonEncode(data);
    var saltkey = saltKey;
    const apiEndPoint = "/pg/v1/pay";
    const saltIndex = "1";
    String base64Data = jsonString.toBase64;
    String dataToHash = base64Data + apiEndPoint + saltkey;
    String sHA256 = generateSha256Hash(dataToHash);

    debugPrint(base64Data);
    debugPrint("SHA256>>>>>>>>$sHA256");
    debugPrint("$sHA256###$saltIndex");
    String body = base64Data;
    String checksum = "$sHA256###$saltIndex";

    debugPrint("body>>>>>$body");
    debugPrint("checksum>>>>>$checksum");

    try {
      PhonePePaymentSdk.startTransaction(
              body, callbackUrl, checksum, packageName)
          .then((response) {
        debugPrint("response>>>>>$response");
        if (response != null) {
          String status = response['status'].toString();
          String error = response['error'].toString();
          if (status == 'SUCCESS') {
            result = "Flow Completed - Status: Success!";
            sendPaymentDetails(response, planDetails, context);
            // Navigator.popAndPushNamed(context, Routes.paymentSuccessful);
          } else {
            result = "Flow Completed - Status: $status and Error: $error";
            // Navigator.popAndPushNamed(context, Routes.paymentFailed);
            updateUI();
          }
        } else {
          result = "Flow Incomplete";
          updateUI();
        }
      }).catchError((error) {
        handleError(error);
      });
    } catch (error) {
      handleError(error);
    }
  }

  //  goToDialog2() {
  //   if (isShowing == true) {
  //     showDialog(
  //       context: context,
  //       barrierDismissible: false,
  //       builder: (context) => PopScope(
  //         child: AlertDialog(
  //           shape: RoundedRectangleBorder(
  //             borderRadius: BorderRadius.all(
  //               Radius.circular(25.0),
  //             ),
  //           ),
  //           backgroundColor: Colors.white,
  //           title: Text(
  //             "Saving Payment Info",
  //             style: TextStyle(color: Theme.of(context).colorScheme.background),
  //           ),
  //           content: Container(
  //             height: 70.0,
  //             width: 150.0,
  //             child: Center(
  //               child: CircularProgressIndicator(),
  //             ),
  //           ),
  //         ),
  //         canPop: false,
  //         onPopInvoked: (didPop) {
  //           if (didPop) {
  //             return;
  //           }
  //           isBack;
  //         },
  //       ),
  //     );
  //   } else {
  //     Navigator.pop(context);
  //   }
  // }

  String generateSha256Hash(String input) {
    var bytes = utf8.encode(input);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  String getRandomNumber() {
    Random random = Random();
    String randomMerchant = "";
    for (int i = 0; i < 15; i++) {
      randomMerchant += random.nextInt(10).toString();
    }
    debugPrint("random Merchant>>>>> $randomMerchant");
    return randomMerchant;
  }

  void handleError(error) {
    if (error is Exception) {
      result = error.toString();
      updateUI();
    } else {
      result = {"error": error};
      updateUI();
    }
  }

  Future<String?> sendPaymentDetails(response, planDetails, context) async {
    // goToDialog2();
    // var planDetails = Provider.of<AppConfig>(context, listen: false).planList;
    var am = planDetails.amount;
    var plan1 = planDetails.id;

    final sendResponse =
        await http.post(Uri.parse(APIData.sendRazorDetails), body: {
      "reference": "$response",
      "amount": "$am",
      "plan_id": "$plan1",
      "status": "1",
      "method": "PhonePe",
    }, headers: {
      HttpHeaders.authorizationHeader: "Bearer $authToken"
    });

    if (sendResponse.statusCode == 200) {
      Navigator.pushNamed(
        context,
        RoutePaths.splashScreen,
        arguments: SplashScreen(
          token: authToken,
        ),
      );
    } else {
      Fluttertoast.showToast(msg: "Your transaction failed contact to Admin.");
    }
    return null;
  }
}

// void _increament(){
//   counter++;
// updateUI();
// }
// void _decreament(){
//   counter--;
//   updateUI();
// }

extension EncodingExtensions on String {
  /// To Base64
  /// This is used to convert the string to base64
  String get toBase64 {
    return base64.encode(toUtf8);
  }

  /// To Utf8
  /// This is used to convert the string to utf8
  List<int> get toUtf8 {
    return utf8.encode(this);
  }

  /// To Sha256
  /// This is used to convert the string to sha256
  String get toSha256 {
    return sha256.convert(toUtf8).toString();
  }
}
