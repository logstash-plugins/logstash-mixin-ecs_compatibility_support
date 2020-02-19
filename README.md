# ECS Compatibility Support Mixin

This gem provides an API-compatible implementation of ECS-compatiblity mode,
allowing plugins to be explicitly configured with `ecs_compatibility` in a way
that respects pipeline- and process-level settings where they are available.
It can be added as a dependency of any plugin that wishes to implement an
ECS-compatibility mode, while still supporting older Logstash versions.

## Usage

1. Add this gem as a runtime dependency of your plugin:

    ~~~ ruby
    Gem::Specification.new do |s|
      # ...

      s.add_runtime_dependency 'logstash-mixin-ecs_compatibility_support', '~>1.0'
    end
    ~~~

2. In your plugin code, require this library and include it into your class or
   module that already inherits `LogStash::Util::Loggable`:

    ~~~ ruby
    require 'logstash/plugin_mixins/ecs_compatibility_support'

    class LogStash::Inputs::Foo < Logstash::Inputs::Base
      include LogStash::PluginMixins::ECSCompatibilitySupport

      # ...
    end
    ~~~

3. Use the `@ecs_compatibility` value; your plugin does not need to know whether
   this config option was provided by Logstash core or by this gem.

    ~~~ ruby
      def register
        if @ecs_compatibility
          # ...
        else
          # ...
        end
      end
    ~~~

## Development

This gem:
 - *MUST* remain API-stable at 1.x
 - *MUST NOT* introduce additional runtime dependencies