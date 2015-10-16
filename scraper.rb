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

def scrape_term(term, url)
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
    ScraperWiki.save_sqlite([:name, :area, :party, :term], data)
  end
end

lists = {
  51 => 'https://en.wikipedia.org/wiki/List_of_MPs_elected_in_the_United_Kingdom_general_election,_1992',
  50 => 'https://en.wikipedia.org/wiki/List_of_MPs_elected_in_the_United_Kingdom_general_election,_1987',
}

lists.each do |term, url|
  scrape_term(term, url)
end
