# encoding: utf-8

require 'rspec/its'

require "logstash-core"

require 'logstash/inputs/base'
require 'logstash/filters/base'
require 'logstash/codecs/base'
require 'logstash/outputs/base'

require "logstash/plugin_mixins/ecs_compatibility_support"

describe LogStash::PluginMixins::ECSCompatibilitySupport do
  let(:ecs_compatibility_support) { described_class }

  context 'included into a class' do
    context 'that does not inherit from `LogStash::Plugin`' do
      let(:plugin_class) { Class.new }
      it 'fails with an ArgumentError' do
        expect do
          plugin_class.send(:include, ecs_compatibility_support)
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
        native_support_for_ecs_compatibility = base_class.method_defined?(:ecs_compatibility?)

        let(:plugin_base_class) { base_class }

        subject(:plugin_class) do
          Class.new(plugin_base_class) do
            config_name 'test'
          end
        end

        context 'the result' do
          before(:each) do
            plugin_class.send(:include, ecs_compatibility_support)
          end

          it 'supports an `ecs_compatibility` config option' do
            expect(plugin_class.get_config).to include('ecs_compatibility')
          end

          it 'defines an `ecs_compatibility?` method' do
            expect(plugin_class.method_defined?(:ecs_compatibility?)).to be true
          end

          # depending on which version of Logstash is running, we either expect
          # to include or to _NOT_ include the legacy adapter.
          if native_support_for_ecs_compatibility
            context 'since base class provides ECS ecs_compatibility config' do
              its(:ancestors) { is_expected.to_not include(ecs_compatibility_support::LegacyAdapter) }
            end
          else
            context 'since base class does not provide ECS ecs_compatibility config' do
              its(:ancestors) { is_expected.to include(ecs_compatibility_support::LegacyAdapter) }
            end

            # TODO: Remove once ECS Compatibility config is included in one or
            #       more Logstash release branches. This speculative spec is meant
            #       to prove that this implementation will not override an existing
            #       implementation.
            context 'if base class were to include ecs_compatibility config' do
              let(:plugin_base_class) do
                Class.new(super()) do
                  config :ecs_compatibility, :validate => :boolean, :default => false
                  def ecs_compatibility?
                  end
                end
              end
              before(:each) do
                expect(plugin_base_class.method_defined?(:ecs_compatibility?)).to be true
              end
              its(:ancestors) { is_expected.to_not include(ecs_compatibility_support::LegacyAdapter) }
            end
          end

          # The four plugin base classes override their own `#initialize` to also
          # send `#config_init`, so we can count on the options being normalized
          # and populated out to the relevant ivars.
          context 'when initialized' do
            let(:plugin_options) { Hash.new }
            subject(:instance) { plugin_class.new(plugin_options) }

            context 'with `ecs_compatibility => true`' do
              let(:plugin_options) { super().merge('ecs_compatibility' => 'true') }
              its(:ecs_compatibility?) { should be true }
            end

            context 'with `ecs_compatibility => false`' do
              let(:plugin_options) { super().merge('ecs_compatibility' => 'false') }
              its(:ecs_compatibility?) { should be false }
            end

            # we only specify default behaviour in cases where native support is _NOT_ provided.
            unless native_support_for_ecs_compatibility
              context 'without an `ecs_compatibility` directive' do
                its(:ecs_compatibility?) { should be false }
              end
            end
          end
        end
      end
    end
  end
end

