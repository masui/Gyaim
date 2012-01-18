buildandinstall: dictdir xcodebuild install

#
#
#
dictdir:
	-mkdir ~/.gyaimdict

xcodebuild:
	xcodebuild -target Gyaim -configuration Debug
install:
	macruby_deploy --embed build/Debug/Gyaim.app
	cp -r build/Debug/Gyaim.app ~/Library/Input\ Methods

dmg:
	/bin/rm -f Gyaim.dmg
	hdiutil create -srcfolder build/Debug/Gyaim.app -volname Gyaim Gyaim.dmg

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
