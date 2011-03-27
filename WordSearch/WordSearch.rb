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

  def studyDictFile
    "#{dictDir}/studydict.txt"
  end

  # dict = NSBundle.mainBundle.pathForResource("dict", ofType:"txt")
  # dict = "../Resources/dict.txt"
  def initialize(*dictfiles)
    @searchmode = 0
    Dir.mkdir(dictDir) unless File.exist?(dictDir)

    # 固定辞書初期化
    @dc = DictCache.new
    if !@dc["kanji"] then
      DictCache.createCache(dictfiles)
    end

    # 個人辞書を読出し
    @localdict = loadDict(localDictFile) 

    # 学習辞書を読出し
    @studydict = loadDict(studyDictFile)
  end

  def search(q,limit=10)
    # @searchmode=0のとき前方マッチ, @searchmode=1のとき完全マッチとする

    return if q.nil? || q == ''

    candfound = {}
    @candidates = []

    if q.length > 1 && q.sub!(/\.$/,'') then
      # Google Suggestを検索
      require 'net/http'
      require 'nkf'
      registered = {}
      words = []
      Net::HTTP.start('google.co.jp', 80) {|http|
        response = http.get("/complete/search?output=toolbar&hl=ja&q=#{q}")
        s = response.body.to_s
        s = NKF.nkf('-w',s)
        while s.sub!(/data="([^"]*)"\/>/,'') do
          word = $1.split[0]
          if !candfound[word] then
            candfound[word] = 1
            @candidates << word
          end
        end
      }
    else
      # 普通に検索
      qq = q.gsub(/[\.\{\}\[\]\(\)]/){ '\\' + $& }
      pat = Regexp.new(@searchmode > 0 ? "^#{qq}$" : "^#{qq}")

      (@studydict + @localdict + @dc[q]).each { |entry|
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
  end
  
  def candidates
    @candidates
  end

  #
  # ユーザ辞書登録
  #
  def register(word,yomi)
    puts "register(#{word},#{yomi})"
    if !@localdict.index([yomi,word]) then
      @localdict.unshift([yomi,word])
      saveDict(localDictFile,@localdict)
    end
  end

  #
  # 学習辞書の扱い
  #
  def study(word,yomi)
    puts "study(#{word},#{yomi})"
    if ! @dc[yomi].index([yomi,word]) then   # 固定辞書に入ってない
      if @studydict.index([yomi,word]) then  # しかし学習辞書に入っている
        register(word,yomi)                  # ならば登録してしまう
      end
    end

    @studydict.unshift([yomi,word])
    @studydict = @studydict[0..1000] # 1000行に制限
  end

  def loadDict(dictfile)
    dict = []
    if File.exist?(dictfile) then
      File.open(dictfile){ |f|
        f.each { |line|
          next if line =~ /^#/
          next if line =~ /^\s*$/
          line.chomp!
          (yomi,word) = line.split(/\s+/)
          if yomi && word then
            dict << [yomi, word]
          end
        }
      }
    end
    dict
  end

  def saveDict(dictfile,dict)
    saved = {}
    File.open(dictfile,"w"){ |f|
      dict.each { |entry|
        yomi = entry[0]
        word = entry[1]
        s = "#{yomi}\t#{word}"
        if !saved[s] then
          f.puts s
          saved[s] = true
        end
      }
    }
  end

  def start
    puts "loadstudy"
    @studydict = loadDict(studyDictFile)
  end

  def finish
    puts "savestudy"
    saveDict(studyDictFile,@studydict)
  end

end

if __FILE__ == $0 then
  ws = WordSearch.new("/Users/masui/Gyaim/Resources/dict.txt")
  ws.search("masui")
  puts ws.candidates
  ws.search("kanj")
  puts ws.candidates
end
