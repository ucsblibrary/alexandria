class CreateMerrittFeeds < ActiveRecord::Migration[5.1]
  def change
    create_table :merritt_feeds do |t|
      t.integer  :last_parsed_page, index: true, null: false
      t.datetime :last_modified, index: true
      t.timestamps
    end
  end
end
