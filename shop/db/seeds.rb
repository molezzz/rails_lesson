# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

Product.delete_all

Product.create!(
 title: '华为 荣耀3C （白色）3G手机 TD-SCDMA/GSM 双卡双待 2G RAM 套装版 ',
 description:
 %{
 <p>四核/5寸大屏/1G+4G内存/双卡双待/800万像素 </p>
 },
 image_url: '/images/phone_3c.jpg',
 price: 899.00
)

Product.create!(
  title: '努比亚（nubia） 小牛2 Z5S mini 3G手机（白色） WCDMA/TD-SCDMA/EVDO',
  description: %{
    <p>
    4.7”夏普最新IGZO屏 幕
全球首款采用夏普IGZO 高性能显示屏技术智能手机，使得显示屏功耗大大降低，但在显示效果上却依然出色，保持了高透亮、色彩鲜明以及更快响应的特点。</p>
  },
  image_url: '/images/phone_nubia.jpg',
  price: 1499
)
Product.create!(
  title: '华为 荣耀 畅玩版（白色）真8核 移动版 TD-SCDMA/GSM 双卡双待 豪华套装版',
  description: %{
    <p>
    5.5英寸高清巨屏，移动+联通双3G，1300万像素摄像头，3000mAh大容量电池，真8核，长续航，飙机王！！</p>
  },
  image_url: '/images/phone_3x.jpg',
  price: 1299
)