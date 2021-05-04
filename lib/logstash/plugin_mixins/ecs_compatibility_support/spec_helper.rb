# encoding: utf-8

require_relative 'selector'

module LogStash
  module PluginMixins
    module ECSCompatibilitySupport
      # The `SpecHelper` is meant to be extended into an rspec context to provide it with
      # tools for vaidating the ecs_compatibility matrix.
      #
      # It creates one sub-context per provided mode, and yields a Selector::State
      # to the provided block primed with the list of supported supported_modes and the active mode.
      #
      # It also memoizes an `ecs_compatibility` set to the active mode. It is up to the user
      # to plumb this into the initialization of your plugin.
      #
      # ~~~ ruby
      # require 'logstash/plugin_mixins/ecs_compatibility_support/spec_helper'
      #
      # describe YourClass, :ecs_compatibility_support
      #   ecs_compatibility_matrix(:disabled, :v1) do |ecs_select|
      #     context "#description" do
      #       subject(:result) { instance.description }
      #       it { is_expected.to eq ecs_select[disabled: "legacy", v1: "novel"] }
      #     end
      #   end
      # end
      # ~~~
      module SpecHelper
        def ecs_compatibility_matrix(*supported_modes,&block)
          ecs_selector = Selector.new(*supported_modes)

          ecs_selector.ecs_modes_supported.each do |active_mode|
            context "`ecs_compatibility => #{active_mode}`" do
              let(:ecs_compatibility) { active_mode }

              ecs_select = ecs_selector.state_for(active_mode)
              instance_exec(ecs_select, &block)
            end
          end
        end
      end

      ::RSpec.configure { |c| c.extend(SpecHelper, :ecs_compatibility_support) } if defined?(::RSpec)
    end
  end
end
