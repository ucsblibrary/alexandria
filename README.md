[![Build Status](https://travis-ci.org/ucsblibrary/alexandria.svg?branch=master)](https://travis-ci.org/ucsblibrary/alexandria)

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

# Important environment variables

| Name | Description | Required |
| ---- | ----------- | -------- |
| `ADRL_BINARY_ROOT` | Directory root for local ingest files (defaults to `/opt/ingest` | No |
| `ADRL_DERIVATIVES` | Directory for ADRL to store IIIF derivatives (defaults to `#{Rails.root}/tmp/derivatives`) | No |
| `ADRL_EMAIL` | Email address used as sender for form emails | No |
| `ADRL_MINTER_STATE` | Path to minter statefile (defaults to `#{Rails.root}/tmp/minter-state` | No |
| `ADRL_RIIIF_CACHE` | Directory where RIIIF stores temporary files during derivative creation (defaults to `#{Rails.root}/tmp/network_files`) | No |
| `ADRL_UPLOADS` | Directory where ADRL stores temporary files during upload to Fedora (defaults to `#{Rails.root}/tmp/uploads`) | No |
| `BRANCH_NAME` | Branch name or revision for Capistrano to deploy (defaults to `master`) | No |
| `DEV_FEDORA_BASE` | Path where development Fedora instance is mounted (defaults to `/devel`) | No |
| `DEV_FEDORA_URL` | Base URL for Fedora service in development mode (defaults to `http://localhost:8984/rest`) | No |
| `DEV_SOLR_URL` | Base URL for Fedora service in development mode (defaults to `http://localhost:8983/solr/development`) | No |
| `EXPLAIN_PARTIALS` | Debugging variable; when true, prints view information in rendered source | No |
| `FFMPEG_PATH` | Path to ffmpeg binary (defaults to `ffmpeg`) | No |
| `RAILS_QUEUE` | How Rails should queue background jobs (e.g., `inline`, `async`, `resque`; defaults to Resque) | No |
| `RAILS_SERVE_STATIC_FILES` | Whether the Rails server should handle requests to `public` (should be true when not behind a reverse proxy) | No |
| `SECRET_KEY_BASE` | Secret key base for the application | Yes |
| `SERVER` | Server targeted by Capistrano deployment | Yes, during deploy |
| `TEST_FEDORA_URL` | Base URL for Fedora service in test mode (defaults to `http://localhost:8986/rest`) | No |
| `TEST_SOLR_URL` | Base URL for Fedora service in test mode (defaults to `http://localhost:8985/solr/test`) | No |

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
