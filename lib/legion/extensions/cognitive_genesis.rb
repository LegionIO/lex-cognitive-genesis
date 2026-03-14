# frozen_string_literal: true

require 'securerandom'
require 'time'
require 'legion/extensions/cognitive_genesis/version'
require 'legion/extensions/cognitive_genesis/helpers/constants'
require 'legion/extensions/cognitive_genesis/helpers/concept_seed'
require 'legion/extensions/cognitive_genesis/helpers/emergence_event'
require 'legion/extensions/cognitive_genesis/helpers/genesis_engine'
require 'legion/extensions/cognitive_genesis/runners/cognitive_genesis'
require 'legion/extensions/cognitive_genesis/client'

module Legion
  module Extensions
    module CognitiveGenesis
      extend Legion::Extensions::Core if Legion::Extensions.const_defined? :Core
    end
  end
end
