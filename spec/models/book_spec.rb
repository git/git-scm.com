require 'rails_helper'

RSpec.describe Book, type: :model do

  let(:book) { Fabricate(:book) }

  it { should have_many :chapters }
  it { should have_many(:sections).through(:chapters) }

  it "has chapters" do
    expect(book.chapters.any?).to be_truthy
    expect(book.chapters.count).to eql(3)
  end

  it "should have 4 chapters" do
    chapter = Fabricate(:chapter, book: book)
    expect(book.chapters.count).to eql(4)
  end

end
