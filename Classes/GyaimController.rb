# -*- coding: utf-8 -*-
# GyaimController.rb
# Gyaim
#
# Created by Toshiyuki Masui on 11/03/14.
# Copyright 2011 Pitecan Systems. All rights reserved.

require 'Log'

class GyaimController < IMKInputController
  attr_accessor :candwin
  attr_accessor :candview
  attr_accessor :textview

  def initWithServer(server, delegate:d, client:c)
    Log.log "initWithServer delegate=#{d}, client="#{c}"
    @client = c   # Lexierraではこれをnilにしてた。何故?
    @candwin = NSApp.delegate.candwin
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
    self.showWindow
  end

  #
  # キー入力などのイベントをすべて取得、必要なあらゆる処理を行なう
  #
  def handleEvent(event, client:sender)
    Log.log "handleEvent: event = #{event}"
    Log.log "handleEvent: sender = #{sender}"
    Log.log "handleEvent: eventstring=#{event.characters}"
    Log.log "handleEvent: keycode=#{event.keyCode}"
    @client = sender
    @client.insertText("漢字", replacementRange:NSMakeRange(NSNotFound, 0))
    return true
  end

  #
  # キャレットの位置に候補ウィンドウを出す
  #
  def showWindow
    # MacRubyでポインタを使うための苦しいやり方
    lineRectP = Pointer.new('{CGRect={CGPoint=dd}{CGSize=dd}}')
    @client.attributesForCharacterIndex(0,lineHeightRectangle:lineRectP)
    lineRect = lineRectP[0]
    Log.log lineRect.origin.x
    Log.log lineRect.origin.y

#  NSRect lineRect;
#  [_client attributesForCharacterIndex:0 lineHeightRectangle:&lineRect];
#  NSPoint origin = lineRect.origin;

#  // And show the candidate window at that position.
#  origin.x -= 15;
#  origin.y -= 125;
    
    origin = lineRect.origin
    origin.x -= 15;
    origin.y -= 125;
    x = @candwin
    Log.log "candwin=#{x}"
    @candwin.setFrameOrigin(origin)
    NSApp.delegate.candview.setNeedsDisplay(true) # ???
    NSApp.unhide(self)
  end

end
