require 'rails_helper'
require 'object_factory_writer'

describe ObjectFactoryWriter do
  let(:writer) { described_class.new({}) }

  describe "#put" do
    let(:traject_context) { double(output_hash: traject_hash) }

    let(:traject_hash) do
      { 'author' => ['Valerie'],
        'title' => ["How to be awesome"],
        'created_start' => ['2013'],
        'filename' => ['My_stuff.pdf'],
        'isbn' => ['1234'],
        'extent' => ['1 online resource (147 pages)'],
        'identifier' => ['ark:/99999/fk4zp46p1g'],
        'id' => ['fk/4z/p4/6p/fk4zp46p1g'],
        'names' => ['Paul', 'Frodo Baggins', 'Hector'],
        'relators' => ['degree supervisor.', 'adventurer', 'Degree suPERvisor'] }
    end

    it "calls the etd factory" do
      expect(writer).to receive(:build_object).with(
        author: ['Valerie'],
        isbn: ['1234'],
        identifier: ['ark:/99999/fk4zp46p1g'],
        id: 'fk/4z/p4/6p/fk4zp46p1g',
        files: ['My_stuff.pdf'], created_attributes: [{ start: ['2013'] }],
        admin_policy_id: AdminPolicy::ADMIN_USER_POLICY_ID,
        collection: { id: "etds", title: "Electronic Theses and Dissertations", accession_number: ['etds'] },
        extent: ['1 online resource (147 pages)'],
        title: 'How to be awesome',
        degree_supervisor: ['Paul', 'Hector']
      )

      writer.put(traject_context)
    end

  end
end
