# Running a development instance in Vagrant

## Prerequisites

- Ansible 1.9.1 or higher
- Vagrant 1.7.2 or higher
- VirtualBox 4.3.30 or higher

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

2. `bundle install`

3. `cd provisioning && bin/create development`

    Once the VM is created, you can SSH into it with `vagrant ssh` or
    manually by using the config produced by `vagrant ssh-config`.

4. `make vagrant` to deploy with Capistrano

5. The following services should be running; `sudo service [program]
    restart` if not:

    - Apache/Passenger (httpd): http://localhost:8484/

    - Tomcat: http://localhost:2424/

    - Solr: http://localhost:2424/hydra

    - Fedora: http://localhost:2424/fedora/

    - Marmotta: http://localhost:2424/marmotta

    - PostgreSQL:

    - Redis:


5. On the VM, add the LDAP password from Secret Server to `/opt/alex2/shared/config/ldap.yml`

# Provisioning and deploying to production

## Prerequisites

- Ansible 1.9.1 or higher
- 4GB+ RAM on the server

## Steps

1. `bundle install`

2. `cd provisioning && bin/create production` to provision the production server

    - It’s (relatively) safe to set `REMOTE_USER` as root, since a
    non-root `deploy` user will be created for Capistrano.

3. Add `/home/deploy/.ssh/id_rsa.pub` to the authorized keys for this repository.

3. `SERVER=alexandria.ucsb.edu REPO=ssh://git@stash.library.ucsb.edu:7999/dr/adrl-v2.git make prod` to deploy with Capistrano.

# Troubleshooting

- **mod_passenger fails to compile**: There’s probably not enough memory on the server.

- **`SSHKit::Command::Failed: bundle exit status: 137` during `bundle install`**: Probably not enough memory.

- **Nokogiri fails to compile**: Add the following to `config/deploy.rb`:

    ```ruby
    set :bundle_env_variables, nokogiri_use_system_libraries: 1
    ```

- **Passenger fails to spawn process**

    ```
    [ 2015-11-26 01:56:19.7981 20652/7f16c6f19700 App/Implementation.cpp:303 ]: Could not spawn process for application /opt/alex2/current: An error occurred while starting up the preloader: it did not write a startup response in time.
    ```

    Try restarting Apache and deploying again.

- **Timeout during assets precompile**:  Not sure yet!

# Testing

  * Make sure jetty is running
  * Make sure marmotta is running, or CI environment variable is set to bypass marmotta
  * `bundle exec rake spec`

# Ingesting

(See also: <https://github.com/curationexperts/alexandria-v2/wiki>)

The descriptive metadata repository
(https://stash.library.ucsb.edu/projects/CMS/repos/adrl-dm/browse) is
automatically cloned to `/opt/download_root/metadata` during
provisioning.  Make sure it is up-to-date when running ingests.

The remote fileshare with supporting images is automatically mounted
to `/opt/ingest/data`.

## ETDs

The ETD collection is created separately from individual records.  See
https://wiki.library.ucsb.edu/pages/viewpage.action?pageId=16288317 on
creating it.

Once the collection has been created, `bin/ingest-etd` can be used to
ingest records:

1. SSH into the server and `cd` to the “current” directory: `cd /opt/alex2/current`.

2. Run the ETD script: `bundle exec bin/ingest-etd /opt/ingest/data/etds/2adrl_ready/*.zip`.

## Images

### MODS

Importing a collection of MODS is a two-step process.  First the
collection is created, then individual records with attachments are
minted and added to the collection.

1. Create a collection: `bin/ingest-mods ../mods-for-adrl/mods_demo_set/collection ../alexandria-images/mods_demo_images/`

2. Add the records: `bin/ingest-mods ../mods-for-adrl/mods_demo_set/objects ../alexandria-images/mods_demo_images/`

The first argument to the script is the directory that contains the
MODS files.  The second argument is the directory that contains
supporting files, such as image files.

### CSV

```
bin/ingest-csv <CSV file> [supporting files] [type]
```

The first argument to the script is the CSV file that contains the
records.  Optional arguments are the directory that contains
supporting files, such as image files, and the type: currently,
`Image`, `ETD`, or `Collection`.

Ingesting CSVs, like MODs, is a two-part process; first create the
collection, then individual records:

1. `bin/ingest-csv /path/to/collection.csv Collection`

2. `bin/ingest-csv /path/to/objects.csv /path/to/files Image`
