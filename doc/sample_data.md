# Sample data

This data is intended for development and testing purposes. It contains collections, images in csv and mods formats, maps, cylinders, and ETDs that are members of the collections. It is accessible within the app via `sample_data` or `ENV['SAMPLE_DATA_DIR']`.

## Collections:

| Type | Title | Identifier |
| --- | --- | --- |
| Cylinder | Cylinder Audio Archive | ark:/48907/f3th8mmz |
| ETD | UCSB electronic theses and dissertations |  ark:/48907/f3348hkz |
| Image (csv) | University Archives photographs collection | ark:/48907/f3hd7vdz |
| Image (mods) | Santa Barbara picture postcards collection | ark:/48907/f3k35rv9 |
| Map | Maps of Santa Barbara County | ark:/99999/fk4n30571j |

## Objects

| Type | Title | Identifier |
| --- | --- | --- |
| Cylinder | Samson et Dalila. | Cylinder 4514 |
| ETD | Another City is Possible: Mujeres de Maiz | ark:/48907/f3zw1j3s |
| Image (csv) | Product page for Keating bicycles | ark:/48907/f3s182j9 |
| Image (mods) | Arlington Hotel, Santa Barbara earthquake | ark:/48907/f3t43r9w |
| Map (index) | Index Map | ark:/48907/f32j6ffd |
| Map (component)| Rio Xixé | ark:/48907/f3445q2w |
| Map (component) | Serra Cubencranquém | ark:/48907/f30g3nq1 |


## Ingesting the data (_see doc/ingest.md for complete information about importing_)

1. Use the cmdline importers to import all of the collections. Run them in the root directory (`/opt/alexandria/current`, on our servers) and supply the correct RAILS_ENV, sample data directory and format types in the commands.

  - `RAILS_ENV=production bin/ingest -f csv -m $SAMPLE_DATA_DIR/cylinders/cylinder_collection.csv`

  - `RAILS_ENV=production bin/ingest -f mods -m $SAMPLE_DATA_DIR/etds/etds-collection.xml`

  - `RAILS_ENV=production bin/ingest -f csv -m $SAMPLE_DATA_DIR/images-csv/image-collection.csv`

  - `RAILS_ENV=production bin/ingest -f mods -m $SAMPLE_DATA_DIR/images-mods/mods_collection.xml`

  - `RAILS_ENV=production bin/ingest -f csv -m $SAMPLE_DATA_DIR/maps/map_collection.csv`

2. Use the importers to ingest each format. In some cases it's necessary to update the collection's solr index afterwards.

  - Cylinders

    - `RAILS_ENV=production bin/ingest -f cyl -m $SAMPLE_DATA_DIR/cylinder.xml -d $SAMPLE_DATA_DIR/cylinders`

    - `rails_console:> cylinder_collection.update_index`

  - ETDs (_The ETD importer requires a zip file._)

    - `RAILS_ENV=production bin/ingest -f etd -d $SAMPLE_DATA_DIR/etds/Gonzalez_ucsb_0035D_12464.zip`

    - `rails_console:> etd_collection.update_index`

  - Images (csv)

    - `RAILS_ENV=production bin/ingest -f csv -m $SAMPLE_DATA_DIR/images-csv/image.csv -d $SAMPLE_DATA_DIR/images-csv`

  - Images (mods) (_The MODS importer only requires a directory as its metadata argument._)

    - `RAILS_ENV=production bin/ingest -f mods -m $SAMPLE_DATA_DIR/images-mods/ -d $SAMPLE_DATA_DIR/images-mods`

 - Maps

    - `RAILS_ENV=production bin/ingest -f csv -m $SAMPLE_DATA_DIR/maps/map.csv -d $SAMPLE_DATA_DIR/maps`

**NOTE about the CSV importer**

{Importer::CSV} uses the `files` column from the CSV to determine where the
associated binaries are located.  First it checks if the files specified exist
in the directory specified as `binary_source_root` in `application.yml` (which
can be overridden with the `ADRL_BINARY_ROOT` environment variable).  If the
files are not there, it will use any directories specified on the command-line
with the `-d` flag.
