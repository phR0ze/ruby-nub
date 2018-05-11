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
      'Permission is hereby granted, free of charge, to any person obtaining a copy']
    _data = ['MIT License', 'Foobar100', '',
      'Permission is hereby granted, free of charge, to any person obtaining a copy']

    mock = Minitest::Mock.new
    mock.expect(:readlines, data)
    mock.expect(:seek, nil, [0])
    mock.expect(:truncate, nil, [0])
    mock.expect(:puts, nil){|x| x == _data}

    File.stub(:open, true, mock){
      assert(FileUtils.update('foobar'){|line|
        line.gsub!(/Copyright.*/, 'Foobar100') if line =~ /Copyright/
      })
    }
    assert_mock(mock)
  end

  def test_update_no_change
    data = ['MIT License', 'Copyright (c) 2018 phR0ze']
    mock = Minitest::Mock.new
    mock.expect(:readlines, data)
    mock.expect(:seek, nil, [0])
    mock.expect(:truncate, nil, [0])
    mock.expect(:puts, nil){|x| x == data}

    File.stub(:open, true, mock){
      assert(!FileUtils.update('foobar'){|line| })
    }
    assert_mock(mock)
  end


  def test_update_rescue
    data = ['MIT License', 'Copyright (c) 2018 phR0ze', '',
      'Permission is hereby granted, free of charge, to any person obtaining a copy']

    mock = Minitest::Mock.new
    mock.expect(:readlines, data)
    mock.expect(:puts, nil){|x| x == data}

    File.stub(:open, true, mock){
      assert_raises(RuntimeError){
        FileUtils.update('foobar'){|line| raise RuntimeError.new("foo")}
      }
    }
    assert_mock(mock)
  end

  def test_update_copyright_single_todate_year
    data = ['MIT License', '#Copyright (c) 2018 phR0ze']

    mock = Minitest::Mock.new
    mock.expect(:readlines, data)
    mock.expect(:seek, nil, [0])
    mock.expect(:truncate, nil, [0])
    mock.expect(:puts, nil){|x| x == data}

    File.stub(:open, true, mock){
      assert(!FileUtils.update_copyright('filepath', '#Copyright (c)', year:'2018'))
    }
    assert_mock(mock)
  end

  def test_update_copyright_single_outdated_year
    data = ['MIT License', '#Copyright (c) 2017 phR0ze']
    _data = ['MIT License', '#Copyright (c) 2017-2018 phR0ze']

    mock = Minitest::Mock.new
    mock.expect(:readlines, data)
    mock.expect(:seek, nil, [0])
    mock.expect(:truncate, nil, [0])
    mock.expect(:puts, nil){|x| x == _data}

    File.stub(:open, true, mock){
      assert(FileUtils.update_copyright('filepath', '#Copyright (c)', year:'2018'))
    }
    assert_mock(mock)
  end

  def test_update_copyright_year_range_todate
    data = ['MIT License', '#Copyright (c) 2016-2017 phR0ze']

    mock = Minitest::Mock.new
    mock.expect(:readlines, data)
    mock.expect(:seek, nil, [0])
    mock.expect(:truncate, nil, [0])
    mock.expect(:puts, nil){|x| x == data}

    File.stub(:open, true, mock){
      assert(!FileUtils.update_copyright('filepath', '#Copyright (c)', year:'2017'))
    }
    assert_mock(mock)
  end

  def test_update_copyright_year_range_outdated
    data = ['MIT License', '#Copyright (c) 2016-2017 phR0ze']
    _data = ['MIT License', '#Copyright (c) 2016-2018 phR0ze']

    mock = Minitest::Mock.new
    mock.expect(:readlines, data)
    mock.expect(:seek, nil, [0])
    mock.expect(:truncate, nil, [0])
    mock.expect(:puts, nil){|x| x == _data}

    File.stub(:open, true, mock){
      assert(FileUtils.update_copyright('filepath', '#Copyright (c)', year:'2018'))
    }
    assert_mock(mock)
  end

  def test_inc_version_revision_only
    data = ['MIT License', "   spec.version = '0.0.1'"]
    _data = ['MIT License', "   spec.version = '0.0.2'"]

    mock = Minitest::Mock.new
    mock.expect(:readlines, data)
    mock.expect(:seek, nil, [0])
    mock.expect(:truncate, nil, [0])
    mock.expect(:puts, nil){|x| x == _data}

    File.stub(:open, true, mock){
      assert_equal('0.0.2', FileUtils.inc_version('filepath', /\s*spec\.version\s*=.*(\d+\.\d+\.\d+).*/))
    }
    assert_mock(mock)
  end

  def test_inc_version_minor_only
    data = ['MIT License', "   spec.version = '0.0.1'"]
    _data = ['MIT License', "   spec.version = '0.1.1'"]

    mock = Minitest::Mock.new
    mock.expect(:readlines, data)
    mock.expect(:seek, nil, [0])
    mock.expect(:truncate, nil, [0])
    mock.expect(:puts, nil){|x| x == _data}

    File.stub(:open, true, mock){
      assert_equal('0.1.1', FileUtils.inc_version('filepath', /\s*spec\.version\s*=.*(\d+\.\d+\.\d+).*/, minor:true, rev:false))
    }
    assert_mock(mock)
  end

  def test_inc_version_all
    data = ['MIT License', "   spec.version = '0.0.1'"]
    _data = ['MIT License', "   spec.version = '1.1.2'"]

    mock = Minitest::Mock.new
    mock.expect(:readlines, data)
    mock.expect(:seek, nil, [0])
    mock.expect(:truncate, nil, [0])
    mock.expect(:puts, nil){|x| x == _data}

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

# vim: ft=ruby:ts=2:sw=2:sts=2
