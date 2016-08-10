# "Local Membership" in a Collection

## Background &amp; description of the problem

Alexandria is based on the `curation_concerns` gem, which depends on several underlying gems from Project Hydra.  The way that collection membership is currently implemented in the hydra gems has a performance problem.  The problem manifests when you try to add records to a collection.  The first few records can be added in a reasonable amount of time, but as the collection grows, it takes longer and longer to add a new member to the collection.

In the specific case of the "Wax Cylinders" collection, we need to add more than 10k records to the collection, but we had issues with timeout errors, and importing batches of cylinders was taking days.

Adding records to `collection.members` instead of `collection.ordered_members` will improve the performance quite a bit, but even that improvement isn&apos;t enough for a collection the size of "Wax Cylinders".

We plan to investigate the performance problem further, and hopefully it can be fixed in the underlying gems, but in the meantime, we have implemented a work-around solution called "Local Membership".  This document describes how local membership works, and how it is different from standard hydra collection membership.

In the future, if the performance problem is fixed in `curation_concerns` or one of the underlying gems, we can remove the `local_collection_id` property and all the code associated with the "Local Membership" work-around, and go back to using the standard hydra collection membership.

See these email threads on the hydra-tech mailing list for more info about the performance problem:

* [Adding records to collection takes longer and longer](https://groups.google.com/forum/#!topic/hydra-tech/ps55N-gkgLk)
* [infinispan errors and adding large amounts to Object.members](https://groups.google.com/forum/#!topic/hydra-tech/kA59iIOYqg4)
* [Objects With Many Links to Repository Objects](https://groups.google.com/forum/#!topic/hydra-tech/W7tdxUJzJdc)

**Important Note:** Our goal is to keep using the old hydra-style membership for existing records, and only use the new "Local Membership" style for wax cylinder records or other collections that are large enough to have performance problems.

For more info about solutions and work-arounds, see:

* [Reversing Collection Membership (Duraspace wiki)](https://wiki.duraspace.org/display/hydra/Reversing+Collection+Membership)
* [Reversing Collection Membership (hydra-tech mailing list)](https://groups.google.com/forum/#!topic/hydra-tech/7_2jSVL8CNk)

## How is the UI different?

You shouldn&apos;t notice any difference in the UI.  All the collection members should behave the same way in the UI, whether they are members of a collection using the old hydra-style membership or whether they use the new local membership.  If you see 2 different members of a collection in the UI, their behavior for faceting, searching, sorting and browsing should be identical.  From the point-of-view of the end user, there is no way to tell which type of membership binds a record to a collection.

## How is the code different?

### Differences in the models

We tried to leave the existing hydra-style collection &amp; membership code intact as much as possible, so that in the future when the hydra community comes up with a permanent fix for the problem, we will be able to migrate to the new solution.  The more we change the code, the harder it will be to get back in line with hydra community standards.

There are no changes to the Collection model itself.  All existing collections, including "Wax Cylinders" will stay the same as they were before.

For the models that represent an intellectual work, such as AudioRecording, Image, or ETD, there is a new property called `local_collection_id` which can be used to store the IDs for the collection(s) that the work belongs to.  If you use the `local_collection_id` property to store the collection IDs, that is what we call "Local Membership" in the collection.

The main difference between "Local Membership" and the standard hydra membership is how the membership is stored in fedora.  The old style of membership uses container relationships defined by `Hydra::PCDM::PcdmBehavior` and `Hydra::PCDM::CollectionBehavior`.  The new style of membership doesn&apos;t create any containers or proxy objects.  It just uses the `local_collection_id` property to store the collection ID directly on the collection member.

The name "Local Membership" was chosen because the collection membership is stored in the property called `local_collection_id`, and that `local_collection_id` property is stored directly on the object that is a member of the collection, instead of on a proxy object.

### How the models are indexed in Solr

Both the old-style members and the new-style members are indexed identically in solr.  In the solr index, we don&apos;t care which style of membership the record has, we only care that it is a member of the collection somehow.  So, if you are looking at the solr document for a collection, the `member_ids_ssim` field will have both old-style and new-style members.  

Similarly, if you view the solr document for an AudioRecording record, the `collection_ssim` and `collection_label_ssim` fields will have the collections that this record belongs to, no matter which style of membership was used to add the record to the collection.

This is why all the records behave the same way in the UI; Even though they have different relationships in fedora, the solr index is the same.

### Adding records to a collection

The normal `curation_concerns` way to add records to a collection is to add the record to `collection.members` or `collection.ordered_members`.  This is the old hydra style of membership:

```ruby
collection.members << audio_recording
collection.members << image
collection.save!

# Re-index records to add the collection label in their solr index:
audio_recording.update_index
image.update_index
```

The new way to add records to a collection using the "Local Membership" work-around:

```ruby
audio_recording.local_collection_id += [collection.id]
audio_recording.save!

image.local_collection_id += [collection.id]
image.save!

# Re-index the collection to add the members to its solr index:
collection.update_index
```

**Note:** It&apos;s OK for a record to belong to the same collection using both the old- and new-style membership.  So, for example, if you run the importer for a cylinder record that already belongs to the cylinders collection using the old style of membership, the importer will add it as a new-style member, and it will be a member of the same collection twice.  You don&apos;t need to worry about that scenario.  The code should handle it gracefully.

## Migrating existing data

#### For records that already belong to a collection

Because the new-style membership and the old-style membership look the same to the end user, they can live peacefully side-by-side.  If you have existing records that already belong to a collection using the old hydra-style membership, you can just leave them as-is.  You don&apos;t need to migrate them to the new style of membership unless you are having perfomance problems with that specific collection.

#### For existing cylinder records (if they don&apos;t belong to the collection yet)

If you have existing cylinder records that don&apos;t belong to any collection, you can use this script to add them to the cylinders collection.  (The script will add all existing AudioRecording records to the cylinder collection, so you should only run it if you haven&apos;t yet imported non-cylinder audio records, such as CSDI records.)  If you don&apos;t have any collectionless cylinders in your production app, you won&apos;t need this script.

You should be able to run it like this:

```bash
RAILS_ENV=production nohup ruby bin/add_cylinders_to_collection.rb 2>&1 > cylinders.log &
```

## Importing new records

#### For new cylinder records:

The cylinders importer will automatically add all newly-imported cylinder records to the cylinders collection, so you don&apos;t have to do anything else.

#### For other new records:

So far only the cylinders importer uses the new style of collection membership.  The other importers use the standard hydra-style membership.  If some collections have performance problems in the future, we can change the other importers at that time.

## Caveats

* This "Local Membership" work-around only works for unordered members of a collection.  You cannot store ordered collection members this way.

* If you run `ActiveFedora::Base.reindex_everything`, you will need to run it **twice in a row** because `app/indexers/collection_indexer.rb` uses a solr query to add the members to the collection&apos;s solr document.  Similarly, if you intend to reindex an individual collection record, you should make sure that the solr documents for all the members are up-to-date first.

* There is currently no association method to query a Collection object and find its members (see the example code below).  In the future, if we have a need for such a method, we would need to use a solr query to find the members with the new style of membership.

* Be careful when using `active-fedora` association methods.  They might not give you the results you need.  Consider this example:

```ruby
# An image that belongs to 2 collections:

coll_1 = Collection.new(id: 'collection_1', title: ['Collection 1'])
coll_1.save!

coll_2 = Collection.new(id: 'collection_2', title: ['Collection 2'])
coll_2.save!

image = Image.new(id: 'image_aaa', title: ['Image AAA'])
image.save!

# The image belongs to Collection 1 using the old hydra-style membership.
coll_1.members << image
coll_1.save!

# The image belongs to Collection 2 using the new "Local Membership".
image.local_collection_id = [coll_2.id]
image.save!

# Reload objects from fedora to make sure we are working with persisted state, not in-memory state.
image.reload
coll_1.reload
coll_2.reload

# To query the image object about which collections it belongs to, you need to call both in_collection_ids and local_collection_ids methods.
image.in_collection_ids   # => ["collection_1"]
image.local_collection_id # => ["collection_2"]

# To query the collection object about which members it contains, you can find the old-style membership using member_ids, but there is currently no association method to find the new-style members.
# Notice that coll_2 returns an empty array for its member_ids, even though image_aaa is a member of that collection.
coll_1.member_ids # => ["image_aaa"]
coll_2.member_ids # => []

```

