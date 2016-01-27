# ElasticDart
[![Build Status](https://travis-ci.org/beanloop/ElasticDart.svg?branch=master)](https://travis-ci.org/beanloop/ElasticDart)
[![Coverage Status](https://coveralls.io/repos/beanloop/ElasticDart/badge.svg)](https://coveralls.io/r/beanloop/ElasticDart)

An Elasticsearch connector for Dart.
Includes both a thin wrapper around the REST API for indexing and querying and
a [Warehouse][] companion adapter for easily adding search and ranking to repositories.

The REST API wrapper can be used in the browser by importing `package:elastic_dart/browser_client.dart`.

## Usage
A simple usage example:
```dart
import 'dart:async';
import 'package:elastic_dart/elastic_dart.dart';

main() async {
  var es = new Elasticsearch();

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

For usage on the Warehouse adapter see the [example folder][].

## Features and bugs
Please file feature requests and bugs at the [issue tracker][tracker].

[Warehouse]: https://pub.dartlang.org/packages/warehouse
[example folder]: https://github.com/Pajn/ElasticDart/tree/master/example
[tracker]: https://github.com/Pajn/ElasticDart/issues
