require 'test_helper'

class ItemTest < ActiveSupport::TestCase
  test "item test" do
    it = Item.new(:name => "name", :description => "des" , :price => 3.21,:category => "meat", :img_src => "src_url" , :quantity => 1.0, :unit => "$")
    it.save
    fit = Item.find( it.id )
    assert_equal it, fit
    printf "DONE #{fit.inspect} count = #{Item.count}\n"
  end
end
