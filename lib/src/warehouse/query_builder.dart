import 'package:warehouse/warehouse.dart';
import 'package:warehouse/adapters/base.dart';

value(value, LookingGlass lg) {
  var converter = lg.convertedTypes[value.runtimeType];
  if (converter != null) {
    return converter.toDatabase(value);
  }
  return value;
}

Map createQuery(LookingGlass lg, Map where, [String type]) {
  var filters = [];

  if (where != null && where.isNotEmpty) {
    where.forEach((property, value) {
      if (value is! Matcher) {
        value = new EqualsMatcher()..expected = value;
      }

      filters.add(visitMatcher(property, value, lg));
    });
  }

  if (type != null) {
    filters.add({
      'type': {
        'value': type,
      }
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
        'must': filters,
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
    //  } else if (matcher is ListContainsMatcher) {
    //    var parameter = setParameter(parameters, matcher.expected, lg);
    //    return '$parameter IN {field}';
    //  } else if (matcher is StringContainMatcher) {
    //    var pattern = escapeRegex(matcher.expected);
    //    var parameter = setParameter(parameters, '(?i).*$pattern.*', lg);
    //    return '{field} =~ $parameter';
    //  } else if (matcher is InListMatcher) {
    //    var parameter = setParameter(parameters, matcher.list, lg);
    //    return '{field} IN $parameter';
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
          'gte': value(matcher.max, lg),
          'lte': value(matcher.min, lg),
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
