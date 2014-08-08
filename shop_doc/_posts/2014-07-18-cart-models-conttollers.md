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

我们不必添加一个新的控制器，也不用给控制器添加新的方法。先来看下Rails脚手架为我们预先创建好的方法：`index`,`show`,`new`,`edit`,`create`,`update`,`destroy`。添加到购物车的这个功能正好可以使用`create`方法来实现(`new`方法看起来也不错，但是这个方法通常会给浏览器发送一个表单，用户在其中输入某些信息，然后由`create`继续处理下去)。

那么下一步我们要创建的是什么呢？肯定不是`Cart`，更不是`Product`。我们要创建的是放在购物车中的`LineItem`。按照以前我们掌握的Rails路由的约定，访问这个控制器需要使用`/line_items`和`POST`方法。

以前我们添加一个链接使用了`link_to()`方法。但是`link_to()`只能生成一个`GET`请求。现在我们需要一个按钮，并且能够发送`POST`请求。还好，Rails为我们提供了`button_to()`方法。根据以前学到的路由知识，我们可以调用`line_items_path()`然后，把要购买的产品ID传给它，这样这个方法就会提供给我们一个可以使用的路径了，打开`app/views/store/index.erb`,添加上按钮：

``` html
<div class="store">
  <% if notice %>
  <p id="notice"><%= notice %></p>
  <% end %>

  <h1>商品列表</h1>

  <ul class="product-list">
  <% cache ['store', Product.latest] do %>
    <% @products.each do |product| %>
     <li>
      <%= image_tag(product.image_url) %>
      <h3><%= product.title %></h3>
      <div class="product-description">
        <%= sanitize(product.description) %>
      </div>
      <div class="price-bar">
        <span class="price"><%=number_to_currency(product.price)%></span>
        <%= button_to '添加到购物车', line_items_path(product_id: product) %>
      </div>
     </li>
    <% end %>
  <% end %>
  </ul>
</div>
```

![s_32_27](/images/s_32_27.png)

如果查看页面的源代码，你会发现`botton_to()`方法为我们生成了一个`<form>`标签。中间还有个`<div>`标签。由于这俩标签都是块元素，如果我们想让按钮排列到价格后而不是下面的话，就需要设置他们的样式了。修改`app/assets/stylesheets/store.css.scss`:

``` css
p, div.price-bar {
  margin-left: 100px;
  margin-top: 0.5em;
  margin-bottom: 0.8em;

  form, div {
    display: inline;
  }

}
```
![s_32_28](/images/s_32_28.png)

点这个按钮之前，我们还得对`line_items_controller`控制器的`create()`方法进行一下改造，让他能够接受传递过来的`product_id`，并且能够获取当前的购物车，并把选购的商品添加进去。首先我们需要把前面写的好的购物车模块添加到控制器，然后还需要根据获取到的参数找出想用的产品：

``` ruby
class LineItemsController < ApplicationController
  # 加入购物车模块
  include CurrentCart
  # 使用钩子，在create前载入购物车
  before_action :set_cart, only: [:create]
  before_action :set_line_item, only: [:show, :edit, :update, :destroy]

  #...

  def create
    # 查找相应商品
    product = Product.find(params[:product_id])
    # 存入购物车
    @line_item = @cart.line_items.build(product: product)

    respond_to do |format|
      if @line_item.save
        # 跳转到购物车
        format.html { redirect_to @line_item.cart, notice: 'Line item was successfully created.' }
        format.json { render :show, status: :created, location: @line_item }
      else
        format.html { render :new }
        format.json { render json: @line_item.errors, status: :unprocessable_entity }
      end
    end
  end

  #...

end

```

这里我们使用了控制器提供的`before_action()`回调方法。这个方法会在`create()`方法被调用前调用`CurrentCart`模块的`set_cart()`方法设置一个购物车。接下来，我们用`params`对象从请求中获得`:product_id`参数。在Rails应用中，`params`对象是非常重要的。它保存了所有浏览器请求中传递的参数。因为视图不需要访问这个结果，所以我们把结构保存在一个局部变量里。

使用`find()`方法找到商品后，我们将找到的商品传递给`@cart.line_items.build()`。这样会构造一个新的购物车和其中商品之间的关系。当然，你也可以从另一端构建这个关系。不过，现在购物车还不能显示其中的项目，我们还得修改下显示页面，打开`app/views/carts/show.html.erb`，显示一个商品列表：

``` html
<% if notice %>
<p id="notice"><%= notice %></p>
<% end %>

<h2>我的购物车</h2>
<ul>
  <% @cart.line_items.each do |item| %>
    <li><%= item.product.title %></li>
  <% end %>
</ul>
```
![s_32_29](/images/s_32_29.png)

##本章知识点

***

####1. Active Record 查询

如果习惯使用 SQL 查询数据库，会发现在 Rails 中执行相同的查询有更好的方式。大多数情况下，在 Active Record 中无需直接使用 SQL。

Active Record 会代你执行数据库查询，可以兼容大多数数据库（MySQL，PostgreSQL 和 SQLite 等）。不管使用哪种数据库，所用的 Active Record 方法都是一样的。


**1.1 从数据库中获取对象**

Active Record 提供了很多查询方法，用来从数据库中获取对象。每个查询方法都接可接受参数，不用直接写 SQL 就能在数据库中执行指定的查询。

这些方法是：

* bind
* create_with
* distinct
* eager_load
* extending
* from
* group
* having
* includes
* joins
* limit
* lock
* none
* offset
* order
* preload
* readonly
* references
* reorder
* reverse_order
* select
* uniq
* where

上述所有方法都返回一个 ActiveRecord::Relation 实例。

Model.find(options) 方法执行的主要操作概括如下：

* 把指定的选项转换成等价的 SQL 查询语句；
* 执行 SQL 查询，从数据库中获取结果；
* 为每个查询结果实例化一个对应的模型对象；
* 如果有 after\_find 回调，再执行 after\_find 回调；

**1.1.1 获取单个对象**

**使用主键**

使用 Model.find(primary_key) 方法可以获取指定主键对应的对象。例如：

``` ruby
# Find the client with primary key (id) 10.
client = Client.find(10)
# => #<Client id: 10, first_name: "Ryan">
```

和上述方法等价的 SQL 查询是：

``` sql
SELECT * FROM clients WHERE (clients.id = 10) LIMIT 1
```

如果未找到匹配的记录，Model.find(primary_key) 会抛出 ActiveRecord::RecordNotFound 异常。

**take**

Model.take 方法会获取一个记录，不考虑任何顺序。例如：

``` ruby
client = Client.take
# => #<Client id: 1, first_name: "Lifo">
```

和上述方法等价的 SQL 查询是：

``` sql
SELECT * FROM clients LIMIT 1
```

如果没找到记录，Model.take 不会抛出异常，而是返回 nil。

获取的记录根据所用的数据库引擎会有所不同。

**first**

Model.first 获取按主键排序得到的第一个记录。例如：

``` ruby
client = Client.first
# => #<Client id: 1, first_name: "Lifo">
```

和上述方法等价的 SQL 查询是：

``` sql
SELECT * FROM clients ORDER BY clients.id ASC LIMIT 1
```

