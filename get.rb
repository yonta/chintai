#!/usr/bin/env ruby
# frozen_string_literal: true

require "open-uri"
require "nokogiri"

# test input
url = "https://www.homes.co.jp/chintai/b-1028850275072/"
html = URI.parse(url).open.read
doc = Nokogiri::HTML.parse(html)

# name
name_base = doc.at_css(".bukkenHead .heading .bukkenName")&.text&.strip
name_ext = doc.at_css(".bukkenHead .heading .bukkenRoom")&.text&.strip
name = "#{name_base} #{name_ext}"

# address
address = doc.at_css(".bukkenSpec .rentLocation #chk-bkc-fulladdress")&.text&.strip&.split("\n")&.first

# rental fee
rent = doc.at_css(".bukkenSpec #chk-bkc-moneyroom")&.text&.strip
rent_match = rent&.match(/(?<base>[\d\.]+)万円 \( (?<ext>[\d,]+)円 \)/)
rent_base = rent_match[:base].to_f
rent_ext = rent_match[:ext].delete(",").to_f
rent_total = rent_base + rent_ext * 0.0001

# floor area
floor_area = doc.at_css(".bukkenSpec #chk-bkc-housearea")&.text&.strip.match(/(?<area>[\d\.]+)m²/)[:area]

# floor plan
floors = doc.at_css(".bukkenSpec #chk-bkc-marodi")&.text&.strip
floor_plan = floors&.split("\n").first
floor_ldk = floors.match(/リビングダイニングキッチン\s*(?<ldk>[\d\.]+)帖/)[:ldk].to_f
floor_rooms = floors.match(/洋室\s*(?<room1>[\d\.]+)帖.*洋室\s*(?<room2>[\d\.]+)帖/m)
floor_room1 = floor_rooms[:room1]
floor_room2 = floor_rooms[:room2]

print "#{name},,,#{url},#{address},,,,#{rent_total},#{floor_area},#{floor_ldk},#{floor_room1},,#{floor_room2}\n"
