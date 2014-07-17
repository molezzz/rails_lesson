---
layout: post
title:  第一天
date:   2014-07-15
excerpt: 增量式开发，需求分析，项目建立
---

###增量式开发

我们会渐进地开发这个应用。在一开始的时候，我们会完成某个功能最基本的部分，然后依据现实的需求和使用者的反馈再逐步改进它。这可能和你以往的开发经历不同，但这样做是为了让你从现在开始熟悉敏捷开发的流程，以便将来能够更好的融入你的团队。

在实际工作中，当一个项目刚刚开始的时候，你的客户或者上司对项目的理解还不深刻，可能会提出一些错误的需求，随着项目的进展，他们可能会改变主意或者修正曾经的想法。如果我们一下子将功能做的很完善，那么一但这个功能需要修改，或者被废弃，那将是个极大的损失。因此，我们需要采取渐进的开发方式，使应用能够随时适应变化，并快速的处理它们。这也正是Ruby on Rails擅长的。

###商城的基本功能

在开始开发前，我们要先确定在线商城能够做些什么。我们会先确定一些用例，然后依照这些简单勾勒下Web页面的样子。还要分析下那些数据是应用需要保存和处理的。

**用例(Use Case)**

“用例”是对其他人如何使用我们系统的简单描述。我们要实现的在线商城应用应该是较为简单的。首先我们先来定义两个基本角色：卖家和买家。

买家会在我们的商城上浏览出售的商品，他们应该能看到商品的价格以及相关的图片和描述。买家还可以选择他们喜欢的商品，将它们放入购物车并生成一个订单。

卖家使用商城来维护他们要出售的商品列表，他们可以上架或下架一个商品，可以浏览买家提交的订单，并能够处理它们（卖家还应该可以在线上收取货款，并将商品发送给买家。但这部分我们不在这次实践中实现）。

好了，目前为止我们已经有足够多的细节了。下面应该按照这些描述画个简单的页面草图了。

**页面流程草图**

在构建一个Web应用的时候，我们总是幻想着应用首页是什么样子，然后想象着用户是如何在上面点击浏览。但是在开发的早期，我们没有那样完善的一个页面，有的只是一些草图。虽然这些页面流是不完整的，但是它仍能帮助我们专注于当前要实现的东西，并为未来的工作指明方向。

首先是一张买家使用的页面流：

![买家流程](/images/s_32_1.png)

买家首先浏览一个商品目录，在其中选取喜欢的商品，然后将它们放入购物车中。购物车会显示出他们挑选的商品和数量。买家还可以在目录页上继续浏览并购买或者选择去结算并生成订单。

卖家的页面流也很简单。卖家在登录以后，可以看到一个菜单，他们可以通过菜单选择创建或浏览商品，也可以选择处理已经存在的订单。卖家在浏览商品的时候可以编辑商品信息或者删掉这个商品。

![卖家流程](/images/s_32_2.png)

“配送”选项也非常简单。点击它以后，当前的订单开始配送。系统会自动从未配送的订单列表中选取下一个订单，显示在当前窗口。卖家也可以点击“忽略”按钮忽略掉当前的订单。不过这个配送功能很显然不能在正式的线上商城中使用，因为它什么也没做。不过给用户演示功能足够了。

**数据**

最后，我们要考虑下如何处理数据了。注意，在这里我们不会讨论架构和类。也不会讨论数据库、表、索引之类的东西。我们仅会简单地讨论下数据如何组织。因为，在这个阶段，我们并不知道是否在将来的开发中使用数据库。

基于用例和页面流程，我们画了下面的这个图来描述数据和它们之间的关系：

![UML类图](/images/s_32_3.png)

在画图的过程中，我们发现了一些问题。由于买家需要购买商品，需要一个地方来保存他们的购物清单，因此我们添加了一个购物车(Cart)。但是，除了临时存放一个购物清单，我们想不出还会在里面放些什么。因此，在画图的时候，购物车的地方留了空白，并打上了问号。希望在后面的开发过程中，我们有些想法，能把这个空白填上。

