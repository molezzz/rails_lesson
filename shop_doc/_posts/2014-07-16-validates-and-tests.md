---
layout: post
title:  第二天
date:   2014-07-16
excerpt: 表单验证，单元测试
---

现在我们的应用已经有了一个产品的模型以及一个由Rails脚手架生成的简单视图了。下一步我们将关注于如何使现有模型更加健壮——如果用户提交了错误的数据，系统不会将数据保存到数据库中，而且应该给用户一个有好的提示。

###新的需求

一些卖家使用了我们的程序，发现了一个问题：在创建新商品时，如果他输入了错误的价格或者忘记填写商品描述，我们程序依然会生成一个新的产品，并显示在商品列表中。虽然商品没有描述不是什么大问题，但是如果一个商品显示“0元”那会给卖家带来巨大损失。所以，卖家希望我们能加上验证：如果商品没有标题或描述，或者图片地址不正确、价格不正确，商品都不应该被保存。

我们应该在哪里添加验证呢？模型是连通代码和数据库的桥梁，我们要想保存数据到数据库就必须通过模型，看起来把验证放在模型中是个不错的选择。不管数据来源于哪里，只要模型对数据进行了检查，错误数据就不会被写入到数据库中了。

我们打开一下`Product`模型文件`app/models/product.rb`:

``` ruby
class Product < ActiveRecord::Base

end
```

很意外？我们实现了那么多功能，但模型里只有两行代码。下面，我们为它添加上空值验证功能，将下面这行代码填写在这两行代码之间：

``` ruby
validates :title, :description, :image_url, presence: true
```

`Validates()`方法是Rails提供的标准验证器。它可以使用一到多个规则验证一个或多个字段。`presence: true`选项告诉验证器，前面的所有字段都必须被填写，并且不能是空值。现在，如果我们打开新建产品页面，什么都不填写，然后点击`创建商品(Create Product)`按钮，你会发现，商品并没有被保存取而代之的是看到一个表单，没有填写的区域被高亮显示。在表单最顶端显示了3条错误信息（至于错误信息为什么是英文，后面你就明白了）：

![s_32_17](/images/s_32_17.png)

前面三个字段都验证了，还剩下一个价格字段，按照客户要求，价格应该是数字，且应该大于等于“0.01”。我们可以用“numericality”选项，配合“:greater_than_or_equal_to”完成这个功能。在刚才代码的下一行插入：

``` ruby
validates :price, numericality: { greater_than_or_equal_to: 0.01 }
```

下面我们再随便填写东西，然后输入一个错误的价格，错误提示页面又会出现了：

![s_32_18](/images/s_32_18.png)

为什么验证时候最小值是“0.01”而不是“0.001”或者更小的值呢？因为，我们在设计数据库的时候，价格字段只精确到小数点后两位，如果我们验证的最小值是“0.001”的话，如果客户填写了“0.002”，模型并不会返回错误，但是如果数据写入数据库，由于精度问题，价格会变成“0”。

我们还有两项需要验证。首先，需要确保产品的标题是唯一的。客户不想相同的产品被添加两次。Rails提供了`uniqueness`选项来处理这个问题。另起一行输入：

``` ruby
validates :title, uniqueness: true
```

然后，我们还要确保商品图片的地址格式是正确的。完成这个功能，我们需要用到“format”选项。在format后，是一个正则表达式。这里我们只简单验证下文件的扩展名是.gif、.jpg或者.png：

``` ruby
validates :image_url, allow_blank: true, format: {
    with: %r{\.(gif|jpg|png)\Z}i,
    message:'图片扩展名必须是.gif、.jpg或者.png'
}
```

需要注意的是，我们使用了“allow_blank:  true”来防止当“image_url”未被填写时报两种错误。现在，经我们修改后的模型大概是这个样子：

``` ruby
class Product < ActiveRecord::Base
  validates :title, :description, :image_url, presence: true
  validates :price, numericality: { greater_than_or_equal_to: 0.01 }
  validates :title, uniqueness: true
  validates :image_url, allow_blank: true, format: {
      with: %r{\.(gif|jpg|png)\Z}i,
      message:'图片扩展名必须是.gif、.jpg或者.png'
  }
end
```

