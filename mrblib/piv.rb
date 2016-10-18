module Piv
  class Config
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
    API_HOST  = 'www.pivotaltracker.com'
    PATH_BASE = '/services/v5'

    def initialize(project_id, token)
      @token = token
      @project_id = project_id
    end

    def me
      get('/me')
    end

    def memberships
      get("/projects/#{@project_id}/memberships")
    end

    def stories(query = {})
      path = "/projects/#{@project_id}/stories"
      path = [path, query.map {|k,v| "#{k}=#{v}" }.join('&')].join('?')

      get(path)
    end

    def story(story_id)
      get("/projects/#{@project_id}/stories/#{story_id}")
    end

    def get(path, header = {})
      client.request('GET', [PATH_BASE, path].join('/'), header.merge(default_header)).body
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
        @args = args
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

      def parse_option(args)
      end

      def client
        return @client if @client

        config  = Piv::Config.new
        @client = PivotalTrackerApiClient.new(config['project_id'], config['token'])
      end
    end

    class Init < Command::Base
      def execute!
        print 'ProjectId: '
        project_id = gets.chomp
        print 'AccessToken: '
        token = gets.chomp
        config = Piv::Config.new
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

          puts "#{('%12d' % story['id'])} : #{story['name']} [#{member_names(story['owner_ids']).join(',')}]"
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
        @my_id ||= JSON.parse(client.me)['id']
      end

      def member_names(owner_ids)
        owner_ids.map do |owner_id|
          owner = memberships.find { |o| o['person']['id'] == owner_id }

          owner['person']['username']
        end
      end

      def memberships
        @memberships ||= JSON.parse(@client.memberships)
      end
    end

    class Show < Base
      def execute!
        story = JSON.parse(client.story(@args[0]))
        puts story['name']
        puts story['description']
      end
    end

    class Branch < Base
      def initialize(args)
        @story_id    = args[0]
        @branch_name = args[1]

        super(args)
      end

      def execute!
        Exec.execv("/bin/bash", "-l", "-c", "git checkout -b #{story_branch_name}")
      end

      def story_branch_name
        [@story_id, @branch_name].join('--')
      end
    end
  end
end

def __main__(argv)
  case argv[1]
  when 'version'
    puts "v#{Piv::VERSION}"
  when 'init'
    Piv::Command::Init.new(arg[2..-1]).run!
  when 'started'
    Piv::Command::Started.new(argv[2..-1]).run!
  when 'show'
    Piv::Command::Show.new(argv[2..-1]).run!
  when 'branch'
    Piv::Command::Branch.new(argv[2..-1]).run!
  else
    config = Piv::Config.new
    config.save!
    client = Piv::PivotalTrackerApiClient.new(config['project_id'], config['token'])
    p client.me
    Exec.execv("/bin/bash", "-l", "-c", "echo Hello exec")
  end
end
