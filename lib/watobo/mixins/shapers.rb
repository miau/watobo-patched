# .
# shapers.rb
# 
# Copyright 2012 by siberas, http://www.siberas.de
# 
# This file is part of WATOBO (Web Application Tool Box)
#        http://watobo.sourceforge.com
# 
# WATOBO is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation version 2 of the License.
# 
# WATOBO is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with WATOBO; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
# .
module Watobo
  module Mixin
    module Shaper
      module Web10
        include Watobo::Constants
        def replace_post_parm(parm,value)
          parm_quoted = Regexp.quote(parm)
          self.last.gsub!(/([?&]{0,1})#{parm_quoted}=([0-9a-zA-Z\-\._,+<>\%!=]*)(&{0,1})/i, "\\1#{parm}=#{value}\\3")
        end

        def replace_get_parm(parm,value)
          parm_quoted = Regexp.quote(parm)
          # puts "replacing parameter #{parm} with value #{value}"
          # self.first.gsub!(/([?&]{0,1})#{parm}=([0-9a-zA-Z\-\._,+<>\%!=]*)(&{0,1})/i, "\\1#{parm}=#{value}\\3")
          self.first.gsub!(/([?&]{1})#{parm_quoted}=([^ &]*)(&{0,1})/i, "\\1#{parm}=#{value}\\3")
        end

        def replaceMethod(new_method)
          self.first.gsub!(/^[^[:space:]]{1,}/i, "#{new_method}")
        end

        def replaceFileExt(new_file)
          #   puts "replace element #{new_element}"
          begin
            new_file.gsub!(/^\//, "")
            self.first.gsub!(/([^\?]*\/)(.*) (HTTP.*)/i,"\\1#{new_file} \\3")
          rescue => bang
            puts bang
          end
        end

        def replaceElement(new_element)
          #   puts "replace element #{new_element}"
          new_element.gsub!(/^\//, "")
          self.first.gsub!(/(.*\/)(.*) (HTTP.*)/i,"\\1#{new_element} \\3")
        end

        def replaceURL(new_url)
          self.first.gsub!(/(^[^[:space:]]{1,})(.*) (HTTP.*)/i,"\\1 #{new_url} \\3")
        end

        def replaceQuery(new_query)
          new_query.gsub!(/^\//, "")
          self.first.gsub!(/(.*\/)(.*) (HTTP.*)/i,"\\1#{new_query} \\3")
        end

        def strip_path()
          if self.first =~ /(^[^[:space:]]{1,} https?:\/\/[\-0-9a-zA-Z.]*[:0-9]{0,6}[^\?]*\/).* (HTTP.*)/i then
            new_line = "#{$1} #{$2}"
          self.shift
          self.unshift(new_line)
          end
        # puts "* StripPath: #{self.first}"
        end

        def setDir(dir)
          dir.strip!
          dir.gsub!(/^\//,"")
          dir.gsub!(/\/$/,"")
          dir += "/" unless dir == ''
          self.first.gsub!(/(^[^[:space:]]{1,} https?:\/\/[\-0-9a-zA-Z.]*[:0-9]{0,6}\/)(.*)( HTTP\/.*)/, "\\1#{dir}\\3")
        end

        def appendDir(dir)
          dir.gsub!(/^\//,"")
          self.first.gsub!(/(^[^[:space:]]{1,} https?:\/\/[\-0-9a-zA-Z.]*[:0-9]{0,6}.*\/).*( HTTP\/.*)/, "\\1#{dir}\\2")

        end

        def add_post_parm(parm,value)
          line = self.last
          return false if line !~ /=/
          line += "&#{parm}=#{value}"
          self.pop
          self.push line
        end

        def add_get_parm(parm,value)
          line = self.shift
          new_p = "&"
          new_p = "?" if not self.element =~ /\?/
          new_p += parm
          line.gsub!(/( HTTP\/.*)/, "#{new_p}=#{value}\\1")
          self.unshift(line)
        end

        def addHeader(header, value)
          self_copy = []
          self_copy.concat(self.headers)
          self_copy.push "#{header}: #{value}\r\n"

          unless self.body.nil?
            self_copy.push "\r\n"
          #self_copy.concat(self.body)
          self_copy.push self.body
          end

          self.replace(self_copy)

        end

        def removeURI
          if self.first =~ /(^[^[:space:]]{1,}) (https?:\/\/[\-0-9a-zA-Z.]*[:0-9]{0,6}\/)/ then
            uri = $2
            self.first.gsub!(/(^[^[:space:]]{1,}) (#{Regexp.quote(uri)})/,"\\1 /")
          # puts "* Removed URI: #{uri}"
          # puts self.first
          return uri
          else
            return nil
          end
        #self.first.gsub!(/^(.*)(https?:\/\/[\-0-9a-zA-Z.]*[:0-9]{0,6}\/)/,"\\1/")
        end

        def removeBody
          self.pop if self[-2].strip.empty?
        end

        def set_header(header, value)
          self.each do |h|
            break if h.strip.empty?
            if h =~ /^#{header}:/
              h.replace "#{header}: #{value}\r\n"             
            end
          end
        end

        def set_body(content)
          if self[-2].strip.empty?
          self.pop
          else
            self << "\r\n"
          end
          self << content
        end

        def rewrite_body(pattern, content)
          if self[-2].strip.empty?
            puts "rewrite_body ... #{pattern} - #{content}"
            b = self.pop
            b.gsub!(/#{pattern}/i, content)
          self << b
          end
        end

        def restoreURI(uri)
          if self.first =~ /(^[^[:space:]]{1,}) \/(.*) (HTTP\/.*)/ then
            method = $1
            rest = $2
            http = $3.strip
            #self.first.gsub!(/^\w*/, "#{method} #{uri}#{rest}")
            self.shift
            self.unshift "#{method} #{uri}#{rest} #{http}\r\n"
          return self.first
          else
            return nil
          end
        #self.first.gsub!(/^(.*)(https?:\/\/[\-0-9a-zA-Z.]*[:0-9]{0,6}\/)/,"\\1/")
        end

        #
        # R E M O V E _ H E A D E R
        #

        def removeHeader(header)
          begin
            eoh_index = self.length
            eoh_index -= 1 unless self.body.nil?

            self.delete_if {|x| self.index(x) <= eoh_index and x =~ /#{header}/i }
          rescue => bang
            puts bang
            puts bang.backtrace if $DEBUG
            puts self
            puts "====="
          end
        end

        # removeUrlParms
        # Function: Remove all parameter within the URL
        #
        def removeUrlParms
          line = self.shift
          new_line = "#{line}"
          # get end-of-path-index
          eop_index = line.rindex(/[^ HTTP]\//)
          # get start of parms
          sop_index = line.index(/(\?|&)/, eop_index)
          # find end-of-url
          eou_index = line.index(/ HTTP/)

          unless sop_index.nil?
          new_line = line[0..sop_index-1]
          new_line += line[eou_index..-1]
          end

          self.unshift new_line
        end

        def removeHeader_OLD(header)
          #  p "REMOVE HEADER: #{header}"
          begin
            self_copy = []
            eoh = false
            self.each do |line|
              puts self if line.nil?
              if not eoh == true then
                if not line =~ /#{header}/i
                self_copy.push line unless line.nil?
                end
              else
              self_copy.push line unless line.nil?
              end

              if line and line.strip.empty? then
              eoh = true
              end
            end
            self.replace(self_copy)

          rescue => bang
            puts bang
            puts bang.backtrace if $DEBUG
            puts self
            puts "====="
          end
        end

        def replace_header(header, value)

        end

        def fix_session(pattern,value)

        end

        def fix_content_length
          return false if self.body.nil?
          set_header("Content-Length" , body.length.to_s )
        #          eoh_index = self.length - 2
        #          self.map!{ |x|
        #            x.gsub!(/^(Content-Length: )(\d+)/, "\\1#{self.body.length.to_s}") if self.index(x) <= eoh_index
        #            x
        #          }
        end

        def fixupContentLength_UNUSED
          te = self.transferEncoding
          if te == TE_CHUNKED then
            # puts "Transfer-Encoding = TE_CHUNKED"
            # puts self.body
            self.removeHeader("Transfer-Encoding")
            self.addHeader("Content-Length", "0")
            new_r = []
            new_r.concat self.headers
            new_r.push "\r\n"

            bytes_to_read = 0
            body = []
            is_new_chunk = false

            off = 0
            new_body = ''

            body_orig = self.body
            puts body_orig.class
            while body_orig[off..-1] =~ /^([0-9a-fA-F]{1,6})\r\n/
              len_raw = "#{$1}"

              len = len_raw.hex

              chunk_start = off + len_raw.length + 2
              chunk_end = chunk_start + len

              break if len == 0

              new_body.chomp!
              new_body += "#{body_orig[chunk_start..chunk_end]}"

              off = chunk_end + 2
            end

          new_r.push new_body
          self.replace(new_r)
          self.fix_content_length
          # puts "= FIXED ="
          # puts self.headers
          elsif te == TE_NONE then
          self.fix_content_length
          end

        end

        def fixupContentLength
          self.unchunk
          self.fix_content_length
        end

        def setRawQueryParms(parm_string)
          return nil if parm_string.nil?
          return nil if parm_string == ''
          new_r = ""
          path = Regexp.quote(self.path)
          #puts path
          if self.first =~ /(.*#{path})/ then
            new_r = $1 << "?" << parm_string
          end
          self.first.gsub!(/(.*) (HTTP\/.*)/, "#{new_r} \\2")
        end

        def appendQueryParms(parms)
          return if parms.nil?
          return if parms == ''

          puts self.first
          puts self.file_ext

          pref = (self.file_ext =~ /\?/) ? '&' : '?'
          puts "append query parms"
          self.first.gsub!(/(.*) (HTTP\/.*)/, "\\1#{pref}#{parms} \\2")

        end

        def setCookie(cname="Cookie", value=nil)
          return nil if value.nil?

          self.map!{ |l|
            break if l.strip.empty?
            if l =~ /^#{cname}:/i
              l = "#{cname}: #{value}"
            end
          }
        end

        # sets post data
        def setData(data)
          return if data.nil?
          if self.has_body?
          self.pop
          self.push data
          else
            self.push("\r\n")
          self.push data
          end
        end

        def setMethod(method)
          self.first.gsub!(/(^[^[:space:]]{1,}) /, "#{method} ")
        end

        def setHTTPVersion(version)
          self.first.gsub!(/HTTP\/(.*)$/, "HTTP\/#{version}")
        #  puts "HTTPVersion fixed: #{self.first}"
        end

        alias :method= :setMethod
      end

      module HttpResponse
        include Watobo::Constants
        def unchunk
          if self.transfer_encoding == TE_CHUNKED then
            self.removeHeader("Transfer-Encoding")
            self.addHeader("Content-Length", "0")
            new_r = []
            new_r.concat self.headers
            new_r.push "\r\n"

            bytes_to_read = 20
            body = []
            is_new_chunk = false

            off = 0
            new_body = ''

            body_orig = self.body
            # puts body_orig.class
            puts body_orig.length
            pattern = '[0-9a-fA-F]{1,6}\r?\n'
            while off >= 0 and off < body_orig.length
              chunk_pos  = body_orig.index(/(#{pattern})/, off)
              len_raw = $1
              unless chunk_pos.nil?
                #len_raw = body_orig.match(/#{pattern}/, chunk_pos)[0]
                # puts "ChunkLen: #{len_raw} (#{len_raw.strip.hex})"
                len = len_raw.strip.hex

                chunk_start = chunk_pos + len_raw.length
                chunk_end = chunk_start + len

                break if len == 0

                #new_body.chomp!
                chunk = "#{body_orig[chunk_start..chunk_end]}"
              new_body += chunk.chomp!

              off = chunk_end
              end
            end
          new_r.push new_body
          self.replace(new_r)
          self.fix_content_length
          # puts "="
          # self.headers.each {|h| puts h}
          # puts "="
          end

        end

        def unzip

          if self.content_encoding == TE_GZIP or self.transfer_encoding == TE_GZIP
            begin
              if self.has_body?
                gziped = self.pop
                gz = Zlib::GzipReader.new( StringIO.new( gziped ) )
                data = gz.read
                #puts data
                self << data
                self.removeHeader("Transfer-Encoding") if self.transfer_encoding == TE_GZIP
                self.removeHeader("Content-Encoding") if self.content_encoding == TE_GZIP
              self.fix_content_length
              end

            rescue => bang
              puts bang
            end
          end
        end

      end
    end
  end
end
