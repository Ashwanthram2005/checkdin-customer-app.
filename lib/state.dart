import 'dart:math' as math;

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
class Landmark {
  final String name, sub;
  final double lat, lng;
  const Landmark(this.name, this.sub, this.lat, this.lng);
}

const landmarks = [
  Landmark('Chennai Airport', 'Airport · Meenambakkam', 12.9941, 80.1709),
  Landmark('Chennai Central', 'Railway station · Park Town', 13.0827, 80.2757),
  Landmark('Chennai Egmore', 'Railway station · Egmore', 13.0780, 80.2614),
  Landmark('Koyambedu CMBT', 'Bus terminus · Koyambedu', 13.0687, 80.2050),
  Landmark('Marina Beach', 'Beach · Triplicane', 13.0500, 80.2824),
  Landmark('Phoenix MarketCity', 'Mall · Velachery', 12.9915, 80.2170),
  Landmark('Express Avenue', 'Mall · Royapettah', 13.0587, 80.2641),
  Landmark('Apollo Hospitals', 'Hospital · Greams Road', 13.0630, 80.2510),
  Landmark('Sri Ramachandra Hospital', 'Hospital · Porur', 13.0367, 80.1430),
  Landmark('Chennai Trade Centre', 'Convention centre · Nandambakkam', 13.0160, 80.1820),
  Landmark('Tidel Park', 'IT park · Taramani', 12.9890, 80.2483),
  Landmark('IIT Madras', 'Campus · Guindy', 12.9916, 80.2336),
  Landmark('Kapaleeshwarar Temple', 'Temple · Mylapore', 13.0339, 80.2697),
];

Landmark? landmarkNamed(String? name) {
  for (final l in landmarks) {
    if (l.name == name) return l;
  }
  return null;
}

double _km(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371.0;
  final dLat = (lat2 - lat1) * math.pi / 180, dLng = (lng2 - lng1) * math.pi / 180;
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(lat1 * math.pi / 180) * math.cos(lat2 * math.pi / 180) * math.sin(dLng / 2) * math.sin(dLng / 2);
  return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

/// Distance used for sorting and labels: from the picked landmark, else the usual one.
double kmFor(Hotel h) {
  final l = landmarkNamed(app.place);
  return l == null ? h.distanceKm : _km(l.lat, l.lng, h.lat, h.lng);
}

String kmLabel(Hotel h) {
  final l = landmarkNamed(app.place);
  return l == null ? '${h.distanceKm} km away' : '${kmFor(h).toStringAsFixed(1)} km from ${l.name}';
}

/// Orders stays for the searched place: nearest to a landmark, the picked hotel first,
/// or stays in the picked area first.
List<Hotel> orderForPlace(List<Hotel> list) {
  final l = [...list];
  final p = app.place;
  if (p == null) return l;
  if (landmarkNamed(p) != null) {
    l.sort((a, b) => kmFor(a).compareTo(kmFor(b)));
  } else {
    int rank(Hotel h) => h.name == p ? 0 : (h.area == p ? 1 : 2);
    l.sort((a, b) => rank(a).compareTo(rank(b)));
  }
  return l;
}

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
  String? photoPath;
  bool useLocation = true;
  // during the stay
  final String checkinOtp = '4827';
  bool checkedIn = false;
  DateTime? stayStart;
  int extraHours = 0;
  int extraPaid = 0;
  // cities the guest asked to be notified about
  final Set<String> notifyCities = {};

  int get stayHours => (fullDay ? nights * 23 : slot) + extraHours;
  /// Scheduled check-in for the current booking.
  DateTime get scheduledIn {
    final d = fullDay ? inDate : date;
    return DateTime(d.year, d.month, d.day, fullDay ? 12 : checkInHour % 24);
  }
  DateTime get stayEnd => (stayStart ?? scheduledIn).add(Duration(hours: stayHours));
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
  int get checkOutHour => checkInHour + slot + extraHours;

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
  String get outTimeLabel => fullDay ? hourLabel(11 + extraHours) : hourLabel(checkOutHour);
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