现在商城满足了新的需求：

* 商品的标题、描述和图片地址都不能为空。
* 价格必须是一个数字且必须大于等于0.01。
* 商品的标题是唯一的。
* 图片的链接地址是正确的。

尽管我们对数据做了初步的验证，但是心里总觉得还少了点什么。在继续下一步前，还是先做个测试吧：

``` bash
rake test
```
![s_32_19](/images/s_32_19.png)

情况看起来不太妙。测试并没有执行通过，它报告了两处错误：`test_should_create_product`和 `test_should_update_product`。显然，是我们做了什么导致产品不能被正常创建和更新。解决这个问题，我们现在只需要对测试文件进行简单的修改，打开`test/controllers/products_controller_test.rb`文件将它修改成这个样子：

``` ruby
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

  #...

  test "should create product" do
    assert_difference('Product.count') do
      #post :create, product: { description: @product.description, image_url: @product.image_url, price: @product.price, title: @product.title }
      #这里使用@update替换原来的代码
      post :create, product: @update
    end

    assert_redirected_to product_path(assigns(:product))
  end

  #...

  test "should update product" do
    #patch :update, id: @product, product: { description: @product.description, image_url: @product.image_url, price: @product.price, title: @product.title }
    #这里同样使用@update替换原来的代码
    patch :update, id: @product, product: @update
    assert_redirected_to product_path(assigns(:product))
  end

  #...

end
```

现在，再次运行测试，它报告一切都没问题了。这意味着，我们编写的代码并没有破坏应用整体。不过，我们仍然需要一些测试来确定刚才编写的验证功能是否能正常运转。下面，就让我们编写一些单元测试来验证一下吧。

使用Rails框架的真正乐趣就在于，从创建项目开始，它就支持测试功能。正如你看到的，从我们使用命令创建应用程序，Rails就在帮助我们创建相应的测试代码。我们看下`test/models`下的文件：

``` bash
ls test/models
```

![s_32_20](/images/s_32_20.png)

`product_test.rb`是由Rails脚手架创建的用于存放`product`模型单元测试代码的文件。我们打开它，看看Rails在里面写了些什么：

``` ruby
require 'test_helper'

class ProductTest < ActiveSupport::TestCase
 # test "the truth" do
 # assert true
 # end
end
```

Rails生成了一个ProductTest类，它继承于`ActiveSupport::TestCase。ActiveSupport::TestCase`实际上是`MiniTest::Unit::TestCase`的子类。因此，默认情况下，Rails生成的测试代码是基于Ruby内建的MiniTest测试框架的。如果你以前接触过`MiniTest`框架，使用Rails的测试对于你来说不是什么难事。如果你没有接触过也没关系，我们会一步步为你讲解。

在这个文件中，Rails注释了一个`test…do`的代码块。第一次看到这样的写法，你可能会感到诧异。实际上`test()`是 Active Support的一个类方法，它接受一个字符串参数和一个块。字符串是这个测试的标题。我们可以把测试代码写在这个代码块中。

`assert`这一行是一个测试语句。`assert()`方法做的唯一一件事就是测试它后面的表达式是否返回了`true`。这里的`true`只是个占位符，实际使用中，我们会在true的位置上编写自己的代码。

下面，我们就开始测试刚才编写的验证代码吧。首先，如果创建商品的时候不填写任何信息，我们期待程序在每个空的字段上返回一个验证错误。我们可以使用模型的`errors()`和` invalid?()`方法来检查是否提交的数据被验证过了。还可以使用`any?()`方法检查错误列表中的属性字段。

现在，我们知道该怎么做了，但是如何让测试框架帮我们判断代码测试是否通过了呢？答案就是通过断言。断言是调用一个方法，告诉测试框架我们期待返回`true`的结果。在Rails中，最简单的断言方法是`assert()`。这个方法会检测传入的参数是否是`true`。如果参数为`false`，断言失败，它会向测试框架输出一个包含代码位置的出错信息。这里，我们希望一个空的产品不能够通过模型验证，所以我们可以这样写：

