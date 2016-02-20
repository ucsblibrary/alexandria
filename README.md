[![Build Status](https://travis-ci.org/curationexperts/alexandria-v2.svg?branch=master)](https://travis-ci.org/curationexperts/alexandria-v2)

# Setup

## OSX

1. `bin/provision local`

2. `bin/rails server`

5. The following services should be running; `brew services restart [program]` if not:

    - Tomcat: http://localhost:8080/

        - Solr: http://localhost:8080/hydra

        - Fedora: http://localhost:8080/fedora/

        - Marmotta: http://localhost:8080/marmotta

    - PostgreSQL: <http://localhost:5432>

    - Redis: <http://localhost:6379>

## Vagrant

### Prerequisites

- Ansible 2.0.0 or higher
- Vagrant 1.7.2 or higher
- VirtualBox 4.3.30 or higher

### Part A: get or build a Vagrant Box with CentOS 7.0 on it.

- Option 1: Get a Vagrant box already built from another developer
- Option 2: Build your own Vagrant box.

#### Building your own Vagrant box:

1. If you didn’t clone this repository with `--recursive`, fetch the
   submodules with `git submodule init && git submodule update`.

2. Download a Centos-7 disk image (ISO):

    ```
    curl ftp://ftp.ucsb.edu//pub/mirrors/linux/centos/7.1.1503/isos/x86_64/CentOS-7-x86_64-Minimal-1503-01.iso -o vagrant-centos/isos/CentOS-7-x86_64-Minimal-1503-01.iso
    ```

3. Run the setup script: `cd vagrant-centos && ./setup isos/CentOS-7-x86_64-Minimal-1503-01.iso ks.cfg`

## Part B: Start a local VM

1. If you didn’t clone this repository with `--recursive`, fetch the
   submodules with `git submodule init && git submodule update`.

2. `bin/provision development`

    Once the VM is created, you can SSH into it with `vagrant ssh` or
    manually by using the config produced by `vagrant ssh-config`.

4. `make vagrant` to deploy with Capistrano

5. The following services should be running; `sudo service [program] restart` if not:

    - Apache/Passenger (httpd): http://localhost:8484/

    - Tomcat: http://localhost:2424/

        - Solr: http://localhost:2424/hydra

        - Fedora: http://localhost:2424/fedora/

        - Marmotta: http://localhost:2424/marmotta

    - PostgreSQL: <http://localhost:5432>

    - Redis: <http://localhost:6379>

## vSphere

### Prerequisites

- Ansible 2.0.0 or higher
- 4GB+ RAM on the server

### Steps

1. `bin/provision production` to provision the production server

    - It’s (relatively) safe to set `REMOTE_USER` as root, since a
      non-root `deploy` user will be created for Capistrano.

2. Add `/home/deploy/.ssh/id_rsa.pub` to the authorized keys for the ADRL repository.

3. `SERVER=alexandria.ucsb.edu REPO=git@github.library.ucsb.edu:ADRL/alexandria.git make prod` to deploy with Capistrano.

# Troubleshooting

- **mod_passenger fails to compile**

    There’s probably not enough memory on the server.

- **`SSHKit::Command::Failed: bundle exit status: 137` during `bundle install`**

    Probably not enough memory.

- **Nokogiri fails to compile**

    Add the following to `config/deploy.rb`:

    ```ruby
    set :bundle_env_variables, nokogiri_use_system_libraries: 1
    ```

# Ingesting

(See also: <https://github.com/curationexperts/alexandria-v2/wiki>)

The descriptive metadata repository
(https://stash.library.ucsb.edu/projects/CMS/repos/adrl-dm/browse) is
automatically cloned to `/opt/download_root/metadata` during
provisioning.  Make sure it is up-to-date when running ingests.

The remote fileshare with supporting images is automatically mounted
to `/opt/ingest/data`.

## Local Authorities

### Exporting Local Authorities to a CSV File

To export local authorities from the local machine, run the export script `bin/export-authorities`
If you need to export local authorities on a remote box and don't want to run the process  on that box, 
see the notes in the wiki: [Exporting Local Authorities](https://github.com/curationexperts/alexandria-v2/wiki/Exporting-Local-Authorities-(especially-from-remote-systems)) 

### Importing Local Authorities from a CSV File

To import local authorities to the local system, you will need a CSV file defining the authorities to import.  
Ideally, this is an export from another system created by the exporter above.   
To run the import script use `bin/ingest-authorities <csv_file>`  

## ETDs

1. SSH into the server and `cd` to the “current” directory: `cd /opt/alex2/current`.

2. Run the ETD script: `bundle exec bin/ingest-etd /opt/ingest/data/etds/2adrl_ready/*.zip`.

After you import the individual ETDs, you need to add the collection-level record to the repository. See
https://wiki.library.ucsb.edu/pages/viewpage.action?pageId=16288317 on
creating it.

## Wax Cylinders

Run the import script
```
RAILS_ENV=production bin/ingest-cylinders spec/fixtures/marcxml/cylinder_sample_marc.xml  /data/objects-cylinders
```

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

#### How to specify the type of a local authority for CSV ingest

The CSV importer will create local authorities for local names or subjects that don't yet exist.

To specify a new local authority in the CSV file, use pairs of columns for the type and name of the authority.  For example, if you have a collector called "Joel Conway", you need 2 columns in your CSV file:

1. A "collector_type" column with the value "Person"
2. A "collector" column with the value "Joel Conway"

You only need the matching ```*_type``` column if you are trying to add a new local authority.  For URIs, just put them straight into the "collector" column, without adding a "collector_type" column.

Usage Notes:

* If the value of the column is a URI (for external authorities or pre-existing local authorities), then don't use the matching ```*_type``` column.

* If the value of the column is a String (for new local authorities), add a matching ```*_type``` column.  The columns must be in pairs (e.g. "composer_type" and "composer"), and the ```*_type``` column must come first.

* The possible values for the ```*_type``` fields are:  Person, Group, Organization, and Subject.

For example, see the "lc_subject", "composer", and "rights_holder" fields in [the example CSV file in the spec fixtures]
(https://github.com/curationexperts/alexandria-v2/blob/master/spec/fixtures/csv/pamss045_with_local_authorities.csv).


# Caveats

* Reindexing all objects (to an empty solr) requires two passes (`2.times { ActiveFedora::Base.reindex_everything }`). This situtation is not common. The first pass will guarantee that the collections are indexed, and the second pass will index the collection name on all the objects. The object indexer looks up the collection name from solr for speed.

# Troubleshooting

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

# Using Ansible to build production machines

We recommend using Ansible to create production instances of Alexandria-v2. Clone https://github.com/acozine/sufia-centos and symlink the roles subdirectory of the sufia-centos code into the ansible subudirectory of the Alexandria-v2 code:
```
sudo ln -s /path/to/sufia-centos/roles /path/to/alexandria-v2/ansible/roles
```
Review/modify ansible/ansible_vars.yml. If you're not creating your server on EC2, comment out the launch_ec2 and ec2 roles in ansible/ansible-ec2.yml, boot your server, add your public key to the centos user's authorized_keys file, add a disk at /opt if desired, then run the ansible scripts with:
```
ansible-playbook ansible/ansible-ec2.yml --private-key=/path/to/private/half/of/your/key
```
