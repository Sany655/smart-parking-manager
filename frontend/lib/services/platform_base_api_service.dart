// platform based local basi api service 
// for web localhost is used
// for android and ios 10.0.2.2 is used
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class BaseApiService {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/';
    } else if (Platform.isAndroid || Platform.isIOS) {
      return 'http://10.0.2.2:3000/';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }
}