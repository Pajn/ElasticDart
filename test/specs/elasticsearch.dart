library elastic_dart.test.elasticsearch;

import 'package:guinness/guinness.dart';
import 'package:unittest/unittest.dart' show expectAsync;

import 'package:elastic_dart/elastic_dart.dart';

main() {
  var es = new Elasticsearch();
  var firstIndex = 'my_movies';
  var secondIndex = 'my_other_movies';

  afterEach(() async {
    await es.bulk(
        [{"delete": {"_index": secondIndex, "_type": "movies", "_id": "2"}}]);
  });

  describe('Elasticsearch', () {
    describe('getIndex', () {
      it('should be able to get a single index with all features', () async {
        var result = await es.getIndex(firstIndex);

        expect(result).toContain(firstIndex);
        expect(result[firstIndex]).toContain('settings');
        expect(result[firstIndex]).toContain('mappings');
        expect(result[firstIndex]).toContain('warmers');
        expect(result[firstIndex]).toContain('aliases');
      });

      it('should be able to get a single index with a single feature',
          () async {
        var result = await es.getIndex(firstIndex, features: '_settings');

        expect(result[firstIndex]).toContain('settings');
        expect(result[firstIndex]['mappings']).toBeNull();
        expect(result[firstIndex]['warmers']).toBeNull();
        expect(result[firstIndex]['aliases']).toBeNull();
      });

      it('should be able to get all indices', () async {
        var result = await es.getIndex('_all');

        expect(result).toContain(firstIndex);
        expect(result).toContain(secondIndex);
      });
    });

    describe('search', () {
      it('should be able to search the whole database with a query', () async {
        var query = {"query": {"match": {"name": "The hunger games"}}};

        var result = await es.search(query: query);
        expect(result['_shards']).toBeNotNull();

        // We have two movies with the same name
        expect(result['hits']['total']).toEqual(3);

        // Expect our indices to exist
        expect(result['hits']['hits'][0]['_index']).toEqual(firstIndex);
        expect(result['hits']['hits'][1]['_index']).toEqual(secondIndex);

        expect(result['hits']['hits'][0]['_source']['name'])
            .toEqual('The hunger games');
        expect(result['hits']['hits'][1]['_source']['name'])
            .toEqual('The hunger games');
        // Star Wars also matches at "THE"...
        expect(result['hits']['hits'][2]['_source']['name'])
            .toEqual('Star Wars: Episode I - The Phantom Menace');
      });

      it('should be able to search the whole database without a query',
          () async {
        var result = await es.search();
        expect(result['_shards']).toBeNotNull();

        // Expect our indices to exist
        expect(result['hits']['hits'][0]['_index']).toEqual(firstIndex);
        expect(result['hits']['hits'][2]['_index']).toEqual(secondIndex);

        expect(result['hits']['hits'][0]['_source']['name'])
            .toEqual('Star Wars: Episode I - The Phantom Menace');
        expect(result['hits']['hits'][4]['_source']['name'])
            .toEqual('Annabelle');
      });

      it('should be able to search on a specific index with a query', () async {
        var query = {"query": {"match": {"name": "Annabelle"}}};
        var result = await es.search(index: firstIndex, query: query);

        expect(result['hits']['hits'][0]['_index']).toContain(firstIndex);
        expect(result['hits']['hits'][0]['_source']['name'])
            .toEqual('Annabelle');
      });

      it('should should throw if the searched index is missing', () {
        var query = {"query": {"match": {"name": "Annabelle"}}};

        es
            .search(index: 'missing_index', query: query)
            .then((_) => throw 'Should throw')
            .catchError(expectAsync((e) {

          expect(e).toBeA(IndexMissingException);
          expect(e.index).toEqual('missing_index');
        }));
      });
    });

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
          await es.deleteIndex('new-index');
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

        expect(result).toEqual({
          'error': 'IndexAlreadyExistsException[[$firstIndex] already exists]',
          'status': 400
        });
      });
    });

    describe('deleteIndex', () {
      afterEach(() async {
        es.createIndex(firstIndex, throwIfExists: false);
      });

      it('should be able to delete a index', () async {
        var result = await es.deleteIndex(firstIndex);
        expect(result).toEqual({'acknowledged': true});
      });

      it('should should throw if the index to delete is missing', () {
        es
            .deleteIndex('missing_index')
            .then((_) => throw 'Should throw')
            .catchError(expectAsync((e) {

          expect(e).toBeA(IndexMissingException);
          expect(e.index).toEqual('missing_index');
        }));
      });
    });

    describe('putMapping', () {
      it('should be able to put mapping', () async {
        var result = await es.putMapping({
          "test-type": {
            "properties": {"name": {"type": "string", "store": "yes"}}
          }
        }, index: firstIndex, type: 'test-type');
        expect(result).toEqual({'acknowledged': true});
      });

      it('should should throw if the index to map is missing', () {
        es
            .putMapping({
          "test-type": {
            "properties": {"name": {"type": "string", "store": "yes"}}
          }
        }, index: 'missing_index', type: 'test-type')
            .then((_) => throw 'Should throw')
            .catchError(expectAsync((e) {
          expect(e).toBeA(IndexMissingException);
          expect(e.index).toEqual('missing_index');
        }));
      });
    });

    describe('getMapping', () {
      beforeEach(() async {
        await es.createIndex('test-index',
            features: {
          "mappings": {
            "test-type": {
              "properties": {"message": {"type": "string", "store": "yes"}}
            },
            "test-type2": {
              "properties": {"message": {"type": "string", "store": "yes"}}
            },
          }
        });
      });

      afterEach(() async {
        await es.deleteIndex('test-index');
      });

      it('should be able to get mapping on an index with a type', () async {
        var result =
            await es.getMapping(index: 'test-index', type: 'test-type2');
        expect(result).toEqual({
          'test-index': {
            "mappings": {
              "test-type2": {
                "properties": {"message": {"type": "string", "store": true}}
              }
            }
          }
        });

        result = await es.getMapping(index: 'test-index', type: 'test-type');
        expect(result).toEqual({
          'test-index': {
            "mappings": {
              "test-type": {
                "properties": {"message": {"type": "string", "store": true}}
              }
            }
          }
        });
      });

      it('should be able to get mapping on an index', () async {
        var result = await es.getMapping(index: 'test-index');
        expect(result).toEqual({
          'test-index': {
            "mappings": {
              "test-type": {
                "properties": {"message": {"type": "string", "store": true}}
              },
              "test-type2": {
                "properties": {"message": {"type": "string", "store": true}}
              },
            }
          }
        });
      });

      it('should should throw if the index to map is missing', () {
        es
            .getMapping(index: 'missing_index')
            .then((_) => throw 'Should throw')
            .catchError(expectAsync((e) {

          expect(e).toBeA(IndexMissingException);
          expect(e.index).toEqual('missing_index');
        }));
      });
    });
  });
}
