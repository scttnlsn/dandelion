$:.push File.expand_path("../lib", __FILE__)

require 'dandelion/version'

Gem::Specification.new do |s|
  s.name        = 'dandelion'
  s.version     = Dandelion::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Scott Nelson']
  s.email       = ['scottbnel@gmail.com']
  s.homepage    = 'http://github.com/scottbnel/dandelion'
  s.summary     = "dandelion-#{s.version}"
  s.description = 'Git repository deployment via SFTP'
  
  s.add_dependency 'net-sftp', '>= 2.0.5'
  s.add_dependency 'grit', '>= 2.4.1'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ['lib']
end
