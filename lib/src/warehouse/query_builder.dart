import 'package:warehouse/warehouse.dart';

Map createQuery(Map where, [String type]) {
  var filters = [];

  if (where != null && where.isNotEmpty) {
    where.forEach((property, value) {
      if (value is! Matcher) {
        value = new EqualsMatcher()..expected = value;
      }

      filters.add(visitMatcher(property, value));
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
      'match_all': {},
    };
  }

  return {
    'bool': {
      'must': filters,
    }
  };
}

Map visitMatcher(String property, Matcher matcher) {
  if (matcher is ExistMatcher) {
    return {
      'exists': {
        'field': property,
      }
    };
  } else if (matcher is NotMatcher) {
    return {
      'bool': {
        'must_not': visitMatcher(property, matcher.invertedMatcher),
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
        property: matcher.expected,
      }
    };
  } else if (matcher is LessThanMatcher) {
    return {
      'range': {
        property: {
          'lt': matcher.expected,
        }
      }
    };
  } else if (matcher is LessThanOrEqualToMatcher) {
    return {
      'range': {
        property: {
          'lte': matcher.expected,
        }
      }
    };
  } else if (matcher is GreaterThanMatcher) {
    return {
      'range': {
        property: {
          'gt': matcher.expected,
        }
      }
    };
  } else if (matcher is GreaterThanOrEqualToMatcher) {
    return {
      'range': {
        property: {
          'gte': matcher.expected,
        }
      }
    };
  } else if (matcher is InRangeMatcher) {
    return {
      'range': {
        property: {
          'gte': matcher.max,
          'lte': matcher.min,
        }
      }
    };
  } else if (matcher is RegexpMatcher) {
    return {
      'regexp': {
        property: matcher.regexp,
      }
    };
  } else {
    throw 'Unsuported matcher ${matcher.runtimeType}';
  }
}
