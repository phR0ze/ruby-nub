#MIT License
#Copyright (c) 2018 phR0ze
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

require 'yaml'
require_relative 'user'

# Simple YAML configuration for an application
# using singleton pattern to handle multi consumers
class Config
  def self.instance

  # Encapsulate configuration
  # @param config_name [String] name of the config file
  def initialize(config_name)
    @@path = "/home/#{User.name}/.config/#{config_name}"
    #@log.puts("Error: config file doesn't exist!".colorize(:red)) and exit unless File.exists?(@config_path)
 
    begin
      @config = YAML.load_file(@@path)
      @vpns = @config['vpns']
      raise("missing 'vpns' list in config") if vpns.nil?
      #vpn = vpns.find{|x| x['name'] == @vpn }
      #raise("couldn't find '#{@vpn}' in config") if vpn.nil?
      #@username = vpn['user']
      #@openvpn_conf = vpn['conf']
      #@route = vpn['route']
      #@auth_path = File.join(File.dirname(@openvpn_conf), "#{@vpn}.auth")
    rescue Exception => e
      @log.puts("Error: #{e}".colorize(:red)) and exit
    end
  end

end

# vim: ft=ruby:ts=2:sw=2:sts=2
