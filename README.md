[![Build Status](http://jenkins.library.ucsb.edu:8080/buildStatus/icon?job=ADRL_pull-requests)](http://jenkins.library.ucsb.edu:8080/job/ADRL_pull-requests/)

# Developing

If you’re developing in a Vagrant VM, see the
[provisioning](#provisioning) section below.  Otherwise:

1. Copy `config/secrets.yml.template` to `config/secrets.yml` and add
   the LDAP and Ezid passwords from
   [Secret Server](https://epm.ets.ucsb.edu/SS/login.aspx).

2. Start PostgreSQL and create a database called `my_hydra_db` and a
   role called `my_hydra_pg_user` that has login privileges.

3. Ensure Java is installed (`brew cask install java`), and start Solr
   and Fedora with `bin/wrap` (stop them with `bin/unwrap`).

4. Run `bundle install` and `CI=1 bin/rake db:migrate`. (The `CI`
   environment variable disables Marmotta, which we don’t need to run
   locally.)

5. Start redis, then a Resque worker with `CI=1 VERBOSE=1 QUEUE='*' INTERVAL=5 bin/rake resque:work`.

6. Start the Rails server with `CI=1 bin/rails s`.

You can run tests with `make spec`, and HTML documentation by
installing `yardoc` with `gem install yardoc` then running `make
html`.

# Run the CI build

`CI=1 bundle exec rake ci`
 * Note: CI=1 keeps it from looking for a local Marmotta instance. 

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
