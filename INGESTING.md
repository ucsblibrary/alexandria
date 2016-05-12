# Ingesting records into ADRL

The descriptive metadata repository
(https://stash.library.ucsb.edu/projects/CMS/repos/adrl-dm/browse) is
automatically cloned to `/opt/ingest/metadata/adrl-dm` during
provisioning.  Make sure it is up-to-date when running ingests.

The remote fileshare with supporting images is automatically mounted
to `/opt/ingest/data`.

## From the web interface

TODO

## From the command-line

Ingests should be done on the remote ADRL server in the “current”
directory: `/opt/alexandria-v2/current`.

Most ingests can be performed with the `bin/ingest` script:

```
$ bin/ingest -h
Options:
  -c, --class=<s>        Object class (e.g., Image, Collection)
  -d, --data=<s+>        Data file(s)/directory
  -f, --format=<s>       Metadata format (csv, mods, etd, cyl)
  -m, --metadata=<s+>    Metadata file(s)/directory
  -s, --skip=<i>         Skip the first N records (default: 0)
  -h, --help             Show this message
```

Multiple files and file globs (e.g., `/path/to/files*`) can be passed
to the `--data` and `--metadata` arguments.

For large ingests, you’ll need to connect to ADRL from a machine
that’s always running, or detach the ingest process so you can log out
of the remote server.  The easiest way is with `nohup`; here’s how
you’d ingest the sample ETDs on the test server:

```shell
ssh adrl@hostname
cd /opt/alexandria-v2/current
RAILS_ENV=production nohup bin/ingest -f etd -d /opt/download_root/proquest/etdadmin_upload_* >> log/ingest-$(date "+%Y.%m.%d").log 2>&1 &
```

That will allow you to log out of the machine, and write the output of
the ingest script to a file in `/opt/alexandria-v2/current/log/` with
the date of the ingest.

If you start an ingest with `bin/ingest` that fails or is stopped, it
will tell you how many records it managed to ingest.  You can begin
the ingest where it stopped by running `bin/ingest` again and adding
`--skip N`, where _N_ is the number of records that have already been
successfully ingested.

### Ingesting ETDs

```
RAILS_ENV=production bin/ingest -f etd -d /opt/ingest/data/etds/2adrl_ready/*.zip
```

After you import the individual ETDs, you need to add the
collection-level record to the repository:

```
RAILS_ENV=production bin/ingest -f mods -m /opt/ingest/metadata/adrl-dm/ingest-ready/etds/
```

### Ingesting Wax Cylinders

```
RAILS_ENV=production bin/ingest -f cyl -m spec/fixtures/marcxml/cylinder_sample_marc.xml -d /data/objects-cylinders
```

### Ingesting MODS records

```
RAILS_ENV=production bin/ingest -f mods -m <XML files> [-d <images>]
```

The `bin/ingest` script searches into the directories you specify, so
you can provide the directory that contains both the `collection` and
`objects` metadata directories:

```
RAILS_ENV=production bin/ingest -f mods -m /opt/data/ingest/metadata/adrl-dm/ingest-ready/sbhcmss036/ -d /opt/data/images/sbhcmss036/
```

### Ingesting CSV records

```
RAILS_ENV=production bin/ingest -f csv -m /path/to/metadata.csv -d /path/to/files
```

#### How to specify the type of a local authority for CSV ingest

The CSV importer will create local authorities for local names or
subjects that don't yet exist.

To specify a new local authority in the CSV file, use pairs of columns
for the type and name of the authority.  For example, if you have a
collector called "Joel Conway", you need 2 columns in your CSV file:

1. A "collector_type" column with the value "Person"
2. A "collector" column with the value "Joel Conway"

You only need the matching ```*_type``` column if you are trying to
add a new local authority.  For URIs, just put them straight into the
"collector" column, without adding a "collector_type" column.

Usage Notes:

* If the value of the column is a URI (for external authorities or
  pre-existing local authorities), then don't use the matching
  ```*_type``` column.

* If the value of the column is a String (for new local authorities),
  add a matching ```*_type``` column.  The columns must be in pairs
  (e.g. "composer_type" and "composer"), and the ```*_type``` column
  must come first.

* The possible values for the ```*_type``` fields are: Person, Group,
  Organization, and Topic.

For example, see the "lc_subject", "composer", and "rights_holder"
fields in [the example CSV file in the spec fixtures]
(https://github.com/curationexperts/alexandria-v2/blob/master/spec/fixtures/csv/pamss045_with_local_authorities.csv).

#### How to specify the type of a Note for CSV ingest

The Notes work the same way as the local authorites (see section
above): If the note has a type that needs to be specified, then you
must have a ```note_type``` column, followed by a ```note``` column.

### Ingesting Local Authorities

#### Exporting Local Authorities to a CSV File

To export local authorities from the local machine, run the export
script `RAILS_ENV=production bin/export-authorities`. If you need to
export local authorities on a remote box and don't want to run the
process on that box, see the notes in the wiki:
[Exporting Local Authorities](https://github.com/curationexperts/alexandria-v2/wiki/Exporting-Local-Authorities-(especially-from-remote-systems))

#### Importing Local Authorities from a CSV File

To import local authorities to the local system, you will need a CSV
file defining the authorities to import.  Ideally, this is an export
from another system created by the exporter above.  To run the import
script use `RAILS_ENV=production bin/ingest-authorities <csv_file>`

# How ingesting works

Cylinders, ETDs, MODS records and CSV records can all be ingested by
`bin/ingest`, but the way it ingests each is slightly different.

## How ETDs are ingested

ETDs (Electronic Dissertations and Theses) are provided to us as
zipfiles by ProQuest.  In each zipfile (named something like
`etdadmin_upload_56186.zip`) there is the PDF of the dissertation or
thesis, an XML file containing the metadata for the ETD, and
(optionally) any supplemental files the author provided to ProQuest.

We don’t ingest an ETD using the ProQuest metadata directly; instead
we use the XML file to find the ETD in Aleph; then ingest it using the
MARC metadata from Aleph.

What happens when you run `bin/ingest -f etd /path/to/etds/etdadmin_upload*`, then, is this:

1. The zipfiles matched by `/path/to/etds/etdadmin_upload*` are
   unzipped by {Proquest.extract} into a temporary directory.
   {Proquest.extract} returns a hash with paths to each of the
   elements in the zipfile:

    ```ruby
    {
      xml: '/tmp/etdadmin_upload_56186.zip/NAME_ucsb_0035D_12328_DATA.xml’,
      pdf: '/tmp/etdadmin_upload_56186.zip/NAME_ucsb_0035D_12328.pdf’,
      supplements: [
        '/tmp/etdadmin_upload_56186.zip/NAME_ucsb_0035D_67/cat.gif'
      ]
    }
    ```


2. Next, `bin/ingest` passes the path to the XML file of each ETD to
   {Importer::ETD.fetch_marc}, which parses each XML file and queries
   Aleph, returning a single string of MARC containing the metadata
   for all the ETDs matched by `/path/to/etds/etdadmin_upload*`.

3. The MARC string is passed (via `StringIO`) to `MARC::XMLReader`,
   which lets us iterate through each MARC record.

    (The ability to iterate one by one through records is very
    important, because it allows us to keep track of how many records
    have been ingested in case the ingest fails and we have to restart
    it.)

4. Finally, for each MARC record, `bin/ingest`

     1. creates a new `Traject::Indexer`,
     2. provides it with the configuration file `lib/traject/etd_config.rb`,
     3. passes it the hash generated by {Proquest.extract}, and
     4. uses `indexer.map_record` to convert the MARC to a hash and
        passes it to {ObjectFactoryWriter#put}.

5. {ObjectFactoryWriter#put} tidies up the information extracted from
   the MARC and passes it (as `attributes`) and the ETD hash to
   {ObjectFactoryWriter#build_object}, which in turn creates the
   {Importer::Factory} for ETDs.

6. {Importer::Factory::ETDFactory} is what saves the ETD into Fedora.
   It inherits from {Importer::Factory::ObjectFactory} and most of its
   methods are defined in that superclass.  The only method overridden
   by every subclass of `ObjectFactory` is `#attach_files`.

7. {ObjectFactoryWriter#build_object} created the instance of
   {Importer::Factory::ETDFactory} in step 5, and it also calls its
   `#run` method, which is defined in the
   {Importer::Factory::ObjectFactory} superclass.  `#run` either
   creates a new object in Fedora, or updates an existing one,
   depending on whether a matching object is found based on the
   object’s Fedora ID (sometimes called the PID) or the system
   identifier field.  If neither correspond to an object already in
   Fedora, a new Fedora object is created with
   {Importer::Factory::ObjectFactory#create}.  If a match is found,
   {Importer::Factory::ObjectFactory#update} updates the metadata in
   Fedora.
