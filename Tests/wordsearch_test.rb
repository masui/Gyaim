# -*- coding: utf-8 -*-
#
#   WordSearch.rbのテスト
#

require 'test/unit'
require 'WordSearch/WordSearch'

class WordSearchTest < Test::Unit::TestCase
  def setup
    @ws = WordSearch.new('Resources/dict.txt')
  end
  
  def teardown
  end

  def check(yomi,word,registered)
    found = {}
    @ws.search(yomi)
    @ws.candidates.each { |candidate|
      c = (candidate.class == Array ? candidate[0] : candidate)
      found[c] = true
    }
    assert_equal(found[word],registered)
  end
  
  def test_true
    check('masui','増井',true)
    check('mazui','増井',nil)
    check('henkan','変換',true)
    check('kanji','漢字',true)
    check('kakaka','文字',nil)
  end
end
