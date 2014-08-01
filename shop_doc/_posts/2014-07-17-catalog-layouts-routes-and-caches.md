---
layout: post
title:  第三天
date:   2014-07-17
excerpt: 布局，缓存
---

到目前为止，我们进行了一次成功的迭代：收集了用户的需求，实现了商品管理功能并按照用户要求进行了改进，甚至还写了一套简单的测试。下一个任务是什么呢？跟用户交流后，用户想从买家的角度看下应用是什么样子。好吧，下一个任务，我们实现一个商品目录列表。

###创建商品列表

商城应用已经有了一个供卖家管理商品的用的控制器了，现在我们需要创建一个供买家使用的控制器，就叫它“store”吧：

``` bash
rails g controller Store index
```

跟上一次差不多，不过这次我们没有使用脚手架命令，而是使用了`controller`命令。这个命令只会生成控制器以及跟控制器相关的试图和测试文件。一切都妥当了，可以打开浏览器访问 “ http://localhost:3000/store/index ” 查看成果了。不过，既然这个页面是买家看到的最终页面，我们应该把它设置成整个应用的首页。打开`config/routes.rb`文件：

``` ruby
Rails.application.routes.draw do
  get 'store/index'

  resources :products


  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'
  root 'store#index', as: 'store'

  #...
end
```

在文件的上半部分，我们可以看到由Rails自动生成的store和products的路由配置。在“resources :products”下添加 “root 'store#index', as: 'store'”将网站的首页指向store控制器。“as: 'store'”表示让rails生成“ store_path”方法，以便在视图中调用。现在，在浏览器中直接输入“ http://localhost:3000/ ”，会发现，默认的首页已经变成我们指定的“store/index”了：


![s_32_22](/images/s_32_22.png)


好了准备工作就到这里，我们来梳理下后面要如何实现客户的需求。首先，需要将产品列表信息从数据库中取出来，然后将它们显示出来。这意味着，我们需要修改“store_controller.rb”中的“index()”方法。从数据库中读取数据，需要用到模型层，所以“index()”方法中应该这样写：


```ruby
class StoreController < ApplicationController

 def index
  @products = Product.order(updated_at: :desc)
 end

end
```

好由于客户想让最新发布或者有过修改的商品能够优先显示，所以，我们在模型的后面调用了“order()”方法，对返回的产品列表进行排序。“updated_at”是Rails的一个魔法字段，每当记录被更新的时候，这个字段会被自动更新。“:desc”告诉Rails，我们想按照降序（后更新的在前）排列列表。

数据取得了，下面需要把它们显示到视图上去。按照Rails的提示，我们打开“app/views/store/index.html.erb”(还记得前面我们介绍过的Rails关于视图和控制器对应关系的约定吧？)，做一些修改：

``` html
<div class="store">
  <% if notice %>
  <p id="notice"><%= notice %></p>
  <% end %>

  <h1>商品列表</h1>

  <ul class="product-list">
  <% @products.each do |product| %>
   <li>
    <%= image_tag(product.image_url) %>
    <h3><%= product.title %></h3>
    <div class="product-description">
      <%= sanitize(product.description) %>
    </div>
    <div class="price-bar">
      <span class="price"><%= product.price %></span>
    </div>
   </li>
  <% end %>
  </ul>
</div>
```

注意，在输出商品的描述信息时，我们使用了`sanitize()`方法。这个是Rails提供的一个视图helper方法，它可以将待输出文本中安全的HTML标签保留下来，过滤掉一些不安全的标签。为了商品描述更美观，编辑可能在描述中添加段落或者图片之类的标签，所以我们不能将所有的HTML都过滤掉。不过使用`sanitize()`方法会带来一个安全隐患，那就是XSS攻击 。不过，这里的商品描述是由卖家输入的，因此可以忽略这个风险。如果信息是由用户输入的话，你就得格外注意了。

视图中，我们还使用了`image_tag()`方法，这个方法能够根据传入的参数生成一个`<img/>`标签。

视图修改完后，我们还需要编写一个样式表，好让这个列表变得美观些。前面创建store控制器的时候，Rails已经帮我们创建了对应的样式表文件，这里，只要打开它进行一番修改即可。打开“app/assets/stylesheets/store.css.scs”并添加样式：

``` css
// Place all the styles related to the Store controller here.
// They will automatically be included in application.css.
// You can use Sass (SCSS) here: http://sass-lang.com/

.store {
  position: relative;

  h1 {
    margin: 0;
    padding-bottom: 0.5em;
    font-size: 1.5em;
    color: #333;
    border-bottom: 3px dotted #555;
  }

  .product-list {
    overflow: auto;
    margin-top: 1em;
    border-bottom: 1px dotted #77d;
    min-height: 100px;
    list-style: none;

    li {
      min-height: 10em;
    }

    img {
      width: 100px;
      margin: 0.2em auto 0.2em;
      position: absolute;
      left: 1em;
    }

    h3 {
      font-size: 120%;
      font-family: sans-serif;
      margin-left: 100px;
      margin-top: 0;
      margin-bottom: 2px;
      color: #222;
    }

    p, div.price-bar {
      margin-left: 100px;
      margin-top: 0.5em;
      margin-bottom: 0.8em;
    }

    .product-description {
      min-height: 3em;
    }

    .price {
      color: #44a;
      font-size: 1.2em;
      font-weight: bold;
      margin-right: 3em;
    }
  }
}
```


刷新浏览器，虽然界面很简单，但是至少具备一定的美感了。

![s_32_23](/images/s_32_23.png)

