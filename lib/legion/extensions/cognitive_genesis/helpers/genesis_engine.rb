# frozen_string_literal: true

module Legion
  module Extensions
    module CognitiveGenesis
      module Helpers
        class GenesisEngine
          include Constants

          attr_reader :seeds, :emergence_events

          def initialize
            @seeds            = {}
            @emergence_events = []
          end

          def plant_seed(concept_type:, source_domains:, novelty: DEFAULT_NOVELTY,
                         viability: DEFAULT_NOVELTY, parent_ids: [], **)
            seed = ConceptSeed.new(
              concept_type:   concept_type,
              source_domains: source_domains,
              novelty:        novelty,
              viability:      viability,
              parent_ids:     parent_ids
            )

            @seeds[seed.id] = seed
            prune_seeds! if @seeds.size > MAX_SEEDS

            strength = (seed.novelty * 0.6 + seed.viability * 0.4).round(10)
            event    = record_emergence(seed: seed, trigger_domains: source_domains,
                                        emergence_strength: strength)

            Legion::Logging.debug "[cognitive_genesis] seed planted id=#{seed.id[0..7]} " \
                                  "type=#{concept_type} novelty=#{novelty.round(2)} " \
                                  "viability=#{viability.round(2)}"

            { success: true, seed_id: seed.id, concept_type: concept_type,
              emergence_event_id: event.id }
          end

          def synthesize(seed_ids:, **)
            seeds_to_combine = Array(seed_ids).map { |sid| @seeds[sid] }.compact

            if seeds_to_combine.size < 2
              Legion::Logging.debug '[cognitive_genesis] synthesize failed: need at least 2 seeds'
              return { success: false, error: :insufficient_seeds,
                       provided: seeds_to_combine.size, required: 2 }
            end

            combined_domains = seeds_to_combine.flat_map(&:source_domains).uniq
            base_novelty     = seeds_to_combine.sum(&:novelty).round(10) / seeds_to_combine.size
            base_viability   = seeds_to_combine.sum(&:viability).round(10) / seeds_to_combine.size
            synth_novelty    = (base_novelty + SYNTHESIS_BONUS).round(10).clamp(0.0, 1.0)
            synth_viability  = (base_viability + SYNTHESIS_BONUS).round(10).clamp(0.0, 1.0)
            parent_ids       = seeds_to_combine.map(&:id)

            result = plant_seed(
              concept_type:   :emergence,
              source_domains: combined_domains,
              novelty:        synth_novelty,
              viability:      synth_viability,
              parent_ids:     parent_ids
            )

            Legion::Logging.info "[cognitive_genesis] synthesis complete parent_count=#{parent_ids.size} " \
                                 "new_seed=#{result[:seed_id]&.slice(0, 7)} novelty=#{synth_novelty.round(2)}"

            result.merge(parent_ids: parent_ids, combined_domains: combined_domains)
          end

          def mature_seed(seed_id:, **)
            seed = @seeds[seed_id]
            return { success: false, error: :seed_not_found } unless seed

            prev_stage = seed.maturity_stage
            seed.mature!

            Legion::Logging.debug "[cognitive_genesis] seed matured id=#{seed_id[0..7]} " \
                                  "#{prev_stage} -> #{seed.maturity_stage} viability=#{seed.viability.round(2)}"

            { success: true, seed_id: seed_id,
              previous_stage: prev_stage, current_stage: seed.maturity_stage,
              viability: seed.viability.round(6) }
          end

          def decay_all!
            @seeds.each_value(&:decay!)
            before = @seeds.size
            @seeds.reject! { |_, s| s.novelty <= 0.0 && !s.viable? }
            removed = before - @seeds.size

            Legion::Logging.debug "[cognitive_genesis] decay_all! removed=#{removed} remaining=#{@seeds.size}"
            { success: true, seeds_decayed: @seeds.size, seeds_removed: removed }
          end

          def viable_seeds(**)
            result = @seeds.values.select(&:viable?)
            { success: true, seeds: result.map(&:to_h), count: result.size }
          end

          def novel_seeds(**)
            result = @seeds.values.select(&:novel?)
            { success: true, seeds: result.map(&:to_h), count: result.size }
          end

          def truly_novel_seeds(**)
            result = @seeds.values.select(&:truly_novel?)
            { success: true, seeds: result.map(&:to_h), count: result.size }
          end

          def seeds_by_type(**)
            grouped = @seeds.values.group_by(&:concept_type)
            { success: true, by_type: grouped.transform_values { |s| s.map(&:to_h) } }
          end

          def seeds_by_stage(**)
            grouped = @seeds.values.group_by(&:maturity_stage)
            { success: true, by_stage: grouped.transform_values { |s| s.map(&:to_h) } }
          end

          def seeds_by_domain(**)
            result = {}
            @seeds.each_value do |seed|
              seed.source_domains.each do |domain|
                result[domain] ||= []
                result[domain] << seed.to_h
              end
            end
            { success: true, by_domain: result }
          end

          def most_novel(limit: 10, **)
            top = @seeds.values.sort_by { |s| -s.novelty }.first(limit)
            { success: true, seeds: top.map(&:to_h), count: top.size }
          end

          def emergence_rate(**)
            total  = @emergence_events.size
            strong = @emergence_events.count(&:strong?)
            weak   = @emergence_events.count(&:weak?)
            rate   = @seeds.empty? ? 0.0 : (total.to_f / @seeds.size).round(10)
            { success: true, total_events: total, strong_events: strong,
              weak_events: weak, rate: rate.round(6) }
          end

          def average_novelty(**)
            return { success: true, average: 0.0, count: 0 } if @seeds.empty?

            avg = (@seeds.values.sum(&:novelty).round(10) / @seeds.size).round(10)
            { success: true, average: avg.round(6), count: @seeds.size }
          end

          def average_viability(**)
            return { success: true, average: 0.0, count: 0 } if @seeds.empty?

            avg = (@seeds.values.sum(&:viability).round(10) / @seeds.size).round(10)
            { success: true, average: avg.round(6), count: @seeds.size }
          end

          def novelty_distribution(**)
            dist = NOVELTY_LABELS.each_with_object({}) do |(range, label), acc|
              acc[label] = @seeds.values.count { |s| range.cover?(s.novelty) }
            end
            { success: true, distribution: dist, total: @seeds.size }
          end

          def genesis_report(**)
            avg_nov = @seeds.empty? ? 0.0 : (@seeds.values.sum(&:novelty).round(10) / @seeds.size).round(6)
            avg_via = @seeds.empty? ? 0.0 : (@seeds.values.sum(&:viability).round(10) / @seeds.size).round(6)
            fertile = (avg_nov * 0.5 + avg_via * 0.5).round(6)

            {
              success:            true,
              total_seeds:        @seeds.size,
              viable_count:       @seeds.values.count(&:viable?),
              novel_count:        @seeds.values.count(&:novel?),
              truly_novel_count:  @seeds.values.count(&:truly_novel?),
              crystallized_count: @seeds.values.count(&:crystallized?),
              average_novelty:    avg_nov,
              average_viability:  avg_via,
              emergence_events:   @emergence_events.size,
              fertility_score:    fertile,
              fertility_label:    fertility_label(fertile),
              seeds_by_type:      @seeds.values.group_by(&:concept_type).transform_values(&:size)
            }
          end

          private

          def fertility_label(score)
            Constants::FERTILITY_LABELS.find { |range, _| range.cover?(score) }&.last || :barren
          end

          def record_emergence(seed:, trigger_domains:, emergence_strength:)
            event = EmergenceEvent.new(
              concept_seed_id:    seed.id,
              trigger_domains:    trigger_domains,
              emergence_strength: emergence_strength
            )
            @emergence_events << event
            event
          end

          def prune_seeds!
            overflow = @seeds.size - MAX_SEEDS
            return if overflow <= 0

            ids_to_prune = @seeds.min_by(overflow) { |_, s| s.novelty }.map(&:first)
            ids_to_prune.each { |id| @seeds.delete(id) }
          end
        end
      end
    end
  end
end
