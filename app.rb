require 'httpclient'
require 'time'
require 'date'
require 'json'
require 'mysql2'
client = HTTPClient.new
# client.debug_dev = $stderr    # デバッグ情報を標準エラー出力に

# DB接続
connection = Mysql2::Client.new(
  host: "db_1",
  username: "root",
  password: "password",
  database: ""
)
# 文字コードをUTF8に設定
connection.query("set character set utf8")

# DB database,tableの作成（初回のみ）
rs1 = connection.query("create database if not exists nanatomaru")
rs2 = connection.query("create table if not exists nanatomaru.gradone_shichijo(id int auto_increment not null primary key, checkin_date datetime, charge int, plan_name varchar(255), room_name varchar(255) ,create_date datetime)")

next_date = Date.today #日程の初期設定
# next_date = next_date.next_day(31) #日程の初期設定


(1..31).each{|e|

  puts "#{e*100/31}%"

  # チェックイン、チェックアウトを定義
  date = next_date #今日の日付を取得
  next_date = date.next_day(1) #次の日付を取得

  # 取得データのパラメータ定義
  query = {
    'format' => 'json',
    'checkinDate' => date.strftime('%Y-%m-%d'),
    'checkoutDate' => next_date.strftime('%Y-%m-%d'),
    'hotelNo' => 161270, # グラッドワン七条
    # 'hotelNo' => 129931, # グラッドワン南大阪
    'affiliateId' => '17dbb631.8d9082f7.17dbb632.6ded7d8f',
    'adult' => '2',
    'applicationId' => '1048946354508105385'
  }

  # 1日分のデータを取得
  res = client.get('https://app.rakuten.co.jp/services/api/Travel/VacantHotelSearch/20170426', :query => query, :follow_redirect => true)

  # データの整形
  response = JSON.parse(res.body)

  # puts response

  while response["error"] == "too_many_requests" do
    # 0.9秒止める
    sleep(0.9)
    # 再度1日分のデータを取得
    res = client.get('https://app.rakuten.co.jp/services/api/Travel/VacantHotelSearch/20170426', :query => query, :follow_redirect => true)
    # データの整形
    response = JSON.parse(res.body)
  end

  # データが無ければNULLで登録し、以降の処理をせず次の日の処理に進む
  if response["error"] == "not_found" then
    rs3 = connection.query("insert into nanatomaru.gradone_shichijo( checkin_date, create_date) value( '#{date.strftime('%Y-%m-%d')}', '#{Time.now.strftime('%Y-%m-%d %H:%M:%S')}')")
    next
  end

  info = response["hotels"][0]["hotel"].drop(1)

  info.each {|element|
    # 1日分のデータを表示
    # data = []
    # data.push(element["roomInfo"][1]["dailyCharge"]["stayDate"]) # 宿泊日
    # data.push(element["roomInfo"][1]["dailyCharge"]["total"]) # 価格
    # data.push(element["roomInfo"][0]["roomBasicInfo"]["planName"]) # プラン名
    # data.push(element["roomInfo"][0]["roomBasicInfo"]["roomName"]) # 部屋名

    # 1日分のデータを保存
    rs3 = connection.query("insert into nanatomaru.gradone_shichijo( checkin_date, charge, plan_name, room_name, create_date) value( '#{element["roomInfo"][1]["dailyCharge"]["stayDate"]}', #{element["roomInfo"][1]["dailyCharge"]["total"]}, '#{element["roomInfo"][0]["roomBasicInfo"]["planName"]}', '#{element["roomInfo"][0]["roomBasicInfo"]["roomName"]}', '#{Time.now.strftime('%Y-%m-%d %H:%M:%S')}')")
  }
}
# コネクションを閉じる
connection.close
