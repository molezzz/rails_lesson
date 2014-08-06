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


##本章知识点

***

####2. ActiveRecord 关联

**为什么要使用关联

模型之间为什么要有关联？因为关联让常规操作更简单。例如，在一个简单的 Rails 程序中，有一个顾客模型和一个订单模型。每个顾客可以下多个订单。没用关联的模型定义如下：

``` ruby
class Customer < ActiveRecord::Base
end
 
class Order < ActiveRecord::Base
end
```

假如我们要为一个顾客添加一个订单，得这么做：

``` ruby
@order = Order.create(order_date: Time.now, customer_id: @customer.id)
```

或者说要删除一个顾客，确保他的所有订单都会被删除，得这么做：

``` ruby
@orders = Order.where(customer_id: @customer.id)
@orders.each do |order|
  order.destroy
end
@customer.destroy
```

使用 Active Record 关联，告诉 Rails 这两个模型是有一定联系的，就可以把这些操作连在一起。下面使用关联重新定义顾客和订单模型：

``` ruby
class Customer < ActiveRecord::Base
  has_many :orders, dependent: :destroy
end
 
class Order < ActiveRecord::Base
  belongs_to :customer
end
```

这么修改之后，为某个顾客添加新订单就变得简单了：

``` ruby
@order = @customer.orders.create(order_date: Time.now)
```

删除顾客及其所有订单更容易：

``` ruby
@customer.destroy
```

**关联的类型

在 Rails 中，关联是两个 Active Record 模型之间的关系。关联使用宏的方式实现，用声明的形式为模型添加功能。例如，声明一个模型属于（belongs_to）另一个模型后，Rails 会维护两个模型之间的“主键-外键”关系，而且还向模型中添加了很多实用的方法。Rails 支持六种关联：

* belongs_to
* has_one
* has_many
* has_many :through
* has_one :through
* has\_and\_belongs\_to\_many

在后面的几节中，你会学到如何声明并使用这些关联。首先来看一下各种关联适用的场景。

**belongs_to 关联

belongs_to 关联创建两个模型之间一对一的关系，声明所在的模型实例属于另一个模型的实例。例如，如果程序中有顾客和订单两个模型，每个订单只能指定给一个顾客，就要这么声明订单模型：

``` ruby
class Order < ActiveRecord::Base
  belongs_to :customer
end
```

> 在 belongs_to 关联声明中必须使用单数形式。如果在上面的代码中使用复数形式，程序会报错，提示未初始化常量 Order::Customers。因为 Rails 自动使用关联中的名字引用类名。如果关联中的名字错误的使用复数，引用的类也就变成了复数。

**has_one 关联

has_one 关联也会建立两个模型之间的一对一关系，但语义和结果有点不一样。这种关联表示模型的实例包含或拥有另一个模型的实例。例如，在程序中，每个供应商只有一个账户，可以这么定义供应商模型：

``` ruby
class Supplier < ActiveRecord::Base
  has_one :account
end
```

**has_many 关联

has\_many 关联建立两个模型之间的一对多关系。在 belongs\_to 关联的另一端经常会使用这个关联。has\_many 关联表示模型的实例有零个或多个另一个模型的实例。例如，在程序中有顾客和订单两个模型，顾客模型可以这么定义：

``` ruby
class Customer < ActiveRecord::Base
  has_many :orders
end
```

> 声明 has_many 关联时，另一个模型使用复数形式。

**has_many :through 关联

has_many :through 关联经常用来建立两个模型之间的多对多关联。这种关联表示一个模型的实例可以借由第三个模型，拥有零个和多个另一个模型的实例。例如，在医疗锻炼中，病人要和医生约定练习时间。这中间的关联声明如下：

``` ruby
class Physician < ActiveRecord::Base
  has_many :appointments
  has_many :patients, through: :appointments
end
 
class Appointment < ActiveRecord::Base
  belongs_to :physician
  belongs_to :patient
end
 
class Patient < ActiveRecord::Base
  has_many :appointments
  has_many :physicians, through: :appointments
end
```

