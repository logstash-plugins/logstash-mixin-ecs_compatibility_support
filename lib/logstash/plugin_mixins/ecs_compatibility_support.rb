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
      # @api internal (use: `LogStash::Plugin::include`)
      # @param: a class that inherits `LogStash::Plugin`, typically one
      #         descending from one of the four plugin base classes (e.g.,
      #         `LogStash::Inputs::Base`)
      # @return [void]
      def self.included(base)
        fail(ArgumentError, "`#{base}` must inherit LogStash::Plugin") unless base < LogStash::Plugin

        # If our base does not include an `ecs_compatibility` config option,
        # include the legacy adapter to ensure it gets defined.      
        base.send(:include, LegacyAdapter) unless base.method_defined?(:ecs_compatibility?)
      end

      ##
      # This `ECSCompatibilitySupport` cannot be extended into an existing object.
      # @api private
      #
      # @param base [Object]
      # @raise [ArgumentError]
      def self.extended(base)
        fail(ArgumentError, "`#{self}` cannot be extended into an existing object.")
      end

      ##
      # Implements `ecs_compatibility?` method backed by a boolean `ecs_compatibility`
      # config option that defaults to `false`.
      #
      # @api internal
      module LegacyAdapter
        def self.included(base)
          base.config(:ecs_compatibility, :validate => :boolean, :default => false)
        end

        ##
        # @api public
        # @return [Boolean]
        def ecs_compatibility?
          # NOTE: The @ecs_compatibility instance variable is an implementation detail of
          #       this `LegacyAdapter` and plugins MUST NOT rely in its presence or value.
          @ecs_compatibility
        end
      end
    end
  end
end
