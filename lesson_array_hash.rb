# -*- coding: utf-8 -*-

a = [1,'cat',3.14]   #新建一个包含3个元素的数组
puts "原始数组：#{a}"
puts 'a[0]的值是：'
puts a[0]           #访问数组第一个元素 “1”
a[2] = nil          #设置数组第3个元素为nil
                    #修改后的数组为 [1,'cat',nil]

puts "修改后的数组：#{a}"
a << 'hello'
puts "插入后的数组：#{a}"

 animal = %w{ ant bee cat dog elk }
 puts "animal: #{animal}"

#hash 演示
inst_section = {
  :cello  => 'string',
  :clarinet  => 'woodwind',
  :drum  => 'percussion'
}

puts inst_section

inst_section = {
  cello: 'string',
  clarinet:  'woodwind',
  drum:  'percussion'
}
puts inst_section

#hash通过键来访问
puts ":clarinet -> #{inst_section[:clarinet]}"  #=>'woodwind'
puts ":bassoon -> #{inst_section[:bassoon]}"    #=> nil
