# frozen_string_literal: true

RSpec.describe Legion::Extensions::CognitiveGenesis::Runners::Genesis do
  let(:engine) { Legion::Extensions::CognitiveGenesis::Helpers::GenesisEngine.new }
  let(:host)   { Object.new.tap { |o| o.extend(described_class) } }

  def plant_viable(eng, domain: :abstract, novelty: 0.8)
    eng.plant(raw_material: %w[concept form structure], domain: domain,
              germination_potential: 0.9, novelty_score: novelty, viability: 0.6)
  end

  describe '#plant_seed' do
    it 'returns success: true' do
      result = host.plant_seed(raw_material: %w[a b], domain: :logical, engine: engine)
      expect(result[:success]).to be true
    end

    it 'returns seed_id' do
      result = host.plant_seed(raw_material: %w[x], domain: :emergent, engine: engine)
      expect(result[:seed_id]).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'returns success: false at capacity' do
      Legion::Extensions::CognitiveGenesis::Helpers::Constants::MAX_SEEDS.times do |i|
        engine.plant(raw_material: ["m#{i}"], domain: :abstract)
      end
      expect(host.plant_seed(raw_material: %w[overflow], domain: :abstract, engine: engine)[:success]).to be false
    end
  end

  describe '#germinate_seed' do
    it 'returns success: true for existing seed' do
      p = plant_viable(engine)
      expect(host.germinate_seed(seed_id: p[:seed_id], engine: engine)[:success]).to be true
    end

    it 'returns success: false for unknown seed' do
      expect(host.germinate_seed(seed_id: 'nope', engine: engine)[:success]).to be false
    end
  end

  describe '#birth_concept' do
    it 'returns success: true for a ready seed' do
      p = plant_viable(engine)
      expect(host.birth_concept(seed_id: p[:seed_id], name: 'meta cognition', definition: 'thinking about thinking', engine: engine)[:success]).to be true
    end

    it 'returns success: false for non-viable seed' do
      p = engine.plant(raw_material: %w[a], domain: :abstract, viability: 0.1, novelty_score: 0.9, germination_potential: 0.9)
      expect(host.birth_concept(seed_id: p[:seed_id], name: 'x', definition: 'y', engine: engine)[:success]).to be false
    end
  end

  describe '#nurture_concept' do
    it 'returns success: true for existing concept' do
      p   = plant_viable(engine)
      cid = engine.birth(seed_id: p[:seed_id], name: 'tender', definition: 'needs care')[:concept_id]
      expect(host.nurture_concept(concept_id: cid, engine: engine)[:success]).to be true
    end

    it 'returns success: false for unknown concept' do
      expect(host.nurture_concept(concept_id: 'ghost', engine: engine)[:success]).to be false
    end
  end

  describe '#prune_seed' do
    it 'returns success: true for existing seed' do
      p = engine.plant(raw_material: %w[dead], domain: :procedural)
      expect(host.prune_seed(seed_id: p[:seed_id], engine: engine)[:success]).to be true
    end

    it 'returns success: false for unknown seed' do
      expect(host.prune_seed(seed_id: 'ghost', engine: engine)[:success]).to be false
    end
  end

  describe '#cross_pollinate' do
    it 'returns success: true for two valid seeds' do
      a = engine.plant(raw_material: %w[red], domain: :spatial, novelty_score: 0.6)
      b = engine.plant(raw_material: %w[blue], domain: :aesthetic, novelty_score: 0.7)
      expect(host.cross_pollinate(seed_id_a: a[:seed_id], seed_id_b: b[:seed_id], engine: engine)[:success]).to be true
    end

    it 'returns success: false for missing seed A' do
      b = engine.plant(raw_material: %w[blue], domain: :aesthetic, novelty_score: 0.7)
      expect(host.cross_pollinate(seed_id_a: 'ghost', seed_id_b: b[:seed_id], engine: engine)[:success]).to be false
    end
  end

  describe '#adopt_concept' do
    it 'returns success: true for existing concept' do
      p   = plant_viable(engine)
      cid = engine.birth(seed_id: p[:seed_id], name: 'adoptable', definition: 'ready')[:concept_id]
      expect(host.adopt_concept(concept_id: cid, engine: engine)[:success]).to be true
    end

    it 'returns success: false for unknown concept' do
      expect(host.adopt_concept(concept_id: 'ghost', engine: engine)[:success]).to be false
    end
  end

  describe '#concept_fitness' do
    it 'returns fitness data for existing concept' do
      p      = plant_viable(engine)
      cid    = engine.birth(seed_id: p[:seed_id], name: 'fit', definition: 'tested')[:concept_id]
      result = host.concept_fitness(concept_id: cid, engine: engine)
      expect(result[:success]).to be true
      expect(result[:fitness_label]).to be_a(Symbol)
    end

    it 'returns success: false for unknown' do
      expect(host.concept_fitness(concept_id: 'ghost', engine: engine)[:success]).to be false
    end
  end

  describe '#novelty_landscape' do
    it 'always returns success: true' do
      expect(host.novelty_landscape(engine: engine)[:success]).to be true
    end

    it 'includes seeds and concepts arrays' do
      result = host.novelty_landscape(engine: engine)
      expect(result[:seeds]).to be_an(Array)
      expect(result[:concepts]).to be_an(Array)
    end
  end

  describe '#genesis_rate' do
    it 'returns success: true and numeric rate' do
      result = host.genesis_rate(engine: engine)
      expect(result[:success]).to be true
      expect(result[:rate]).to be_a(Float)
    end
  end

  describe '#most_adopted' do
    it 'returns success: true and nil when empty' do
      result = host.most_adopted(engine: engine)
      expect(result[:success]).to be true
      expect(result[:concept]).to be_nil
    end
  end

  describe '#orphan_concepts' do
    it 'returns empty orphan list with no concepts' do
      result = host.orphan_concepts(engine: engine)
      expect(result[:success]).to be true
      expect(result[:count]).to eq(0)
    end

    it 'counts orphans correctly after birth' do
      p = plant_viable(engine)
      engine.birth(seed_id: p[:seed_id], name: 'orphan', definition: 'alone')
      expect(host.orphan_concepts(engine: engine)[:count]).to eq(1)
    end
  end

  describe '#genesis_report' do
    it 'returns success: true with all expected keys' do
      result = host.genesis_report(engine: engine)
      expect(result[:success]).to be true
      %i[seeds concepts genesis_events genesis_rate orphan_count avg_seed_novelty domains_active].each do |k|
        expect(result).to have_key(k)
      end
    end
  end

  describe 'default_engine isolation' do
    it 'each host gets its own engine' do
      host_a = Object.new.extend(described_class)
      host_b = Object.new.extend(described_class)
      host_a.plant_seed(raw_material: %w[a], domain: :logical)
      expect(host_a.genesis_report[:seeds]).to eq(1)
      expect(host_b.genesis_report[:seeds]).to eq(0)
    end
  end
end
