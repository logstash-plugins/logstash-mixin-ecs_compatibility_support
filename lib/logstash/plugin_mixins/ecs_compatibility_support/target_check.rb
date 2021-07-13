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

        private

        ##
        # Check whether `target` is specified.
        #
        # @return [nil] if target is unspecified and ECS compatibility is disabled
        # @return [true, false]
        def target_set?
          return true unless target.nil?
          return nil if ecs_compatibility == :disabled
          false # target isn't set
        end

        ##
        # Check whether a codec is present and specifies a target.
        #
        # @return [nil] if codec not present or codec does not support target
        # @return [true,false]
        def codec_target_set?
          return nil unless respond_to?(:codec)
          return nil unless codec.respond_to?(:target)
          !codec.target.nil?
        end

        module RegisterDecorator

          ECS_TARGET_NOT_SET_MESSAGE = ("ECS compatibility is enabled but `target` option was not specified. " +
            "This may cause fields to be set at the top-level of the event where they are likely to clash with the Elastic Common Schema. " +
            "It is recommended to set the `target` option to avoid potential schema conflicts " +
            "(if your data is ECS compliant or non-conflicting, feel free to ignore this message)").freeze

          ECS_TARGET_NOT_SET_PREFER_CODEC_MESSAGE = ("ECS compatibility is enabled but `target` option was not specified for this plugin or its codec." +
            "This may cause fields to be set at the top-level of the event where they are likely to clash with the Elastic Common Schema. " +
            "When a plugin and its codec both provide a `target` option, it is recommended to set the `target` option on the codec to avoid potential schema conflicts " +
            "(if your data is ECS compliant or non-conflicting, feel free to ignore this message)."
          ).freeze

          MULTIPLE_TARGETS_SET_MESSAGE = ("This plugin and its codec are both configured with a `target` option, which can lead to surprising results. " +
            "In general, it is recommended to ONLY set the codec's `target`.").freeze

          PREFER_CODEC_TARGET_MESSAGE_TEMPLATE = ("Both this plugin and its codec provide a `target` option, but the codec's `target` was left unspecified. "+
            "In general, it is recommended to only set the codec's `target`. "+
            "To do so, remove the `target` directive from this plugin and instead define the codec with `codec => %s { target => %p }`").freeze

          ##
          # Logs an info message when ecs_compatibility is enabled but plugin has no `target` configuration specified.
          # @override
          def register
            super.tap do
              plugin_targeted = target_set?
              codec_targeted = codec_target_set?

              if plugin_targeted
                if codec_targeted
                  # both is not good. prefer codec.
                  logger.warn(MULTIPLE_TARGETS_SET_MESSAGE)
                elsif codec_targeted == false
                  # prefer codec's target option
                  logger.warn(PREFER_CODEC_TARGET_MESSAGE_TEMPLATE % [codec.config_name, target])
                end
              elsif (plugin_targeted == false)
                # ECS enabled and plugin not targeted
                if codec_targeted.nil?
                  # codec does not support target
                  logger.info(ECS_TARGET_NOT_SET_MESSAGE)
                elsif codec_targeted == false
                  # codec supports target, but it is unspecified
                  logger.info(ECS_TARGET_NOT_SET_PREFER_CODEC_MESSAGE)
                end
              end
            end
          end

        end
        private_constant :RegisterDecorator
      end
    end
  end
end