``` ruby
assert product.invalid?
```
将“product_test.rb”中的代码进行一番修改：

``` ruby
require 'test_helper'

class ProductTest < ActiveSupport::TestCase
 test "product attributes must not be empty" do
 product = Product.new
 assert product.invalid?
 assert product.errors[:title].any?
 assert product.errors[:description].any?
 assert product.errors[:price].any?
 assert product.errors[:image_url].any?
 end
end
```

然后再运行一遍测试

``` bash
rake test:models
```

![s_32_20](/images/s_32_20.png)

提示信息告诉我们，测试被执行，且全部通过了。你可能注意到，我们为`test()`方法设置标题的时候使用了英文，这并不是必须的，你可以使用中文以便表意更明确。不过，在一些不支持中文的系统上，错误信息可能会乱码。

刚才的代码，只是测试了字段为空的情况，除此之外，我们还要验证下价格是否有效的问题。在这个文件中添加一个新的测试：

``` ruby
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

```

这个方法中，我们新添加了一个商品，然后依次修改它的价格为“-1”，“0”和“1”，随后再验证结果是否跟我们期待的一样。如果数据没有通过模型的验证方法，我们还调用了“assert_equal()”方法，对出错的信息进行了对比，检查错误信息是否跟我们期待的一致。

第三步，我们还要验证下产品图片的地址的验证是否有效。在文件中添加如下的代码：

``` ruby
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

```

由于图片名称可能存在很多种可能，而一个个写实在是太麻烦了，因此我们使用了两个循环结构来分别验证正确和错误的图片格式。细心的你可能注意到，在`assert()`方法后面我们添加了第二个参数。`assert()`的第二个参数可以接受一个字符串，当断言失败时，这个字符串会被当作出错信息输出，以便我们知道哪里出现了问题。

最后我们还要测试下商品标题重复的验证。进行这个测试，我们可以先创建一个商品，保存，然后再创建另一个，并且让两个商品标题一样，试着保存第二个看看会不是产生验证错误。这样手动进行实在是费时费力，还好Rails为我们提供了更简单的方法`预置数据（fixtures）`。

在测试的世界中，预置数据就是一个可以运行测试的环境。比如，你要测试一块电路板，那就需要有“预置数据”提供电源之类的环境。

在Rails中，预置数据是一个模型在测试开始前的初始数据。举例来说，如果在测试前，想确保数据库产品表中的数据是一组特定数据的话，我们只需将这些数据定义成预置数据，Rails会自动帮我们完成剩下的步骤。

定义预置数据，我们需要将这些数据放置在`test/fixtures`目录中。目录中的每个文件对应一个模型，数据以YAML格式书写在文件中。文件命名需要按照Rails的约定：文件名称必须同数据库表名称匹配。例如，Product模型的数据保存在`products`表中，我们要为Product设置预置数据，就需要将文件命名为`products.yml`。

如果使用Rails的工具生成模型，这个模型对应的预置文件也会被自动创建，因此只需要打开它写入我们需要的数据即可，我们打开`test/fixtures/products.yml`：

``` yaml
# Read about fixtures at http://api.rubyonrails.org/classes/ActiveRecord/FixtureSet.html

one:
  title: MyString
  description: MyText
  image_url: MyString
  price: 9.99

two:
  title: MyString
  description: MyText
  image_url: MyString
  price: 9.99

```


这个文件包含了我们要插入数据的每一个条目。每个条目有一个名字。现在这个文件中的，两个条目分别叫“one”和“two”。它们是由Rails自动生成的。这个名字并不会被写入到数据库中，因此你可以任意编写。不过由于我们会在测试文件中引用这个名字，所以还是尽量起得简短明了比较好。

