class User
  # To change this template use File | Settings | File Templates.
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Paperclip

  has_mongoid_attached_file :photo
end
