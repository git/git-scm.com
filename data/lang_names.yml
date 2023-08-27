# frozen_string_literal: true

# t.string :name
# t.timestamps
class DocFile < ApplicationRecord
  has_many :doc_versions, dependent: :delete_all
  has_many :versions, through: :doc_versions

  scope :with_includes, -> { includes(doc_versions: %i[doc version]) }

  @@true_lang = {
    "de" => "Deutsch",
    "en" => "English",
    "es" => "Español",
    "es_MX" => "Español (Mexico)",
    "fr" => "Français",
    "hu" => "magyar",
    "id" => "Bahasa Indonesia",
    "is" => "Íslenska",
    "it" => "Italiano",
    "ja" => "日本語",
    "mr" => "मराठी",
    "nb_NO" => "Norsk bokmål",
    "nl" => "Nederlands",
    "pl" => "Polski",
    "pt_BR" => "Português (Brasil)",
    "pt_PT" => "Português (Portugal)",
    "ro" => "Română",
    "ru" => "Русский",
    "tr" => "Türkçe",
    "uk" => "українська мова",
    "zh_HANS-CN" => "简体中文",
    "zh_HANT" => "繁體中文"
  }

  def true_lang
    @@true_lang
  end

  def languages
    doc_versions.select(:language).distinct.collect do |v|
      [v[:language], @@true_lang[v[:language]] || v[:language]]
    end
  end

  def version_changes(limit_size = 100)
    unchanged_versions = []
    changes = []
    doc_versions = self.doc_versions.includes(:version).version_changes.limit(limit_size).to_a
    doc_versions.each_with_index do |doc_version, i|
      previous_doc_version = doc_versions[i + 1]
      next unless previous_doc_version

      sha2 = doc_version.doc.blob_sha
      sha1 = previous_doc_version.doc.blob_sha
      if sha1 == sha2
        unchanged_versions << doc_version.name
      else
        if !unchanged_versions.empty?
          if unchanged_versions.size == 1
            changes << { name: "#{unchanged_versions.first} no changes", changed: false }
          else
            changes << { name: "#{unchanged_versions.last} &rarr; #{unchanged_versions.first} no changes",
                         changed: false }
          end
          unchanged_versions = []
        end
        changes << { name: doc_version.name, time: doc_version.committed, diff: previous_doc_version.diff(doc_version),
                     changed: true }
      end
    end
    changes
  end

  # TODO: parse file for description
  def description
    ""
  end
end
