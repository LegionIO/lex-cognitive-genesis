# frozen_string_literal: true

RSpec.describe Legion::Extensions::CognitiveGenesis::Client do
  subject(:client) { described_class.new }

  describe '#initialize' do
    it 'creates a client with a default genesis engine' do
      expect(client).to be_a(described_class)
    end

    it 'accepts an injected engine' do
      engine = Legion::Extensions::CognitiveGenesis::Helpers::GenesisEngine.new
      c      = described_class.new(engine: engine)
      expect(c).to be_a(described_class)
    end
  end

  describe '#plant_seed' do
    it 'returns success true' do
      result = client.plant_seed(concept_type: :fusion, source_domains: %i[perception memory],
                                 novelty: 0.8, viability: 0.6)
      expect(result[:success]).to be true
    end

    it 'returns a seed_id' do
      result = client.plant_seed(concept_type: :abstraction, source_domains: [:reasoning],
                                 novelty: 0.7, viability: 0.5)
      expect(result[:seed_id]).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'uses provided engine kwarg when given' do
      engine = Legion::Extensions::CognitiveGenesis::Helpers::GenesisEngine.new
      client.plant_seed(concept_type: :analogy, source_domains: [:language],
                        novelty: 0.6, viability: 0.5, engine: engine)
      expect(engine.seeds.size).to eq(1)
    end
  end

  describe '#synthesize' do
    let(:sid_a) do
      client.plant_seed(concept_type: :fusion, source_domains: %i[perception memory],
                        novelty: 0.8, viability: 0.6)[:seed_id]
    end

    let(:sid_b) do
      client.plant_seed(concept_type: :abstraction, source_domains: %i[reasoning language],
                        novelty: 0.7, viability: 0.55)[:seed_id]
    end

    it 'returns success true for two valid seeds' do
      result = client.synthesize(seed_ids: [sid_a, sid_b])
      expect(result[:success]).to be true
    end

    it 'returns error for insufficient seeds' do
      result = client.synthesize(seed_ids: [sid_a])
      expect(result[:success]).to be false
      expect(result[:error]).to eq(:insufficient_seeds)
    end
  end

  describe '#mature_seed' do
    let(:sid) do
      client.plant_seed(concept_type: :mutation, source_domains: [:emotion],
                        novelty: 0.7, viability: 0.5)[:seed_id]
    end

    it 'returns success true' do
      expect(client.mature_seed(seed_id: sid)[:success]).to be true
    end

    it 'advances the stage' do
      result = client.mature_seed(seed_id: sid)
      expect(result[:current_stage]).to eq(:embryonic)
    end

    it 'returns error for unknown seed' do
      result = client.mature_seed(seed_id: 'nonexistent-id')
      expect(result[:success]).to be false
    end
  end

  describe '#list_seeds' do
    before do
      client.plant_seed(concept_type: :fusion, source_domains: [:memory], novelty: 0.8, viability: 0.6)
      client.plant_seed(concept_type: :inversion, source_domains: [:emotion], novelty: 0.6, viability: 0.5)
    end

    it 'returns success true' do
      expect(client.list_seeds[:success]).to be true
    end

    it 'returns seeds array with 2 items' do
      expect(client.list_seeds[:seeds].size).to eq(2)
    end

    it 'includes count' do
      expect(client.list_seeds[:count]).to eq(2)
    end

    it 'includes a summary' do
      expect(client.list_seeds[:summary]).to be_a(Hash)
    end
  end

  describe '#genesis_status' do
    before do
      client.plant_seed(concept_type: :transcendence, source_domains: [:imagination],
                        novelty: 0.95, viability: 0.9)
    end

    it 'returns success true' do
      expect(client.genesis_status[:success]).to be true
    end

    it 'includes total_seeds' do
      expect(client.genesis_status[:total_seeds]).to eq(1)
    end

    it 'includes fertility_label' do
      expect(client.genesis_status[:fertility_label]).to be_a(Symbol)
    end
  end

  describe 'injected engine isolation' do
    it 'two clients with separate engines have isolated state' do
      c1 = described_class.new
      c2 = described_class.new
      c1.plant_seed(concept_type: :fusion, source_domains: [:memory], novelty: 0.8, viability: 0.6)
      expect(c2.genesis_status[:total_seeds]).to eq(0)
    end
  end
end
