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

  def initWithServer(server, delegate:d, client:c)
    Log.log "initWithServer delegate=#{d}, client="#{c}"
    # self = [super initWithServer:server delegate:delegate client:inputClient];
    if super then
      Log.log "Super end"
      self
    end
  end

  def handleEvent(event, client:sender)
    # Syslog.log(Syslog::LOG_ALERT, "sender=%x", sender)
    Log.log "handleEvent: event = #{event}"
    Log.log "handleEvent: sender = #{sender}"
    Log.log "handleEvent: eventstring=#{event.characters}"
    Log.log "handleEvent: keycode=#{event.keyCode}"
    sender.insertText("漢字", replacementRange:NSMakeRange(NSNotFound, 0))
    return true
  end

end
