import 'state.dart';

/// Coupon rules. Discounts come off the booking amount (room + fees).
class CouponDef {
  final String code, title, desc;
  const CouponDef(this.code, this.title, this.desc);
}

const allCoupons = [
  CouponDef('NEWSTAY', '25% off your first stay', 'Up to ₹200 off on any hourly booking.'),
  CouponDef('FIRST40', '₹40 off', 'Flat ₹40 off on any booking.'),
  CouponDef('NIGHT150', '₹150 off full-day stays', 'On full-day bookings above ₹1,500.'),
  CouponDef('BACK8', '8% back as credits', 'Get 8% of this booking back as credits after checkout.'),
  CouponDef('ASHW100', '₹100 off · referral', 'For a friend\'s first stay. Can\'t be used on your own account.'),
];

CouponDef? couponByCode(String code) {
  final c = code.trim().toUpperCase();
  for (final x in allCoupons) {
    if (x.code == c) return x;
  }
  return null;
}

/// Why a coupon can't be used for the current booking, or null if it can.
String? couponProblem(String code) {
  switch (code) {
    case 'NEWSTAY':
      return app.fullDay ? 'Only for hourly bookings' : null;
    case 'NIGHT150':
      if (!app.fullDay) return 'Only for full-day stays';
      if (app.gross < 1500) return 'Add ${inr(1500 - app.gross)} more to use this';
      return null;
    case 'ASHW100':
      return 'This is your own referral code';
  }
  return null;
}

/// Money off now for [code] on the current booking.
int couponDiscount(String code) {
  switch (code) {
    case 'NEWSTAY':
      final d = (app.gross * 0.25).round();
      return d > 200 ? 200 : d;
    case 'FIRST40':
      return 40;
    case 'NIGHT150':
      return 150;
  }
  return 0;
}

/// Credits earned later (BACK8).
int couponCashback(String code) => code == 'BACK8' ? (app.gross * 0.08).round() : 0;

String couponSaving(String code) {
  final d = couponDiscount(code);
  if (d > 0) return 'You save ${inr(d)}';
  final b = couponCashback(code);
  return b > 0 ? 'You get ${inr(b)} back as credits' : '';
}
