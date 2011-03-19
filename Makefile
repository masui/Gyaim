buildandinstall: xcodebuild install

small: smalldict dictcache buildandinstall
large: largedict dictcache buildandinstall

xcodebuild:
	xcodebuild -target Gyaim -configuration Debug
install:
	cp -r build/Debug/Gyaim.app ~/Library/Input\ Methods
test:
	macruby Tests/run_suite.rb
dictcache:
	ruby -e 'require "WordSearch/WordSearch"; ws = WordSearch.new("Resources/dict.txt"); ws.createDictCache;'
largedict:
	cp Resources/fugodic.txt Resources/dict.txt
smalldict:
	head -20000 Resources/fugodic.txt > Resources/dict.txt
clean:
	/bin/rm -f *~ */*~
