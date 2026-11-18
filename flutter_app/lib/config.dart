import 'package:flutter/foundation.dart';

/// Public web address of the app (used for share and invite links). Web builds use their own origin.
String webBaseUrl() {
  if (kIsWeb) return Uri.base.origin;
  const configured = String.fromEnvironment('WEB_URL');
  return configured.endsWith('/') ? configured.substring(0, configured.length - 1) : configured;
}
