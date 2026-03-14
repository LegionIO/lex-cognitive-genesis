# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module CognitiveGenesis
      module Helpers
        class Concept
          attr_reader   :concept_id, :name, :definition, :parent_seed_id, :domain, :born_at
          attr_accessor :maturity, :connections, :utility_score, :adoption_count

          def initialize(name:, definition:, parent_seed_id:, domain:,
                         maturity: 0.0, connections: [], utility_score: 0.0, adoption_count: 0)
            unless Constants::SEED_DOMAINS.include?(domain.to_sym)
              raise ArgumentError, "invalid domain: #{domain.inspect}; must be one of #{Constants::SEED_DOMAINS.inspect}"
            end

            @concept_id     = SecureRandom.uuid
            @name           = name.to_s.freeze
            @definition     = definition.to_s.freeze
            @parent_seed_id = parent_seed_id.to_s.freeze
            @domain         = domain.to_sym
            @maturity       = maturity.clamp(0.0, 1.0).round(10)
            @connections    = Array(connections).dup
            @utility_score  = utility_score.clamp(0.0, 1.0).round(10)
            @adoption_count = adoption_count.to_i
            @born_at        = Time.now.utc
          end

          def maturity_label
            Constants.label_for(Constants::MATURITY_LABELS, maturity)
          end

          def fitness_label
            Constants.label_for(Constants::FITNESS_LABELS, utility_score)
          end

          def adopt!
            @adoption_count += 1
            @utility_score   = (@utility_score + Constants::ADOPTION_BONUS).clamp(0.0, 1.0).round(10)
            @maturity        = (@maturity + Constants::MATURITY_BOOST).clamp(0.0, 1.0).round(10)
          end

          def nurture!(boost: Constants::MATURITY_BOOST)
            @maturity = (@maturity + boost).clamp(0.0, 1.0).round(10)
          end

          def decay!(rate: Constants::MATURITY_DECAY)
            @maturity = (@maturity - rate).clamp(0.0, 1.0).round(10)
          end

          def connect_to(concept_id)
            @connections << concept_id unless @connections.include?(concept_id)
          end

          def orphan?
            adoption_count.zero?
          end

          def to_h
            {
              concept_id:     concept_id,
              name:           name,
              definition:     definition,
              parent_seed_id: parent_seed_id,
              domain:         domain,
              maturity:       maturity,
              maturity_label: maturity_label,
              connections:    connections,
              utility_score:  utility_score,
              fitness_label:  fitness_label,
              adoption_count: adoption_count,
              orphan:         orphan?,
              born_at:        born_at
            }
          end
        end
      end
    end
  end
end
