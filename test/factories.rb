FactoryGirl.define do
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
end
