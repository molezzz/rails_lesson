# -*- coding: utf-8 -*-


total = 26000

if total > 100000
  puts "large account"
elsif total > 25000
  puts "medium account"
else
  puts "small account"
end

class Pallet

  def weight
    @weight.to_i
  end

  def weight=(w)
    @weight = w
  end

end

pallets = []
50.times do |i|
  p = Pallet.new
  p.weight = rand(20)
  pallets << p
end

def next_pallet(pallets)
  pallets.pop
end

num_pallets = 20
weight = 20
while weight < 100 and num_pallets <= 30
  pallet = next_pallet(pallets)
  puts "这次托盘的总量：#{pallet.weight},当前总重：#{weight}，已有#{num_pallets}个托盘"
  weight += pallet.weight
  num_pallets += 1
end

#条件表达式的真值情况

puts "not execute" if nil
puts "not execute" if false

puts "execute" if true # 输出 execute
puts "execute" if "" # 输出 execute (和JavaScript不同)
puts "execute" if 0 # 输出 execute (和C不同)
puts "execute" if 1 # 输出 execute
puts "execute" if "foo" # 输出 execute
puts "execute" if Array.new # 输出 execute


#练习，将1到100的数存入一个数组