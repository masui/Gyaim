all:
	xcodebuild -target Gyaim -configuration Debug
	cp -r build/Debug/Gyaim.app ~/Library/Input\ Methods
test:
	macruby Tests/run_suite.rb
dict:
	ruby -e 'require "WordSearch/WordSearch"; ws = WordSearch.new("Resources/fugodic.txt"); ws.createDictCache;'
