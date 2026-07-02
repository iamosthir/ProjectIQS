import 'package:flutter/foundation.dart';

/// `GET /governorates` row. `code` is the stable identifier sent on writes;
/// `name` is the localized display label.
@immutable
class Governorate {
  const Governorate({required this.code, required this.name});

  final String code;
  final String name;

  factory Governorate.fromJson(Map<String, dynamic> j) => Governorate(
        code: j['code'].toString(),
        name: j['name'].toString(),
      );

  @override
  bool operator ==(Object other) =>
      other is Governorate && other.code == code;

  @override
  int get hashCode => code.hashCode;
}
