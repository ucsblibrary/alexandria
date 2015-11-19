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

    You can SSH into the VM with `vagrant ssh` or manually by using
    the config produced by `vagrant ssh-config`.

3. `bundle install`

4. `make deploy` to run Capistrano

    - At this point Apache should be running at: http://localhost:8484/

    - Tomcat should be running: http://localhost:2424/

    - Solr should be running: http://localhost:2424/hydra

        The first time you deploy to the VM, you may have to manually
        restart Tomcat in order for Solr to run: `sudo services tomcat restart`

    - Fedora should be running: http://localhost:2424/fedora/

    - PostgreSQL should be running:

    - Redis should be running:

    - Passenger should be running:

    - Marmotta should be running:

5. On the VM, add the LDAP password from Secret Server to `/opt/alex2/shared/config/ldap.yml`

## Ingesting

See also: <https://github.com/curationexperts/alexandria-v2/wiki>

### ETDs

There are scripts to ingest records from zipfiles like those on the
[sample ETDs page](https://wiki.library.ucsb.edu/display/repos/ETD+Sample+Files+for+DCE).
The process is as follows:

1. Move the zipfile(s) into the root of this repository so that they
   appear in the VM’s shared directory (by default `/vagrant`).

2. SSH into the VM; and `cd` to the “current” directory: `cd /opt/alex2/current`.

3. Run the ETD script: `bundle exec bin/ingest-etd /vagrant/Batch\ 3.zip`.

### Images

#### CSV

##### Individual images
```
bundle exec bin/ingest-csv ../ucsb_sample_data/adrl-dm/ingest-ready/pamss045\(Couper\)/pamss045\(Couper\)-objects.csv ../alexandria-images/special_collections/pamss045/tiff-a16
```

##### Collections
```
bin/ingest-csv ../ucsb_sample_data/adrl-dm/ingest-ready/pamss045\(Couper\)/pamss045\(Couper\)-collection.csv Collection
```

The first argument to the script is the CSV file that contains the records.  The second argument is the directory that contains supporting files, such as image files.

#### MODS

```
bin/ingest-mods ../mods-for-adrl/mods_demo_set/demo_sbhcmss36_SantaBarbaraPicturePostcards ../alexandria-images/special_collections/mss36-sb-postcards/tiff-a16

bin/ingest-mods ../mods-for-adrl/mods_demo_set/demo_sbhcmss78_FlyingAStudios ../alexandria-images/special_collections/spc-flying-a/conway-2010/16bit
```

The first argument to the script is the directory that contains the MODS files.  The second argument is the directory that contains supporting files, such as image files.

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
