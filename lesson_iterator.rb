# -*- coding: utf-8 -*-

languages = ['Ruby', 'Javascript', 'Perl']
languages.each do |lang|
    puts "I love #{lang}!"
end
#带索引的迭代
languages.each_with_index do |lang, i|
    puts "#{i}, I love #{lang}!"
end

# 反覆三次
3.times do
    puts 'Good Job!'
end

1.upto(9) { |x| puts x }

# 迭代并造出另一个数组
puts '迭代并造出另一个数组:'
a = [ "a", "b", "c", "d" ]
b = a.map {|x| x + "!" }
puts b.inspect


# 找出符合条件的值
puts '找出符合条件的值'
b = [1,2,3].find_all{ |x| x % 2 == 0 }
puts b.inspect


# 迭代并根据条件删除
puts '迭代并根据条件删除'
a = [51, 101, 256]
a.delete_if {|x| x >= 100 }
puts a



# 降序排序
puts '降序排序'
puts [2,1,3].sort! { |a, b| b <=> a }
#<=>是比较运算符，两边数字相等返回0，第一个数字较大返回1，反之返回-1


# 计算总和
puts '计算总和'
puts (5..10).inject {|sum, n| sum + n }

# 找出最长字串
puts '找出最长字串'
longest = ["cat", "sheep", "bear"].inject do |memo,word|
    ( memo.length > word.length )? memo : word
end
puts longest
