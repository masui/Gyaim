# Log.rb
# Gyaim
#
# Created by Toshiyuki Masui on 2011/3/15.
# Copyright 2011 Pitecan Systems. All rights reserved.

GYAIMLOGFILE = "/tmp/gyaim.log"

class Log
  def Log.log(s)
    File.open(GYAIMLOGFILE,"a"){ |f|
      f.puts s
    }
  end
end
