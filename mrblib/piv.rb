
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
