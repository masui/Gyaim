install:
	cp -r build/Debug/Gyaim.app ~/Library/Input\ Methods
test:
	macruby Tests/run_suite.rb
