# t.string  :name
# t.string  :content_type
# t.string  :content_url
# t.string  :related_type
# t.string  :related_id
# t.integer :score
# t.timestamps
class RelatedItem < ActiveRecord::Base

  def self.create_both(from_arr, to_arr)
    ri = RelatedItem.where( :name         => to_arr[1],
                            :content_type => to_arr[0],
                            :content_url  => to_arr[3],
                            :related_type => from_arr[0],
                            :related_id   => from_arr[2]).first_or_create
    ri.score = to_arr[4] if to_arr[4] > ri.score.to_i
    ri.save

    ri = RelatedItem.where( :name         => from_arr[1],
                            :content_type => from_arr[0],
                            :content_url  => from_arr[3],
                            :related_type => to_arr[0],
                            :related_id   => to_arr[2]).first_or_create
    ri.score = from_arr[4] if from_arr[4] > ri.score.to_i
    ri.save
  end
end
