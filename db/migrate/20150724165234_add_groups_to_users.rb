class AddGroupsToUsers < ActiveRecord::Migration
  def change
    add_column :users, :group_list, :text
    add_column :users, :groups_list_expires_at, :datetime
    drop_table :roles_users
    drop_table :roles
  end
end
