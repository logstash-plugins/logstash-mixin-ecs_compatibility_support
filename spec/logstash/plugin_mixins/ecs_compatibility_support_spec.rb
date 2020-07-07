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
        native_support_for_ecs_compatibility = base_class.method_defined?(:ecs_compatibility)

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

          it 'defines an `ecs_compatibility` method' do
            expect(plugin_class.method_defined?(:ecs_compatibility)).to be true
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
                  config :ecs_compatibility
                  def ecs_compatibility
                  end
                end
              end
              before(:each) do
                expect(plugin_base_class.method_defined?(:ecs_compatibility)).to be true
              end
              its(:ancestors) { is_expected.to_not include(ecs_compatibility_support::LegacyAdapter) }
            end
          end

          # The four plugin base classes override their own `#initialize` to also
          # send `#config_init`, so we can count on the options being normalized
          # and available.
          context 'when initialized' do
            let(:plugin_options) { Hash.new }
            subject(:instance) { plugin_class.new(plugin_options) }

            context 'with `ecs_compatibility => v1`' do
              let(:plugin_options) { super().merge('ecs_compatibility' => 'v1') }
              its(:ecs_compatibility) { should equal :v1 }
            end

            context 'with `ecs_compatibility => disabled`' do
              let(:plugin_options) { super().merge('ecs_compatibility' => 'disabled') }
              its(:ecs_compatibility) { should equal :disabled }
            end

            context 'with an invalid value for `ecs_compatibility`' do
              shared_examples 'invalid value' do |invalid_value|
                before { allow(plugin_class).to receive(:logger).and_return(logger_stub) }
                let(:logger_stub) { double('Logger').as_null_object }

                let(:plugin_options) { super().merge('ecs_compatibility' => invalid_value) }

                it 'fails to initialize and emits a helpful log message' do
                  # we cannot rely on internal details of the error that is emitted such as its exact message,
                  # but we can expect the given value to be included in a message logged at ERROR-level.
                  expect { plugin_class.new(plugin_options) }.to raise_error(LogStash::ConfigurationError)
                  expect(logger_stub).to have_received(:error).with(/\b#{Regexp.escape(invalid_value.to_s)}\b/)
                end
              end

              context('a random string') do
                include_examples 'invalid value', 'bananas'
              end

              context('nil') do
                include_examples 'invalid value', nil
              end

              context('an integer') do
                include_examples 'invalid value', 17
              end
            end

            # we only specify default behaviour in cases where native support is _NOT_ provided.
            unless native_support_for_ecs_compatibility
              context 'without an `ecs_compatibility` directive' do
                its(:ecs_compatibility) { should equal :disabled }
              end
            end
          end
        end
      end
    end
  end
end

