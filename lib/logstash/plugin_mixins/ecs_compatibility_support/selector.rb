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

        EMPTY_HASH = {}.freeze
        private_constant :EMPTY_HASH

        ##
        # @api private
        # @see ECSCompatibilitySupport()
        # @param ecs_modes_supported
        def initialize(*ecs_modes_and_optional_alias_map)
          selector_module = self

          alias_mapping = ecs_modes_and_optional_alias_map.last.kind_of?(Hash) ? ecs_modes_and_optional_alias_map.pop.dup.freeze : EMPTY_HASH
          ecs_modes_supported = ecs_modes_and_optional_alias_map.dup

          fail(ArgumentError, "one or more ecs_modes_supported required") if ecs_modes_supported.empty?
          fail(ArgumentError, "ecs_modes_supported must only contain symbols") unless ecs_modes_supported.all? { |s| s.kind_of?(Symbol) }

          fail(ArgumentError, "alias names must be symbols") unless alias_mapping.keys.all? { |v| v.kind_of?(Symbol) }
          fail(ArgumentError, "alias targets must be symbols") unless alias_mapping.values.all? { |v| v.kind_of?(Symbol) }
          fail(ArgumentError, "alias must not redefine") if alias_mapping.keys.any? {|v| ecs_modes_supported.include?(v) }
          fail(ArgumentError, "alias map must not have circular references") if circular_references_present?(alias_mapping)

          ecs_modes_supported |= alias_mapping.keys

          fail(ArgumentError, "alias target doesn't exist") if alias_mapping.values.any? { |v| !ecs_modes_supported.include?(v) }

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
            @_ecs_select = selector_module.state_for(effective_ecs_mode)
          end

          ##
          # @method ecs_select
          # @return [State]
          define_method(:ecs_select) { @_ecs_select }

          define_singleton_method(:ecs_modes_supported) { ecs_modes_supported }

          define_singleton_method(:state_for) do |selected_value|
            unless ecs_modes_supported.include?(selected_value)
              fail(NotImplementedError, "Unsupported state `#{selected_value}` (expected one of #{ecs_modes_supported})")
            end
            State.new(ecs_modes_supported, selected_value, alias_mapping)
          end
        end

        ##
        # @return [String]
        def name
          "#{Selector}(#{ecs_modes_supported.join(',')})"
        end

        private

        def circular_references_present?(alias_candidates)
          alias_candidates.each do |candidate, target|
            current = target
            (alias_candidates.size + 1).times do
              return true if current == candidate
              break unless alias_candidates.include?(current)
              current = alias_candidates.fetch(current)
            end
          end

          false
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
          # @api private -- Use Selector#state_for(current_value)
          # @param supported_modes [Array<Symbol>]
          # @param active_mode [Symbol]
          def initialize(supported_modes, active_mode, alias_map=EMPTY_HASH)
            fail(ArgumentError, "invalid alias mapping") unless alias_map.flatten.all? {|v| supported_modes.include?(v) }

            @supported_modes = supported_modes
            @active_mode = active_mode
            @alias_map = alias_map
          end

          attr_reader :active_mode
          attr_reader :supported_modes

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

            missing = @supported_modes - (defined_choices.keys + @alias_map.keys)
            fail(ArgumentError, "missing one or more required choice definition #{missing}") if missing.any?

            unknown = defined_choices.keys - @supported_modes
            fail(ArgumentError, "unknown choices #{unknown}; valid choices are #{@supported_modes}") if unknown.any?

            # resolve aliases of missing choices
            effective_mode = @active_mode
            @alias_map.size.times do # theoretical upper limit of alias chain
              break if defined_choices.include?(effective_mode)
              effective_mode = @alias_map.fetch(effective_mode)
            end

            defined_choices.fetch(effective_mode)
          end
          alias_method :[], :value_from
        end
      end
    end
  end
end
