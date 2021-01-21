# encoding: utf-8

require_relative '../ecs_compatibility_support'

module LogStash
  module PluginMixins
    module ECSCompatibilitySupport
      # A `ECSCompatibilitySupport::Selector` is a `Module` that can be included into any `LogStash::Plugin`
      # to constrain instances to a specific set of supported `ecs_compatibility` modes.
      #
      # It also provides an `ecs_select` that allows plugin developers to specify ECS alternatives
      # in-line with their existing code.
      #
      # @api private
      # @see ECSCompatibilitySupport()
      class Selector < Module

        ##
        # @api internal (use: `LogStash::Plugin::include`)
        # @param base [Class]: a class that inherits `LogStash::Plugin`, typically one
        #                      descending from one of the four plugin base classes
        #                      (e.g., `LogStash::Inputs::Base`)
        # @return [void]
        def included(base)
          fail(ArgumentError, "`#{base}` must inherit LogStash::Plugin") unless base < LogStash::Plugin
          base.include(ECSCompatibilitySupport)
        end

        ##
        # @api private
        # @see ECSCompatibilitySupport()
        # @param ecs_modes_supported
        def initialize(*ecs_modes_supported)
          fail(ArgumentError, "one or more ecs_modes_supported required") if ecs_modes_supported.empty?
          fail(ArgumentError, "ecs_modes_supported must only contain symbols") unless ecs_modes_supported.all? { |s| s.kind_of?(Symbol) }

          ecs_modes_supported.freeze

          ##
          # Hooks initialization to throw a configuration error if plugin is initialized with
          # an unsupported `ecs_compatibility` mode.
          # @method initialize
          define_method(:initialize) do |*args|
            super(*args) # Plugin#initialize

            effective_ecs_mode = ecs_compatibility
            if !ecs_modes_supported.include?(effective_ecs_mode)
              message = "#{config_name} #{@plugin_type} plugin does not support `ecs_compatibility => #{effective_ecs_mode}`. "+
                        "Supported modes are: #{ecs_modes_supported}"
              fail(LogStash::ConfigurationError, message)
            end
            @_ecs_select = State.new(ecs_modes_supported, effective_ecs_mode)
          end

          ##
          # @method ecs_select
          # @return [State]
          define_method(:ecs_select) { @_ecs_select }

          define_singleton_method(:ecs_modes_supported) { ecs_modes_supported }
        end

        ##
        # @return [String]
        def name
          "#{Selector}(#{ecs_modes_supported.join(',')})"
        end

        ##
        # A `State` contains the active mode and a list of all supported modes.
        #
        # It allows a developer to safely define mappings of alternative values, exactly
        # one of which will be selected based on the effective mode.
        #
        # It is _NOT_ designed for performance, but may be helpful during  instantiation.
        #
        # @api private
        class State
          ##
          # @api private
          # @param supported_modes [Array<Symbol>]
          # @param active_mode [Symbol]
          def initialize(supported_modes, active_mode)
            @supported_modes = supported_modes
            @active_mode = active_mode
          end

          # With the active mode, select one of the provided options.
          # @param defined_choices [Hash{Symbol=>Object}]: the options to chose between.
          #                        it is an `ArgumentError` to provide a different set of
          #                        options than those this `State` was initialized with.
          #                        This ensures that all reachable code implements all
          #                        supported options.
          # @return [Object]
          def value_from(defined_choices)
            fail(ArgumentError, "defined_choices must be a Hash") unless defined_choices.kind_of?(Hash)
            fail(ArgumentError, "defined_choices cannot be empty") if defined_choices.empty?
            fail(ArgumentError, "defined_choices must have Symbol keys") unless defined_choices.keys.all? { |k| k.kind_of?(Symbol) }

            fail(ArgumentError, "at least one choice must be defined") if defined_choices.empty?

            missing = @supported_modes - defined_choices.keys
            fail(ArgumentError, "missing one or more required choice definition #{missing}") if missing.any?

            unknown = defined_choices.keys - @supported_modes
            fail(ArgumentError, "unknown choices #{unknown}; valid choices are #{@supported_modes}") if unknown.any?

            defined_choices.fetch(@active_mode)
          end
          alias_method :[], :value_from
        end
      end
    end
  end
end
