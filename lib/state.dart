import 'package:flutter/foundation.dart';

import 'theme.dart';

/// Sample hotel. Replace with data from your backend.
class Hotel {
  final String id, name, area, address, rating;
  final double distanceKm;
  final int reviews;
  final bool topRated;
  final List<String> tags;
  /// Price for 3, 6, 9, 12 hours. null = sold out.
  final List<int?> prices;
  /// Price per night for full-day stays.
  final int night;
  /// Map position.
  final double lat, lng;
  const Hotel({
    required this.id,
    required this.name,
    required this.area,
    required this.address,
    required this.rating,
    required this.distanceKm,
    required this.reviews,
    required this.topRated,
    required this.tags,
    required this.prices,
    this.night = 1999,
    this.lat = 13.0418,
    this.lng = 80.2341,
  });

  int? priceFor(int slot) => prices[[3, 6, 9, 12].indexOf(slot)];
}

const hotels = <Hotel>[
  Hotel(
    id: 'gr',
    name: 'The Grand Residency',
    area: 'T. Nagar',
    address: '12, Usman Road, T. Nagar, Chennai 600017',
    rating: '4.4',
    distanceKm: 0.4,
    reviews: 128,
    topRated: true,
    tags: ['Couple friendly', 'Local ID accepted', 'AC'],
    prices: [849, 1299, 1599, 1899],
    night: 2499,
    lat: 13.0405,
    lng: 80.2337,
  ),
  Hotel(
    id: 'ls',
    name: 'Lotus Stay Inn',
    area: 'T. Nagar',
    address: '4, Ranganathan Street, T. Nagar, Chennai 600017',
    rating: '4.1',
    distanceKm: 1.1,
    reviews: 64,
    topRated: false,
    tags: ['Couple friendly', 'Free Wi-Fi'],
    prices: [699, 999, null, 1499],
    night: 1899,
    lat: 13.0425,
    lng: 80.229,
  ),
  Hotel(
    id: 'mi',
    name: 'Hotel Marina Inn',
    area: 'Egmore',
    address: '22, Pantheon Road, Egmore, Chennai 600008',
    rating: '3.9',
    distanceKm: 3.2,
    reviews: 41,
    topRated: false,
    tags: ['Local ID accepted', 'Parking'],
    prices: [749, 1099, 1349, 1649],
    night: 2199,
    lat: 13.0716,
    lng: 80.2585,
  ),
];

/// Extra stays that only take full-day (overnight) bookings.
const fullDayOnly = <Hotel>[
  Hotel(
    id: 'sk',
    name: 'Skyline Suites',
    area: 'OMR',
    address: '88, Rajiv Gandhi Salai, Sholinganallur, Chennai 600119',
    rating: '4.5',
    distanceKm: 12.4,
    reviews: 45,
    topRated: true,
    tags: ['Couple friendly', 'Local ID accepted', 'Pool'],
    prices: [null, null, null, null],
    night: 2899,
    lat: 12.901,
    lng: 80.2279,
  ),
  Hotel(
    id: 'ph',
    name: 'Porur Comfort Inn',
    area: 'Porur',
    address: '9, Mount Poonamallee Road, Porur, Chennai 600116',
    rating: '4.0',
    distanceKm: 8.2,
    reviews: 22,
    topRated: false,
    tags: ['Local ID accepted', 'Parking'],
    prices: [null, null, null, null],
    night: 1499,
    lat: 13.0359,
    lng: 80.1567,
  ),
];

const areas = ['T. Nagar', 'OMR', 'Porur', 'Velachery', 'Anna Nagar', 'Guindy', 'Egmore', 'Adyar'];
const landmarks = [
  ['Chennai Airport', 'Meenambakkam'],
  ['Chennai Central', 'Railway station'],
  ['Marina Beach', 'Triplicane'],
];

/// Shared booking + user state for the whole app.
class AppState extends ChangeNotifier {
  // user
  String phone = '';
  String name = 'Ashwanth';
  String email = '';
  bool whatsappUpdates = true;

  // search
  String? place;
  bool fullDay = false;
  int slot = 3;
  DateTime date = DateTime.now();
  int? hour;
  // full-day (overnight) dates
  DateTime inDate = DateTime.now();
  DateTime outDate = DateTime.now().add(const Duration(days: 1));

