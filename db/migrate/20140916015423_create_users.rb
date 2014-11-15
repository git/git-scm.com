class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :screen_name
      t.string :github_id
      t.string :remember_token
      t.timestamps
    end
    add_index :users, :github_id
    add_index :users, :remember_token
  end
end
