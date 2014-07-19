require 'test_helper'

class ProductTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end

  fixtures :products

  test "product price must be positive" do
   product = Product.new(
     title: 'a Phone',
     description: 'a description',
     image_url: 'phone.jpg'
   )
   product.price = -1
   assert product.invalid?
   assert_equal ['must be greater than or equal to 0.01'],product.errors[:price]
   product.price = 0
   assert product.invalid?
   assert_equal ['must be greater than or equal to 0.01'],product.errors[:price]
   product.price = 1
   assert product.valid?
  end

  def new_product(image_url)
    Product.new(
      title: 'a phone',
      description: 'a description',
      price: 1,
      image_url: image_url
    )
  end

  test "image url" do
    ok = %w{ zte.gif zte.jpg zte.png ZTE.JPG ZTE.Jpg
    http://jd.com/1/a/x/zte.gif }
    bad = %w{ zte.doc zte.gif/more zte.gif.more }

    ok.each do |name|
      assert new_product(name).valid?, "#{name} should be valid"
    end

    bad.each do |name|
      assert new_product(name).invalid?, "#{name} shouldn't be valid"
    end
  end

  test "product is not valid without a unique title" do
    product = Product.new(
      title: products(:lenovo).title,
      description: 'lenovo',
      price:       699,
      image_url:   'lenovo.gif'
    )

    assert product.invalid?
    assert_equal ['has already been taken'], product.errors[:title]
  end

end
