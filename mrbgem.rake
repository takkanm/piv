MRuby::Gem::Specification.new('piv') do |spec|
  spec.license = 'MIT'
  spec.author  = 'MRuby Developer'
  spec.summary = 'piv'
  spec.bins    = ['piv']

  spec.add_dependency 'mruby-print', :core => 'mruby-print'
  spec.add_dependency 'mruby-sprintf', :core => 'mruby-sprintf'
  spec.add_dependency 'mruby-mtest', :mgem => 'mruby-mtest'
  spec.add_dependency 'mruby-io',    :mgem => 'mruby-io'
  spec.add_dependency 'mruby-polarssl', :github => 'luisbebop/mruby-polarssl'
  spec.add_dependency 'mruby-simplehttp', :github => 'matsumoto-r/mruby-simplehttp'
  spec.add_dependency 'mruby-json', :mgem => 'mruby-json'
end
