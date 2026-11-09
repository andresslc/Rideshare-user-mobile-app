class MapStyles {
  // OLD MAP CODE:
  static const String dark = '''
[
  {"elementType":"geometry","stylers":[{"color":"#1b222c"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#746855"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#242f3e"}]},
  {"featureType":"administrative.locality","elementType":"labels.text.fill","stylers":[{"color":"#ffffff"}]},
  {"featureType":"poi","elementType":"labels.text.fill","stylers":[{"color":"#d59563"}]},
  {"featureType":"poi.business","elementType":"labels.text.fill","stylers":[{"color":"#ffffff"}]},
  {"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#263c3f"}]},
  {"featureType":"poi.park","elementType":"labels.text.fill","stylers":[{"color":"#6b9a76"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#38414e"}]},
  {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#212a37"}]},
  {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#9ca5b3"}]},
  {"featureType":"road.highway","elementType":"geometry.stroke","stylers":[{"color":"#1f2835"}]},
  {"featureType":"road.highway","elementType":"labels.text.fill","stylers":[{"color":"#f3d19c"}]},
  {"featureType":"transit","elementType":"geometry","stylers":[{"color":"#2f3948"},{"weight":1}]},
  {"featureType":"transit.station","elementType":"labels.text.fill","stylers":[{"color":"#d59563"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#283348"}]},
  {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#515c6d"}]},
  {"featureType":"water","elementType":"labels.text.stroke","stylers":[{"color":"#17263c"}]}
]

/// Old map code:
// [
//   {"elementType":"geometry","stylers":[{"color":"#000000"}]},
//   {"elementType":"labels.text.fill","stylers":[{"color":"#bdbdbd"}]},
//   {"elementType":"labels.text.stroke","stylers":[{"color":"#000000"}]},
//   {"featureType":"road","elementType":"geometry","stylers":[{"color":"#1a1a1a"}]},
//   {"featureType":"water","elementType":"geometry","stylers":[{"color":"#0a0a0a"}]}
// ]
''';
  static const String light = '''
[
  {"featureType":"administrative.country","elementType":"geometry.fill","stylers":[{"visibility":"off"}]},
  {"featureType":"administrative.province","elementType":"geometry.fill","stylers":[{"visibility":"off"}]},
  {"featureType":"landscape.natural.landcover","elementType":"geometry.fill","stylers":[{"visibility":"simplified"}]},
  {"featureType":"water","elementType":"geometry.fill","stylers":[{"color":"#9fd3f4"}]},
  {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#000000"}]}
]

/// Old map code:
// [
//   {"elementType":"geometry","stylers":[{"color":"#ffffff"}]},
//   {"elementType":"labels.text.fill","stylers":[{"color":"#424242"}]},
//   {"elementType":"labels.text.stroke","stylers":[{"color":"#ffffff"}]},
//   {"featureType":"road","elementType":"geometry","stylers":[{"color":"#f5f5f5"}]},
//   {"featureType":"water","elementType":"geometry","stylers":[{"color":"#eaeaea"}]}
// ]
''';
}





//// OLD MAP CODE:
//   static const String dark = '''
// [
//   {"elementType":"geometry","stylers":[{"color":"#000000"}]},
//   {"elementType":"labels.text.fill","stylers":[{"color":"#bdbdbd"}]},
//   {"elementType":"labels.text.stroke","stylers":[{"color":"#000000"}]},
//   {"featureType":"road","elementType":"geometry","stylers":[{"color":"#1a1a1a"}]},
//   {"featureType":"water","elementType":"geometry","stylers":[{"color":"#0a0a0a"}]}
// ]
// ''';
//  static const String light = '''
// [
//   {"elementType":"geometry","stylers":[{"color":"#ffffff"}]},
//   {"elementType":"labels.text.fill","stylers":[{"color":"#424242"}]},
//   {"elementType":"labels.text.stroke","stylers":[{"color":"#ffffff"}]},
//   {"featureType":"road","elementType":"geometry","stylers":[{"color":"#f5f5f5"}]},
//   {"featureType":"water","elementType":"geometry","stylers":[{"color":"#eaeaea"}]}
// ]
// ''';