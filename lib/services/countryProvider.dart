
String countryName = "AUSTRALIA";
 int statusCode = 200;
Future<void> getCountry() async {
  if (statusCode == 200) {
    var body = "country_name";
    countryName = "AUSTRALIA";
    print("Country : $countryName");
  } else {
    print("Country : ${countryName}");
  }
}