  // booking
  Hotel hotel = hotels.first;
  int rooms = 1, adults = 2, kids = 0;
  String? couponCode;
  bool get coupon => couponCode != null;
  int get discount {
    final c = couponCode;
    if (c == null) return 0;
    if (c == 'NEWSTAY' && fullDay) return 0;
    if (c == 'NIGHT150' && (!fullDay || gross < 1500)) return 0;
    switch (c) {
      case 'NEWSTAY':
        final d = (gross * 0.25).round();
        return d > 200 ? 200 : d;
      case 'FIRST40':
        return 40;
      case 'NIGHT150':
        return 150;
    }
    return 0;
  }
  final Set<String> saved = {'gr', 'ls'};
  bool priceAlerts = true;
  // upcoming booking cancelled by the guest
  bool bookingCancelled = false;
  // cards the guest chose to save (shared by checkout and Manage payments)
  final List<SavedCard> cards = [];
  String paidWith = 'UPI';
  // the guest's own posted review (shown on the hotel page)
  MyReview? myReview;
  // logged in with Google (demo)
  bool googleAccount = false;
  // during the stay
  final String checkinOtp = '4827';
  bool checkedIn = false;
  DateTime? stayStart;
  int extraHours = 0;
  int extraPaid = 0;
  // cities the guest asked to be notified about
  final Set<String> notifyCities = {};

  int get stayHours => (fullDay ? nights * 23 : slot) + extraHours;
  DateTime get stayEnd => (stayStart ?? DateTime.now()).add(Duration(hours: stayHours));
  /// Price per extra hour (a little cheaper than the slot's hourly rate).
  int get extendRate {
    final p = hotel.priceFor(slot) ?? hotel.prices.whereType<int>().first;
    return ((p / slot) * 0.8 / 10).round() * 10;
  }
  int cancelRefund = 0;

  void set(VoidCallback fn) {
    fn();
    notifyListeners();
  }

  DateTime get today {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  bool get isToday => DateTime(date.year, date.month, date.day) == today;

  /// First hour that can still be booked for the chosen date.
  int get earliestHour => isToday ? DateTime.now().hour + 1 : 6;

  int get checkInHour => hour ?? earliestHour;
  int get checkOutHour => checkInHour + slot;

  int get nights {
    final a = DateTime(inDate.year, inDate.month, inDate.day);
    final b = DateTime(outDate.year, outDate.month, outDate.day);
    final n = b.difference(a).inDays;
    return n < 1 ? 1 : n;
  }

  /// Price for one unit of the stay: a slot, or one night.
  int? get unitPrice => fullDay ? hotel.night : hotel.priceFor(slot);
  String get stayLabel => fullDay ? '$nights ${nights > 1 ? 'nights' : 'night'}' : '$slot hrs';
  String get inTimeLabel => fullDay ? '12:00 PM' : hourLabel(checkInHour);
  String get outTimeLabel => fullDay ? '11:00 AM' : hourLabel(checkOutHour);
  String get inDateLabel => dateLabel(fullDay ? inDate : date);
  String get outDateLabel =>
      dateLabel(fullDay ? outDate : (checkOutHour >= 24 ? date.add(const Duration(days: 1)) : date));
  String get whenShort => fullDay ? '${dateLabel(inDate)} – ${dateLabel(outDate)}' : '${dateLabel(date)} · ${hourLabel(checkInHour, short: true)}';

  int get gross => fullDay
      ? hotel.night * nights * rooms
      : (hotel.priceFor(slot) ?? hotel.prices.whereType<int>().first) * rooms;
  int get fees => (gross * 0.106).round();
  int get total => gross - discount;

  String get guestsLabel =>
      '$adults ${adults > 1 ? 'guests' : 'guest'}${kids > 0 ? ', $kids ${kids > 1 ? 'kids' : 'kid'}' : ''}';
}

final app = AppState();

class MyReview {
  final String hotelId, text, when;
  final int rating, photos;
  final List<String> tags;
  final bool anonymous;
  const MyReview(this.hotelId, this.rating, this.text, this.tags, this.photos, this.anonymous, this.when);
}

class SavedCard {
  final String brand, last4, expiry, name;
  const SavedCard(this.brand, this.last4, this.expiry, this.name);
  String get label => '${brand == 'Card' ? 'Card' : brand} •••• $last4';
}
