# frozen_string_literal: true

RSpec.describe Legion::Extensions::CognitiveGenesis::Helpers::Concept do
  let(:consts) { Legion::Extensions::CognitiveGenesis::Helpers::Constants }
  let(:parent_id) { SecureRandom.uuid }
  let(:defaults) do
    { name: 'liminal cognition', definition: 'threshold state between frameworks',
      parent_seed_id: parent_id, domain: :abstract }
  end

  describe '#initialize' do
    it 'generates a unique UUID concept_id' do
      expect(described_class.new(**defaults).concept_id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'generates unique IDs for each instance' do
      a = described_class.new(**defaults)
      b = described_class.new(**defaults)
      expect(a.concept_id).not_to eq(b.concept_id)
    end

    it 'freezes name' do
      expect(described_class.new(**defaults).name).to be_frozen
    end

    it 'freezes definition' do
      expect(described_class.new(**defaults).definition).to be_frozen
    end

    it 'coerces domain to symbol' do
      c = described_class.new(**defaults.merge(domain: 'emergent'))
      expect(c.domain).to eq(:emergent)
    end

    it 'raises ArgumentError for invalid domain' do
      expect { described_class.new(**defaults.merge(domain: :imaginary)) }
        .to raise_error(ArgumentError, /invalid domain/)
    end

    it 'clamps maturity to 1.0' do
      expect(described_class.new(**defaults, maturity: 2.5).maturity).to eq(1.0)
    end

    it 'clamps maturity to 0.0' do
      expect(described_class.new(**defaults, maturity: -0.1).maturity).to eq(0.0)
    end

    it 'clamps utility_score to 1.0' do
      expect(described_class.new(**defaults, utility_score: 5.0).utility_score).to eq(1.0)
    end

    it 'defaults maturity to 0.0' do
      expect(described_class.new(**defaults).maturity).to eq(0.0)
    end

    it 'defaults adoption_count to 0' do
      expect(described_class.new(**defaults).adoption_count).to eq(0)
    end

    it 'defaults connections to empty array' do
      expect(described_class.new(**defaults).connections).to eq([])
    end

    it 'sets born_at to UTC Time' do
      before = Time.now.utc
      c      = described_class.new(**defaults)
      after  = Time.now.utc
      expect(c.born_at).to be >= before
      expect(c.born_at).to be <= after
    end
  end

  describe '#maturity_label' do
    it 'returns :nascent for maturity 0.0' do
      expect(described_class.new(**defaults, maturity: 0.0).maturity_label).to eq(:nascent)
    end

    it 'returns :foundational for maturity 0.9' do
      expect(described_class.new(**defaults, maturity: 0.9).maturity_label).to eq(:foundational)
    end

    it 'returns :establishing for maturity 0.5' do
      expect(described_class.new(**defaults, maturity: 0.5).maturity_label).to eq(:establishing)
    end
  end

  describe '#fitness_label' do
    it 'returns :untested for utility 0.1' do
      expect(described_class.new(**defaults, utility_score: 0.1).fitness_label).to eq(:untested)
    end

    it 'returns :essential for utility 0.9' do
      expect(described_class.new(**defaults, utility_score: 0.9).fitness_label).to eq(:essential)
    end
  end

  describe '#adopt!' do
    it 'increments adoption_count' do
      c = described_class.new(**defaults)
      c.adopt!
      expect(c.adoption_count).to eq(1)
    end

    it 'increases utility_score by ADOPTION_BONUS' do
      c = described_class.new(**defaults, utility_score: 0.3)
      c.adopt!
      expect(c.utility_score).to be_within(0.0001).of(0.3 + consts::ADOPTION_BONUS)
    end

    it 'increases maturity by MATURITY_BOOST' do
      c = described_class.new(**defaults, maturity: 0.2)
      c.adopt!
      expect(c.maturity).to be_within(0.0001).of(0.2 + consts::MATURITY_BOOST)
    end

    it 'clamps utility_score at 1.0' do
      c = described_class.new(**defaults, utility_score: 0.98)
      c.adopt!
      expect(c.utility_score).to eq(1.0)
    end

    it 'accumulates over multiple calls' do
      c = described_class.new(**defaults)
      3.times { c.adopt! }
      expect(c.adoption_count).to eq(3)
    end
  end

  describe '#nurture!' do
    it 'increases maturity by default MATURITY_BOOST' do
      c = described_class.new(**defaults, maturity: 0.4)
      c.nurture!
      expect(c.maturity).to be_within(0.0001).of(0.4 + consts::MATURITY_BOOST)
    end

    it 'accepts a custom boost' do
      c = described_class.new(**defaults, maturity: 0.3)
      c.nurture!(boost: 0.2)
      expect(c.maturity).to be_within(0.0001).of(0.5)
    end

    it 'clamps at 1.0' do
      c = described_class.new(**defaults, maturity: 0.99)
      c.nurture!
      expect(c.maturity).to eq(1.0)
    end
  end

  describe '#decay!' do
    it 'decreases maturity by MATURITY_DECAY' do
      c = described_class.new(**defaults, maturity: 0.5)
      c.decay!
      expect(c.maturity).to be_within(0.0001).of(0.5 - consts::MATURITY_DECAY)
    end

    it 'clamps at 0.0' do
      c = described_class.new(**defaults, maturity: 0.01)
      c.decay!
      expect(c.maturity).to eq(0.0)
    end

    it 'accepts a custom rate' do
      c = described_class.new(**defaults, maturity: 0.5)
      c.decay!(rate: 0.1)
      expect(c.maturity).to be_within(0.0001).of(0.4)
    end
  end

  describe '#connect_to' do
    it 'adds a concept_id to connections' do
      c  = described_class.new(**defaults)
      id = SecureRandom.uuid
      c.connect_to(id)
      expect(c.connections).to include(id)
    end

    it 'does not add duplicates' do
      c  = described_class.new(**defaults)
      id = SecureRandom.uuid
      c.connect_to(id)
      c.connect_to(id)
      expect(c.connections.count(id)).to eq(1)
    end

    it 'supports multiple unique connections' do
      c = described_class.new(**defaults)
      3.times { c.connect_to(SecureRandom.uuid) }
      expect(c.connections.size).to eq(3)
    end
  end

  describe '#orphan?' do
    it 'returns true when adoption_count is 0' do
      expect(described_class.new(**defaults).orphan?).to be true
    end

    it 'returns false after one adoption' do
      c = described_class.new(**defaults)
      c.adopt!
      expect(c.orphan?).to be false
    end
  end

  describe '#to_h' do
    subject(:hash) { described_class.new(**defaults).to_h }

    it { expect(hash[:concept_id]).to match(/\A[0-9a-f-]{36}\z/) }
    it { expect(hash[:name]).to eq('liminal cognition') }
    it { expect(hash[:definition]).to include('threshold state') }
    it { expect(hash[:parent_seed_id]).to be_a(String) }
    it { expect(hash[:domain]).to eq(:abstract) }
    it { expect(hash[:maturity]).to eq(0.0) }
    it { expect(hash[:maturity_label]).to eq(:nascent) }
    it { expect(hash[:connections]).to eq([]) }
    it { expect(hash[:utility_score]).to eq(0.0) }
    it { expect(hash[:fitness_label]).to eq(:untested) }
    it { expect(hash[:adoption_count]).to eq(0) }
    it { expect(hash[:orphan]).to be true }
    it { expect(hash[:born_at]).to be_a(Time) }
  end
end
