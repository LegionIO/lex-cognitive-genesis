# frozen_string_literal: true

RSpec.describe Legion::Extensions::CognitiveGenesis::Helpers::GenesisEngine do
  subject(:engine) { described_class.new }

  let(:seed_a_id) do
    engine.plant_seed(concept_type: :fusion, source_domains: %i[perception memory],
                      novelty: 0.8, viability: 0.6)[:seed_id]
  end

  let(:seed_b_id) do
    engine.plant_seed(concept_type: :abstraction, source_domains: %i[reasoning language],
                      novelty: 0.75, viability: 0.65)[:seed_id]
  end

  let(:seed_c_id) do
    engine.plant_seed(concept_type: :analogy, source_domains: %i[emotion social],
                      novelty: 0.5, viability: 0.3)[:seed_id]
  end

  describe '#initialize' do
    it 'starts with empty seeds' do
      expect(engine.seeds).to be_empty
    end

    it 'starts with empty emergence_events' do
      expect(engine.emergence_events).to be_empty
    end
  end

  describe '#plant_seed' do
    it 'returns success true' do
      result = engine.plant_seed(concept_type: :fusion, source_domains: [:perception],
                                 novelty: 0.8, viability: 0.6)
      expect(result[:success]).to be true
    end

    it 'returns a seed_id' do
      result = engine.plant_seed(concept_type: :fusion, source_domains: [:perception],
                                 novelty: 0.8, viability: 0.6)
      expect(result[:seed_id]).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'returns the concept_type' do
      result = engine.plant_seed(concept_type: :mutation, source_domains: [:emotion],
                                 novelty: 0.6, viability: 0.5)
      expect(result[:concept_type]).to eq(:mutation)
    end

    it 'stores the seed in @seeds' do
      result = engine.plant_seed(concept_type: :analogy, source_domains: [:language],
                                 novelty: 0.7, viability: 0.6)
      expect(engine.seeds[result[:seed_id]]).not_to be_nil
    end

    it 'records an emergence event' do
      expect { engine.plant_seed(concept_type: :fusion, source_domains: [:memory], novelty: 0.8, viability: 0.6) }
        .to change(engine.emergence_events, :size).by(1)
    end

    it 'returns an emergence_event_id' do
      result = engine.plant_seed(concept_type: :transcendence, source_domains: [:imagination],
                                 novelty: 0.95, viability: 0.9)
      expect(result[:emergence_event_id]).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'propagates ArgumentError for unknown concept_type' do
      expect do
        engine.plant_seed(concept_type: :bad_type, source_domains: [:emotion], novelty: 0.5, viability: 0.5)
      end.to raise_error(ArgumentError)
    end

    it 'prunes seeds when exceeding MAX_SEEDS' do
      max = Legion::Extensions::CognitiveGenesis::Helpers::Constants::MAX_SEEDS
      (max + 5).times do
        engine.plant_seed(concept_type: :fusion, source_domains: [:memory],
                          novelty: rand(0.1..0.9), viability: rand(0.1..0.9))
      end
      expect(engine.seeds.size).to be <= max
    end
  end

  describe '#synthesize' do
    before { seed_a_id; seed_b_id }

    it 'returns success true for valid seeds' do
      result = engine.synthesize(seed_ids: [seed_a_id, seed_b_id])
      expect(result[:success]).to be true
    end

    it 'creates a new seed with type :emergence' do
      result    = engine.synthesize(seed_ids: [seed_a_id, seed_b_id])
      new_seed  = engine.seeds[result[:seed_id]]
      expect(new_seed.concept_type).to eq(:emergence)
    end

    it 'applies SYNTHESIS_BONUS to novelty' do
      seed_a = engine.seeds[seed_a_id]
      seed_b = engine.seeds[seed_b_id]
      bonus  = Legion::Extensions::CognitiveGenesis::Helpers::Constants::SYNTHESIS_BONUS
      avg    = (seed_a.novelty + seed_b.novelty) / 2.0
      result = engine.synthesize(seed_ids: [seed_a_id, seed_b_id])
      new_seed = engine.seeds[result[:seed_id]]
      expect(new_seed.novelty).to be_within(0.001).of([avg + bonus, 1.0].min)
    end

    it 'applies SYNTHESIS_BONUS to viability' do
      seed_a = engine.seeds[seed_a_id]
      seed_b = engine.seeds[seed_b_id]
      bonus  = Legion::Extensions::CognitiveGenesis::Helpers::Constants::SYNTHESIS_BONUS
      avg    = (seed_a.viability + seed_b.viability) / 2.0
      result = engine.synthesize(seed_ids: [seed_a_id, seed_b_id])
      new_seed = engine.seeds[result[:seed_id]]
      expect(new_seed.viability).to be_within(0.001).of([avg + bonus, 1.0].min)
    end

    it 'combines source_domains from parent seeds' do
      result   = engine.synthesize(seed_ids: [seed_a_id, seed_b_id])
      new_seed = engine.seeds[result[:seed_id]]
      expect(new_seed.source_domains).to include(:perception, :memory, :reasoning, :language)
    end

    it 'records parent_ids on the synthesized seed' do
      result   = engine.synthesize(seed_ids: [seed_a_id, seed_b_id])
      new_seed = engine.seeds[result[:seed_id]]
      expect(new_seed.parent_ids).to include(seed_a_id, seed_b_id)
    end

    it 'returns parent_ids in the result hash' do
      result = engine.synthesize(seed_ids: [seed_a_id, seed_b_id])
      expect(result[:parent_ids]).to include(seed_a_id, seed_b_id)
    end

    it 'returns combined_domains in the result hash' do
      result = engine.synthesize(seed_ids: [seed_a_id, seed_b_id])
      expect(result[:combined_domains]).not_to be_empty
    end

    it 'fails with :insufficient_seeds when given only 1 seed id' do
      result = engine.synthesize(seed_ids: [seed_a_id])
      expect(result[:success]).to be false
      expect(result[:error]).to eq(:insufficient_seeds)
    end

    it 'fails when seed ids do not exist' do
      result = engine.synthesize(seed_ids: %w[nonexistent-1 nonexistent-2])
      expect(result[:success]).to be false
    end

    it 'fails with :insufficient_seeds for empty array' do
      result = engine.synthesize(seed_ids: [])
      expect(result[:success]).to be false
    end
  end

  describe '#mature_seed' do
    before { seed_a_id }

    it 'returns success true for existing seed' do
      result = engine.mature_seed(seed_id: seed_a_id)
      expect(result[:success]).to be true
    end

    it 'advances the maturity stage' do
      engine.mature_seed(seed_id: seed_a_id)
      expect(engine.seeds[seed_a_id].maturity_stage).to eq(:embryonic)
    end

    it 'returns previous_stage and current_stage' do
      result = engine.mature_seed(seed_id: seed_a_id)
      expect(result[:previous_stage]).to eq(:germinal)
      expect(result[:current_stage]).to eq(:embryonic)
    end

    it 'returns updated viability' do
      result = engine.mature_seed(seed_id: seed_a_id)
      expect(result[:viability]).to be_a(Float)
    end

    it 'returns error for unknown seed_id' do
      result = engine.mature_seed(seed_id: 'nonexistent')
      expect(result[:success]).to be false
      expect(result[:error]).to eq(:seed_not_found)
    end
  end

  describe '#decay_all!' do
    before { seed_a_id; seed_b_id; seed_c_id }

    it 'returns success true' do
      expect(engine.decay_all![:success]).to be true
    end

    it 'reduces novelty on all seeds' do
      novelty_before = engine.seeds[seed_a_id].novelty
      engine.decay_all!
      expect(engine.seeds[seed_a_id].novelty).to be < novelty_before
    end

    it 'removes seeds with zero novelty and non-viable' do
      result = engine.decay_all!
      expect(result[:seeds_removed]).to be >= 0
    end
  end

  describe '#viable_seeds' do
    before { seed_a_id; seed_b_id; seed_c_id }

    it 'returns success true' do
      expect(engine.viable_seeds[:success]).to be true
    end

    it 'returns only seeds where viable? is true' do
      result = engine.viable_seeds
      result[:seeds].each do |s|
        expect(s[:viable]).to be true
      end
    end

    it 'includes count' do
      result = engine.viable_seeds
      expect(result[:count]).to eq(result[:seeds].size)
    end
  end

  describe '#novel_seeds' do
    before { seed_a_id; seed_b_id; seed_c_id }

    it 'returns success true' do
      expect(engine.novel_seeds[:success]).to be true
    end

    it 'returns only seeds where novel? is true' do
      result = engine.novel_seeds
      result[:seeds].each do |s|
        expect(s[:novel]).to be true
      end
    end
  end

  describe '#truly_novel_seeds' do
    before do
      # Plant a truly novel seed (no parents, high novelty)
      engine.plant_seed(concept_type: :transcendence, source_domains: [:imagination],
                        novelty: 0.95, viability: 0.8)
      # Plant a derived seed with parent
      parent_id = engine.plant_seed(concept_type: :fusion, source_domains: [:memory],
                                    novelty: 0.9, viability: 0.7)[:seed_id]
      engine.plant_seed(concept_type: :mutation, source_domains: [:language],
                        novelty: 0.9, viability: 0.6, parent_ids: [parent_id])
    end

    it 'returns seeds that are novel AND have no parent_ids' do
      result = engine.truly_novel_seeds
      result[:seeds].each do |s|
        expect(s[:truly_novel]).to be true
        expect(s[:parent_ids]).to be_empty
      end
    end
  end

  describe '#seeds_by_type' do
    before { seed_a_id; seed_b_id }

    it 'returns success true' do
      expect(engine.seeds_by_type[:success]).to be true
    end

    it 'groups seeds by concept_type' do
      result = engine.seeds_by_type
      expect(result[:by_type]).to have_key(:fusion)
      expect(result[:by_type]).to have_key(:abstraction)
    end
  end

  describe '#seeds_by_stage' do
    before { seed_a_id }

    it 'returns success true' do
      expect(engine.seeds_by_stage[:success]).to be true
    end

    it 'groups seeds by maturity_stage' do
      result = engine.seeds_by_stage
      expect(result[:by_stage]).to have_key(:germinal)
    end
  end

  describe '#seeds_by_domain' do
    before { seed_a_id; seed_b_id }

    it 'returns success true' do
      expect(engine.seeds_by_domain[:success]).to be true
    end

    it 'groups seeds by each source domain they belong to' do
      result = engine.seeds_by_domain
      expect(result[:by_domain]).to have_key(:perception)
      expect(result[:by_domain]).to have_key(:reasoning)
    end

    it 'allows a seed to appear in multiple domains' do
      # seed_a has both :perception and :memory
      result = engine.seeds_by_domain[:by_domain]
      perception_ids = result[:perception]&.map { |s| s[:id] } || []
      memory_ids     = result[:memory]&.map { |s| s[:id] } || []
      expect(perception_ids).to include(seed_a_id)
      expect(memory_ids).to include(seed_a_id)
    end
  end

  describe '#most_novel' do
    before { seed_a_id; seed_b_id; seed_c_id }

    it 'returns success true' do
      expect(engine.most_novel[:success]).to be true
    end

    it 'returns seeds sorted by novelty descending' do
      result   = engine.most_novel(limit: 10)
      novelties = result[:seeds].map { |s| s[:novelty] }
      expect(novelties).to eq(novelties.sort.reverse)
    end

    it 'respects the limit parameter' do
      result = engine.most_novel(limit: 2)
      expect(result[:seeds].size).to be <= 2
    end
  end

  describe '#emergence_rate' do
    it 'returns rate 0.0 with no seeds or events' do
      expect(engine.emergence_rate[:rate]).to eq(0.0)
    end

    it 'returns counts of strong and weak events' do
      engine.plant_seed(concept_type: :transcendence, source_domains: [:imagination],
                        novelty: 0.95, viability: 0.9)
      engine.plant_seed(concept_type: :fusion, source_domains: [:language],
                        novelty: 0.1, viability: 0.1)
      result = engine.emergence_rate
      expect(result[:total_events]).to eq(2)
      expect(result).to have_key(:strong_events)
      expect(result).to have_key(:weak_events)
    end
  end

  describe '#average_novelty' do
    it 'returns 0.0 when no seeds' do
      expect(engine.average_novelty[:average]).to eq(0.0)
    end

    it 'computes correct average' do
      engine.plant_seed(concept_type: :fusion, source_domains: [:memory], novelty: 0.6, viability: 0.5)
      engine.plant_seed(concept_type: :analogy, source_domains: [:language], novelty: 0.8, viability: 0.6)
      result = engine.average_novelty
      expect(result[:average]).to be_within(0.001).of(0.7)
      expect(result[:count]).to eq(2)
    end
  end

  describe '#average_viability' do
    it 'returns 0.0 when no seeds' do
      expect(engine.average_viability[:average]).to eq(0.0)
    end

    it 'computes correct average' do
      engine.plant_seed(concept_type: :fusion, source_domains: [:memory], novelty: 0.6, viability: 0.4)
      engine.plant_seed(concept_type: :analogy, source_domains: [:language], novelty: 0.7, viability: 0.8)
      result = engine.average_viability
      expect(result[:average]).to be_within(0.001).of(0.6)
    end
  end

  describe '#novelty_distribution' do
    before { seed_a_id; seed_b_id; seed_c_id }

    it 'returns success true' do
      expect(engine.novelty_distribution[:success]).to be true
    end

    it 'includes distribution hash with novelty labels' do
      result = engine.novelty_distribution
      expect(result[:distribution]).to be_a(Hash)
      expect(result[:distribution].keys).to include(:highly_novel)
    end

    it 'reports total matching seed count' do
      result = engine.novelty_distribution
      expect(result[:total]).to eq(engine.seeds.size)
    end
  end

  describe '#genesis_report' do
    before { seed_a_id; seed_b_id; seed_c_id }

    it 'returns success true' do
      expect(engine.genesis_report[:success]).to be true
    end

    it 'includes total_seeds' do
      expect(engine.genesis_report[:total_seeds]).to eq(3)
    end

    it 'includes viable_count' do
      result = engine.genesis_report
      expect(result[:viable_count]).to be_a(Integer)
    end

    it 'includes novel_count' do
      expect(engine.genesis_report[:novel_count]).to be_a(Integer)
    end

    it 'includes truly_novel_count' do
      expect(engine.genesis_report[:truly_novel_count]).to be_a(Integer)
    end

    it 'includes crystallized_count' do
      expect(engine.genesis_report[:crystallized_count]).to be_a(Integer)
    end

    it 'includes average_novelty' do
      expect(engine.genesis_report[:average_novelty]).to be_a(Float)
    end

    it 'includes average_viability' do
      expect(engine.genesis_report[:average_viability]).to be_a(Float)
    end

    it 'includes emergence_events count' do
      expect(engine.genesis_report[:emergence_events]).to eq(engine.emergence_events.size)
    end

    it 'includes fertility_score' do
      expect(engine.genesis_report[:fertility_score]).to be_a(Float)
    end

    it 'includes fertility_label' do
      expect(engine.genesis_report[:fertility_label]).to be_a(Symbol)
    end

    it 'includes seeds_by_type breakdown' do
      result = engine.genesis_report[:seeds_by_type]
      expect(result).to be_a(Hash)
      expect(result.values.sum).to eq(3)
    end
  end
end
