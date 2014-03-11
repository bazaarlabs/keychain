require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)
require 'sshkit/dsl'

Dir.glob('capistrano/tasks/*.cap').each { |r| import r }
@servers = []
def set_servers(server_list)
  @servers = server_list
end
require_relative 'servers'

# takes care of loading keys from keys.rb, fetching them from github if needed
class KeysetBuilder
  require 'httparty'

  def initialize()
    @key_array = []
  end

  def key(*args)
    key_val = ""
    if args.first.is_a?(Hash)
      params = args.first
      if params[:github]
        key_val = KeysetBuilder.get_github_key(params[:github])
      end
    elsif args.first.is_a?(String)
      key_val = args.first
    else
      raise RuntimeError "Invalid key specification: #{args}"
    end

    @key_array.push(key_val)
  end

  def keys
    return @key_array
  end

  def KeysetBuilder.get_github_key(username)
    response = HTTParty.get("https://github.com/#{username}.keys")
    if response.code == 200 && response.body
      return response.body
    end
    raise RuntimeError "Could not fetch ssh key for #{username}: #{response.message}"
  end
end

# load in key from keys.rb, using a simple DSL
@builder = KeysetBuilder.new
def set_keys(&block)
  Docile.dsl_eval(@builder, &block)
end
require_relative 'keys'

keyset = @builder.keys.join("\n")


on @servers, in: :parallel do |host|
  begin
    execute :mkdir, '-p .ssh'
    io = StringIO.new(keyset)
    upload! io, '.ssh/authorized_keys'
  rescue Exception
    puts "could not connect to #{host}, skipping"
  end
end

