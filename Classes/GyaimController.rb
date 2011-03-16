# -*- coding: utf-8 -*-
# GyaimController.rb
# Gyaim
#
# Created by Toshiyuki Masui on 11/03/14.
# Copyright 2011 Pitecan Systems. All rights reserved.

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
    @candwin = NSApp.delegate.candwin
    @romakana = Romakana.new

    ws = WordSearch.new
    Log.log ws

    reset

    if super then # "super" と書くと同じ引数でスーパークラスを呼べる
      Log.log "Super end"
      self
    end
  end

  #
  # 入力システムがアクティブになると呼ばれる
  #
  def activateServer(sender)
    Log.log "ActivateServer sender=#{sender}"
    showWindow
  end

  def deactivateServer(sender)
    Log.log "DeActivateServer sender=#{sender}"
    hideWindow
  end

  def reset
    @converting = false
    @inputpat = ""
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

    if c == 0x08 || c == 0x7f || c == 0x1b then
      if @converting then
        backspaceKey
        handled = true
      end
    elsif c == 0x20 then
      if @converting then
        spaceKey
        handled = true
      end
    elsif c == 0x0a || c == 0x0d then
      if @converting then
        returnKey
        handled = true
      end
    elsif c >= 0x21 && c <= 0x7e && (modifierFlags & NSControlKeyMask) == 0 then
      normalKey(eventString)
      handled = true
    end

#    @client.insertText("漢字", replacementRange:NSMakeRange(NSNotFound, 0))

    showWindow

    return handled
  end

  def backspaceKey
    Log.log "backspaceKey"
  end

  def spaceKey
    Log.log "spaceKey"
  end

  def returnKey
    Log.log "returnKey"
  end

  def normalKey(s)
    Log.log "normalKey #{s}"
    @client.insertText(s, replacementRange:NSMakeRange(NSNotFound, 0))
  end


  #
  # キャレットの位置に候補ウィンドウを出す
  #
  def showWindow
    Log.log "showWindow"
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
    # NSApp.delegate.candview.setNeedsDisplay(true) # ??? 消したり出したりするやり方をちゃんと考えなければ
    NSApp.unhide(self)
  end

  def hideWindow
    NSApp.hide(self)
  end

end
