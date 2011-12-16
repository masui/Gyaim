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

require 'openssl'

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

  #
  # 単語の暗号化登録のために利用する暗号化/複号化ライブラリ
  # ウノウラボから持ってきたもの
  # http://labs.unoh.net/2007/05/ruby.html
  # decryptしても漢字に戻らない不具合あり
  #
  def encrypt(aaa, salt = 'salt')
    puts "encrypt(#{aaa},#{salt})"
    enc = OpenSSL::Cipher::Cipher.new('aes256')
    enc.encrypt
    enc.pkcs5_keyivgen(salt)
    #((enc.update(aaa) + enc.final).unpack("H*")).to_s  # 何故か文字列への変換に失敗することがある...
    ((enc.update(aaa) + enc.final).unpack("H*"))[0]
  rescue
    false
  end

  def decrypt(bbb, salt = 'salt')
    dec = OpenSSL::Cipher::Cipher.new('aes256')
    dec.decrypt
    dec.pkcs5_keyivgen(salt)
    (dec.update(Array.new([bbb]).pack("H*")) + dec.final)
  rescue
    false
  end

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
    elsif q == "ds" then # TimeStamp or DateStamp(?)
      @candidates << Time.now.strftime('%Y/%m/%d %H:%M:%S')
    elsif q.length > 1 && q =~ /^(.*)\?$/ then  # 個人辞書の中から暗号化された単語だけ抽出
      pat = $1
      @localdict.each { |entry|
        yomi = entry[0]
        word = entry[1]
        if yomi == '?' then # 暗号化された単語は読みが「?」になってる
          if !candfound[word] then
            # decryptしたバイト列が漢字だとうまくいかない...★★修正必要
            word = decrypt(word,pat)
            if word then
              @candidates << [word, yomi]
              candfound[word] = true
              break if @candidates.length > limit
            end
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
    puts word.class
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
    if yomi.length > 1 then                    # (間違って変な単語を登録しないように)
      if ! @dc[yomi].index([yomi,word]) then   # 固定辞書に入ってない
        if @studydict.index([yomi,word]) then  # しかし学習辞書に入っている
          register(word,yomi)                  # ならば登録してしまう
        end
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
    # 変換ウィンドウが出るときにこれを読んでいるのだが、これを
    # 実行すると変換が遅れて文字をとりこぼしてしまう。
    # たいした処理をしてないのに何故だろうか?
    Thread.new do
      @studydict = loadDict(studyDictFile)
    end
  end

  def finish
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
