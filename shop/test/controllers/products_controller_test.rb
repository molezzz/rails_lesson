require 'test_helper'

class ProductsControllerTest < ActionController::TestCase
  setup do
    @product = products(:one)
    #由于我们添加了属性不能为空的验证，因此原先的更新不能成功了
    #这里我们需要添加一些属性
    @update = {
      title: 'a mobile phone',
      description: 'this phone is Nokia',
      image_url: 'nokia.jpg',
      price: 299.95
    }
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:products)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create product" do
    assert_difference('Product.count') do
      #post :create, product: { description: @product.description, image_url: @product.image_url, price: @product.price, title: @product.title }
      #这里使用@update替换原来的代码
      post :create, product: @update
    end

    assert_redirected_to product_path(assigns(:product))
  end

  test "should show product" do
    get :show, id: @product
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @product
    assert_response :success
  end

  test "should update product" do
    #patch :update, id: @product, product: { description: @product.description, image_url: @product.image_url, price: @product.price, title: @product.title }
    #这里同样使用@update替换原来的代码
    patch :update, id: @product, product: @update
    assert_redirected_to product_path(assigns(:product))
  end

  test "should destroy product" do
    assert_difference('Product.count', -1) do
      delete :destroy, id: @product
    end

    assert_redirected_to products_path
  end
end
