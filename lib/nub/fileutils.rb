#MIT License
#Copyright (c) 2017-2018 phR0ze
#
#Permission is hereby granted, free of charge, to any person obtaining a copy
#of this software and associated documentation files (the "Software"), to deal
#in the Software without restriction, including without limitation the rights
#to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#copies of the Software, and to permit persons to whom the Software is
#furnished to do so, subject to the following conditions:
#
#The above copyright notice and this permission notice shall be included in all
#copies or substantial portions of the Software.
#
#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#SOFTWARE.

require 'fileutils'

# Monkey patch FileUtils with some useful methods
module FileUtils

  # Check PATH for executable
  # @param name [String] name of executable to find
  # @param path [Array] path to search
  # @return path of executable or nil
  def self.exec?(name, path:nil)
    (path || ENV['PATH'].split(File::PATH_SEPARATOR).uniq).each{|dir|
      target = File.join(dir, name)
      if stat = File.stat(target) rescue nil
        return target if stat.file? && stat.executable?
      end
    }
    return nil
  end

  # Increment SemVer formatted versions
  # @param path [String] file to increment version for
  # @param regex [Regex] capture pattern for version match
  # @param major [Bool] true then increment the major
  # @param minor [Bool] true then increment the minor
  # @param rev [Bool] true then increment the revision
  # @param override [String] value to use for version if set
  # @return new version
  def self.inc_version(path, regex, major:false, minor:false, rev:true, override:nil)
    version = nil
    self.update(path){|line|

      # Increment version
      if ver = line[regex, 1]
        new_ver = nil
        if not override
          new_ver = ver.strip.split('.')
          new_ver[0] = new_ver[0].to_i + 1 if major
          new_ver[1] = new_ver[1].to_i + 1 if minor
          new_ver[2] = new_ver[2].to_i + 1 if rev
          new_ver = new_ver * '.'
        else
          new_ver = override
        end

        # Modify the original line
        version = new_ver
        line.gsub!(ver, new_ver)
      end
    }

    return version
  end

  # Update the file using a block, revert on failure.
  # Use this for simple line edits. Block is passed in each line of the file
  # @param filename [String] name of the file to change
  # @return true on change
  def self.update(filename)
    changed = false
    block = Proc.new # Most efficient way to get block

    begin
      lines = nil
      File.open(filename, 'r+'){|f|
        lines = f.readlines
        lines.each{|line|
          line_copy = line.dup
          block.call(line)
          changed |= line_copy != line
        }

        # Save the changes back to the file
        f.seek(0)
        f.truncate(0)
        f.puts(lines)
      }
    rescue
      # Revert back to the original incase of failure
      File.open(filename, 'w'){|f| f.puts(lines)} if lines
      raise
    end

    return changed
  end

  # Check copyright and update if required
  # @param path [String] path of the file to update
  # @param copyright [String] copyright match string e.g. Copyright (c)
  # @param year [String] year to add if needed
  # @return true on change
  def self.update_copyright(path, copyright, year:Time.now.year)
    set_copyright = false

    changed = self.update(path){|line|
      if !set_copyright && line =~ /#{Regexp.quote(copyright)}/
        set_copyright = true
        _year = line[/#{Regexp.quote(copyright)}\s+((\d{4}\s)|(\d{4}-\d{4})).*/, 1].strip
        if _year.include?("-")
          years = _year.split("-")
          line.gsub!(_year, "#{years.first}-#{year}") if years.last != year
        elsif prev_year = _year != year.to_s ? year.to_i - 1 : nil
          line.gsub!(_year.to_s, "#{prev_year}-#{year}")
        end
      end
    }
    return changed
  end

  # Get SemVer formatted versions
  # @param path [String] file to increment version for
  # @param regex [Regex] capture pattern for version match
  # @return version
  def self.version(path, regex)
    if File.file?(path)
      File.readlines(path).each{|line|
        if ver = line[regex, 1]
          return ver
        end
      }
    end
    return nil
  end
end

# vim: ft=ruby:ts=2:sw=2:sts=2
