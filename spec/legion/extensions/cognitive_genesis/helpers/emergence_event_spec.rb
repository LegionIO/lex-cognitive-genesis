# frozen_string_literal: true

RSpec.describe Legion::Extensions::CognitiveGenesis::Helpers::EmergenceEvent do
  subject(:event) do
    described_class.new(
      concept_seed_id:    'seed-abc-123',
      trigger_domains:    %i[perception memory],
      emergence_strength: 0.75
    )
  end

  describe '#initialize' do
    it 'assigns a uuid id' do
      expect(event.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'assigns concept_seed_id' do
      expect(event.concept_seed_id).to eq('seed-abc-123')
    end

    it 'assigns trigger_domains as array' do
      expect(event.trigger_domains).to eq(%i[perception memory])
    end

    it 'clamps emergence_strength to 0..1' do
      e = described_class.new(concept_seed_id: 's1', trigger_domains: [:emotion], emergence_strength: 1.8)
      expect(e.emergence_strength).to eq(1.0)
    end

    it 'clamps emergence_strength below 0 to 0' do
      e = described_class.new(concept_seed_id: 's1', trigger_domains: [:emotion], emergence_strength: -0.5)
      expect(e.emergence_strength).to eq(0.0)
    end

    it 'sets timestamp to current time' do
      before = Time.now.utc
      e      = described_class.new(concept_seed_id: 's', trigger_domains: [:memory], emergence_strength: 0.5)
      after  = Time.now.utc
      expect(e.timestamp).to be >= before
      expect(e.timestamp).to be <= after
    end

    it 'wraps single trigger_domain in array' do
      e = described_class.new(concept_seed_id: 's', trigger_domains: :emotion, emergence_strength: 0.5)
      expect(e.trigger_domains).to eq([:emotion])
    end

    it 'each new event has a unique id' do
      e1 = described_class.new(concept_seed_id: 's', trigger_domains: [:memory], emergence_strength: 0.5)
      e2 = described_class.new(concept_seed_id: 's', trigger_domains: [:memory], emergence_strength: 0.5)
      expect(e1.id).not_to eq(e2.id)
    end
  end

  describe '#strong?' do
    it 'returns true when emergence_strength > 0.7' do
      e = described_class.new(concept_seed_id: 's', trigger_domains: [:memory], emergence_strength: 0.85)
      expect(e.strong?).to be true
    end

    it 'returns false when emergence_strength <= 0.7' do
      e = described_class.new(concept_seed_id: 's', trigger_domains: [:memory], emergence_strength: 0.7)
      expect(e.strong?).to be false
    end

    it 'returns true for the test subject with strength 0.75' do
      expect(event.strong?).to be true
    end
  end

  describe '#weak?' do
    it 'returns true when emergence_strength < 0.3' do
      e = described_class.new(concept_seed_id: 's', trigger_domains: [:memory], emergence_strength: 0.1)
      expect(e.weak?).to be true
    end

    it 'returns false when emergence_strength >= 0.3' do
      e = described_class.new(concept_seed_id: 's', trigger_domains: [:memory], emergence_strength: 0.3)
      expect(e.weak?).to be false
    end

    it 'returns false for the test subject with strength 0.75' do
      expect(event.weak?).to be false
    end
  end

  describe '#moderate?' do
    it 'returns true when strength is between 0.3 and 0.7 inclusive' do
      e = described_class.new(concept_seed_id: 's', trigger_domains: [:memory], emergence_strength: 0.5)
      expect(e.moderate?).to be true
    end

    it 'returns false for strong events' do
      e = described_class.new(concept_seed_id: 's', trigger_domains: [:memory], emergence_strength: 0.9)
      expect(e.moderate?).to be false
    end

    it 'returns false for weak events' do
      e = described_class.new(concept_seed_id: 's', trigger_domains: [:memory], emergence_strength: 0.1)
      expect(e.moderate?).to be false
    end
  end

  describe '#to_h' do
    it 'includes all expected keys' do
      h = event.to_h
      expect(h.keys).to include(:id, :concept_seed_id, :trigger_domains,
                                 :emergence_strength, :timestamp, :strong, :weak, :moderate)
    end

    it 'rounds emergence_strength to 6 decimal places' do
      e = described_class.new(concept_seed_id: 's', trigger_domains: [:emotion],
                               emergence_strength: 0.123456789)
      h = e.to_h
      expect(h[:emergence_strength].to_s.split('.').last.length).to be <= 6
    end

    it 'serializes timestamp as iso8601 string' do
      expect(event.to_h[:timestamp]).to match(/\d{4}-\d{2}-\d{2}T/)
    end

    it 'includes correct boolean flags' do
      h = event.to_h
      expect(h[:strong]).to eq(event.strong?)
      expect(h[:weak]).to eq(event.weak?)
      expect(h[:moderate]).to eq(event.moderate?)
    end
  end
end
