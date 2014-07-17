# -*- coding: utf-8 -*-

begin
    puts 10 / 0 # 引发 ZeroDivisionError 异常
rescue RuntimeError
    puts 'someting is wrong'
rescue => e
    puts e.class # 如果发生异常 rescue 这一段
rescue Exception => e #异常是自上而下捕获的，这段放在上面会发生什么？
    puts e
ensure
    # 无论有沒有发生异常，ensure 这一段都一定会执行
    # 一般会在这里执行资源清理或者关闭打开的文件等操作
end

# 抛出一个 RuntimeError 异常
raise 'Not works!!'


# 自定义异常
class MyException < RuntimeError
end

raise MyException