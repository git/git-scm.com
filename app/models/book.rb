# frozen_string_literal: true

# t.string      :code
# t.timestamps
class Book < ApplicationRecord
  has_many :chapters, dependent: :delete_all
  has_many :sections, through: :chapters
  has_many :xrefs, dependent: :delete_all

  @@all_books = {
    "az" => "progit2-aze/progit2",
    "be" => "progit/progit2-be",
    "bg" => "progit/progit2-bg",
    "cs" => "progit-cs/progit2-cs",
    "de" => "progit/progit2-de",
    "en" => "progit/progit2",
    "es" => "progit/progit2-es",
    "fr" => "progit/progit2-fr",
    "gr" => "progit2-gr/progit2",
    "id" => "progit/progit2-id",
    "it" => "progit/progit2-it",
    "ja" => "progit/progit2-ja",
    "ko" => "progit/progit2-ko",
    "mk" => "progit2-mk/progit2",
    "nl" => "progit/progit2-nl",
    "pl" => "progit2-pl/progit2-pl",
    "pt-br" => "progit/progit2-pt-br",
    "pt-pt" => "progit2-pt-pt/progit2",
    "ru" => "progit/progit2-ru",
    "sl" => "progit/progit2-sl",
    "sr" => "progit/progit2-sr",
    "tl" => "progit2-tl/progit2",
    "tr" => "progit/progit2-tr",
    "sv" => "progit2-sv/progit2",
    "uk" => "progit/progit2-uk",
    "uz" => "progit/progit2-uz",
    "zh" => "progit/progit2-zh",
    "zh-tw" => "progit/progit2-zh-tw",
    "fa" => "progit2-fa/progit2"
  }

  def self.all_books
    @@all_books
  end

  def edition?(number)
    Book.where(edition: number, code: code).count > 0
  end
end
