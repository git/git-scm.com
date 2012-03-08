# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20120308160013) do

  create_table "doc_files", :force => true do |t|
    t.string   "name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "doc_files", ["name"], :name => "index_doc_files_on_name"

  create_table "doc_versions", :force => true do |t|
    t.integer  "version_id"
    t.integer  "doc_id"
    t.integer  "doc_file_id"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  create_table "docs", :force => true do |t|
    t.text     "blob_sha"
    t.text     "plain"
    t.text     "html"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "docs", ["blob_sha"], :name => "index_docs_on_blob_sha"

  create_table "versions", :force => true do |t|
    t.string   "name"
    t.string   "commit_sha"
    t.string   "tree_sha"
    t.datetime "committed"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  add_index "versions", ["name"], :name => "index_versions_on_name"

end
