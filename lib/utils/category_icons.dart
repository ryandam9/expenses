import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Keyword rules mapping a category name to a Font Awesome icon, checked in
/// order against the lower-cased name — the first rule with any matching
/// keyword wins, so more specific rules (pets, vehicles) come before broad
/// ones (home, shopping). Unmatched categories fall back to a generic tag.
const List<(List<String>, FaIconData)> _iconRules = [
  // Pets (Mellow is the household dog).
  (['mellow', 'dog', 'puppy', 'vet', 'veterinar'], FontAwesomeIcons.dog),
  (['cat', 'kitten'], FontAwesomeIcons.cat),
  (['pet'], FontAwesomeIcons.paw),
  // Food & drink.
  (['grocer', 'supermarket'], FontAwesomeIcons.basketShopping),
  (['coffee', 'cafe'], FontAwesomeIcons.mugSaucer),
  (['restaurant', 'dining', 'takeaway', 'food', 'eat'],
      FontAwesomeIcons.utensils),
  (['bar', 'pub', 'alcohol', 'drink'], FontAwesomeIcons.martiniGlass),
  // Housing.
  (['rent', 'mortgage', 'lease'], FontAwesomeIcons.fileContract),
  (['furniture'], FontAwesomeIcons.couch),
  (['repair', 'mainten', 'renovat'], FontAwesomeIcons.screwdriverWrench),
  (['garden', 'lawn', 'plant'], FontAwesomeIcons.leaf),
  (['home', 'house'], FontAwesomeIcons.house),
  // Utilities & services.
  (['electric', 'power', 'energy', 'utilit'], FontAwesomeIcons.bolt),
  (['water'], FontAwesomeIcons.droplet),
  (['internet', 'wifi', 'broadband', 'phone', 'mobile'],
      FontAwesomeIcons.wifi),
  (['subscript', 'stream', 'netflix', 'spotify'], FontAwesomeIcons.tv),
  // Transport.
  (['fuel', 'petrol', 'gas'], FontAwesomeIcons.gasPump),
  (['uber', 'taxi', 'cab'], FontAwesomeIcons.taxi),
  (['train', 'bus', 'transit', 'transport', 'commute'],
      FontAwesomeIcons.trainSubway),
  (['flight', 'travel', 'holiday', 'hotel', 'trip', 'vacation'],
      FontAwesomeIcons.plane),
  (['car', 'auto', 'vehicle', 'rego', 'parking', 'toll'],
      FontAwesomeIcons.car),
  // Health & personal.
  (['medical', 'health', 'doctor', 'hospital', 'dental'],
      FontAwesomeIcons.heartPulse),
  (['pharma', 'chemist', 'medicine'], FontAwesomeIcons.pills),
  (['gym', 'fitness', 'sport'], FontAwesomeIcons.dumbbell),
  (['beauty', 'hair', 'salon', 'barber'], FontAwesomeIcons.scissors),
  (['baby', 'kids', 'child'], FontAwesomeIcons.baby),
  // Shopping & leisure.
  (['cloth', 'fashion', 'apparel', 'shoes'], FontAwesomeIcons.shirt),
  (['shopping', 'retail', 'amazon'], FontAwesomeIcons.bagShopping),
  (['movie', 'cinema', 'entertain'], FontAwesomeIcons.film),
  (['game', 'gaming'], FontAwesomeIcons.gamepad),
  (['music', 'concert'], FontAwesomeIcons.music),
  (['book'], FontAwesomeIcons.book),
  (['gift', 'donation', 'charity'], FontAwesomeIcons.gift),
  // Money.
  (['transfer'], FontAwesomeIcons.moneyBillTransfer),
  (['income', 'salary', 'wage', 'pay'], FontAwesomeIcons.sackDollar),
  (['saving'], FontAwesomeIcons.piggyBank),
  (['invest', 'shares', 'stock', 'crypto'], FontAwesomeIcons.chartLine),
  (['insurance'], FontAwesomeIcons.shieldHalved),
  (['tax', 'taxes', 'council', 'rates', 'fine'],
      FontAwesomeIcons.buildingColumns),
  (['fee', 'fees', 'bank', 'interest', 'charge'], FontAwesomeIcons.creditCard),
  // Work & education.
  (['education', 'school', 'tuition', 'course', 'uni'],
      FontAwesomeIcons.graduationCap),
  (['work', 'office', 'business'], FontAwesomeIcons.briefcase),
];

/// True when [kw] matches the category, conservatively: long keywords may
/// match anywhere in the name, medium ones must start a word, and short ones
/// must be a whole word — so 'car' matches 'CAR-EXPENSES' but never 'CARD'.
bool _matches(Set<String> tokens, String full, String kw) {
  if (kw.length >= 6 && full.contains(kw)) return true;
  for (final t in tokens) {
    if (t == kw) return true;
    if (kw.length >= 4 && t.startsWith(kw)) return true;
  }
  return false;
}

/// The Font Awesome icon for a category, derived from its name.
FaIconData categoryIcon(String category) {
  final c = category.toLowerCase();
  final tokens = c
      .split(RegExp(r'[^a-z0-9]+'))
      .where((t) => t.isNotEmpty)
      .toSet();
  for (final (keywords, icon) in _iconRules) {
    if (keywords.any((kw) => _matches(tokens, c, kw))) return icon;
  }
  return FontAwesomeIcons.tag;
}
