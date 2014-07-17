# -*- coding: utf-8 -*-

s = [
  'a string',
  "another string",
  "第一行\n第二行",
  "现在的时间是：#{Time.now}"
]

#多行文本
s << %/
  床前名月光，
  疑是地上霜
/
moon = '明月'
homeland = '故乡'
s << %Q{
  举头望#{moon}
}
s <<  %q{
  低头思#{homeland}
}
s << <<TPL
  这是\t使用here document
  创建的文本
TPL
s << <<'TPL'
  这里的特殊符号\n不会被替换
TPL

s.each_with_index do |str,index|
  puts "#{index}. -----------------"
  puts str
end