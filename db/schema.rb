# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2019_01_31_210305) do

  create_table "books", force: :cascade do |t|
    t.string "code"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "edition", default: 1
    t.string "ebook_pdf"
    t.string "ebook_epub"
    t.string "ebook_mobi"
    t.string "ebook_html"
    t.boolean "processed"
    t.integer "percent_complete"
    t.string "language"
    t.index ["code"], name: "index_books_on_code"
  end

  create_table "chapters", force: :cascade do |t|
    t.string "title"
    t.integer "book_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "number"
    t.string "sha"
    t.string "chapter_type", default: "chapter"
    t.string "chapter_number"
    t.index ["book_id"], name: "index_chapters_on_book_id"
  end

  create_table "doc_files", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["name"], name: "index_doc_files_on_name"
  end

  create_table "doc_versions", force: :cascade do |t|
    t.integer "version_id"
    t.integer "doc_id"
    t.integer "doc_file_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "language", default: "en"
  end

  create_table "docs", force: :cascade do |t|
    t.string "blob_sha"
    t.text "plain"
    t.text "html"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["blob_sha"], name: "index_docs_on_blob_sha"
  end

  create_table "downloads", force: :cascade do |t|
    t.string "url"
    t.string "filename"
    t.string "platform"
    t.integer "version_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "release_date"
  end

  create_table "sections", force: :cascade do |t|
    t.string "title"
    t.string "slug"
    t.text "plain"
    t.text "html"
    t.integer "chapter_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "source_url"
    t.integer "number"
    t.index ["chapter_id"], name: "index_sections_on_chapter_id"
    t.index ["slug"], name: "index_sections_on_slug"
  end

  create_table "versions", force: :cascade do |t|
    t.string "name"
    t.string "commit_sha"
    t.string "tree_sha"
    t.datetime "committed"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.float "vorder"
    t.index ["name"], name: "index_versions_on_name"
  end

  create_table "xrefs", force: :cascade do |t|
    t.integer "section_id"
    t.integer "book_id"
    t.string "name"
  end

end
