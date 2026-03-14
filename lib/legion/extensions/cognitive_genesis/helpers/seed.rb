# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module CognitiveGenesis
      module Helpers
        class Seed
          attr_reader   :seed_id, :raw_material, :domain, :created_at
          attr_accessor :germination_potential, :novelty_score, :viability

          def initialize(raw_material:, domain:, germination_potential: Constants::DEFAULT_GERMINATION,
                         novelty_score: 0.0, viability: 0.0)
            unless Constants::SEED_DOMAINS.include?(domain.to_sym)
              raise ArgumentError, "invalid domain: #{domain.inspect}; must be one of #{Constants::SEED_DOMAINS.inspect}"
            end

            @seed_id              = SecureRandom.uuid
            @raw_material         = Array(raw_material).freeze
            @domain               = domain.to_sym
            @germination_potential = germination_potential.clamp(0.0, 1.0).round(10)
            @novelty_score        = novelty_score.clamp(0.0, 1.0).round(10)
            @viability            = viability.clamp(0.0, 1.0).round(10)
            @created_at           = Time.now.utc
          end

          def germination_label
            Constants.label_for(Constants::GERMINATION_LABELS, germination_potential)
          end

          def novelty_label
            Constants.label_for(Constants::NOVELTY_LABELS, novelty_score)
          end

          def viable?
            viability >= Constants::VIABILITY_THRESHOLD
          end

          def novel?
            novelty_score >= Constants::NOVELTY_THRESHOLD
          end

          def ready_to_birth?
            germination_potential >= Constants::GERMINATION_THRESHOLD && viable? && novel?
          end

          def to_h
            {
              seed_id:               seed_id,
              raw_material:          raw_material,
              domain:                domain,
              germination_potential: germination_potential,
              novelty_score:         novelty_score,
              viability:             viability,
              germination_label:     germination_label,
              novelty_label:         novelty_label,
              ready_to_birth:        ready_to_birth?,
              created_at:            created_at
            }
          end
        end
      end
    end
  end
end
