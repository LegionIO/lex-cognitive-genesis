# frozen_string_literal: true

module Legion
  module Extensions
    module CognitiveGenesis
      module Runners
        module Genesis
          def plant_seed(raw_material:, domain:, engine: nil,
                         germination_potential: Helpers::Constants::DEFAULT_GERMINATION,
                         novelty_score: 0.0, viability: 0.0, **)
            e      = engine || default_engine
            result = e.plant(raw_material: raw_material, domain: domain,
                             germination_potential: germination_potential,
                             novelty_score: novelty_score, viability: viability)
            { success: result[:planted], **result }
          end

          def germinate_seed(seed_id:, engine: nil, boost: Helpers::Constants::GERMINATION_BOOST, **)
            e      = engine || default_engine
            result = e.germinate(seed_id: seed_id, boost: boost)
            { success: result[:germinated], **result }
          end

          def birth_concept(seed_id:, name:, definition:, engine: nil, **)
            e      = engine || default_engine
            result = e.birth(seed_id: seed_id, name: name, definition: definition)
            { success: result[:birthed], **result }
          end

          def nurture_concept(concept_id:, engine: nil, boost: Helpers::Constants::MATURITY_BOOST, **)
            e      = engine || default_engine
            result = e.nurture(concept_id: concept_id, boost: boost)
            { success: result[:nurtured], **result }
          end

          def prune_seed(seed_id:, engine: nil, **)
            e      = engine || default_engine
            result = e.prune(seed_id: seed_id)
            { success: result[:pruned], **result }
          end

          def cross_pollinate(seed_id_a:, seed_id_b:, engine: nil, **)
            e      = engine || default_engine
            result = e.cross_pollinate(seed_id_a: seed_id_a, seed_id_b: seed_id_b)
            { success: result[:cross_pollinated], **result }
          end

          def adopt_concept(concept_id:, engine: nil, **)
            e      = engine || default_engine
            result = e.adopt_concept(concept_id: concept_id)
            { success: result[:adopted], **result }
          end

          def concept_fitness(concept_id:, engine: nil, **)
            e      = engine || default_engine
            result = e.concept_fitness(concept_id: concept_id)
            { success: result[:found], **result }
          end

          def novelty_landscape(engine: nil, **)
            e         = engine || default_engine
            landscape = e.novelty_landscape
            { success: true, **landscape }
          end

          def genesis_rate(engine: nil, **)
            e      = engine || default_engine
            result = e.genesis_rate
            { success: true, **result }
          end

          def most_adopted(engine: nil, **)
            e       = engine || default_engine
            concept = e.most_adopted
            { success: true, concept: concept }
          end

          def orphan_concepts(engine: nil, **)
            e       = engine || default_engine
            orphans = e.orphan_concepts
            { success: true, orphans: orphans, count: orphans.size }
          end

          def genesis_report(engine: nil, **)
            e      = engine || default_engine
            report = e.genesis_report
            { success: true, **report }
          end

          include Legion::Extensions::Helpers::Lex if defined?(Legion::Extensions::Helpers::Lex)

          private

          def default_engine
            @default_engine ||= Helpers::GenesisEngine.new
          end
        end
      end
    end
  end
end
