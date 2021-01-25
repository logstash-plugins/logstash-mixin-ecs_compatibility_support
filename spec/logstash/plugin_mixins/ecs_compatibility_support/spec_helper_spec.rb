# encoding: utf-8

require 'rspec/its'

require "logstash/plugin_mixins/ecs_compatibility_support/spec_helper"

describe LogStash::PluginMixins::ECSCompatibilitySupport::SpecHelper, :ecs_compatibility_support do
  context '::ecs_compatibility_matrix(*modes)' do
    ecs_compatibility_matrix(:disabled,:v1) do |ecs_select|
      it("sets `ecs_compatibility` with the current active mode `#{ecs_select.active_mode}`") do
        expect(ecs_compatibility).to eq(ecs_select.active_mode)
      end
      context 'the yielded value' do
        subject { ecs_select }
        it { is_expected.to be_a_kind_of LogStash::PluginMixins::ECSCompatibilitySupport::Selector::State }
        its(:supported_modes) { is_expected.to contain_exactly(:disabled,:v1) }
        its(:active_mode) { is_expected.to be ecs_compatibility }
      end
    end
  end
end
