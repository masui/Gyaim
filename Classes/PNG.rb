# coding: UTF-8
# http://d.hatena.ne.jp/ku-ma-me/20091003/p1

require "zlib"

class PNG
  def PNG.chunk(type, data)
    [data.bytesize, type, data, Zlib.crc32(type + data)].pack("NA4A*N")
  end
  
  def PNG.png(data,depth=8,color_type=2)
    height = data.length
    width = data[0].length
    out = "\x89PNG\r\n\x1a\n"
    out.force_encoding("ASCII-8BIT") # 苦しい!
    out += PNG.chunk("IHDR", [width, height, depth, color_type, 0, 0, 0].pack("NNCCCCC"))
    img_data = data.map {|line| ([0] + line.flatten).pack("C*") }.join
    out += PNG.chunk("IDAT", Zlib::Deflate.deflate(img_data))
    out += PNG.chunk("IEND", "")
  end
end

if __FILE__ == $0 then
  width, height = 20, 20
  raw_data = [[[255,255,0]] * width] * height
  pngdata = PNG.png(raw_data)
  
  print pngdata
  exit

  width, height = 20, 10
  
  line = (0...width).map {|x| [x * 255 / width, 0, 0] }
  raw_data = [line] * height
  pngdata = PNG.png(raw_data)
  
  print pngdata
end



