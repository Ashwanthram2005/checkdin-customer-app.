import 'package:flutter/foundation.dart';

/// Sample hotel. Replace with data from your backend.
class Hotel {
  final String id, name, area, address, rating;
  final double distanceKm;
  final int reviews;
  final bool topRated;
  final List<String> tags;
  /// Price for 3, 6, 9, 12 hours. null = sold out.
  final List<int?> prices;
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

  // booking
  Hotel hotel = hotels.first;
  int rooms = 1, adults = 2, kids = 0;
  bool coupon = false;
  final Set<String> saved = {'gr', 'ls'};
  bool priceAlerts = true;

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

  int get gross => (hotel.priceFor(slot) ?? hotel.prices.whereType<int>().first) * rooms;
  int get fees => (gross * 0.106).round();
  int get total => gross - (coupon ? 40 : 0);

  String get guestsLabel =>
      '$adults ${adults > 1 ? 'guests' : 'guest'}${kids > 0 ? ', $kids ${kids > 1 ? 'kids' : 'kid'}' : ''}';
}

final app = AppState();
