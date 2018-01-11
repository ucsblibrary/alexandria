# Ingesting records into ADRL

The descriptive metadata repository is automatically cloned to
`/opt/ingest/metadata/adrl-dm` during provisioning.  Make sure it is
up-to-date when running ingests.

The remote fileshare with supporting images is automatically mounted
to `/opt/ingest/data`.

Some ingests trigger background jobs, which are handled by Resque.
The web interface for Resque can be started with the following:
```
RAILS_ENV=production bundle exec resque-web -N curation_concerns:production
```

## From the web interface

TODO

## From the command-line

Ingests should be done on the remote ADRL server in the “current”
directory: `/opt/alexandria/current`.

Most ingests can be performed with the `bin/ingest` script:

```
$ bin/ingest -h
Command line object ingest for the UCSB Alexandria Digital Library

Example:
      RAILS_ENV=development ./bin/ingest -f csv -m /data/mss292.csv -d
/data/mss292-objects
Usage:
      RAILS_ENV=[development|test|production] ./bin/ingest [options]
where [options] are:
  -d, --data=<s+>        Data file(s)/directory
  -f, --format=<s>       Metadata format (csv, mods, etd, cyl)
  -m, --metadata=<s+>    Metadata file(s)/directory
  -n, --number=<i>       Only ingest N records
  -s, --skip=<i>         Skip the first N records (default: 0)
  -v, --verbosity=<s>    Log verbosity: DEBUG, INFO, WARN, ERROR
                         (default: INFO)
  -h, --help             Show this message
```

Multiple files and file globs (e.g., `/path/to/files*`) can be passed
to the `--data` and `--metadata` arguments.

By default, the ingest process will run in the background using Resque, and print output to a
log file.

It is possible to change what job runner is used by setting the `RAILS_QUEUE`
environment variable (e.g., to `inline` or `async`).  However, those adapters
currently fail to ingest cylinders correctly.

If you start an ingest with `bin/ingest` that fails or is stopped, the
logs will tell you how many records it managed to ingest.  You can
begin the ingest where it stopped by running `bin/ingest` again and
adding `--skip N`, where _N_ is the number of records that have
already been successfully ingested.

### Ingesting ETDs

Before you can import individual ETDs, you need to add the
collection-level record to the repository:

```
RAILS_ENV=production bin/ingest -f mods -m /opt/ingest/metadata/adrl-dm/ingest-ready/etds/
```

Then ingest ETDs:

```
RAILS_ENV=production bin/ingest -f etd -d /opt/ingest/data/etds/2adrl_ready/*.zip
```

Currently, because we’re using a local modification to collection
membership (see {file:local_collections.md}), we need to update the
ETD collection after ingesting members:

```
irb> etd_collection.update_index
```

### Ingesting Wax Cylinders

Before you can import individual Cylinders, you need to add the
collection-level record to the repository:

```
RAILS_ENV=production bin/ingest -f csv -m /opt/ingest/metadata/adrl-dm/ingest-ready/cylinders/cylinders-collection.csv
```

Then ingest Cylinders:

```
RAILS_ENV=production bin/ingest -f cyl -m spec/fixtures/marcxml/cylinder_sample_marc.xml -d /data/objects-cylinders
```

Currently, because we’re using a local modification to collection
membership (see {file:local_collections.md}), we need to update the
Cylinder collection after ingesting members:

```
irb> cylinder_collection.update_index
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
RAILS_ENV=production bin/ingest -f csv -m /path/to/metadata.csv [-d /path/to/files]
```

{Importer::CSV} will use the `files` column from the CSV to determine where the
associated binaries are located.  First it checks if the files specified exist
in the directory specified as `binary_source_root` in `application.yml` (which
can be overridden with the `ADRL_BINARY_ROOT` environment variable).  If the
files are not there, it will use any directories specified on the command-line
with the `-d` flag.

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
  `*_type` column.

* If the value of the column is a String (for new local authorities),
  add a matching `*_type` column.  The columns must be in pairs
  (e.g. "composer_type" and "composer"), and the `*_type` column
  must come first.

* The possible values for the `*_type` fields are: Person, Group,
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

## General notes

The code that handles ingests is primarily in the {Importer} module, with some helper
methods defined in {Parse}, {SRU}, {Proquest}, {LocalAuthority}, and
{ObjectFactoryWriter}.  In the future some or all of these modules should be
extracted into a standalone gem.

The basic ingest flow is as follows:

1. CLI arguments are passed to {Importer::CLI}, which invokes the appropriate
   import submodule: {Importer::CSV}, {Importer::ETD}, {Importer::MODS}, or
   {Importer::Cylinder}.

2. The import submodule parses the provided metadata file(s) and creates a
   normalized hash of attributes (sometimes via {ObjectFactoryWriter}).  This
   hash must be converted to JSON and passed through ActiveJob, so we have to
   ensure that everything is serialized correctly.  Notably, ActiveJob does not
   know how to serialize `RDF::URI` objects, so we instead pass a special hash
   that is later used to generate an `RDF::URI`.  They look like this:

    ```ruby
    { _rdf: "http://rdf.me/please" }
    ```

3. The normalized attributes hash is then passed to the appropriate
   {ObjectFactory} subclass – {AudioRecordingFactory}, {ETDFactory}, etc.  There
   the object is created in Fedora, and associated binaries (PDFs, TIFF images,
   WAV files) are processed.

## Object types

Cylinders, ETDs, MODS records and CSV records can all be ingested by
`bin/ingest`, but the way it ingests each is slightly different.

### How ETDs are ingested

ETDs (Electronic Dissertations and Theses) are provided to us as
zipfiles by ProQuest.  In each zipfile (named something like
`etdadmin_upload_56186.zip`) there is the PDF of the dissertation or
thesis, an XML file containing the metadata for the ETD, and
(optionally) any supplemental files the author provided to ProQuest.

We don’t ingest an ETD using the ProQuest metadata directly; instead
we use the XML file to find the ETD with the SRU API; then ingest it using the
MARC metadata from Alma.

What happens when you run `bin/ingest -f etd /path/to/etds/etdadmin_upload*`, then, is this:

1. The zipfiles matched by `/path/to/etds/etdadmin_upload*` are
   unzipped by {Proquest.extract} into a temporary directory.
   {Proquest.extract} returns a hash with paths to each of the
   elements in the zipfile:

    ```ruby
    {
      xml: '/tmp/etdadmin_upload_56186.zip/NAME_ucsb_0035D_12328_DATA.xml',
      pdf: '/tmp/etdadmin_upload_56186.zip/NAME_ucsb_0035D_12328.pdf',
      supplements: [
        '/tmp/etdadmin_upload_56186.zip/NAME_ucsb_0035D_67/cat.gif'
      ]
    }
    ```


2. Next, `bin/ingest` passes the path to the XML file of each ETD to
   {Importer::ETDParser.parse_file}, which parses the XML and queries
   the SRU API, returning a single string of MARC containing the
   metadata for all the ETDs matched by
   `/path/to/etds/etdadmin_upload*`.

3. The MARC strings are passed (via `StringIO`) to `MARC::XMLReader`,
   then collected in an array.

4. Finally, for each MARC record, `bin/ingest`

     1. creates a new `Traject::Indexer`,
     2. provides it with the ETD configuration file `lib/traject/etd_config.rb`,
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

### How Cylinders are ingested

The ETD and Cylinders ingest processes are similar in that both use
MARC as the metadata format instead of CSV or MODS, but the details
are different enough that `bin/ingest` has separate options for each,
instead of a single `marc` option.

Unlike ETDs, for which the MARC is generated on the fly, currently
ingesting cylinders requires a pre-existing MARCXML file; generated by
querying the SRU API.  Once the metadata file(s) have been generated,
`bin/ingest -f cyl -m /path/to/metadata -d /path/to/data` results in
the following operations:

1. The MARC records from all metadata files given to `-m` are
   collected in an array.
