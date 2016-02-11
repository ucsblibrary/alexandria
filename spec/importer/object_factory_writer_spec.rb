require 'rails_helper'
require 'object_factory_writer'

describe ObjectFactoryWriter do
  let(:writer) { described_class.new({}) }

  describe '#put' do
    let(:traject_context) { double(output_hash: traject_hash) }

    let(:traject_hash) do
      { 'author' => ['Valerie'],
        'title' => ['How to be awesome'],
        'created_start' => ['2013'],
        'filename' => ['My_stuff.pdf'],
        'isbn' => ['1234'],
        'extent' => ['1 online resource (147 pages)'],
        'description' => ['Marine mussels use a mixture of proteins...', 'The performance of strong adhesion...'],
        'identifier' => ['ark:/99999/fk4zp46p1g'],
        'id' => ['fk/4z/p4/6p/fk4zp46p1g'],
        'names' => ['Paul', 'Frodo Baggins', 'Hector'],
        'degree_grantor' => ['University of California, Santa Barbara Mathematics'],
        'place_of_publication' => ['[Santa Barbara, Calif.]'],
        'publisher' => ['University of California, Santa Barbara'],
        'issued' => ['2013'],
        'relators' => ['degree supervisor.', 'adventurer', 'Degree suPERvisor'],
        'system_number' => [nil],
        'dissertation_degree' => [nil],
        'dissertation_institution' => [nil],
        'dissertation_year' => [nil],
        'fulltext_link' => [nil],
        'fulltext_link' => [nil],
        'work_type' => [RDF::URI('http://id.loc.gov/vocabulary/resourceTypes/txt')]
      }
    end

    it 'calls the etd factory' do
      expect(writer).to receive(:build_object).with(
        {
          author: ['Valerie'],
          isbn: ['1234'],
          identifier: ['ark:/99999/fk4zp46p1g'],
          id: 'fk/4z/p4/6p/fk4zp46p1g',
          files: ['My_stuff.pdf'], created_attributes: [{ start: ['2013'] }],
          collection: { id: 'etds', title: ['Electronic Theses and Dissertations'], accession_number: ['etds'] },
          extent: ['1 online resource (147 pages)'],
          description: ['Marine mussels use a mixture of proteins...', 'The performance of strong adhesion...'],
          title: ['How to be awesome'],
          degree_grantor: ['University of California, Santa Barbara Mathematics'],
          place_of_publication: ['[Santa Barbara, Calif.]'],
          publisher: ['University of California, Santa Barbara'],
          issued: ['2013'],
          degree_supervisor: %w(Paul Hector),
          system_number: [],
          language: [],
          dissertation_degree: [],
          dissertation_institution: [],
          dissertation_year: [],
          fulltext_link: [],
          work_type: [RDF::URI('http://id.loc.gov/vocabulary/resourceTypes/txt')]
        }.with_indifferent_access
      )

      writer.put(traject_context)
    end

    context 'when fields are missing' do
      let(:traject_hash) do
        { 'identifier' => ['ark:/99999/fk4zp46p1g'],
          'id' => ['fk/4z/p4/6p/fk4zp46p1g'],
          'author' => [nil],
          'filename' => [nil],
          'isbn' => [nil],
          'extent' => [nil],
          'description' => [nil],
          'title' => [nil],
          'degree_grantor' => [nil],
          'place_of_publication' => [nil],
          'publisher' => [nil],
          'issued' => [nil],
          'degree_supervisor' => [nil],
          'system_number' => [nil],
          'dissertation_degree' => [nil],
          'dissertation_institution' => [nil],
          'dissertation_year' => [nil],
        }
      end

      it 'overwrites with blank' do
        expect(writer).to receive(:build_object).with(
          {
            author: [],
            isbn: [],
            identifier: ['ark:/99999/fk4zp46p1g'],
            id: 'fk/4z/p4/6p/fk4zp46p1g',
            files: [], created_attributes: [{ 'start' => [] }],
            collection: { id: 'etds', title: ['Electronic Theses and Dissertations'], accession_number: ['etds'] },
            extent: [],
            description: [],
            title: [],
            degree_grantor: [],
            place_of_publication: [],
            publisher: [],
            issued: [],
            degree_supervisor: [],
            system_number: [],
            language: [],
            dissertation_degree: [],
            dissertation_institution: [],
            dissertation_year: [],
            fulltext_link: [] }.with_indifferent_access
        )
        writer.put(traject_context)
      end
    end
  end
end
