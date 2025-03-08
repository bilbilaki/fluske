// lib/screens/otp_login_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:pinput/pinput.dart';
import 'package:provider/provider.dart';

import '../../common/apipath.dart';
import '../../common/route_paths.dart';
import '../../common/styles.dart';
import '../../providers/user_profile_provider.dart';
import '../../services/otp_auth_provider.dart';

class OtpLoginScreen extends StatefulWidget {
  @override
  _OtpLoginScreenState createState() => _OtpLoginScreenState();
}

class _OtpLoginScreenState extends State<OtpLoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  // final TextEditingController _otpController = TextEditingController();
  PhoneCountryData? _initialCountryDataFiltered;
  Future<void> _sendOtp() async {
    var phoneNumber = _phoneController.text.replaceAll(' ', '');
    try {
      await Provider.of<OtpAuthProvider>(context, listen: false)
          .sendOtp('+' + _initialCountryDataFiltered!.phoneCode! + phoneNumber);
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
          'Failed to send OTP',
          style: TextStyle(color: Colors.black),
        )),
      );
    }
  }

  Future<void> _verifyOtp(context, pin) async {
    try {
      final authProvider = Provider.of<OtpAuthProvider>(context, listen: false);
      await Provider.of<OtpAuthProvider>(context, listen: false)
          .verifyOtp(context, pin);

      // await Provider.of<OtpAuthProvider>(context, listen: false)
      //     .verifyOtp(_otpController.text);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Valid OTP')),
      );
      if (authProvider.loginStatus == true) {
        final userDetails =
            Provider.of<UserProfileProvider>(context, listen: false)
                .userProfileModel!;
        if (userDetails.payment == "Free") {
          Navigator.pushNamed(context, RoutePaths.bottomNavigationHome);
        } else if (userDetails.active == 1 || userDetails.active == "1") {
          Navigator.pushNamed(context, RoutePaths.multiScreen);
        } else {
          Navigator.pushNamed(context, RoutePaths.bottomNavigationHome);
        }
      }
      // Navigator.pushReplacement(
      //   context,
      //   MaterialPageRoute(builder: (context) => HomeScreen()),
      // );
    } catch (error) {
      print(error);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid OTP')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<OtpAuthProvider>(context);
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 60,
      textStyle: const TextStyle(
        fontSize: 22,
        color: Colors.white,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.transparent),
      ),
    );
    return Scaffold(
        // appBar: AppBar(
        //   leading: BackButton(
        //     onPressed: () => Navigator.pushNamed(context, RoutePaths.loginHome),
        //   ),
        //   title: Text(
        //     "Login",
        //     style: TextStyle(
        //       fontSize: 16.0,
        //       letterSpacing: 0.9,
        //     ),
        //   ),
        //   centerTitle: true,
        //   backgroundColor: Theme.of(context).primaryColorDark,
        // ),
        // AppBar(
        //   title: Text('OTP Login'),
        // ),
        backgroundColor: Theme.of(context).primaryColorLight,
        body: authProvider.isOtpSent
            ? SingleChildScrollView(
                padding: const EdgeInsets.all(0),
                child: Container(
                  margin: const EdgeInsets.only(top: 0),
                  width: double.infinity,
                  child: Column(
                    children: [
                      const Text(
                        "Verification",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 40, bottom: 10),
                        child: const Text(
                          "Enter the code sent to your number",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(bottom: 40),
                        child: Text(
                          "+91 ${_phoneController.text}",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      Pinput(
                        length: 6,
                        defaultPinTheme: defaultPinTheme,
                        focusedPinTheme: defaultPinTheme.copyWith(
                          decoration: defaultPinTheme.decoration!.copyWith(
                            border: Border.all(
                                color: Theme.of(context).primaryColor),
                          ),
                        ),
                        onCompleted: (pin) =>
                            {debugPrint(pin), _verifyOtp(context, pin)},
                      ),
                      SizedBox(
                        height: 30,
                      ),
                      Text("Didn't get OTP code?",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          )),
                      TextButton(
                        onPressed: _sendOtp,
                        child: Text(
                          'Resend OTP',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: CountryDropdown(
                            printCountryName: true,
                            initialCountryData:
                                PhoneCodes.getPhoneCountryDataByCountryCode(
                              APIData.initialCountryCode,
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Theme.of(context)
                                  .primaryColor
                                  .withOpacity(0.05),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide.none,
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide.none,
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              // labelText: 'Country',
                              labelStyle: TextStyle(
                                  color: Theme.of(context).primaryColor),
                            ),
                            onCountrySelected: (PhoneCountryData countryData) {
                              setState(() {
                                _initialCountryDataFiltered = countryData;
                              });
                            },
                          ),
                        ),
                        SizedBox(width: 10.0),
                        Expanded(
                          flex: 5,
                          child: TextFormField(
                            controller: _phoneController,
                            key: Key(_initialCountryDataFiltered?.countryCode ??
                                'country2'),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Theme.of(context)
                                  .primaryColor
                                  .withOpacity(0.05),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide.none,
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide.none,
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              labelText: 'Phone Number',
                              labelStyle: TextStyle(
                                  color: Theme.of(context).primaryColor),
                            ),
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              PhoneInputFormatter(
                                allowEndlessPhone: true,
                                defaultCountryCode:
                                    _initialCountryDataFiltered?.countryCode,
                              )
                            ],
                          ),
                        )
                      ],
                    ),

                    SizedBox(
                      height: 20,
                    ),

                    // if (authProvider.isOtpSent)
                    //   TextField(
                    //     controller: _otpController,
                    //     decoration: InputDecoration(labelText: 'Enter OTP'),
                    //     keyboardType: TextInputType.number,
                    //   ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5.0)),
                        minimumSize:
                            Size(MediaQuery.of(context).size.width - 50, 40),
                        backgroundColor: Theme.of(context).primaryColor,
                        padding: EdgeInsets.symmetric(vertical: 15.0),
                      ),
                      child:
                          // _isLoading == true
                          //     ? SizedBox(
                          //         height: 20.0,
                          //         width: 20.0,
                          //         child:
                          //             CircularProgressIndicator(
                          //           strokeWidth: 2.0,
                          //           valueColor:
                          //               AlwaysStoppedAnimation(
                          //                   primaryBlue),
                          //         ),
                          //       )
                          //     :

                          authProvider.isLoading
                              ?
                              // Text("${authProvider.isLoading}")
                              SizedBox(
                                  height: 25.0,
                                  width: 25.0,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.0,
                                    valueColor:
                                        AlwaysStoppedAnimation(primaryBlue),
                                  ),
                                )
                              : Text(
                                  authProvider.isOtpSent
                                      ? 'Verify OTP'
                                      : 'Request OTP',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                      onPressed: authProvider.isLoading ? null : _sendOtp,
                      // authProvider.isOtpSent ? _verifyOtp : _sendOtp,
                    ),

                    authProvider.isOtpSent
                        ? Padding(
                            padding: EdgeInsets.symmetric(horizontal: 15.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: _sendOtp,
                                  child: Text(
                                    'Resend OTP',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : SizedBox.shrink(),
                    // ElevatedButton(
                    //   onPressed: authProvider.isOtpSent ? _verifyOtp : _sendOtp,
                    //   child: Text(authProvider.isOtpSent ? 'Verify OTP' : 'Send OTP'),
                    // ),
                  ],
                ),
              ));
  }
}