Model.first 如果没找到匹配的记录，不会抛出异常，而是返回 nil。

**last**

Model.last 获取按主键排序得到的最后一个记录。例如：

``` ruby
client = Client.last
# => #<Client id: 221, first_name: "Russel">
```

和上述方法等价的 SQL 查询是：

``` ruby
SELECT * FROM clients ORDER BY clients.id DESC LIMIT 1
```

Model.last 如果没找到匹配的记录，不会抛出异常，而是返回 nil。

**find_by**

Model.find_by 获取满足条件的第一个记录。例如：

``` ruby
Client.find_by first_name: 'Lifo'
# => #<Client id: 1, first_name: "Lifo">

Client.find_by first_name: 'Jon'
# => nil
```

等价于：

``` ruby
Client.where(first_name: 'Lifo').take
```

**take!**

Model.take! 方法会获取一个记录，不考虑任何顺序。例如：

``` ruby
client = Client.take!
# => #<Client id: 1, first_name: "Lifo">
```

和上述方法等价的 SQL 查询是：

``` sql
SELECT * FROM clients LIMIT 1
```

如果未找到匹配的记录，Model.take! 会抛出 ActiveRecord::RecordNotFound 异常。

**first!**

Model.first! 获取按主键排序得到的第一个记录。例如：

``` ruby
client = Client.first!
# => #<Client id: 1, first_name: "Lifo">
```

和上述方法等价的 SQL 查询是：

``` sql
SELECT * FROM clients ORDER BY clients.id ASC LIMIT 1
```

如果未找到匹配的记录，Model.first! 会抛出 ActiveRecord::RecordNotFound 异常。

**last!**

Model.last! 获取按主键排序得到的最后一个记录。例如：

``` ruby
client = Client.last!
# => #<Client id: 221, first_name: "Russel">
```

和上述方法等价的 SQL 查询是：

``` sql
SELECT * FROM clients ORDER BY clients.id DESC LIMIT 1
```

如果未找到匹配的记录，Model.last! 会抛出 ActiveRecord::RecordNotFound 异常。

**find_by!**

Model.find_by! 获取满足条件的第一个记录。如果没找到匹配的记录，会抛出 ActiveRecord::RecordNotFound 异常。例如：

``` ruby
Client.find_by! first_name: 'Lifo'
# => #<Client id: 1, first_name: "Lifo">

Client.find_by! first_name: 'Jon'
# => ActiveRecord::RecordNotFound
```

等价于：

``` ruby
Client.where(first_name: 'Lifo').take!
```

**1.1.2  获取多个对象**

**使用多个主键**

Model.find(array_of_primary_key) 方法可接受一个由主键组成的数组，返回一个由主键对应记录组成的数组。例如：

``` ruby
# Find the clients with primary keys 1 and 10.
client = Client.find([1, 10]) # Or even Client.find(1, 10)
# => [#<Client id: 1, first_name: "Lifo">, #<Client id: 10, first_name: "Ryan">]
```

上述方法等价的 SQL 查询是：

``` sql
SELECT * FROM clients WHERE (clients.id IN (1,10))
```

只要有一个主键的对应的记录未找到，Model.find(array_of_primary_key) 方法就会抛出 ActiveRecord::RecordNotFound 异常。

**take**

Model.take(limit) 方法获取 limit 个记录，不考虑任何顺序：

``` ruby
Client.take(2)
# => [#<Client id: 1, first_name: "Lifo">,
      #<Client id: 2, first_name: "Raf">]

```

和上述方法等价的 SQL 查询是：

``` sql
SELECT * FROM clients LIMIT 2
```

**first**

Model.first(limit) 方法获取按主键排序的前 limit 个记录：

``` ruby
Client.first(2)
# => [#<Client id: 1, first_name: "Lifo">,
      #<Client id: 2, first_name: "Raf">]
```

和上述方法等价的 SQL 查询是：

``` sql
SELECT * FROM clients ORDER BY id ASC LIMIT 2
```

**last**

Model.last(limit) 方法获取按主键降序排列的前 limit 个记录：

``` ruby
Client.last(2)
# => [#<Client id: 10, first_name: "Ryan">,
      #<Client id: 9, first_name: "John">]
```

和上述方法等价的 SQL 查询是：

``` sql
SELECT * FROM clients ORDER BY id DESC LIMIT 2
```

**批量获取多个对象**

我们经常需要遍历由很多记录组成的集合，例如给大量用户发送邮件列表，或者导出数据。

我们可能会直接写出如下的代码：

``` ruby
# This is very inefficient when the users table has thousands of rows.
User.all.each do |user|
  NewsLetter.weekly_deliver(user)
end
```

但这种方法在数据表很大时就有点不现实了，因为 User.all.each 会一次读取整个数据表，一行记录创建一个模型对象，然后把整个模型对象数组存入内存。如果记录数非常多，可能会用完内存。

Rails 为了解决这种问题提供了两个方法，把记录分成几个批次，不占用过多内存。第一个方法是 find\_each，获取一批记录，然后分别把每个记录传入代码块。第二个方法是 find\_in\_batches，获取一批记录，然后把整批记录作为数组传入代码块。

find\_each 和 find\_in\_batches 方法的目的是分批处理无法一次载入内存的巨量记录。如果只想遍历几千个记录，更推荐使用常规的查询方法。

**find_each**

find\_each 方法获取一批记录，然后分别把每个记录传入代码块。在下面的例子中，find\_each 获取 1000 各记录，然后把每个记录传入代码块，知道所有记录都处理完为止：

``` ruby
User.find_each do |user|
  NewsLetter.weekly_deliver(user)
end
```

**find_each 方法的选项**

在 find\_each 方法中可使用 find 方法的大多数选项，但不能使用 :order 和 :limit，因为这两个选项是保留给 find_each 内部使用的。

find\_each 方法还可使用另外两个选项：:batch\_size 和 :start。

`:batch_size`

:batch\_size 选项指定在把各记录传入代码块之前，各批次获取的记录数量。例如，一个批次获取 5000 个记录：

``` ruby
User.find_each(batch_size: 5000) do |user|
  NewsLetter.weekly_deliver(user)
end
```

`:start`

默认情况下，按主键的升序方式获取记录，其中主键的类型必须是整数。如果不想用最小的 ID，可以使用 :start 选项指定批次的起始 ID。例如，前面的批量处理中断了，但保存了中断时的 ID，就可以使用这个选项继续处理。

例如，在有 5000 个记录的批次中，只向主键大于 2000 的用户发送邮件列表，可以这么做：

``` ruby
User.find_each(start: 2000, batch_size: 5000) do |user|
  NewsLetter.weekly_deliver(user)
end
```

还有一个例子是，使用多个 worker 处理同一个进程队列。如果需要每个 worker 处理 10000 个记录，就可以在每个 worker 中设置相应的 :start 选项。

**1.2 条件查询**

**1.2.1 纯字符串条件**

果查询时要使用条件，可以直接指定。例如 Client.where("orders_count = '2'")，获取 orders_count 字段为 2 的客户记录。

> 注意！

