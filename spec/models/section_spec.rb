require 'rails_helper'

RSpec.describe Section, type: :model do

  let(:book) { Fabricate(:book) }
  let(:chapter) { Fabricate(:chapter, book: book) }
  let(:section) { Fabricate(:section, chapter: chapter) }


  it { should belong_to :chapter }
  it { should have_one(:book).through(:chapter) }


  it "should have title" do
    expect(section.title).to eql("Git Section")
  end

  it "should have chapter" do
    expect(section.chapter).to eql(chapter)
  end

  it "should have book" do
    expect(section.book).to eql(book)
  end

end
