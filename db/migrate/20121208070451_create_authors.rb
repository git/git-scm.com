class CreateAuthors < ActiveRecord::Migration
  def change
    create_table :authors do |t|
      t.string :name
      t.integer :commit_count

      t.timestamps
    end
    add_index :authors, [:name]
    add_index :authors, [:commit_count]
  end
end