> 使用纯字符串指定条件可能导致 SQL 注入漏洞。例如，Client.where("first_name LIKE '%#{params[:first_name]}%'")，这里的条件就不安全。

**1.2.2 数组条件**

如果数字是在别处动态生成的话应该怎么处理呢？可用下面的查询：

``` ruby
Client.where("orders_count = ?", params[:orders])
```

Active Record 会先处理第一个元素中的条件，然后使用后续元素替换第一个元素中的问号（?）。

指定多个条件的方式如下：

``` ruby
Client.where("orders_count = ? AND locked = ?", params[:orders], false)
```

在这个例子中，第一个问号会替换成 params[:orders] 的值；第二个问号会替换成 false 在 SQL 中对应的值，具体的值视所用的适配器而定。

下面这种形式

``` ruby
Client.where("orders_count = ?", params[:orders])
```

要比这种形式好

``` ruby
Client.where("orders_count = #{params[:orders]}")
```

因为前者传入的参数更安全。直接在条件字符串中指定的条件会原封不动的传给数据库。也就是说，即使用户不怀好意，条件也会转义。如果这么做，整个数据库就处在一个危险境地，只要用户发现可以接触数据库，就能做任何想做的事。所以，千万别直接在条件字符串中使用参数。

**条件中的占位符**

除了使用问号占位之外，在数组条件中还可使用键值对 Hash 形式的占位符：

``` ruby
Client.where("created_at >= :start_date AND created_at <= :end_date",
  {start_date: params[:start_date], end_date: params[:end_date]})
```

如果条件中有很多参数，使用这种形式可读性更高。

**1.2.3 Hash 条件**

Active Record 还允许使用 Hash 条件，提高条件语句的可读性。使用 Hash 条件时，传入 Hash 的键是要设定条件的字段，值是要设定的条件。

在 Hash 条件中只能指定相等。范围和子集这三种条件。

**相等**

``` ruby
Client.where(locked: true)
```

字段的名字还可使用字符串表示：

``` ruby
Client.where('locked' => true)
```

在 belongs_to 关联中，如果条件中的值是模型对象，可用关联键表示。这种条件指定方式也可用于多态关联。

``` ruby
Post.where(author: author)
Author.joins(:posts).where(posts: { author: author })
```

条件的值不能为 Symbol。例如，不能这么指定条件：Client.where(status: :active)。

**范围**

``` ruby
Client.where(created_at: (Time.now.midnight - 1.day)..Time.now.midnight)
```

指定这个条件后，会使用 SQL BETWEEN 子句查询昨天创建的客户：

``` sql
SELECT * FROM clients WHERE (clients.created_at BETWEEN '2008-12-21 00:00:00' AND '2008-12-22 00:00:00')
```

这段代码演示了数组条件的简写形式。

**子集**

如果想使用 IN 子句查询记录，可以在 Hash 条件中使用数组：

``` ruby
Client.where(orders_count: [1,3,5])
```

上述代码生成的 SQL 语句如下：

``` sql
SELECT * FROM clients WHERE (clients.orders_count IN (1,3,5))
```

**1.2.4 NOT 条件**

SQL NOT 查询可用 where.not 方法构建。

``` ruby
Post.where.not(author: author)
```

也即是说，这个查询首先调用没有参数的 where 方法，然后再调用 not 方法。

**1.3 排序**

要想按照特定的顺序从数据库中获取记录，可以使用 order 方法。

例如，想按照 created_at 的升序方式获取一些记录，可以这么做：

``` ruby
Client.order(:created_at)
# OR
Client.order("created_at")
```

还可使用 ASC 或 DESC 指定排序方式：

``` ruby
Client.order(created_at: :desc)
# OR
Client.order(created_at: :asc)
# OR
Client.order("created_at DESC")
# OR
Client.order("created_at ASC")
```

或者使用多个字段排序：

``` ruby
Client.order(orders_count: :asc, created_at: :desc)
# OR
Client.order(:orders_count, created_at: :desc)
# OR
Client.order("orders_count ASC, created_at DESC")
# OR
Client.order("orders_count ASC", "created_at DESC")
```

如果想在不同的上下文中多次调用 order，可以在前一个 order 后再调用一次：

``` ruby
Client.order("orders_count ASC").order("created_at DESC")
# SELECT * FROM clients ORDER BY orders_count ASC, created_at DESC
```
**1.4 查询指定字段**

默认情况下，Model.find 使用 SELECT * 查询所有字段。

要查询部分字段，可使用 select 方法。

例如，只查询 viewable_by 和 locked 字段：

``` ruby
Client.select("viewable_by, locked")
```

上述查询使用的 SQL 语句如下：

``` sql
SELECT viewable_by, locked FROM clients
```

使用时要注意，因为模型对象只会使用选择的字段初始化。如果字段不能初始化模型对象，会得到以下异常：

``` ruby
ActiveModel::MissingAttributeError: missing attribute: <attribute>
```

其中 <attribute> 是所查询的字段。id 字段不会抛出 ActiveRecord::MissingAttributeError 异常，所以在关联中使用时要注意，因为关联需要 id 字段才能正常使用。

如果查询时希望指定字段的同值记录只出现一次，可以使用 distinct 方法：

``` ruby
Client.select(:name).distinct
```

上述方法生成的 SQL 语句如下：

``` sql
SELECT DISTINCT name FROM clients
```

查询后还可以删除唯一性限制：

``` ruby
query = Client.select(:name).distinct
# => Returns unique names

query.distinct(false)
# => Returns all names, even if there are duplicates
```
**1.5 限量和偏移**

要想在 Model.find 方法中使用 SQL LIMIT 子句，可使用 limit 和 offset 方法。

limit 方法指定获取的记录数量，offset 方法指定在返回结果之前跳过多少个记录。例如：

``` ruby
Client.limit(5)
```

上述查询最大只会返回 5 各客户对象，因为没指定偏移，多以会返回数据表中的前 5 个记录。生成的 SQL 语句如下：

``` sql
SELECT * FROM clients LIMIT 5
```

再加上 offset 方法：

``` ruby
Client.limit(5).offset(30)
```

这时会从第 31 个记录开始，返回最多 5 个客户对象。生成的 SQL 语句如下：

``` sql
SELECT * FROM clients LIMIT 5 OFFSET 30
```

**1.6 分组**

要想在查询时使用 SQL GROUP BY 子句，可以使用 group 方法。

例如，如果想获取一组订单的创建日期，可以这么做：

``` sql
Order.select("date(created_at) as ordered_date, sum(price) as total_price").group("date(created_at)")
```

上述查询会只会为相同日期下的订单创建一个 Order 对象。

生成的 SQL 语句如下：

``` sql
SELECT date(created_at) as ordered_date, sum(price) as total_price
FROM orders
GROUP BY date(created_at)
```

**1.7 分组筛选**

SQL 使用 HAVING 子句指定 GROUP BY 分组的条件。在 Model.find 方法中可使用 :having 选项指定 HAVING 子句。

例如：

``` sql
Order.select("date(created_at) as ordered_date, sum(price) as total_price").
  group("date(created_at)").having("sum(price) > ?", 100)
```
生成的 SQL 如下：

