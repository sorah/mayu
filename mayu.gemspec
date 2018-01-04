
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "mayu/version"

Gem::Specification.new do |spec|
  spec.name          = "mayu"
  spec.version       = Mayu::VERSION
  spec.authors       = ["Sorah Fukumori"]
  spec.email         = ["sorah@cookpad.com"]

  spec.summary       = %q{Rack app to locate employees in an office by Wi-Fi MAC address and WLC association data}
  spec.homepage      = "https://github.com/sorah/mayu"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end + Dir['app/public/dist/**/*']
  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '>= 2.5.0'

  spec.add_dependency 'wlc_snmp'
  spec.add_dependency 'sinatra'
  spec.add_dependency 'aws-sdk-s3'

  spec.add_dependency 'graphed_fuzzy_search'

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "~> 3.0"
end
