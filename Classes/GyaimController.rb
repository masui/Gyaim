# -*- coding: utf-8 -*-
#
# GyaimController.rb
# Gyaim
#
# Created by Toshiyuki Masui on 2011/3/14.
# Copyright 2011 Pitecan Systems. All rights reserved.
#

framework 'InputMethodKit'

require 'rubygems'
# http://ferrous26.com/blog/2012/04/03/axelements-part1/
require 'accessibility/string'
include Accessibility::String

require 'WordSearch'
require 'Romakana'
require 'Crypt'

class GyaimController < IMKInputController
  attr_accessor :candwin
  attr_accessor :candview
  attr_accessor :textview

  @@ws = nil

  def imageDir
    File.expand_path("~/.gyaimdict/images")
  end

  def cacheDir
    File.expand_path("~/.gyaimdict/cacheimages")
  end

  def initWithServer(server, delegate:d, client:c)
    # puts "initWithServer===============@@ws = #{@@ws}"
    # Log.log "initWithServer delegate=#{d}, client="#{c}"
    @client = c   # Lexierraではこれをnilにしてた。何故?

    # これが何故必要なのか不明
    @candwin = NSApp.delegate.candwin
    @textview = NSApp.delegate.textview

    # 辞書サーチ
    dictpath = NSBundle.mainBundle.pathForResource("dict", ofType:"txt")
    if @@ws.nil? then
      @@ws = WordSearch.new(dictpath)
    end

    resetState

    if super then
      self
    end
  end

  #
  # 入力システムがアクティブになると呼ばれる
  #
  def activateServer(sender)
    @@ws.start
    showWindow
  end

  #
  # 別の入力システムに切り換わったとき呼ばれる
  #
  def deactivateServer(sender)
    hideWindow
    fix
    @@ws.finish
  end

  def resetState
    @inputPat = ""
    @candidates = []
    @nthCand = 0
    @@ws.searchmode = 0
    @selectedstr = nil
  end

  def converting
    @inputPat.length > 0
  end

  #
  # キー入力などのイベントをすべて取得、必要なあらゆる処理を行なう
  # BS, Retなどが来ないこともあるのか?
  #
  def handleEvent(event, client:sender)
    # かなキーボードのコード
    kVirtual_JISRomanModeKey = 102
    kVirtual_JISKanaModeKey  = 104
    kVirtual_Arrow_Left      = 0x7B
    kVirtual_Arrow_Right     = 0x7C
    kVirtual_Arrow_Down      = 0x7D
    kVirtual_Arrow_Up        = 0x7E

    @client = sender
    # puts "handleEvent: event.type = #{event.type}"
    return false if event.type != NSKeyDown

    eventString = event.characters
    keyCode = event.keyCode
    modifierFlags = event.modifierFlags

    # puts "handleEvent: event = #{event}"
    # puts "handleEvent: sender = #{sender}"
    # puts "handleEvent: eventString=#{eventString}"
    # puts "handleEvent: keyCode=#{keyCode}"
    # puts "handleEvent: modifierFlags=#{modifierFlags}"

    # 選択されている文字列があれば覚えておく
    # 後で登録に利用するかも
    range = @client.selectedRange
    astr = @client.attributedSubstringFromRange(range)
    if astr then
      s = astr.string
      @selectedstr = s if s != ""
    end

    return true if keyCode == kVirtual_JISKanaModeKey || keyCode == kVirtual_JISRomanModeKey
    return true if !eventString
    return true if eventString.length == 0

    handled = false

    # eventStringの文字コード取得
    # する方法がわからないので...
    s = sprintf("%s",eventString) # NSStringを普通のStringに??
    c = s.each_byte.to_a[0]
    # puts sprintf("c = 0x%x",c)

    #
    # スペース、バックスペース、通常文字などの処理
    #
    if c == 0x08 || c == 0x7f || c == 0x1b then
      if converting && @tmp_image_displayed && !@bs_through then
        @tmp_image_displayed = false
        KeyCoder.post_event [51,true]   # BS
        KeyCoder.post_event [51,false]  # BS
        return true
      end
      if !@bs_through then
        if converting then
          if @nthCand > 0 then
            @nthCand -= 1
            showCands
          else
            @inputPat.sub!(/.$/,'')
            searchAndShowCands
          end
          handled = true
        end
      end
      @bs_through = false
    elsif c == 0x20 then
      if converting then
        if @tmp_image_displayed then