连接模型中的集合可以使用 API 关联。例如：

``` ruby
physician.patients = patients
```

会为新建立的关联对象创建连接模型实例，如果其中一个对象删除了，相应的记录也会删除。

> 自动删除连接模型的操作直接执行，不会触发 *_destroy 回调。

has\_many :through 还可用来简化嵌套的 has\_many 关联。例如，一个文档分为多个部分，每一部分又有多个段落，如果想使用简单的方式获取文档中的所有段落，可以这么做：

``` ruby
class Document < ActiveRecord::Base
  has_many :sections
  has_many :paragraphs, through: :sections
end
 
class Section < ActiveRecord::Base
  belongs_to :document
  has_many :paragraphs
end
 
class Paragraph < ActiveRecord::Base
  belongs_to :section
end
```

加上 through: :sections 后，Rails 就能理解这段代码：

``` ruby
@document.paragraphs
```

**has_one :through 关联

has_one :through 关联建立两个模型之间的一对一关系。这种关联表示一个模型通过第三个模型拥有另一个模型的实例。例如，每个供应商只有一个账户，而且每个账户都有一个历史账户，那么可以这么定义模型：

``` ruby
class Supplier < ActiveRecord::Base
  has_one :account
  has_one :account_history, through: :account
end
 
class Account < ActiveRecord::Base
  belongs_to :supplier
  has_one :account_history
end
 
class AccountHistory < ActiveRecord::Base
  belongs_to :account
end
```

**has\_and\_belongs\_to\_many 关联

has\_and\_belongs\_to\_many 关联之间建立两个模型之间的多对多关系，不借由第三个模型。例如，程序中有装配体和零件两个模型，每个装配体中有多个零件，每个零件又可用于多个装配体，这时可以按照下面的方式定义模型：

``` ruby
class Assembly < ActiveRecord::Base
  has_and_belongs_to_many :parts
end
 
class Part < ActiveRecord::Base
  has_and_belongs_to_many :assemblies
end
```

**使用 belongs\_to 还是 has\_one

如果想建立两个模型之间的一对一关系，可以在一个模型中声明 belongs\_to，然后在另一模型中声明 has\_one。但是怎么知道在哪个模型中声明哪种关联？

不同的声明方式带来的区别是外键放在哪个模型对应的数据表中（外键在声明 belongs\_to 关联所在模型对应的数据表中）。不过声明时要考虑一下语义，has\_one 的意思是某样东西属于我。例如，说供应商有一个账户，比账户拥有供应商更合理，所以正确的关联应该这么声明：

``` ruby
class Supplier < ActiveRecord::Base
  has_one :account
end
 
class Account < ActiveRecord::Base
  belongs_to :supplier
end
```

**使用 has\_many :through 还是 has\_and\_belongs\_to\_many

Rails 提供了两种建立模型之间多对多关系的方法。其中比较简单的是 has\_and\_belongs\_to_many，可以直接建立关联：

``` ruby
class Assembly < ActiveRecord::Base
  has_and_belongs_to_many :parts
end
 
class Part < ActiveRecord::Base
  has_and_belongs_to_many :assemblies
end
第二种方法是使用 has_many :through，但无法直接建立关联，要通过第三个模型：

class Assembly < ActiveRecord::Base
  has_many :manifests
  has_many :parts, through: :manifests
end
 
class Manifest < ActiveRecord::Base
  belongs_to :assembly
  belongs_to :part
end
 
class Part < ActiveRecord::Base
  has_many :manifests
  has_many :assemblies, through: :manifests
end
```

根据经验，如果关联的第三个模型要作为独立实体使用，要用 has\_many :through 关联；如果不需要使用第三个模型，用简单的 has\_and\_belongs\_to\_many 关联即可（不过要记得在数据库中创建连接数据表）。

如果需要做数据验证、回调，或者连接模型上要用到其他属性，此时就要使用 has_many :through 关联。

##扩展阅读

***

1. 多态关联、自关联

