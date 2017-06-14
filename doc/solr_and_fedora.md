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

Here are some files that I have used.  Note that I am running my dev and test environments on the same port.  You might want to use different ports if you intend to run specs at the same time that your dev environment is running.

Example file `.solr_wrapper_dev`:

```ruby
version: 5.5.0
port: 8983
download_dir: tmp/solr_download
instance_dir: tmp/solr
collection:
    persist: true
    dir: solr/config/
    name: development
```

Example file `.solr_wrapper_test`:

```ruby
version: 5.5.0
port: 8983
download_dir: tmp/solr_download
instance_dir: tmp/solr
collection:
    persist: false
    dir: solr/config/
    name: test
```

Example file `.fcrepo_wrapper_dev`:

```ruby
port: 8984
enable_jms: false
version: 4.5.0
download_dir: tmp/fedora/download
instance_dir: tmp/fedora
fcrepo_home_dir: tmp/fedora/dev
```
Example file `.fcrepo_wrapper_test`:

```ruby
port: 8984
enable_jms: false
version: 4.5.0
download_dir: tmp/fedora/download
instance_dir: tmp/fedora
fcrepo_home_dir: tmp/fedora/test
```

## Running solr and fedora

To run solr using your config file:

```bash
$ solr_wrapper --config .solr_wrapper_dev
```

To run fedora using your config file:
```bash
$ fcrepo_wrapper --config .fcrepo_wrapper_dev
```

## Running the specs

* Make sure postgres server is running
* Make sure marmotta is running, or CI environment variable is set to bypass marmotta

```bash
$ solr_wrapper --config .solr_wrapper_test
$ fcrepo_wrapper --config .fcrepo_wrapper_test
$ bundle exec rake spec
```
