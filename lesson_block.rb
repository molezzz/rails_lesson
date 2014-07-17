# -*- coding: utf-8 -*-

#{ puts 'hello'}   # 这是一个块

# do                       ###
#   club.enroll(person)    # 这也是一个块
#   person.socialize       #
# end

animals = %w( ant bee cat dog elk ) #创建数组
animals.each { | animal | puts animal } #迭代并输出数组中的内容

# yield 演示
def call_block
    puts "Start"
    yield
    yield
    puts "End"
end

call_block { puts "Blocks are cool!" }

# &符号演示
def wrap &b
  3.times(&b)
end

wrap { puts 'hello'}