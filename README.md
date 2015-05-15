# ElasticDart
[![Build Status](https://travis-ci.org/Pajn/ElasticDart.svg?branch=master)](https://travis-ci.org/Pajn/ElasticDart)
[![Coverage Status](https://coveralls.io/repos/Pajn/ElasticDart/badge.svg)](https://coveralls.io/r/Pajn/ElasticDart)

An ElasticSearch connector for Dart. Currently it features a thin wrapper around the REST api.

## Usage
A simple usage example:
```dart
import 'dart:async';
import 'package:elastic_dart/elastic_dart.dart';

main() async {
  var es = new ElasticSearch();

  await es.createIndex('my_movies', throwIfExists: false);

  await es.bulk([
    {"index": {"_index": "my_movies", "_type": "movies", "_id": "1"} },
    {"name": "The hunger games", "year": "2012" },
    {"index": {"_index": "my_movies", "_type": "movies", "_id": "2"} },
    {"name": "Titanic", "year": "1997" },
    {"index": {"_index": "my_movies", "_type": "movies", "_id": "3"} },
    {"name": "Annabelle", "year": "2014" },
    {"index": {"_index": "my_movies", "_type": "movies", "_id": "4"} },
    {"name": "Star Wars: Episode I - The Phantom Menace", "year": "1999" }
  ]);

  // Wait for Elasticsearch to index the new documents
  await new Future.delayed(new Duration(seconds: 2));

  var result = await es.search(index: 'my_movies', query: {
    "query": {
      "match": {"name": "The hunger games"}
    }
  });

  print(result);
}
```

## Features and bugs
Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/Pajn/ElasticDart/issues
