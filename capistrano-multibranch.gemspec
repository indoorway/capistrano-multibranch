
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "capistrano-multibranch"
  spec.version       = '0.1.2'
  spec.authors       = ["Patryk Pastewski"]
  spec.email         = ["patryk.pastewski@indoorway.com"]

  spec.summary       = "Capistrano plugin for deploying separate application per feature branch."
  spec.description   = "Capistrano plugin for deploying separate application per feature branch."
  spec.homepage      = "https://github.com/indoorway/capistrano-multibranch"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'capistrano', '~> 3.1'
  spec.add_dependency 'sshkit', '~> 1.2'

  spec.add_development_dependency "bundler", "~> 1.16.a"
  spec.add_development_dependency "rake", "~> 10.0"
end
