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

require 'digest'
require 'fileutils'
require 'yaml'

require_relative 'core'

# Monkey patch FileUtils with some useful methods
module FileUtils

  # Check if any digests have changed based on the given files
  # @param key [yaml] yalm section heading to give digests
  # @param digestfile [string] digest file to check against
  # @param files [array] files to get digests for
  # @returns (newfiles, modifiedfiles, deletedfiles)
  def self.digests_changed?(key, digestfile, files)
    files = [files] if files.is_a?(String)
    newfiles, modifiedfiles, deletedfiles = [], [], []

    # Since layers are stacked and the digest file may be from a lower
    # layer this should be ignored unless the layer matches
    if (digests = File.exist?(digestfile) ? YAML.load_file(digestfile)[key] : nil)

      # New files: in files but not yaml
      newfiles = files.select{|x| not digests[x]}

      # Delete files: in yaml but not files
      deletedfiles = digests.map{|k,v| k}.select{|x| not files.include?(x)}

      # Modified files: in both but digest is different
      modifiedfiles = files.select{|x| digests[x] and
        Digest::MD5.hexdigest(File.binread(x)) != digests[x]}
    else
      newfiles = files
    end

    return newfiles, modifiedfiles, deletedfiles
  end


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
    self.update(path){|data|

      # Increment version
      line = data.split("\n").find{|x| x[regex, 1]}
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
        newline = line.gsub(ver, new_ver)
        data.gsub!(line, newline)
      end
    }

    return version
  end

  # Insert into a file
  # Location of insert is determined by the given regex and offset.
  # Append is used if no regex is given.
  # @param file [string] path of file to modify
  # @param values [array] string or list of string values to insert
  # @param regex [string] regular expression for location, not used if offset is nil
  # @param offset [int] offset insert location by this amount for regexs
  # @returns true if a change was made to the file
  def self.insert(file, values, regex:nil, offset:1)
    return false if not values or values.empty?

    values = [values] if values.is_a?(String)
    FileUtils.touch(file) if not File.exist?(file)

    changed = self.update(file){|data|
      lines = data.split("\n")

      # Match regex for insert location
      regex = Regexp.new(regex) if regex.is_a?(String)
      if i = regex ? lines.index{|x| x =~ regex} : lines.size
        i += offset if regex and offset

        # Insert at offset
        values.each{|x| lines.insert(i, x) and i += 1}

        # Change data inline
        newdata = lines * "\n"
        newdata += "\n" if data[-1] == "\n"
        data.gsub!(data, newdata)
      end
    }

    return changed
  end


  # Replace in file
  # @param file [string] file to modify
  # @param regex [string] regular expression match on
  # @param value [string] regular expression string replacement
  # @returns true on change
  def self.replace(file, regex, value)
    changed = self.update(file){|data|
      lines = data.split("\n")

      # Search replace
      regex = Regexp.new(regex) if regex.is_a?(String)
      lines.each{|x| x.gsub!(regex, value)}

      # Change data inline
      newdata = lines * "\n"
      newdata += "\n" if data[-1] == "\n"
      data.gsub!(data, newdata)
    }

    return changed
  end

  # Resolve template
  # @param file [string] file to resolve templates for
  # @param vars [hash/ostruct] templating variables to use while resolving
  # @returns true on change
  def self.resolve(file, vars)
    return self.update(file){|data| data.erb!(vars)}
  end

  # Update the file using a block, revert on failure.
  # Use this for file edits. Block is passed in the file data
  # @param filename [String] name of the file to change
  # @return true on change
  def self.update(filename)
    changed = false
    block = Proc.new # Most efficient way to get block

    begin
      data = nil
      File.open(filename, 'r+'){|f|
        data = f.read
        data_orig = data.dup

        # Call block
        block.call(data)
        changed |= data_orig != data

        # Save the changes back to the file
        if changed
          f.seek(0)
          f.truncate(0)
          f << data
        end
      }
    rescue Exception => e
      # Revert back to the original incase of failure
      File.open(filename, 'w'){|f| f << data} if data
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

    changed = self.update(path){|data|
      line = data.split("\n").find{|x| x[/#{Regexp.quote(copyright)}/]}
      if !set_copyright && line =~ /#{Regexp.quote(copyright)}/
        set_copyright = true
        _year = line[/#{Regexp.quote(copyright)}\s+((\d{4}\s)|(\d{4}-\d{4})).*/, 1].strip
        if _year.include?("-")
          years = _year.split("-")
          if years.last != year
            newline = line.gsub(_year, "#{years.first}-#{year}")
            data.gsub!(line, newline)
          end
        elsif prev_year = _year != year.to_s ? year.to_i - 1 : nil
          newline = line.gsub(_year.to_s, "#{prev_year}-#{year}")
          data.gsub!(line, newline)
        end
      end
    }
    return changed
  end

  # Generate digests for array of files given and save them
  # @param key [yaml] yalm section heading to give digests
  # @param digestfile [string] digest file to update
  # @param files [array] files to get digests for
  def self.update_digests(key, digestfile, files)
    files = [files] if files.is_a?(String)

    # Build up digests structure
    digests = {}
    files.each{|x| digests[x] = Digest::MD5.hexdigest(File.binread(x)) if File.exist?(x)}

    # Write out digests structure as yaml with named header
    File.open(digestfile, 'w'){|f| f.puts({key => digests}.to_yaml)}
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
