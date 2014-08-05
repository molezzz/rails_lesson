---
layout: post
title:  第四天
date:   2014-07-18
excerpt: 模型,控制器，会话
---

现在我们已经有个一个不错的首页来显示商品了。如果能购买他们就更好了。客户当然也需要这样一个功能。因此，下一步我们决定实现一个购物车功能。这一步，我们会学到很多新知识，迫不及待了么？

###创建购物车

当用户访问首页的时候，他们需要（当然也是我们的希望）选择购买的商品。我们通常的在线购物习惯是，浏览商品然后将喜爱的商品放入虚拟购物车中。选购完成后，去收银台结账。

这意味着，我们的商城系统需要跟踪所有由买家添加到购物车中的商品。要做到这一点，需要把购物车放到数据库中，并且在会话中存储该购物车唯一标识符，cart.id。这样，在结账是，我们可以从会话中找到购物车的标识，然后利用这个标识从数据库中找出待结账的商品。

首先，我们得先创建一个购物车。

``` bash
rails g scaffold Cart
rake db:migrate
```

Rails的会话(session)看起来就像一个`Hash`，所以想把购物车的id放到会话中，可以用`:care_id`作为建，而id作为值。

``` ruby
module CurrentCart
  extend ActiveSupport::Concern

  private

  def set_cart
    @cart = Cart.find(session[:cart_id])
  rescue ActiveRecord::RecordNotFound
    @cart = Cart.create
    session[:cart_id]=@cart.id
  end

end
```

`set_cart()`方法首先从`session`对象中读取`:cart_id`,然后试图从数据库中找出和这个`id`相对应的购物车。由于`find()`方法在没有找到id或者id是`nil`的时候会抛出一个异常，因此，我们利用这一点，使用`rescue`捕获这个异常，然后创建一个新的购物车，并将它存到数据库中。

注意，这里我们使用的Rails4的新特性`Concern`。由于这个方法可能会被多个控制器使用，因此我们把它放到了`CurrentCart`模块里，以方便在不同控制间共享。

**将商品放到购物车中**

经过一段时间的思考和与客户的沟通，我们决定再创建一个模型来管理购物车中的商品：

``` bash
rails g scaffold LineItem product:references cart:belongs_to
rake db:migrate
```

现在数据库中已经有地方存放商品、购物车和购物车中的商品了。不过Rails并没有把它们之间的关系保存在服务器中。要把它们联系起来，我们还需要在模型中声明关系。刚才使用脚手架创建完成后，Rails已经帮我们在模型中设置好了关系。

``` ruby
class LineItem < ActiveRecord::Base
  belongs_to :product
  belongs_to :cart
end
```

在使用脚手架的时候，我们分别使用了`references`和`belongs_to`来分别描述`product`和`belongs_to`。但是我们看到，在模型层面，这两种写法并没有什么区别。Rails都使用了`belongs_to()`方法来创建关系。`belongs_to()`告诉Rails，数据库中`line_item`表中的数据行是依赖于`carts`表和`products`表中的数据行的。也就是说购物车中二的商品是不能单独存在的，除非有对应的购物车和商品。有个简单的方法可以记住在哪里放置`belongs_to`声明：如果一个数据库表有外键，那么应该在相应的模型中为每个外键设置一个`belongs_to`。

刚才的声明是干什么的呢？它们的基本目的是给模型对象添加导航能力。因为我们给`LineItem`添加了`belongs_to()`声明，就可以直接通过`LineItem`的对象读取到与它相关联的`Product`对象了。

``` ruby
li = LineItem.find(...)
puts "This line item is for #{li.product.title}"
```

如果想从与`LineItem`关联的另一端同样实现这样的功能，那么我们还得在相应模型中进行一些修改。打开`app/models/cart.rb`文件，加入`has_many()`方法:

``` ruby
class Cart < ActiveRecord::Base
  has_many :line_items,dependent: :destroy
end
```

这段代码中`has_many :line_items`意思是：一个购物车中有许多被选购的商品。因为每个购物车中的商品都包含对该购物车'id'的引用，所以这些商品被关联到购物车上。`dependent: :destroy`表示购物车中的商品依赖于购物车是否存在。如果这个购物车被删除，那购物车里的商品应该一并被删除。

现在，为了让购物车、商品、购物车中的商品三者之间关系更加完整，我们还要在`Product`模型中添加一些代码。如果有很多的购物车，每一个商品都会被很多购物车中的商品引用（购物车中的商品可以理解为某种标签，它并不是真正存在的商品）。当某种商品被删除的时候，我们要确保这种商品没有存在在任何人的购物车中才可以删除。


``` ruby
class Product < ActiveRecord::Base
  has_many :line_items

  before_destroy :ensure_not_referenced_by_any_line_item

  validates :title, :description, :image_url, presence: true
  validates :price, numericality: { greater_than_or_equal_to: 0.01 }
  validates :title, uniqueness: true
  validates :image_url, allow_blank: true, format: {
      with: %r{\.(gif|jpg|png)\Z}i,
      message:'图片扩展名必须是.gif、.jpg或者.png'
  }

  def self.latest
    Product.order(:updated_at).last
  end

  private

  # 确保商品删除前没被任何购物车引用
  def ensure_not_referenced_by_any_line_item
    if line_items.empty?
      return true
    else
      errors.add(:base, 'Line Items present')
      return false
    end
  end
end
```

模型中，我们除了声明了`has_many`关系外，还定义了一个钩子方法(hook)`ensure_not_referenced_by_any_line_item`。钩子方法就是在对象生命周期中的某个给定的敌方，Rails会自动调用的方法。这里，我们注册了`before_destroy`的钩子方法。Rails在尝试删除数据库中一个数据行之前，会先调用该方法。如果这个钩子方法返回false，就不会删除这一行。

> 注意

> 这里我们直接访问了`errors`对象。`validates`也会把错误信息放在这个对象里。错误信息可以关联到某个属性上，但也可以像代码中写得那样那样，直接与基类相关联。

**将商品添加到购物车**

现在模型间的关系搞定了。是时候给每个产品添加一个“加入购物车”的按钮了。

我们不必添加一个新的控制器，也不用给控制器添加新的方法。先来看下Rails脚手架为我们预先创建好的方法：`index`,`show`,`new`,`edit`,`create`,`update`,`destroy`