##          @bs_through = true
##          KeyCoder.post_event [51,true]   # BS BSで画像を消してから再度スペースを入力したことにする
##          KeyCoder.post_event [51,false]  # BS

          KeyCoder.post_event [55,true]  # CMD
          KeyCoder.post_event [6,true]   # Z
          KeyCoder.post_event [6,false]  # Z
          KeyCoder.post_event [55,false] # CMD

          KeyCoder.post_event [49,true]   # SP 
          KeyCoder.post_event [49,false]  # SP
          @tmp_image_displayed = false
          return true
        end

        if @nthCand < @candidates.length-1 then
          @nthCand += 1
          showCands
        end
        handled = true
      end
    elsif c == 0x0a || c == 0x0d then
      if converting then
        if @tmp_image_displayed then
          @tmp_image_displayed = false
          resetState
          # KeyCoder.post_event [51,true]  # BS 何故かリターンで確定すると改行が入ってしまうので...
          # KeyCoder.post_event [51,false]  # BS
          return true
        end
        if @@ws.searchmode > 0 then
          fix
        else
          if @nthCand == 0 then
            @@ws.searchmode = 1
            searchAndShowCands
          else
            fix
          end
        end
        handled = true
      end
    elsif c >= 0x21 && c <= 0x7e && (modifierFlags & (NSControlKeyMask|NSCommandKeyMask|NSAlternateKeyMask)) == 0 then
      fix if @nthCand > 0 || @@ws.searchmode > 0
      @inputPat += eventString
      searchAndShowCands
      @@ws.searchmode = 0
      handled = true
    end

    showWindow
    return handled
  end

  def wordpart(e) # 候補が[単語, 読み]のような配列で返ってくるとき単語部分だけ取得
    e.class == String ? e : e[0]
  end
  
  def delete(a,s)
    a.find_all { |e|
      wordpart(e) != s
    }
  end

  # 単語検索して候補の配列作成
  def searchAndShowCands
    #
    # WordSearch#search で検索して WordSearch#candidates で受け取る
    #
    # @@ws.searchmode == 0 前方マッチ
    # @@ws.searchmode == 1 完全マッチ ひらがな/カタカナも候補に加える
    #
    if @@ws.searchmode > 0 then
      @@ws.search(@inputPat)
      @candidates = @@ws.candidates
      katakana = @inputPat.roma2katakana
      if katakana != "" then
        @candidates = delete(@candidates,katakana)
        @candidates.unshift(katakana)
      end
      hiragana = @inputPat.roma2hiragana
      if hiragana != "" then
        @candidates = delete(@candidates,hiragana)
        @candidates.unshift(hiragana)
      end
    else
      @@ws.search(@inputPat)
      @candidates = @@ws.candidates
      @candidates.unshift(@selectedstr) if @selectedstr && @selectedstr != ''
      @candidates.unshift(@inputPat)
      if @candidates.length < 8 then
        hiragana = @inputPat.roma2hiragana
        @candidates.push(hiragana)
      end

    end
    @nthCand = 0
    showCands
  end
  
  def fix
    if @candidates.length > @nthCand then
      word = wordpart(@candidates[@nthCand])
      # 何故かinsertTextだとhandleEventが呼ばれてしまうようで
      # @client.insertText(word)

      if word =~ /^[0-9a-f]{32}$/ then
        if !@tmp_image_displayed then