另一个问题是，**在订单中我们应该放些什么？**同样，留到后面的开发过程中去思考吧。

最后，你可能注意到，我们在订单条目`Item`中也添加了一个`price`来记录价格。这是不是重复了呢？其实这个设计是出于实践经验。现实生活中，一件商品可能会涨价或者降价，但是价格的调整不应该影响到已经达成的订单。因此，我们需要一个额外的字段来记录订单达成时的商品价格。

好了，准备工作做的差不多了。可以开始编写代码了。

###创建商城应用

在线商城应用的核心是一个数据库。将数据库安装并配置妥当会为后面的开发和测试减少很多麻烦。如果你不知道如何配置，那么保留Rails的默认配置是个明智的选择。如果你了解怎么配置，Rails提供了一个简单的配置文件方便你进行设置。

**首先，我们要创建一个应用新的Rails应用。**

``` bash
rvm use 2.1@rails4
rails new shop -d=mysql
```
在新建项目时候使用`-d`参数，告诉Rails我们使用何种数据库。这里我们使用`mysql`作为应用的数据库。
项目创建完成后，我们需要编辑`config/database.yml`,修改里面的配置参数，以便连接到数据库。

``` yaml
default: &default
  adapter: mysql2
  encoding: utf8
  pool: 5
  username: root
  password: 123456
  host: localhost

development:
  <<: *default
  database: lesson_shop_develop

test:
  <<: *default
  database: lesson_shop_test


production:
  <<: *default
  database: lesson_shop
  username: shop
  password: <%= ENV['SHOP_DATABASE_PASSWORD'] %>
```

然后，切换到命令行，创建数据库：

``` bash
cd shop
rake db:create
```

###使用Rails脚手架

前面，我们已经规划了产品表中应该有些什么。现在，是实现它们的时候了。我们需要创建一个数据库表和一个Rails的模型（通过模型可以操作数据库的表），创建一个视图供使用者操作，还需要有一个控制器来组织。

好了，让我们开始创建“Product”的模型、视图、控制器和迁移文件吧。Rails 提供了一种简便的方法让我们可以使用一条命令就创建好上述的结构，这就是“脚手架（scaffold）”。我们继续在项目工程目录下输入如下的命令：

``` bash
 rails g scaffold Product title:string description:text image_url:string price:decimal
```
注意，这个命令中，我们输入的是“Product”的单数形式。Rails会自动将模型映射到数据库中的表，表的名称默认是模型类名称的复数形式。现在我们创建了一个叫做“Proudct”的模型，这个模型会被Rails自动映射到名叫“products”的数据库表。

rails脚手架的基本语法是：
`rails g scaffold [模型名] [属性名]:[类型]:[index](可选)`

脚手架生成了大量文件，这里我们要关注一个类似`20140505030129_create_products.rb`的数据迁移文件。

数据迁移文件记录了对数据变化的描述，它与具体的数据库无关。它们既可以改变数据库表的结构，也可以改变表中的数据。我们可以应用这些迁移文件对数据库进行修改，也可以通过它们撤销对数据库的修改，将数据库回滚到修改前的状态。

数据迁移文件由一个基于UTC格式的时间戳前缀`20140505030129`、一个名称`create_products`和一个文件扩展名`.rb` (表示这是个Ruby代码文件)组成。你运行这个命令生成迁移文件的时间戳跟这里写的会不一样。因为它们是根据命令执行的时间自动生成的，反映了迁移文件创建的时间。

###应用迁移文件

虽然在运行脚手架命令的时候我们已经告知了Rails基本的数据类型，但是这里仍需要手动对数据迁移文件进行一些修改。我们需要将`price`字段限制成整数部分8位，小数部分2位的形式。现在打开迁移文件（Rails会把数据迁移文件存储在工程目录下的“db/migrate”目录下），对它进行编辑,改成下面的形式：

