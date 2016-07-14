require 'rails_helper'
require 'object_factory_writer'

describe ObjectFactoryWriter do
  let(:settings) { {} }
  let(:writer) { described_class.new(settings) }

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
        }.with_indifferent_access, []
      )

      writer.put(traject_context.output_hash)
    end
  end

  describe '#find_files_to_attach' do
    let(:settings) { { files_dirs: files_dirs } }
    let(:attrs) { { filename: ['Cylinder 12783', 'Cylinder 0001'] } }

    subject { writer.find_files_to_attach(attrs) }

    context 'with a single directory' do
      let(:files_dirs) { File.join(fixture_path, 'cylinders') }

      it 'contains the correct files' do
        expect(subject.count).to eq 1 # It's an array of arrays
        expect(subject.first).to contain_exactly(
          File.join(files_dirs, 'cusb-cyl0001a.wav'),
          File.join(files_dirs, 'cusb-cyl0001b.wav')
        )
      end
    end

    context 'with more than one directory' do
      let(:files_dirs) {
        [File.join(fixture_path, 'cylinders'),
         File.join(fixture_path, 'cylinders2')]
      }

      it 'contains the correct files, grouped by cylinder' do
        expect(subject.count).to eq 2

        expect(subject[0]).to contain_exactly(
          File.join(files_dirs.last, 'audio_files', 'cusb-cyl12783a.wav'),
          File.join(files_dirs.last, 'audio_files', 'cusb-cyl12783b.wav')
        )

        expect(subject[1]).to contain_exactly(
          File.join(files_dirs.first, 'cusb-cyl0001a.wav'),
          File.join(files_dirs.first, 'cusb-cyl0001b.wav')
        )
      end
    end
  end

end