在每个条目中，你会看到一组具有相同缩进的“名称: 值”对。它看起来很像前面我们修改过的数据库配置文件（`config/database.yml`）。在每一行数据前，我们必须使用空格而不是制表位`tabs`进行缩进，而且它们必须有相同的缩进量。这里的每一个名称都对应着数据库中的一个列名，因此，书写的时候需要格外小心，要保证它们与数据库列名一致。如果名称写错了，测试时将会引发一个`hard-to-track-down`的异常。

我们在这个文件中添加一个数据条目：

``` yaml
#START:lenovo
lenovo:
  title: 联想 A820 白色
  description:
    联想A820是一款实惠的大屏幕智能机，搭载了4.5英寸屏幕，以及1.2GHz四核处理器，体验非常的不错。
  price: 600
  image_url:   lenovo.png
#END:lenovo
```

现在我们有了一个关于Product模型的预置数据文件，如何让Rails在每次测试之前将其导入到数据库中呢？其实很简单，只要按照我们介绍的规则做，Rails就会自动加载这个预置数据文件了。不过，我们也可以通过一些设置来控制，打开` test/models/product_test.rb`：

``` ruby
class ProductTest < ActiveSupport::TestCase

  fixtures :products

  #...

end
```

在类声明的下一行加入`fixtures :products`。`fixtures()`方法会在测试方法运行前，将指定的预置数据写入到数据库中。参数的名称对应数据库表的名称。所以`:products`会将`products.yml`中的数据加载到数据库`products`表中。

使用Rails脚手架生成的测试文件并不会包含我们刚加入的那一行。这是因为，Rails在进行测试前，默认会加载所有的预置数据文件。因此，这里这样做显得有些画蛇添足了。不过，如果你有特殊的需要，可以通过这个方法指定不同的预置数据文件。

这时你可能会问了，我们在进行开发的时候已经在数据库中填充了一些数据，Rails加载预置数据会覆盖掉已经存在的开发用数据吗？其实Rails早已为我们考虑好了这个事情。打开`database.yml`数据库配置文件，你会发现里面有三段配置，分别是 development、test、production。每段配置中都有不同的数据库。`development`是我们平常开发时使用的数据库。`test`是测试环境使用的。`production`是生产环境使用的，也就是我们的应用真正放到线上运行时使用的。所以，加载预置数据并不会影响到我们的开发库，它们只会被填充到测试库中。每次运行测试，Rails都会自动初始化测试数据库，并加载预置数据。不过，你也可以通过运行`rake db:test:prepare.`来手动完成这个过程。

有了预置数据，我们来看看如何在测试中使用它们。既然数据已经被加载到数据库，那我们使用Rails的`find()`方法把它从数据库中取出来不就行了？这是一个方法，不过还有更方便的方法。Rails会自动生成一个跟预置数据文件同名的方法，通过这个方法，我们就可以直接访问到预置数据了。

比如，想使用刚才新添加的`lenovo`数据，我们可以调用`products(:lenovo)`。这个方法会返回一个Product模型的对象，对象会包含我们定义好的属性。现在，我们用它来对重名检测功能做个测试（`test/models/product_test.rb`）：

``` ruby
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
```

由于测试开始前，`lenovo`的数据已经被添加到数据库中，我们使用`products(:lenovo).title`将预置数据中`lenovo`的标题取出来，赋值给新的产品。这样新的产品就跟数据库中已存在的产品重名了，然后我们再用断言方法检测验证是否正常运作了。如果你不想将出错信息硬编码在测试文件中，也可以这样写：

``` ruby
test "product is not valid without a unique title" do
  product = Product.new(
    title: products(:lenovo).title,
    description: 'lenovo',
    price:       699,
    image_url:   'lenovo.gif'
  )

  assert product.invalid?
  assert_equal [I18n.translate('errors.messages.taken')], product.errors[:title]
end
```

`I18n`方法我们在后面的章节会详细介绍，这里只要了解，它能够通过翻译文件，将文字翻译成本地语言即可。现在，我们一颗石头落了地。前面编写的验证代码都正常的工作了。该继续这个商城的其它部分了。

