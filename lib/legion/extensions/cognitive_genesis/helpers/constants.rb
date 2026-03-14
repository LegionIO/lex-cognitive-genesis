# frozen_string_literal: true

module Legion
  module Extensions
    module CognitiveGenesis
      module Helpers
        module Constants
          MAX_SEEDS    = 200
          MAX_CONCEPTS = 100

          DEFAULT_GERMINATION   = 0.3
          GERMINATION_BOOST     = 0.1
          GERMINATION_THRESHOLD = 0.7

          DEFAULT_NOVELTY     = 0.5
          NOVELTY_THRESHOLD   = 0.5
          VIABILITY_THRESHOLD = 0.4

          MATURATION_RATE = 0.08
          NOVELTY_DECAY   = 0.02
          SYNTHESIS_BONUS = 0.15
          MATURITY_BOOST  = 0.08
          MATURITY_DECAY  = 0.02
          ADOPTION_BONUS  = 0.05

          CONCEPT_TYPES = %i[
            fusion
            abstraction
            analogy
            inversion
            extrapolation
            mutation
            emergence
            transcendence
          ].freeze

          SOURCE_DOMAINS = %i[
            perception
            memory
            language
            reasoning
            emotion
            social
            embodiment
            imagination
          ].freeze

          MATURITY_STAGES = %i[
            germinal
            embryonic
            nascent
            developing
            viable
            mature
            crystallized
          ].freeze

          SEED_DOMAINS = %i[
            linguistic
            spatial
            logical
            interpersonal
            aesthetic
            procedural
            abstract
            emergent
          ].freeze

          GERMINATION_LABELS = {
            (0.0...0.2) => :dormant,
            (0.2...0.4) => :stirring,
            (0.4...0.6) => :awakening,
            (0.6...0.8) => :developing,
            (0.8..1.0)  => :ready
          }.freeze

          NOVELTY_LABELS = {
            (0.0...0.2) => :derivative,
            (0.2...0.4) => :recombinant,
            (0.4..0.6)  => :emergent,
            (0.6...0.8) => :novel,
            (0.8..1.0)  => :unprecedented
          }.freeze

          MATURITY_LABELS = {
            (0.0...0.2) => :nascent,
            (0.2...0.4) => :fragile,
            (0.4...0.6) => :establishing,
            (0.6...0.8) => :stable,
            (0.8..1.0)  => :foundational
          }.freeze

          FITNESS_LABELS = {
            (0.0...0.2) => :untested,
            (0.2...0.4) => :experimental,
            (0.4...0.6) => :promising,
            (0.6...0.8) => :proven,
            (0.8..1.0)  => :essential
          }.freeze

          VIABILITY_LABELS = {
            (0.8..1.0)  => :strongly_viable,
            (0.6...0.8) => :viable,
            (0.4...0.6) => :marginal,
            (0.2...0.4) => :tenuous,
            (0.0...0.2) => :non_viable
          }.freeze

          FERTILITY_LABELS = {
            (0.8..1.0)  => :prolific,
            (0.6...0.8) => :fertile,
            (0.4...0.6) => :moderate,
            (0.2...0.4) => :sparse,
            (0.0...0.2) => :barren
          }.freeze

          def self.label_for(labels_hash, value)
            clamped = value.clamp(0.0, 1.0)
            labels_hash.each do |range, label|
              return label if range.cover?(clamped)
            end
            labels_hash.values.last
          end
        end
      end
    end
  end
end
