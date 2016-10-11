class PivConfig
  def initialize(config_file_path = './.piv.json')
    File.open(config_file_path) do |fp|
      body = fp.read.chomp
      @config = JSON.parse(body)
    end
  end

  def [](key)
    @config[key]
  end
end

def __main__(argv)
  if argv[1] == "version"
    puts "v#{Piv::VERSION}"
  else
    config = PivConfig.new
    p config
    p SimpleHttp.new("https", config['url']).request("GET", "/", {'User-Agent' => "test-agent"})
  end
end