``` sql
SELECT date(created_at) as ordered_date, sum(price) as total_price
FROM orders
GROUP BY date(created_at)
HAVING sum(price) > 100
```

这个查询只会为同一天下的订单创建一个 Order 对象，而且这一天的订单总额要大于 $100。

####2. Active Record 关联

**为什么要使用关联**

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

**关联的类型**

在 Rails 中，关联是两个 Active Record 模型之间的关系。关联使用宏的方式实现，用声明的形式为模型添加功能。例如，声明一个模型属于（belongs_to）另一个模型后，Rails 会维护两个模型之间的“主键-外键”关系，而且还向模型中添加了很多实用的方法。Rails 支持六种关联：

* belongs_to
* has_one
* has_many
* has_many :through
* has_one :through
* has\_and\_belongs\_to\_many

在后面的几节中，你会学到如何声明并使用这些关联。首先来看一下各种关联适用的场景。

**belongs_to 关联**

belongs_to 关联创建两个模型之间一对一的关系，声明所在的模型实例属于另一个模型的实例。例如，如果程序中有顾客和订单两个模型，每个订单只能指定给一个顾客，就要这么声明订单模型：

``` ruby
class Order < ActiveRecord::Base
  belongs_to :customer
end
```

> 在 belongs_to 关联声明中必须使用单数形式。如果在上面的代码中使用复数形式，程序会报错，提示未初始化常量 Order::Customers。因为 Rails 自动使用关联中的名字引用类名。如果关联中的名字错误的使用复数，引用的类也就变成了复数。

**has_one 关联**

has_one 关联也会建立两个模型之间的一对一关系，但语义和结果有点不一样。这种关联表示模型的实例包含或拥有另一个模型的实例。例如，在程序中，每个供应商只有一个账户，可以这么定义供应商模型：

``` ruby
class Supplier < ActiveRecord::Base
  has_one :account
end
```

**has_many 关联**

has\_many 关联建立两个模型之间的一对多关系。在 belongs\_to 关联的另一端经常会使用这个关联。has\_many 关联表示模型的实例有零个或多个另一个模型的实例。例如，在程序中有顾客和订单两个模型，顾客模型可以这么定义：

``` ruby
class Customer < ActiveRecord::Base
  has_many :orders
end
```

> 声明 has_many 关联时，另一个模型使用复数形式。

**has_many :through 关联**

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

**has_one :through 关联**

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

**has\_and\_belongs\_to\_many 关联**

has\_and\_belongs\_to\_many 关联之间建立两个模型之间的多对多关系，不借由第三个模型。例如，程序中有装配体和零件两个模型，每个装配体中有多个零件，每个零件又可用于多个装配体，这时可以按照下面的方式定义模型：

``` ruby
class Assembly < ActiveRecord::Base
  has_and_belongs_to_many :parts
end

class Part < ActiveRecord::Base
  has_and_belongs_to_many :assemblies
end
```

**使用 belongs\_to 还是 has\_one**

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

**使用 has\_many :through 还是 has\_and\_belongs\_to\_many**

Rails 提供了两种建立模型之间多对多关系的方法。其中比较简单的是 has\_and\_belongs\_to_many，可以直接建立关联：

``` ruby
class Assembly < ActiveRecord::Base
  has_and_belongs_to_many :parts
end

class Part < ActiveRecord::Base
  has_and_belongs_to_many :assemblies
end
```

第二种方法是使用 has_many :through，但无法直接建立关联，要通过第三个模型：

``` ruby
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

####3. Active Record 回调

**回调简介**

回调是在对象生命周期的特定时刻执行的方法。回调方法可以在 Active Record 对象创建、保存、更新、删除、验证或从数据库中读出时执行。

**注册回调**

在使用回调之前，要先注册。回调方法的定义和普通的方法一样，然后使用类方法注册：

``` ruby
class User < ActiveRecord::Base
  validates :login, :email, presence: true

  before_validation :ensure_login_has_a_value

  protected
    def ensure_login_has_a_value
      if login.nil?
        self.login = email unless email.blank?
      end
    end
end
```

这种类方法还可以接受一个代码块。如果操作可以使用一行代码表述，可以考虑使用代码块形式。

``` ruby
class User < ActiveRecord::Base
  validates :login, :email, presence: true

  before_create do
    self.name = login.capitalize if name.blank?
  end
end
```

注册回调时可以指定只在对象生命周期的特定事件发生时执行：

``` ruby
class User < ActiveRecord::Base
  before_validation :normalize_name, on: :create

  # :on takes an array as well
  after_validation :set_location, on: [ :create, :update ]

  protected
    def normalize_name
      self.name = self.name.downcase.titleize
    end

    def set_location
      self.location = LocationService.query(self)
    end
end
```

一般情况下，都把回调方法定义为受保护的方法或私有方法。如果定义成公共方法，回调就可以在模型外部调用，违背了对象封装原则。

**可用的回调**

下面列出了所有可用的 Active Record 回调，按照执行各操作时触发的顺序：

**创建对象**

* before_validation
* after_validation
* before_save
* around_save
* before_create
* around_create
* after_create
* after_save

**更新对象**

* before_validation
* after_validation
* before_save
* around_save
* before_update
* around_update
* after_update
* after_save

**销毁对象**

* before_destroy
* around_destroy
* after_destroy

创建和更新对象时都会触发 after\_save，但不管注册的顺序，总在 after\_create 和 after\_update 之后执行。

**after\_initialize 和 after\_find**

after\_initialize 回调在 Active Record 对象初始化时执行，包括直接使用 new 方法初始化和从数据库中读取记录。after\_initialize 回调不用直接重定义 Active Record 的 initialize 方法。

after\_find 回调在从数据库中读取记录时执行。如果同时注册了 after\_find 和 after\_initialize 回调，after\_find 会先执行。

after\_initialize 和 after\_find 没有对应的 before\_* 回调，但可以像其他回调一样注册。

``` ruby

class User < ActiveRecord::Base
  after_initialize do |user|
    puts "You have initialized an object!"
  end

  after_find do |user|
    puts "You have found an object!"
  end
end
```
``` bash
>> User.new
You have initialized an object!
=> #<User id: nil>

>> User.first
You have found an object!
You have initialized an object!
=> #<User id: 1>
```

**after_touch**

after_touch 回调在触碰 Active Record 对象时执行。

``` ruby
class User < ActiveRecord::Base
  after_touch do |user|
    puts "You have touched an object"
  end
end
```

``` bash
>> u = User.create(name: 'Kuldeep')
=> #<User id: 1, name: "Kuldeep", created_at: "2013-11-25 12:17:49", updated_at: "2013-11-25 12:17:49">

>> u.touch
You have touched an object
=> true
```

可以结合 belongs_to 一起使用：

``` ruby

class Employee < ActiveRecord::Base
  belongs_to :company, touch: true
  after_touch do
    puts 'An Employee was touched'
  end
end

class Company < ActiveRecord::Base
  has_many :employees
  after_touch :log_when_employees_or_company_touched

  private
  def log_when_employees_or_company_touched
    puts 'Employee/Company was touched'
  end
end
```

``` bash
>> @employee = Employee.last
=> #<Employee id: 1, company_id: 1, created_at: "2013-11-25 17:04:22", updated_at: "2013-11-25 17:05:05">

