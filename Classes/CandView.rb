# CandView.rb
# Gyaim
#
# Created by Toshiyuki Masui on 11/03/15.
# Copyright 2011 __MyCompanyName__. All rights reserved.

require 'Log'

class CandView < NSView
  def drawRect(rect)
    Log.log "CandView drawRect"
    mainBundle = NSBundle.mainBundle
    image = NSImage.alloc.initByReferencingFile(mainBundle.pathForResource("candwin",ofType:"png"))
    image.compositeToPoint(NSZeroPoint,operation:NSCompositeSourceOver)
  end
end