``` ruby
class CreateProducts < ActiveRecord::Migration
  def change
    create_table :products do |t|
      t.string :title
      t.text :description
      t.string :image_url
      t.decimal :price, precision: 8, scale: 2

      t.timestamps
    end
  end
end
```

好了，修改完以后，我们需要让Rails将这些改变应用的我们的开发数据库中。我们使用“rake”命令来完成这项工作。“rake”命令就像一个助手：我们告诉它执行一个任务，它就会按照要求完成这个任务。现在我们要求它将所有未应用的数据迁移同步到数据库中：

``` bash
rake db:migrate
```
Rails会搜索所有未被应用的数据迁移文件，然后依次执行它们。现在数据库中“products”表已经被创建，并且被添加到“database.yml”设定的开发数据库中了。到目前为止，所有准备工作都完成了。下面要启动Rails服务并开始编码工作了。

###实现商品列表

首先，我们启动Rails服务器：

``` bash
rails s
```

这个命令启动了一个web服务器，并监听了本地的3000端口。如果你运行时候系统提示“ Address already in use”，那么可能另一个web服务器实例正在运行中。你可以切换到那个应用的终端窗口，按“Ctrl-C”终止那个服务器的运行。或者使用命令“killall ruby”命令，杀死ruby 的进程。

好，现在打开浏览器，访问下刚创建的商城应用。我们需要在地址栏输上端口号“3000”和控制器的名字“products”：

![s_32_8](/images/s_32_8.png)

一个商品的列表页出现了，不过它是英文的。我们可以通过多语言功能把它变成中文的，但那是后面的内容，这里先不涉及。现在我们点击“New Product”来创建一个新产品：

![s_32_9](/images/s_32_9.png)

新建商品的表单被显示出来了。这个表单也是由脚手架自动生成的，不过看起来商品描述（Description）字段留的空间有点小，我们给它增加几行，打开`app/views/products/_form.html.erb`,修改第20行：

``` ruby
<%= f.text_area :description %>
```

修改成：

``` ruby
<%= f.text_area :description, rows: 5 %>
```
刷新下浏览器，你会发现商品描述字段变大了：

![s_32_10](/images/s_32_10.png)

随便在表单里添些东西：

![s_32_11](/images/s_32_11.png)

点击创建商品`Create Product`按钮，一个新的商品就添加成功了。成功后，浏览器会被自动转向到商品内容页面：

![s_32_12](/images/s_32_12.png)

点击返回`Back`按钮后，我们回到了商品列表页，你会发现，列表中已经出现了我们刚才添加的商品：

![s_32_13](/images/s_32_13.png)

尽管这个界面还很丑陋，但是它已经具备了基本的增、删、改、查功能了。如果你对其它的连接和按钮感兴趣的话，也可以自己点击下试试。

到目前为止，我们只使用的4个命令，在进入下一章节前，应该再试试其他的命令。打开终端窗口，在你的工程目录下输入：

``` bash
rake test
```

![s_32_14](/images/s_32_14.png)

这条命令告诉Rails进行一个测试任务。最后一行显示“ 0 failures, 0 errors”表示我们的应用一切正常，所有测试代码执行并没发现问题。这个测试是针对已有模型和控制器的，由于测试代码是脚手架生成的，所以这里应该不会有什么错误。测试是程序开发过程中很重要的一个工作，后面我们会写真正的测试代码，现在先试试，热热身 ：）

###对商品列表页进行美化

现在的商品列表页实在是太难看了！不光你这么认为，我也觉得很难看。下面我们就一起动手对他进行一番美化。不过在美化之前，最好能有一组测试数据填充列表。

填充测试数据，我们可以按照前文介绍的步骤，点击新建按钮然后一步步填写表单再保存。如果这个应用是你自己独立开发，这样做当然没问题。但是如果项目是你同其他团队成员一起开发时候就会有问题了。你填充自己的测试数据，其他团队成员也不得不自己填充测试数据，这样做不仅效率低下，而且不便于团队之间的交流和协同。好在Rails已经想到了这一点，为我们提供了“seeds.rb”文件，方便我们进行数据的填充工作。现在，我们打开`db`目录下的`seeds.rb`文件，做一些修改:

``` ruby
Product.delete_all

Product.create!(
 title: '华为 荣耀3C （白色）3G手机 TD-SCDMA/GSM 双卡双待 2G RAM 套装版 ',
 description:
 %{
 <p>四核/5寸大屏/1G+4G内存/双卡双待/800万像素 </p>
 },
 image_url: '/images/phone_3c.jpg',
 price: 899.00
)
# 还有一些，这里省略了...
```

#####**素材**
![3c](/resources/phone_3c.jpg)
![3x](/resources/phone_3x.jpg)
![nubia](/resources/phone_nubia.jpg)

在文件的前面，我们调用了“delete_all()”方法。这个方法会清空目前`products`表中的所有数据，所以不要在正式上线运行的生产环境中执行这个文件。在商品描述字段`description`中，我们使用了`%{}`，这代表了一个字符串常量，跟使用双引号声明的字符串常量一样，只不过它能够更方便的表示大段的文本。因为被它包裹的字符串可以直接换行或者加入双引号。

将数据同步到数据库，我们只需要在终端中输入：

``` bash
rake db:seed
```
把素材图片放到`public/images`目录下，然后启动Rails服务器，并打开浏览器刷新产品列表页。

![s_32_15](/images/s_32_15.png)

现在，列表中已经填满了数据了。可以开始列表美化工作了。

对列表进行美化需要有两个步骤。首先，我们需要修改`app/views/products/index.html.erb`，然后给列表编写一个style样式表，并在HTML中进行引用。

打开“app/views/products/index.html.erb”,我们将里面的英文改成中文，然后再修改下结构：

``` html
<h1>商品列表</h1>

<table>
 <thead>
 <tr>
 <th>名称</th>
 <th>描述</th>
 <th>价格</th>
 <th></th>
 <th></th>
 <th></th>
 </tr>
 </thead>

 <tbody class="products">
 <% @products.each do |product| %>
 <tr class="<%= cycle('line-odd','line-even')%>">
 <td class="list-image">
 <%= image_tag(product.image_url, class: 'list_image')%>
 </td>
 <td class="list-description">
 <dl>
 <dt><%=product.title%></dt>
 <dd><%=truncate(strip_tags(product.description), length: 80)%></dd>
 </dl>
 </td>
 <td class="list-price"><%= product.price %>元</td>
 <td class="list-actions">
 <%= link_to '查看', product %>
 <%= link_to '编辑', edit_product_path(product) %>
 <%= link_to '删除', product, method: :delete, data: { confirm: '你确定删除吗?' } %>
 </td>
 </tr>
 <% end %>
 </tbody>
</table>

<br>

<%= link_to '新建商品', new_product_path %>
```

我们的样式表应该放在哪里呢？实际上Rails的脚手架命令已经为我们创建好一个空的样式表文件了。它的位置在“app/assets/stylesheets/products.css.scss”。名字是同控制器名称相对应的。现在，我们打开这个文件并进行简单的编辑：

``` css
body {
  font-size: 12px;
}

.products {

 table {
   border-collapse: collapse;
 }

 table tr td{
   padding: 5px;
   vertical-align: top;
 }

 .list-image {
   width: 60px;
   height: 70px;

   img {
     width: 100%;
   }
 }

 .list-description {
   width: 60%;

   dl {
     margin: 0;
   }

   dt {
     color: #244;
     font-weight: bold;
     font-size: 1.2em;
   }

   dd {
     margin: 0;
   }
 }

 .list-price {
   text-align: center;
 }

 .list-actions {
   font-size: 1em;
   text-align: right;
   padding-left: 1em;
 }

 .line-even{
   background: #fff;
 }

 .line-odd{
   background: #eee;
 }
}
```