# triggers @employee.company.touch
>> @employee.touch
Employee/Company was touched
An Employee was touched
=> true
```

**执行回调**

下面的方法会触发执行回调：

* create
* create!
* decrement!
* destroy
* destroy!
* destroy_all
* increment!
* save
* save!
* save(validate: false)
* toggle!
* update_attribute
* update
* update!
* valid?

after_find 回调由以下查询方法触发执行：

* all
* first
* find
* find_by
* find_by_*
* find_by_*!
* find_by_sql
* last

after_initialize 回调在新对象初始化时触发执行。

**跳过回调**

和数据验证一样，回调也可跳过，使用下列方法即可：

* decrement
* decrement_counter
* delete
* delete_all
* increment
* increment_counter
* toggle
* touch
* update_column
* update_columns
* update_all
* update_counters

使用这些方法是要特别留心，因为重要的业务逻辑可能在回调中完成。如果没弄懂回调的作用直接跳过，可能导致数据不合法。

**终止执行**

在模型中注册回调后，回调会加入一个执行队列。这个队列中包含模型的数据验证，注册的回调，以及要执行的数据库操作。

整个回调链包含在一个事务中。如果任何一个 before\_* 回调方法返回 false 或抛出异常，整个回调链都会终止执行，撤销事务；而 after\_* 回调只有抛出异常才能达到相同的效果。

> 注意！

> ActiveRecord::Rollback 之外的异常在回调链终止之后，还会由 Rails 再次抛出。抛出 ActiveRecord::Rollback 之外的异常，可能导致不应该抛出异常的方法（例如 save 和 update_attributes，应该返回 true 或 false）无法执行。

####4. Action Controller 控制器

**1. 控制器的作用**

Action Controller 是 MVC 中的 C（控制器）。路由决定使用哪个控制器处理请求后，控制器负责解析请求，生成对应的请求。Action Controller 会代为处理大多数底层工作，使用易懂的约定，让整个过程清晰明了。

在大多数按照 REST 规范开发的程序中，控制器会接收请求（开发者不可见），从模型中获取数据，或把数据写入模型，再通过视图生成 HTML。如果控制器需要做其他操作，也没问题，以上只不过是控制器的主要作用。

因此，控制器可以视作模型和视图的中间人，让模型中的数据可以在视图中使用，把数据显示给用户，再把用户提交的数据保存或更新到模型中。

**2. 控制器命名约定**

Rails 控制器的命名习惯是，最后一个单词使用复数形式，但也是有例外，比如 ApplicationController。例如：用 ClientsController，而不是 ClientController；用 SiteAdminsController，而不是 SiteAdminController 或 SitesAdminsController。

遵守这一约定便可享用默认的路由生成器（例如 resources 等），无需再指定 :path 或 :controller，URL 和路径的帮助方法也能保持一致性。

> 注意！

> 控制器的命名习惯和模型不同，模型的名字习惯使用**单数**形式。

**3. 方法和动作**

控制器是一个类，继承自 ApplicationController，和其他类一样，定义了很多方法。程序接到请求时，路由决定运行哪个控制器和哪个动作，然后创建该控制器的实例，运行和动作同名的方法。

``` ruby
class ClientsController < ApplicationController
  def new
  end
end
```

例如，用户访问 /clients/new 新建客户，Rails 会创建一个 ClientsController 实例，运行 new 方法。注意，在上面这段代码中，即使 new 方法是空的也没关系，因为默认会渲染 new.html.erb 视图，除非指定执行其他操作。在 new 方法中，声明可在视图中使用的 @client 实例变量，创建一个新的 Client 实例：

``` ruby
def new
  @client = Client.new
end
```

ApplicationController 继承自 ActionController::Base。ActionController::Base 定义了很多实用方法。本文会介绍部分方法，如果想知道定义了哪些方法，可查阅 API 文档或源码。

只有公开方法才被视为动作。所以最好减少对外可见的方法数量，例如辅助方法和过滤器方法。

**4. 参数**

在控制器的动作中，往往需要获取用户发送的数据，或其他参数。在网页程序中参数分为两类。第一类随 URL 发送，叫做“请求参数”，即 URL 中 ? 符号后面的部分。第二类经常成为“POST 数据”，一般来自用户填写的表单。之所以叫做“POST 数据”是因为，只能随 HTTP POST 请求发送。Rails 不区分这两种参数，在控制器中都可通过 params Hash 获取：

``` ruby
class ClientsController < ApplicationController
  # This action uses query string parameters because it gets run
  # by an HTTP GET request, but this does not make any difference
  # to the way in which the parameters are accessed. The URL for
  # this action would look like this in order to list activated
  # clients: /clients?status=activated
  def index
    if params[:status] == "activated"
      @clients = Client.activated
    else
      @clients = Client.inactivated
    end
  end

  # This action uses POST parameters. They are most likely coming
  # from an HTML form which the user has submitted. The URL for
  # this RESTful request will be "/clients", and the data will be
  # sent as part of the request body.
  def create
    @client = Client.new(params[:client])
    if @client.save
      redirect_to @client
    else
      # This line overrides the default rendering behavior, which
      # would have been to render the "create" view.
      render "new"
    end
  end
end
```

**4.1 Hash 和数组参数**

params Hash 不局限于只能使用一维键值对，其中可以包含数组和嵌套的 Hash。要发送数组，需要在键名后加上一对空方括号（[]）：

``` bash
GET /clients?ids[]=1&ids[]=2&ids[]=3
```

“[”和“]”这两个符号不允许出现在 URL 中，所以上面的地址会被编码成 /clients?ids%5b%5d=1&ids%5b%5d=2&ids%5b%5d=3。大多数情况下，无需你费心，浏览器会为你代劳编码，接收到这样的请求后，Rails 也会自动解码。如果你要手动向服务器发送这样的请求，就要留点心了。

此时，params[:ids] 的值是 ["1", "2", "3"]。注意，参数的值始终是字符串，Rails 不会尝试转换类型。

默认情况下，基于安全考虑，参数中的 []、[nil] 和 [nil, nil, ...] 会替换成 nil。

要发送嵌套的 Hash 参数，需要在方括号内指定键名：

``` html
<form accept-charset="UTF-8" action="/clients" method="post">
  <input type="text" name="client[name]" value="Acme" />
  <input type="text" name="client[phone]" value="12345" />
  <input type="text" name="client[address][postcode]" value="12345" />
  <input type="text" name="client[address][city]" value="Carrot City" />
