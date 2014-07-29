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

在文件的上半部分，我们可以看到由Rails自动生成的store和products的路由配置。在“resources :products”下添加 “root 'store#index', as: 'store'”将网站的首页指向store控制器。“as: 'store'”表示让rails生成“ store_path”方法，以便在视图中调用。现在，在浏览器中直接输入“http://localhost:3000/”，你会发现，默认的首页已经变成我们指定的“store/index”了：


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


    li {
      min-height: 10em;
    }

    img {
      width: 100px;
      margin: 0.2em auto 0.2em;
      position: absolute;
      left: 2em;
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
  background: #9c9;
  padding: 10px;
  border-bottom: 2px solid;
  font: small-caps 40px/40px "Times New Roman", serif;
  color: #282;
  text-align: center;

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
  background: #141;

  #main {
    margin-left: 17em;
    padding: 1em;
    background: white;
  }

  #side {
    float: left;
    padding: 1em 2em;
    width: 13em;
    background: #141;

    ul {
      padding: 0;
      li {
        list-style: none;
        a {
          color: #bfb;
          font-size: small;
        }
      }
    }
  }
}
```