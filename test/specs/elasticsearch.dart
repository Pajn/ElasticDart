library elastic_dart.test.elasticsearch;

import 'package:guinness/guinness.dart';
import 'package:unittest/unittest.dart' show expectAsync;

import 'package:elastic_dart/elastic_dart.dart';

main() {
  var es = new Elasticsearch();
  var firstIndex = 'my_movies';
  var secondIndex = 'my_other_movies';

  afterEach(() async {
    await es.bulk([
      {"delete": {"_index": secondIndex, "_type": "movies", "_id": "2"} },
    ]);
  });

  describe('Elasticsearch', () {

    describe('getIndex', () {
      it('should be able to get a single index with all features', () async {
        await es.createIndex('test-index');

        var result = await es.getIndex('test-index');

        expect(result).toContain('test-index');
        expect(result['test-index']).toContain('settings');
        expect(result['test-index']).toContain('mappings');
        expect(result['test-index']).toContain('warmers');
        expect(result['test-index']).toContain('aliases');

        await es.deleteIndex('test-index');
      });

      it('should be able to get a single index with a single feature', () async {
        await es.createIndex('test-index');

        var result = await es.getIndex('test-index', features: '_settings');

        expect(result['test-index']).toContain('settings');
        expect(result['test-index']['mappings']).toBeNull();
        expect(result['test-index']['warmers']).toBeNull();
        expect(result['test-index']['aliases']).toBeNull();

        await es.deleteIndex('test-index');
      });

      it('should be able to get all indices', () async {
        await es.createIndex('first-index');
        await es.createIndex('second-index');

        var result = await es.getIndex('_all');

        expect(result).toContain('first-index');
        expect(result).toContain('second-index');

        await es.deleteIndex('first-index');
        await es.deleteIndex('second-index');
      });
    });

    describe('search', () {
      it('should be able to search the whole database with a query', () async {
        var query = {
          "query": {
            "match": {"name": "The hunger games"}
          }
        };

        var result = await es.search(query: query);
        expect(result['_shards']).toBeNotNull();

        // We have two movies with the same name
        expect(result['hits']['total']).toEqual(3);

        // Expect our indices to exist
        expect(result['hits']['hits'][0]['_index']).toEqual(firstIndex);
        expect(result['hits']['hits'][1]['_index']).toEqual(secondIndex);

        expect(result['hits']['hits'][0]['_source']['name']).toEqual('The hunger games');
        expect(result['hits']['hits'][1]['_source']['name']).toEqual('The hunger games');
        // Star Wars also matches at "THE"...
        expect(result['hits']['hits'][2]['_source']['name']).toEqual('Star Wars: Episode I - The Phantom Menace');
      });

      it('should be able to search the whole database without a query', () async {
        var result = await es.search();
        expect(result['_shards']).toBeNotNull();

        // Expect our indices to exist
        expect(result['hits']['hits'][0]['_index']).toEqual(firstIndex);
        expect(result['hits']['hits'][2]['_index']).toEqual(secondIndex);

        expect(result['hits']['hits'][0]['_source']['name']).toEqual('Star Wars: Episode I - The Phantom Menace');
        expect(result['hits']['hits'][4]['_source']['name']).toEqual('Annabelle');
      });

      it('should be able to search on a specific index with a query', () async {
        var query = {
          "query": {
            "match": {"name": "Annabelle"}
          }
        };
        var result = await es.search(index: firstIndex, query: query);

        expect(result['hits']['hits'][0]['_index']).toContain(firstIndex);
        expect(result['hits']['hits'][0]['_source']['name']).toEqual('Annabelle');
      });

      it('should should throw if the searched index is missing', () {
        var query = {
          "query": {
            "match": {"name": "Annabelle"}
          }
        };

        es.search(index: 'missing_index', query: query)
        .then((_) => throw 'Should throw')
        .catchError(expectAsync((e) {
          expect(e).toBeA(IndexMissingException);
          expect(e.index).toEqual('missing_index');
        }));
      });
    });

    it('should be able to bulk', () async {
      var result = await es.bulk([
        {"index": {"_index": secondIndex, "_type": "movies", "_id": "2"} },
        {"name": "Fury", "year": "2014" },
      ]);

      expect(result.keys).toContain('items');
    });

    describe('createIndex', () {
      it('should be able to create a new index', () async {
        var result = await es.createIndex('testindex');
        expect(result).toEqual({'acknowledged': true});
      });

      it('should throw if the index exists', () {
        es.createIndex(firstIndex)
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
      it('should be able to delete a index', () async {
        var result = await es.deleteIndex('testindex');
        expect(result).toEqual({'acknowledged': true});
      });

      it('should should throw if the index to delete is missing', () {
        es.deleteIndex('missing_index')
          .then((_) => throw 'Should throw')
          .catchError(expectAsync((e) {
            expect(e).toBeA(IndexMissingException);
            expect(e.index).toEqual('missing_index');
          }));
      });
    });

    describe('putMapping', () {
      it('should be able to put mapping', () async {
        await es.createIndex('test-index');
        var result = await es.putMapping(
            {"test-type": {"properties": {"name": {"type": "string", "store": "yes"}}}},
            index: 'test-index', type: 'test-type'
        );
        expect(result).toEqual({'acknowledged': true});
        await es.deleteIndex('test-index');
      });

      it('should should throw if the index to map is missing', () {
        es.putMapping(
            {"test-type": {"properties": {"name": {"type": "string", "store": "yes"}}}},
            index: 'missing_index', type: 'test-type'
        )
          .then((_) => throw 'Should throw')
          .catchError(expectAsync((e) {
            expect(e).toBeA(IndexMissingException);
            expect(e.index).toEqual('missing_index');
          }));
      });
    });

    describe('getMapping', () {
      it('should be able to get mapping on an index with a type', () async {
        await es.createIndex('test-index');
        await es.putMapping(
            {"test-type": {"properties": {"message": {"type": "string", "store": "yes"}}}},
            index: 'test-index', type: 'test-type'
        );

        await es.putMapping(
            {"test-type2": {"properties": {"message": {"type": "string", "store": "yes"}}}},
            index: 'test-index', type: 'test-type2'
        );

        var result = await es.getMapping(index: 'test-index', type: 'test-type2');
        expect(result).toEqual({"test-index": {"mappings": {"test-type2": {"properties": {"message": {"type": "string", "store": true}}}}}});

        result = await es.getMapping(index: 'test-index', type: 'test-type');
        expect(result).toEqual({"test-index": {"mappings": {"test-type": {"properties": {"message": {"type": "string", "store": true}}}}}});

        await es.deleteIndex('test-index');
      });

      it('should be able to get mapping on an index', () async {
        await es.createIndex('test-index');
        await es.putMapping(
            {"test-type": {"properties": {"message": {"type": "string", "store": "true"}}}},
            index: 'test-index', type: 'test-type'
        );

        var result = await es.getMapping(index: 'test-index');
        expect(result).toEqual({"test-index": {"mappings": {"test-type": {"properties": {"message": {"type": "string", "store": true}}}}}});

        await es.deleteIndex('test-index');
      });

      it('should should throw if the index to map is missing', () {
        es.getMapping(index: 'missing_index')
          .then((_) => throw 'Should throw')
          .catchError(expectAsync((e) {
            expect(e).toBeA(IndexMissingException);
            expect(e.index).toEqual('missing_index');
          }));
      });
    });
  });
}
