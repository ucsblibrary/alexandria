# Using Solr and Fedora in development mode

We are using the gems `solr_wrapper` and `fcrepo_wrapper` to run solr and fedora in development mode and for running specs.

## Initial setup of development workspace

1. You&apos;ll need to create config files for `solr_wrapper` and `fcrepo_wrapper`.  (See below for example config files)

2. Add your new wrapper files to .git/info/exclude so they won&apos;t get checked into git.

3. Make sure your Rails config files match the settings in your `solr_wrapper` and `fcrepo_wrapper` config files:

    * config/solr.yml
    * config/fedora.yml
    * config/blacklight.yml

4. The first time you run `solr_wrapper` or `fcrepo_wrapper`, it
   should download and install the proper files for you.  However,
   `solr_wrapper` makes assumptions about the location of the download
   files which will be incorrect if you are using an older version of
   solr.  You may have to download the files yourself and manually
   place them into your `download_dir` before you run `solr_wrapper`.
   Find the correct `*.zip` and matching `*.md5` for your version.
   You should be able to download the files from the [Apache Archive](http://archive.apache.org/dist/lucene/solr)

## Example config files
The app uses 2 separate configs for development and test environments. 
See `config/solr_wrapper_development.yml` & `config/solr_wrapper_test.yml` for solr config.     
See `config/fedora_wrapper_development.yml` & `config/fedora_wrapper_test.yml` for fedora config.

## Running solr and fedora

To run solr in development mode:

```bash
$ bundle exec solr_wrapper --config config/solr_wrapper_development.yml
```

To run fedora in development mode:
```bash
$ bundle exec fcrepo_wrapper --config config/fcrepo_wrapper_development.yml
```

## Running the specs

* Make sure postgres server is running
* Make sure marmotta is running, or CI environment variable is set to bypass marmotta

```bash
$ bundle exec solr_wrapper --config config/solr_wrapper_test.yml
$ bundle exec fcrepo_wrapper --config config/fcrepo_wrapper_test.yml
$ bundle exec rake spec
```
