# -*- coding: utf-8 -*-
#
#   Romakana.rbのテスト
#

$KCODE='utf8'

require 'test/unit'
require 'Romakana/Romakana'

class RomakanaTest < Test::Unit::TestCase
  def setup
    @rk = Romakana.new
  end
  
  def teardown
  end
  
  def test_simple
    assert "masui".roma2hiragana, "ますい"
    assert "komatta".roma2hiragana, "こまった"
    assert "hannnya".roma2hiragana, "はんにゃ"
    assert "kippu".roma2hiragana, "きっぷ"
  end

  def test_random
    @hira = "あいうえおぁぃぅぇぉかきくけこがぎぐげごさしすせそざじずぜぞたちつてとっだぢづでどっなにぬねのはひふへほまみむめもやゆよゃゅょらりるれろわをんー".split(//)
    @kata = "アイウエオァィゥェォカキクケコガギグゲゴサシスセソザジズゼゾタチツテトッダヂヅデドッナニヌネノハヒフヘホマミムメモヤユヨャュョラリルレロワヲンーヴ".split(//)
    #
    # ランダムに生成したひらがな/カタカナ文字列をローマ字変換した後
    # かな変換してもとにもどるかのテスト
    #
    # "よぅつしみぉつけ"
    # "おりぬぎぇせたぁ"
    # "またっっいろむむ"
    # ....
    # みたいなのをどんどん生成する
    #
    1000.times { |count|
      h = (0..7).collect { |i|
        @hira[rand(@hira.length)]
      }.join
      romas = @rk.hiragana2roma(h)
      romas.each { |r|
        @rk.roma2hiragana(r).each { |h2|
          assert_equal(h,h2)
        }
      }
    }
    1000.times { |count|
      h = (0..7).collect { |i|
        @kata[rand(@kata.length)]
      }.join
      romas = @rk.katakana2roma(h)
      romas.each { |r|
        @rk.roma2katakana(r).each { |h2|
          assert_equal(h,h2)
        }
      }
    }
  end
end
