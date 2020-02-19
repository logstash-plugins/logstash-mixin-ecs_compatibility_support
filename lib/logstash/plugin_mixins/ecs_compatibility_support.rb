# encoding: utf-8

require 'logstash/namespace'
require 'logstash/plugin'

module LogStash
  module PluginMixins
    ##
    # This `ECSCompatibilitySupport` can be included in any `LogStash::Plugin`,
    # and will ensure that the plugin provides a boolean `ecs_compatibility`
    # option.
    #
    # When included into a Logstash plugin that already has the option (e.g.,
    # when run on a Logstash release that includes this option on all plugins),
    # this adapter will _NOT_ override the existing implementation.
    module ECSCompatibilitySupport
      ##
      # @param: a class that inherits `LogStash::Plugin` and includes
      #         `LogStash::Config::Mixin`, typically one descending from one of
      #         the four plugin base classes (e.g., `LogStash::Inputs::Base`)
      # @return [void]
      def self.included(base)
        fail(ArgumentError, "`#{base}` must inherit LogStash::Plugin") unless base < LogStash::Plugin
        fail(ArgumentError, "`#{base}` must include LogStash::Config::Mixin") unless base < LogStash::Config::Mixin

        # If our base does not include an `ecs_compatibility` config option,
        # include the legacy adapter to ensure it gets defined.      
        base.send(:include, LegacyAdapter) unless base.get_config.include?("ecs_compatibility")
      end

      ##
      # Declares a boolean `ecs_compatibility` config option on the `base` that
      # defaults to `false`.
      #
      # @api private
      module LegacyAdapter
        def self.included(base)
          base.config(:ecs_compatibility, :validate => :boolean, :default => false)
        end
      end
    end
  end
end
