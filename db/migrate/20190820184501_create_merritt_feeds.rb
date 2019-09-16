class CreateMerrittFeeds < ActiveRecord::Migration[5.1]
  def change
    create_table :merritt_feeds do |t|
      t.integer   :page, null: false
      t.datetime  :last_modified, index: true, null: false
      t.timestamps
    end
  end
end
