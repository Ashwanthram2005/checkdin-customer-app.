import 'dart:math' as math;

import '../state.dart';
import 'fake_api.dart';

/// Everything the app asks the Checkdin server for.
///
/// Screens only talk to [api]. Today that is [FakeApi] (sample data with
/// realistic delays). When the real server is ready, write `HttpApi implements
/// CheckdinApi` and change the one line at the bottom of this file.
abstract class CheckdinApi {
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
  Future<String> pay({required String method, required int amount, bool simulateFailure = false});
  Future<bool> verifyUpiId(String vpa);
  Future<void> checkCoupon(String code);
  Future<int> cancelBooking(String bookingId, String reason);
  Future<void> extendStay(String bookingId, int hours);
  Future<void> checkOut(String bookingId);

  // account
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

/// The one line to change when the real backend is ready.
final CheckdinApi api = FakeApi();
