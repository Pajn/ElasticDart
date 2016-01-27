/// Internal helpers for investigating classes
library elastic_dart.warehouse.mirrors;

import 'dart:mirrors';
import 'package:warehouse/adapters/base.dart';
import 'package:warehouse/warehouse.dart';

final lookingGlass = new LookingGlass();
final dateTime = reflectClass(DateTime);
final geoPoint = reflectClass(GeoPoint);

Map findMapping(Type type) {
  var mapping = {};
  lookingGlass.lookOnClass(type).propertyFields.forEach((field, declaration) {
    if (geoPoint.isAssignableTo(getType(declaration))) {
      mapping[MirrorSystem.getName(field)] = const {'type': 'geo_point'};
    } else if (geoPoint.isAssignableTo(getType(declaration))) {
      mapping[MirrorSystem.getName(field)] = const {'type': 'date'};
    }
  });
  return mapping;
}

bool isAny(Object object, Iterable<Type> types) =>
    types.any((type) => isSubtype(object, type));
