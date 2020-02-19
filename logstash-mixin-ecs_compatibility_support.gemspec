Gem::Specification.new do |s|
  s.name          = 'logstash-mixin-ecs_compatibility_support'
  s.version       = '1.0.0.alpha'
  s.licenses      = %w(Apache-2.0)
  s.summary       = "Support for the ECS-Compatibility mode targeting Logstash 7.7, for plugins wishing to use this API on older Logstashes"
  s.description   = "This gem is meant to be a dependency of any Logstash plugin that wishes to use the ECS-Compatibility mode introduced in 7.7 while maintaining backward-compatibility with earlier Logstashes. When used on older Logstash versions, it provides an implementation of ECS-Compatibility mode that can be controlled at the plugin instance level."
  s.authors       = %w(Elastic)
  s.email         = 'info@elastic.co'
  s.homepage      = 'https://github.com/logstash-plugins/logstash-mixin-ecs_compatibility_support'
  s.require_paths = %w(lib)

  s.files = %w(lib spec vendor).flat_map{|dir| Dir.glob("#{dir}/**/*")}+Dir.glob(["*.md","LICENSE"])

  s.test_files = s.files.grep(%r{^(test|spec|features)/})

  s.platform = RUBY_PLATFORM

  s.add_runtime_dependency 'logstash-core', '>= 5.0.0'

  s.add_development_dependency 'rspec', '~> 3.9'
  s.add_development_dependency 'rspec-its', '~>1.3'
  s.add_development_dependency 'logstash-codec-plain'
end
