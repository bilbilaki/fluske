import 'dart:convert';
import 'package:http/http.dart' as http;

String countryName = "AUSTRALIA";
 int statusCode = 200;
Future<void> getCountry() async {
  if (statusCode == 200) {
    var body = "country_name";
    countryName = "country_name";
    print("Country : $countryName");
  } else {
    print("Country : ${countryName}");
  }
}
