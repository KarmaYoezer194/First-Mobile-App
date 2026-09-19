import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:premium_auth_app/main.dart';

/// Fakes just enough of `firebase_core`'s platform channel that
/// `Firebase.initializeApp()` succeeds with no real backend or platform
/// plugin — `flutter test` runs on the host, with no Android/iOS/web engine
/// underneath, so the real Firebase plugins can't talk to anything. Every
/// other Firebase plugin (firebase_auth, cloud_firestore, ...) checks for
/// this registered default app rather than making its own platform call
/// just to construct `FirebaseAuth.instance` / `FirebaseFirestore.instance`,
/// so this alone is enough to let the widget tree build.
class _FakeFirebasePlatform extends FirebasePlatform {
  @override
  FirebaseAppPlatform app([String name = defaultFirebaseAppName]) {
    return _FakeFirebaseAppPlatform(name);
  }

  @override
  Future<FirebaseAppPlatform> initializeApp({
    String? name,
    FirebaseOptions? options,
  }) async {
    return _FakeFirebaseAppPlatform(name ?? defaultFirebaseAppName);
  }

  @override
  List<FirebaseAppPlatform> get apps => [_FakeFirebaseAppPlatform(defaultFirebaseAppName)];
}

class _FakeFirebaseAppPlatform extends FirebaseAppPlatform {
  _FakeFirebaseAppPlatform(String name)
      : super(
          name,
          const FirebaseOptions(
            apiKey: 'test-api-key',
            appId: 'test-app-id',
            messagingSenderId: 'test-sender-id',
            projectId: 'test-project-id',
          ),
        );
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    FirebasePlatform.instance = _FakeFirebasePlatform();
    await Firebase.initializeApp();
  });

  testWidgets('App boots and shows the splash screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: PremiumAuthApp()));

    // Only pump once here (don't pumpAndSettle) — the splash screen has a
    // deliberate delayed navigation, so settling immediately would time out
    // waiting for that timer/animation to finish.
    await tester.pump();

    expect(find.text('GoBuy'), findsOneWidget);

    // Let the splash screen's delayed navigation actually fire before the
    // test ends — flutter_test fails any test that leaves a Timer pending,
    // and `Future.delayed` (see splash_page.dart) creates exactly that.
    await tester.pump(const Duration(seconds: 5));
  });
}
