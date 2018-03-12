# IIIF
This application uses [IIIF](http://iiif.io/) (international image interoperability framework)
standards to interact with images. 

## Internal RIIIF engine
For local development, use the internal [RIIIF](https://github.com/curationexperts/riiif) system. See 
`config/initializers/riiif_initializer.rb` for details.

## External IIIF server
In production, to improve image performance, specify an external IIIF server
in `config/environments/production.rb`, like this:

```ruby
  config.external_iiif_url = "http://iiif.library.ucsb.edu:8080/Cantaloupe-3.4.1/iiif/2"
```

Because openseadragon (the pan/zoom widget) gets its urls from solr, once the
value of `Rails.configuration.external_iiif_url` changes, objects must be
re-indexed to use the new URL. 

The external system we have installed is [Cantaloupe](https://medusa-project.github.io/cantaloupe/), but any IIIF
compatible image server could be substituted. 

## Example
```ruby
> image = Image.last
> Rails.configuration.external_iiif_url = nil
> image.to_solr["file_set_iiif_manifest_ssm"]
 => ["/image-service/08612n52b%2Ffiles%2F5d3ddbd3-d1d6-4d9f-bea0-8542d71c2d53/info.json", "/image-service/vt150j246%2Ffiles%2F68ca4f9c-8936-4780-83da-c3c32a95d6b5/info.json"]
> Rails.configuration.external_iiif_url = "http://iiif.library.ucsb.edu:8080/Cantaloupe-3.4.1/iiif/2"
> image.to_solr["file_set_iiif_manifest_ssm"]
 => ["http://iiif.library.ucsb.edu:8080/Cantaloupe-3.4.1/iiif/208612n52b%2Ffiles%2F5d3ddbd3-d1d6-4d9f-bea0-8542d71c2d53/info.json", "http://iiif.library.ucsb.edu:8080/Cantaloupe-3.4.1/iiif/2vt150j246%2Ffiles%2F68ca4f9c-8936-4780-83da-c3c32a95d6b5/info.json"]
```
