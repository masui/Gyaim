# -*- coding: utf-8 -*-
# Romakana.rb
# Gyaim
#
# Created by Toshiyuki Masui on 2011/3/15.
# Copyright 2011 Pitecan Systems. All rights reserved.
#
#  複数のローマ字表現を考慮したローマ字かな変換ライブラリ。
#
#  rk = Romakana.new
#  rk.hiragana2roma('じしょ') ⇒ ['jisho', 'jisyo', 'zisho', 'zisyo']
#  rk = Romakana.new(File.readlines('rklist.pep')
#  rk.hiragana2roma('じしょ') ⇒ ['jisho', 'jisyo', 'zisho', 'zisyo']
#

# Ruby1.9にはString#eachが存在しないので
class String
  def each
    self.each_line { |line|
      yield line
    }
  end
end

class Romakana
  RKLIST = <<EOF
#
#	標準rklist
#
a	あ	ア
ba	ば	バ
be	べ	ベ
bi	び	ビ
bo	ぼ	ボ
bu	ぶ	ブ
bya	びゃ	ビャ
bye	びぇ	ビェ
byi	びぃ	ビィ
byo	びょ	ビョ
byu	びゅ	ビュ
cha	ちゃ	チャ
che	ちぇ	チェ
chi	ち	チ
cho	ちょ	チョ
chu	ちゅ	チュ
da	だ	ダ
de	で	デ
dha	でゃ	デャ
dhe	でぇ	デェ
dhi	でぃ	ディ
dho	でょ	デョ
dhu	でゅ	デュ
di	ぢ	ヂ
do	ど	ド
du	づ	ヅ
dya	ぢゃ	ヂャ
dye	ぢぇ	ヂェ
dyi	ぢぃ	ヂィ
dyo	ぢょ	ヂョ
dyu	でゅ	デュ
e	え	エ
fa	ふぁ	ファ
fe	ふぇ	フェ
fi	ふぃ	フィ
fo	ふぉ	フォ
fuxyu	ふゅ	フュ
fu	ふ	フ
ga	が	ガ
ge	げ	ゲ
gi	ぎ	ギ
go	ご	ゴ
gu	ぐ	グ
gya	ぎゃ	ギャ
gye	ぎぇ	ギェ
gyi	ぎぃ	ギィ
gyo	ぎょ	ギョ
gyu	ぎゅ	ギュ
ha	は	ハ
he	へ	ヘ
hi	ひ	ヒ
ho	ほ	ホ
hu	ふ	フ
hya	ひゃ	ヒャ
hye	ひぇ	ヒェ
hyi	ひぃ	ヒィ
hyo	ひょ	ヒョ
hyu	ひゅ	ヒュ
i	い	イ
ja	じゃ	ジャ
je	じぇ	ジェ
ji	じ	ジ
jo	じょ	ジョ
ju	じゅ	ジュ
ka	か	カ
ke	け	ケ
ki	き	キ
ko	こ	コ
ku	く	ク
kya	きゃ	キャ
kye	きぇ	キェ
kyi	きぃ	キィ
kyo	きょ	キョ
kyu	きゅ	キュ
ma	ま	マ
me	め	メ
mi	み	ミ
mo	も	モ
mu	む	ム
mya	みゃ	ミャ
mye	みぇ	ミェ
myi	みぃ	ミィ
myo	みょ	ミョ
myu	みゅ	ミュ
#n'	ん	ン
nn	ん	ン
na	な	ナ
ne	ね	ネ
ni	に	ニ
no	の	ノ
nu	ぬ	ヌ
nya	にゃ	ニャ
nye	にぇ	ニェ
nyi	にぃ	ニィ
nyo	にょ	ニョ
nyu	にゅ	ニュ
o	お	オ
pa	ぱ	パ
pe	ぺ	ペ
pi	ぴ	ピ
po	ぽ	ポ
pu	ぷ	プ
pya	ぴゃ	ピャ
pye	ぴぇ	ピェ
pyi	ぴぃ	ピィ
pyo	ぴょ	ピョ
pyu	ぴゅ	ピュ
ra	ら	ラ
re	れ	レ
ri	り	リ
ro	ろ	ロ
ru	る	ル
rya	りゃ	リャ
rye	りぇ	リェ
ryi	りぃ	リィ
ryo	りょ	リョ
ryu	りゅ	リュ
sa	さ	サ
se	せ	セ
sha	しゃ	シャ
she	しぇ	シェ
shi	し	シ
sho	しょ	ショ
shu	しゅ	シュ
si	し	シ
so	そ	ソ
su	す	ス
sya	しゃ	シャ
sye	しぇ	シェ
syi	しぃ	シィ
syo	しょ	ショ
syu	しゅ	シュ
ta	た	タ
te	て	テ
tha	てゃ	テャ
the	てぇ	テェ
thi	てぃ	ティ
tho	てょ	テョ
thu	てゅ	テュ
ti	ち	チ
to	と	ト
tsu	つ	ツ
tu	つ	ツ
tya	ちゃ	チャ
tye	ちぇ	チェ
tyi	ちぃ	チィ
tyo	ちょ	チョ
tyu	ちゅ	チュ
u	う	ウ
va	う゛ぁ	ヴァ
ve	う゛ぃ	ヴェ
vi	う゛ぅ	ヴィ
vo	う゛ぉ	ヴォ
vu	う゛	ヴ
wa	わ	ワ
we	うぇ	ウェ
wi	うぃ	ウィ
wo	を	ヲ
xa	ぁ	ァ
xe	ぇ	ェ
xi	ぃ	ィ
xo	ぉ	ォ
xtu	っ	ッ
xtsu	っ	ッ
xu	ぅ	ゥ
xwa	ゎ	ヮ
ya	や	ヤ
yo	よ	ヨ
yu	ゆ	ユ
za	ざ	ザ
ze	ぜ	ゼ
zi	じ	ジ
zo	ぞ	ゾ
zu	ず	ズ
zya	じゃ	ジャ
zye	じぇ	ジェ
zyi	じぃ	ジィ
zyo	じょ	ジョ
zyu	じゅ	ジュ
xya	ゃ	ャ
xyu	ゅ	ュ
xyo	ょ	ョ
-	ー	ー
EOF

  def initialize(rklist=nil, no_tsu=false)
    @rklist = (rklist ? rklist : RKLIST)
    @kkr = {}
    @hkr = {}
    @krk = {}
    @hrk = {}
    @rklist.each { |line|
      line.chomp!
      next if line =~ /^#/
      (roma, hira, kata) = line.split(/\s+/)
      @kkr[kata] = [] if @kkr[kata].nil?
      @kkr[kata] << roma
      @hkr[hira] = [] if @hkr[hira].nil?
      @hkr[hira] << roma
#      @krk[roma] = [] if @krk[roma].nil?
#      @krk[roma] << kata
#      @hrk[roma] = [] if @hrk[roma].nil?
#      @hrk[roma] << hira
      @krk[roma] = kata
      @hrk[roma] = hira
    }
    @no_tsu = no_tsu
  end

  def katakana2roma(s)
