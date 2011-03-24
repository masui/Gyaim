# -*- coding: utf-8 -*-
# WordSearch.rb
# Gyaim
#
# Created by Toshiyuki Masui on 2011/3/15.
# Copyright 2011 Pitecan Systems. All rights reserved.

# dict = DictCache.new
# DictCache.create(*dictfiles)
#   DictCache.createCache(fugodic,localdic, ...)
# dict["k"] 配列を返す

class DictCache
  def initialize
    @dict = {}
  end

  def DictCache.charCode(s)
    sprintf("%02x",s.each_byte.to_a[0])
  end

  def DictCache.cacheDictDir
    # NSBundle.mainBundle.resourcePath
    # "/tmp"
    File.expand_path("~/.gyaimdict")
  end

  def DictCache.dictMarshalFile(code)
    "#{cacheDictDir}/dict#{code}"
  end

  def [](s)
    code =  DictCache.charCode(s)
    if @dict[code].nil? then
      marshal = DictCache.dictMarshalFile(code)
      if File.exist?(marshal) then
        File.open(marshal){ |f|
          @dict[code] = Marshal.load(f)
        }
      end
    end
    @dict[code]
  end

  def DictCache.createCache(*dictfiles)
    @dict = {}
    dictfiles.flatten.each { |dictfile|
      File.open(dictfile){ |f|
        f.each { |line|
          next if line =~ /^#/
          next if line =~ /^\s*$/
          line.chomp!
          (yomi,word) = line.split(/\s+/)
          if yomi && word then
            if @dict[charCode(yomi)].nil? then
              @dict[charCode(yomi)] = []
            end
            @dict[charCode(yomi)] << [yomi,word]
          end
        }
      }
    }
    @dict.each { |code,dic|
      File.open(dictMarshalFile(code),"w"){ |f|
        Marshal.dump(dic,f)
      }
    }
  end
end


class WordSearch
  attr :searchmode, true

  def dictDir
    File.expand_path("~/.gyaimdict")
  end

  def localDictFile
    "#{dictDir}/localdict.txt"
  end

  # dict = NSBundle.mainBundle.pathForResource("dict", ofType:"txt")
  # dict = "../Resources/dict.txt"
  def initialize(*dictfiles)
    @searchmode = 0
    Dir.mkdir(dictDir) unless File.exist?(dictDir)
    @dc = DictCache.new
    if !@dc["kanji"] then
      DictCache.createCache(dictfiles)
    end

    @localdict = []
    if File.exist?(localDictFile) then
      File.open(localDictFile){ |f|
        f.each { |line|
          next if line =~ /^#/
          next if line =~ /^\s*$/
          line.chomp!
          (yomi,word) = line.split(/\s+/)
          if yomi && word then
            @localdict << [yomi, word]
          end
        }
      }
    end
  end

  def search(q,limit=10)
    # @searchmode=0のとき前方マッチ, @searchmode=1のとき完全マッチとする

    return if q.nil? || q == ''

    qq = q.gsub(/[\{\}\[\]\(\)]/){ '\\' + $& }
    pat = Regexp.new(@searchmode > 0 ? "^#{qq}$" : "^#{qq}")

    candfound = {}
    @candidates = []

    (@localdict + @dc[q]).each { |entry|
      yomi = entry[0]
      word = entry[1]
      if pat.match(yomi) then
        if !candfound[word] then
          @candidates << [word, yomi]
          candfound[word] = true
          break if @candidates.length > limit
        end
      end
    }
  end
  
  def candidates
    @candidates
  end

  # 登録辞書、学習辞書をどうするかが問題である
  def register(word,yomi)
    puts "register(#{word},#{yomi})"
    @localdict.unshift([yomi,word])
    File.open(localDictFile,"w"){ |f|
      @localdict.each { |entry|
        yomi = entry[0]
        word = entry[1]
        f.puts "#{yomi}\t#{word}"
      }
    }
  end

end

if __FILE__ == $0 then
  ws = WordSearch.new("/Users/masui/Gyaim/Resources/dict.txt")
  ws.search("masui")
  puts ws.candidates
  ws.search("kanj")
  puts ws.candidates
end
