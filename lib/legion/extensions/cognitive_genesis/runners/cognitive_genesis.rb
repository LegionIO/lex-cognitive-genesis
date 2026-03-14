# frozen_string_literal: true

module Legion
  module Extensions
    module CognitiveGenesis
      module Runners
        module CognitiveGenesis
          include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers) &&
                                                      Legion::Extensions::Helpers.const_defined?(:Lex)

          def plant_seed(concept_type:, source_domains:,
                         novelty: Helpers::Constants::DEFAULT_NOVELTY,
                         viability: Helpers::Constants::DEFAULT_NOVELTY,
                         parent_ids: [], engine: nil, **)
            target = engine || genesis_engine
            Legion::Logging.debug "[cognitive_genesis] runner plant_seed type=#{concept_type}"
            target.plant_seed(
              concept_type:   concept_type,
              source_domains: source_domains,
              novelty:        novelty,
              viability:      viability,
              parent_ids:     parent_ids
            )
          end

          def synthesize(seed_ids:, engine: nil, **)
            target = engine || genesis_engine
            Legion::Logging.debug "[cognitive_genesis] runner synthesize seed_count=#{Array(seed_ids).size}"
            target.synthesize(seed_ids: seed_ids)
          end

          def mature_seed(seed_id:, engine: nil, **)
            target = engine || genesis_engine
            Legion::Logging.debug "[cognitive_genesis] runner mature_seed id=#{seed_id[0..7]}"
            target.mature_seed(seed_id: seed_id)
          end

          def list_seeds(engine: nil, **)
            target = engine || genesis_engine
            Legion::Logging.debug '[cognitive_genesis] runner list_seeds'
            report = target.genesis_report
            { success: true, seeds: target.seeds.values.map(&:to_h),
              count: target.seeds.size, summary: report }
          end

          def genesis_status(engine: nil, **)
            target = engine || genesis_engine
            Legion::Logging.debug '[cognitive_genesis] runner genesis_status'
            target.genesis_report
          end

          private

          def genesis_engine
            @genesis_engine ||= Helpers::GenesisEngine.new
          end
        end
      end
    end
  end
end