如果你了解CSS，你会觉得这个样式表文件同你接触过的有些不一样。描述“dl”的规则书写在“.list-description”规则的列表中，而“.list-description”规则又写到了“.produces”规则中。这似乎不符合标准的CSS语法。是的，这个文件实际上是一个Sass的文件。Sass是对CSS语法的扩展和增强。正如你看到的，层级嵌套使CSS更易被编写、阅读和理解。而Sass的规则大部分与CSS的语法兼容，这又使熟悉CSS的人很快就能上手。关于Sass更多的内容，这里就不再展开说明了，你可以去它的官方网站：http://sass-lang.com/ 详细了解。

在Rails中，以“.scss”为结尾的文件会自动被框架处理成标准的CSS代码，然后发送给浏览器。所以你可以放心享受Sass带来的便利，而无需关心浏览器是否支持。

然后我们打开浏览器，刷新一下页面，奇迹出现了：

![s_32_16](/images/s_32_16.png)

列表跟我们想象得一样，变得漂亮了。但是仔细看下`index.html.erb`文件，这里我们并没有引用样式表文件，只是直接在标签上引用了样式类，而样式却自动被加载了，这很神奇。其实，样式表被自动加载的奥秘隐藏在布局文件(layout)`application.html.erb`中。布局文件是视图文件公用的部分。当一个视图文件被调用时，Rails会首先调用指定的布局文件，然后将布局文件中的一些特殊标记进行替换，并将视图文件的渲染结果合并到布局文件的指定位置。默认情况下，所有的视图文件被存储在`app/views/layouts`目录中。我们打开`application.html.erb`看一下：

``` html
<!DOCTYPE html>
<html>
<head>
 <title>Shop</title>
 <%= stylesheet_link_tag "application", media: "all", "data-turbolinks-track" => true %>
 <%= javascript_include_tag "application", "data-turbolinks-track" => true %>
 <%= csrf_meta_tags %>
</head>
<body>

<%= yield %>

</body>
</html>
```

这个布局文件是Rails自动生成的。我们看到，它使用了`stylesheet_link_tag`方法加载了一个叫做`application`的样式文件。默认情况，如果我们不指定样式文件的全路径的话，这个方法会在`app/assets/stylesheets`文件夹中查找相应文件（这里会查找：application.css）。如果你打开`application.css`就会发现，这个文件默认包含了“assets”目录中包含它自己在内的所有样式表文件。而使用脚手架创建的`products.css.scss`也在这个目录中，因此，这个文件被Rails一并加载了。所以，我们不用手动引入样式表文件，也能看到最终效果了。

下面，我们回到`index.html.erb`文件，看看这个文件中需要注意的几个地方：

* 商品列表奇偶行的颜色不同，这是怎么实现的呢？也许你早注意到，我们调用了一个叫做`cycle()`的方法。没错，就是这个方法产生的功效。`cycle()`方法每次被调用，都会交替返回它的两个参数值，也就是`line-odd`和`line-even`。因此，列表中的奇偶行被写上了不同的类名，颜色自然也不同了。

* 我们在视图源代码使用了`truncate()`方法。这个方法会对传入的字符串做一个裁剪。裁剪的长度使用`length`指定。在调用`truncate()`方法前，我们还调用了`strip_tags()`方法来过滤掉输出信息中的HTML标签。需要注意的是，即使你不使用`strip_tags()`过滤HTML标签，也不会出现安全问题。因为Rails在输出时默认将字符串中的HTML标签全部转义了。因此，你只能看到按照文字输出的标签。

* 再来看看“删除”连接。在“link_to()”方法的后面有一个新的选项“data:{…}”。如果你点击这个链接，浏览器会询问你是否确实要删除。在进行有风险操作前，我们都应该提示操作者并让其确认，以防止误操作。

##本章知识点讲解
***

###Action View: Helpers 方法

在Rails中，Helper指的是可以在Template中使用的辅助方法。Helper的主要功能是按照指定要求生成相应的HTML代码。使用Helper方法，可以提高代码的复用率。Rails已经为我们内建了大量的Helper方法，方便我们快速构建页面。

另一个使用Helper的理由是，可以将大量复杂的代码进行封装，使模板层看起来更加简洁清晰。

