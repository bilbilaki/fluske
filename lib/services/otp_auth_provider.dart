// lib/providers/auth_provider.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../common/global.dart';
import '../providers/audio_provider.dart';
import '../providers/count_view_provider.dart';
import '../providers/faq_provider.dart';
import '../providers/live_event_provider.dart';
import '../providers/main_data_provider.dart';
import '../providers/menu_provider.dart';
import '../providers/movie_tv_provider.dart';
import '../providers/slider_provider.dart';
import '../providers/user_profile_provider.dart';

class OtpAuthProvider with ChangeNotifier {
  var _token;
  String? _phone;
  bool _isOtpSent = false;
  bool _isLoading = false;
  bool _loginStatus = false;

  String? get token => _token;
  bool get isOtpSent => _isOtpSent;
  bool get isLoading => _isLoading;
  bool get loginStatus => _loginStatus;

  Future<void> sendOtp(String phone) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await http.post(
        Uri.parse('https://clicknplays.com/public/api/send-otp'),
        body: {'mobile': phone},
      );
      print("hello:$response");
      print("hello:${json.decode(response.body)}");
      if (response.statusCode == 200) {
        _phone = phone;
        _isOtpSent = true;
        _isLoading = false;
        notifyListeners();
      } else {
        // Handle error
        _isLoading = false;
        notifyListeners();
        throw Exception('Failed to send OTP');
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw Exception('Failed to send OTP');
    }
  }

  backPress(otpSent) {
    _isOtpSent = otpSent;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> verifyOtp(BuildContext ctx, String otp) async {
    MenuProvider menuProvider = Provider.of<MenuProvider>(ctx, listen: false);
    UserProfileProvider userProfileProvider =
        Provider.of<UserProfileProvider>(ctx, listen: false);
    MainProvider mainProvider = Provider.of<MainProvider>(ctx, listen: false);
    SliderProvider sliderProvider =
        Provider.of<SliderProvider>(ctx, listen: false);
    MovieTVProvider movieTVProvider =
        Provider.of<MovieTVProvider>(ctx, listen: false);
    FAQProvider faqProvider = Provider.of<FAQProvider>(ctx, listen: false);

    final response = await http.post(
      Uri.parse('https://clicknplays.com/public/api/verify-otp'),
      body: {'mobile': _phone, 'otp': otp},
    );

    print('status code type: ${response.body}');
    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      _token = responseData['token'];
      var accessToken = _token['accessToken'];
      print('res: ${_token['accessToken']}');
      print('status code: ${response.statusCode}');
      authToken = accessToken;
      // Store the token securely
      await storage.write(key: "login", value: "true");
      await storage.write(key: "authToken", value: _token['accessToken']);

      await menuProvider.getMenus(ctx);
      await sliderProvider.getSlider();
      await userProfileProvider.getUserProfile(ctx);
      await faqProvider.fetchFAQ(ctx);
      await mainProvider.getMainApiData(ctx);
      await movieTVProvider.getMoviesTVData(ctx);

      await Provider.of<AudioProvider>(ctx, listen: false).loadData();
      await Provider.of<LiveEventProvider>(ctx, listen: false).loadData();
      await Provider.of<CountViewProvider>(ctx, listen: false).loadData();

      _loginStatus = true;
      notifyListeners();
    } else {
      // Handle error
      throw Exception('Invalid OTP');
    }
  }

  Future<void> logout() async {
    _token = null;
    _isOtpSent = false;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');

    notifyListeners();
  }

  Future<void> autoLogin() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('token')) return;

    _token = prefs.getString('token');
    notifyListeners();
  }
}
