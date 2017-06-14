# Developing

1. Copy `config/secrets.yml.template` to `config/secrets.yml` and add
   the LDAP and Ezid passwords from
   [Secret Server](https://epm.ets.ucsb.edu/SS/login.aspx).

1. Start PostgreSQL and create new database and a user with login
   privileges, then add their names to `secrets.yml`.

1. Add the credentials for Active Directory and campus LDAP (from
   Secret Server) to `secrets.yml`.

1. Add the Ezid test password (if you don’t have it, email them for
   it) to `secrets.yml`.

1. Add the SRU base URL (currently Pegasus, soon Alma) to `secrets.yml`.

1. Ensure Java is installed (`brew cask install java`), and start Solr
   and Fedora with `bin/wrap` (stop them with `bin/unwrap`).

1. Run `bundle install` and `CI=1 bin/rake db:migrate`. (The `CI`
   environment variable disables Marmotta, which we don’t need to run
   locally.)

1. Start redis, then a Resque worker with `CI=1 VERBOSE=1 QUEUE='*' INTERVAL=5 bin/rake resque:work`.

1. Start the Rails server with `CI=1 bin/rails s`.

You can run tests with `make spec`, and HTML documentation by
installing `yardoc` with `gem install yardoc` then running `make
html`.

# Ingesting records

See {file:ingesting.md} and DCE’s wiki:
<https://github.com/curationexperts/alexandria-v2/wiki>

# Caveats

* Reindexing all objects (to an empty solr) requires two passes
  (`2.times { ActiveFedora::Base.reindex_everything }`). This
  situtation is not common. The first pass will guarantee that the
  collections are indexed, and the second pass will index the
  collection name on all the objects. The object indexer looks up the
  collection name from solr for speed.

# License

See {file:LICENSE.md}

Some parts of `lib/*vocabularies` and `spec/vocabularies` are licensed
as follows:

```
Copyright 2013 Oregon Digital ( Oregon State University & University of
Oregon )
Copyright 2015 Data Curation Experts

Additional copyright may be held by others, as reflected in the commit log

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