除了上面我们介绍的`cycle()`等方法外，我们常用的Helper还有以下几大类：

####**静态文件Helper方法**

* javascript\_include\_tag

  > 生成引用javascript的标签

* stylesheet\_link\_tag

  > 生成引用样式表的标签

* image_tag

  > 生成引用图片的标签

* video_tag

  > 生成引用视频的标签

* audio_tag

  > 生成引用音频的标签

####**格式化Helper方法**

* simple_format

  > 将`\n`替换成HTML中的`<br>`标签

* truncate

  > 按照给定参数，对字符串进行截取

* sanitize

  > 按照白名单过滤字符串中的HTML标签
  > 预设允许的HTML标签：
  > ```
      ActionView::Base.sanitized_allowed_tags
      => #<Set: {"strong", "em", "b", "i", "p", "code", "pre", "tt", "samp", "kbd", "var", "sub", "sup", "dfn", "cite", "big", "small", "address", "hr", "br", "div", "span", "h1", "h2", "h3", "h4", "h5", "h6", "ul", "ol", "li", "dl", "dt", "dd", "abbr", "acronym", "a", "img", "blockquote", "del", "ins"}>
      ActionView::Base.sanitized_allowed_attributes
      => #<Set: {"href", "src", "width", "height", "alt", "cite", "datetime", "title", "class", "name", "xml:lang", "abbr"}>
    ```

* strip_tags

  > 删除字符串中的HTML标签

* strip_links

  > 删除字符串中的超链接标签 (`<a href="..."></a>`)

####**URL Helper方法**

* link_to

  > 生成超连接

* mail_to

  > 生成`mailto`超链接

* button_to

  > 生成一个按钮

###**表单Helper方法**

对于一个Web应用来说，表单是非常重要的用户输入界面。Rails提供了很多好用的表单Helper方法。基本上，Rails处理表单分为两种类型：

一种是我们比较常用的，针对模型的增加、修改使用的 —— `form_for`。它的好处是，我们可以传入一个模型对象，模型属性值会被自动绑定到相应的表单域中：

``` html
<%= form_for @model do |f| %>
    <%= f.text_field :name %>
    <%= f.submit %>
<% end %>
```

使用这种表单，我们需要传递一个模型对象或一个模型对象数组。并且需要传递一个块，块接受一个参数。块中是我们需要输出的表单域，每个域的名字必须和模型的属性相对应。


另一种是没有对应模型的表单——`form_tag`:

``` html
<%= form_tag "/search" do %>
    <%= text_field_tag :keyword %>
    <%= submit_tag %>
<% end %>
```

这种写法跟`form_for`有些类似，但是不需要传递模型对象，只需要提供表单提交的地址。同时，提供的块也没有参数。每一个表单域需要以`_tag`结尾。另外，表单域的名称完全不受限制，不需要跟模型属性相对应。

**几个常见的表单域Helper方法**

* text_field

  > 单行文本域

* text_area

  > 多行文本域

* radio_button

  > 单选框

* check_box

  > 多选框

* select

  > 选择框

* select_date, select_datetime

  > Rails特有的日期时间选择框

* submit

  > 提交按钮

**如何处理模型中不存在的属性？**

`form_for`要求表单域的名字在模型中都存在，如果有的表单域并没有模型中的属性相对应，Rails就会报错。但是，这种情况现实生活中又很常见。该如何处理呢？其实很简单，我们只需要给模型添加相应的“虚拟属性”即可：

``` ruby
class Event < ActiveRecord::Base
    attr_accessor :custom_field
end
```

然后就可以在`form_for`中使用了：

``` html
<%= form_for @event do |f| %>
    <%= f.text_field :custom_field %>
    <%= f.submit %>
<% end %>

```
更多关于表单Helper的介绍，可以参考官网的向导
[http://guides.rubyonrails.org/form_helpers.html](http://guides.rubyonrails.org/form_helpers.html)

好了，简单的美化就到这里了。下一章节我们将做一些基本的验证和测试。
