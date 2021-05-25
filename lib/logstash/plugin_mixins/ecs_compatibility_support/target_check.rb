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
          fail(ArgumentError, "`#{base}` must include #{ECSCompatibilitySupport}") unless base.method_defined?(:ecs_compatibility)
        end

        TARGET_NOT_SET_MESSAGE = ("ECS compatibility is enabled but no `target` option was specified, " +
            "it is recommended to set the option to avoid potential schema conflicts (if your data is ECS compliant " +
            "or non-conflicting feel free to ignore this message)").freeze

        private

        ##
        # Logs an info message when ecs_compatibility is enabled but plugin has no `target` configuration specified.
        # @note This method assumes a common plugin convention of using the target option.
        # @return [nil] if ECS compatibility is disabled or no target option exists
        # @return [true, false]
        def check_target_set_in_ecs_mode
          return if ecs_compatibility == :disabled || !respond_to?(:target)
          if target.nil?
            logger.info(TARGET_NOT_SET_MESSAGE)
            return false
          end
          true
        end

      end
    end
  end
end
