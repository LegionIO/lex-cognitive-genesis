# frozen_string_literal: true

RSpec.describe Legion::Extensions::CognitiveGenesis::Helpers::Constants do
  describe 'capacity constants' do
    it 'defines MAX_SEEDS as 200' do
      expect(described_class::MAX_SEEDS).to eq(200)
    end

    it 'defines MAX_CONCEPTS as 100' do
      expect(described_class::MAX_CONCEPTS).to eq(100)
    end
  end

  describe 'germination constants' do
    it 'defines DEFAULT_GERMINATION as 0.3' do
      expect(described_class::DEFAULT_GERMINATION).to eq(0.3)
    end

    it 'defines GERMINATION_BOOST as 0.1' do
      expect(described_class::GERMINATION_BOOST).to eq(0.1)
    end

    it 'defines GERMINATION_THRESHOLD as 0.7' do
      expect(described_class::GERMINATION_THRESHOLD).to eq(0.7)
    end
  end

  describe 'novelty and viability thresholds' do
    it 'defines NOVELTY_THRESHOLD as 0.5' do
      expect(described_class::NOVELTY_THRESHOLD).to eq(0.5)
    end

    it 'defines VIABILITY_THRESHOLD as 0.4' do
      expect(described_class::VIABILITY_THRESHOLD).to eq(0.4)
    end
  end

  describe 'concept lifecycle constants' do
    it 'defines MATURITY_BOOST as 0.08' do
      expect(described_class::MATURITY_BOOST).to eq(0.08)
    end

    it 'defines MATURITY_DECAY as 0.02' do
      expect(described_class::MATURITY_DECAY).to eq(0.02)
    end

    it 'defines ADOPTION_BONUS as 0.05' do
      expect(described_class::ADOPTION_BONUS).to eq(0.05)
    end
  end

  describe 'SEED_DOMAINS' do
    it 'is frozen' do
      expect(described_class::SEED_DOMAINS).to be_frozen
    end

    it 'contains exactly 8 domains' do
      expect(described_class::SEED_DOMAINS.size).to eq(8)
    end

    it 'includes all expected domains' do
      expected = %i[linguistic spatial logical interpersonal aesthetic procedural abstract emergent]
      expect(described_class::SEED_DOMAINS).to match_array(expected)
    end

    it 'contains only symbols' do
      expect(described_class::SEED_DOMAINS).to all(be_a(Symbol))
    end
  end

  describe 'GERMINATION_LABELS' do
    it 'is a hash' do
      expect(described_class::GERMINATION_LABELS).to be_a(Hash)
    end

    it 'labels 0.1 as :dormant' do
      expect(described_class.label_for(described_class::GERMINATION_LABELS, 0.1)).to eq(:dormant)
    end

    it 'labels 0.5 as :awakening' do
      expect(described_class.label_for(described_class::GERMINATION_LABELS, 0.5)).to eq(:awakening)
    end

    it 'labels 0.9 as :ready' do
      expect(described_class.label_for(described_class::GERMINATION_LABELS, 0.9)).to eq(:ready)
    end
  end

  describe 'NOVELTY_LABELS' do
    it 'labels 0.1 as :derivative' do
      expect(described_class.label_for(described_class::NOVELTY_LABELS, 0.1)).to eq(:derivative)
    end

    it 'labels 0.7 as :novel' do
      expect(described_class.label_for(described_class::NOVELTY_LABELS, 0.7)).to eq(:novel)
    end

    it 'labels 0.9 as :unprecedented' do
      expect(described_class.label_for(described_class::NOVELTY_LABELS, 0.9)).to eq(:unprecedented)
    end
  end

  describe 'MATURITY_LABELS' do
    it 'labels 0.1 as :nascent' do
      expect(described_class.label_for(described_class::MATURITY_LABELS, 0.1)).to eq(:nascent)
    end

    it 'labels 0.5 as :establishing' do
      expect(described_class.label_for(described_class::MATURITY_LABELS, 0.5)).to eq(:establishing)
    end

    it 'labels 0.9 as :foundational' do
      expect(described_class.label_for(described_class::MATURITY_LABELS, 0.9)).to eq(:foundational)
    end
  end

  describe 'FITNESS_LABELS' do
    it 'labels 0.1 as :untested' do
      expect(described_class.label_for(described_class::FITNESS_LABELS, 0.1)).to eq(:untested)
    end

    it 'labels 0.5 as :promising' do
      expect(described_class.label_for(described_class::FITNESS_LABELS, 0.5)).to eq(:promising)
    end

    it 'labels 0.85 as :essential' do
      expect(described_class.label_for(described_class::FITNESS_LABELS, 0.85)).to eq(:essential)
    end
  end

  describe '.label_for' do
    it 'clamps values below 0.0 to 0.0' do
      expect(described_class.label_for(described_class::NOVELTY_LABELS, -0.5)).to eq(:derivative)
    end

    it 'clamps values above 1.0 to 1.0' do
      expect(described_class.label_for(described_class::NOVELTY_LABELS, 1.5)).to eq(:unprecedented)
    end

    it 'returns last label as fallback when no range matches' do
      sparse = { (0.9..1.0) => :high }
      expect(described_class.label_for(sparse, 0.5)).to eq(:high)
    end
  end
end
