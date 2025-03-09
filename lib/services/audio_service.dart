import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../common/apipath.dart';
import '../common/global.dart';
import '../models/AudioModel.dart';

class AudioServices {
  Future<AudioModel> loadData(context) async {
    AudioModel audioModel = AudioModel();
    var token;
    if (kIsWeb) {
      SharedPreferences sharedPreferences =
          await SharedPreferences.getInstance();
      token = sharedPreferences.getString('token');
    } else {
      token = await storage.read(key: "authToken");
    }
    try {
      final response = await http.get(
        Uri.parse(APIData.audios),
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
          HttpHeaders.authorizationHeader: "Bearer $token",
        },
      );
      print("Audio API Status Code :-> ${response.statusCode}");
      log("Audios API Response :-> ${response.body}");
      if (response.statusCode == 200) {
        final item = json.decode(response.body);
        audioModel = AudioModel.fromJson(item);
        // notifyListeners();
      } else {
        print('Error Occurred');
      }
    } catch (e) {
      print('Error Occurred' + e.toString());
    }
    return audioModel;
  }
}