</form>
```

提交这个表单后，params[:client] 的值是 { "name" => "Acme", "phone" => "12345", "address" => { "postcode" => "12345", "city" => "Carrot City" } }。注意 params[:client][:address] 是个嵌套 Hash。

注意，params Hash 其实是 ActiveSupport::HashWithIndifferentAccess 的实例，虽和普通的 Hash 一样，**但键名使用 Symbol 和字符串的效果一样**。

**4.2 JSON 参数**

开发网页服务程序时，你会发现，接收 JSON 格式的参数更容易处理。如果请求的 Content-Type 报头是 application/json，Rails 会自动将其转换成 params Hash，按照常规的方法使用：

例如，如果发送如下的 JSON 格式内容：

``` json
{ "company": { "name": "acme", "address": "123 Carrot Street" } }
```

得到的是 params[:company] 就是 { "name" => "acme", "address" => "123 Carrot Street" }。

如果在初始化脚本中开启了 config.wrap\_parameters 选项，或者在控制器中调用了 wrap\_parameters 方法，可以放心的省去 JSON 格式参数中的根键。Rails 会以控制器名新建一个键，复制参数，将其存入这个键名下。因此，上面的参数可以写成：

``` json
{ "name": "acme", "address": "123 Carrot Street" }
```

假设数据传送给 CompaniesController，那么参数会存入 :company 键名下：

``` json
{ name: "acme", address: "123 Carrot Street", company: { name: "acme", address: "123 Carrot Street" } }
```

如果想修改默认使用的键名，或者把其他参数存入其中，请参阅 API 文档。

> 解析 XML 格式参数的功能现已抽出，制成了 gem，名为 actionpack-xml_parser。

**4.3 路由参数**

params Hash 总有 :controller 和 :action 两个键，但获取这两个值应该使用 controller\_name 和 action\_name 方法。路由中定义的参数，例如 :id，也可通过 params Hash 获取。例如，假设有个客户列表，可以列出激活和禁用的客户。我们可以定义一个路由，捕获下面这个 URL 中的 :status 参数：

``` bash
get '/clients/:status' => 'clients#index', foo: 'bar'
```

在这个例子中，用户访问 /clients/active 时，params[:status] 的值是 "active"。同时，params[:foo] 的值也会被设为 "bar"，就像通过请求参数传入的一样。params[:action] 也是一样，其值为 "index"。

**4.4 default_url_options**

在控制器中定义名为 default_url_options 的方法，可以设置所生成 URL 中都包含的参数。这个方法必须返回一个 Hash，其值为所需的参数值，而且键必须使用 Symbol：

``` ruby
class ApplicationController < ActionController::Base
  def default_url_options
    { locale: I18n.locale }
  end
end
```

这个方法定义的只是预设参数，可以被 url_for 方法的参数覆盖。

如果像上面的代码一样，在 ApplicationController 中定义 default\_url\_options，则会用于所有生成的 URL。default\_url\_options 也可以在具体的控制器中定义，只影响和该控制器有关的 URL。

**4.5 健壮参数**

加入健壮参数功能后，Action Controller 的参数禁止在 Avtive Model 中批量赋值，除非参数在白名单中。也就是说，你要明确选择那些属性可以批量更新，避免意外把不该暴露的属性暴露了。

而且，还可以标记哪些参数是必须传入的，如果没有收到，会交由 raise/rescue 处理，返回“400 Bad Request”。

``` ruby
class PeopleController < ActionController::Base
  # This will raise an ActiveModel::ForbiddenAttributes exception
  # because it's using mass assignment without an explicit permit
  # step.
  def create
    Person.create(params[:person])
  end

  # This will pass with flying colors as long as there's a person key
  # in the parameters, otherwise it'll raise a
  # ActionController::ParameterMissing exception, which will get
  # caught by ActionController::Base and turned into that 400 Bad
  # Request reply.
  def update
    person = current_account.people.find(params[:id])
    person.update!(person_params)
    redirect_to person
  end

  private
    # Using a private method to encapsulate the permissible parameters
    # is just a good pattern since you'll be able to reuse the same
    # permit list between create and update. Also, you can specialize
    # this method with per-user checking of permissible attributes.
    def person_params
      params.require(:person).permit(:name, :age)
    end
end
```

**4.5.1 允许使用的标量值**

假如允许传入 :id：

``` ruby
params.permit(:id)
```

若 params 中有 :id，且 :id 是标量值，就可以通过白名单检查，否则 :id 会被过滤掉。因此不能传入数组、Hash 或其他对象。

允许使用的标量类型有：String、Symbol、NilClass、Numeric、TrueClass、FalseClass、Date、Time、DateTime、StringIO、IO、ActionDispatch::Http::UploadedFile 和 Rack::Test::UploadedFile。

要想指定 params 中的值必须为数组，可以把键对应的值设为空数组：

``` ruby
params.permit(id: [])
```

要想允许传入整个参数 Hash，可以使用 permit! 方法：

``` ruby
params.require(:log_entry).permit!
```

此时，允许传入整个 :log_entry Hash 及嵌套 Hash。使用 permit! 时要特别注意，因为这么做模型中所有当前属性及后续添加的属性都允许进行批量赋值。

**4.5.2 嵌套参数**

也可以允许传入嵌套参数，例如：

``` ruby
params.permit(:name, { emails: [] },
              friends: [ :name,
                         { family: [ :name ], hobbies: [] }])
```

此时，允许传入 name，emails 和 friends 属性。其中，emails 必须是数组；friends 必须是一个由资源组成的数组：应该有个 name 属性，还要有 hobbies 属性，其值是由标量组成的数组，以及一个 family 属性，其值只能包含 name 属性（任何允许使用的标量值）。


**5 会话(session)**

程序中的每个用户都有一个会话（session），可以存储少量数据，在多次请求中永久存储。会话只能在控制器和视图中使用，可以通过以下几种存储机制实现：

* ActionDispatch::Session::CookieStore：所有数据都存储在客户端
* ActionDispatch::Session::CacheStore：数据存储在 Rails 缓存里
* ActionDispatch::Session::ActiveRecordStore：使用 Active Record 把数据存储在数据库中（需要使用 activerecord-session_store gem）
* ActionDispatch::Session::MemCacheStore：数据存储在 Memcached 集群中（这是以前的实现方式，现在请改用 CacheStore）

所有存储机制都会用到一个 cookie，存储每个会话的 ID（必须使用 cookie，因为 Rails 不允许在 URL 中传递会话 ID，这么做不安全）。

大多数存储机制都会使用这个 ID 在服务商查询会话数据，例如在数据库中查询。不过有个例外，即默认也是推荐使用的存储方式 CookieStore。CookieStore 把所有会话数据都存储在 cookie 中（如果需要，还是可以使用 ID）。CookieStore 的优点是轻量，而且在新程序中使用会话也不用额外的设置。cookie 中存储的数据会使用密令签名，以防篡改。cookie 会被加密，任何有权访问的人都无法读取其内容。（如果修改了 cookie，Rails 会拒绝使用。）

CookieStore 可以存储大约 4KB 数据，比其他几种存储机制都少很多，但一般也足够用了。不过使用哪种存储机制，都**不建议在会话中存储大量数据**。应该特别避免在会话中存储复杂的对象（Ruby 基本对象之外的一切对象，最常见的是模型实例），服务器可能无法在多次请求中重组数据，最终导致错误。

如果会话中没有存储重要的数据，或者不需要持久存储（例如使用 Flash 存储消息），可以考虑使用 ActionDispatch::Session::CacheStore。这种存储机制使用程序所配置的缓存方式。CacheStore 的优点是，可以直接使用现有的缓存方式存储会话，不用额外的设置。不过缺点也很明显，会话存在时间很多，随时可能消失。

如果想使用其他的会话存储机制，可以在 config/initializers/session_store.rb 文件中设置：

``` ruby
# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rails g active_record:session_migration")
# YourApp::Application.config.session_store :active_record_store
```

签署会话数据时，Rails 会用到会话的键（cookie 的名字），这个值可以在 config/initializers/session_store.rb 中修改：

``` ruby
# Be sure to restart your server when you modify this file.
YourApp::Application.config.session_store :cookie_store, key: '_your_app_session'
```

还可以传入 :domain 键，指定可使用此 cookie 的域名：

``` ruby
# Be sure to restart your server when you modify this file.
YourApp::Application.config.session_store :cookie_store, key: '_your_app_session', domain: ".example.com"
```

Rails 为 CookieStore 提供了一个密令，用来签署会话数据。这个密令可以在 config/secrets.yml 文件中修改：

``` yaml
# Be sure to restart your server when you modify this file.

