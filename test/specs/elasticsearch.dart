library elastic_dart.test.elasticsearch;

import 'package:guinness/guinness.dart';
import 'package:unittest/unittest.dart' show expectAsync;

import 'package:elastic_dart/elastic_dart.dart';

main(Elasticsearch es) {
  var firstIndex = 'my_movies';
  var secondIndex = 'my_other_movies';

  afterEach(() async {
    await es.bulk(
        [{"delete": {"_index": secondIndex, "_type": "movies", "_id": "2"}}]);
  });

  describe('Elasticsearch', () {
    it('should be able to bulk', () async {
      var result = await es.bulk([
        {"index": {"_index": secondIndex, "_type": "movies", "_id": "2"}},
        {"name": "Fury", "year": "2014"},
      ]);

      expect(result.keys).toContain('items');
    });

    describe('createIndex', () {
      afterEach(() async {
        try {
          await es.index('new-index').delete();
        } catch (_) {}
      });

      it('should be able to create a new index', () async {
        var result = await es.createIndex('new-index');
        expect(result).toEqual({'acknowledged': true});
      });

      it('should be able to create a new index with features', () async {
        var result = await es.createIndex('new-index',
            features: {
          "settings": {"number_of_shards": 3, "number_of_replicas": 2}
        });
        expect(result).toEqual({'acknowledged': true});
      });

      it('should throw if the index exists', () {
        es
            .createIndex(firstIndex)
            .then((_) => throw 'Should throw')
            .catchError(expectAsync((e) {
          expect(e).toBeA(IndexAlreadyExistsException);
          expect(e.index).toEqual(firstIndex);
        }));
      });

      it('should not throw if the index exists and its told so', () async {
        var result = await es.createIndex(firstIndex, throwIfExists: false);
        expect(result).toBeA(Index);
      });
    });
  });
}
