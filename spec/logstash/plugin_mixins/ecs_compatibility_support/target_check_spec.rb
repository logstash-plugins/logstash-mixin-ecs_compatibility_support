# encoding: utf-8

require "logstash-core"

require 'logstash/inputs/base'
require 'logstash/filters/base'
require 'logstash/codecs/base'
require 'logstash/outputs/base'

require "logstash/plugin_mixins/ecs_compatibility_support/target_check"

describe LogStash::PluginMixins::ECSCompatibilitySupport::TargetCheck do

  describe "check_target_set_in_ecs_mode" do

    context 'with a plugin' do

      subject(:plugin_class) do
        Class.new(LogStash::Filters::Base) do
          include LogStash::PluginMixins::ECSCompatibilitySupport
          include LogStash::PluginMixins::ECSCompatibilitySupport::TargetCheck

          config :target, :validate => :string

          def register
            check_target_set_in_ecs_mode
          end
        end
      end

      it 'skips check when ECS disabled' do
        plugin = plugin_class.new('ecs_compatibility' => 'disabled')
        expect( plugin.register ).to be nil
      end

      it 'warns when target is not set in ECS mode' do
        plugin = plugin_class.new('ecs_compatibility' => 'v1')
        allow( plugin.logger ).to receive(:info)
        expect( plugin.register ).to be false
        expect( plugin.logger ).to have_received(:info).with(/ECS compatibility is enabled but no `target` option was specified/)
      end

      it 'does not warn when target is set' do
        plugin = plugin_class.new('ecs_compatibility' => 'v1', 'target' => 'foo')
        allow( plugin.logger ).to receive(:info)
        expect( plugin.register ).to be true
        expect( plugin.logger ).to_not have_received(:info)
      end

    end

    it 'skips check when no target config' do
      plugin_class = Class.new(LogStash::Filters::Base) do
        include LogStash::PluginMixins::ECSCompatibilitySupport
        include LogStash::PluginMixins::ECSCompatibilitySupport::TargetCheck
      end
      expect( plugin_class.new({}).send(:check_target_set_in_ecs_mode) ).to be nil
    end

  end

end