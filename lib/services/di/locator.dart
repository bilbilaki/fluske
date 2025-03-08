import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../../ui/gateways/phonepe_in.dart';

final locator = GetIt.instance;

void setUpLocator() {
  locator.registerLazySingleton(() => PhonePeCheckoutViewModel());
}
