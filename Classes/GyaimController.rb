# -*- coding: undecided -*-
# GyaimController.rb
# Gyaim
#
# Created by Toshiyuki Masui on 11/03/14.
# Copyright 2011 Pitecan Systems. All rights reserved.

class GyaimController < IMKInputController

  def log(s)
    File.open("/tmp/system.log","a"){ |f|
      f.puts s
    }
  end

  def initWithServer(server, delegate:d, client:c)
    File.open("/tmp/system.log","a"){ |f|
      f.puts "initWithServer delegate=#{d}, client="#{c}"
    }
    # self = [super initWithServer:server delegate:delegate client:inputClient];
    if super then
      File.open("/tmp/system.log","a"){ |f|
        f.puts "Super end"
      }
      
      self
    end
  end

  def handleEvent(event, client:sender)
    # Syslog.log(Syslog::LOG_ALERT, "sender=%x", sender)
    log "handleEvent: event = #{event}"
    log "handleEvent: sender = #{sender}"
    log "handleEvent: eventstring=#{event.characters}"
    log "handleEvent: keycode=#{event.keyCode}"
    sender.insertText("漢字", replacementRange:NSMakeRange(NSNotFound, 0))
    return true
  end

end
