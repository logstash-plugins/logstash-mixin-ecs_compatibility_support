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

        TARGET_NOT_SET_MESSAGE = ("ECS compatibility is enabled but `target` option was not specified. " +
            "This may cause fields to be set at the top-level of the event where they are likely to clash with the Elastic Common Schema. " +
            "It is recommended to set the `target` option to avoid potential schema conflicts (if your data is ECS compliant " +
            "or non-conflicting, feel free to ignore this message)").freeze

        private

        ##
        # Check whether `target` is specified.
        # For the majority of plugins, they don't have `codec`, hence does a simple check on `target`
        # The rest of plugins, mostly input plugins, if the `codec` support `target`, check whether `codec.target` is specified
        #
        # @return [nil] if target is unspecified and ECS compatibility is disabled
        # @return [false, log_msg] when target is not set to the correct field
        # @return [true] when target is set
        def target_set?
          return nil if ecs_compatibility == :disabled

          if self.respond_to?(:codec) && codec.respond_to?(:target)
            if target && codec.target
              #  targeting both is not good.
              msg = "ECS compatibility is enabled but `target` options were set in both codec " +
                "and plugin. This causes duplication of data in the same event. It is recommended to set " +
                "`codec => #{codec.config_name} { target => #{codec.target.inspect} }` " +
                "and remove `target => #{target.inspect}`"
              [false, msg]
            elsif target && !codec.target
              # setting `target` causes `[event][original]` nested in `target`
              msg = "ECS compatibility is enabled and `target` was set. " +
                "It is recommended to set `codec => #{codec.config_name} { target => #{target.inspect} }` " +
                "to have [event][original] in top-level"
              [false, msg]
            elsif !target && codec.target
              # setting codec target is desired
              [true]
            else
              # both are not set
              msg = "ECS compatibility is enabled but `target` option was not specified in codec. " +
                "This may cause fields to be set at the top-level of the event where they are likely to clash with the Elastic Common Schema. " +
                "It is recommended to set `codec => #{codec.config_name} { target => YOUR_TARGET_FIELD_NAME }` " +
                "to avoid potential schema conflicts (if your data is ECS compliant " +
                "or non-conflicting, feel free to ignore this message)"
              [false, msg]
            end
          else
            return [true] unless target.nil?
            [false, TARGET_NOT_SET_MESSAGE] # target isn't set
          end
        end

        module RegisterDecorator

          ##
          # Logs an info message when ecs_compatibility is enabled but plugin has no `target` configuration specified.
          # @override
          def register
            super.tap do
              is_set, log_msg = target_set?
              logger.info(log_msg) if is_set == false
            end
          end

        end
        private_constant :RegisterDecorator
      end
    end
  end
end
