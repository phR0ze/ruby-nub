#!/usr/bin/env ruby
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

require 'minitest/autorun'
require_relative '../lib/nub/fileutils'

class TestFileUtils < Minitest::Test

  def test_exec_success
    mock = Minitest::Mock.new
    mock.expect(:file?, true)
    mock.expect(:executable?, true)
    File.stub(:stat, mock){
      assert_equal('/test/bob', FileUtils.exec?('bob', path:['/test']))
    }
    assert_mock(mock)
  end

  def test_exec_fail
    mock = Minitest::Mock.new
    mock.expect(:file?, false)
    File.stub(:stat, mock){
      assert_nil(FileUtils.exec?('bob', path:['/test']))
    }
    assert_mock(mock)
  end

  def test_update_changed
    data = ['MIT License', 'Copyright (c) 2018 phR0ze', '',
      'Permission is hereby granted, free of charge, to any person obtaining a copy'] * "\n"
    _data = ['MIT License', 'Foobar100', '',
      'Permission is hereby granted, free of charge, to any person obtaining a copy'] * "\n"

    mock = Minitest::Mock.new
    mock.expect(:read, data)
    mock.expect(:seek, nil, [0])
    mock.expect(:truncate, nil, [0])
    mock.expect(:<<, nil){|x| x == _data}

    File.stub(:open, true, mock){
      assert(FileUtils.update('foobar'){|line|
        line.gsub!(/Copyright.*/, 'Foobar100') if line =~ /Copyright/
      })
    }
    assert_mock(mock)
  end

  def test_update_no_change
    data = ['MIT License', 'Copyright (c) 2018 phR0ze'] * "\n"
    mock = Minitest::Mock.new
    mock.expect(:read, data)

    File.stub(:open, true, mock){
      assert(!FileUtils.update('foobar'){|line| })
    }
    assert_mock(mock)
  end


  def test_update_rescue
    data = ['MIT License', 'Copyright (c) 2018 phR0ze', '',
      'Permission is hereby granted, free of charge, to any person obtaining a copy'] * "\n"

    mock = Minitest::Mock.new
    mock.expect(:read, data)
    mock.expect(:<<, nil){|x| x == data}

    File.stub(:open, true, mock){
      assert_raises(RuntimeError){
        FileUtils.update('foobar'){|line| raise RuntimeError.new("foo")}
      }
    }
    assert_mock(mock)
  end

  def test_update_copyright_single_todate_year
    data = ['MIT License', '#Copyright (c) 2018 phR0ze'] * "\n"

    mock = Minitest::Mock.new
    mock.expect(:read, data)

    File.stub(:open, true, mock){
      assert(!FileUtils.update_copyright('filepath', '#Copyright (c)', year:'2018'))
    }
    assert_mock(mock)
  end

  def test_update_copyright_single_outdated_year
    data = ['MIT License', '#Copyright (c) 2017 phR0ze'] * "\n"
    _data = ['MIT License', '#Copyright (c) 2017-2018 phR0ze'] * "\n"

    mock = Minitest::Mock.new
    mock.expect(:read, data)
    mock.expect(:seek, nil, [0])
    mock.expect(:truncate, nil, [0])
    mock.expect(:<<, nil){|x| x == _data}

    File.stub(:open, true, mock){
      assert(FileUtils.update_copyright('filepath', '#Copyright (c)', year:'2018'))
    }
    assert_mock(mock)
  end

  def test_update_copyright_year_range_todate
    data = ['MIT License', '#Copyright (c) 2016-2017 phR0ze'] * "\n"

    mock = Minitest::Mock.new
    mock.expect(:read, data)

    File.stub(:open, true, mock){
      assert(!FileUtils.update_copyright('filepath', '#Copyright (c)', year:'2017'))
    }
    assert_mock(mock)
  end

  def test_update_copyright_year_range_outdated
    data = ['MIT License', '#Copyright (c) 2016-2017 phR0ze'] * "\n"
    _data = ['MIT License', '#Copyright (c) 2016-2018 phR0ze'] * "\n"

    mock = Minitest::Mock.new
    mock.expect(:read, data)
    mock.expect(:seek, nil, [0])
    mock.expect(:truncate, nil, [0])
    mock.expect(:<<, nil){|x| x == _data}

    File.stub(:open, true, mock){
      assert(FileUtils.update_copyright('filepath', '#Copyright (c)', year:'2018'))
    }
    assert_mock(mock)
  end

  def test_inc_version_revision_only
    data = ['MIT License', "   spec.version = '0.0.1'"] * "\n"
    _data = ['MIT License', "   spec.version = '0.0.2'"] * "\n"

    mock = Minitest::Mock.new
    mock.expect(:read, data)
    mock.expect(:seek, nil, [0])
    mock.expect(:truncate, nil, [0])
    mock.expect(:<<, nil){|x| x == _data}

    File.stub(:open, true, mock){
      assert_equal('0.0.2', FileUtils.inc_version('filepath', /\s*spec\.version\s*=.*(\d+\.\d+\.\d+).*/))
    }
    assert_mock(mock)
  end

  def test_inc_version_minor_only
    data = ['MIT License', "   spec.version = '0.0.1'"] * "\n"
    _data = ['MIT License', "   spec.version = '0.1.1'"] * "\n"

    mock = Minitest::Mock.new
    mock.expect(:read, data)
    mock.expect(:seek, nil, [0])
    mock.expect(:truncate, nil, [0])
    mock.expect(:<<, nil){|x| x == _data}

    File.stub(:open, true, mock){
      assert_equal('0.1.1', FileUtils.inc_version('filepath', /\s*spec\.version\s*=.*(\d+\.\d+\.\d+).*/, minor:true, rev:false))
    }
    assert_mock(mock)
  end

  def test_inc_version_all
    data = ['MIT License', "   spec.version = '0.0.1'"] * "\n"
    _data = ['MIT License', "   spec.version = '1.1.2'"] * "\n"

    mock = Minitest::Mock.new
    mock.expect(:read, data)
    mock.expect(:seek, nil, [0])
    mock.expect(:truncate, nil, [0])
    mock.expect(:<<, nil){|x| x == _data}

    File.stub(:open, true, mock){
      assert_equal('1.1.2', FileUtils.inc_version('filepath', /\s*spec\.version\s*=.*(\d+\.\d+\.\d+).*/, major:true, minor:true))
    }
    assert_mock(mock)
  end

  def test_version
    data = ['MIT License', "   spec.version = '0.0.1'"]
    regex = /\s*spec\.version\s*=.*(\d+\.\d+\.\d+).*/

    File.stub(:file?, true){
      File.stub(:readlines, data){
        assert_equal('0.0.1', FileUtils.version('foobar', regex))
      }
    }
  end
