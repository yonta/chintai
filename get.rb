#!/usr/bin/env ruby
# frozen_string_literal: true

require "open-uri"
require "nokogiri"

def is_homes?(url)
  url.include?("homes.co.jp")
end

def is_shamaison?(url)
  url.include?("shamaison.com")
end

def get_commute_time(address)
  address = "東京都足立区南花畑2丁目"
  params = URI.encode_www_form([["to", "築地小山ビル"],
                                ["from", address],
                                ["y", "2023"],
                                ["m", "05"],
                                ["d", "09"],
                                ["hh", "10"],
                                ["m1", "0"],
                                ["m2", "0"],
                                ["type", "1"],
                                ["ticket", "ic"],
                                ["expkind", "1"],
                                ["userpass", "1"],
                                ["ws", "2"],
                                ["s", "0"],
                                ["al", "1"],
                                ["shin", "1"],
                                ["ex", "1"],
                                ["hb", "1"],
                                ["lb", "1"],
                                ["sr", "1"]])
  url = "https://transit.yahoo.co.jp/search/result?#{params}"
  html = URI.parse(url).open.read
  doc = Nokogiri::HTML.parse(html)

  doc.at_css(".routeList .time .small")&.text&.strip&.match(/(?<commute>\d+)分/)[:commute]
end

def homes_to_line(url)
  html = URI.parse(url).open.read
  doc = Nokogiri::HTML.parse(html)

  name_base = doc.at_css(".bukkenHead .heading .bukkenName")&.text&.strip
  name_ext = doc.at_css(".bukkenHead .heading .bukkenRoom")&.text&.strip
  name = "#{name_base} #{name_ext}"

  address = doc.at_css(".bukkenSpec .rentLocation #chk-bkc-fulladdress")&.text&.strip&.split("\n")&.first

  rent = doc.at_css(".bukkenSpec #chk-bkc-moneyroom")&.text&.strip
  rent_match = rent&.match(/(?<base>[\d\.]+)万円 \( (?<ext>[\d,]+)円 \)/)
  rent_base = rent_match[:base].to_f
  rent_ext = rent_match[:ext].delete(",").to_f
  rent_total = rent_base + (rent_ext * 0.0001)

  floor_area = doc.at_css(".bukkenSpec #chk-bkc-housearea")&.text&.strip&.match(/(?<area>[\d\.]+)m²/)[:area]

  floors = doc.at_css(".bukkenSpec #chk-bkc-marodi")&.text&.strip
  floor_ldk = floors.match(/リビングダイニングキッチン\s*(?<ldk>[\d\.]+)帖/)[:ldk].to_f
  floor_rooms = floors.match(/洋室\s*(?<room1>[\d\.]+)帖.*洋室\s*(?<room2>[\d\.]+)帖/m)
  floor_room1 = floor_rooms[:room1]
  floor_room2 = floor_rooms[:room2]

  commute = get_commute_time(address)

  "#{name},,,#{url},#{address},,,#{commute},#{rent_total},#{floor_area},#{floor_ldk},#{floor_room1},,#{floor_room2}\n"
end

def shamaison_to_line(url)
  html = URI.parse(url).open.read
  doc = Nokogiri::HTML.parse(html)

  name = doc.at_css(".prBox h1 div")&.text
  address = doc.at_css(".detailClmRight td .bp")&.text
  rent = doc.at_css(".detailClmRight .tableBoxLeft")&.text&.match(/家賃[\s\n\r]*(?<base>[\d\,]+)円.*共益費等[\s\n\r]*(?<ext>[\d\,]+)円/m)
  rent_base = rent[:base].delete(",").to_f * 0.0001
  rent_ext = rent[:ext].delete(",").to_f * 0.0001
  rent_total = rent_base + rent_ext
  floor_area = doc.at_css(".tableBoxRight")&.text&.match(/専有面積[\s\r\n]+(?<area>[\d\.]+)m/)[:area]
  commute = get_commute_time(address)

  "#{name},,,#{url},#{address},,,#{commute},#{rent_total},#{floor_area}\n"
end

def print_line(url)
  if is_homes?(url)
    print homes_to_line(url)
  elsif is_shamaison?(url)
    print shamaison_to_line(url)
  else
    print "Unknown URL\n"
  end
end

def print_help
  print "Usage: get.rb URL\n"
end

def main
  if ARGV[0].nil?
    print_help
  else
    print_line(ARGV[0])
  end
end

main
