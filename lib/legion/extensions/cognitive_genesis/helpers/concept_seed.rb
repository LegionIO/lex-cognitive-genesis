# frozen_string_literal: true

require 'securerandom'
require 'time'

module Legion
  module Extensions
    module CognitiveGenesis
      module Helpers
        class ConceptSeed
          include Constants

          attr_reader :id, :concept_type, :source_domains, :novelty, :viability,
                      :maturity_stage, :parent_ids, :created_at

          def initialize(concept_type:, source_domains:, novelty: DEFAULT_NOVELTY,
                         viability: DEFAULT_NOVELTY, parent_ids: [], **)
            unless CONCEPT_TYPES.include?(concept_type)
              raise ArgumentError, "unknown concept_type: #{concept_type.inspect}; " \
                                   "must be one of #{CONCEPT_TYPES.inspect}"
            end

            @id             = SecureRandom.uuid
            @concept_type   = concept_type
            @source_domains = Array(source_domains)
            @novelty        = novelty.clamp(0.0, 1.0)
            @viability      = viability.clamp(0.0, 1.0)
            @maturity_stage = :germinal
            @parent_ids     = Array(parent_ids)
            @created_at     = Time.now.utc
          end

          def mature!
            current_index   = MATURITY_STAGES.index(@maturity_stage) || 0
            next_index      = [current_index + 1, MATURITY_STAGES.size - 1].min
            @maturity_stage = MATURITY_STAGES[next_index]
            @viability      = (@viability + MATURATION_RATE).round(10).clamp(0.0, 1.0)
            self
          end

          def decay!
            @novelty = (@novelty - NOVELTY_DECAY).round(10).clamp(0.0, 1.0)
            self
          end

          def viable?
            @viability > VIABILITY_THRESHOLD
          end

          def novel?
            @novelty > NOVELTY_THRESHOLD
          end

          def truly_novel?
            novel? && @parent_ids.empty?
          end

          def crystallized?
            @maturity_stage == :crystallized
          end

          def germinal?
            @maturity_stage == :germinal
          end

          def novelty_label
            NOVELTY_LABELS.find { |range, _| range.cover?(@novelty) }&.last || :conventional
          end

          def viability_label
            VIABILITY_LABELS.find { |range, _| range.cover?(@viability) }&.last || :non_viable
          end

          def to_h
            {
              id:              @id,
              concept_type:    @concept_type,
              source_domains:  @source_domains,
              novelty:         @novelty.round(6),
              viability:       @viability.round(6),
              maturity_stage:  @maturity_stage,
              parent_ids:      @parent_ids,
              created_at:      @created_at.iso8601,
              novel:           novel?,
              viable:          viable?,
              truly_novel:     truly_novel?,
              crystallized:    crystallized?,
              novelty_label:   novelty_label,
              viability_label: viability_label
            }
          end
        end
      end
    end
  end
end