不过，这个页面和常见的网站还是有很大的不同。我们常见的网站一般都会有一个顶部的导航栏和一个左侧的侧边栏。在实际工作中，这个时候我们通常要召唤设计师小伙伴了，由他们来完成整个网站的设计。不过，现在没有设计师，我们也只能自己来设计个简单的导航栏和侧边栏了。下一个任务，我们来实现这些功能。

**添加一个布局文件**

现实中我们看到网站，页面和页面之间大多有相似的布局。在工作中，设计师一般会给我们提供一个框架模板。我们只需要对其中的部分进行修改，并将其应用到各个页面上。

Rails中这个页面模板称之为“layout(布局)”，他们通常会被放置在`app/views/layouts`文件夹中。这个目录中有个特殊的`application.html.erb`文件，在没有其他页面布局或特殊设置的情况下，所有控制器视图都将使用这个布局。了解到这一点，我们就有办法了。只要修改这个文件，整个站点就能换一个风格了。打开这个文件，我们为站点加上头和侧边栏：

``` html
<!DOCTYPE html>
<html>
<head>
  <title>Shop</title>
  <%= stylesheet_link_tag    'application', media: 'all', 'data-turbolinks-track' => true %>
  <%= javascript_include_tag 'application', 'data-turbolinks-track' => true %>
  <%= csrf_meta_tags %>
</head>
<body>
  <div id="banner">
    <%= image_tag("logo.png") %>
    <%= @page_title || "京西小店" %>
  </div>
  <div id="columns">
    <div id="side">
      <ul>
        <li><a href="#">首页</a></li>
        <li><a href="#">新闻</a></li>
        <li><a href="#">客服</a></li>
        <li><a href="#">联系我们</a></li>
      </ul>
    </div>
    <div id="main">

      <%= yield %>

    </div>
  </div>

</body>
</html>
```

这个文件的前面几行是Rails脚手架自动生成的。其中使用了`stylesheet_link_tag()`方法生成了一个`<link>`标签，引用全局的样式表文件。在`<body>`标签之间我们加入了顶栏和侧边栏的代码，其中使用了`@page_title`实例变量，来充当页面标题。（这个表达式看起来很眼熟，还记得原来讲过的ruby的一些小习惯么？）。再往下是`yield`关键字，使用这个布局的页面会把页面中的内容输出到这个位置。

好，下面我们来为这个页面添加点样式。首先，为了在样式文件中使用`sass`，我们得先把`application.css`重命名为`application.css.scss`。然后添加下面的代码：

```css
/*
 * This is a manifest file that'll be compiled into application.css, which will include all the files
 * listed below.
 *
 * Any CSS and SCSS file within this directory, lib/assets/stylesheets, vendor/assets/stylesheets,
 * or vendor/assets/stylesheets of plugins, if any, can be referenced here using a relative path.
 *
 * You're free to add application-wide styles to this file and they'll appear at the bottom of the
 * compiled file so the styles you add here take precedence over styles defined in any styles
 * defined in the other CSS/SCSS files in this directory. It is generally better to create a new
 * file per style scope.
 *
 *= require_tree .
 *= require_self
 */

#banner {
  background: #FFF;
  padding: 10px;
  border-bottom: 2px solid;
  font: small-caps 40px/60px "Times New Roman", serif;
  color: #C91623;
  text-align: center;
  height: 60px;

  img {
    float: left;
  }
}

#notice {
  color: #000 !important;
  border: 2px solid red;
  padding: 1em;
  margin-bottom: 2em;
  background-color: #f0f0f0;
  font: bold smaller sans-serif;
}

#columns {
  background: #E4393C;

  #main {
    margin-left: 17em;
    padding: 1em;
    background: white;
  }

  #side {
    float: left;
    padding: 1em 2em;
    width: 13em;
    background: #E4393C;

    ul {
      padding: 0;
      li {
        list-style: none;
        a {
          color: #FFF;
          font-size: small;
        }
      }
    }
  }
}
```

![s_32_24](/images/s_32_24.png)

现在感觉有点意思了。不过好像还有些问题。我们期望价格能够显示小数点后两位，也就是显示到分，而且前面显示货币符号。Ruby提供了对数字进行格式化的方法`sprintf()`，使用这个方法，就可以实现对价格的格式化输出了。比如，我们可以这样写：

``` html
<span class="price"><%= sprintf("￥%0.02f",product.price)%></span>
```
这样写当然没错，但是将货币符号写到视图中，如果将来要国际化这个商城应用，比如都用美元标示，这就存在问题了。还好，Rails帮我们考虑了这个问题，它提供了`number_to_currency`的helper方法，我们将模板中的：

``` html
<span class="price"><%= product.price %></span>
```

修改成：

``` html
<span class="price"><%=number_to_currency(product.price)%></span>
```

刷新页面，价格发生了变化。不过好像跟我们期待的不一样。这个helper方法并没有输出“￥”而是输出了“$”：

![s_32_25](/images/s_32_25.png)

这是由于Rails默认的语言是英语。我们打开`config/application.rb`，会看到注释中有关于语言的设置说明：

``` ruby
# The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
# config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
# config.i18n.default_locale = :de
```

我们把`config.i18n.default_locale = :de`这行注释打开，修改成中文：

