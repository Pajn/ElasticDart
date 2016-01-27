import 'package:quiver_pattern/regexp.dart' show escapeRegExp;
import 'package:warehouse/warehouse.dart';
import 'package:warehouse/adapters/base.dart';

value(value, LookingGlass lg) {
  var converter = lg.convertedTypes[value.runtimeType];
  if (converter != null) {
    return converter.toDatabase(value);
  }
  return value;
}

Map createQuery(LookingGlass lg, Map where, [List<Type> types]) {
  var filters = [];

  if (types != null) {
    where = where ?? {};
    where['@labels'] = IS.inList(types.map(findLabel));
  }

  if (where != null && where.isNotEmpty) {
    where.forEach((property, value) {
      if (value is! Matcher) {
        value = new EqualsMatcher()..expected = value;
      }

      filters.add(visitMatcher(property, value, lg));
    });
  }

  if (filters.isEmpty) {
    return {
      'query': {
        'match_all': {},
      }
    };
  }

  return {
    'query': {
      'bool': {
        'must': filters.where((filter) => filter != null).toList(),
      }
    }
  };
}

Map visitMatcher(String property, Matcher matcher, LookingGlass lg) {
  if (matcher is ExistMatcher) {
    return {
      'exists': {
        'field': property,
      }
    };
  } else if (matcher is NotMatcher) {
    return {
      'bool': {
        'must_not': visitMatcher(property, matcher.invertedMatcher, lg),
      }
    };
  } else if (matcher is ListContainsMatcher) {
    return {
      'match': {
        property: value(matcher.expected, lg),
      }
    };
  } else if (matcher is StringContainMatcher) {
    final pattern = escapeRegExp(matcher.expected);
    return {
      'regexp': {
        property: value('.*$pattern.*', lg),
      }
    };
  } else if (matcher is InListMatcher) {
    if (matcher.list.length == 1) {
      return {
        'match': {
          property: value(matcher.list.first, lg),
        }
      };
    } else if (matcher.list.length > 1) {
      return {
        'bool': {
          'should': matcher.list.map((expected) => {
            'match': {
              property: value(expected, lg)
            }
          }).toList()
        }
      };
    } else {
      return null;
    }
  } else if (matcher is EqualsMatcher) {
    return {
      'match': {
        property: value(matcher.expected, lg),
      }
    };
  } else if (matcher is LessThanMatcher) {
    return {
      'range': {
        property: {
          'lt': value(matcher.expected, lg),
        }
      }
    };
  } else if (matcher is LessThanOrEqualToMatcher) {
    return {
      'range': {
        property: {
          'lte': value(matcher.expected, lg),
        }
      }
    };
  } else if (matcher is GreaterThanMatcher) {
    return {
      'range': {
        property: {
          'gt': value(matcher.expected, lg),
        }
      }
    };
  } else if (matcher is GreaterThanOrEqualToMatcher) {
    return {
      'range': {
        property: {
          'gte': value(matcher.expected, lg),
        }
      }
    };
  } else if (matcher is InRangeMatcher) {
    return {
      'range': {
        property: {
          'gte': value(matcher.min, lg),
          'lte': value(matcher.max, lg),
        }
      }
    };
  } else if (matcher is RegexpMatcher) {
    return {
      'regexp': {
        property: value(matcher.regexp, lg),
      }
    };
  } else {
    throw 'Unsuported matcher ${matcher.runtimeType}';
  }
}
