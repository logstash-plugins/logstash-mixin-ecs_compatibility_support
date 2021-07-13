# encoding: utf-8

require "logstash-core"

require 'logstash/inputs/base'
require 'logstash/filters/base'
require 'logstash/codecs/base'
require 'logstash/outputs/base'
require 'logstash/codecs/json'

require "logstash/plugin_mixins/ecs_compatibility_support/target_check"

describe LogStash::PluginMixins::ECSCompatibilitySupport::TargetCheck do

  describe "check_target_set_in_ecs_mode" do

    context 'with a plugin' do

      shared_examples "check target set" do
        it 'skips check when ECS disabled' do
          plugin = plugin_class.new('ecs_compatibility' => 'disabled')
          allow( plugin.logger ).to receive(:info)
          expect( plugin.register ).to eql 42
          expect( plugin.logger ).to_not have_received(:info).with(a_string_including "`target` option")
        end

        it 'warns when target is not set in ECS mode' do
          plugin = plugin_class.new('ecs_compatibility' => 'v1')
          allow( plugin.logger ).to receive(:info)
          expect( plugin.register ).to eql 42
          expect( plugin.logger ).to have_received(:info).with(a_string_including "ECS compatibility is enabled but `target` option was not specified.")
        end

        it 'does not warn when target is set' do
          plugin = plugin_class.new('ecs_compatibility' => 'v1', 'target' => 'foo')
          allow( plugin.logger ).to receive(:info)
          expect( plugin.register ).to eql 42
          expect( plugin.logger ).to_not have_received(:info).with(a_string_including "`target` option")
        end
      end

      context "filter" do
        subject(:plugin_class) do
          Class.new(LogStash::Filters::Base) do
            include LogStash::PluginMixins::ECSCompatibilitySupport
            include LogStash::PluginMixins::ECSCompatibilitySupport::TargetCheck

            config :target, :validate => :string

            def register; 42 end

          end
        end

        include_examples("check target set")
      end

      context "input with codec plain" do
        subject(:plugin_class) do
          Class.new(LogStash::Inputs::Base) do
            include LogStash::PluginMixins::ECSCompatibilitySupport
            include LogStash::PluginMixins::ECSCompatibilitySupport::TargetCheck

            default :codec, "plain"

            config :target, :validate => :string

            def register; 42 end

          end
        end

        include_examples("check target set")
      end

      context "input with codec json" do
        subject(:plugin_class) do
          Class.new(LogStash::Inputs::Base) do
            include LogStash::PluginMixins::ECSCompatibilitySupport
            include LogStash::PluginMixins::ECSCompatibilitySupport::TargetCheck

            default :codec, "json"

            config :target, :validate => :string

            def register; 42 end

          end
        end

        it 'warns when target and codec.target are not set' do
          plugin = plugin_class.new('ecs_compatibility' => 'v1')
          allow( plugin.logger ).to receive(:info)
          expect( plugin.register ).to eql 42
          expect( plugin.logger ).to have_received(:info).with(a_string_including "ECS compatibility is enabled but `target` option was not specified in codec.")
        end

        it 'warns when target and codec.target are set' do
          json_codec = LogStash::Codecs::JSON.new('ecs_compatibility' => 'v1', 'target' => 'bar')
          plugin = plugin_class.new('ecs_compatibility' => 'v1', 'target' => 'foo', 'codec' => json_codec )
          allow( plugin.logger ).to receive(:info)
          expect( plugin.register ).to eql 42
          expect( plugin.logger ).to have_received(:info).with(a_string_including "ECS compatibility is enabled but `target` options were set")
        end

        it 'warns when target is set and codec.target is not set' do
          json_codec = LogStash::Codecs::JSON.new('ecs_compatibility' => 'v1')
          plugin = plugin_class.new('ecs_compatibility' => 'v1', 'target' => 'foo', 'codec' => json_codec )
          allow( plugin.logger ).to receive(:info)
          expect( plugin.register ).to eql 42
          expect( plugin.logger ).to have_received(:info).with(a_string_including "ECS compatibility is enabled and `target` was set")
        end

        it 'does not warn when target is not set and codec.target is set' do
          json_codec = LogStash::Codecs::JSON.new('ecs_compatibility' => 'v1', 'target' => 'bar')
          plugin = plugin_class.new('ecs_compatibility' => 'v1', 'target' => 'foo', 'codec' => json_codec )
          allow( plugin.logger ).to receive(:info)
          expect( plugin.register ).to eql 42
          expect( plugin.logger ).to_not have_received(:info).with(a_string_including "`ECS compatibility")
        end
      end
    end

    it 'fails check when no target config' do
      plugin_class = Class.new(LogStash::Filters::Base) do
        include LogStash::PluginMixins::ECSCompatibilitySupport
        include LogStash::PluginMixins::ECSCompatibilitySupport::TargetCheck

        def register; end

      end
      plugin = plugin_class.new('ecs_compatibility' => 'v1')
      expect { plugin.register }.to raise_error NameError, /\btarget\b/
    end

  end

end
