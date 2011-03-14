//
//  main.m
//  Gyaim
//
//  Created by Toshiyuki Masui on 11/03/14.
//  Copyright __MyCompanyName__ 2011. All rights reserved.
//

#import <MacRuby/MacRuby.h>
#import <InputMethodKit/InputMethodKit.h>

int main(int argc, char *argv[])
{
  return macruby_main("rb_main.rb", argc, argv);
}
