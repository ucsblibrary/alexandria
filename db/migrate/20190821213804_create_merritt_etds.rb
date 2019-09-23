class CreateMerrittEtds < ActiveRecord::Migration[5.1]
  def change
    create_table :merritt_etds do |t|
      t.string   :merritt_id, index: true, null: false
      t.datetime  :last_modified, index: true, null: false
      t.timestamps
    end
  end
end
