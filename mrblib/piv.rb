class PivConfig
  def initialize(config_file_path = './.piv.json')
    @config_file_path = config_file_path
    load_config!
  end

  def [](key)
    @config[key]
  end

  def []=(key, val)
    @config[key] = val
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

  def stories(query = {})
    path = "/services/v5/projects/#{@project_id}/stories"
    path = [path, query.map {|k,v| "#{k}=#{v}" }.join('&')].join('?')

    get(path)
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

class Command
  class Base
    def initialize(args)
      parse_option args
      @help = args.any? {|arg| ['--help', '-h'].include?(arg) }
    end

    def run!
      if @help
        show_help
      else
        execute!
      end
    end

    def show_help
      puts help_text
    end

    def help_text
      ''
    end
  end

  class Init < Command::Base
    def execute!
      print 'ProjectId: '
      project_id = gets.chomp
      print 'AccessToken: '
      token = gets.chomp
      config = PivConfig.new
      config['project_id'] = project_id
      config['token'] = token
      config.save!

      puts 'create piv.json'
    end
  end

  class Started < Command::Base
    def parse_option(args)
      @only_me = args.any? {|arg| arg == '--only-me' }
    end

    def execute!
      JSON.parse(client.stories(with_state: 'started')).each do |story|
        next if @only_me && !story['owner_ids'].include?(my_id)

        puts [('%12d' % story['id']), story['name']].join(' : ')
      end
    end

    def help_text
      <<-EOS
usage: piv started [--only-me] [--help] [-h]

Show started stories.

  --only-me : show only my stories
      EOS
    end

    private

    def my_id
      @my_id ||= client.me['id']
    end

    def client
      return @client if @client

      config  = PivConfig.new
      @client = PivotalTrackerApiClient.new(config['project_id'], config['token'])
    end
  end
end

def __main__(argv)
  case argv[1]
  when 'version'
    puts "v#{Piv::VERSION}"
  when 'init'
    Command::Init.new(arg[2..-1]).run!
  when 'started'
    Command::Started.new(argv[2..-1]).run!
  else
    config = PivConfig.new
    config.save!
    client = PivotalTrackerApiClient.new(config['project_id'], config['token'])
    p client.me
  end
end
