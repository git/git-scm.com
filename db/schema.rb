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

ActiveRecord::Schema.define(version: 20141027114732) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "books", force: :cascade do |t|
    t.string   "code",             limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "edition",                      default: 1
    t.string   "ebook_pdf"
    t.string   "ebook_epub"
    t.string   "ebook_mobi"
    t.string   "ebook_html"
    t.boolean  "processed"
    t.integer  "percent_complete"
    t.string   "language"
  end

  add_index "books", ["code"], name: "index_books_on_code", using: :btree

  create_table "chapters", force: :cascade do |t|
    t.string   "title",          limit: 255
    t.integer  "book_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "number"
    t.string   "sha",            limit: 255
    t.string   "chapter_type",               default: "chapter"
    t.string   "chapter_number"
  end

  add_index "chapters", ["book_id"], name: "index_chapters_on_book_id", using: :btree

  create_table "doc_files", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "doc_files", ["name"], name: "index_doc_files_on_name", using: :btree

  create_table "doc_versions", force: :cascade do |t|
    t.integer  "version_id"
    t.integer  "doc_id"
    t.integer  "doc_file_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "docs", force: :cascade do |t|
    t.string   "blob_sha",   limit: 255
    t.text     "plain"
    t.text     "html"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "docs", ["blob_sha"], name: "index_docs_on_blob_sha", using: :btree

  create_table "downloads", force: :cascade do |t|
    t.string   "url",          limit: 255
    t.string   "filename",     limit: 255
    t.string   "platform",     limit: 255
    t.integer  "version_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "release_date"
  end

  create_table "related_items", force: :cascade do |t|
    t.string   "name",         limit: 255
    t.string   "content_type", limit: 255
    t.string   "content_url",  limit: 255
    t.string   "related_type", limit: 255
    t.string   "related_id",   limit: 255
    t.integer  "score"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "sections", force: :cascade do |t|
    t.string   "title",      limit: 255
    t.string   "slug",       limit: 255
    t.text     "plain"
    t.text     "html"
    t.integer  "chapter_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "source_url", limit: 255
    t.integer  "number"
  end

  add_index "sections", ["chapter_id"], name: "index_sections_on_chapter_id", using: :btree
  add_index "sections", ["slug"], name: "index_sections_on_slug", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "screen_name",    limit: 255
    t.string   "github_id",      limit: 255
    t.string   "remember_token", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "users", ["github_id"], name: "index_users_on_github_id", using: :btree
  add_index "users", ["remember_token"], name: "index_users_on_remember_token", using: :btree

  create_table "versions", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.string   "commit_sha", limit: 255
    t.string   "tree_sha",   limit: 255
    t.datetime "committed"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.float    "vorder"
  end

  add_index "versions", ["name"], name: "index_versions_on_name", using: :btree

  create_table "xrefs", force: :cascade do |t|
    t.integer "section_id"
    t.integer "book_id"
    t.string  "name"
  end

end
