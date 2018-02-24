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

  create_table "books", force: :cascade do |t|
    t.string   "code"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "edition",          default: 1
    t.string   "ebook_pdf"
    t.string   "ebook_epub"
    t.string   "ebook_mobi"
    t.string   "ebook_html"
    t.boolean  "processed"
    t.integer  "percent_complete"
    t.string   "language"
  end

  add_index "books", ["code"], name: "index_books_on_code"

  create_table "chapters", force: :cascade do |t|
    t.string   "title"
    t.integer  "book_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "number"
    t.string   "sha"
    t.string   "chapter_type",   default: "chapter"
    t.string   "chapter_number"
  end

  add_index "chapters", ["book_id"], name: "index_chapters_on_book_id"

  create_table "doc_files", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "doc_files", ["name"], name: "index_doc_files_on_name"

  create_table "doc_versions", force: :cascade do |t|
    t.integer  "version_id"
    t.integer  "doc_id"
    t.integer  "doc_file_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "docs", force: :cascade do |t|
    t.string   "blob_sha"
    t.text     "plain"
    t.text     "html"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "docs", ["blob_sha"], name: "index_docs_on_blob_sha"

  create_table "downloads", force: :cascade do |t|
    t.string   "url"
    t.string   "filename"
    t.string   "platform"
    t.integer  "version_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "release_date"
  end

  create_table "sections", force: :cascade do |t|
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

  create_table "versions", force: :cascade do |t|
    t.string   "name"
    t.string   "commit_sha"
    t.string   "tree_sha"
    t.datetime "committed"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.float    "vorder"
  end

  add_index "versions", ["name"], name: "index_versions_on_name"

  create_table "xrefs", force: :cascade do |t|
    t.integer "section_id"
    t.integer "book_id"
    t.string  "name"
  end

end
