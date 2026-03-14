# frozen_string_literal: true

RSpec.describe Legion::Extensions::CognitiveGenesis::Client do
  let(:engine) { Legion::Extensions::CognitiveGenesis::Helpers::GenesisEngine.new }
  let(:client) { described_class.new(engine: engine) }

  describe '#initialize' do
    it 'accepts injected engine' do
      expect(client.engine).to eq(engine)
    end

    it 'creates a default engine when none injected' do
      expect(described_class.new.engine).to be_a(Legion::Extensions::CognitiveGenesis::Helpers::GenesisEngine)
    end
  end

  describe 'runner method presence' do
    %i[
      plant_seed germinate_seed birth_concept nurture_concept prune_seed
      cross_pollinate adopt_concept concept_fitness novelty_landscape
      genesis_rate most_adopted orphan_concepts genesis_report
    ].each do |method|
      it "responds to ##{method}" do
        expect(client).to respond_to(method)
      end
    end
  end

  describe 'full lifecycle integration' do
    it 'plants, germinates, and births a concept end-to-end' do
      plant = client.plant_seed(raw_material: %w[awareness recursion boundary], domain: :abstract,
                                germination_potential: 0.6, novelty_score: 0.55, viability: 0.45)
      expect(plant[:success]).to be true
      sid = plant[:seed_id]

      # Germinate
      germ = client.germinate_seed(seed_id: sid, boost: 0.15)
      expect(germ[:success]).to be true

      # Push seed past all thresholds
      seed = engine.seeds[sid]
      seed.novelty_score         = 0.8
      seed.viability             = 0.6
      seed.germination_potential = 0.75

      birth = client.birth_concept(seed_id: sid, name: 'reflexive dissolution',
                                   definition: 'a boundary recognizing and dissolving itself')
      expect(birth[:success]).to be true
      cid = birth[:concept_id]

      client.nurture_concept(concept_id: cid)
      client.adopt_concept(concept_id: cid)
      client.adopt_concept(concept_id: cid)

      fitness = client.concept_fitness(concept_id: cid)
      expect(fitness[:adoption_count]).to eq(2)
      expect(fitness[:utility_score]).to be > 0.0

      report = client.genesis_report
      expect(report[:concepts]).to eq(1)
      expect(report[:genesis_events]).to eq(1)
      expect(report[:orphan_count]).to eq(0)
    end

    it 'cross-pollinates two seeds to form a more novel child' do
      client.plant_seed(raw_material: %w[signal noise], domain: :emergent, novelty_score: 0.55)
      client.plant_seed(raw_material: %w[pattern chaos], domain: :abstract, novelty_score: 0.65)
      seeds  = engine.seeds.values
      result = client.cross_pollinate(seed_id_a: seeds[0].seed_id, seed_id_b: seeds[1].seed_id)
      expect(result[:success]).to be true
      child = engine.seeds[result[:seed_id]]
      expect(child.novelty_score).to be >= 0.65
      expect(child.raw_material).to include('signal', 'noise', 'pattern', 'chaos')
    end

    it 'tracks orphan concepts correctly' do
      s = engine.plant(raw_material: %w[a b c], domain: :abstract,
                       germination_potential: 0.9, novelty_score: 0.8, viability: 0.6)
      engine.birth(seed_id: s[:seed_id], name: 'orphan', definition: 'never used')
      orphans = client.orphan_concepts
      expect(orphans[:count]).to eq(1)
    end

    it 'novelty landscape reflects planted seeds' do
      client.plant_seed(raw_material: %w[x y z], domain: :logical, novelty_score: 0.73)
      landscape = client.novelty_landscape
      expect(landscape[:seeds].size).to eq(1)
      expect(landscape[:seeds].first[:score]).to eq(0.73)
    end

    it 'genesis_rate increases with each birth' do
      s = engine.plant(raw_material: %w[q r s], domain: :abstract,
                       germination_potential: 0.9, novelty_score: 0.8, viability: 0.6)
      engine.birth(seed_id: s[:seed_id], name: 'rate test', definition: 'checking rate')
      rate = client.genesis_rate
      expect(rate[:total_events]).to eq(1)
      expect(rate[:rate]).to be > 0.0
    end

    it 'most_adopted returns concept with highest count' do
      s1   = engine.plant(raw_material: %w[a], domain: :abstract, germination_potential: 0.9, novelty_score: 0.8, viability: 0.6)
      cid1 = engine.birth(seed_id: s1[:seed_id], name: 'popular concept', definition: 'used often')[:concept_id]
      s2   = engine.plant(raw_material: %w[b], domain: :abstract, germination_potential: 0.9, novelty_score: 0.8, viability: 0.6)
      engine.birth(seed_id: s2[:seed_id], name: 'unknown concept', definition: 'never used')
      client.adopt_concept(concept_id: cid1)
      client.adopt_concept(concept_id: cid1)
      expect(client.most_adopted[:concept][:name]).to eq('popular concept')
    end
  end
end
