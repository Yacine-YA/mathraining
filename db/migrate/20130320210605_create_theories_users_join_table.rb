class CreateTheoriesUsersJoinTable < ActiveRecord::Migration
  def change
    create_table :theories_users, :id => false do |t|
      t.references :theory
      t.references :user
    end
    
    add_index :theories_users, :user_id
  end
end