##本章知识点
***
#### 1. 验证方法

#####**为什么要做数据验证？**

数据验证能确保只有合法的数据才会存入数据库。例如，程序可能需要用户提供一个合法的 Email 地址和邮寄地址。在模型中做验证是最有保障的，只有通过验证的数据才能存入数据库。数据验证和使用的数据库种类无关，终端用户也无法跳过，而且容易测试和维护。在 Rails 中做数据验证很简单，Rails 内置了很多帮助方法，能满足常规的需求，而且还可以编写自定义的验证方法。还有一点要特别注意：**在任何情况下都不要信任用户的任何输入！！！**

数据存入数据库之前的验证方法还有其他几种，包括数据库内建的约束，客户端验证和控制器层验证。下面列出了这几种验证方法的优缺点：

* 数据库约束和“存储过程”无法兼容多种数据库，而且测试和维护较为困难。不过，如果其他程序也要使用这个数据库，最好在数据库层做些约束。数据库层的某些验证（例如在使用量很高的数据表中做唯一性验证）通过其他方式实现起来有点困难。
* 客户端验证很有用，但单独使用时可靠性不高。如果使用 JavaScript 实现，用户在浏览器中禁用 JavaScript 后很容易跳过验证。客户端验证和其他验证方式结合使用，可以为用户提供实时反馈。
* 控制器层验证很诱人，但一般都不灵便，难以测试和维护。只要可能，就要保证控制器的代码简洁性，这样才有利于长远发展。
你可以根据实际的需求选择使用哪种验证方式。Rails 认为，模型层数据验证最具普适性。而我们在日常实践中更多的是**采取客户端和模型层双重验证机制**以保证良好的用户体验和安全。

**数据验证在什么时候起作用？**

在 Active Record 中对象有两种状态：一种在数据库中有对应的记录，一种没有。新建的对象（例如，使用 new 方法）还不属于数据库。在对象上调用 save 方法后，才会把对象存入相应的数据表。Active Record 使用实例方法 new_record? 判断对象是否已经存入数据库。

新建并保存记录会在数据库中执行 SQL INSERT 操作。更新现有的记录会在数据库上执行 SQL UPDATE 操作。一般情况下，数据验证发生在这些 SQL 操作执行之前。如果验证失败，对象会被标记为不合法，Active Record 不会向数据库发送 INSERT 或 UPDATE 指令。这样就可以避免把不合法的数据存入数据库。你可以选择在对象创建、保存或更新时执行哪些数据验证。

下列方法会做数据验证，如果验证失败就不会把对象存入数据库：

* create
* create!
* save
* save!
* update
* update!

带有“!”的方法会在验证失败后抛出异常。验证失败后，不带“!”方法不会抛出异常，save 和 update 返回 false，create 返回对象本身。

下列方法会跳过验证，不过验证是否通过都会把对象存入数据库，使用时要特别留意。

* decrement!
* decrement_counter
* increment!
* increment_counter
* toggle!
* touch
* update_all
* update\_attribute（***注意！***不是"update_attributes"，这个方法会触发验证）
* update_column
* update_columns
* update_counters

#####**valid? 和 invalid?**

Rails 使用 valid? 方法检查对象是否合法。valid? 方法会触发数据验证，如果对象上没有错误，就返回 true，否则返回 false。前面我们写测试的时候已经用过了。

#####**errors[]**

要检查对象的某个属性是否合法，可以使用 errors[:attribute]。errors[:attribute] 中包含 :attribute 的所有错误。如果某个属性没有错误，就会返回空数组。

这个方法只在数据验证之后才能使用，因为它只是用来收集错误信息的，并不会触发验证。而且，和前面介绍的 ActiveRecord::Base#invalid? 方法不一样，因为 errors[:attribute] 不会验证整个对象，只检查对象的某个属性是否出错。

#####**数据验证的一般写法**

在Rails4版本中，我们通常使用合并的写法来书写验证规则，比如：

