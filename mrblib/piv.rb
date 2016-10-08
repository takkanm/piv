def __main__(argv)
  if argv[1] == "version"
    puts "v#{Piv::VERSION}"
  else
    File.open('./.piv') do |fp|
      puts fp.read
    end
  end
end
