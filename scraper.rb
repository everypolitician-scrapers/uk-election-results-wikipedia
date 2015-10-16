#!/bin/env ruby
# encoding: utf-8

require 'scraperwiki'
require 'nokogiri'
require 'colorize'
require 'pry'
require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

class String
  def tidy
    self.gsub(/[[:space:]]+/, ' ').strip
  end
end

def noko_for(url)
  Nokogiri::HTML(open(url).read)
end

# 4 (or more) columns: Constituency, Previous Party, MP (Party)
def scrape_four_col(term, url)
  noko = noko_for(url)
  rows = noko.xpath('//table[.//th[contains(.,"Member returned")]]//tr[td[3]]')
  raise "No rows" if rows.count.zero?
  rows.each do |tr|
    td = tr.css('td')
    data = { 
      name: td[4].css('a')[0].text,
      wikiname: td[4].css('a')[0].attr('title'),
      party: td[4].css('a')[1].attr('title'),
      constituency: td[0].xpath('.//a').text,
      constituency_wikiname: td[0].xpath('.//a[not(@class="new")]/@title').text,
      term: term,
      source: url,
    }
    ScraperWiki.save_sqlite([:name, :constituency, :party, :term], data) rescue binding.pry
  end
end

# 3 (or more) columns: Constituency, MP, Party
def scrape_three_col(term, url)
  noko = noko_for(url)
  rows = noko.xpath('//table[.//th[contains(.,"Constituency")]]//tr[td[3]]')
  raise "No rows" if rows.count.zero?
  rows.each do |tr|
    td = tr.css('td')
    data = { 
      name: td[1].text.tidy,
      wikiname: td[1].xpath('.//a[not(@class="new")]/@title').text,
      party: td[2].text.tidy,
      constituency: td[0].xpath('.//a').text,
      constituency_wikiname: td[0].xpath('.//a[not(@class="new")]/@title').text,
      term: term,
      source: url,
    }
    ScraperWiki.save_sqlite([:name, :constituency, :party, :term], data)
  end
end


four_col = {
  55 => 'https://en.wikipedia.org/wiki/List_of_MPs_elected_in_the_United_Kingdom_general_election,_2010',
  56 => 'https://en.wikipedia.org/wiki/List_of_MPs_elected_in_the_United_Kingdom_general_election,_2015',
}

four_col.each do |term, url|
  scrape_four_col(term, url)
end

three_col = {
  54 => 'https://en.wikipedia.org/wiki/List_of_MPs_elected_in_the_United_Kingdom_general_election,_2005',
  53 => 'https://en.wikipedia.org/wiki/List_of_MPs_elected_in_the_United_Kingdom_general_election,_2001',
  52 => 'https://en.wikipedia.org/wiki/List_of_MPs_elected_in_the_United_Kingdom_general_election,_1997',
  51 => 'https://en.wikipedia.org/wiki/List_of_MPs_elected_in_the_United_Kingdom_general_election,_1992',
  50 => 'https://en.wikipedia.org/wiki/List_of_MPs_elected_in_the_United_Kingdom_general_election,_1987',
}

three_col.each do |term, url|
  scrape_three_col(term, url)
end
