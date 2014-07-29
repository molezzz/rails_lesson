class StoreController < ApplicationController

 def index
  @products = Product.order(updated_at: :desc)
 end

end
