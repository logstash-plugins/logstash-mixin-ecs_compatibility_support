# ECS Compatibility Support Mixin

[![Build Status](https://travis-ci.com/logstash-plugins/logstash-mixin-ecs_compatibility_support.svg?branch=master)](https://travis-ci.com/logstash-plugins/logstash-mixin-ecs_compatibility_support)

This gem provides an API-compatible implementation of ECS-compatiblity mode,
allowing plugins to be explicitly configured with `ecs_compatibility` in a way
that respects pipeline- and process-level settings where they are available.
It can be added as a dependency of any plugin that wishes to implement one or
more ECS-compatibility modes while still supporting older Logstash versions.

## Usage (simple)

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

3. Use the `ecs_compatibility` method, which will reflect the user's desired
   ECS-Compatibility mode (either `:disabled` or a symbol holding a v-prefixed
   integer major version of ECS, e.g., `:v1`) after the plugin has been sent
   `#config_init`; your plugin does not need to know whether the user specified
   the value in their plugin config or its value was provided by Logstash.

   Care should be taken to handle _all_ possible values:
    - all ECS major versions that are supported by the plugin
    - ECS Compatibility being disabled
    - helpful failure when an unsupported version is requested

    ~~~ ruby
      def register
        case ecs_compatibility
        when :disabled
          # ...
        when :v1
          # ...
        else
          fail(NotImplementedError, "ECS #{ecs_compatibility} is not supported by this plugin.")
        end
      end
    ~~~

## Usage (advanced)

Release 1.1 of this support gem includes support for constraining a plugin
to only operate in specified ECS-Compatibility modes, and advanced support for
runtime selectors that provide developers a way to provide alternate _values_
during initialization based on the instantiated plugin's effective
`ecs_compatibility` mode. This is helpful in plugins that define large field
mappings, because it allows those mappings to be side-by-side where they are
unlikely to diverge and introduce bugs.

1. Add version `~>1.2` of this gem as a runtime dependency of your Logstash plugin's `gemspec`:

    ~~~ ruby
    Gem::Specification.new do |s|
      # ...

      s.add_runtime_dependency 'logstash-mixin-ecs_compatibility_support', '~>1.2'
    end
    ~~~

2. In your plugin code, require this library and include it into your plugin class
   that already inherits `LogStash::Plugin`, but this time specify which versions
   of ECS your plugin supports:

    ~~~ ruby
    require 'logstash/plugin_mixins/ecs_compatibility_support'

    class LogStash::Inputs::Foo < Logstash::Inputs::Base
      include LogStash::PluginMixins::ECSCompatibilitySupport(:disabled,:v1)

      # ...
    end
    ~~~

   This prevents the plugin from being instantiated with an unsupported mode,
   whether that mode was explicitly defined for the plugin instance or implictly
   defined by the pipeline in which the plugin is run.

   You can also optionally provide an alias mapping, for when your plugin supports
   multiple versions of ECS that are largely identical to each other. This can be
   especially helpful when using `ecs_select`.

    ~~~ ruby
    require 'logstash/plugin_mixins/ecs_compatibility_support'

    class LogStash::Inputs::Foo < Logstash::Inputs::Base
      include LogStash::PluginMixins::ECSCompatibilitySupport(:disabled,:v1,:v8 => :v1)

      # ...
    end
    ~~~

3. As in the simple usage example, you can use the `ecs_compatibility` method.

   But when supported versions are specified, you can also use the `ecs_select`
   method to define alternates in-line. At runtime, the correct value will be
   selected based on the current effective `ecs_compatibility` mode.

    ~~~ ruby
      def register
        @field_hostname = ecs_select[disabled: "hostname", v1: "[host][name]"]
        @field_hostip   = ecs_select[disabled: "ip",       v1: "[host][ip]"  ]
      end
    ~~~

   If you initialized the mixin with an alias mapping, missing values will
   be resolved by their alias.

   NOTE: `ecs_select` should only be used during plugin initialization and
   not during event-by-event processing.

## Development

This gem:
 - *MUST* remain API-stable at 1.x
 - *MUST NOT* introduce additional runtime dependencies
