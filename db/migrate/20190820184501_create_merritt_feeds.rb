class CreateMerrittFeeds < ActiveRecord::Migration[5.1]
  def change
    create_table :merritt_feeds do |t|
      t.string    :repo_url, null: false
      t.integer   :page_num, null: false
      t.datetime  :last_modified, index: true, null: false
      t.string    :work_type, index: true, null: false
      t.timestamps
    end
  end
end