# Your secret key is used for verifying the integrity of signed cookies.
# If you change this key, all old signed cookies will become invalid!

# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.
# You can use `rake secret` to generate a secure secret key.

# Make sure the secrets in this file are kept private
# if you're sharing your code publicly.

development:
  secret_key_base: a75d...

test:
  secret_key_base: 492f...

# Do not keep production secrets in the repository,
# instead read values from the environment.
production:
  secret_key_base: <%= ENV["SECRET_KEY_BASE"] %>
```

> 使用 CookieStore 时，如果修改了密令，之前所有的会话都会失效。

**5.1 获取会话**

在控制器中，可以使用实例方法 session 获取会话。

会话是惰性加载的，如果不在动作中获取，不会自动加载。因此无需禁用会话，不获取即可。

会话中的数据以键值对的形式存储，类似 Hash：

``` ruby
class ApplicationController < ActionController::Base

  private

  # Finds the User with the ID stored in the session with the key
  # :current_user_id This is a common way to handle user login in
  # a Rails application; logging in sets the session value and
  # logging out removes it.
  def current_user
    @_current_user ||= session[:current_user_id] &&
      User.find_by(id: session[:current_user_id])
  end
end
```

要想把数据存入会话，像 Hash 一样，给键赋值即可：

``` ruby
class LoginsController < ApplicationController
  # "Create" a login, aka "log the user in"
  def create
    if user = User.authenticate(params[:username], params[:password])
      # Save the user ID in the session so it can be used in
      # subsequent requests
      session[:current_user_id] = user.id
      redirect_to root_url
    end
  end
end
```

要从会话中删除数据，把键的值设为 nil 即可：

``` ruby
class LoginsController < ApplicationController
  # "Delete" a login, aka "log the user out"
  def destroy
    # Remove the user id from the session
    @_current_user = session[:current_user_id] = nil
    redirect_to root_url
  end
end
```

要重设整个会话，请使用 reset_session 方法。

**5.2 Flash 消息**

Flash 是会话的一个特殊部分，每次请求都会清空。也就是说，其中存储的数据只能在下次请求时使用，可用来传递错误消息等。

Flash 消息的获取方式和会话差不多，类似 Hash。Flash 消息是 FlashHash 实例。

下面以退出登录为例。控制器可以发送一个消息，在下一次请求时显示：

``` ruby
class LoginsController < ApplicationController
  def destroy
    session[:current_user_id] = nil
    flash[:notice] = "You have successfully logged out."
    redirect_to root_url
  end
end
```

注意，Flash 消息还可以直接在转向中设置。可以指定 :notice、:alert 或者常规的 :flash：

``` ruby
redirect_to root_url, notice: "You have successfully logged out."
redirect_to root_url, alert: "You're stuck here!"
redirect_to root_url, flash: { referral_code: 1234 }
```
上例中，destroy 动作转向程序的 root_url，然后显示 Flash 消息。注意，只有下一个动作才能处理前一个动作中设置的 Flash 消息。

Flash 不局限于警告和提醒，可以设置任何可在会话中存储的内容：

``` erb
<% if flash[:just_signed_up] %>
  <p class="welcome">Welcome to our site!</p>
<% end %>
```

如果希望 Flash 消息保留到其他请求，可以使用 keep 方法：

``` ruby
class MainController < ApplicationController
  # Let's say this action corresponds to root_url, but you want
  # all requests here to be redirected to UsersController#index.
  # If an action sets the flash and redirects here, the values
  # would normally be lost when another redirect happens, but you
  # can use 'keep' to make it persist for another request.
  def index
    # Will persist all flash values.
    flash.keep

    # You can also use a key to keep only some kind of value.
    # flash.keep(:notice)
    redirect_to users_url
  end
end
```

默认情况下，Flash 中的内容只在下一次请求中可用，但有时希望在同一个请求中使用。例如，create 动作没有成功保存资源时，会直接渲染 new 模板，这并不是一个新请求，但却希望希望显示一个 Flash 消息。针对这种情况，可以使用 flash.now，用法和 flash 一样：

``` ruby
class ClientsController < ApplicationController
  def create
    @client = Client.new(params[:client])
    if @client.save
      # ...
    else
      flash.now[:error] = "Could not save client"
      render action: "new"
    end
  end
end
```

**6 Cookies**

程序可以在客户端存储少量数据（称为 cookie），在多次请求中使用，甚至可以用作会话。在 Rails 中可以使用 cookies 方法轻松获取 cookies，用法和 session 差不多，就像一个 Hash：

``` ruby
class CommentsController < ApplicationController
  def new
    # Auto-fill the commenter's name if it has been stored in a cookie
    @comment = Comment.new(author: cookies[:commenter_name])
  end

  def create
    @comment = Comment.new(params[:comment])
    if @comment.save
      flash[:notice] = "Thanks for your comment!"
      if params[:remember_name]
        # Remember the commenter's name.
        cookies[:commenter_name] = @comment.author
      else
        # Delete cookie for the commenter's name cookie, if any.
        cookies.delete(:commenter_name)
      end
      redirect_to @comment.article
    else
      render action: "new"
    end
  end
end
```

注意，删除会话中的数据是把键的值设为 nil，但要删除 cookie 中的值，要使用 cookies.delete(:key) 方法。

Rails 还提供了签名 cookie 和加密 cookie，用来存储敏感数据。签名 cookie 会在 cookie 的值后面加上一个签名，确保值没被修改。加密 cookie 除了会签名之外，还会加密，让终端用户无法读取。

这两种特殊的 cookie 会序列化签名后的值，生成字符串，读取时再反序列化成 Ruby 对象。

序列化所用的方式可以指定：

``` ruby
Rails.application.config.action_dispatch.cookies_serializer = :json
```

新程序默认使用的序列化方法是 :json。为了兼容以前程序中的 cookie，如果没设定 cookies_serializer，就会使用 :marshal。

这个选项还可以设为 :hybrid，读取时，Rails 会自动返序列化使用 Marshal 序列化的 cookie，写入时使用 JSON 格式。把现有程序迁移到使用 :json 序列化方式时，这么设定非常方便。

序列化方式还可以使用其他方式，只要定义了 load 和 dump 方法即可：

``` ruby
Rails.application.config.action_dispatch.cookies_serializer = MyCustomSerializer
```

**7 渲染 XML 和 JSON 数据**

在 ActionController 中渲染 XML 和 JSON 数据非常简单。使用脚手架生成的控制器如下所示：

``` ruby
class UsersController < ApplicationController
  def index
    @users = User.all
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render xml: @users}
      format.json { render json: @users}
    end
  end
