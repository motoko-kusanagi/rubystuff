#!/usr/bin/env ruby
# encoding: utf-8

require 'open-uri'
require 'nokogiri'
require 'rubygems'

DATA_DIR = "web-data"
BASE_URL = "http://allegro.pl/domy-na-sprzedaz-112740?order=p&p="

@file = File.open("allegro.csv", "w")
@file.write("tytuł aukcji;miejscowość;powierzchnia;powierzchnia działki;rok budowy;liczba pokoi;rodzaj zabudowy;liczba pięter;matierały budynku;dach;cena\n")

def to_csv
  puts "#{@tytul};#{@miejscowosc};#{@powierzchnia};#{@powierzchnia_dzialki};#{@rok_budowy};#{@liczba_pokoi};#{@rodzaj_zabudowy};#{@liczba_pieter};#{@material_budynku};#{@dach};#{@cena};"
  @file.write("#{@tytul};#{@miejscowosc};#{@powierzchnia};#{@powierzchnia_dzialki};#{@rok_budowy};#{@liczba_pokoi};#{@rodzaj_zabudowy};#{@liczba_pieter};#{@material_budynku};#{@dach};#{@cena}\n")
end

def parse_params
  @powierzchnia = "null"
  @powierzchnia_dzialki = "null"
  @rok_budowy = "null"
  @liczba_pokoi = "null"
  @rodzaj_zabudowy = "null"
  @liczba_pieter = "null"
  @material_budynku = "null"
  @dach = "null"

  @co.each do |what_item|
    if what_item.text == "Powierzchnia"
      @powierzchnia = @wartosc[0].text
      @i=2
    elsif what_item.text == "Powierzchnia działki"
      @powierzchnia_dzialki = @wartosc[2].text
      @i=4
    else
     if what_item.text == "Rok budowy" ; @rok_budowy = @wartosc[@i].text ; end
     if what_item.text == "Liczba pokoi" ; @liczba_pokoi = @wartosc[@i].text ; end
     if what_item.text == "Rodzaj zabudowy" ; @rodzaj_zabudowy = @wartosc[@i].text ; end
     if what_item.text == "Liczba pięter" ; @liczba_pieter = @wartosc[@i].text ; end
     if what_item.text == "Materiał budynku" ; @material_budynku = @wartosc[@i].text ; end
     if what_item.text == "Dach" ; @dach = @wartosc[@i].text ; end
     @i=@i+1
    end
  end

  puts "Tytul : #{@tytul}"
  puts "Miasto : #{@miejscowosc}"  
  puts "Powierzchnia : #{@powierzchnia}"
  puts "Powierzchnia działki : #{@powierzchnia_dzialki}"
  puts "Rok budowy : #{@rok_budowy}"
  puts "Liczba pokoi : #{@liczba_pokoi}"
  puts "Rodzaj zabudowy : #{@rodzaj_zabudowy.capitalize!}"
  puts "Liczba pięter : #{@liczba_pieter}"
  puts "Materiał budynku : #{@material_budynku.capitalize!}"
  puts "Dach : #{@dach.capitalize!}"
  puts "Cena : #{@cena}"
  
  to_csv
end

for x in 1..300
  remote_url = "#{BASE_URL}#{x}"
  url = Nokogiri::HTML(open(remote_url),'utf-8')

  puts "#{x} >>>>>> #{remote_url}"
  url = url.css("section[class='offers']")

  url.css('article').each do |item|
    @tytul = item.css('div[class="details"] h2').text.capitalize
    @miejscowosc = item.to_s.lines.first.split('"')[7].to_s.capitalize
    
    @cena = item.css('span[class="buy-now dist"]').text.gsub(" Kup Teraz ","").gsub(" zł","").gsub("\n","").gsub(" ","").chomp(" ")
    if @cena == ""
      @cena = item.css('span[class="bid dist"]').text.gsub(" ogłoszenie","").gsub(" zł","").gsub("\n","").gsub(" ","").chomp(" ")
    end
    @co = item.css('div[class="params params-featured"] dt span')
    @wartosc = item.css('div[class="params params-featured"] dd span')
    @i = 0

    parse_params
  end
  sleep(5)
end
