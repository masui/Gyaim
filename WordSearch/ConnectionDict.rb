# -*- coding: utf-8 -*-
#
# 接続辞書による変換
#

class DictEntry
  attr_reader :pat, :word, :inConnection, :outConnection
  attr_accessor :keyLink, :connectionLink

  def initialize(pat,word,inConnection,outConnection)
    @pat = pat
    @word = word
    @inConnection = inConnection
    @outConnection = outConnection
    @keylink = nil
    @connectionLink = nil
  end
end
  
class ConnectionDict
  def initialize(dict)
    @dict = []
    @keyLink = []
    @connectionLink = []
    readDict(dict)
    initLink()
  end

  def readDict(dict)
    File.open(dict){ |f|
      f.each { |line|
        line.chomp!
        next if line =~ /^#/
        next if line =~ /^\s/
        a = line.split(/\t/)
        a[3] = 0 if a[3].nil? || a[3] == ""
        a[2] = a[2].to_i
        @dict << DictEntry.new(a[0],a[1],a[2].to_i,a[3].to_i)
      }
    }
  end

  def initLink
    #
    # 先頭読みが同じ単語のリスト
    #
    cur = []
    @dict.each_with_index { |entry,i|
      next if entry.word =~ /^\*/
      # ind = entry.pat[0]
      ind = entry.pat.ord # 1.9
      if @keyLink[ind].nil? then
        cur[ind] = i
        @keyLink[ind] = i
      else
        @dict[cur[ind]].keyLink = i
        cur[ind] = i
      end
      entry.keyLink = nil # リンクの末尾
    }
    #
    # コネクションつながりのリスト
    #
    cur = []
    @dict.each_with_index { |entry,i|
      ind = entry.inConnection
      if @connectionLink[ind].nil? then
        cur[ind] = i
        @connectionLink[ind] = i
      else
        @dict[cur[ind]].connectionLink = i
        cur[ind] = i
      end
      entry.connectionLink = nil # リンクの末尾
    }
  end

  def search(pat,searchmode,&block)
    @searchmode = searchmode
    @candidates = []
    generateCand(nil, pat, "", "", &block)
  end
  
  def generateCand(connection, pat, foundword, foundpat, &block)
    # これまでマッチした文字列がfoundword,foundpatに入っている
    # d = (connection ? @connectionLink[connection] : @keyLink[pat[0]]) <- Ruby1.8
    d = (connection ? @connectionLink[connection] : @keyLink[pat.ord])
    while d do
      if pat == @dict[d].pat then # 完全一致
        block.call(foundword+@dict[d].word, foundpat+@dict[d].pat, @dict[d].outConnection)
      elsif @dict[d].pat.index(pat) == 0 # 先頭一致
        if @searchmode == 0 then
          block.call(foundword+@dict[d].word, foundpat+@dict[d].pat, @dict[d].outConnection)
        end
      elsif pat.index(@dict[d].pat) == 0 # connectionがあるかも
        restpat = pat[@dict[d].pat.length,pat.length]
        generateCand(@dict[d].outConnection, restpat, foundword+@dict[d].word, foundpat+@dict[d].pat, &block)
      end
      d = (connection ? @dict[d].connectionLink : @dict[d].keyLink)
    end
  end
end

if $0 == __FILE__ then
  d = ConnectionDict.new("../Resources/dict.txt")
  puts "ConnectionDict set"

  candidates = []

  d.search("tou"){ |word,pat,outc|
    next if word =~ /\*$/
    word.gsub!(/\*/,'')
    next if candidates.collect { |e| e.word }.member?(word)
    puts "addCandidate(#{word},#{pat},#{outc})"
    candidates << DictEntry.new(pat,word,outc,nil)
    puts candidates.length
    if candidates.length > 20 then
      break
    end
  }
end
