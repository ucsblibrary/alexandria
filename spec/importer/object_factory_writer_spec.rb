require 'rails_helper'
require 'object_factory_writer'

describe ObjectFactoryWriter do
  let(:writer) { described_class.new({}) }

  describe '#put' do
    let(:traject_context) { double(output_hash: traject_hash) }

    let(:traject_hash) do
      {
        'author' => ['Valerie'],
        'created_start' => ['2013'],
        'degree_grantor' => ['University of California, Santa Barbara Mathematics'],
        'description' => ['Marine mussels use a mixture of proteins...\n\nThe performance of strong adhesion...'],
        'dissertation_degree' => [],
        'dissertation_institution' => [],
        'dissertation_year' => [],
        'extent' => ['1 online resource (147 pages)'],
        'filename' => ['My_stuff.pdf'],
        'fulltext_link' => [],
        'id' => ['fk/4z/p4/6p/fk4zp46p1g'],
        'identifier' => ['ark:/99999/fk4zp46p1g'],
        'isbn' => ['1234'],
        'issued' => ['2013'],
        'names' => ['Paul', 'Frodo Baggins', 'Hector'],
        'place_of_publication' => ['[Santa Barbara, Calif.]'],
        'publisher' => ['University of California, Santa Barbara'],
        'relators' => ['degree supervisor.', 'adventurer', 'Degree suPERvisor'],
        'system_number' => [],
        'title' => ['How to be awesome'],
        'work_type' => [RDF::URI('http://id.loc.gov/vocabulary/resourceTypes/txt')],
      }
    end

    it 'calls the etd factory' do
      expect(writer).to receive(:build_object).with(
        {
          language: [],
          fulltext_link: [],
          author: ['Valerie'],
          degree_grantor: ['University of California, Santa Barbara Mathematics'],
          description: ['Marine mussels use a mixture of proteins...\n\nThe performance of strong adhesion...'],
          dissertation_degree: [],
          dissertation_institution: [],
          dissertation_year: [],
          extent: ['1 online resource (147 pages)'],
          id: 'fk/4z/p4/6p/fk4zp46p1g',
          identifier: ['ark:/99999/fk4zp46p1g'],
          isbn: ['1234'],
          issued: ['2013'],
          place_of_publication: ['[Santa Barbara, Calif.]'],
          publisher: ['University of California, Santa Barbara'],
          system_number: [],
          title: ['How to be awesome'],
          work_type: [RDF::URI('http://id.loc.gov/vocabulary/resourceTypes/txt')],
          degree_supervisor: %w(Paul Hector),
          created_attributes: [{ start: ['2013'] }],
          files: ['My_stuff.pdf']
        }.with_indifferent_access, nil
      )

      writer.put(traject_context.output_hash)
    end
  end
end
