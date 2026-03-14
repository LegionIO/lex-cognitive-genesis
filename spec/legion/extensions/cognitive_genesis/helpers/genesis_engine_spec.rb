# frozen_string_literal: true

RSpec.describe Legion::Extensions::CognitiveGenesis::Helpers::GenesisEngine do
  subject(:engine) { described_class.new }

  let(:consts) { Legion::Extensions::CognitiveGenesis::Helpers::Constants }

  def plant_viable(eng, domain: :abstract, novelty: 0.8)
    eng.plant(raw_material: %w[alpha beta gamma], domain: domain,
              germination_potential: 0.9, novelty_score: novelty, viability: 0.6)
  end

  describe '#initialize' do
    it 'starts with empty seeds' do
      expect(engine.seeds).to be_empty
    end

    it 'starts with empty concepts' do
      expect(engine.concepts).to be_empty
    end

    it 'starts with empty genesis_events' do
      expect(engine.genesis_events).to be_empty
    end
  end

  describe '#plant' do
    it 'plants a seed successfully' do
      result = engine.plant(raw_material: %w[one two], domain: :logical)
      expect(result[:planted]).to be true
      expect(result[:seed_id]).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'adds seed to seeds hash' do
      result = engine.plant(raw_material: %w[one two], domain: :logical)
      expect(engine.seeds).to have_key(result[:seed_id])
    end

    it 'respects MAX_SEEDS limit' do
      consts::MAX_SEEDS.times { |i| engine.plant(raw_material: ["m_#{i}"], domain: :abstract) }
      result = engine.plant(raw_material: %w[overflow], domain: :abstract)
      expect(result[:planted]).to be false
      expect(result[:reason]).to eq(:capacity_exceeded)
    end

    it 'defaults germination_potential to DEFAULT_GERMINATION' do
      result = engine.plant(raw_material: %w[a], domain: :spatial)
      expect(engine.seeds[result[:seed_id]].germination_potential).to eq(consts::DEFAULT_GERMINATION)
    end

    it 'includes seed hash in result' do
      result = engine.plant(raw_material: %w[a], domain: :emergent)
      expect(result[:seed]).to be_a(Hash)
      expect(result[:seed][:domain]).to eq(:emergent)
    end
  end

  describe '#germinate' do
    it 'returns not_found for unknown seed_id' do
      result = engine.germinate(seed_id: 'none')
      expect(result[:germinated]).to be false
      expect(result[:reason]).to eq(:not_found)
    end

    it 'boosts germination_potential by GERMINATION_BOOST' do
      planted = engine.plant(raw_material: %w[x], domain: :logical, germination_potential: 0.5)
      engine.germinate(seed_id: planted[:seed_id])
      expect(engine.seeds[planted[:seed_id]].germination_potential).to be_within(0.0001).of(0.6)
    end

    it 'accepts a custom boost' do
      planted = engine.plant(raw_material: %w[x], domain: :logical, germination_potential: 0.4)
      engine.germinate(seed_id: planted[:seed_id], boost: 0.2)
      expect(engine.seeds[planted[:seed_id]].germination_potential).to be_within(0.0001).of(0.6)
    end

    it 'clamps potential at 1.0' do
      planted = engine.plant(raw_material: %w[x], domain: :logical, germination_potential: 0.95)
      engine.germinate(seed_id: planted[:seed_id], boost: 0.2)
      expect(engine.seeds[planted[:seed_id]].germination_potential).to eq(1.0)
    end

    it 'returns label in result' do
      planted = engine.plant(raw_material: %w[x], domain: :logical, germination_potential: 0.3)
      result  = engine.germinate(seed_id: planted[:seed_id])
      expect(result[:label]).to be_a(Symbol)
    end

    it 'recomputes viability after boost' do
      planted = engine.plant(raw_material: %w[a b c d], domain: :logical, germination_potential: 0.3, novelty_score: 0.6)
      result  = engine.germinate(seed_id: planted[:seed_id])
      expect(result[:viability]).to be_a(Float)
    end
  end

  describe '#birth' do
    let(:viable_id) { plant_viable(engine)[:seed_id] }

    it 'births a concept from a ready seed' do
      result = engine.birth(seed_id: viable_id, name: 'meta awareness', definition: 'awareness of awareness')
      expect(result[:birthed]).to be true
      expect(result[:concept_id]).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'removes the seed after birth' do
      engine.birth(seed_id: viable_id, name: 'test', definition: 'test')
      expect(engine.seeds).not_to have_key(viable_id)
    end

    it 'adds concept to concepts hash' do
      result = engine.birth(seed_id: viable_id, name: 'born', definition: 'newly')
      expect(engine.concepts).to have_key(result[:concept_id])
    end

    it 'records a genesis event' do
      engine.birth(seed_id: viable_id, name: 'event', definition: 'recorded')
      expect(engine.genesis_events.size).to eq(1)
    end

    it 'genesis event contains correct data' do
      result = engine.birth(seed_id: viable_id, name: 'named', definition: 'desc')
      event  = engine.genesis_events.first
      expect(event[:concept_id]).to eq(result[:concept_id])
      expect(event[:name]).to eq('named')
      expect(event[:domain]).to eq(:abstract)
    end

    it 'returns not_found for unknown seed' do
      result = engine.birth(seed_id: 'ghost', name: 'x', definition: 'y')
      expect(result[:birthed]).to be false
      expect(result[:reason]).to eq(:not_found)
    end

    it 'returns not_viable when viability is low' do
      p = engine.plant(raw_material: %w[a], domain: :abstract, viability: 0.1, novelty_score: 0.9, germination_potential: 0.9)
      expect(engine.birth(seed_id: p[:seed_id], name: 'x', definition: 'y')[:reason]).to eq(:not_viable)
    end

    it 'returns not_novel when novelty is low' do
      p = engine.plant(raw_material: %w[a b c], domain: :abstract, viability: 0.6, novelty_score: 0.2, germination_potential: 0.9)
      expect(engine.birth(seed_id: p[:seed_id], name: 'x', definition: 'y')[:reason]).to eq(:not_novel)
    end

    it 'returns not_ready when germination is low' do
      p = engine.plant(raw_material: %w[a b c], domain: :abstract, viability: 0.6, novelty_score: 0.8, germination_potential: 0.5)
      expect(engine.birth(seed_id: p[:seed_id], name: 'x', definition: 'y')[:reason]).to eq(:not_ready)
    end

    it 'respects MAX_CONCEPTS limit' do
      consts::MAX_CONCEPTS.times do |i|
        sid = plant_viable(engine)[:seed_id]
        engine.birth(seed_id: sid, name: "c#{i}", definition: "d#{i}")
      end
      sid = plant_viable(engine)[:seed_id]
      expect(engine.birth(seed_id: sid, name: 'overflow', definition: 'x')[:reason]).to eq(:concept_capacity_exceeded)
    end
  end

  describe '#nurture' do
    it 'returns not_found for unknown concept' do
      expect(engine.nurture(concept_id: 'ghost')[:reason]).to eq(:not_found)
    end

    it 'increases maturity' do
      sid    = plant_viable(engine)[:seed_id]
      cid    = engine.birth(seed_id: sid, name: 'n', definition: 'd')[:concept_id]
      before = engine.concepts[cid].maturity
      engine.nurture(concept_id: cid)
      expect(engine.concepts[cid].maturity).to be > before
    end
  end

  describe '#prune' do
    it 'removes a seed and returns pruned: true' do
      p = engine.plant(raw_material: %w[x], domain: :logical)
      expect(engine.prune(seed_id: p[:seed_id])[:pruned]).to be true
      expect(engine.seeds).not_to have_key(p[:seed_id])
    end

    it 'returns not_found for unknown seed' do
      expect(engine.prune(seed_id: 'ghost')[:reason]).to eq(:not_found)
    end
  end

  describe '#cross_pollinate' do
    let(:a_id) { engine.plant(raw_material: %w[red circle], domain: :spatial, novelty_score: 0.6)[:seed_id] }
    let(:b_id) { engine.plant(raw_material: %w[blue triangle], domain: :aesthetic, novelty_score: 0.7)[:seed_id] }

    it 'creates a new seed' do
      result = engine.cross_pollinate(seed_id_a: a_id, seed_id_b: b_id)
      expect(result[:cross_pollinated]).to be true
      expect(result[:seed_id]).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'combines raw materials without duplicates' do
      result = engine.cross_pollinate(seed_id_a: a_id, seed_id_b: b_id)
      child  = engine.seeds[result[:seed_id]]
      expect(child.raw_material).to include('red', 'blue', 'circle', 'triangle')
    end

    it 'includes parent_seed_ids' do
      result = engine.cross_pollinate(seed_id_a: a_id, seed_id_b: b_id)
      expect(result[:parent_seed_ids]).to eq([a_id, b_id])
    end

    it 'returns seed_a_not_found for unknown A' do
      expect(engine.cross_pollinate(seed_id_a: 'ghost', seed_id_b: b_id)[:reason]).to eq(:seed_a_not_found)
    end

    it 'returns seed_b_not_found for unknown B' do
      expect(engine.cross_pollinate(seed_id_a: a_id, seed_id_b: 'ghost')[:reason]).to eq(:seed_b_not_found)
    end

    it 'child novelty is at least max parent novelty' do
      result = engine.cross_pollinate(seed_id_a: a_id, seed_id_b: b_id)
      expect(engine.seeds[result[:seed_id]].novelty_score).to be >= 0.7
    end
  end

  describe '#adopt_concept' do
    it 'increments count and updates utility' do
      sid    = plant_viable(engine)[:seed_id]
      cid    = engine.birth(seed_id: sid, name: 'adoptable', definition: 'ready')[:concept_id]
      result = engine.adopt_concept(concept_id: cid)
      expect(result[:adopted]).to be true
      expect(result[:adoption_count]).to eq(1)
    end

    it 'returns not_found for unknown concept' do
      expect(engine.adopt_concept(concept_id: 'ghost')[:adopted]).to be false
    end
  end

  describe '#concept_fitness' do
    it 'returns fitness data' do
      sid    = plant_viable(engine)[:seed_id]
      cid    = engine.birth(seed_id: sid, name: 'fit', definition: 'tested')[:concept_id]
      result = engine.concept_fitness(concept_id: cid)
      expect(result[:found]).to be true
      expect(result[:fitness_label]).to be_a(Symbol)
    end

    it 'returns found: false for unknown' do
      expect(engine.concept_fitness(concept_id: 'ghost')[:found]).to be false
    end
  end

  describe '#novelty_landscape' do
    it 'returns empty landscape initially' do
      landscape = engine.novelty_landscape
      expect(landscape[:seeds]).to be_empty
      expect(landscape[:concepts]).to be_empty
    end

    it 'includes seeds with novelty scores' do
      engine.plant(raw_material: %w[a], domain: :abstract, novelty_score: 0.6)
      expect(engine.novelty_landscape[:seeds].first[:score]).to eq(0.6)
    end

    it 'counts high_novelty_seeds' do
      engine.plant(raw_material: %w[a], domain: :abstract, novelty_score: 0.8)
      engine.plant(raw_material: %w[b], domain: :logical, novelty_score: 0.3)
      expect(engine.novelty_landscape[:high_novelty_seeds]).to eq(1)
    end
  end

  describe '#genesis_rate' do
    it 'returns 0.0 with no events' do
      result = engine.genesis_rate
      expect(result[:rate]).to eq(0.0)
      expect(result[:total_events]).to eq(0)
    end

    it 'returns positive rate after birthing' do
      sid = plant_viable(engine)[:seed_id]
      engine.birth(seed_id: sid, name: 'born', definition: 'just born')
      expect(engine.genesis_rate[:rate]).to be > 0.0
    end
  end

  describe '#most_adopted' do
    it 'returns nil with no concepts' do
      expect(engine.most_adopted).to be_nil
    end

    it 'returns concept with highest adoption' do
      sid_a = plant_viable(engine)[:seed_id]
      cid_a = engine.birth(seed_id: sid_a, name: 'popular', definition: 'widely used')[:concept_id]
      sid_b = plant_viable(engine)[:seed_id]
      engine.birth(seed_id: sid_b, name: 'obscure', definition: 'rarely used')
      engine.adopt_concept(concept_id: cid_a)
      engine.adopt_concept(concept_id: cid_a)
      expect(engine.most_adopted[:name]).to eq('popular')
    end
  end

  describe '#orphan_concepts' do
    it 'returns empty with no concepts' do
      expect(engine.orphan_concepts).to be_empty
    end

    it 'returns unadopted concepts' do
      sid = plant_viable(engine)[:seed_id]
      engine.birth(seed_id: sid, name: 'lonely', definition: 'never used')
      expect(engine.orphan_concepts.size).to eq(1)
    end

    it 'excludes adopted concepts' do
      sid = plant_viable(engine)[:seed_id]
      cid = engine.birth(seed_id: sid, name: 'adopted', definition: 'used')[:concept_id]
      engine.adopt_concept(concept_id: cid)
      expect(engine.orphan_concepts).to be_empty
    end
  end

  describe '#genesis_report' do
    it 'returns all expected keys' do
      report = engine.genesis_report
      %i[seeds concepts genesis_events genesis_rate orphan_count most_adopted
         avg_seed_novelty avg_concept_maturity domains_active].each do |key|
        expect(report).to have_key(key)
      end
    end

    it 'reflects current seed count' do
      engine.plant(raw_material: %w[x], domain: :abstract)
      expect(engine.genesis_report[:seeds]).to eq(1)
    end

    it 'includes domain tally' do
      engine.plant(raw_material: %w[a], domain: :abstract)
      engine.plant(raw_material: %w[b], domain: :abstract)
      engine.plant(raw_material: %w[c], domain: :logical)
      report = engine.genesis_report
      expect(report[:domains_active][:abstract]).to eq(2)
      expect(report[:domains_active][:logical]).to eq(1)
    end
  end
end