end
```

你可能注意到了，在这段代码中，我们使用的是 render xml: @users 而不是 render xml: @users.to\_xml。如果不是字符串对象，Rails 会自动调用 to\_xml 方法。

**8 过滤器**

过滤器（filter）是一些方法，在控制器动作运行之前、之后，或者前后运行。

过滤器会继承，如果在 ApplicationController 中定义了过滤器，那么程序的每个控制器都可使用。

前置过滤器有可能会终止请求循环。前置过滤器经常用来确保动作运行之前用户已经登录。这种过滤器的定义如下：

``` ruby
class ApplicationController < ActionController::Base
  before_action :require_login

  private

  def require_login
    unless logged_in?
      flash[:error] = "You must be logged in to access this section"
      redirect_to new_login_url # halts request cycle
    end
  end
end
```

如果用户没有登录，这个方法会在 Flash 中存储一个错误消息，然后转向登录表单页面。如果前置过滤器渲染了页面或者做了转向，动作就不会运行。如果动作上还有后置过滤器，也不会运行。

在上面的例子中，过滤器在 ApplicationController 中定义，所以程序中的所有控制器都会继承。程序中的所有页面都要求用户登录后才能访问。很显然（这样用户根本无法登录），并不是所有控制器或动作都要做这种限制。如果想跳过某个动作，可以使用 skip\_before\_action：

``` ruby
class LoginsController < ApplicationController
  skip_before_action :require_login, only: [:new, :create]
end
```

此时，LoginsController 的 new 动作和 create 动作就不需要用户先登录。:only 选项的意思是只跳过这些动作。还有个 :except 选项，用法类似。定义过滤器时也可使用这些选项，指定只在选中的动作上运行。

**8.1 后置过滤器和环绕过滤器**

除了前置过滤器之外，还可以在动作运行之后，或者在动作运行前后执行过滤器。

后置过滤器类似于前置过滤器，不过因为动作已经运行了，所以可以获取即将发送给客户端的响应数据。显然，后置过滤器无法阻止运行动作。

环绕过滤器会把动作拉入（yield）过滤器中，工作方式类似 Rack 中间件。

例如，网站的改动需要经过管理员预览，然后批准。可以把这些操作定义在一个事务中：

``` ruby
class ChangesController < ApplicationController
  around_action :wrap_in_transaction, only: :show

  private

  def wrap_in_transaction
    ActiveRecord::Base.transaction do
      begin
        yield
      ensure
        raise ActiveRecord::Rollback
      end
    end
  end
end
```

注意，环绕过滤器还包含了渲染操作。在上面的例子中，视图本身是从数据库中读取出来的（例如，通过作用域（scope）），读取视图的操作在事务中完成，然后提供预览数据。

也可以不拉入动作，自己生成响应，不过这种情况不会运行动作。

**8.2 过滤器的其他用法**

一般情况下，过滤器的使用方法是定义私有方法，然后调用相应的 *_action 方法添加过滤器。不过过滤器还有其他两种用法。

第一种，直接在 *\_action 方法中使用代码块。代码块接收控制器作为参数。使用这种方法，前面的 require\_login 过滤器可以改写成：

``` ruby
class ApplicationController < ActionController::Base
  before_action do |controller|
    unless controller.send(:logged_in?)
      flash[:error] = "You must be logged in to access this section"
      redirect_to new_login_url
    end
  end
end
```

注意，此时在过滤器中使用的是 send 方法，因为 logged\_in? 是私有方法，而且过滤器和控制器不在同一作用域内。定义 require\_login 过滤器不推荐使用这种方法，但比较简单的过滤器可以这么用。

第二种，在类（其实任何能响应正确方法的对象都可以）中定义过滤器。这种方法用来实现复杂的过滤器，使用前面的两种方法无法保证代码可读性和重用性。例如，可以在一个类中定义前面的 require_login 过滤器：

``` ruby
class ApplicationController < ActionController::Base
  before_action LoginFilter
end

class LoginFilter
  def self.before(controller)
    unless controller.send(:logged_in?)
      controller.flash[:error] = "You must be logged in to access this section"
      controller.redirect_to controller.new_login_url
    end
  end
end
```

这种方法也不是定义 require\_login 过滤器的理想方式，因为和控制器不在同一作用域，要把控制器作为参数传入。定义过滤器的类，必须有一个和过滤器种类同名的方法。对于 before_action 过滤器，类中必须定义 before 方法。其他类型的过滤器以此类推。around 方法必须调用 yield 方法执行动作。

**9 防止请求伪造**

跨站请求伪造（CSRF）是一种工具方式，A 网站的用户伪装成 B 网站的用户发送请求，在 B 站中添加、修改或删除数据，而 B 站的用户绝然不知。

防止这种攻击的第一步是，确保所有析构动作（create，update 和 destroy）只能通过 GET 之外的请求方法访问。如果遵从 REST 架构，已经完成了这一步。不过，恶意网站还是可以很轻易地发起非 GET 请求，这时就要用到其他防止跨站攻击的方法了。

我们添加一个只有自己的服务器才知道的难以猜测的令牌。如果请求中没有该令牌，就会禁止访问。

如果使用下面的代码生成一个表单：

``` erb
<%= form_for @user do |f| %>
  <%= f.text_field :username %>
  <%= f.text_field :password %>
<% end %>
```

会看到 Rails 自动添加了一个隐藏字段：

``` html
<form accept-charset="UTF-8" action="/users/1" method="post">
<input type="hidden"
       value="67250ab105eb5ad10851c00a5621854a23af5489"
       name="authenticity_token"/>
<!-- username & password fields -->
</form>
```

所有使用表单帮助方法生成的表单，都有会添加这个令牌。如果想自己编写表单，或者基于其他原因添加令牌，可以使用 form\_authenticity\_token 方法。

form\_authenticity\_token 会生成一个有效的令牌。在 Rails 没有自动添加令牌的地方（例如 Ajax）可以使用这个方法。

**10 request 和 response 对象**

在每个控制器中都有两个存取器方法，分别用来获取当前请求循环的请求对象和响应对象。request 方法的返回值是 AbstractRequest 对象的实例；response 方法的返回值是一个响应对象，表示回送客户端的数据。（详情请参考扩展阅读）

##扩展阅读

***

1. 关联，避免N+1问题,scope [http://guides.rubyonrails.org/active_record_querying.html](http://guides.rubyonrails.org/active_record_querying.html)
2. 多态关联、自关联 [http://guides.rubyonrails.org/association_basics.html](http://guides.rubyonrails.org/association_basics.html)
3. 关联回调 [http://guides.rubyonrails.org/active_record_callbacks.html](http://guides.rubyonrails.org/active_record_callbacks.html)
4. request,response https 等 [http://guides.rubyonrails.org/action_controller_overview.html](http://guides.rubyonrails.org/action_controller_overview.html)

