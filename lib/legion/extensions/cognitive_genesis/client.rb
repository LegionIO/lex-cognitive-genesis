# frozen_string_literal: true

module Legion
  module Extensions
    module CognitiveGenesis
      class Client
        include Runners::Genesis

        attr_reader :engine

        def initialize(engine: nil, **)
          @engine = engine || Helpers::GenesisEngine.new
        end

        private

        def default_engine
          @engine
        end
      end
    end
  end
end
