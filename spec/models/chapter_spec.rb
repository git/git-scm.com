# frozen_string_literal: true

require "rails_helper"

RSpec.describe Chapter, type: :model do

  let(:book) { Fabricate(:book) }
  let(:chapter) { Fabricate(:chapter, book: book) }

  it { should belong_to :book }
  it { should have_many :sections }


  it "should have title" do
    expect(chapter.title).to eql("Git")
  end

  it "should have book" do
    expect(chapter.book).to eql(book)
  end

  it "should have sections" do
    sections = chapter.sections

    expect(sections.any?).to be_truthy
    expect(sections.count).to eql(3)
  end

end
