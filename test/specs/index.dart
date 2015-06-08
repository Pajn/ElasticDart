library elastic_dart.test.index;

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

  describe('Index', () {
    describe('get', () {
      it('should be able to get a single index with all features', () async {
        var result = await es.index(firstIndex).get();

        expect(result).toContain(firstIndex);
        expect(result[firstIndex]).toContain('settings');
        expect(result[firstIndex]).toContain('mappings');
        expect(result[firstIndex]).toContain('warmers');
        expect(result[firstIndex]).toContain('aliases');
      });

      it('should be able to get a single index with a single feature',
          () async {
        var result = await es.index(firstIndex).get(features: ['_settings']);

        expect(result[firstIndex]).toContain('settings');
        expect(result[firstIndex]['mappings']).toBeNull();
        expect(result[firstIndex]['warmers']).toBeNull();
        expect(result[firstIndex]['aliases']).toBeNull();
      });

      it('should be able to get a single index with multiple features',
          () async {
        var result =
            await es.index(firstIndex).get(features: ['_settings', '_warmers']);

        // Expect our features.
        expect(result[firstIndex]).toContain('settings');
        expect(result[firstIndex]).toContain('warmers');

        // Expect the rest of the features to not exist.
        expect(result[firstIndex]['mappings']).toBeNull();
        expect(result[firstIndex]['aliases']).toBeNull();
      });

      it('should be able to get all indices with all features', () async {
        var result = await es.all.get();

        // Expect both of our indices.
        expect(result).toContain(firstIndex);
        expect(result).toContain(secondIndex);

        // Expect all features in both indices.
        expect(result[firstIndex]).toContain('settings');
        expect(result[firstIndex]).toContain('mappings');
        expect(result[firstIndex]).toContain('warmers');
        expect(result[firstIndex]).toContain('aliases');
        expect(result[secondIndex]).toContain('settings');
        expect(result[secondIndex]).toContain('mappings');
        expect(result[secondIndex]).toContain('warmers');
        expect(result[secondIndex]).toContain('aliases');
      });

      it('should be able to get all indices with a single feature', () async {
        var result = await es.all.get(features: ['_aliases']);

        // Expect both of our indices.
        expect(result).toContain(firstIndex);
        expect(result).toContain(secondIndex);

        // Expect our feature in both indices.
        expect(result[firstIndex]).toContain('aliases');
        expect(result[secondIndex]).toContain('aliases');
      });

      it('should be able to get all indices with multiple features', () async {
        var result = await es.all.get(features: ['_aliases', '_mappings']);

        // Expect both of our indices.
        expect(result).toContain(firstIndex);
        expect(result).toContain(secondIndex);

        // Expect our features in both indices.
        expect(result[firstIndex]).toContain('aliases');
        expect(result[secondIndex]).toContain('aliases');
        expect(result[firstIndex]).toContain('mappings');
        expect(result[secondIndex]).toContain('mappings');

        // Expect the rest of the features to not exist.
        expect(result[firstIndex]['settings']).toBeNull();
        expect(result[firstIndex]['warmers']).toBeNull();
      });
    });

    describe('delete', () {
      it('should be able to delete a index', () async {
        await es.createIndex('to_be_deleted', throwIfExists: false);
        var result = await es.index('to_be_deleted').delete();
        expect(result).toEqual({'acknowledged': true});
      });

      it('should should throw if the index to delete is missing', () {
        es
            .index('missing_index')
            .delete()
            .then((_) => throw 'Should throw')
            .catchError(expectAsync((e) {
          expect(e).toBeA(IndexMissingException);
          expect(e.index).toEqual('missing_index');
        }));
      });
    });

    describe('close', () {
      it('should be able to close a index', () async {
        var result = await es.index(firstIndex).close();
        expect(result).toEqual({'acknowledged': true});
      });

      it('should should throw if the closed index is missing', () {
        es
            .index('missing_index')
            .close()
            .then((_) => throw 'Should throw')
            .catchError(expectAsync((e) {
          expect(e).toBeA(IndexMissingException);
          expect(e.index).toEqual('missing_index');
        }));
      });
    });

    describe('open', () {
      it('should be able to open a index', () async {
        var result = await es.index(firstIndex).open();
        expect(result).toEqual({'acknowledged': true});
      });

      it('should should throw if the opened index is missing', () {
        es
            .index('missing_index')
            .open()
            .then((_) => throw 'Should throw')
            .catchError(expectAsync((e) {
          expect(e).toBeA(IndexMissingException);
          expect(e.index).toEqual('missing_index');
        }));
      });
    });

    describe('search', () {
      it('should be able to search the whole database with a query', () async {
        var query = {"query": {"match": {"name": "The hunger games"}}};

        var result = await es.all.search(query: query);
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
        var result = await es.all.search();
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
        var result = await es.index(firstIndex).search(query: query);

        expect(result['hits']['hits'][0]['_index']).toContain(firstIndex);
        expect(result['hits']['hits'][0]['_source']['name'])
            .toEqual('Annabelle');
      });

      it('should should throw if the searched index is missing', () {
        var query = {"query": {"match": {"name": "Annabelle"}}};

        es
            .index('missing_index')
            .search(query: query)
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
        await es.index('test-index').delete();
      });

      it('should be able to get mapping on an index with a type', () async {
        var result =
            await es.index('test-index').getMapping(type: 'test-type2');
        expect(result).toEqual({
          'test-index': {
            "mappings": {
              "test-type2": {
                "properties": {"message": {"type": "string", "store": true}}
              }
            }
          }
        });

        result = await es.index('test-index').getMapping(type: 'test-type');
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
        var result = await es.index('test-index').getMapping();
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
            .index('missing_index')
            .getMapping()
            .then((_) => throw 'Should throw')
            .catchError(expectAsync((e) {
          expect(e).toBeA(IndexMissingException);
          expect(e.index).toEqual('missing_index');
        }));
      });
    });

    describe('putMapping', () {
      it('should be able to put mapping', () async {
        var result = await es.index(firstIndex).putMapping({
          "test-type": {
            "properties": {"name": {"type": "string", "store": "yes"}}
          }
        }, type: 'test-type');
        expect(result).toEqual({'acknowledged': true});
      });

      it('should should throw if the index to map is missing', () {
        es
            .index('missing_index')
            .putMapping({
          "test-type": {
            "properties": {"name": {"type": "string", "store": "yes"}}
          }
        }, type: 'test-type')
            .then((_) => throw 'Should throw')
            .catchError(expectAsync((e) {
          expect(e).toBeA(IndexMissingException);
          expect(e.index).toEqual('missing_index');
        }));
      });
    });
  });
}
