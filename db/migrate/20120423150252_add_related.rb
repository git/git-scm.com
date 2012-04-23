class AddRelated < ActiveRecord::Migration
  def up
    create_table :related_items do |t|
      t.string  :name
      t.string  :content_type
      t.string  :content_url
      t.string  :related_type
      t.string  :related_id
      t.integer :score
      t.timestamps
    end
  end

  def down
    drop_table :related_items
  end
end