2. For each record, `bin/ingest`

     1. creates a new `Traject::Indexer`,
     2. provides it with the cylinder configuration file
        `lib/traject/audio_config.rb`,
     3. passes it the array of files generated from the paths passed
        to `-d`, then
     4. uses `indexer.map_record` to convert the MARC to a hash and
        passes it to {ObjectFactoryWriter#put}.

3. As with the ETD ingest process, {ObjectFactoryWriter#put} formats
   the MARC metadata for Fedora, then creates the appropriate
   {Importer::Factory} (in this case,
   {Importer::Factory::AudioRecordingFactory}), which creates (or
   updates) the Fedora object.

4. {Importer::Factory::AudioRecordingFactory#attach_files} is slightly
   more complex than the other implementations of `#attach_files`
   since we have separate methods for attaching the original and
   restored audio files (both are in WAV format; the original follows
   the naming schema of <accession number>a.wav, and the restored
   <accession number>b.wav).

### How CSVs are ingested

CSV (comma-separated value) metadata can be used for any object model
(any type of record); currently we are using it for some of our image
records and some collection-level records.

If the CSV file passed to `bin/ingest` is just for a collection-level
record, you don’t need to provide any data, but otherwise the command
is the same for any type of record:

```
bin/ingest -f csv -m /path/to/metadata.csv -d /path/to/data
```

(Both `-m` and `-d` can be passed single files, file globs, or
directories.)

When `bin/ingest` is run on CSV records, what happens is this:

1. Each metadata file is processed separately.  {Importer::CSV.split}
   reads the metadata file and returns its header and body (the first
   row of the CSV, and the rest).  The header describes the values of
   each column of metadata; each row of the CSV is compared to the
   header by {Importer::CSV.csv_attributes} in order to generate a
   hash that looks like this:

    ```ruby
    {
      :type => "Collection",
      :accession_number => ["PA Mss 1"],
      :title => ["Verne Todd collection"],
      :alternative => ["Todd (Verne) collection"],
      :description => ["Vogue picture records from the Verne Todd collection. Acquired in 1995, the Todd Collection includes over 200,000 sound recordings, including classical, popular jazz and ethnic disc recordings as well as nearly 6000 cylinders, primarily commercial Edison and Columbia cylinders."],
      :lc_subject => [#<RDF::URI:0x3fea148ea164 URI:http://id.loc.gov/authorities/subjects/sh90003868>],
      :language => [#<RDF::URI:0x3fea148e7e78 URI:http://id.loc.gov/vocabulary/iso639-2/eng>],
      :form_of_work => [#<RDF::URI:0x3fea148e7c48 URI:http://vocab.getty.edu/aat/300265790>],
      :work_type => [#<RDF::URI:0x3fea148e793c URI:http://id.loc.gov/vocabulary/resourceTypes/col>,
                     #<RDF::URI:0x3fea148e72c0 URI:http://id.loc.gov/vocabulary/resourceTypes/img>],
      :note => [
        { :type => "original",
          :name => "From the Verne Todd collection, PA Mss 1." }
      ],
      :description_standard => ["local"],
      :issued_attributes => [
        { :start => ["1901"],
          :finish => ["1999"],
          :label => ["20th century"],
          :start_qualifier => ["approximate"],
          :finish_qualifier => ["approximate"] }
     ],
      :sub_location => ["Department of Special Research Collections"],
      :institution => [#<RDF::URI:0x3fea148e60c8 URI:http://id.loc.gov/vocabulary/organizations/cusb>]
    }
    ```

2. For each record, the `:files` field of its attributes hash is
   checked against the files passed to `bin/ingest` with `-d` in order
   to determine which file(s) should be attached to the new record.

3. The attributes hash and the array of files from step 2 are passed
   to {Importer::CSV.import}, which determines the object model from
   the `:type` key on the attributes hash, and creates the appropriate
   {Importer::Factory} (the CSV ingest process does not use
   {ObjectFactoryWriter}—that’s only used during the ETD and Cylinder
   ingests).  Both {Importer::Factory::ImageFactory} and
   {Importer::Factory::CollectionFactory} inherit from
   {Importer::Factory::ObjectFactory}, so the same comments apply as
   above in the section on ETD ingests.

### How MODS records are ingested

MODS (Metadata Object Description Schema) is an XML-based metadata
schema.  The object models currently using it are, like our CSV
records, images and collection-level records (including the ETD
collection-level record).

Like CSV records and cylinders, you can ingest only metadata (`-m`
using the command-line `bin/ingest` script), but with data as well the
command invocation will look like this:

```
bin/ingest -f mods -m /path/to/metadata -d /path/to/data
```

**NB:** Currently the MODS ingest process assumes that the metadata
will be available as one XML file per record.  This can easily be
remedied when necessary by parsing the XML in `bin/ingest` before
passing it to {Importer::MODS.import}.

When the above command is run, the following occurs:

1. Each record to be ingested is matched with the correct files
   (passed with the `-d` flag) by comparing the filenames; the name of
   the XML file for a record and the names of the associated data
   files will each share a substring.

2. Each set of metadata and data paths is passed to
   {Importer::MODS.import}.  That method calls an instance of
   {Importer::MODS::Parser} on the metadata path, determining the
   object model and preparing the metadata for Fedora.  Then, as in
   the CSV ingest, an instance of the appropriate {Importer::Factory}
   is created and `#run` to create the record in Fedora.
