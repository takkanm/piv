module Piv
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

      def help_text
        <<-EOS
  usage: piv show STORY_ID

  Show story name and description.
        EOS
      end
    end

    class Open < Base
      def initialize(args)
        super
        @story_id = args[0]
      end

      def execute!
        story_url = "https://www.pivotaltracker.com/story/show/#{@story_id}"
        Exec.execv("/bin/bash", "-l", "-c", "open #{story_url}")
      end

      def help_text
        <<-EOS
  usage: piv open STORY_ID

  Open story page.
        EOS
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

      def help_text
        <<-EOS
  usage: piv branch STORY_ID BRANCH_NAME

  create git branch with story_id
        EOS
      end
    end
  end
end
