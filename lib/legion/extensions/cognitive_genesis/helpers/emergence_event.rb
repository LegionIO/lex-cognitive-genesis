# frozen_string_literal: true

require 'securerandom'
require 'time'

module Legion
  module Extensions
    module CognitiveGenesis
      module Helpers
        class EmergenceEvent
          attr_reader :id, :concept_seed_id, :trigger_domains, :emergence_strength, :timestamp

          def initialize(concept_seed_id:, trigger_domains:, emergence_strength:)
            @id                 = SecureRandom.uuid
            @concept_seed_id    = concept_seed_id
            @trigger_domains    = Array(trigger_domains)
            @emergence_strength = emergence_strength.clamp(0.0, 1.0)
            @timestamp          = Time.now.utc
          end

          def strong?
            @emergence_strength > 0.7
          end

          def weak?
            @emergence_strength < 0.3
          end

          def moderate?
            !strong? && !weak?
          end

          def to_h
            {
              id:                 @id,
              concept_seed_id:    @concept_seed_id,
              trigger_domains:    @trigger_domains,
              emergence_strength: @emergence_strength.round(6),
              timestamp:          @timestamp.iso8601,
              strong:             strong?,
              weak:               weak?,
              moderate:           moderate?
            }
          end
        end
      end
    end
  end
end
