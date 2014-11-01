# encoding: UTF-8
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
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20140916015423) do

  create_table "books", force: true do |t|
    t.string   "code"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "books", ["code"], name: "index_books_on_code"

  create_table "chapters", force: true do |t|
    t.string   "title"
    t.integer  "book_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "number"
    t.string   "sha"
  end

  add_index "chapters", ["book_id"], name: "index_chapters_on_book_id"

  create_table "doc_files", force: true do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "doc_files", ["name"], name: "index_doc_files_on_name"

  create_table "doc_versions", force: true do |t|
    t.integer  "version_id"
    t.integer  "doc_id"
    t.integer  "doc_file_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "docs", force: true do |t|
    t.string   "blob_sha"
    t.text     "plain"
    t.text     "html"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "docs", ["blob_sha"], name: "index_docs_on_blob_sha"

  create_table "downloads", force: true do |t|
    t.string   "url"
    t.string   "filename"
    t.string   "platform"
    t.integer  "version_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "release_date"
  end

  create_table "related_items", force: true do |t|
    t.string   "name"
    t.string   "content_type"
    t.string   "content_url"
    t.string   "related_type"
    t.string   "related_id"
    t.integer  "score"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "sections", force: true do |t|
    t.string   "title"
    t.string   "slug"
    t.text     "plain"
    t.text     "html"
    t.integer  "chapter_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "source_url"
    t.integer  "number"
  end

  add_index "sections", ["chapter_id"], name: "index_sections_on_chapter_id"
  add_index "sections", ["slug"], name: "index_sections_on_slug"

  create_table "users", force: true do |t|
    t.string   "screen_name"
    t.string   "github_id"
    t.string   "remember_token"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "users", ["github_id"], name: "index_users_on_github_id"
  add_index "users", ["remember_token"], name: "index_users_on_remember_token"

  create_table "versions", force: true do |t|
    t.string   "name"
    t.string   "commit_sha"
    t.string   "tree_sha"
    t.datetime "committed"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.float    "vorder"
  end

  add_index "versions", ["name"], name: "index_versions_on_name"

end
