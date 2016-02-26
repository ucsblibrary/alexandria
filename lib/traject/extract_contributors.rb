module ExtractContributors

  # For wax cylinder recordings, we want to capture
  # contributor data from fields 100, 110, 700, and 710
  # of the MARC record.
  TAGS = ['100', '110', '700', '710']

  # For each field, which subfields do we use to construct the
  # contributor's name?
  SUBFIELD_MAP = { '100' => ['a', 'c', 'd', 'q'],
                   '110' => ['a', 'b'],
                   '700' => ['a', 'b', 'c', 'd', 'q'],
                   '710' => ['a', 'b'] }

  # Decide which type of local authority to create, based on
  # the field indicators
  NAME_TYPE_MAP = { '0' => 'person',
                    '1' => 'person',
                    '3' => 'group' }

  # Find the attribute name based on what's in subfield 4 or e.
  ROLE_MAP = { 'arr' => :arranger,
               'aut' => :author,
               'cmp' => :composer,
               'cnd' => :conductor,
               'itr' => :instrumentalist,
               'lbt' => :librettist,
               'lyr' => :lyricist,
               'prf' => :performer,
               'sng' => :singer,
               'spk' => :speaker,
               'voc' => :singer,
               'arranger of music' => :arranger,
               'author' => :author,
               'composer' => :composer,
               'conductor' => :conductor,
               'instrumentalist' => :instrumentalist,
               'librettist' => :librettist,
               'lyricist' => :lyricist,
               'performer' => :performer,
               'singer' => :singer,
               'speaker' => :speaker }


  def extract_contributors
    lambda do |record, accumulator|
      fields = record.fields.select{|f| TAGS.include?(f.tag) }

      contributors = Hash.new
      fields.each do |field|
        keys = roles_for(field)
        value = data_for(field)
        keys.each do |key|
          contributors[key] ||= []
          contributors[key] << value
        end
      end

      accumulator << contributors
    end
  end

  def roles_for(field)
    sub_4 = field.subfields.select {|s| s.code == '4'.freeze }
    sub_e = field.subfields.select {|s| s.code == 'e'.freeze }
    roles = sub_4 + sub_e

    if roles.blank?
      [:performer]
    else
      roles.map {|r| ROLE_MAP.fetch(r.value.strip.downcase) }
    end
  end

  def data_for(field)
    strings = field.subfields.inject([]) do |values, subfield|
      v = subfield.value.strip
      if !v.blank? && relevant_subfield?(field.tag, subfield)
        values << v
      end
      values
    end

    { type: model_name_for(field), name: strings.join(' ') }
  end

  # Only use the text from certain subfields
  def relevant_subfield?(field_tag, subfield)
    SUBFIELD_MAP[field_tag].include?(subfield.code)
  end

  def model_name_for(field)
    if field.tag == '110'.freeze || field.tag == '710'.freeze
      'organization'.freeze
    else
      NAME_TYPE_MAP.fetch(field.indicator1, 'agent'.freeze)
    end
  end

end
