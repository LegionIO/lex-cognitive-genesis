# frozen_string_literal: true

RSpec.describe Legion::Extensions::CognitiveGenesis::Helpers::ConceptSeed do
  let(:valid_type)    { :fusion }
  let(:valid_domains) { %i[perception memory] }

  subject(:seed) do
    described_class.new(
      concept_type:   valid_type,
      source_domains: valid_domains,
      novelty:        0.8,
      viability:      0.6
    )
  end

  describe '#initialize' do
    it 'assigns a uuid id' do
      expect(seed.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'assigns concept_type' do
      expect(seed.concept_type).to eq(:fusion)
    end

    it 'assigns source_domains as array' do
      expect(seed.source_domains).to eq(%i[perception memory])
    end

    it 'clamps novelty to 0..1' do
      s = described_class.new(concept_type: :analogy, source_domains: [:language], novelty: 1.5, viability: 0.5)
      expect(s.novelty).to eq(1.0)
    end

    it 'clamps novelty below 0 to 0' do
      s = described_class.new(concept_type: :analogy, source_domains: [:language], novelty: -0.3, viability: 0.5)
      expect(s.novelty).to eq(0.0)
    end

    it 'clamps viability to 0..1' do
      s = described_class.new(concept_type: :mutation, source_domains: [:emotion], novelty: 0.5, viability: 2.0)
      expect(s.viability).to eq(1.0)
    end

    it 'starts at germinal stage' do
      expect(seed.maturity_stage).to eq(:germinal)
    end

    it 'initializes with empty parent_ids by default' do
      expect(seed.parent_ids).to eq([])
    end

    it 'accepts parent_ids' do
      s = described_class.new(concept_type: :fusion, source_domains: [:memory],
                              parent_ids: %w[parent-1 parent-2])
      expect(s.parent_ids).to eq(%w[parent-1 parent-2])
    end

    it 'sets created_at to current time' do
      before = Time.now.utc
      s = described_class.new(concept_type: :abstraction, source_domains: [:reasoning])
      after = Time.now.utc
      expect(s.created_at).to be >= before
      expect(s.created_at).to be <= after
    end

    it 'raises ArgumentError for unknown concept_type' do
      expect do
        described_class.new(concept_type: :invalid_type, source_domains: [:memory])
      end.to raise_error(ArgumentError, /unknown concept_type/)
    end

    it 'wraps single source_domain in array' do
      s = described_class.new(concept_type: :fusion, source_domains: :perception)
      expect(s.source_domains).to eq([:perception])
    end

    it 'uses DEFAULT_NOVELTY when not specified' do
      s = described_class.new(concept_type: :analogy, source_domains: [:language])
      expect(s.novelty).to eq(Legion::Extensions::CognitiveGenesis::Helpers::Constants::DEFAULT_NOVELTY)
    end
  end

  describe '#mature!' do
    it 'advances maturity stage' do
      expect { seed.mature! }.to change(seed, :maturity_stage).from(:germinal).to(:embryonic)
    end

    it 'boosts viability by MATURATION_RATE' do
      rate = Legion::Extensions::CognitiveGenesis::Helpers::Constants::MATURATION_RATE
      expect { seed.mature! }.to change(seed, :viability).by(rate)
    end

    it 'does not advance past crystallized' do
      6.times { seed.mature! }
      expect(seed.maturity_stage).to eq(:crystallized)
      seed.mature!
      expect(seed.maturity_stage).to eq(:crystallized)
    end

    it 'caps viability at 1.0' do
      high_seed = described_class.new(concept_type: :emergence, source_domains: [:imagination], viability: 0.99)
      high_seed.mature!
      expect(high_seed.viability).to be <= 1.0
    end

    it 'returns self for chaining' do
      expect(seed.mature!).to be(seed)
    end

    it 'advances through all stages sequentially' do
      expected = %i[germinal embryonic nascent developing viable mature crystallized]
      stages   = [seed.maturity_stage]
      6.times { seed.mature!; stages << seed.maturity_stage }
      expect(stages).to eq(expected)
    end
  end

  describe '#decay!' do
    it 'reduces novelty by NOVELTY_DECAY' do
      decay = Legion::Extensions::CognitiveGenesis::Helpers::Constants::NOVELTY_DECAY
      expect { seed.decay! }.to change(seed, :novelty).by(-decay)
    end

    it 'does not reduce novelty below 0' do
      low_seed = described_class.new(concept_type: :inversion, source_domains: [:social], novelty: 0.01)
      low_seed.decay!
      expect(low_seed.novelty).to be >= 0.0
    end

    it 'returns self for chaining' do
      expect(seed.decay!).to be(seed)
    end
  end

  describe '#viable?' do
    it 'returns true when viability > VIABILITY_THRESHOLD' do
      s = described_class.new(concept_type: :fusion, source_domains: [:emotion], viability: 0.9)
      expect(s.viable?).to be true
    end

    it 'returns false when viability <= VIABILITY_THRESHOLD' do
      s = described_class.new(concept_type: :fusion, source_domains: [:emotion], viability: 0.2)
      expect(s.viable?).to be false
    end
  end

  describe '#novel?' do
    it 'returns true when novelty > NOVELTY_THRESHOLD' do
      s = described_class.new(concept_type: :abstraction, source_domains: [:language], novelty: 0.85)
      expect(s.novel?).to be true
    end

    it 'returns false when novelty <= NOVELTY_THRESHOLD' do
      s = described_class.new(concept_type: :abstraction, source_domains: [:language], novelty: 0.3)
      expect(s.novel?).to be false
    end
  end

  describe '#truly_novel?' do
    it 'returns true when novel and no parent_ids' do
      s = described_class.new(concept_type: :transcendence, source_domains: [:imagination],
                              novelty: 0.9, parent_ids: [])
      expect(s.truly_novel?).to be true
    end

    it 'returns false when novel but has parent_ids' do
      s = described_class.new(concept_type: :emergence, source_domains: [:memory],
                              novelty: 0.9, parent_ids: %w[p1])
      expect(s.truly_novel?).to be false
    end

    it 'returns false when not novel regardless of parent_ids' do
      s = described_class.new(concept_type: :fusion, source_domains: [:reasoning],
                              novelty: 0.3, parent_ids: [])
      expect(s.truly_novel?).to be false
    end
  end

  describe '#crystallized?' do
    it 'returns false initially' do
      expect(seed.crystallized?).to be false
    end

    it 'returns true after 6 mature! calls' do
      6.times { seed.mature! }
      expect(seed.crystallized?).to be true
    end
  end

  describe '#germinal?' do
    it 'returns true initially' do
      expect(seed.germinal?).to be true
    end

    it 'returns false after maturation' do
      seed.mature!
      expect(seed.germinal?).to be false
    end
  end

  describe '#novelty_label' do
    it 'returns :transcendent for very high novelty' do
      s = described_class.new(concept_type: :transcendence, source_domains: [:imagination], novelty: 0.95)
      expect(s.novelty_label).to eq(:transcendent)
    end

    it 'returns :highly_novel for novelty in 0.7..0.9' do
      s = described_class.new(concept_type: :mutation, source_domains: [:memory], novelty: 0.75)
      expect(s.novelty_label).to eq(:highly_novel)
    end

    it 'returns :conventional for low novelty' do
      s = described_class.new(concept_type: :fusion, source_domains: [:language], novelty: 0.1)
      expect(s.novelty_label).to eq(:conventional)
    end
  end

  describe '#viability_label' do
    it 'returns :strongly_viable for high viability' do
      s = described_class.new(concept_type: :abstraction, source_domains: [:emotion], viability: 0.9)
      expect(s.viability_label).to eq(:strongly_viable)
    end

    it 'returns :non_viable for very low viability' do
      s = described_class.new(concept_type: :analogy, source_domains: [:social], viability: 0.05)
      expect(s.viability_label).to eq(:non_viable)
    end
  end

  describe '#to_h' do
    it 'returns a hash with all expected keys' do
      h = seed.to_h
      expect(h.keys).to include(:id, :concept_type, :source_domains, :novelty, :viability,
                                 :maturity_stage, :parent_ids, :created_at, :novel,
                                 :viable, :truly_novel, :crystallized, :novelty_label, :viability_label)
    end

    it 'rounds novelty and viability to 6 decimal places' do
      s = described_class.new(concept_type: :fusion, source_domains: [:perception],
                              novelty: 0.123456789, viability: 0.987654321)
      h = s.to_h
      expect(h[:novelty].to_s.split('.').last.length).to be <= 6
      expect(h[:viability].to_s.split('.').last.length).to be <= 6
    end

    it 'serializes created_at as iso8601 string' do
      expect(seed.to_h[:created_at]).to match(/\d{4}-\d{2}-\d{2}T/)
    end

    it 'includes boolean state flags' do
      h = seed.to_h
      expect(h[:novel]).to eq(seed.novel?)
      expect(h[:viable]).to eq(seed.viable?)
      expect(h[:truly_novel]).to eq(seed.truly_novel?)
      expect(h[:crystallized]).to eq(seed.crystallized?)
    end
  end
end
