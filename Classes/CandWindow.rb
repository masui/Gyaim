# -*- coding: utf-8 -*-
# CandWindow.rb
# Gyaim
#
# Created by Toshiyuki Masui on 2011/3/15.
# Copyright 2011 Pitecan Systems. All rights reserved.

class CandWindow < NSWindow
  def initWithContentRect(contentRect,styleMask:aStyle,backing:bufferingType,defer:d)
    # superにはキーワード引数が使えないらしく、以下のように書くことができない
    # super(contentRect,styleMask:NSBorderlessWindowMask,backing:NSBackingStoreBuffered,defer:false)
    if super(contentRect,NSBorderlessWindowMask,NSBackingStoreBuffered,false)
      setBackgroundColor(NSColor.clearColor)
      setLevel(NSStatusWindowLevel)
      setAlphaValue(1.0)
      setOpaque(false)
      setHasShadow(true)
      setCanHide(true)
      self
    end
  end

  #
  # ウィンドウ枠をドラッグ可能にするためにmouseDownとmouseDraggedを定義
  #
  def mouseDragged(event)
    screenFrame = NSScreen.mainScreen.frame
    windowFrame = self.frame

    # grab the current global mouse location; we could just as easily get the mouse location 
    # in the same way as we do in -mouseDown:
    # currentLocation = [self convertBaseToScreen:[self mouseLocationOutsideOfEventStream]];
    currentLocation = self.convertBaseToScreen(event.locationInWindow)
    newOrigin = NSPoint.new(currentLocation.x - @initialLocation.x, currentLocation.y - @initialLocation.y)
    
    # Don't let window get dragged up under the menu bar
    if newOrigin.y+windowFrame.size.height > screenFrame.origin.y+screenFrame.size.height then
      newOrigin.y=screenFrame.origin.y + (screenFrame.size.height-windowFrame.size.height)
    end
    
    # go ahead and move the window to the new location
    self.setFrameOrigin(newOrigin)
  end

  # We start tracking the a drag operation here when the user first clicks the mouse,
  # to establish the initial location.
  def mouseDown(event)
    windowFrame = self.frame
    # grab the mouse location in global coordinates
    @initialLocation = self.convertBaseToScreen(event.locationInWindow)
    @initialLocation.x -= windowFrame.origin.x;
    @initialLocation.y -= windowFrame.origin.y;
  end

end
