/// Single place to fill in the real Facebook App ID once you have one
/// (https://developers.facebook.com → your app → Settings → Basic).
/// Used to initialize the Facebook JS SDK on web (see `main.dart`) — the
/// native Android/iOS values live in their own platform config files
/// instead ([android/app/src/main/res/values/strings.xml](../../../android/app/src/main/res/values/strings.xml),
/// [ios/Runner/Info.plist](../../../ios/Runner/Info.plist)) since those
/// can't read a Dart constant.
class SocialAuthConfig {
  SocialAuthConfig._();

  static const String facebookAppId = 'YOUR_FACEBOOK_APP_ID';
}
