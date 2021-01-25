# encoding: utf-8

require 'rspec/its'

require "logstash-core"

require 'logstash/inputs/base'
require 'logstash/filters/base'
require 'logstash/codecs/base'
require 'logstash/outputs/base'

require "logstash/plugin_mixins/ecs_compatibility_support/selector"

describe LogStash::PluginMixins::ECSCompatibilitySupport::Selector do
  context 'initialize' do
    it 'rejects zero arguments' do
      expect { described_class.new }.to raise_error(ArgumentError, /one or more/)
    end
    it 'rejects non-symbol arguments' do
      expect { described_class.new("v1") }.to raise_error(ArgumentError, /symbol/)
    end
    it 'accepts one symbol argument'do
      selector_mod = described_class.new(:disabled)
      aggregate_failures do
        expect(selector_mod.ecs_modes_supported).to contain_exactly(:disabled)
        expect(selector_mod.name).to include('disabled')
      end
    end
    it 'accepts many symbol arguments'do
      selector_mod = described_class.new(:disabled, :v1)
      aggregate_failures do
        expect(selector_mod.ecs_modes_supported).to contain_exactly(:disabled, :v1)
        expect(selector_mod.name).to include('disabled')
        expect(selector_mod.name).to include('v1')
      end
    end
  end
  context 'included into a class' do
    let(:ecs_compatibility_support) { LogStash::PluginMixins::ECSCompatibilitySupport }
    let(:selector_module) { described_class.new(:disabled,:v1) }
    context 'that does not inherit from LogStash::Plugin' do
      let(:plugin_class) { Class.new }
      it 'fails with an ArgumentError' do
        expect do
          plugin_class.send(:include, selector_module)
        end.to raise_error(ArgumentError, /LogStash::Plugin/)
      end
    end

    [
      LogStash::Inputs::Base,
      LogStash::Filters::Base,
      LogStash::Codecs::Base,
      LogStash::Outputs::Base
    ].each do |base_class|
      context "that inherits from `#{base_class}`" do
        let(:ecs_supported_modes) { [:disabled, :v1] }
        let(:selector_module) { described_class.new(*ecs_supported_modes) }
        let(:plugin_base_class) { base_class }
        subject(:plugin_class) do
          klass = Class.new(plugin_base_class) do
            config_name 'test'
          end
          klass.send(:include, selector_module)
          klass
        end
        context 'the result' do
          its(:ancestors) { is_expected.to include(ecs_compatibility_support) }
          its(:instance_methods) { is_expected.to include(:ecs_select) }
        end
        context '#ecs_select' do
          let(:plugin_options) { Hash.new }
          let(:plugin_instance) { plugin_class.new(plugin_options) }
          let(:ecs_effective_mode) { :v1 }

          before(:each) do
            # occurs during initialization, before we can get a reference to the instance.
            # our plugin_class is generated per-spec and not reused.
            allow_any_instance_of(plugin_class).to receive(:ecs_compatibility).and_return(ecs_effective_mode)
          end

          subject(:ecs_select) { plugin_instance.ecs_select }

          it { is_expected.to be_a_kind_of described_class::State }
          it { is_expected.to respond_to :[] }

          context 'when effective ecs_compatibility is not supported' do
            let(:ecs_supported_modes) { [:disabled,:v1,:v2] }
            let(:ecs_effective_mode) { :v3 }
            it 'raises a configuration error' do
              expect { plugin_instance.ecs_select }.to raise_error(LogStash::ConfigurationError)
            end
          end

          context '#[]' do
            it 'rejects empty options' do
              expect { ecs_select[{}] }.to raise_error(ArgumentError, /empty/)
            end
            it 'rejects unknown options' do
              expect { ecs_select[disabled: "nope", v1: "no", bananas: "monkey"] }.to raise_error(ArgumentError, /unknown/)
            end
            it 'rejects missing options' do
              expect { ecs_select[disabled: "nope"] }.to raise_error(ArgumentError, /missing/)
            end
            it 'rejects non-hash options' do
              expect { ecs_select["bananas"] }.to raise_error(ArgumentError, /Hash/)
            end
            it 'requires symbol keys' do
              expect { ecs_select["bananas"=>"apes"] }.to raise_error(ArgumentError, /Symbol keys/)
            end
            it 'selects the correct effective value' do
              expect(ecs_select[disabled: "nope", v1: "winner"]).to eq("winner")
            end
          end
        end
      end
    end
  end
end