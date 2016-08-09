# Developing

After running `bundle install`, you can run tests with `make spec`.

HTML documentation can be generated locally by installing `yardoc`
with `gem install yardoc` then running `make html`.

# Provisioning

See the readme in the
[sufia-centos](https://github.library.ucsb.edu/ADRL/sufia-centos/blob/master/README.md)
repository.

# Ingesting records

See {file:Ingesting.md} and DCE’s wiki:
<https://github.com/curationexperts/alexandria-v2/wiki>

# Caveats

* Reindexing all objects (to an empty solr) requires two passes
  (`2.times { ActiveFedora::Base.reindex_everything }`). This
  situtation is not common. The first pass will guarantee that the
  collections are indexed, and the second pass will index the
  collection name on all the objects. The object indexer looks up the
  collection name from solr for speed.
