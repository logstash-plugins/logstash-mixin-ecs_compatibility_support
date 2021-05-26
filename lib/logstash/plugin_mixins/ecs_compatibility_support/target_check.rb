# encoding: utf-8

require_relative '../ecs_compatibility_support'

module LogStash
  module PluginMixins
    module ECSCompatibilitySupport
      # A target option check that can be included into any `LogStash::Plugin`.
      #
      # @see ECSCompatibilitySupport()
      module TargetCheck
        ##
        # @api internal (use: `LogStash::Plugin::include`)
        # @param base [Class]: a class that inherits `LogStash::Plugin`, typically one
        #                      descending from one of the four plugin base classes
        #                      (e.g., `LogStash::Inputs::Base`)
        # @return [void]
        def self.included(base)
          fail(ArgumentError, "`#{base}` must inherit LogStash::Plugin") unless base < LogStash::Plugin
          fail(ArgumentError, "`#{base}` must include #{ECSCompatibilitySupport}") unless base < ECSCompatibilitySupport
          base.prepend(RegisterDecorator)
        end

        TARGET_NOT_SET_MESSAGE = ("ECS compatibility is enabled but no `target` option was specified, " +
            "it is recommended to set the option to avoid potential schema conflicts (if your data is ECS compliant " +
            "or non-conflicting feel free to ignore this message)").freeze

        private

        ##
        # Check whether `target` is specified.
        #
        # @return [nil] if ECS compatibility is disabled
        # @return [true, false]
        def target_set?
          return if ecs_compatibility == :disabled
          ! target.nil?
        end

        module RegisterDecorator

          ##
          # Logs an info message when ecs_compatibility is enabled but plugin has no `target` configuration specified.
          # @override
          def register
            super.tap do
              logger.info(TARGET_NOT_SET_MESSAGE) if target_set? == false
            end
          end

        end
      end
    end
  end
end
