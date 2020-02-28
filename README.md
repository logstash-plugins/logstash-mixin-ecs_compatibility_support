# ECS Compatibility Support Mixin

[![Build Status](https://travis-ci.org/logstash-plugins/logstash-mixin-ecs_compatibility_support.svg?branch=master)](https://travis-ci.org/logstash-plugins/logstash-mixin-ecs_compatibility_support)

This gem provides an API-compatible implementation of ECS-compatiblity mode,
allowing plugins to be explicitly configured with `ecs_compatibility` in a way
that respects pipeline- and process-level settings where they are available.
It can be added as a dependency of any plugin that wishes to implement an
ECS-compatibility mode while still supporting older Logstash versions.

## Usage

1. Add version `~>1.0` of this gem as a runtime dependency of your Logstash plugin's `gemspec`:

    ~~~ ruby
    Gem::Specification.new do |s|
      # ...

      s.add_runtime_dependency 'logstash-mixin-ecs_compatibility_support', '~>1.0'
    end
    ~~~

2. In your plugin code, require this library and include it into your plugin class
   that already inherits `LogStash::Plugin`:

    ~~~ ruby
    require 'logstash/plugin_mixins/ecs_compatibility_support'

    class LogStash::Inputs::Foo < Logstash::Inputs::Base
      include LogStash::PluginMixins::ECSCompatibilitySupport

      # ...
    end
    ~~~

3. Use the `ecs_compatibility?` method, which will reflect the user's desired
   ECS-Compatibility mode after the plugin has been sent `#config_init`; your
   plugin does not need to know whether the user specified it in their plugin
   config or its value was provided by Logstash.

    ~~~ ruby
      def register
        if ecs_compatibility?
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