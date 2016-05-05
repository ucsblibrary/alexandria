[![Build Status](https://travis-ci.org/curationexperts/alexandria-v2.svg?branch=master)](https://travis-ci.org/curationexperts/alexandria-v2)

# Provisioning

For provisioning, there is a wrapper script that runs Ansible for us:
`bin/provision`.  Run it from the root directory:

```shell
bin/provision <production|staging|test|vagrant|local> [variables.cfg]
```

The `bin/provision` wrapper script’s optional second argument is a
list of pre-defined variables; see the format in
`ansible/variables.cfg.template`.  If `bin/provision` is run without a
second argument, it will prompt you for the values and write a
temporary file that can be re-used on failed plays.

Variables for passwords and other sensitive information are kept in
encryped Ansible Vault files: `ansible/prod_vars.yml`,
`ansible/stage_vars.yml`, and `ansible/dev_vars.yml`.  When you run
`bin/provision <production|staging|test|vagrant|local>` (`test`,
`vagrant`, and `local` all use `dev_vars.yml`), Ansible will prompt
you for the password to decrypt the corresponding file; the passwords
are in Secret Server.

Some of the Rails configuration files are written by Ansible during
provisioning, since they contain server-specific information and
should not be committed to Git.  The list of files/directories that
are createed or modified during provisioning corresponds to the
`linked_dirs` and `linked_files` in `config/deploy.rb`.  They are
written to the server in the `shared` directory of the project root,
and are symlinked into each `release` directory by Capistrano each
time we deploy.

## OSX

1. `bin/provision local [variables.cfg]`

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

2. `bin/provision vagrant [variables.cfg]`

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

## Production or staging server

### Prerequisites

- Ansible 2.0.0 or higher
- 4GB+ RAM on the server

### Steps

1. `bin/provision production [variables.cfg]` to provision the
   production server; or

    `bin/provision staging [variables.cfg]` to provision a staging server.

    - It’s (relatively) safe to set `REMOTE_USER` as root, since a
      non-root `deploy` user will be created for Capistrano.

2. Add `/home/deploy/.ssh/id_rsa.pub` to the authorized keys for the ADRL repository.

3. `SERVER=alexandria.ucsb.edu REPO=git@github.library.ucsb.edu:ADRL/alexandria.git make prod` to deploy with Capistrano.

## EC2 server

Review/modify ansible/ansible_vars.yml. If you're not creating your server on EC2, comment out the launch_ec2 and ec2 roles in ansible/ansible-ec2.yml, boot your server, add your public key to the centos user's authorized_keys file, add a disk at /opt if desired, then run the ansible scripts with:
```
ansible-playbook ansible/ansible-ec2.yml --private-key=/path/to/private/half/of/your/key
```

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
automatically cloned to `/opt/ingest/metadata/adrl-dm` during
provisioning.  Make sure it is up-to-date when running ingests.

The remote fileshare with supporting images is automatically mounted
to `/opt/ingest/data`.

Most ingests can be performed with `bin/ingest`:
```
$ bin/ingest -h
Usage: ingest [options]
    -h, --help                       Prints this help
    -f, --format STRING              Metadata format (csv, mods, etd, cyl)
    -m, --metadata PATH              Path to metadata files/directory
    -d, --data PATH                  Path to data files/directory
    -o, --object STRING              The type of object (e.g. Image, Collection)
```

Ingests should be done on the remote server in the “current” directory: `/opt/alexandria-v2/current`.

## ETDs

```
RAILS_ENV=production bin/ingest -f etd -d /opt/ingest/data/etds/2adrl_ready/*.zip
```

After you import the individual ETDs, you need to add the
collection-level record to the repository:

```
RAILS_ENV=production bin/ingest -f mods -m /opt/ingest/metadata/adrl-dm/ingest-ready/etds/
```

## Wax Cylinders

```
RAILS_ENV=production bin/ingest -f cyl -m spec/fixtures/marcxml/cylinder_sample_marc.xml -d /data/objects-cylinders
```

## Images

### MODS

Importing a collection of MODS is a two-step process.  First the
collection is created, then individual records with attachments are
minted and added to the collection.

1. Create a collection: `RAILS_ENV=production bin/ingest -f mods -m ../mods-for-adrl/mods_demo_set/collection`

2. Add the records: `RAILS_ENV=production bin/ingest -f mods -m ../mods-for-adrl/mods_demo_set/objects -d ../alexandria-images/mods_demo_images/`

### CSV

```
RAILS_ENV=production bin/ingest -f csv -m <CSV file> -d [supporting files] -o [object type]
```

If the object type is not specified, it defaults to “Collection”.  The
other valid object type (as of now) is “Image”:

```
RAILS_ENV=production bin/ingest -f csv -m /path/to/metadata.csv -d /path/to/files -o Image
```

#### How to specify the type of a local authority for CSV ingest

The CSV importer will create local authorities for local names or subjects that don't yet exist.

To specify a new local authority in the CSV file, use pairs of columns for the type and name of the authority.  For example, if you have a collector called "Joel Conway", you need 2 columns in your CSV file:

1. A "collector_type" column with the value "Person"
2. A "collector" column with the value "Joel Conway"

You only need the matching ```*_type``` column if you are trying to add a new local authority.  For URIs, just put them straight into the "collector" column, without adding a "collector_type" column.

Usage Notes:

* If the value of the column is a URI (for external authorities or pre-existing local authorities), then don't use the matching ```*_type``` column.

* If the value of the column is a String (for new local authorities), add a matching ```*_type``` column.  The columns must be in pairs (e.g. "composer_type" and "composer"), and the ```*_type``` column must come first.

* The possible values for the ```*_type``` fields are:  Person, Group, Organization, and Topic.

For example, see the "lc_subject", "composer", and "rights_holder" fields in [the example CSV file in the spec fixtures]
(https://github.com/curationexperts/alexandria-v2/blob/master/spec/fixtures/csv/pamss045_with_local_authorities.csv).

#### How to specify the type of a Note for CSV ingest

The Notes work the same way as the local authorites (see section above):  If the note has a type that needs to be specified, then you must have a ```note_type``` column, followed by a ```note``` column.

## Local Authorities

### Exporting Local Authorities to a CSV File

To export local authorities from the local machine, run the export
script `RAILS_ENV=production bin/export-authorities`. If you need to
export local authorities on a remote box and don't want to run the
process on that box, see the notes in the wiki:
[Exporting Local Authorities](https://github.com/curationexperts/alexandria-v2/wiki/Exporting-Local-Authorities-(especially-from-remote-systems))

### Importing Local Authorities from a CSV File

To import local authorities to the local system, you will need a CSV file defining the authorities to import.
Ideally, this is an export from another system created by the exporter above.
To run the import script use `RAILS_ENV=production bin/ingest-authorities <csv_file>`

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
