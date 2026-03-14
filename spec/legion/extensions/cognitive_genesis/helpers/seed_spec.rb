# frozen_string_literal: true

RSpec.describe Legion::Extensions::CognitiveGenesis::Helpers::Seed do
  let(:defaults) { { raw_material: %w[light wave photon], domain: :abstract } }

  let(:consts) { Legion::Extensions::CognitiveGenesis::Helpers::Constants }

  describe '#initialize' do
    it 'generates a UUID seed_id' do
      seed = described_class.new(**defaults)
      expect(seed.seed_id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'generates unique IDs for each instance' do
      a = described_class.new(**defaults)
      b = described_class.new(**defaults)
      expect(a.seed_id).not_to eq(b.seed_id)
    end

    it 'freezes raw_material as an array' do
      seed = described_class.new(**defaults)
      expect(seed.raw_material).to eq(%w[light wave photon])
      expect(seed.raw_material).to be_frozen
    end

    it 'wraps scalar raw_material in an array' do
      seed = described_class.new(raw_material: 'single', domain: :linguistic)
      expect(seed.raw_material).to eq(['single'])
    end

    it 'coerces domain to symbol' do
      seed = described_class.new(raw_material: [], domain: 'logical')
      expect(seed.domain).to eq(:logical)
    end

    it 'raises ArgumentError for invalid domain' do
      expect { described_class.new(raw_material: [], domain: :bogus) }
        .to raise_error(ArgumentError, /invalid domain/)
    end

    it 'clamps germination_potential at 1.0' do
      seed = described_class.new(**defaults, germination_potential: 1.5)
      expect(seed.germination_potential).to eq(1.0)
    end

    it 'clamps germination_potential at 0.0' do
      seed = described_class.new(**defaults, germination_potential: -0.3)
      expect(seed.germination_potential).to eq(0.0)
    end

    it 'clamps novelty_score to 0.0..1.0' do
      seed = described_class.new(**defaults, novelty_score: 2.0)
      expect(seed.novelty_score).to eq(1.0)
    end

    it 'clamps viability to 0.0..1.0' do
      seed = described_class.new(**defaults, viability: -1.0)
      expect(seed.viability).to eq(0.0)
    end

    it 'sets created_at to UTC Time' do
      before = Time.now.utc
      seed   = described_class.new(**defaults)
      after  = Time.now.utc
      expect(seed.created_at).to be_a(Time)
      expect(seed.created_at).to be >= before
      expect(seed.created_at).to be <= after
    end

    it 'defaults germination_potential to DEFAULT_GERMINATION' do
      seed = described_class.new(**defaults)
      expect(seed.germination_potential).to eq(consts::DEFAULT_GERMINATION)
    end
  end

  describe '#germination_label' do
    it 'returns :dormant for potential 0.05' do
      seed = described_class.new(**defaults, germination_potential: 0.05)
      expect(seed.germination_label).to eq(:dormant)
    end

    it 'returns :ready for potential 0.85' do
      seed = described_class.new(**defaults, germination_potential: 0.85)
      expect(seed.germination_label).to eq(:ready)
    end

    it 'returns :awakening for potential 0.5' do
      seed = described_class.new(**defaults, germination_potential: 0.5)
      expect(seed.germination_label).to eq(:awakening)
    end
  end

  describe '#novelty_label' do
    it 'returns :derivative for novelty 0.1' do
      seed = described_class.new(**defaults, novelty_score: 0.1)
      expect(seed.novelty_label).to eq(:derivative)
    end

    it 'returns :novel for novelty 0.7' do
      seed = described_class.new(**defaults, novelty_score: 0.7)
      expect(seed.novelty_label).to eq(:novel)
    end

    it 'returns :unprecedented for novelty 0.9' do
      seed = described_class.new(**defaults, novelty_score: 0.9)
      expect(seed.novelty_label).to eq(:unprecedented)
    end
  end

  describe '#viable?' do
    it 'returns false below VIABILITY_THRESHOLD' do
      seed = described_class.new(**defaults, viability: consts::VIABILITY_THRESHOLD - 0.01)
      expect(seed.viable?).to be false
    end

    it 'returns true at VIABILITY_THRESHOLD' do
      seed = described_class.new(**defaults, viability: consts::VIABILITY_THRESHOLD)
      expect(seed.viable?).to be true
    end

    it 'returns true above VIABILITY_THRESHOLD' do
      seed = described_class.new(**defaults, viability: 0.9)
      expect(seed.viable?).to be true
    end
  end

  describe '#novel?' do
    it 'returns false below NOVELTY_THRESHOLD' do
      seed = described_class.new(**defaults, novelty_score: consts::NOVELTY_THRESHOLD - 0.01)
      expect(seed.novel?).to be false
    end

    it 'returns true at NOVELTY_THRESHOLD' do
      seed = described_class.new(**defaults, novelty_score: consts::NOVELTY_THRESHOLD)
      expect(seed.novel?).to be true
    end
  end

  describe '#ready_to_birth?' do
    it 'returns false when germination_potential is below threshold' do
      seed = described_class.new(**defaults, germination_potential: 0.5, viability: 0.6, novelty_score: 0.7)
      expect(seed.ready_to_birth?).to be false
    end

    it 'returns false when not viable' do
      seed = described_class.new(**defaults, germination_potential: 0.8, viability: 0.2, novelty_score: 0.7)
      expect(seed.ready_to_birth?).to be false
    end

    it 'returns false when not novel' do
      seed = described_class.new(**defaults, germination_potential: 0.8, viability: 0.6, novelty_score: 0.3)
      expect(seed.ready_to_birth?).to be false
    end

    it 'returns true when all conditions met' do
      seed = described_class.new(**defaults, germination_potential: 0.8, viability: 0.6, novelty_score: 0.7)
      expect(seed.ready_to_birth?).to be true
    end
  end

  describe '#to_h' do
    subject(:hash) do
      described_class.new(**defaults, germination_potential: 0.5, novelty_score: 0.5, viability: 0.5).to_h
    end

    it { expect(hash[:seed_id]).to match(/\A[0-9a-f-]{36}\z/) }
    it { expect(hash[:raw_material]).to eq(%w[light wave photon]) }
    it { expect(hash[:domain]).to eq(:abstract) }
    it { expect(hash[:germination_potential]).to eq(0.5) }
    it { expect(hash[:novelty_score]).to eq(0.5) }
    it { expect(hash[:viability]).to eq(0.5) }
    it { expect(hash[:germination_label]).to eq(:awakening) }
    it { expect(hash[:novelty_label]).to eq(:emergent) }
    it { expect(hash[:ready_to_birth]).to be(false).or be(true) }
    it { expect(hash[:created_at]).to be_a(Time) }
  end

  describe 'mutable accessors' do
    it 'allows germination_potential to be updated' do
      seed = described_class.new(**defaults)
      seed.germination_potential = 0.9
      expect(seed.germination_potential).to eq(0.9)
    end

    it 'allows novelty_score to be updated' do
      seed = described_class.new(**defaults)
      seed.novelty_score = 0.75
      expect(seed.novelty_score).to eq(0.75)
    end

    it 'allows viability to be updated' do
      seed = described_class.new(**defaults)
      seed.viability = 0.55
      expect(seed.viability).to eq(0.55)
    end
  end
end
