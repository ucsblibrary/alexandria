class CreateMerrittEtds < ActiveRecord::Migration[5.1]
  def change
    create_table :merritt_etds do |t|
      t.integer   :merritt_id, index: true, null: false
      t.string    :title
      t.string    :author
      t.datetime  :published_date
      t.datetime  :updated_date, null: false
      t.timestamps
    end
  end
end
