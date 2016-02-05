# Create local authorities with data imported from a CSV file
module Importer
  class LocalAuthorityImporter

    attr_accessor :input_file

    def initialize(file)
      AdminPolicy.ensure_admin_policy_exists
      @input_file = file
    end

    def run
      puts "Importing local authorities from: #{input_file}"

      CSV.foreach(input_file, headers: true, header_converters: [:downcase, :symbol]) do |row|
        create_or_update_fedora_object(row)
      end
    end

    # TODO: Is ID a required field?  If no id, error? or allow fedora to create id?
    def create_or_update_fedora_object(attributes)
      klass = model(attributes)
      attrs = transform_attributes(attributes, klass)

      object = find(klass, attrs[:id])
      if object
        update(object, attrs)
        log_updated(object)
      else
        object = klass.create(attrs)
        log_created(object)
      end
    end

    def model(attributes)
      model = Array(attributes[:type]).first
      raise '"type" column cannot be blank' if model.blank?
      model.capitalize.constantize
    end

    def transform_attributes(attrs, model)
      attributes = { id: attrs[:id] }

      list_of_names = Array(attrs).flat_map {|a| a.first == :name ? a - [a[0]] : nil }.compact
      names = if model.attribute_names.include?('foaf_name')
                { foaf_name:  list_of_names.first }
              else
                { label: list_of_names }
              end
      attributes.merge(names)
    end

    def find(klass, id)
      klass.find(id) if klass.exists?(id)
    rescue => e
      puts "ERROR trying to find object with id #{id}"
      raise e
    end

    def update(object, attrs)
      object.attributes = attrs.except(:id)
      object.save!
    end

    def log_created(obj)
      puts "   Created #{obj.class.to_s.downcase}: #{obj.id} #{obj.rdf_label}"
    end

    def log_updated(obj)
      puts "   Updated #{obj.class.to_s.downcase}: #{obj.id} #{obj.rdf_label}"
    end

  end
end