##          @client.insertText(' ',replacementRange:NSMakeRange(NSNotFound, NSNotFound))
##          KeyCoder.post_event [51,true]  # BS
##          KeyCoder.post_event [51,false]  # BS
          KeyCoder.post_event [55,true]  # CMD
          KeyCoder.post_event [9,true]   # V
          KeyCoder.post_event [9,false]  # V
          KeyCoder.post_event [55,false] # CMD
        end
        @tmp_image_displayed = false
      else
        @client.insertText(word,replacementRange:NSMakeRange(NSNotFound, NSNotFound))
        if @inputPat !~ /^(.*)\?$/ then # 暗号化単語じゃない
          File.open(File.expand_path("~/.gyaimdict/log/#{Time.now.strftime('%Y%m%d')}.txt"),"a"){ |f|
            f.puts "#{Time.now.strftime('%Y%m%d%H%M%S')}\t#{word}"
          }
        end
      end

      if word == @selectedstr then
        if @inputPat =~ /^(.*)\?$/ then # 暗号化単語登録
          @@ws.register(Crypt.encrypt(word,$1).to_s,'?')
        else
          @@ws.register(word,@inputPat)
        end
        @selectedstr = nil
      else
        c = @candidates[@nthCand]
        if c.class == Array then
          if c[1] != 'ds' && c[1] != '?' then
            @@ws.study(c[0],c[1])
          end
        else
          # 読みが未登録 = ユーザ辞書に登録されていない
          if @inputPat != 'ds' && @inputPat != '?' then
            @@ws.study(word,@inputPat)
          end
        end
      end
    end
    resetState
  end

  def showCands
    #
    # 選択中の単語をキャレット位置にアンダーライン表示
    #
    @cands = @candidates.collect { |e|
      wordpart(e)
    }
    word = @cands[@nthCand]
    if word then
      if word =~ /^[0-9a-f]{32}$/ then
        # 入力中モードじゃなくするためのハック
        @client.insertText(' ',replacementRange:NSMakeRange(NSNotFound, NSNotFound))
        @bs_through = true
        KeyCoder.post_event [51,true]  # BS
        KeyCoder.post_event [51,false]  # BS

        # 画像をペーストボードに貼る
        mainBundle = NSBundle.mainBundle
        # imagepath = mainBundle.pathForResource(word,ofType:"png")
        # imagepath = "#{mainBundle.bundlePath}/Contents/Resources/#{word}.png"
        imagepath = "#{cacheDir}/#{word}.png"
        if !File.exists?(imagepath) then
          imagepath = "#{imageDir}/#{word}.png"
        end
        image = NSImage.alloc.initByReferencingFile(imagepath)
        imagedata = image.TIFFRepresentation
        pasteboard = NSPasteboard.generalPasteboard
        pasteboard.clearContents
        pasteboard.declareTypes([NSPasteboardTypeTIFF, NSPasteboardTypeString],owner:nil)
        pasteboard.setData(imagedata,forType:NSTIFFPboardType)
        pasteboard.setString("[[http://Gyazo.com/#{word}.png]]",forType:NSStringPboardType)

        KeyCoder.post_event [55,true]  # CMD
        KeyCoder.post_event [9,true]   # V
        KeyCoder.post_event [9,false]  # V
        KeyCoder.post_event [55,false] # CMD

        @tmp_image_displayed = true
      else
        if @tmp_image_displayed then

          # undo
          KeyCoder.post_event [55,true]  # CMD
          KeyCoder.post_event [6,true]   # Z
          KeyCoder.post_event [6,false]  # Z
          KeyCoder.post_event [55,false] # CMD

##          @bs_through = true
##          KeyCoder.post_event [51,true]  # BS
##          KeyCoder.post_event [51,false]  # BS
          @tmp_image_displayed = false
        end

        kTSMHiliteRawText = 2
        attr = self.markForStyle(kTSMHiliteRawText,atRange:NSMakeRange(0,word.length))
        attrstr = NSAttributedString.alloc.initWithString(word,attributes:attr)
        @client.setMarkedText(attrstr,selectionRange:NSMakeRange(word.length,0),replacementRange:NSMakeRange(NSNotFound, NSNotFound))
      end
    end
    #
    # 候補単語リストを表示
    #
    # @textview.setString(@cands[@nthCand+1 .. @nthCand+1+10].join(' '))
    @textview.setString('')
    (0..10).each { |i|
      w = @cands[@nthCand+1+i]
      break if w.nil?
      if w =~ /^[0-9a-f]{32}$/ then
        imagepath = "#{cacheDir}/#{w}s.png"
        if !File.exists?(imagepath) then
          imagepath = "#{imageDir}/#{w}s.png"
        end
        if !File.exists?(imagepath) then
          imageorigpath = "#{imageDir}/#{w}.png"
          system "/opt/local/bin/wget http://Gyazo.com/#{w}.png -O '#{imageorigpath}' > /dev/null >& /dev/null"
          system "/bin/cp '#{imageorigpath}' '#{imagepath}'"
          system "/usr/bin/sips --resampleHeight 20 '#{imagepath}' > /dev/null >& /dev/null"
        end
        image = NSImage.alloc.initByReferencingFile(imagepath)

        url = NSURL.fileURLWithPath(imagepath,false)
        wrap = NSFileWrapper.alloc.initWithURL(url,options:0,error:nil)
        attachment = NSTextAttachment.alloc.initWithFileWrapper(wrap)
        attachChar = NSAttributedString.attributedStringWithAttachment(attachment)
        attrString = @textview.textStorage
        attrString.beginEditing
        attrString.insertAttributedString(attachChar,atIndex:attrString.string.length)
        attrString.endEditing
#        @textview.textStorage.setAttributedString(attrString)
      else
        @textview.insertText(w)
      end
      @textview.insertText(' ')
    }
  end

  #
  # キャレットの位置に候補ウィンドウを出す
  #
  def showWindow
    # MacRubyでポインタを使うための苦しいやり方
    # 説明: http://d.hatena.ne.jp/Watson/20100823/1282543331
    #
    lineRectP = Pointer.new('{CGRect={CGPoint=dd}{CGSize=dd}}')
    @client.attributesForCharacterIndex(0,lineHeightRectangle:lineRectP)
    lineRect = lineRectP[0]
    origin = lineRect.origin
    origin.x -= 15;
    origin.y -= 125;
    @candwin.setFrameOrigin(origin)
    NSApp.unhide(self)
  end

  def hideWindow
    NSApp.hide(self)
  end
end
