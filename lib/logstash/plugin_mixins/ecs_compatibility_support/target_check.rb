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

        MULTIPLE_TARGETS_MESSAGE = ("This plugin and its codec both specify a `target` option, which can lead to surprising results. " +
          "In general, it is recommended to only set the codec's `target`.").freeze

        PREFER_CODEC_TARGET_MESSAGE = ("Both this plugin and its codec provide a `target` option, but the codec's `target` was left unspecified. "+
          "In general, it is recommended to only set the codec's `target`.").freeze

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

          ##
          # Logs an info message when ecs_compatibility is enabled but plugin has no `target` configuration specified.
          # @override
          def register
            super.tap do
              if target_set? && codec_target_set?
                # both is not good. prefer codec.
                logger.warn(MULTIPLE_TARGETS_MESSAGE)
              elsif target_set? && (codec_target_set? == false)
                # prefer codec's target option
                logger.info(PREFER_CODEC_TARGET_MESSAGE +
                              "To do so, remove the `target` directive from this plugin and instead define the codec with " +
                              "`codec => #{codec.config_name} { target => #{target.inspect} }`")
              elsif (target_set? == false) && codec_target_set?.nil?
                # target desired but unset, codec doesn't provide
                logger.info(TARGET_NOT_SET_MESSAGE)
              end
            end
          end

        end
        private_constant :RegisterDecorator
      end
    end
  end
end
