
class Item
  include Mongoid::Document
  include Mongoid::Timestamps

  #index({ :created_at => 1}, expire_after_seconds: 20.seconds);

  field :id , type: Integer

  field :img_src, type: String
  field :category, type: String
  field :name, type: String
  field :description, type: String
  field :price, type: Float
  field :quantity, type: Float
  field :unit, type: String


  index({:sid => Mongo::ASCENDING}, {unique: true})

end