$s = s
    r1 = krexpand('',s,false,[],@kkr)
    r2= r1.find_all { |r|
      r !~ /ix|ux/ # vuxaiorin のようなものを除去
    }
    r2.length == 0 ? r1 : r2
  end
  
  def hiragana2roma(s)
$s = s
    r1 = krexpand('',s,false,[],@hkr)
    r2= r1.find_all { |r|
      r !~ /ix|ux/ # vuxaiorin のようなものを除去
    }
    r2.length == 0 ? r1 : r2
  end
  
  def krexpand(a,b,t,result,kr)
#    puts "krexpand(#{a}, #{b}, #{t})"
    if t then # 「ッ」の処理
      b =~ /^(.)/
      k = $1
      if k then
        if kr[k] then
          rs = kr[k]
          rs.each { |r|
            kr[k] = r
            if r =~ /^([bcdfghjklmpqrstvwxyz])/ then
              krexpand(a + $1, b, false, result, kr)
            else
              kr[t].each { |rr|
                krexpand(a + rr, b, false, result, kr)
              }
            end
          }
          kr[k] = rs
        end
      else
if kr[t].nil? then
#puts "t = <#{t}>"
#puts $s
#puts kr.keys
else
        kr[t].each { |r|
          result << a + r
        }
end
      end
      return result
    end
    
    if b == '' then
      a.gsub!(/n'([bcdfghjklmnpqrstvwxz])/, "n\\1")
      a.sub!(/n'$/,'n')
      result << a
      return result
    else
      if b =~ /^(((.).).)(.*)$/ then # 「う゛ぁ」など
        k = $1
        k1 = $2
        k2 = $3
        c = $4
        if kr[k] then
          rs1 = kr[k1]
          rs2 = kr[k2]
#          kr[k1] = nil
#          kr[k2] = nil
          rs = kr[k]
          rs.each { |r|
            kr[k] = r
            krexpand(a+r, c, false, result, kr)
          }
          kr[k] = rs
          kr[k1] = rs1
          kr[k2] = rs2
        end
      end
      if b =~ /^((.).)(.*)$/ then # 「しゃ」など
        k = $1
        k1 = $2
        c = $3
        if kr[k] then
          rs1 = kr[k1]
#          kr[k1] = nil
          rs = kr[k]
          rs.each { |r|
            kr[k] = r
            krexpand(a+r, c, false, result, kr)
          }
          kr[k] = rs
          kr[k1] = rs1
        end
      end
      if b =~ /^(.)(.*)$/ then
        k = $1
        c = $2
        rs = kr[k]
        if rs && (@no_tsu || (k != 'ッ' && k != 'っ')) then
          rs.each { |r|
            kr[k] = r
            krexpand(a+r, c, false, result, kr)
          }
        end
        if (k == 'ッ' || k == 'っ') && !@no_tsu then
          krexpand(a, c, k, result, kr);
        end
        kr[k] = rs
      end
    end
    return result
  end

  def roma2hiragana(roma)
    okay = true
    kana = ''
    ind = 0

    while ind < roma.length do
      found = false
      @hrk.each { |r, h|
        len = r.length
        if roma[ind,len] == r then
          kana += h
          ind += len
          found = true
          break
        end
      }
      if !found then
        r0 = roma[ind,1]
        r1 = roma[ind+1,1]
        if (r0 == 'n' || r0 == 'N') && "bcdfghjklmnpqrstvwxz".index(r1) then
          kana += "ん"
          ind += 1
        else
          if "bcdfghjklmpqrstvwxyz".index(r0) && r0 == r1 then
            kana += "っ"
            ind += 1
          else
            if (r0 == 'n' || r0 == 'N') && ! r1 then
              kana += "ん"
              ind += 1
            else
              ind += 1
              okay = false
            end
          end
        end
      end
    end
    okay ? [kana] : [kana]
  end

  def roma2katakana(roma)
    okay = true
    kana = ''
    ind = 0

    while ind < roma.length do
      found = false
      @krk.each { |r, k|
        len = r.length
        if roma[ind,len] == r then
          kana += k
          ind += len
          found = true
          break
        end
      }
      if !found then
        r0 = roma[ind,1]
        r1 = roma[ind+1,1]
        if (r0 == 'n' || r0 == 'N') && "bcdfghjklmnpqrstvwxz".index(r1) then
          kana += "ン"
          ind += 1
        else
          if "bcdfghjklmpqrstvwxyz".index(r0) && r0 == r1 then
            kana += "ッ"
            ind += 1
          else
            if (r0 == 'n' || r0 == 'N') && ! r1 then
              kana += "ン"
              ind += 1
            else
              ind += 1
              okay = false
            end
          end
        end
      end
    end
    okay ? [kana] : [kana]
  end
end

class String
  @@rk = Romakana.new

  def roma2hiragana
    @@rk.roma2hiragana(self)[0].to_s
  end

  def roma2katakana
    @@rk.roma2katakana(self)[0].to_s
  end

  def hiragana2roma
    @@rk.hiragana2roma(self)[0].to_s
  end

  def katakana2roma
    @@rk.katakana2roma(self)[0].to_s
  end
end


