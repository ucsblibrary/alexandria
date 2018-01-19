# ADRL Migration Protocol

The goal of this migration protocol is to set up a full new system in parallel with the old system, then re-import all the existing objects into the new system. That way there will be no down-time because the old system will still be in place while the new system is being prepared. 

Currently, ARKs and local authority IDs minted by the old system need to be exported from the old system and imported into the new system since that data does not exist in the CSV and MODS files (currently maintained in the [adrl-dm GitHub repository](https://github.library.ucsb.edu/CMS/adrl-dm)) that are used for importing objects. This protocol will need to be updated once master object metadata (for non-harvest objects) is maintained in ADRL itself.

## Simple Migration Protocol

A simple migration is one where all existing production ARKs will be maintained and migrated to the new system, and the master descriptive metadata records are either harvested from another source (e.g., the Library’s ILS) or maintained in the [adrl-dm GitHub repository](https://github.library.ucsb.edu/CMS/adrl-dm).

### Migration Preparation
Prior to beginning migration to a new production system, the following preparation steps must be performed:

1. Make sure that everyone knows that they cannot import or edit any objects in the current production environment until the migration is complete.

2. Check server settings and confirm that the new production system is configured to mint ARKs via sb-adrl EZID (rather than the demo account). 

3. Create a JIRA ticket to document and track the migration process. All exports and migration related documentation (described below) should be attached to that ticket.

4. Export local authorities from the current production environment (produces CSV file with the following fields: type, id, name). 
On the current production environment, run: `RAILS_ENV=production bin/export/export-authorities`

5. Export brief object records from current production environment (produces CSV file with following fields: type, id, accession_number, identifier, title, access_policy). 
On the current production environment, run: `RAILS_ENV=production bin/export/export-identifiers`

6. Document object counts
   1. Run Fedora object count and save the output for later. This is a high level accounting of what is in the system organized by Fedora object type. 
Run: `RAILS_ENV=production bin/rake fedora:count`
   2. Document object count by collection. This is to help with object count verification throughout the migration process. 
   3.   Document object count of the results of a keyword search in Alma for the ARDL ARK shoulder (keyword = ark:/48907). Note if there is a discrepancy between ARDL and Alma because this means that there are items in the queue that have not been ingested. If this is the case then the Alma count should be used for count verification as the migration will trigger an ingest of any queued harvest objects.
   4.   Document object count of any new non-harvest content that is in the queue for ingest. 
   
7. Document the number of identifiers currently owned by the ADRL EZID account (sb-adrl).

8. Document any collection or object ingest sequencing notes. For example, any collection with new objects in the queue should be noted, and those objects ingested last (or post migration), following the successful migration of all existing objects.

### Migration Ingest Process

ARKs and local authority Fedora IDs are both considered persistent identifiers. In order to ensure that duplicate identifiers are not created during the migration process, it is important that the imports into the system be done in the following order, with verification checks completed between each ingest as specified. 

1. Import local authorities (using the CSV file from previous stage). 
On the new production system, run:   `RAILS_ENV=production bin/import/ingest-authorities <csv_file>`

2. Verify that the local authorities have been successfully migrated.
   1. Run `RAILS_ENV=production bin/rake fedora:count` and compare the new object count to the one performed in the preparation step. Check Agent, Person, Group, Organization, and Topic (all other models should have zero objects at this step).
   2. Spot check a few records of each type and make sure that the new records have the correct label and that the local authority Fedora ID matches.
   
3. Import ARKs and IDs for migrating collections and objects (using the CSV file from previous stage). You will receive a warning message that the content files (e.g., binaries) will not be attached, which is expected since the content files are ingested later. Run: `RAILS_ENV=production bin/ingest -f csv -m <path to csv file>`

4. Verify that the ARKs and IDs have been successfully migrated.
   1. Run `RAILS_ENV=production bin/rake fedora:count` and compare to the new object count to the one performed in the preparation step. All models except FileSet should match at this point. If any counts are off, perform a collection by collection check to identify where the problem is.
   2. Spot check a few records from each collection and make sure the ARK, Fedora ID, and accession number matches (the rest of the descriptive metadata will still be empty). 

5. Ensure that the adrl-dm master branch has been updated, and then begin ingest of CSV and MODS records collection-by-collection. Do not ingest any new content at this point. When beginning work on a collection, ingest the collection record first, followed by the object records. (Note that scanned map collection records are stored in a separate directory from the scanned map object records.) Repeat this step, and the next, until all CSV- and MODS-based collections are ingested.

6. Following the ingest of each CSV or MODS based collection, verify that it has been successfully ingested. Do not move on to the next collection until you are sure that the records are correct. 
   1. Compare by collection object count to what was documented at the beginning of the process. 
   2. Spot check a few records and make sure the metadata is correct, especially those that reference an external or local authority (e.g., creators, subjects, genres, etc.). 
   3. Check the ADRL EZID account (sb-adrl) to confirm that no additional ARKs have been created. 

7. Ingest the collection records for harvest-based collections from adrl-dm master branch.

8. Verify that the collection records were successfully ingested.
   1. Spot check the records to make sure the metadata is correct.
   2. Check the ADRL EZID account (sb-adrl) to confirm that no additional ARKs have been created. 

9. Ingest harvest-based collections. (If new ETDs are in the queue, they may also be ingested post-migration.)

10. Verify that each harvest collection has been successfully ingested. Do not move on to the next collection until you are sure that the records are correct. 
    1. Compare collection object counts to what was documented at the beginning of the process. If there was a discrepancy between ADRL and Alma counts at the beginning of the process (because of queued content), confirm against the Alma count. 
    2. Spot check a few records and make sure the metadata is correct, especially those that reference an external or local authority (e.g., creators, subjects, genres, etc.). 
    3. Check the ADRL EZID account (sb-adrl) to confirm that no additional ARKs have been created. 
   
11. (Step may also be completed post-migration.) Ingest any new CSV, MODS, or ETDs objects collection-by-collection. Repeat this step, and the next, until all new CSV and MODS objects are ingested.
    1. If adding records to an existing collection, it is not necessary to re-ingest the collection record. 
    2. If adding a new collection, ingest the collection record first, followed by the object records. (Note that scanned map collection records are stored in a separate directory from the scanned map object records.) 

12. (Step may also be completed post-migration.) Following the ingest of each new batch of CSV or MODS objects, verify that it has been successfully ingested. Do not move on to the next batch until you are sure that the records are correct. 
    1. Compare by collection object count to what was documented at the beginning of the process. 
    2. Spot check a few records and make sure the metadata is correct, especially those that reference an external or local authority (e.g., creators, subjects, genres, etc.). 
    3. Check the ADRL EZID account (sb-adrl) to confirm that the correct number of new ARKs have been minted for the objects and collection records ingested.

## Post Migration 

1. Export brief object records from new production environment (produces CSV file with following fields: type, id, accession_number, identifier, title, access_policy). Check that no demo arks exist in the new production system (demo arks begin with ark:/99999)
Run: `RAILS_ENV=production bin/rake fedora:count`

2. Confirm that ARKs match public ARKs in EZID using the brief object records from previous step and EZID identifier report. Perform any needed EZID updates.

3. Ingest any new content in the queue that you would like to be present before cutting over to the new system, and perform any required verification and quality assurance checks.

4. DNS changes and whatever else is necessary to cut over to the new system.

5. Retire the old system.

## Complex Migration Protocol

Any migration where some subset of production ARKs or local authority Fedora IDs are not being migrated to the new system is considered a complex migration. These types of migrations occur when, for some reason, the ARK or Fedora ID in the current system is considered to “bad.” Some examples of when that might happen include: a “fake” ARK (ark:/99999) was minted because production was connected to the EZID demo account at the time of ingest, an ARK was accidentally deleted from EZID, or two ARKs were minted for the same object. 

Generally, the migration protocol is the same as for the Simple Migration Protocol with several notable exceptions:

* Pre-processing must be done on the exported local authorities and/or brief objects CSVs to remove the “bad” ARKs or Fedora IDs from the CSV prior to ingest into the new system. Depending on the complexity of the problem, it may be necessary to split the export into several CSV files in order to have better control over the migration process.

* Sequencing of imports and object ingests is especially important during complex migrations. Good ARKs and Fedora IDs must be imported into the system before any ingests can be run. New identifiers will be created for any collections, objects, or local identifiers not in the system at the time of ingest. 
   * If a collection contains a mix of good and bad ARKs, be extra careful about sequencing, especially if the collection object has a bad ARK. In that case you would want to ingest the collection record first (which will mint a new ARK), then import the good object ARKs, and finally ingest the full batch of objects (which will add full metadata and mint ARKs for any objects not imported in the previous step).
   
* Collection records must be either imported or ingested into the new production system prior to ingesting any objects from that collection, or you will end up with multiple collections (each containing a subset of collection objects) due to concurrent ingests. 