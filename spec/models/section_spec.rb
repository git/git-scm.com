require 'spec_helper'

describe Section do

  let(:book) { Fabricate(:book) }
  let(:chapter) { Fabricate(:chapter, book: book) }
  let(:section) { Fabricate(:section, chapter: chapter) }


  it { should belong_to :chapter }
  it { should have_one(:book).through(:chapter) }


  it "should have title" do
    section.title.should == "Git Section"
  end

  it "should have chapter" do
    section.chapter.should == chapter
  end

  it "should have book" do
    section.book.should == book
  end

end