``` ruby
config.i18n.default_locale = :'zh-CN'
```
然后[下载](https://github.com/svenfuchs/rails-i18n/blob/master/rails/locale/zh-CN.yml)一份中文语言文件，存储到`config/locales`下:

``` yaml
zh-CN:
  date:
    abbr_day_names:
    - 日
    - 一
    - 二
    - 三
    - 四
    - 五
    - 六
    abbr_month_names:
    -
    - 1月
    - 2月
    - 3月
    - 4月
    - 5月
    - 6月
    - 7月
    - 8月
    - 9月
    - 10月
    - 11月
    - 12月
    day_names:
    - 星期日
    - 星期一
    - 星期二
    - 星期三
    - 星期四
    - 星期五
    - 星期六
    formats:
      default: ! '%Y-%m-%d'
      long: ! '%Y年%b%d日'
      short: ! '%b%d日'
    month_names:
    -
    - 一月
    - 二月
    - 三月
    - 四月
    - 五月
    - 六月
    - 七月
    - 八月
    - 九月
    - 十月
    - 十一月
    - 十二月
    order:
    - :year
    - :month
    - :day
  datetime:
    distance_in_words:
      about_x_hours:
        one: 大约一小时
        other: 大约 %{count} 小时
      about_x_months:
        one: 大约一个月
        other: 大约 %{count} 个月
      about_x_years:
        one: 大约一年
        other: 大约 %{count} 年
      almost_x_years:
        one: 接近一年
        other: 接近 %{count} 年
      half_a_minute: 半分钟
      less_than_x_minutes:
        one: 不到一分钟
        other: 不到 %{count} 分钟
      less_than_x_seconds:
        one: 不到一秒
        other: 不到 %{count} 秒
      over_x_years:
        one: 一年多
        other: ! '%{count} 年多'
      x_days:
        one: 一天
        other: ! '%{count} 天'
      x_minutes:
        one: 一分钟
        other: ! '%{count} 分钟'
      x_months:
        one: 一个月
        other: ! '%{count} 个月'
      x_seconds:
        one: 一秒
        other: ! '%{count} 秒'
    prompts:
      day: 日
      hour: 时
      minute: 分
      month: 月
      second: 秒
      year: 年
  errors:
    format: ! '%{attribute}%{message}'
    messages:
      accepted: 必须是可被接受的
      blank: 不能为空字符
      present: 必须是空白
      confirmation: 与确认值不匹配
      empty: 不能留空
      equal_to: 必须等于 %{count}
      even: 必须为双数
      exclusion: 是保留关键字
      greater_than: 必须大于 %{count}
      greater_than_or_equal_to: 必须大于或等于 %{count}
      inclusion: 不包含于列表中
      invalid: 是无效的
      less_than: 必须小于 %{count}
      less_than_or_equal_to: 必须小于或等于 %{count}
      not_a_number: 不是数字
      not_an_integer: 必须是整数
      odd: 必须为单数
      record_invalid: ! '验证失败: %{errors}'
      restrict_dependent_destroy:
        one: 由于 %{record} 需要此记录，所以无法移除记录
        many: 由于 %{record} 需要此记录，所以无法移除记录
      taken: 已经被使用
      too_long:
        one: 过长（最长为一个字符）
        other: 过长（最长为 %{count} 个字符）
      too_short:
        one: 过短（最短为一个字符）
        other: 过短（最短为 %{count} 个字符）
      wrong_length:
        one: 长度非法（必须为一个字符）
        other: 长度非法（必须为 %{count} 个字符）
      other_than: 长度非法（不可为 %{count} 个字符
    template:
      body: 如下字段出现错误：
      header:
        one: 有 1 个错误发生导致「%{model}」无法被保存。
        other: 有 %{count} 个错误发生导致「%{model}」无法被保存。
  helpers:
    select:
      prompt: 请选择
    submit:
      create: 新增%{model}
      submit: 储存%{model}
      update: 更新%{model}
  number:
    currency:
      format:
        delimiter: ! ','
        format: ! '%u %n'
        precision: 2
        separator: .
        significant: false
        strip_insignificant_zeros: false
        unit: ¥
    format:
      delimiter: ! ','
      precision: 3
      separator: .
      significant: false
      strip_insignificant_zeros: false
    human:
      decimal_units:
        format: ! '%n %u'
        units:
          billion: 十亿
          million: 百万
          quadrillion: 千兆
          thousand: 千
          trillion: 兆
          unit: ''
      format:
        delimiter: ''
        precision: 1
        significant: false
        strip_insignificant_zeros: false
      storage_units:
        format: ! '%n %u'
        units:
          byte:
            one: Byte
            other: Bytes
          gb: GB
          kb: KB
          mb: MB
          tb: TB
    percentage:
      format:
        delimiter: ''
    precision:
      format:
        delimiter: ''
  support:
    array:
      last_word_connector: ! ', 和 '
      two_words_connector: ! ' 和 '
      words_connector: ! ', '
  time:
    am: 上午
    formats:
      default: ! '%Y年%b%d日 %A %H:%M:%S %Z'
      long: ! '%Y年%b%d日 %H:%M'
      short: ! '%b%d日 %H:%M'
    pm: 下午
```

重启服务器，刷新页面。OK，现在正常了。

![s_32_26](/images/s_32_26.png)

#####**为页面添加缓存**

如果一切进行顺利地话，作为首页的这个页面会有大量的访问量。每当这个页面被访问的时候，我们都需要从数据库中取出产品，然后循环显示他们。这将给我们的服务器带来很大的负担。还好，这个页面不会被频繁地修改，因此，我们可以用Rails提供的缓存方法。

由于开发环境Rails默认不开启缓存功能，所以我们要先打开缓存。编辑`config/environments/development.rb`文件，将`config.action_controller.perform_caching`设成`true`:

``` ruby
config.action_controller.perform_caching=true
```

为了让配置生效，我们需要重启服务器。

现在来规划下如何缓存页面。首先，当有新产品被添加或者旧产品被更新以后，我们页面的缓存应该更新，除此之外，缓存应该一直有效。如何实现这一点呢？还好Rails模型提供了一个魔法字段`updated_at`，每当有产品被新建或更新时候，Rails会自动改写这个属性，并保存到库中，我们就用他来实现吧。打开`app/models/product.rb`添加：

``` ruby
def self.latest
  Product.order(:updated_at).last
end
```

然后我们更新下模板，使用Rails提供的cache方法配合刚才自定义的方法实现缓存：

``` ruby
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
      </div>
     </li>
    <% end %>
  <% end %>
  </ul>
</div>
```

我们只要这样写就可以了。Rails会帮我们搞定其他的操作，比如选择什么样的方式存储缓存，缓存的数据何时更新，核实过期等等。是不是很方便？尽管我们做了这么多工作，但很不幸现在看不到太惊艳的效果。不过，当我们商城上线，有大量用户访问的时候你就知道缓存的威力了。为了方便后面的开发，我们还是把缓存配置改回来吧：

``` ruby
config.action_controller.perform_caching = false
```


##本章知识点

***

####1. Rails的路由

#####**Rails 路由的作用**

Rails 路由能识别 URL，将其分发给控制器的动作进行处理，还能生成路径和 URL，无需直接在视图中硬编码字符串。

**把 URL 和代码连接起来**

Rails 程序收到如下请求时

``` bash
GET /patients/17
```
会查询路由，找到匹配的控制器动作。如果首个匹配的路由是：

``` bash
get '/patients/:id', to: 'patients#show'
```
那么这个请求就交给 patients 控制器的 show 动作处理，并把 { id: '17' } 传入 params。

**生成路径和 URL**

通过路由还可生成路径和 URL。如果把前面的路由修改成：

``` bash
get '/patients/:id', to: 'patients#show', as: 'patient'
```

在控制器中有如下代码：

``` bash
@patient = Patient.find(17)
```

在相应的视图中有如下代码：

``` html
<%= link_to 'Patient Record', patient_path(@patient) %>
```

那么路由就会生成路径 /patients/17。这么做代码易于维护、理解。注意，在路由帮助方法中无需指定 ID。

#####**2. 资源路径（Resources）**

使用资源路径可以快速声明资源式控制器所有的常规路由，无需分别为 index、show、new、edit、create、update 和 destroy 动作分别声明路由，只需一行代码就能搞定。

**网络中的资源**

浏览器向 Rails 程序请求页面时会使用特定的 HTTP 方法，例如 GET、POST、PATCH、PUT 和 DELETE。每个方法对应对资源的一种操作。资源路由会把一系列相关请求映射到单个路由器的不同动作上。

如果 Rails 程序收到如下请求：

``` bash
DELETE /photos/17
```

会查询路由将其映射到一个控制器的路由上。如果首个匹配的路由是：

``` ruby
resources :photos
```

那么这个请求就交给 photos 控制器的 destroy 方法处理，并把 { id: '17' } 传入 params。

**CRUD，HTTP 方法和动作**

在 Rails 中，资源式路由把 HTTP 方法和 URL 映射到控制器的动作上。而且根据约定，还映射到数据库的 CRUD 操作上。路由文件中如下的单行声明：

``` ruby
resources :photos
```

会创建七个不同的路由，全部映射到 Photos 控制器上：

HTTP 方法 | 路径 | 控制器#动作 | 作用
--- | --- | --- | ---
GET | /photos | photos#index | 显示所有图片
GET | /photos/new | photos#new | 显示新建图片的表单
POST | /photos | photos#create | 新建图片
GET | /photos/:id | photos#show | 显示指定的图片
GET | /photos/:id/edit | photos#edit | 显示编辑图片的表单
PATCH/PUT | /photos/:id | photos#update | 更新指定的图片
DELETE | /photos/:id | photos#destroy | 删除指定的图片

> _注意！_

> 路由使用 HTTP 方法和 URL 匹配请求，把四个 URL 映射到七个不同的动作上。

> NOTE: 路由按照声明的顺序匹配哦，如果在 get 'photos/poll' 之前声明了 resources :photos，那么 show 动作的路由由 resources 这行解析。如果想使用 get 这行，就要将其移到 resources 之前。

**路径和 URL 帮助方法**

声明资源式路由后，会自动创建一些帮助方法。以 resources :photos 为例：

* photos_path 返回 /photos
* new_photo_path 返回 /photos/new
* edit_photo_path(:id) 返回 /photos/:id/edit，例如 edit_photo_path(10) 返回 /photos/10/edit
* photo_path(:id) 返回 /photos/:id，例如 photo_path(10) 返回 /photos/10

这些帮助方法都有对应的 _url 形式，例如 photos_url，返回主机、端口加路径。

**一次声明多个资源路由**

如果需要为多个资源声明路由，可以节省一点时间，调用一次 resources 方法完成：

``` ruby
resources :photos, :books, :videos
```

这种方式等价于：

``` ruby
resources :photos
resources :books
resources :videos
```

**单数资源**

有时希望不用 ID 就能查看资源，例如，/profile 一直显示当前登入用户的个人信息。针对这种需求，可以使用单数资源，把 /profile（不是 /profile/:id）映射到 show 动作：

``` ruby
get 'profile', to: 'users#show'
```

如果 get 方法的 to 选项是字符串，要使用 controller#action 形式；如果是 Symbol，就可以直接指定动作：

``` ruby
get 'profile', to: :show
```

下面这个资源式路由：

``` ruby
resource :geocoder
```

会生成六个路由，全部映射到 Geocoders 控制器

HTTP 方法 | 路径 | 控制器#动作 | 作用
--- | --- | --- | ---
GET | /geocoder/new | geocoders#new | 显示新建 geocoder 的表单
POST | /geocoder | geocoders#create | 新建 geocoder
GET | /geocoder | geocoders#show | 显示唯一的 geocoder 资源
GET | /geocoder/edit | geocoders#edit | 显示编辑 geocoder 的表单
PATCH/PUT | /geocoder | geocoders#update | 更新唯一的 geocoder 资源
DELETE | /geocoder | geocoders#destroy |ß 删除 geocoder 资源

单数资源式路由生成以下帮助方法：

* new_geocoder_path 返回 /geocoder/new
* edit_geocoder_path 返回 /geocoder/edit
* geocoder_path 返回 /geocoder

和复数资源一样，上面各帮助方法都有对应的 _url 形式，返回主机、端口加路径。

有个一直存在的问题导致 form_for 无法自动处理单数资源。为了解决这个问题，可以直接指定表单的 URL，例如：

``` ruby
form_for @geocoder, url: geocoder_path do |f|
```

**嵌套资源**

开发程序时经常会遇到一个资源是其他资源的子资源这种情况。假设程序中有如下的模型：

```ruby
class Magazine < ActiveRecord::Base
  has_many :ads
end

class Ad < ActiveRecord::Base
  belongs_to :magazine
end
```

在路由中可以使用“嵌套路由”反应这种关系。针对这个例子，可以声明如下路由：

``` ruby
resources :magazines do
  resources :ads
end
```

除了创建 MagazinesController 的路由之外，上述声明还会创建 AdsController 的路由。广告的 URL 要用到杂志资源：

HTTP 方法 | 路径 | 控制器#动作 | 作用
--- | --- | --- | ---
GET | /magazines/:magazine_id/ads | ads#index | 显示指定杂志的所有广告
GET | /magazines/:magazine_id/ads/new | ads#new | 显示新建广告的表单，该告属于指定的杂志
POST | /magazines/:magazine_id/ads | ads#create | 创建属于指定杂志的广告
GET | /magazines/:magazine_id/ads/:id | ads#show | 显示属于指定杂志的指定广告
GET | /magazines/:magazine_id/ads/:id/edit | ads#edit |  显示编辑广告的表单，该广告属于指定的杂志
PATCH/PUT | /magazines/:magazine_id/ads/:id | ads#update | 更新属于指定杂志的指定广告
DELETE | /magazines/:magazine_id/ads/:id | ads#destroy | 删除属于指定杂志的指定广告

上述路由还会生成 magazine\_ads\_url 和 edit\_magazine\_ad\_path 等路由帮助方法。这些帮助方法的第一个参数是 Magazine 实例，例如 magazine\_ads\_url(@magazine)。

**由对象创建路径和 URL**

除了使用路由帮助方法之外，Rails 还能从参数数组中创建路径和 URL。例如，假设有如下路由：

``` ruby
resources :magazines do
  resources :ads
end
```

使用 `magazine_ad_path` 时，可以不传入数字 ID，传入 Magazine 和 Ad 实例即可：

``` html
<%= link_to 'Ad details', magazine_ad_path(@magazine, @ad) %>
```

而且还可使用 `url_for` 方法，指定一组对象，Rails 会自动决定使用哪个路由：

``` html
<%= link_to 'Ad details', url_for([@magazine, @ad]) %>
```

此时，Rails 知道 @magazine 是 Magazine 的实例，@ad 是 Ad 的实例，所以会调用 `magazine_ad_path` 帮助方法。使用 `link_to` 等方法时，无需使用完整的 `url_for` 方法，直接指定对象即可：

```html
<%= link_to 'Ad details', [@magazine, @ad] %>
```

如果想链接到一本杂志，可以这么做：

``` html
<%= link_to 'Magazine details', @magazine %>
```

要想链接到其他动作，把数组的第一个元素设为所需动作名即可：

``` html
<%= link_to 'Edit Ad', [:edit, @magazine, @ad] %>
```

在这种用法中，会把模型实例转换成对应的 URL，这是资源式路由带来的主要好处之一。

**添加更多的 REST 架构动作**

可用的路由并不局限于 REST 路由默认创建的那七个，还可以添加额外的集合路由或成员路由。

**添加成员路由**

要添加成员路由，在 resource 代码块中使用 member 块即可：

``` ruby
resources :photos do
  member do
    get 'preview'
  end
end
```

这段路由能识别 `/photos/1/preview`是个 GET 请求，映射到 `PhotosController` 的 `preview` 动作上，资源的 ID 传入 params[:id]。同时还生成了 `preview_photo_url` 和 `preview_photo_path` 两个帮助方法。

在 member 代码块中，每个路由都要指定使用的 HTTP 方法。可以使用 get，patch，put，post 或 delete。如果成员路由不多，可以不使用代码块形式，直接在路由上使用 :on 选项：

``` ruby
resources :photos do
  get 'preview', on: :member
end
```

也可以不使用 :on 选项，得到的成员路由是相同的，但资源 ID 存储在 params[:photo_id] 而不是 params[:id] 中。

**添加集合路由**

添加集合路由的方式如下：

``` ruby
resources :photos do
  collection do
    get 'search'
  end
end
```

这段路由能识别 `/photos/search` 是个 GET 请求，映射到 `PhotosController` 的 `search` 动作上。同时还会生成 `search_photos_url` 和 `search_photos_path`两个帮助方法。

和成员路由一样，也可使用 :on 选项：

``` ruby
resources :photos do
  get 'search', on: :collection
end
```

**添加额外新建动作的路由**

要添加额外的新建动作，可以使用 :on 选项：

``` ruby
resources :comments do
  get 'preview', on: :new
end
```

这段代码能识别  `/comments/new/preview` 是个 GET 请求，映射到 `CommentsController` 的 `preview` 动作上。同时还会生成 `preview_new_comment_url` 和 `preview_new_comment_path` 两个路由帮助方法。

> 注意:

> 如果在资源式路由中添加了过多额外动作，这时就要停下来问自己，是不是要新建一个资源

**定制资源式路由**

虽然 resources :posts 默认生成的路由和帮助方法都满足大多数需求，但有时还是想做些定制。Rails 允许对资源式帮助方法做几乎任何形式的定制。

**指定使用的控制器**

:controller 选项用来指定资源使用的控制器。例如：

``` ruby
resources :photos, controller: 'images'
```

能识别以 /photos 开头的请求，但交给 Images 控制器处理：

HTTP 方法 | 路径 | 控制器#动作 | 作用
--- | --- | --- | ---
GET | /photos | images#index | photos_path
GET | /photos/new | images#new | new_photo_path
POST | /photos | images#create | photos_path
GET | /photos/:id | images#show | photo_path(:id)
GET | /photos/:id/edit | images#edit | edit_photo_path(:id)
PATCH/PUT | /photos/:id | images#update | photo_path(:id)
DELETE | /photos/:id | images#destroy | photo_path(:id)

#####**非资源式路由**

除了资源路由之外，Rails 还提供了强大功能，把任意 URL 映射到动作上。此时，不会得到资源式路由自动生成的一系列路由，而是分别声明各个路由。

虽然一般情况下要使用资源式路由，但也有一些情况使用简单的路由更合适。如果不合适，也不用非得使用资源实现程序的每种功能。

简单的路由特别适合把传统的 URL 映射到 Rails 动作上。

**绑定参数**

声明常规路由时，可以提供一系列 Symbol，做为 HTTP 请求的一部分，传入 Rails 程序。其中两个 Symbol 有特殊作用：:controller 映射程序的控制器名，:action 映射控制器中的动作名。例如，有下面的路由：

``` ruby
get ':controller(/:action(/:id))'
```

如果 `/photos/show/1` 由这个路由处理（没匹配路由文件中其他路由声明），会映射到 `PhotosController` 的 `show` 动作上，最后一个参数 "1" 可通过 `params[:id]` 获取。上述路由还能处理 `/photos` 请求，映射到 `PhotosController#index`，因为 `:action` 和 `:id `放在括号中，是可选参数。

**动态路径片段**

在常规路由中可以使用任意数量的动态片段。:controller 和 :action 之外的参数都会存入 params 传给动作。如果有下面的路由：

``` ruby
get ':controller/:action/:id/:user_id'
```

`/photos/show/1/2` 请求会映射到 `PhotosController` 的 `show` 动作。params[:id] 的值是 "1"，params[:user_id] 的值是 "2"。

**静态路径片段**

声明路由时可以指定静态路径片段，片段前不加冒号即可：

``` ruby
get ':controller/:action/:id/with_user/:user_id'
```

这个路由能响应 `/photos/show/1/with_user/2`这种路径。此时，params 的值为 { controller: 'photos', action: 'show', id: '1', user_id: '2' }。

**查询字符串**

params 中还包含查询字符串中的所有参数。例如，有下面的路由：

``` ruby
get ':controller/:action/:id'
```

`/photos/show/1?user_id=2` 请求会映射到 Photos 控制器的 show 动作上。params 的值为 { controller: 'photos', action: 'show', id: '1', user_id: '2' }。

**定义默认值**

在路由中无需特别使用 `:controller` 和 `:action`，可以指定默认值：

``` ruby
get 'photos/:id', to: 'photos#show'
```

这样声明路由后，Rails 会把 `/photos/12` 映射到 `PhotosController` 的 `show` 动作上。

路由中的其他部分也使用 `:defaults `选项设置默认值。甚至可以为没有指定的动态路径片段设定默认值。例如：

``` ruby
get 'photos/:id', to: 'photos#show', defaults: { format: 'jpg' }
```

Rails 会把 `photos/12` 请求映射到 `PhotosController` 的 `show` 动作上，把 params[:format] 的值设为 "jpg"。

**命名路由**

使用 `:as` 选项可以为路由起个名字：

``` ruby
get 'exit', to: 'sessions#destroy', as: :logout
```

这段路由会生成 `logout_path` 和 `logout_url` 这两个具名路由帮助方法。调用 logout_path 方法会返回 /exit。

使用 `:as` 选项还能重设资源的路径方法，例如：

``` ruby
get ':username', to: 'users#show', as: :user
```

这段路由会定义一个名为 `user_path` 的方法，可在控制器、帮助方法和视图中使用。在 `UsersController` 的 `show` 动作中，params[:username] 的值即用户的用户名。如果不想使用 `:username` 作为参数名，可在路由声明中修改。

**HTTP 方法约束**

一般情况下，应该使用 get、post、put、patch 和 delete 方法限制路由可使用的 HTTP 方法。如果使用 match 方法，可以通过 `:via` 选项一次指定多个 HTTP 方法：

``` ruby
match 'photos', to: 'photos#show', via: [:get, :post]
```

如果某个路由想使用所有 HTTP 方法，可以使用 `via: :all`：

``` ruby
match 'photos', to: 'photos#show', via: :all
```
> 注意！

> 同个路由即处理 GET 请求又处理 POST 请求有安全隐患。一般情况下，除非有特殊原因，切记不要允许在一个动作上使用所有 HTTP 方法。

**使用 root**

使用 root 方法可以指定怎么处理 '/' 请求：

``` ruby
root to: 'pages#main'
root 'pages#main' # shortcut for the above
```

root 路由应该放在文件的顶部，因为这是最常用的路由，应该先匹配。

> 注意！ root 路由只处理映射到动作上的 GET 请求。

####2. Rails缓存基础

本节介绍三种缓存技术：页面，动作和片段。Rails 默认支持片段缓存。如果想使用页面缓存和动作缓存，要在 Gemfile 中加入 `actionpack-page_caching 和 actionpack-action_caching`。

在开发环境中若想使用缓存，要把 `config.action_controller.perform_caching` 选项设为 `true`。这个选项一般都在各环境的设置文件（config/environments/*.rb）中设置，在开发环境和测试环境默认是禁用的，在生产环境中默认是开启的。

``` ruby
config.action_controller.perform_caching = true
```
**页面缓存**

页面缓存机制允许网页服务器（Apache 或 Nginx 等）直接处理请求，不经 Rails 处理。这么做显然速度超快，但并不适用于所有情况（例如需要身份认证的页面）。服务器直接从文件系统上读取文件，所以缓存过期是一个很棘手的问题。

> 注意！

> Rails 4 删除了对页面缓存的支持，如想使用就得安装 actionpack-page_caching gem。

**动作缓存**

如果动作上有前置过滤器就不能使用页面缓存，例如需要身份认证的页面，这时需要使用动作缓存。动作缓存和页面缓存的工作方式差不多，但请求还是会经由 Rails 处理，所以在读取缓存之前会执行前置过滤器。使用动作缓存可以执行身份认证等限制，然后再从缓存中取出结果返回客户端。

> 注意！

> Rails 4 删除了对动作缓存的支持，如想使用就得安装 actionpack-action_caching gem。

**片段缓存**

如果能缓存整个页面或动作的内容，再读取给客户端，这个世界就完美了。但是，动态网页程序的页面一般都由很多部分组成，使用的缓存机制也不尽相同。在动态生成的页面中，不同的内容要使用不同的缓存方式和过期日期。为此，Rails 提供了一种缓存机制叫做“片段缓存”。

片段缓存把视图逻辑的一部分打包放在 cache 块中，后续请求都会从缓存中读取这部分内容。

例如，如果想实时显示网站的订单，而且不想缓存这部分内容，但想缓存显示所有可选商品的部分，就可以使用下面这段代码：

``` html
<% Order.find_recent.each do |o| %>
  <%= o.buyer.name %> bought <%= o.product.name %>
<% end %>

<% cache do %>
  All available products:
  <% Product.all.each do |p| %>
    <%= link_to p.name, product_url(p) %>
  <% end %>
<% end %>
```

上述代码中的 cache 块会绑定到调用它的动作上，输出到动作缓存的所在位置。因此，如果要在动作中使用多个片段缓存，就要使用 action_suffix 为 cache 块指定前缀：

``` html
<% cache(action: 'recent', action_suffix: 'all_products') do %>
  All available products:
```

expire_fragment 方法可以把缓存设为过期，例如：

``` html
expire_fragment(controller: 'products', action: 'recent', action_suffix: 'all_products')
```

如果不想把缓存绑定到调用它的动作上，调用 cahce 方法时可以使用全局片段名：

``` ruby
<% cache('all_available_products') do %>
  All available products:
<% end %>
```

在 ProductsController 的所有动作中都可以使用片段名调用这个片段缓存，而且过期的设置方式不变：

``` ruby
expire_fragment('all_available_products')
```

如果不想手动设置片段缓存过期，而想每次更新商品后自动过期，可以定义一个帮助方法：

``` ruby
module ProductsHelper
  def cache_key_for_products
    count          = Product.count
    max_updated_at = Product.maximum(:updated_at).try(:utc).try(:to_s, :number)
    "products/all-#{count}-#{max_updated_at}"
  end
end
```

这个方法生成一个缓存键，用于所有商品的缓存。在视图中可以这么做：

``` ruby
<% cache(cache_key_for_products) do %>
  All available products:
<% end %>
```

如果想在满足某个条件时缓存片段，可以使用 cache_if 或 cache_unless 方法：

``` ruby
<% cache_if (condition, cache_key_for_products) do %>
  All available products:
<% end %>
```

缓存的键名还可使用 Active Record 模型：

``` ruby
<% Product.all.each do |p| %>
  <% cache(p) do %>
    <%= link_to p.name, product_url(p) %>
  <% end %>
<% end %>
```

Rails 会在模型上调用 `cache_key` 方法，返回一个字符串，例如 `products/23-20130109142513`。键名中包含模型名，ID 以及 `updated_at`字段的时间戳。所以更新商品后会自动生成一个新片段缓存，因为键名变了。

上述两种缓存机制还可以结合在一起使用，这叫做“俄罗斯套娃缓存”（Russian Doll Caching）：

``` ruby
<% cache(cache_key_for_products) do %>
  All available products:
  <% Product.all.each do |p| %>
    <% cache(p) do %>
      <%= link_to p.name, product_url(p) %>
    <% end %>
  <% end %>
<% end %>
```

之所以叫“俄罗斯套娃缓存”，是因为嵌套了多个片段缓存。这种缓存的优点是，更新单个商品后，重新生成外层片段缓存时可以继续使用内层片段缓存。

**底层缓存**

有时不想缓存视图片段，只想缓存特定的值或者查询结果。Rails 中的缓存机制可以存储各种信息。

实现底层缓存最有效地方式是使用 `Rails.cache.fetch` 方法。这个方法既可以从缓存中读取数据，也可以把数据写入缓存。传入单个参数时，读取指定键对应的值。传入代码块时，会把代码块的计算结果存入缓存的指定键中，然后返回计算结果。

以下面的代码为例。程序中有个 `Product` 模型，其中定义了一个实例方法，用来查询竞争对手网站上的商品价格。这个方法的返回结果最好使用底层缓存：

``` ruby
class Product < ActiveRecord::Base
  def competing_price
    Rails.cache.fetch("#{cache_key}/competing_price", expires_in: 12.hours) do
      Competitor::API.find_price(id)
    end
  end
end
```
> 注意，在这个例子中使用了 cache_key 方法，所以得到的缓存键名是这种形式：products/233-20140225082222765838000/competing_price。cache_key 方法根据模型的 id 和 updated_at 属性生成键名。这是最常见的做法，因为商品更新后，缓存就失效了。一般情况下，使用底层缓存保存实例的相关信息时，都要生成缓存键。

#####**3. Rails是如何处理 i18n(Internationalization) 的**

国际化是个很复杂的问题。自然语言千差万别（例如复数变形规则），很难提供一种工具解决所有问题。因此，Rails I18n API 只关注：

* 默认支持和英语类似的语言；
* 让支持其他语言变得简单；

Rails 框架中的每个静态字符串（例如，Active Record 数据验证消息，日期和时间的格式）都支持国际化，因此本地化时只要重写默认值即可。

**公开 API**
I18n API 最重要的方法是：

```ruby
translate # Lookup text translations
localize  # Localize Date and Time objects to local formats
```

这两个方法都有别名，分别为 #t 和 #l。因此可以这么用：

```ruby
I18n.t 'store.title'
I18n.l Time.now
```

I18n API 同时还提供了针对下述属性的读取和设值方法：

``` ruby
load_path         # Announce your custom translation files
locale            # Get and set the current locale
default_locale    # Get and set the default locale
exception_handler # Use a different exception_handler
backend           # Use a different backend```
```


**配置 I18n 模块**

按照“约定优于配置”原则，Rails 会为程序提供一些合理的默认值。如果想使用其他设置，可以很容易的改写默认值。

Rails 会自动把 config/locales 文件夹中所有 .rb 和 .yml 文件加入译文加载路径。

默认提供的 en.yml 文件中包含一些简单的翻译文本：

``` yaml
en:
  hello: "Hello world"
```

上面这段代码的意思是，在 `:en` 语言中，hello 键映射到字符串 "Hello world" 上。Rails 中的每个字符串的国际化都使用这种方式，比如说 Active Model 数据验证消息以及日期和时间格式。在默认的后台中，可以使用 YAML 或标准的 Ruby Hash 存储翻译数据。

I18n 库使用的默认语言是英语，所以如果没设为其他语言，就会用 `:en` 查找翻译数据。

> 经过讨论之后，i18n 库决定为语言名称使用一种务实的方案，只说明所用语言（例如，:en，:pl），不区分地区（例如，:en-US，:en-GB）。地区经常用来区分同一语言在不同地区的分支或者方言。很多国际化程序只使用语言名称，例如 :cs、:th 和 :es（分别为捷克语，泰语和西班牙语）。不过，同一语种在不同地区可能有重要差别。例如，在 :en-US 中，货币符号是“$”，但在 :en-GB 中是“£”。在 Rails 中使用区分地区的语言设置也是可行的，只要在 :en-GB 中使用完整的“English - United Kingdom”即可。很多 Rails I18n 插件，例如 Globalize3，都可以实现。

译文加载路径（I18n.load_path）是一个 Ruby 数组，由译文文件的路径组成，Rails 程序会自动加载这些文件。你可以使用任何一个文件夹，任何一种文件命名方式。

首次加载查找译文时，后台会惰性加载这些译文。这么做即使已经声明过，也可以更换所用后台。

application.rb 文件中的默认内容有介绍如何从其他文件夹中添加本地数据，以及如何设置默认使用的语言。去掉相关代码行前面的注释，修改即可。

``` ruby
# The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
# config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
# config.i18n.default_locale = :de
```

**更改 I18n 库的设置**

如果基于某些原因不想使用 application.rb 文件中的设置，我们来介绍一下手动设置的方法。

告知 I18n 库在哪里寻找译文文件，可以在程序的任何地方指定加载路径。但要保证这个设置要在加载译文之前执行。我们可能还要修改默认使用的语言。要完成这两个设置，最简单的方法是把下面的代码放到一个初始化脚本中：

``` ruby
# in config/initializers/locale.rb

# tell the I18n library where to find your translations
I18n.load_path += Dir[Rails.root.join('lib', 'locale', '*.{rb,yml}')]

# set default locale to something other than :en
I18n.default_locale = :pt
```

##扩展阅读

***

1. 控制器命名空间、scope路由等 [http://guides.rubyonrails.org/routing.html](http://guides.rubyonrails.org/routing.html)

2. 缓存 [http://guides.rubyonrails.org/caching_with_rails.html](http://guides.rubyonrails.org/caching_with_rails.html)