end

class TestReplace < Minitest::Test

  def setup
    @file = 'foo'
    @vars ||= {'arch' => 'x86_64','release' => '4.7.4-1', 'distro' => 'cyberlinux'}
    @mock = Minitest::Mock.new
    @mock.expect(:seek, nil, [0])
    @mock.expect(:truncate, nil, [0])

    @replace_lam ||= ->(mock, file, regex, value){
      File.stub(:open, true, mock){
        FileUtils.replace(file, regex, value)
      }
    }
  end

  def test_replace_with_regex_comment_multiline
    data = ['UseFooBar=true', 'UncleBob=false'] * "\n"
    _data = ['#UseFooBar=true', '#UncleBob=false'] * "\n"
    @mock.expect(:read, data)
    @mock.expect(:<<, nil){|x|
      print("Failed puts with: ", x) if x != _data
      x == _data
    }

    # Weird, needs the ^ to not insert # at begining and end
    assert(@replace_lam[@mock, @file, /^(.*)/, '#\1'])
    assert_mock(@mock)
  end

  def test_replace_with_regex_set_value
    data = ['UseFooBar=true', 'UncleBob=false'] * "\n"
    _data = ['UseFooBar=false', 'UncleBob=false'] * "\n"
    @mock.expect(:read, data)
    @mock.expect(:<<, nil){|x| x == _data}

    assert(@replace_lam[@mock, @file, /(UseFooBar)=.*/, '\1=false'])
    assert_mock(@mock)
  end

  def test_replace_with_regex_uncomment_multiline
    data = ['#UseFooBar=true', '#UncleBob=false'] * "\n"
    _data = ['UseFooBar=true', 'UncleBob=false'] * "\n"
    @mock.expect(:read, data)
    @mock.expect(:<<, nil){|x| x == _data}

    assert(@replace_lam[@mock, @file, /^#(.*)/, '\1'])
    assert_mock(@mock)
  end

  def test_replace_with_regex_and_remember_change
    data = ['bar1', '<%= distro %>', 'bar3']
    _data = data.clone
    _data[1] = '<%= bar2 %>'
    @mock.expect(:read, data * "\n")
    @mock.expect(:<<, nil){|x| x == _data * "\n"}

    assert(@replace_lam[@mock, @file, /(.*)distro(.*)/, '\1bar2\2'])
    assert_mock(@mock)
  end

  def test_replace_with_regex_multiple
    data = ["position='top'",
      "dock-items=['lxterminal.dockitem','filezilla.dockitem','chromium.dockitem']",
      "pinned-only=true"]
    _data = data.clone
    newdata = ",'virtualbox.dockitem','calc.dockitem'"
    _data[1] = "dock-items=['lxterminal.dockitem','filezilla.dockitem','chromium.dockitem'#{newdata}]"
    @mock.expect(:read, data * "\n")
    @mock.expect(:<<, nil){|x| x == _data * "\n"}

    assert(@replace_lam[@mock, @file, /(dock-items.*)(\].*)/, "\\1#{newdata}\\2"])
    assert_mock(@mock)
  end

  def test_replace_with_regex_multiple_quotes
    data = ["position='top'",
      "dock-items=['lxterminal.dockitem','filezilla.dockitem','chromium.dockitem']",
      "pinned-only=true"]
    _data = data.clone
    newdata = "'virtualbox.dockitem',"
    _data[1] = "dock-items=['lxterminal.dockitem',#{newdata}'filezilla.dockitem','chromium.dockitem']"
    @mock.expect(:read, data * "\n")
    @mock.expect(:<<, nil){|x| x == _data * "\n"}

    assert(@replace_lam[@mock, @file, /(dock-items.*)('filezilla.*)/, "\\1#{newdata}\\2"])
    assert_mock(@mock)
  end

  def test_replace_with_regex_and_no_change
    data = ['bar1', '<%= distro %>', 'bar3']
    _data = data.clone
    @mock.expect(:read, data * "\n")

    refute(@replace_lam[@mock, @file, /(.*)bistro(.*)/, '\1bar2\2'])
  end

  def test_replace_rescue
    data = ['bar1', 'bar2', 'bar3']
    @mock = Minitest::Mock.new
    @mock.expect(:read, nil) # passing in wrong type here to make it fail

    File.stub(:open, true, @mock){
      assert_raises(NoMethodError){FileUtils.replace(@file, /.*foo/, 'foo')}
    }
    assert_mock(@mock)
  end
end

class TestResolve < Minitest::Test

  def setup
    @vars ||= {'arch' => 'x86_64','release' => '4.7.4-1', 'distro' => 'cyberlinux'}
    @mock = Minitest::Mock.new
    @mock.expect(:seek, nil, [0])
    @mock.expect(:truncate, nil, [0])

    @resolve_lam ||= ->(mock, file, vars){
      File.stub(:open, true, mock){
        FileUtils.resolve(file, vars)
      }
    }
  end

  def teardown
    assert_mock(@mock)
  end

  def test_resolve_missing_var
    data = ["bar1", "<%= bar %>", "bar3"] * "\n"
    @mock = Minitest::Mock.new
    @mock.expect(:read, data)
    @mock.expect(:<<, data, [data])

    File.stub(:open, true, @mock){
      assert_raises(NameError){FileUtils.resolve('foo', @vars)}
    }
  end

  def test_resolve_with_change
    data = ["bar1", "<%= distro %>", "bar3"] * "\n"
    _data = ["bar1", "cyberlinux", "bar3"] * "\n"
    @mock.expect(:read, data)
    @mock.expect(:<<, nil){|x| x == _data}

    assert(@resolve_lam[@mock, 'foo', @vars])
  end

  def test_resolve_with_single_file_and_no_change
    data = ["bar1", "bar2", "bar3"] * "\n"
    @mock = Minitest::Mock.new
    @mock.expect(:read, data)

    refute(@resolve_lam[@mock, 'foo', @vars])
  end
end

class TestInsert < Minitest::Test

  def setup
    @file ||= 'foo'
    @mock = Minitest::Mock.new
    @mock.expect(:seek, nil, [0])
    @mock.expect(:truncate, nil, [0])

    @insert_lam ||= ->(mock, file, values, regex:nil, offset:1){
      FileUtils.stub(:touch, true, file){
        File.stub(:exist?, false, file){
          File.stub(:open, true, mock){
            FileUtils.insert(file, values, regex:regex, offset:offset)
          }
        }
      }
    }
  end

  def teardown
    assert_mock(@mock)
  end

  # Test Regex
  #-----------------------------------------------------------------------------
  def test_insert_multi_matching_regex_existing_file_with_neg_offset
    values = ['foo1', 'foo2']
    data = ['bar1', 'bar2', 'bar3']
    @mock.expect(:read, data * "\n")
    @mock.expect(:<<, nil){|x| x == (values + data) * "\n"}

    assert(@insert_lam[@mock, @file, values, regex:/.*bar2.*/, offset:-1])
  end

  def test_insert_multi_matching_regex_existing_file_with_zero_offset
    values = ['foo1', 'foo2']
    data = ['bar1', 'bar2', 'bar3']
    _data = data * "\n"
    data.insert(1, values.first)
    data.insert(2, values.last)
    @mock.expect(:read, _data)
    @mock.expect(:<<, nil){|x| x == data * "\n"}

    assert(@insert_lam[@mock, @file, values, regex:/.*bar2.*/, offset:0])
  end

  def test_insert_multi_matching_regex_existing_file_with_pos_offset
    values = ['foo1', 'foo2']
    data = ['bar1', 'bar2', 'bar3']
    _data = data * "\n"
    data.insert(3, values.first)
    data.insert(4, values.last)
    @mock.expect(:read, _data)
    @mock.expect(:<<, nil){|x| x == data * "\n"}

    assert(@insert_lam[@mock, @file, values, regex:/.*bar2.*/, offset:2])
  end

  def test_insert_single_non_matching_regex_existing_file_default_offset
    values = ['foo']
    data = ['bar1', 'bar2', 'bar3']
    @mock = Minitest::Mock.new
    @mock.expect(:read, data * "\n")

    refute(@insert_lam[@mock, @file, values, regex:/.*foo2.*/])
  end

  def test_insert_multi_matching_regex_existing_file_default_offset
    values = ['foo1', 'foo2']
    data = ['bar1', 'bar2', 'bar3']
    _data = data * "\n"
    data.insert(2, values.first)
    data.insert(3, values.last)
    @mock.expect(:read, _data)
    @mock.expect(:<<, nil){|x| x == data * "\n"}

    assert(@insert_lam[@mock, @file, values, regex:/.*bar2.*/])
  end

  def test_insert_single_matching_regex_existing_file_default_offset
    values = ['foo']
    data = ['bar1', 'bar2', 'bar3']
    _data = data * "\n"
    data.insert(2, values.first)
    @mock.expect(:read, _data)
    @mock.expect(:<<, nil){|x| x == data * "\n"}

    assert(@insert_lam[@mock, @file, values, regex:/.*bar2.*/])
  end

  # Test Append
  #-----------------------------------------------------------------------------
  def test_insert_empty_append
    @mock = Minitest::Mock.new

    refute(@insert_lam[@mock, @file, ""], "No file change should have occurred")
    refute(@insert_lam[@mock, @file, []], "No file change should have occurred")
    refute(@insert_lam[@mock, @file, nil], "No file change should have occurred")
  end

  def test_insert_single_append_existing_file
    values = ['foo']
    data = ['bar1', 'bar2', 'bar3']
    _data = data * "\n"
    @mock.expect(:read, _data)
    @mock.expect(:<<, nil){|x| x == (data + values) * "\n"}

    assert(@insert_lam[@mock, @file, values])
  end

  def test_insert_single_append_new_file_nil_offset
    values = ['foo']
    @mock.expect(:read, "")
    @mock.expect(:<<, nil){|x| x == values * "\n"}

    assert(@insert_lam[@mock, @file, values, offset:nil])
  end

  def test_insert_single_append_new_file
    values = ['foo']
    @mock.expect(:read, "")
    @mock.expect(:<<, nil){|x| x == values * "\n"}

    assert(@insert_lam[@mock, @file, values])
  end

  def test_insert_multi_append_existing_file
    values = ['foo1', 'foo2']
    data = ['bar1', 'bar2', 'bar3']
    _data = data * "\n"
    @mock.expect(:read, _data)
    @mock.expect(:<<, nil){|x| x == (data + values) * "\n"}

    assert(@insert_lam[@mock, @file, values])
  end

  def test_insert_multi_append_new_file
    values = ['foo1', 'foo2']
    @mock.expect(:read, "")
    @mock.expect(:<<, nil){|x| x == values * "\n"}

    assert(@insert_lam[@mock, @file, values])
  end

  def test_insert_rescue
    data = ['bar1', 'bar2', 'bar3']
    @mock = Minitest::Mock.new
    @mock.expect(:read, data) # passing in wrong type here to make it fail
    @mock.expect(:<<, data, [data])

    assert_raises(NoMethodError){@insert_lam[@mock, @file, ['foo']]}
  end
end

# vim: ft=ruby:ts=2:sw=2:sts=2