``` ruby
validates :title, :description, :image_url, presence: true
```
它的基本用法是 `validates [验证的属性名，一般是符号形式],[其他属性]`

在Rails3以前的版本，我们还可以见到类似这样的写法：

``` ruby
class Account < ActiveRecord::Base
  validates_uniqueness_of :email, :message => "你的 Email 重复了"
end
```

Rails4中你也可以这样书写，但是这种方式已经不提倡使用了。

Active Record 预先定义了很多数据验证帮助方法，可以直接在模型类定义中使用。这些帮助方法提供了常用的验证规则。每次验证失败后，都会向对象的 errors 集合中添加一个消息，这些消息和所验证的属性是关联的。

每个帮助方法都可以接受任意数量的属性名，所以一行代码就能在多个属性上做同一种验证。

所有的帮助方法都可指定 :on 和 :message 选项，指定何时做验证，以及验证失败后向 errors 集合添加什么消息。:on 选项的可选值是 :create 和 :update。每个帮助函数都有默认的错误消息，如果没有通过 :message 选项指定，则使用默认值。下面分别介绍各帮助方法。

#####**常用的验证方法**

**1. acceptance**

这个方法检查表单提交时，用户界面中的复选框是否被选中。这个功能一般用来要求用户接受程序的服务条款，阅读一些文字，等等。这种验证只针对网页程序，不会存入数据库（如果没有对应的字段，该方法会创建一个虚拟属性）。

``` ruby
class Person < ActiveRecord::Base
  validates :terms_of_service, acceptance: true
end
```

这个方法可以指定 :accept 选项，决定可接受什么值。默认为“1”，很容易修改：

``` ruby
class Person < ActiveRecord::Base
  validates :terms_of_service, acceptance: { accept: 'yes' }
end
```

**2. validates_associated**

如果模型和其他模型有关联，也要验证关联的模型对象，可以使用这个方法。保存对象是，会在相关联的每个对象上调用 valid? 方法。

``` ruby
class Library < ActiveRecord::Base
  has_many :books
  validates_associated :books
end
```

***注意！不要在关联的两端都使用 validates_associated，这样会生成一个循环。***

**3. confirmation**

如果要检查两个文本字段的值是否完全相同，可以使用这个帮助方法。例如，确认 Email 地址或密码。这个帮助方法会创建一个虚拟属性，其名字为要验证的属性名后加 _confirmation。

``` ruby
class Person < ActiveRecord::Base
  validates :email, confirmation: true
end
```

视图中这样写：

``` ruby
<%= text_field :person, :email %>
<%= text_field :person, :email_confirmation %>
```

只有 email_confirmation 的值不是 nil 时才会做这个验证。所以要为确认属性加上存在性验证（后文会介绍 presence 验证）。

``` ruby
class Person < ActiveRecord::Base
  validates :email, confirmation: true
  validates :email_confirmation, presence: true
end
```

**4. exclusion**

这个帮助方法检查属性的值是否不在指定的集合中。集合可以是任何一种可枚举的对象。

``` ruby
class Account < ActiveRecord::Base
  validates :subdomain, exclusion: { in: %w(www us ca jp),
    message: "%{value} is reserved." }
end
```

exclusion 方法要指定 :in 选项，设置哪些值不能作为属性的值。:in 选项有个别名 :with，作用相同。上面的例子设置了 :message 选项，演示如何获取属性的值。


**5. format**

这个帮助方法检查属性的值是否匹配 :with 选项指定的正则表达式。

``` ruby
class Product < ActiveRecord::Base
  validates :legacy_code, format: { with: /\A[a-zA-Z]+\z/,
    message: "only allows letters" }
end
```

**6. inclusion**

这个帮助方法检查属性的值是否在指定的集合中。集合可以是任何一种可枚举的对象。

``` ruby
class Coffee < ActiveRecord::Base
  validates :size, inclusion: { in: %w(small medium large),
    message: "%{value} is not a valid size" }
end

```

inclusion 方法要指定 :in 选项，设置可接受哪些值。:in 选项有个别名 :within，作用相同。上面的例子设置了 :message 选项，演示如何获取属性的值。

