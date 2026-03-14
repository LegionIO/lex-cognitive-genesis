# frozen_string_literal: true

require 'legion/extensions/cognitive_genesis/helpers/constants'
require 'legion/extensions/cognitive_genesis/helpers/concept_seed'
require 'legion/extensions/cognitive_genesis/helpers/emergence_event'
require 'legion/extensions/cognitive_genesis/helpers/genesis_engine'
require 'legion/extensions/cognitive_genesis/runners/cognitive_genesis'

module Legion
  module Extensions
    module CognitiveGenesis
      class Client
        include Runners::CognitiveGenesis

        def initialize(engine: nil, **)
          @genesis_engine = engine || Helpers::GenesisEngine.new
        end

        private

        attr_reader :genesis_engine
      end
    end
  end
end
