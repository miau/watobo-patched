module Watobo
  module Utils
    
    # decodes text into UTF-8 string (destructive)
    def Utils.decode!(text)
      if text.valid_encoding? && text.encoding != Encoding::ASCII_8BIT
        if text.encoding != Encoding::UTF_8
          text.encode!(Encoding::UTF_8)
        end
        return text
      end
      
      if text.encoding != Encoding::UTF_8
        text.force_encoding(Encoding::UTF_8)
        if text.valid_encoding?
          return text
        end
      end
      
      text.force_encoding(Encoding::ASCII_8BIT)
      if text.match(/^Content-Type: .*charset=([-A-Za-z0-9_]+)/n) ||
         text.match(/<meta http-equiv="Content-Type" content="[^"]*charset=([-A-Za-z0-9_]+)[^"]*"/n) ||
         text.match(/<\?xml version="1.0" encoding="([^"]*)"/n) ||
         text.match(/@charset "([^"]*)"/n)
        encoding = $1.match(/Shift.JIS/) ? 'Windows-31J' : $1
        File.open('C:/bin/watobo.tmp', 'wb') do |f|
          f.write(text)
        end
        text.encode!(Encoding::UTF_8, encoding, invalid: :replace)
      else
        text.force_encoding(Encoding::UTF_8)
      end
      
      text
    end
    
    # decodes text into UTF-8 string (non-destructive)
    def Utils.decode(text)
      Utils.decode! text.dup
    end
  end
end
