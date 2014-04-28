class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :github_user_name
      t.string :remember_token
      t.timestamps
    end
    add_index :users, :github_user_name
  end
end
