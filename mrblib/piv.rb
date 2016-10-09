def __main__(argv)
  if argv[1] == "version"
    puts "v#{Piv::VERSION}"
  else
    url = ''
    File.open('./.piv') do |fp|
      url = fp.read.chomp
    end
    p url
    p SimpleHttp.new("http", url, 80).request("GET", "/", {'User-Agent' => "test-agent"})
  end
end
