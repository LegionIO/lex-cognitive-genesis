# lex-cognitive-genesis

**Level 3 Leaf Documentation**
- **Parent**: `/Users/miverso2/rubymine/legion/extensions-agentic/CLAUDE.md`
- **Gem**: `lex-cognitive-genesis`

## Purpose

Models the emergence of new cognitive concepts from seeds. Seeds are planted with a germination potential; once potential exceeds the germination threshold they can be germinated. Germinated seeds become concepts only when they meet three simultaneous criteria: viability (fitness >= VIABILITY_THRESHOLD), novelty (novelty >= NOVELTY_THRESHOLD), and readiness (maturity stage). Concepts can be nurtured to increase fitness, pruned if stale, cross-pollinated to produce hybrid seeds, or adopted from external sources. Tracks genesis rate and novelty landscape across domains.

## Gem Info

| Field | Value |
|---|---|
| Gem name | `lex-cognitive-genesis` |
| Version | `0.1.0` |
| Namespace | `Legion::Extensions::CognitiveGenesis` |
| Ruby | `>= 3.4` |
| License | MIT |
| GitHub | https://github.com/LegionIO/lex-cognitive-genesis |

## File Structure

```
lib/legion/extensions/cognitive_genesis/
  cognitive_genesis.rb              # Top-level require
  version.rb                        # VERSION = '0.1.0'
  client.rb                         # Client class
  helpers/
    constants.rb                    # Concept types, domains, stages, thresholds, 6 label hashes
    seed.rb                         # Seed value object
    concept.rb                      # Concept value object
    genesis_engine.rb               # Engine: seeds, concepts, germination, fitness, novelty
  runners/
    genesis.rb                      # Runner module
```

## Key Constants

| Constant | Value | Meaning |
|---|---|---|
| `CONCEPT_TYPES` | array | `[:idea, :theory, :hypothesis, :belief, :intention, :memory, :insight, :fantasy, :archetype, :symbol]` |
| `SOURCE_DOMAINS` | array | `[:experience, :observation, :inference, :intuition, :analogy, :synthesis, :dream, :external]` |
| `MATURITY_STAGES` | array | `[:nascent, :developing, :mature, :crystallized, :transcendent]` |
| `SEED_DOMAINS` | array | Various cognitive domains |
| `GERMINATION_THRESHOLD` | 0.7 | Minimum potential to attempt germination |
| `NOVELTY_THRESHOLD` | 0.5 | Minimum novelty for concept birth |
| `VIABILITY_THRESHOLD` | 0.4 | Minimum fitness for concept birth |
| `GENESIS_RATE_WINDOW` | last N | Rolling window for genesis rate calculation |

Label hashes: `MATURITY_LABELS`, `FITNESS_LABELS`, `NOVELTY_LABELS`, `POTENTIAL_LABELS`, `GENESIS_LABELS`, `ADOPTION_LABELS`.

## Helpers

### `Seed`

Pre-concept cognitive material awaiting germination.

- `initialize(domain:, source:, content:, potential: 0.5, seed_id: nil)`
- `potential`, `germinated?`, `germinate!` — marks as germinated
- `boost!(amount)` — increases potential, capped at 1.0
- `to_h`

### `Concept`

A birthed cognitive entity with fitness, novelty, and maturity tracking.

- `initialize(concept_type:, domain:, content:, fitness: 0.5, novelty: 0.5, seed_id: nil, concept_id: nil)`
- `nurture!(amount)` — increases fitness
- `viable?` — fitness >= `VIABILITY_THRESHOLD`
- `novel?` — novelty >= `NOVELTY_THRESHOLD`
- `maturity_label`, `fitness_label`, `novelty_label`
- `to_h`

### `GenesisEngine`

- `plant(domain:, source:, content:, potential: 0.5)` — creates Seed; returns `{ planted:, seed_id:, seed: }`
- `germinate(seed_id:)` — requires potential >= GERMINATION_THRESHOLD; returns Concept candidate or `{ germinated: false, reason: }`
- `birth(seed_id:)` — requires viable + novel + ready (germinated); stores in concept map; returns `{ born:, concept_id:, concept: }` or rejection
- `nurture(concept_id:, amount: 0.1)` — increases concept fitness
- `prune(seed_id:)` — removes seed from store
- `cross_pollinate(seed_a_id:, seed_b_id:)` — creates new seed combining domains and averaging potential
- `adopt_concept(concept_type:, domain:, content:, fitness: 0.5, novelty: 0.5)` — imports concept from external source
- `concept_fitness(concept_id:)` — returns fitness + label
- `novelty_landscape` — domain -> mean novelty map
- `genesis_rate` — concepts born per time window
- `most_adopted(limit: 10)`, `orphan_concepts(limit: 10)`
- `genesis_report` — full stats

## Runners

**Module**: `Legion::Extensions::CognitiveGenesis::Runners::Genesis`

| Method | Key Args | Returns |
|---|---|---|
| `plant_seed` | `domain:`, `source:`, `content:`, `potential: 0.5` | `{ success:, seed_id:, seed: }` |
| `germinate_seed` | `seed_id:` | `{ success:, concept: }` or `{ success: false, reason: }` |
| `birth_concept` | `seed_id:` | `{ success:, concept_id:, concept: }` |
| `nurture_concept` | `concept_id:`, `amount: 0.1` | `{ success:, concept: }` |
| `prune_seed` | `seed_id:` | `{ success:, pruned: }` |
| `cross_pollinate` | `seed_a_id:`, `seed_b_id:` | `{ success:, seed_id:, seed: }` |
| `adopt_concept` | `concept_type:`, `domain:`, `content:` | `{ success:, concept_id:, concept: }` |
| `concept_fitness` | `concept_id:` | `{ success:, fitness:, label: }` |
| `novelty_landscape` | — | `{ success:, landscape: }` |
| `genesis_rate` | — | `{ success:, rate: }` |
| `most_adopted` | `limit: 10` | `{ success:, concepts: }` |
| `orphan_concepts` | `limit: 10` | `{ success:, concepts: }` |
| `genesis_report` | — | Full report hash |

Private: `genesis_engine` — memoized `GenesisEngine`. Logs via `log_debug` helper.

## Integration Points

- **`lex-cognitive-furnace`**: Smelted alloys (insight, wisdom, synthesis) feed genesis as seeds or direct concept inputs. The furnace produces refined material; genesis turns that material into new concepts.
- **`lex-cognitive-garden`**: Mature, flowering garden plants are candidates for genesis seed planting or cross-pollination.
- **`lex-memory`**: Born concepts should be stored as semantic traces in lex-memory. `adopt_concept` is the primary path for ingesting concepts from external sources or other agents.
- **`lex-dream`**: Dream cycle outputs (agenda items, resolved contradictions) can be adopted as concepts via `adopt_concept`.

## Development Notes

- `birth` is the gating step: a germinated seed's concept candidate must independently pass both viability (`fitness >= 0.4`) and novelty (`novelty >= 0.5`) checks. Germination alone is not sufficient.
- `cross_pollinate` does not consume source seeds; both remain in the store after producing a child seed.
- `orphan_concepts` returns concepts whose originating seed has been pruned.
- `genesis_rate` uses a rolling window; a cold engine with no births returns 0.0.
- In-memory only.

---

**Maintained By**: Matthew Iverson (@Esity)
