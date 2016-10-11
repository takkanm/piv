class PivConfig
  def initialize(config_file_path = './.piv.json')
    @config_file_path = config_file_path
    load_config!
  end

  def [](key)
    @config[key]
  end

  def load_config!
    File.open(@config_file_path) do |fp|
      body = fp.read.chomp
      @config = JSON.parse(body)
    end
  end

  def save!
    File.open(@config_file_path, 'w') do |fp|
      fp.puts JSON.stringify(@config)
    end
  end
end

class PivotalTrackerApiClient
  API_HOST = 'www.pivotaltracker.com'

  def initialize(project_id, token)
    @token = token
    @project_id = project_id
  end

  def me
    get('/services/v5/me')
  end

  def get(path, header = {})
    client.request('GET', path, header.merge(default_header)).body
  end

  def default_header
    {'X-TrackerToken' => @token}
  end

  def client
    @client ||= SimpleHttp.new('https', API_HOST)
  end
end

def __main__(argv)
  if argv[1] == "version"
    puts "v#{Piv::VERSION}"
  else
    config = PivConfig.new
    config.save!
    client = PivotalTrackerApiClient.new(config['project_id'], config['token'])
    p client.me
  end
end
