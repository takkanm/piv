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
end
