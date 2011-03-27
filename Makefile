buildandinstall: xcodebuild install

#
# 富豪辞書の一部から辞書キャッシュを作って変換に利用
#
small: smalldict dictcache buildandinstall
#
# 富豪辞書全部から辞書キャッシュを作って変換に利用
#
large: largedict dictcache buildandinstall

xcodebuild:
	xcodebuild -target Gyaim -configuration Debug
install:
	cp -r build/Debug/Gyaim.app ~/Library/Input\ Methods
dictcache:
	ruby -e 'require "WordSearch/WordSearch"; DictCache.createCache("Resources/dict.txt");'
#	ruby -e 'require "WordSearch/WordSearch"; ws = WordSearch.new("Resources/dict.txt"); ws.createDictCache;'

#
# 富豪辞書を利用
#
largedict:
	cp Resources/fugodic.txt Resources/dict.txt
#
# 富豪辞書の一部を利用
#
smalldict:
	head -20000 Resources/fugodic.txt > Resources/dict.txt

clean:
	/bin/rm -f *~ */*~
#
# Ruby1.9のmacrubyを使うとmake testが失敗するが気にしない
# 1.8なら大丈夫?
#
test:
	macruby Tests/run_suite.rb

push:
	git push pitecan.com:/home/masui/git/Gyaim.git
	git push git@github.com:masui/Gyaim.git