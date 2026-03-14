# lex-cognitive-genesis

Cognitive concept emergence engine for brain-modeled agentic AI in the LegionIO ecosystem.

## What It Does

Models how new cognitive concepts emerge from raw seeds. Seeds are planted with a germination potential; once potential exceeds the threshold (0.7), germination produces a concept candidate. That candidate only achieves full birth if it simultaneously passes viability (fitness >= 0.4) and novelty (>= 0.5) checks. Born concepts can be nurtured to increase fitness, cross-pollinated to produce hybrid seeds, or pruned. External concepts can be adopted directly. The engine tracks novelty distribution across domains and genesis rate over time.

## Usage

```ruby
require 'legion/extensions/cognitive_genesis'

client = Legion::Extensions::CognitiveGenesis::Client.new

# Plant a seed
result = client.plant_seed(domain: :engineering, source: :experience, content: 'fault-tolerant retry pattern', potential: 0.8)
seed_id = result[:seed_id]

# Germinate when potential is sufficient
germination = client.germinate_seed(seed_id: seed_id)
# => { success: true, concept: { fitness: 0.5, novelty: 0.6, ... } }

# Birth the concept if viable and novel
concept = client.birth_concept(seed_id: seed_id)
# => { success: true, concept_id: "...", concept: { ... } }

# Nurture to increase fitness
client.nurture_concept(concept_id: concept[:concept_id], amount: 0.15)

# Check novelty across domains
client.novelty_landscape
# => { success: true, landscape: { engineering: 0.6, ... } }

# Full genesis report
client.genesis_report
# => { success: true, report: { seed_count: 0, concept_count: 1, genesis_rate: 0.1, ... } }
```

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
