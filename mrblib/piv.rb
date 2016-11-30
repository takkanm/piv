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
  when 'open'
    Piv::Command::Open.new(argv[2..-1]).run!
  when 'finish'
    Piv::Command::Finish.new(argv[2..-1]).run!
  else
    puts <<-EOS
usage: piv sub_commands

piv is PivotalTracker client command.

sub_commands:
  version: show version
  init:    initialize configuration
  started: show started stories
  show:    show story infomation
  finish:  finsh story
  open:    open page

options:
  --help show help message
    EOS
  end
end
