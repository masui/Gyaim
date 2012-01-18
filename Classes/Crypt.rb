# -*- coding: utf-8 -*-

require 'openssl'

class Crypt
  #
  # 単語の暗号化登録のために利用する暗号化/複号化ライブラリ
  # ウノウラボから持ってきたもの
  # http://labs.unoh.net/2007/05/ruby.html
  # decryptしても漢字に戻らない不具合あり
  # 
  def Crypt.encrypt(aaa, salt = 'salt')
    puts "encrypt(#{aaa},#{salt})"
    enc = OpenSSL::Cipher::Cipher.new('aes256')
    enc.encrypt
    enc.pkcs5_keyivgen(salt)
    #((enc.update(aaa) + enc.final).unpack("H*")).to_s  # 何故か文字列への変換に失敗することがある...
    ((enc.update(aaa) + enc.final).unpack("H*"))[0]
  rescue
    false
  end

  def Crypt.decrypt(bbb, salt = 'salt')
    dec = OpenSSL::Cipher::Cipher.new('aes256')
    dec.decrypt
    dec.pkcs5_keyivgen(salt)
    (dec.update(Array.new([bbb]).pack("H*")) + dec.final)
  rescue  
    false
  end
end

