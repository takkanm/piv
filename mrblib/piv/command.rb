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

        @client = PivotalTrackerApiClient.new(config['project_id'], config['token'])
      end

      def config
        @config ||= Piv::Config.new
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

        puts <<-STORY
Story Id    : #{story['id']}
Title       : #{story['name']}
Estimate    : #{story['estimate']}
Story Type  : #{story['story_type']}
Description :

#{story['description']}
        STORY
      end

      def help_text
        <<-EOS
  usage: piv show STORY_ID

  Show story name and description.
        EOS
      end
    end

    class Finish < Base
      def execute!
        if current_status_is_started?
          finish!
        else
          puts "#{@args[0]} status is not 'started'"
        end
      end

      def current_status_is_started?
        story = JSON.parse(client.story(@args[0]))
        story['current_state'] == 'started'
      end

      def finish!
        JSON.parse(client.finish(@args[0]))
      end

      def help_text
        <<-EOS
  usage: piv finish STORY_ID

  Story finished.
        EOS
      end
    end

    class Open < Base
      def initialize(args)
        super
        @story_id = args[0]
      end

      def execute!
        open_url = if @sotry_id
          "https://www.pivotaltracker.com/story/show/#{@story_id}"
        else
          "https://www.pivotaltracker.com/n/projects/#{config['project_id']}"
        end

        Exec.execv("/bin/bash", "-l", "-c", "open #{open_url}")
      end

      def help_text
        <<-EOS
  usage: piv open [STORY_ID]

  Open project page. If STORY_ID is supplied, open story page.
        EOS
      end
    end

    class CurrentIteration < Base
      def parse_option(args)
        @md_format = args.any? {|arg| arg == '--md-format' }
      end

      def execute!
        JSON.parse(client.current_iteration)[0]['stories'].each do |story|
          if @md_format
            puts "[#{story['name']}](https://www.pivotaltracker.com/story/show/#{story['id']})"
          else
            puts "#{('%12d' % story['id'])} : #{story['name']} <#{story['current_state']}> [#{member_names(story['owner_ids']).join(',')}]"
          end
        end
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

      def help_text
        <<-EOS
  usage: piv current_iteration [--md-format]

  Show current iteration stories.

    --md-format : show current iteration stories at markdown style link
        EOS
      end
    end
  end
end
