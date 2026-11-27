import '../state.dart';
import 'api.dart';

/// Sample-data backend with realistic delays. Flip [mode] to test slow or
/// failing networks.
class FakeApi implements CheckdinApi {
  static NetMode mode = NetMode.fast;

  Future<void> _wait([int fastMs = 650]) async {
    switch (mode) {
      case NetMode.fast:
        await Future<void>.delayed(Duration(milliseconds: fastMs + rng.nextInt(350)));
        break;
      case NetMode.slow:
        await Future<void>.delayed(Duration(milliseconds: 1800 + rng.nextInt(1400)));
        break;
      case NetMode.fail:
        await Future<void>.delayed(Duration(milliseconds: 900 + rng.nextInt(500)));
        throw const ApiError('network', 'We couldn\'t reach Checkdin. Check your internet and try again.');
    }
  }

  // ---------------------------------------------------------------- auth
  @override
  Future<void> sendOtp(String phone) => _wait(800);

  @override
  Future<bool> verifyOtp(String phone, String code) async {
    await _wait(700);
    if (code != '1234') throw const ApiError('wrong_otp', 'That OTP is wrong.');
    return app.name.isEmpty;
  }

  @override
  Future<void> googleSignIn(String email) => _wait(900);

  // ---------------------------------------------------------------- discovery
  @override
  Future<void> homeFeed() => _wait(600);

  @override
  Future<List<String>> suggestPlaces(String query) async {
    await _wait(250);
    return const [];
  }

  @override
  Future<List<Hotel>> searchHotels({String? place, required bool fullDay}) async {
    await _wait(800);
    return fullDay ? [...hotels, ...fullDayOnly] : [...hotels];
  }

  @override
  Future<Hotel> hotelDetails(String hotelId) async {
    await _wait(700);
    return [...hotels, ...fullDayOnly].firstWhere((h) => h.id == hotelId, orElse: () => app.hotel);
  }

  @override
  Future<void> hotelReviews(String hotelId) => _wait(700);

  @override
  Future<int?> quote(String hotelId) async {
    await _wait(450);
    return app.unitPrice;
  }

  // ---------------------------------------------------------------- booking
  @override
  Future<String> pay({required String method, required int amount, bool simulateFailure = false}) async {
    await _wait(1600);
    if (simulateFailure) throw const ApiError('payment_failed', 'Your bank declined this payment.');
    return newBookingId(DateTime.now());
  }

  @override
  Future<bool> verifyUpiId(String vpa) async {
    await _wait(700);
    return RegExp(r'^[a-zA-Z0-9._-]{2,}@[a-zA-Z]{2,}$').hasMatch(vpa);
  }

  @override
  Future<void> checkCoupon(String code) => _wait(500);

  @override
  Future<int> cancelBooking(String bookingId, String reason) async {
    await _wait(900);
    return app.cancelRefund;
  }

  @override
  Future<void> extendStay(String bookingId, int hours) => _wait(1100);

  @override
  Future<void> checkOut(String bookingId) => _wait(800);

  // ---------------------------------------------------------------- account
  @override
  Future<void> myBookings() => _wait(700);
  @override
  Future<void> bookingDetail(String bookingId) => _wait(600);
  @override
  Future<void> savedHotels() => _wait(600);
  @override
  Future<void> offers() => _wait(600);
  @override
  Future<void> refunds() => _wait(700);
  @override
  Future<void> creditsHistory() => _wait(600);
  @override
  Future<void> notifications() => _wait(600);
  @override
  Future<void> account() => _wait(500);
  @override
  Future<void> paymentMethods() => _wait(600);
  @override
  Future<void> saveCard() => _wait(900);
  @override
  Future<void> updateProfile() => _wait(700);
  @override
  Future<void> submitReview() => _wait(900);
  @override
  Future<String> reportIssue(String type, String text) async {
    await _wait(900);
    return 'TKT-${1000 + rng.nextInt(9000)}';
  }

  @override
  Future<void> deleteAccount() => _wait(1200);
}
