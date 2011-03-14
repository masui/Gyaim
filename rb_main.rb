# -*- coding: utf-8 -*-
#
# rb_main.rb
# Gyaim
#
# Created by Toshiyuki Masui on 11/03/14.
# Copyright Pitecan Systems. 2011. All rights reserved.
#

# Loading the Cocoa framework. If you need to load more frameworks, you can
# do that here too.

framework 'Cocoa'
framework 'InputMethodKit'

# Loading all the Ruby project files.
main = File.basename(__FILE__, File.extname(__FILE__))
dir_path = NSBundle.mainBundle.resourcePath.fileSystemRepresentation
Dir.glob(File.join(dir_path, '*.{rb,rbo}')).map { |x| File.basename(x, File.extname(x)) }.uniq.each do |path|
  if path != main
    require(path)
  end
end

#
# IMKServerに接続
#
identifier = NSBundle.mainBundle.bundleIdentifier
server = IMKServer.alloc.initWithName("Gyaim_Connection",bundleIdentifier:identifier)

# Starting the Cocoa main loop.
NSApplicationMain(0, nil)
