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
