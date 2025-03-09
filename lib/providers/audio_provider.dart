import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:fluske/common/global.dart';
import 'package:fluske/models/AudioModel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../common/apipath.dart';
import 'dart:io';

import '../services/audio_service.dart';

class AudioProvider with ChangeNotifier {
  AudioModel data = AudioModel();
  bool loading = false;
  AudioServices services = AudioServices();

  getAudioData(context) async {
    loading = true;
    data = await services.loadData(context);
    loading = false;
    notifyListeners();
  }

  AudioModel audioModel = AudioModel();

  Future<AudioModel> loadData() async {
    var token;
    if (kIsWeb) {
      SharedPreferences sharedPreferences =
          await SharedPreferences.getInstance();
      token = sharedPreferences.getString('token');
    } else {
      token = await storage.read(key: "authToken");
    }
    final response = await http.get(
      Uri.parse(APIData.audios),
      headers: {
        HttpHeaders.authorizationHeader: "Bearer $token",
      },
    );
    print("Audio API Status Code :-> ${response.statusCode}");
    log("Audios API Response :-> ${response.body}");
    if (response.statusCode == 200) {
      return audioModel = AudioModel.fromJson(jsonDecode(response.body));
      // print("Audio API Status Code :-> ${response.statusCode}");
      // notifyListeners();
    } else {
      print("Audio API Status Code :-> ${response.statusCode}");
      return AudioModel();
    }
  }
}
