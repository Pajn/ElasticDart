import 'package:guinness/guinness.dart';

import 'package:elastic_dart/elastic_dart.dart';

main() {
  var es = new ElasticSearch();
  var firstIndex = 'my_movies';
  var secondIndex = 'my_other_movies';

  afterEach(() async {
    await es.bulk([
      {"delete": {"_index": secondIndex, "_type": "movies", "_id": "2"} },
    ]);
  });

  describe('elasticsearch', () {

    it('should be able to search the whole database with a query', () async {
      var query = {
        "query": {
          "match": {"name": "The hunger games"}
        }
      };

      var result = await es.search(query);
      expect(result['_shards']).toBeNotNull();

      // We have two movies with the same name
      expect(result['hits']['total']).toEqual(3);

      // Expect our indexes to exist
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

      // Expect our indexes to exist
      expect(result['hits']['hits'][0]['_index']).toEqual(firstIndex);
      expect(result['hits']['hits'][2]['_index']).toEqual(secondIndex);

      expect(result['hits']['hits'][0]['_source']['name']).toEqual('Star Wars: Episode I - The Phantom Menace');
      expect(result['hits']['hits'][4]['_source']['name']).toEqual('Annabelle');
    });

    it('should be able to bulk', () async {
      var result = await es.bulk([
        {"index": {"_index": secondIndex, "_type": "movies", "_id": "2"} },
        {"name": "Fury", "year": "2014" },
      ]);

      expect(result.keys).toContain('items');
    });

    it('should be able to search on a specific index with a query', () async {
      var query = {
        "query": {
          "match": {"name": "Annabelle"}
        }
      };
      var index = es.getIndex(firstIndex);
      var result = await index.search(query);

      expect(result['hits']['hits'][0]['_index']).toContain(firstIndex);
      expect(result['hits']['hits'][0]['_source']['name']).toEqual('Annabelle');
    });
  });
}