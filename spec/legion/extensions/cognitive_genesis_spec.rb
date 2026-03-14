# frozen_string_literal: true

RSpec.describe Legion::Extensions::CognitiveGenesis do
  it 'exposes the correct version' do
    expect(described_class::VERSION).to eq('0.1.0')
  end

  it 'exposes Helpers::Constants' do
    expect(described_class::Helpers::Constants).to be_a(Module)
  end

  it 'exposes Helpers::Seed' do
    expect(described_class::Helpers::Seed).to be_a(Class)
  end

  it 'exposes Helpers::Concept' do
    expect(described_class::Helpers::Concept).to be_a(Class)
  end

  it 'exposes Helpers::GenesisEngine' do
    expect(described_class::Helpers::GenesisEngine).to be_a(Class)
  end

  it 'exposes Runners::Genesis' do
    expect(described_class::Runners::Genesis).to be_a(Module)
  end

  it 'exposes Client' do
    expect(described_class::Client).to be_a(Class)
  end
end
