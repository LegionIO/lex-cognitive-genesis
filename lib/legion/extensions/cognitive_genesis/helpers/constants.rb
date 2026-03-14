# frozen_string_literal: true

module Legion
  module Extensions
    module CognitiveGenesis
      module Helpers
        module Constants
          MAX_SEEDS           = 300
          MAX_CONCEPTS        = 200
          DEFAULT_NOVELTY     = 0.5
          NOVELTY_THRESHOLD   = 0.7
          VIABILITY_THRESHOLD = 0.4
          MATURATION_RATE     = 0.08
          NOVELTY_DECAY       = 0.02
          SYNTHESIS_BONUS     = 0.15

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

          NOVELTY_LABELS = {
            (0.9..)     => :transcendent,
            (0.7...0.9) => :highly_novel,
            (0.5...0.7) => :moderately_novel,
            (0.3...0.5) => :derivative,
            (..0.3)     => :conventional
          }.freeze

          VIABILITY_LABELS = {
            (0.8..)     => :strongly_viable,
            (0.6...0.8) => :viable,
            (0.4...0.6) => :marginal,
            (0.2...0.4) => :tenuous,
            (..0.2)     => :non_viable
          }.freeze

          FERTILITY_LABELS = {
            (0.8..)     => :prolific,
            (0.6...0.8) => :fertile,
            (0.4...0.6) => :moderate,
            (0.2...0.4) => :sparse,
            (..0.2)     => :barren
          }.freeze
        end
      end
    end
  end
end
