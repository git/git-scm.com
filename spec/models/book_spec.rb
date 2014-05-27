require 'spec_helper'

describe Book do

  let(:book) { Fabricate(:book) }

  it { should have_many :chapters }
  it { should have_many(:sections).through(:chapters) }

  it "has chapters" do
    book.chapters.any?.should be_true
    book.chapters.count.should == 3
  end

  it "should have 4 chapters" do
    chapter = Fabricate(:chapter, book: book)
    book.chapters.count.should == 4
  end

end
