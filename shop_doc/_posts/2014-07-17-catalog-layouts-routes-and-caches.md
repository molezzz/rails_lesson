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
Shop::Application.routes.draw do
 get "store/index"
 resources :products

 root 'store#index', as: 'store'
 #...
end
```



