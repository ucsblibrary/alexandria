# Running ADRL in Vagrant

## PreReqs

- Vagrant 1.7.2 or higher
- VirtualBox 4.3.30 or higher
- Git
- Ansible 1.9.1 or higher
- PostgreSQL

## Part A: get or build a Vagrant Box with CentOS 7.0 on it.

- Option 1: Get a Vagrant box already built from another developer
- Option 2: Build your own Vagrant box.

### Building your own Vagrant box:

1. If you didn’t clone this repository with `--recursive`, fetch the
   submodules with `git submodule init && git submodule update`.

2. `cd vagrant-centos` and check out the CentOS 7.0 branch

    ```
    git checkout -b CentOS-7.0 origin/CentOS-7.0
    ```

3. Download the Centos-7 disk image (ISO):

    ```
    curl ftp://ftp.ucsb.edu//pub/mirrors/linux/centos/7.1.1503/isos/x86_64/CentOS-7-x86_64-Minimal-1503-01.iso -o isos/CentOS-7-x86_64-Minimal-1503-01.iso
    ```

4. Run the setup script

    ```
    ./setup
    # Wait for it to complete, then run the cleanup and package
    # command emmited by the setup script
    ./cleanup && vagrant package --base centos70-x86_64 --output boxes/centos70-x86_64-20150730.box
    ```

## Part B: Start a local VM

1. If you didn’t clone this repository with `--recursive`, fetch the
   submodules with `git submodule init && git submodule update`.

2. `vagrant up`

    At this point Apache should be running at: http://localhost:8484/

    Tomcat should be running: http://localhost:2424/

    Fedora should be running: http://localhost:2424/fedora/

    PostGres should be running:

    Redis should be running:

    Passenger should be running:

    Marmotta should be running:

3. `bundle install`

4. `make deploy` and view the fruits of yr labor at <http://localhost:8484>.

    ```
    # after successful cap deploy...
    # check status of Tomcat
      sudo service tomcat status
    # Restart Tomcat
      sudo service tomcat restart
    # It takes Tomcat a while to fully restart (Fedora takes a while).
    # check if Tomcat is running with:
    curl localhost:8080
    curl localhost:8080/fedora/rest
    curl localhost:8080/hydra/
    # check status of apache
      sudo service httpd status
    # restart apache
      sudo service httpd restart
    # check what is being served out on port 80
      curl localhost
     ADRL should be available at:
       http://localhost:8484
    ```

## Ingesting

- To import multiple ETDs from a single file:

    ```
    RAILS_ENV=production bundle exec traject -c traject_config.rb /opt/download_root/marc/batch1.xml
    ```

    (will need proquest zip files to go with these)

- For images CSV use rogers collection

- For images MODS use flying-A & SB Picture postcards

See also: <https://github.com/curationexperts/alexandria-v2/wiki>

## Manual Setup Notes

### Dev/Test Configuration
  * Copy `config/blacklight.yml.template` to `config/blacklight.yml`
  * Copy `config/database.yml.template` to `config/database.yml`
  * Copy `config/fedora.yml.template` to `config/fedora.yml`
  * Copy `config/ezid.yml.template` to `config/ezid.yml`
  * Copy `config/secrets.yml.template` to `config/secrets.yml`
  * Edit `config/secrets.yml` and paste in a new secret key
  * update the host\_name in `config/environments/{environment}.rb`
  * Copy `config/smtp.yml.template` to `config/smtp.yml`
  * Edit `config/smtp.yml` and add fake email settings
  * Copy `config/solr.yml.template` to `config/solr.yml`
  * Copy `config/redis.yml.template` to `config/redis.yml`
  * Copy `config/resque-pool.yml.template` to `config/resque-pool.yml`
  * Copy `config/ldap.yml.template` to `config/ldap.yml`
  * Install [PhantomJS](https://github.com/teampoltergeist/poltergeist#installing-phantomjs)

### Set up Jetty

```
rake jetty:unzip
rake jetty:start
```

### Set up Marmotta

Download and unzip: https://github.com/curationexperts/marmotta-standalone/archive/master.zip

Go into the unpacked archive and start it up.
```
java -jar start.jar -Xmx1024mb -Djetty.port=8180
```

Then configure it to connect to a Postgres instance by following the directions here:
http://marmotta.apache.org/configuration.html

### Install imagemagick

On a mac:
```
brew install imagemagick --with-jp2 --with-libtiff --with-ghostscript
```

### Background jobs

#### Install redis

On a mac:
```
brew install redis
```

#### Run background jobs

To start the redis server:
```
redis-server /usr/local/etc/redis.conf
```

To see the status of recent jobs in the browser console:
```
resque-web
```

To start worker(s) to run the jobs:
```
resque-pool
```

### Run the test suite

  * Make sure jetty is running
  * Make sure marmotta is running, or CI environment variable is set to bypass marmotta
  * `bundle exec rake spec`

### Import Data

#### MODS records
```
script/import_mods_records ../mods-for-adrl/mods_demo_set/demo_sbhcmss36_SantaBarbaraPicturePostcards ../alexandria-images/special_collections/mss36-sb-postcards/tiff-a16

script/import_mods_records ../mods-for-adrl/mods_demo_set/demo_sbhcmss78_FlyingAStudios ../alexandria-images/special_collections/spc-flying-a/conway-2010/16bit

script/import_mods_records ../mods-for-adrl/mods_demo_set/collection_records ./tmp
```

The first argument to the script is the directory that contains the MODS files.  The second argument is the directory that contains supporting files, such as image files.

Note:  When importing collections, the 2nd argument won't actually be used, so you can set it to any valid directory.

#### CSV records

##### Images
```
script/import_csv ../ucsb_sample_data/adrl-dm/ingest-ready/pamss045\(Couper\)/pamss045\(Couper\)-objects.csv ../alexandria-images/special_collections/pamss045/tiff-a16
```

##### Collections
```
script/import_csv ../ucsb_sample_data/adrl-dm/ingest-ready/pamss045\(Couper\)/pamss045\(Couper\)-collection.csv Collection
```

The first argument to the script is the CSV file that contains the records.  The second argument is the directory that contains supporting files, such as image files.

#### MARC records (ETDs)

```
bundle exec traject -c traject_config.rb /opt/download_root/marc/etds1-150.xml | tee -a etd-import.log
```
