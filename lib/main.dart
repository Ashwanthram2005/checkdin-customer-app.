import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'appearance.dart';
import 'theme.dart';
import 'screens/location_settings.dart';
import 'screens/refunds.dart';
import 'screens/login.dart';
import 'screens/otp.dart';
import 'screens/profile_setup.dart';
import 'screens/search.dart';
import 'screens/search_picker.dart';
import 'screens/date_select.dart';
import 'screens/time_select.dart';
import 'screens/results.dart';
import 'screens/hotel_detail.dart';
import 'screens/reserve.dart';
import 'screens/payment.dart';
import 'screens/booking_success.dart';
import 'screens/account.dart';
import 'screens/edit_profile.dart';
import 'screens/bookings.dart';
import 'screens/booking_detail.dart';
import 'screens/payment_methods.dart';
import 'screens/help.dart';
import 'screens/home.dart';
import 'screens/saved.dart';
import 'screens/offers.dart';
import 'screens/cancel_policy.dart';
import 'screens/legal.dart';
import 'screens/add_card.dart';
import 'screens/rate_stay.dart';
import 'screens/notifications.dart';
import 'screens/full_day_search.dart';
import 'screens/full_day_results.dart';
import 'screens/payment_failed.dart';
import 'screens/splash.dart';
import 'screens/policy_doc.dart';
import 'screens/credits_history.dart';
import 'screens/states.dart';
import 'screens/gallery.dart';
import 'screens/reviews.dart';
import 'screens/report_issue.dart';
import 'screens/delete_account.dart';
import 'screens/stay.dart';
import 'screens/support_chat.dart';
import 'screens/coming_soon.dart';
import 'screens/refer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Appearance.load();
  await loadLocationChoice();
  runApp(const CheckdinApp());
}

class CheckdinApp extends StatefulWidget {
  const CheckdinApp({super.key});
  @override
  State<CheckdinApp> createState() => _CheckdinAppState();
}

class _CheckdinAppState extends State<CheckdinApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    // Checkdin is light-only; the phone's dark setting is ignored.
  }

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: C.dark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: C.bg,
      canvasColor: C.bg,
      dividerColor: C.line,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFD1F148),
        brightness: C.dark ? Brightness.dark : Brightness.light,
        primary: C.ink,
        onPrimary: C.bg,
        surface: C.bg,
        onSurface: C.ink,
      ),
      iconTheme: IconThemeData(color: C.ink),
      splashFactory: InkRipple.splashFactory,
      // Android back swipe shows the screen underneath before you let go.
      pageTransitionsTheme: PageTransitionsTheme(builders: {
        TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
      }),
    );
    return MaterialApp(
      title: 'Checkdin',
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        textTheme: tabularDigits(GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(bodyColor: C.ink, displayColor: C.ink)),
        textSelectionTheme: TextSelectionThemeData(cursorColor: C.ink, selectionColor: C.limeSoft, selectionHandleColor: C.ink),
      ),
      builder: (context, child) => OfflineGate(child: child ?? const SizedBox()),
      initialRoute: '/splash',
      routes: {
        '/splash': (_) => const SplashScreen(),
        '/location': (_) => const LocationSettingsScreen(),
        '/refunds': (_) => const RefundsScreen(),
        '/policy': (_) => const PolicyDocScreen(),
        '/credits': (_) => const CreditsHistoryScreen(),
        '/gallery': (_) => const GalleryScreen(),
        '/reviews': (_) => const ReviewsScreen(),
        '/report': (_) => const ReportIssueScreen(),
        '/delete-account': (_) => const DeleteAccountScreen(),
        '/checkin': (_) => const CheckinOtpScreen(),
        '/live': (_) => const LiveStayScreen(),
        '/chat': (_) => const SupportChatScreen(),
        '/coming-soon': (_) => const ComingSoonScreen(),
        '/refer': (_) => const ReferScreen(),
        '/': (_) => const LoginScreen(),
        '/otp': (_) => const OtpScreen(),
        '/profile-setup': (_) => const ProfileSetupScreen(),
        '/search': (_) => const SearchScreen(),
        '/picker': (_) => const SearchPickerScreen(),
        '/date': (_) => const DateSelectScreen(),
        '/time': (_) => const TimeSelectScreen(),
        '/results': (_) => const ResultsScreen(),
        '/hotel': (_) => const HotelDetailScreen(),
        '/reserve': (_) => const ReserveScreen(),
        '/payment': (_) => const PaymentScreen(),
        '/success': (_) => const BookingSuccessScreen(),
        '/account': (_) => const AccountScreen(),
        '/edit-profile': (_) => const EditProfileScreen(),
        '/bookings': (_) => const BookingsScreen(),
        '/booking-detail': (_) => const BookingDetailScreen(),
        '/payment-methods': (_) => const PaymentMethodsScreen(),
        '/help': (_) => const HelpScreen(),
        '/home': (_) => const HomeScreen(),
        '/saved': (_) => const SavedScreen(),
        '/offers': (_) => const OffersScreen(),
        '/cancel-policy': (_) => const CancelPolicyScreen(),
        '/legal': (_) => const LegalScreen(),
        '/add-card': (_) => const AddCardScreen(),
        '/rate': (_) => const RateStayScreen(),
        '/notifications': (_) => const NotificationsScreen(),
        '/fullday': (_) => const FullDaySearchScreen(),
        '/fullday-results': (_) => const FullDayResultsScreen(),
        '/payment-failed': (_) => const PaymentFailedScreen(),
      },
    );
  }
}


/// Same-width digits everywhere (prices, timers, IDs) so numbers don't jump.
TextTheme tabularDigits(TextTheme t) {
  const f = [FontFeature.tabularFigures()];
  TextStyle? x(TextStyle? s) => s?.copyWith(fontFeatures: f);
  return t.copyWith(
    displayLarge: x(t.displayLarge),
    displayMedium: x(t.displayMedium),
    displaySmall: x(t.displaySmall),
    headlineLarge: x(t.headlineLarge),
    headlineMedium: x(t.headlineMedium),
    headlineSmall: x(t.headlineSmall),
    titleLarge: x(t.titleLarge),
    titleMedium: x(t.titleMedium),
    titleSmall: x(t.titleSmall),
    bodyLarge: x(t.bodyLarge),
    bodyMedium: x(t.bodyMedium),
    bodySmall: x(t.bodySmall),
    labelLarge: x(t.labelLarge),
    labelMedium: x(t.labelMedium),
    labelSmall: x(t.labelSmall),
  );
}
