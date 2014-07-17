# -*- coding: utf-8 -*-

class Pet
    #姓名是可以读写的
    attr_accessor :name
    #性别是只读的
    attr_reader :gender
    #年龄是可写的
    attr_writer :age

    def self.get_pet(type = :cat)
      klass = {:cat => Cat,:dog => Dog}[type]
      klass.nil? ? nil : klass.new
    end

    def initialize(owner='someone')
      @owner = owner
      #随机生成性别
      @gender = ['雌性','雄性'][rand(2)]
      @age = 0
      new_pet
      puts "主人：#{@owner},#{gender},#{@age}岁,#{self.class.name}"
    end

    def say(word)
      puts "Say: #{word}"
    end

    def eat(food)
      puts "#{name} 吃 #{food}"
    end

    def dance
      print_status '跳舞'
    end

    protected
    def print_status(status)
      puts "#{name} 正在 #{status}"
    end

    private
    def new_pet
      puts '一个新宠物创建了！'
    end
end

class Cat < Pet
    def say(word)
        puts "Meow~"
        super
    end

end

class Dog < Pet
    def say(word, person)
        puts "Bark at #{person}!"
        super(word)
    end

    def new_dog
      # Private methods cannot be called with an explicit receiver.

      # 私有方法无法指定receiver(消息接收者), 或者按照另一种说法: 无法指定方法
      # 调用者, 也就是说只能隐式的通过self被调用!!. 只有这一种方式, 无它.
      begin
        self.new_pet
        #但是直接使用 new_pet 是可以的
      rescue Exception => e
        puts e
      end
    end
end

#类方法调用
Pet.get_pet(:dog)

cat = Cat.new('我')
dog = Dog.new

#给宠物指定名字
cat.name = '奥巴马'
dog.name = '金正恩'
puts [cat.name,dog.name]
#只读 只写方法
cat.age = 1
begin
  #读取只写属性会抛出异常
  puts cat.age
rescue Exception => e
  puts e
end
puts "#{cat.class.name}性别：#{cat.gender}"
begin
  #修改只读属性也会引发异常
  cat.gender = '男'
rescue Exception => e
  puts e
end
#方法可见性
#方法默认是public的
dog.eat('骨头')
#protected方法是不能在外部调用的
begin
  dog.print_status('喝水')
rescue Exception => e
  puts e
end
#但是子类的方法中可以调用
dog.dance
#private方法在子类方法中也不能被调用
dog.new_dog
#方法覆盖
cat.say("Hi")
dog.say("Hi", "ihower")

module M
  N = 1
  def common
    puts "From module"
  end
end

class C
  include M

  def self.foo
    puts N
  end

  class << self
    def bar
      puts N
    end
  end
end

C.new.common
C.foo
C.bar

=begin
练习
=======================================
使用类完成一个存放图书的书架

书架：
  具有存入和取出书的功能
  书架能够统计当前存放了多少本书，以及他们的总价值

书：
  所有类别的书都包含 ISBN 、价格和出版时间
  有些类别的书，比如编程书籍，带有光盘
  每本书都能够将自己的价格转换成“分”的形式表示
  所有书都能够通过“to_s”方法，将自己转换成可读的字符串信息，
    普通书籍格式： "ISBN:xxxx 价格:xxxx 出版时间：xxxx-xx-xx"
    带光盘的书格式： "ISBN:xxxx 价格:xxxx 出版时间：xxxx-xx-xx 光盘：x张"

已有的书籍数据

"出版日期",   "ISBN",             "价格"  "光盘"
"2014-05-15","978-1-9343561-0-4","39.45",  无
"2014-05-11","978-1-9343561-6-6","45.76",  无
"2014-03-15","978-1-9343561-7-4","30. 15", 3张
"2012-06-02","978-1-9343231-0-5","80",     2张

提示：
  使用类的继承和方法的覆盖来完成普通书与编程书在输出时的区分。


=end