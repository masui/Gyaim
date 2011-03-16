# -*- coding: utf-8 -*-
# WordSearch.rb
# Gyaim
#
# Created by Toshiyuki Masui on 11/03/15.
# Copyright 2011 Pitecan Systems. All rights reserved.

class WordSearch
  attr :searchMode, true

  def initialize
    fugopath = NSBundle.mainBundle.pathForResource("fugodic", ofType:"txt")
    # fugopath = "../Resources/fugodic.txt"

    @dict = []
    File.open(fugopath){ |f|
      f.each { |line|
        next if line =~ /^#/
        line.chomp!
        (yomi,word) = line.split(/\s+/)
        if yomi && word then
          @dict << [yomi,word]
        end
      }
    }
  end

  def search(q)
    pat = /^#{q}/
    @candidates = []
    @dict.each { |entry|
      yomi = entry[0]
      word = entry[1]
      if yomi =~ pat then
        @candidates << word
        break if @candidates.length > 10
      end
    }
  end
  
  def candidates
    @candidates
  end
end

# ws = WordSearch.new
# ws.search("masui")
# puts ws.candidates
