# -*- coding: utf-8 -*-
#
# GyaimController.rb
# Gyaim
#
# Created by Toshiyuki Masui on 11/03/14.
# Copyright 2011 Pitecan Systems. All rights reserved.
#

framework 'InputMethodKit'

require 'Log'
require 'WordSearch'
require 'Romakana'

class GyaimController < IMKInputController
  attr_accessor :candwin
  attr_accessor :candview
  attr_accessor :textview

  def initWithServer(server, delegate:d, client:c)
    Log.log "initWithServer delegate=#{d}, client="#{c}"
    @client = c   # Lexierraではこれをnilにしてた。何故?

    # これが何故必要なのか不明
    @candwin = NSApp.delegate.candwin
    @textview = NSApp.delegate.textview

    # 富豪辞書サーチ
    fugopath = NSBundle.mainBundle.pathForResource("fugodic", ofType:"txt")
    @ws = WordSearch.new(fugopath)

    resetState

    if super then
      self
    end
  end

  #
  # 入力システムがアクティブになると呼ばれる
  #
  def activateServer(sender)
    showWindow
  end

  def deactivateServer(sender)
    hideWindow
  end

  def resetState
    @inputPat = ""
    @candidates = []
    @nthCand = 0
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
    Log.log "handleEvent: event.type = #{event.type}"
    return false if event.type != NSKeyDown

    eventString = event.characters
    keyCode = event.keyCode
    modifierFlags = event.modifierFlags

    Log.log "handleEvent: event = #{event}"
    Log.log "handleEvent: sender = #{sender}"
    Log.log "handleEvent: eventString=#{eventString}"
    Log.log "handleEvent: keyCode=#{keyCode}"
    Log.log "handleEvent: modifierFlags=#{modifierFlags}"

    return true if keyCode == kVirtual_JISKanaModeKey || keyCode == kVirtual_JISRomanModeKey
    return true if !eventString
    return true if eventString.length == 0

    handled = false

    # eventStringの文字コード取得
    # する方法がわからないので...
    s = sprintf("%s",eventString) # NSStringを普通のStringに??
    c = s.each_byte.to_a[0]
    Log.log sprintf("c = 0x%x",c)

    #
    # スペース、バックスペース、通常文字などの処理
    #
    if c == 0x08 || c == 0x7f || c == 0x1b then
      if converting then
        if @nthCand > 0 then
          @nthCand -= 1
          showCands
        else
          if @inputPat.length == 1 then
            @inputPat = ""
            resetState
            showCands
            @client.setMarkedText(NSAttributedString.alloc.initWithString(""),
                                  selectionRange:NSMakeRange(0,0),
                                  replacementRange:NSMakeRange(NSNotFound,NSNotFound))
          elsif @inputPat.length > 0 then
            @inputPat.sub!(/.$/,'')
            searchAndShowCands
          end
        end
        handled = true
      end
    elsif c == 0x20 then
      if converting then
        if @nthCand < @candidates.length - 1 then
          @nthCand += 1
          showCands
        end
        handled = true
      end
    elsif c == 0x0a || c == 0x0d then
      if converting then
        fix
        handled = true
      end
    elsif c >= 0x21 && c <= 0x7e && (modifierFlags & NSControlKeyMask) == 0 then
      fix if @nthCand > 0
      @inputPat += eventString
      searchAndShowCands
      handled = true
    end

    showWindow
    return handled
  end

  # 単語検索して候補の配列作成
  def searchAndShowCands
    #
    # WordSearch#search で検索して WordSearch#candidates で受け取る
    #
    @ws.search(@inputPat)
    @candidates = @ws.candidates
    hiragana = @inputPat.roma2hiragana
    @candidates.delete(hiragana)
    @candidates.unshift(hiragana) if hiragana != ""
    @candidates.unshift(@inputPat)
    @nthCand = 0
    showCands
  end
  
  def fix
    if @candidates.length > @nthCand then
      word = @candidates[@nthCand]
      # 何故かinsertTextだとhandleEventが呼ばれてしまうようで
      # @client.insertText(word)
      @client.insertText(word,replacementRange:NSMakeRange(NSNotFound, 0))
    end
    resetState
  end

  def showCands
#    if converting && @candidates.length > @nthCand then
      #
      # 選択中の単語をキャレット位置にアンダーライン表示
      #
      word = @candidates[@nthCand]
      if word then
        kTSMHiliteRawText = 2
        attr = self.markForStyle(kTSMHiliteRawText,atRange:NSMakeRange(0,word.length))
        attrstr = NSAttributedString.alloc.initWithString(word,attributes:attr)
        @client.setMarkedText(attrstr,selectionRange:NSMakeRange(word.length,0),replacementRange:NSMakeRange(NSNotFound, 0))
      end
      #
      # 候補単語リストを表示
      #
      @textview.setString(@candidates[@nthCand+1 .. @nthCand+1+10].join(' '))
#    end
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
