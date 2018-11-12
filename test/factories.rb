# frozen_string_literal: true

FactoryGirl.define do

  sequence :number do |n|
    n
  end

  sequence :slug do |n|
    "title-#{n}"
  end

  sequence :title do |n|
    "Title #{n}"
  end

  sequence :plain do |n|
    "Doc #{n}"
  end

  sequence :version_name do |n|
    "v#{n}.0"
  end

  factory :doc_file do
  end

  factory :doc do
    plain :plain
  end

  factory :doc_version do
    doc_file
    version
    doc
  end

  factory :version do
    name :version_name
  end

  factory :book do
    code "en"
  end

  factory :section do
    chapter
    html "<html></html>"
    number { FactoryGirl.generate(:number) }
    title { FactoryGirl.generate(:title) }
    slug { FactoryGirl.generate(:slug) }
    plain { FactoryGirl.generate(:plain) }
  end

  factory :chapter do
    book
    number { FactoryGirl.generate(:number) }
    title { FactoryGirl.generate(:title) }
  end

end
