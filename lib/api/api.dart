import 'dart:math' as math;

import '../state.dart';
import 'fake_api.dart';

/// Everything the app asks the Checkdin server for.
///
/// Screens only talk to [api]. Today that is [FakeApi] (sample data with
/// realistic delays). When the real server is ready, write `HttpApi implements
/// CheckdinApi` and change the one line at the bottom of this file.
abstract class CheckdinApi {
  // app
  /// 'ok', 'update' (this version is too old) or 'maintenance' (server down for work).
  Future<String> appStatus();

  // auth
  /// Checks the saved login on this phone. True = go straight to Home.
  Future<bool> restoreSession();
  Future<void> sendOtp(String phone);
  /// Returns true when this phone number is new (needs profile setup).
  Future<bool> verifyOtp(String phone, String code);
  Future<void> googleSignIn(String email);

  // discovery
  Future<void> homeFeed();
  Future<List<String>> suggestPlaces(String query);
  Future<List<Hotel>> searchHotels({String? place, required bool fullDay});
  Future<Hotel> hotelDetails(String hotelId);
  Future<void> hotelReviews(String hotelId);
  /// Price for the selected date, slot and guests (null = slot not offered).
  Future<int?> quote(String hotelId);

  // booking & payment
  /// [idempotencyKey]: one key per payment attempt. If the same request
  /// reaches the server twice (double tap, network retry), it charges once.
  Future<String> pay({required String method, required int amount, required String idempotencyKey, bool simulateFailure = false});
  Future<bool> verifyUpiId(String vpa);
  Future<void> checkCoupon(String code);
  Future<int> cancelBooking(String bookingId, String reason, {required String idempotencyKey});
  Future<void> extendStay(String bookingId, int hours, {required String idempotencyKey});
  Future<void> checkOut(String bookingId);

  // account
  Future<void> setSaved(String hotelId, bool saved);
  Future<void> setPreference(String key, bool on);
  Future<void> markNotificationsRead();
  Future<void> removeCard(String last4);
  Future<void> myBookings();
  Future<void> bookingDetail(String bookingId);
  Future<void> savedHotels();
  Future<void> offers();
  Future<void> refunds();
  Future<void> creditsHistory();
  Future<void> notifications();
  Future<void> account();
  Future<void> paymentMethods();
  Future<void> saveCard();
  Future<void> updateProfile();
  Future<void> submitReview();
  Future<String> reportIssue(String type, String text);
  Future<void> deleteAccount();
}

/// Problems the server can report. [message] is safe to show to the guest.
class ApiError implements Exception {
  final String code, message;
  const ApiError(this.code, this.message);
  @override
  String toString() => message;
}

/// Test switch for the fake backend (Account → long-press the version line).
enum NetMode { fast, slow, fail }

extension NetModeLabel on NetMode {
  String get label => switch (this) {
        NetMode.fast => 'Fast',
        NetMode.slow => 'Slow 3G',
        NetMode.fail => 'Always fail',
      };
}

final rng = math.Random();

/// A fresh random key for one money-moving attempt (pay, cancel, extend).
String newIdempotencyKey() {
  final r = math.Random.secure();
  return List.generate(16, (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
}

/// The one line to change when the real backend is ready.
final CheckdinApi api = FakeApi();

/// Test switches for situations that are hard to cause on purpose
/// (Account → long-press the version line → Simulate). The real server
/// produces these on its own; only the fake backend reads them.
class Sim {
  static bool forceUpdate = false;
  static bool maintenance = false;
  static bool priceChange = false;
  static bool soldOut = false;
  static bool hotelUnavailable = false;
  static bool missedCheckin = false;
  /// The next request answers "logged out".
  static bool expireSession = false;

  /// Called when the server says the login is no longer valid.
  /// The app shows "Please log in again".
  static void Function()? onSessionExpired;
}