**7. length**

这个帮助方法验证属性值的长度，有多个选项，可以使用不同的方法指定长度限制：

``` ruby
class Person < ActiveRecord::Base
  validates :name, length: { minimum: 2 }
  validates :bio, length: { maximum: 500 }
  validates :password, length: { in: 6..20 }
  validates :registration_number, length: { is: 6 }
end
```

可用的长度限制选项有：

* :minimum：属性的值不能比指定的长度短；
* :maximum：属性的值不能比指定的长度长；
* :in（或 :within）：属性值的长度在指定值之间。该选项的值必须是一个范围；
* :is：属性值的长度必须等于指定值；

默认的错误消息根据长度验证类型而有所不同，还是可以 :message 定制。定制消息时，可以使用 :wrong\_length、:too\_long 和 :too\_short 选项，%{count} 表示长度限制的值。

``` ruby
class Person < ActiveRecord::Base
  validates :bio, length: { maximum: 1000,
    too_long: "%{count} characters is the maximum allowed" }
end
```

这个帮助方法默认统计字符数，但可以使用 :tokenizer 选项设置其他的统计方式:

``` ruby
class Essay < ActiveRecord::Base
  validates :content, length: {
    minimum: 300,
    maximum: 400,
    tokenizer: lambda { |str| str.scan(/\w+/) },
    too_short: "must have at least %{count} words",
    too_long: "must have at most %{count} words"
  }
end
```

**8. numericality**

这个帮助方法检查属性的值是否值包含数字。默认情况下，匹配的值是可选的正负符号后加整数或浮点数。如果只接受整数，可以把 :only_integer 选项设为 true。

``` ruby
class Player < ActiveRecord::Base
  validates :points, numericality: true
  validates :games_played, numericality: { only_integer: true }
end
```

除了 :only_integer 之外，这个方法还可指定以下选项，限制可接受的值：

* :greater_than：属性值必须比指定的值大。该选项默认的错误消息是“must be greater than %{count}”；
* :greater\_than\_or_equal\_to：属性值必须大于或等于指定的值。该选项默认的错误消息是“must be greater than or equal to %{count}”；
* :equal_to：属性值必须等于指定的值。该选项默认的错误消息是“must be equal to %{count}”；
* :less_than：属性值必须比指定的值小。该选项默认的错误消息是“must be less than %{count}”；
* :less\_than\_or\_equal\_to：属性值必须小于或等于指定的值。该选项默认的错误消息是“must be less than or equal to %{count}”；
* :odd：如果设为 true，属性值必须是奇数。该选项默认的错误消息是“must be odd”；
* :even：如果设为 true，属性值必须是偶数。该选项默认的错误消息是“must be even”；

**9. presence**

这个帮助方法检查指定的属性是否为非空值，调用 blank? 方法检查只是否为 nil 或空字符串，即空字符串或只包含空白的字符串。

``` ruby
class Person < ActiveRecord::Base
  validates :name, :login, :email, presence: true
end
```

**10. absence**

这个方法验证指定的属性值是否为空，使用 present? 方法检测值是否为 nil 或空字符串，即空字符串或只包含空白的字符串。

``` ruby
class Person < ActiveRecord::Base
  validates :name, :login, :email, absence: true
end
```

**11. uniqueness**

这个帮助方法会在保存对象之前验证属性值是否是唯一的。该方法不会在数据库中创建唯一性约束，所以有可能两个数据库连接创建的记录字段的值是相同的。为了避免出现这种问题，要在数据库的字段上建立唯一性索引。关于多字段所以的详细介绍，参阅 MySQL 手册。

``` ruby
class Account < ActiveRecord::Base
  validates :email, uniqueness: true
end
```

这个验证会在模型对应的数据表中执行一个 SQL 查询，检查现有的记录中该字段是否已经出现过相同的值。

:scope 选项可以指定其他属性，用来约束唯一性验证：

