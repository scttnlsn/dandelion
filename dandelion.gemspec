lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'dandelion/version'

Gem::Specification.new do |s|
  s.name             = 'dandelion'
  s.version          = Dandelion::VERSION
  s.authors          = ['Scott Nelson']
  s.email            = ['scott@scttnlsn.com']
  s.summary          = 'Incremental Git repository deployment'
  s.homepage         = 'https://github.com/scttnlsn/dandelion'
  s.license          = 'MIT'

  s.files         = `git ls-files`.split($/)
  s.executables   = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ['lib']

  s.post_install_message = <<-MSG
!   The 'dandelion' gem is installed but you may need to install additional
!   gems depending on the adapters you intend to use.
!
!   Running 'dandelion status' in your project directory will indicate which
!   additional gems need to be installed.
  MSG

  s.add_dependency 'rugged', '0.23.3'
end
