# encoding: utf-8

require "logstash-core"

require 'logstash/inputs/base'
require 'logstash/filters/base'
require 'logstash/codecs/base'
require 'logstash/outputs/base'

require "logstash/plugin_mixins/ecs_compatibility_support/target_check"

describe LogStash::PluginMixins::ECSCompatibilitySupport::TargetCheck do
  subject(:plugin) { plugin_class.new(plugin_params) }
  let(:plugin_params) { Hash.new }

  let(:logger) { double("Logger").as_null_object }
  before { allow(plugin).to receive(:logger).and_return(logger)}

  context 'with a plugin' do

    shared_examples "check target set" do
      context("ECS disabled") do
        let(:plugin_params) { super().merge('ecs_compatibility' => 'disabled') }
        it 'does not log info about setting the target' do
          expect(plugin.register).to eql 42
          expect(plugin.logger).to_not have_received(:info).with(a_string_including "`target` option")
        end
      end

      context "ECS enabled" do
        let(:plugin_params) { super().merge('ecs_compatibility' => 'v1') }

        context "when target not set" do
          it 'emits a helpful info log' do
            expect(plugin.register).to eql 42
            expect(plugin.logger).to have_received(:info).with(a_string_including("ECS compatibility is enabled but `target` option was not specified.")
                                                                 .and(including "set the `target` option to avoid potential schema conflicts"))
          end
        end

        context "when target is provided" do
          let(:plugin_params) { super().merge('target' => 'foo') }
          it 'does not emit an info log about setting the target' do
            expect(plugin.register).to eql 42
            expect(plugin.logger).to_not have_received(:info).with(a_string_including "`target` option")
          end
        end
      end
    end

    context "filter" do
      let(:plugin_class) do
        Class.new(LogStash::Filters::Base) do
          include LogStash::PluginMixins::ECSCompatibilitySupport
          include LogStash::PluginMixins::ECSCompatibilitySupport::TargetCheck

          config :target, :validate => :string

          def register; 42 end
        end
      end

      include_examples("check target set")
    end

    context "input" do
      let(:plugin_class) do
        Class.new(LogStash::Inputs::Base) do
          include LogStash::PluginMixins::ECSCompatibilitySupport
          include LogStash::PluginMixins::ECSCompatibilitySupport::TargetCheck

          config :target, :validate => :string

          def register; 42 end
        end
      end
      let(:codec) { codec_class.new(codec_params) }
      let(:codec_params) { Hash.new }

      context 'when configured with a codec that does not support `target`' do
        let(:codec_class) do
          Class.new(LogStash::Codecs::Base)
        end
        let(:plugin_params) { super().merge('codec' => codec) }

        include_examples("check target set")
      end

      context 'when configured with a codec that supports `target`' do
        let(:codec_class) do
          Class.new(LogStash::Codecs::Base) do
            config_name :dummy
            config :target, :validate => :string
          end
        end
        let(:plugin_params) { super().merge('codec' => codec) }


        context "and neither the input's target nor the codec's target is set" do
          context "and ECS compatibility is enabled" do
            let(:plugin_params) { super().merge('ecs_compatibility' => 'v1') }
            it "logs info advocating for setting the codec's target" do
              expect(plugin.register).to eq(42)
              expect(plugin.logger).to have_received(:info).with(a_string_including "set the `target` option on the codec")
            end
          end
          context "and ECS compatibility is disabled" do
            let(:plugin_params) { super().merge('ecs_compatibility' => 'disabled') }
            it "does not log info about targets" do
              expect(plugin.register).to eq(42)
              expect(plugin.logger).to_not have_received(:info).with(a_string_including "`target`")
            end
          end
        end

        context "and both the input's target and the codec's target are specified" do
          let(:plugin_params) { super().merge('target' => 'outer') }
          let(:codec_params) { super().merge('target' => 'inner') }

          it 'logs a warning about target being specified multiple places' do
            expect(plugin.register).to eq(42)
            expect(plugin.logger).to have_received(:warn).with(a_string_including "This plugin and its codec are both configured with a `target` option")
          end
        end

        context "and target is provided in the input but not the codec" do
          let(:plugin_params) { super().merge('target' => 'outer') }

          it "logs info about preferring the codec's target" do
            expect(plugin.register).to eq(42)
            expect(plugin.logger).to have_received(:warn).with(a_string_including("codec's `target` was left unspecified")
                                                                 .and(including "only set the codec's `target`")
                                                                 .and(including "`codec => dummy { target => \"outer\" }`"))
          end
        end

        context "and target is provided in the codec but not the input" do
          let(:codec_params) { super().merge('target' => 'inner') }

          it "does not log info about target" do
            expect(plugin.register).to eq(42)
            expect(plugin.logger).to_not have_received(:info).with(a_string_including("`target`"))
          end
        end
      end
    end
  end

  context 'with a plugin that does not have target config' do
    let(:plugin_class) do
      Class.new(LogStash::Filters::Base) do
        include LogStash::PluginMixins::ECSCompatibilitySupport
        include LogStash::PluginMixins::ECSCompatibilitySupport::TargetCheck

        def register; end
      end
    end
    it 'raises an error at registration' do
      expect { plugin.register }.to raise_error NameError, /\btarget\b/
    end
  end

end
