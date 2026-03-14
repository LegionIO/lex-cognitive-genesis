# frozen_string_literal: true

module Legion
  module Extensions
    module CognitiveGenesis
      module Helpers
        class GenesisEngine
          include Constants

          attr_reader :seeds, :concepts, :genesis_events

          def initialize
            @seeds          = {}
            @concepts       = {}
            @genesis_events = []
          end

          def plant(raw_material:, domain:, germination_potential: DEFAULT_GERMINATION,
                    novelty_score: 0.0, viability: 0.0, **)
            return { planted: false, reason: :capacity_exceeded } if @seeds.size >= MAX_SEEDS

            seed = Seed.new(
              raw_material:          raw_material,
              domain:                domain,
              germination_potential: germination_potential,
              novelty_score:         novelty_score,
              viability:             viability
            )
            @seeds[seed.seed_id] = seed
            Legion::Logging.debug "[cognitive_genesis] planted seed #{seed.seed_id[0..7]} " \
                                  "domain=#{domain} novelty=#{novelty_score.round(3)}"
            { planted: true, seed_id: seed.seed_id, seed: seed.to_h }
          end

          def germinate(seed_id:, boost: GERMINATION_BOOST, **)
            seed = @seeds[seed_id]
            return { germinated: false, reason: :not_found } unless seed

            seed.germination_potential = (seed.germination_potential + boost).clamp(0.0, 1.0).round(10)
            seed.viability             = compute_viability(seed)

            Legion::Logging.debug "[cognitive_genesis] germinated #{seed_id[0..7]} " \
                                  "potential=#{seed.germination_potential.round(3)}"
            { germinated: true, seed_id: seed_id,
              germination_potential: seed.germination_potential,
              viability:             seed.viability,
              label:                 seed.germination_label }
          end

          def birth(seed_id:, name:, definition:, **)
            seed = @seeds[seed_id]
            return { birthed: false, reason: :not_found } unless seed
            return { birthed: false, reason: :not_viable }  unless seed.viable?
            return { birthed: false, reason: :not_novel }   unless seed.novel?
            return { birthed: false, reason: :not_ready }   unless seed.ready_to_birth?
            return { birthed: false, reason: :concept_capacity_exceeded } if @concepts.size >= MAX_CONCEPTS

            concept = Concept.new(
              name:           name,
              definition:     definition,
              parent_seed_id: seed_id,
              domain:         seed.domain
            )
            @concepts[concept.concept_id] = concept
            @seeds.delete(seed_id)
            record_genesis_event(concept: concept, seed: seed)

            Legion::Logging.info "[cognitive_genesis] concept born: \"#{name}\" " \
                                 "(#{concept.concept_id[0..7]}) domain=#{seed.domain}"
            { birthed: true, concept_id: concept.concept_id, concept: concept.to_h }
          end

          def nurture(concept_id:, boost: MATURITY_BOOST, **)
            concept = @concepts[concept_id]
            return { nurtured: false, reason: :not_found } unless concept

            concept.nurture!(boost: boost)
            Legion::Logging.debug "[cognitive_genesis] nurtured #{concept_id[0..7]} " \
                                  "maturity=#{concept.maturity.round(3)}"
            { nurtured: true, concept_id: concept_id,
              maturity: concept.maturity, label: concept.maturity_label }
          end

          def prune(seed_id:, **)
            seed = @seeds.delete(seed_id)
            return { pruned: false, reason: :not_found } unless seed

            Legion::Logging.debug "[cognitive_genesis] pruned seed #{seed_id[0..7]}"
            { pruned: true, seed_id: seed_id }
          end

          def cross_pollinate(seed_id_a:, seed_id_b:, **)
            guard = cross_pollinate_guard(seed_id_a, seed_id_b)
            return guard if guard

            seed_a         = @seeds[seed_id_a]
            seed_b         = @seeds[seed_id_b]
            child_novelty  = cross_novelty(seed_a.novelty_score, seed_b.novelty_score)
            result         = plant_cross_child(seed_a, seed_b, child_novelty)

            Legion::Logging.debug '[cognitive_genesis] cross_pollinated ' \
                                  "#{seed_id_a[0..7]}+#{seed_id_b[0..7]} -> #{result[:seed_id]&.slice(0, 8)}"
            result.merge(cross_pollinated: true, parent_seed_ids: [seed_id_a, seed_id_b])
          end

          def adopt_concept(concept_id:, **)
            concept = @concepts[concept_id]
            return { adopted: false, reason: :not_found } unless concept

            concept.adopt!
            Legion::Logging.debug "[cognitive_genesis] adopted #{concept_id[0..7]} " \
                                  "count=#{concept.adoption_count}"
            { adopted: true, concept_id: concept_id,
              adoption_count: concept.adoption_count,
              utility_score:  concept.utility_score,
              maturity:       concept.maturity }
          end

          def concept_fitness(concept_id:, **)
            concept = @concepts[concept_id]
            return { found: false } unless concept

            { found:          true,
              concept_id:     concept_id,
              utility_score:  concept.utility_score,
              fitness_label:  concept.fitness_label,
              adoption_count: concept.adoption_count,
              maturity:       concept.maturity }
          end

          def novelty_landscape(**)
            seeds_map = @seeds.values.map do |s|
              { id: s.seed_id, type: :seed, score: s.novelty_score,
                label: s.novelty_label, domain: s.domain }
            end
            concepts_map = @concepts.values.map do |c|
              { id: c.concept_id, type: :concept, score: 0.0, label: :n_a, domain: c.domain }
            end
            {
              seeds:              seeds_map,
              concepts:           concepts_map,
              avg_seed_novelty:   avg_values(@seeds.values.map(&:novelty_score)),
              high_novelty_seeds: @seeds.values.count(&:novel?)
            }
          end

          def genesis_rate(**)
            return { rate: 0.0, total_events: 0 } if @genesis_events.empty?

            oldest        = @genesis_events.min_by { |e| e[:born_at] }[:born_at]
            elapsed_hours = [(Time.now.utc - oldest) / 3600.0, 1.0].max
            rate          = @genesis_events.size / elapsed_hours
            { rate:          rate.round(10),
              total_events:  @genesis_events.size,
              elapsed_hours: elapsed_hours.round(4) }
          end

          def most_adopted(**)
            return nil if @concepts.empty?

            @concepts.values.max_by(&:adoption_count)&.to_h
          end

          def orphan_concepts(**)
            @concepts.values.select(&:orphan?).map(&:to_h)
          end

          def genesis_report(**)
            {
              seeds:                @seeds.size,
              concepts:             @concepts.size,
              genesis_events:       @genesis_events.size,
              genesis_rate:         genesis_rate,
              orphan_count:         orphan_concepts.size,
              most_adopted:         most_adopted,
              avg_seed_novelty:     avg_values(@seeds.values.map(&:novelty_score)),
              avg_concept_maturity: avg_values(@concepts.values.map(&:maturity)),
              domains_active:       active_domains
            }
          end

          private

          def cross_pollinate_guard(seed_id_a, seed_id_b)
            return { cross_pollinated: false, reason: :seed_a_not_found } unless @seeds[seed_id_a]
            return { cross_pollinated: false, reason: :seed_b_not_found } unless @seeds[seed_id_b]
            return { cross_pollinated: false, reason: :capacity_exceeded } if @seeds.size >= MAX_SEEDS

            nil
          end

          def plant_cross_child(seed_a, seed_b, child_novelty)
            combined_viability = ((seed_a.viability + seed_b.viability) / 2.0).round(10)
            plant(
              raw_material:          (seed_a.raw_material + seed_b.raw_material).uniq,
              domain:                pick_domain(seed_a.domain, seed_b.domain, child_novelty),
              germination_potential: DEFAULT_GERMINATION + GERMINATION_BOOST,
              novelty_score:         child_novelty,
              viability:             combined_viability
            )
          end

          def compute_viability(seed)
            material_factor  = [seed.raw_material.size / 5.0, 1.0].min
            novelty_factor   = seed.novelty_score
            potential_factor = seed.germination_potential
            ((material_factor * 0.3) + (novelty_factor * 0.4) + (potential_factor * 0.3)).clamp(0.0, 1.0).round(10)
          end

          def cross_novelty(score_a, score_b)
            base    = [score_a, score_b].max
            synergy = (score_a - score_b).abs * 0.5
            (base + synergy + GERMINATION_BOOST).clamp(0.0, 1.0).round(10)
          end

          def pick_domain(domain_a, domain_b, novelty)
            return :emergent if novelty >= 0.8
            return domain_a  if domain_a == domain_b

            novelty >= 0.6 ? :abstract : domain_a
          end

          def avg_values(values)
            return 0.0 if values.empty?

            (values.sum / values.size.to_f).round(10)
          end

          def active_domains
            all_domains = @seeds.values.map(&:domain) + @concepts.values.map(&:domain)
            all_domains.tally
          end

          def record_genesis_event(concept:, seed:)
            @genesis_events << {
              concept_id: concept.concept_id,
              name:       concept.name,
              domain:     concept.domain,
              seed_id:    seed.seed_id,
              born_at:    concept.born_at
            }
          end
        end
      end
    end
  end
end