``` ruby
class Holiday < ActiveRecord::Base
  validates :name, uniqueness: { scope: :year,
    message: "should happen once per year" }
end
```

还有个 :case_sensitive 选项，指定唯一性验证是否要区分大小写，默认值为 true。

``` ruby
class Person < ActiveRecord::Base
  validates :name, uniqueness: { case_sensitive: false }
end
```

#####**常用的验证选项**

**1. :allow_nil**

指定 :allow_nil 选项后，如果要验证的值为 nil 就会跳过验证。

``` ruby
class Coffee < ActiveRecord::Base
  validates :size, inclusion: { in: %w(small medium large),
    message: "%{value} is not a valid size" }, allow_nil: true
end

```

**2. :allow_blank**

:allow\_blank 选项和 :allow\_nil 选项类似。如果要验证的值为空（调用 blank? 方法，例如 nil 或空字符串），就会跳过验证。

``` ruby
class Topic < ActiveRecord::Base
  validates :title, length: { is: 5 }, allow_blank: true
end

Topic.create(title: "").valid?  # => true
Topic.create(title: nil).valid? # => true
```

**3 :message**

前面已经介绍过，如果验证失败，会把 :message 选项指定的字符串添加到 errors 集合中。如果没指定这个选项，Active Record 会使用各种验证帮助方法的默认错误消息。

**4 :on**

:on 选项指定什么时候做验证。所有内建的验证帮助方法默认都在保存时（新建记录或更新记录）做验证。如果想修改，可以使用 on: :create，指定只在创建记录时做验证；或者使用 on: :update，指定只在更新记录时做验证。

``` ruby
class Person < ActiveRecord::Base
  # it will be possible to update email with a duplicated value
  validates :email, uniqueness: true, on: :create

  # it will be possible to create the record with a non-numerical age
  validates :age, numericality: true, on: :update

  # the default (validates on both create and update)
  validates :name, presence: true
end
```

#####**条件验证**

有时只有满足特定条件时做验证才说得通。条件可通过 :if 和 :unless 选项指定，这两个选项的值可以是 Symbol、字符串、Proc 或数组。:if 选项指定何时做验证。如果要指定何时不做验证，可以使用 :unless 选项。

**指定 Symbol**

:if 和 :unless 选项的值为 Symbol 时，表示要在验证之前执行对应的方法。这是最常用的设置方法。

``` ruby
class Order < ActiveRecord::Base
  validates :card_number, presence: true, if: :paid_with_card?

  def paid_with_card?
    payment_type == "card"
  end
end
```

**指定字符串**

:if 和 :unless 选项的值还可以是字符串，但必须是 Ruby 代码，传入 eval 方法中执行。当字符串表示的条件非常短时才应该使用这种形式。

``` ruby
class Person < ActiveRecord::Base
  validates :surname, presence: true, if: "name.nil?"
end
```

**指定 Proc**

:if and :unless 选项的值还可以是 Proc。使用 Proc 对象可以在行间编写条件，不用定义额外的方法。这种形式最适合用在一行代码能表示的条件上。

``` ruby
class Account < ActiveRecord::Base
  validates :password, confirmation: true,
    unless: Proc.new { |a| a.password.blank? }
end
```

**条件组合**

有时同一个条件会用在多个验证上，这时可以使用 with_options 方法：

``` ruby
class User < ActiveRecord::Base
  with_options if: :is_admin? do |admin|
    admin.validates :password, length: { minimum: 10 }
    admin.validates :email, presence: true
  end
end
```

**联合条件**

另一方面，如果是否做某个验证要满足多个条件时，可以使用数组。而且，都一个验证可以同时指定 :if 和 :unless 选项。

``` ruby
class Computer < ActiveRecord::Base
  validates :mouse, presence: true,
                    if: ["market.retail?", :desktop?]
                    unless: Proc.new { |c| c.trackpad.present? }
end
```

##扩展阅读

***

1. 验证 [http://guides.rubyonrails.org/active_record_validations.html](http://guides.rubyonrails.org/active_record_validations.html)
