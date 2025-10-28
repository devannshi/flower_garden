# Greedy Planting Algorithm with Pattern Replication & Optimization

An advanced plant placement algorithm that combines strategic greedy selection, pattern replication, and multiple performance optimizations to efficiently fill large gardens with interacting plant communities.

## 🎯 Core Strategy

### The Three-Phase Approach

**Phase 1: Design the Optimal Starter Group**
- Build a small, highly optimized group of 3-5 plants
- Each plant must interact with multiple species for nutrient exchange
- Stop when no further improvements are possible

**Phase 2: Replicate the Proven Pattern**
- Move the starter group to origin (0,0) for easy copying
- Systematically scan the garden and place identical copies
- Each copy uses fresh plant varieties from the inventory

**Phase 3: Fill Remaining Space**
- Build new independent groups in uncovered areas
- Continue with greedy one-by-one placement if needed
- Validate all groups to ensure quality

## 🔬 Algorithm Details

### 1. Candidate Generation

**Exhaustive Grid Search**
- Scans every integer position in the garden (e.g., 51×51 = 2,601 positions)
- Filters out collision zones (positions inside existing plants)
- Guarantees no valid position is missed

Unlike geometric approaches that sample around existing plants, exhaustive search ensures comprehensive coverage across the entire garden space.

### 2. Intelligent Candidate Evaluation

The algorithm uses a **multi-stage evaluation pipeline** to balance quality and speed:

#### Stage 1: Fast Heuristic Pre-filtering
Quickly scores candidates using cheap calculations:
- **Nutrient Production Score**: Weighted by garden's current nutrient deficit
- **Exchange Potential**: Estimates ideal nutrient exchange with neighbors
- **Normalization**: Divides by effective interaction area (rewards space-efficient placements)

Only the top ~30% of candidates advance to expensive simulation.

#### Stage 2: Adaptive Simulation Depth
Uses **dynamic simulation turns** that decrease as the garden fills:
- Early placements: Longer simulations (T=100) → more accurate predictions
- Later placements: Shorter simulations (T=40) → faster execution
- Formula: `T = T_max × (T_min/T_max)^(progress^0.7)`

This prioritizes accuracy when it matters most and speed when the garden is nearly full.

#### Stage 3: Finegrained Refinement
Re-evaluates the top 4 candidates with deeper simulation (T=500):
- Catches subtle differences missed by initial evaluation
- Ensures the final choice is truly optimal among the best candidates

### 3. Interaction Requirements

**Progressive Constraints** ensure healthy plant communities:

| Plant # | Constraint | Reason |
|---------|------------|--------|
| 1st | None | Foundation plant, placed at garden center |
| 2nd | Different species from 1st | Enable nutrient exchange |
| 3rd+ | Interact with ≥2 species | Ensure diverse exchange networks |

**Relaxation Mechanism** (one-time fallback):
- If no 2-species position exists, allow 1-species interaction *once*
- If the next plant restores 2-species interaction → continue building
- If restoration fails → rollback and stop group construction

This prevents getting stuck while maintaining quality standards.

### 4. Group Validation

After each group is built, an **iterative validation pass** removes weak plants:

```
For each plant (from 3rd onwards):
    If plant lacks 2-species interaction:
        Remove plant
        Check if removal caused neighbors to lose 2-species → remove them too
        Repeat until all remaining plants are valid
```

This ensures no single-species "dead ends" remain in the final garden.

### 5. Performance Optimizations

**Parallel Simulation** (4 CPU cores)
- Evaluates multiple candidates simultaneously
- Automatically enabled when evaluating 8+ candidates
- ~3-4× speedup on multi-core systems

**Interaction Caching**
- Stores results of "which species does this position interact with?"
- Cache key: `(variety, position, garden_size)`
- Eliminates redundant distance calculations

**Interaction Pattern Grouping**
- Groups candidates by identical interaction patterns
- Only simulates the spatially-best candidate from each group
- Reduces 2000+ evaluations → ~200-500 actual simulations

### 6. Scoring Function

**Fast Heuristic** (for pre-filtering):
```
produce_score = Σ(nutrient_production × demand_weight)
exchange_score = Σ(min(offer_to_neighbor, offer_from_neighbor))
final_score = (produce_score + exchange_score) / effective_area
```

**Full Simulation** (for final decisions):
- Clones the garden and simulates T turns of growth
- Tracks short-term (turns 1-5) and long-term (6-T) growth
- Computes weighted score: `0.2×short_term + 1.0×long_term`
- Normalizes by effective area: `circle_area^1.5 - (overlap + out_of_bounds)×0.5×radius`

## 📊 Algorithm Flow

```
START
  │
  ├─ Phase 1: Build Starter Group
  │    └─ Place plant #1 at garden center
  │    └─ Place plant #2 (different species, interacts with #1)
  │    └─ Place plant #3 (different species, interacts with #1 and #2)
  │    └─ Place plant #4+ greedily (each must interact with ≥2 species)
  │    └─ Stop when score ≤ epsilon
  │    └─ Validate group (remove plants lacking 2-species interaction)
  │
  ├─ Phase 2: Move to Origin
  │    └─ Shift entire group so top-left corner is at (0,0)
  │
  ├─ Phase 3: Replicate Pattern
  │    └─ Scan garden left→right, top→bottom
  │    └─ Try placing copy at each position
  │    └─ Place if: no collisions + all plants in bounds + varieties available
  │    └─ Repeat until no more copies fit
  │
  ├─ Phase 4: Fill Remaining Space
  │    └─ Try building new independent groups (≥3 plants each)
  │         └─ Find open position
  │         └─ Build group with 2-species interaction requirement
  │         └─ Validate group
  │         └─ Repeat if successful
  │    └─ Continue with greedy one-by-one placement
  │         └─ Each plant must interact with ≥2 species
  │         └─ Stop when no valid placements remain
  │    └─ Final validation of entire garden
  │
END
```

## ⚙️ Configuration

All parameters are defined in the `CONFIG` dictionary at the top of `gardener.py`:

### Simulation Parameters
- `T`: Default simulation turns (100) - balances accuracy and speed
- `adaptive_T_min`: Minimum turns in late stage (40) - ensures baseline quality
- `adaptive_T_alpha`: Decay curve shape (0.7) - controls how quickly T decreases
- `area_power`: Exponent for area calculation (1.5) - penalizes large plants less than quadratic

### Performance Parameters
- `parallel`: Enable multiprocessing (True) - utilize multiple CPU cores
- `num_workers`: Parallel workers (4) - match your CPU core count
- `heuristic_top_k`: Candidates after pre-filtering (32) - balance breadth and speed
- `finegrained_top_k`: Candidates for deep simulation (4) - focus on best options
- `finegrained_T`: Deep simulation turns (500) - high accuracy for final choices

### Placement Parameters
- `epsilon`: Stopping threshold (-10) - allows small decreases to explore more
- `tolerance`: Deduplication distance (0.5) - merges nearby candidates

## 🚀 Usage

### Quick Start

```bash
# From project root
cd /path/to/flower_garden

# Run with test configuration
python main.py \
  --gardener gardeners.group10.greedy_algorithm_with_replacement_1028 \
  --config examples/example.json \
  --simulation-turns 1000
```

### Configuration File Format

```json
{
  "width": 50,
  "height": 50,
  "varieties": [
    {"name": "R1", "species": "RHODODENDRON", "radius": 3, ...},
    {"name": "G1", "species": "GERANIUM", "radius": 1, ...},
    {"name": "B1", "species": "BEGONIA", "radius": 2, ...}
  ]
}
```

### Adjusting Parameters

Edit `CONFIG` in `gardener.py`:

```python
# For faster execution (competition mode)
CONFIG = {
    'simulation': {
        'T': 100,
        'adaptive_T_min': 22,  # Reduce minimum simulation depth
        'finegrained_T': 250,  # Reduce finegrained depth
    },
    'performance': {
        'heuristic_top_k': 32,  # Fewer candidates to evaluate
    }
}

# For maximum quality (no time limit)
CONFIG = {
    'simulation': {
        'T': 1000,
        'adaptive_T_min': 100,  # Maintain high simulation depth
        'finegrained_T': 1000,  # Deep finegrained evaluation
    },
    'performance': {
        'heuristic_top_k': 100,  # More candidates
    }
}
```

## 📈 Performance Characteristics

### Time Complexity

| Stage | Complexity | Typical Count |
|-------|-----------|---------------|
| Candidate generation | O(W×H) | ~2,500 positions |
| Heuristic filtering | O(C×P) | 2,500 × 30 varieties |
| Simulation | O(K×T×P²) | 32 × 40 × 30² |
| Finegrained | O(F×T'×P²) | 4 × 500 × 30² |

Where: W=width, H=height, C=candidates, P=plants, K=top_k, F=finegrained_k, T=turns

**Typical Execution**: 20-30 seconds for 100 varieties, 50×50 garden, 1000-turn simulation

### Space Usage

- Garden state: O(P) where P is number of plants placed
- Candidate pool: O(W×H) positions
- Interaction cache: O(V×C×P) entries (auto-invalidates as garden grows)

## 🎯 Algorithm Strengths

**1. Comprehensive Search**
- Exhaustive grid search guarantees no position is missed
- No bias toward clustered or spread-out layouts

**2. Multi-Level Optimization**
- Fast heuristics eliminate poor candidates quickly
- Adaptive simulation balances accuracy and speed
- Finegrained search ensures optimal final choices

**3. Quality Assurance**
- 2-species interaction requirement ensures healthy communities
- Group validation removes weak plants
- Relaxation mechanism prevents premature stopping

**4. Scalability**
- Pattern replication efficiently fills large gardens
- Parallel simulation utilizes modern multi-core CPUs
- Caching avoids redundant calculations

**5. Robustness**
- Handles arbitrary garden sizes and variety counts
- Gracefully degrades when varieties run out
- No configuration required (sensible defaults)

## 🔍 Key Design Decisions

### Why Exhaustive Search?

**Alternatives considered:**
- Geometric candidates (sample angles around existing plants)
- Multi-species intersection points (find CCI zones)

**Why exhaustive wins:**
- Geometric methods may miss optimal positions between clusters
- Intersection-based methods struggle with first few plants
- Modern optimization (pattern grouping + caching) makes exhaustive feasible

### Why Pattern Replication?

**Problem**: Placing 30-100 plants individually is slow (each requires simulation)

**Solution**: Design once, copy many times
- Designing 5-plant pattern: 5 × 500 simulations = 2,500 evaluations
- Copying pattern 10 times: 10 × 0 simulations = 0 evaluations
- Total: 2,500 vs. 30 × 500 = 15,000 for individual placement

**Result**: ~6× speedup with comparable quality

### Why Adaptive Simulation Depth?

Early plants have **cascading impact** on all future placements:
- Plant #1 determines initial cluster location
- Plant #2-3 set the group geometry and species distribution
- Plant #10+ fills gaps in an established layout

Adaptive T allocates computational budget proportionally to impact.

## 📝 Technical Notes

### No YAML Dependency

Configuration is embedded as a Python dictionary (`CONFIG`) for:
- **Faster startup**: No file I/O or parsing overhead (~50× faster)
- **Type safety**: IDE autocomplete and type checking
- **Simplicity**: One less external dependency

### Effective Area Calculation

Plants are penalized for overlap and boundary overflow:

```
circle_area = π × radius^1.5  (sub-quadratic penalty for large plants)
overlap_penalty = Σ(intersection_areas) × 0.5 × radius
boundary_penalty = area_outside_bounds × 0.5 × radius
effective_area = circle_area - overlap_penalty - boundary_penalty
```

This rewards space-efficient placements within garden bounds.

### Interaction Caching Strategy

Cache invalidation uses garden size as version key:
```python
cache_key = (variety_signature, position, len(garden.plants))
```

When a new plant is added, `len(garden.plants)` increases → cache misses → recalculation.
This ensures correctness without manual invalidation logic.

## 🧪 Testing & Validation

### Recommended Test Cases

```bash
# Small garden (quick test)
python main.py --config test_small.json --turns 100

# Medium garden (development)
python main.py --config examples/example.json --turns 1000

# Large garden (stress test)
python main.py --config test_large.json --turns 1000
```

### Expected Results

| Scenario | Varieties | Plants Placed | Growth (T=1000) | Time |
|----------|-----------|---------------|-----------------|------|
| Small (20 varieties) | 20 | 12-15 | 3,500-4,500 | 5-10s |
| Medium (50 varieties) | 50 | 28-35 | 4,500-5,500 | 20-30s |
| Large (100 varieties) | 100 | 35-45 | 5,000-6,000 | 25-35s |

*Results vary based on variety distribution and garden size*

### Debug Mode

Enable verbose output to see algorithm progress:

```python
CONFIG = {
    'debug': {
        'verbose': True,  # Print placement decisions
        'log_candidates': False,  # Print candidate details (very verbose)
    }
}
```

Output example:
```
Starting placement with 50 varieties
Iter 1: 0 placed, 50 remain
  Generated 2601 exhaustive candidates
  Exhaustive eval: 2601 pos × 30 varieties = 78030 combos in 450 groups
  Finegrained: re-evaluating top 4 with T=500
  → R at (25,25): value=42.50, score=45.32
Iter 2: 1 placed, 49 remain [different species]
  ...
```

## 🎓 Algorithm Evolution

This algorithm builds on `greedy_planting_algorithm_1026` with key improvements:

1. **Pattern Replication** (v1027): Copy successful patterns across the garden
2. **Exhaustive Search** (v1027): Replace geometric candidates with full grid scan
3. **Performance Optimization** (v1028): Add parallel simulation, caching, adaptive T
4. **No External Config** (v1028): Embed configuration in code for faster startup

## 📚 References

- Core placement logic: `cultivate_garden()`
- Replication system: `_replicate_first_group()`
- Evaluation pipeline: `_find_best_placement_exhaustive_optimized()`
- Validation logic: `_validate_and_prune_group()`
- Scoring functions: `_cheap_heuristic_score()`, `evaluate_placement()` (in utils)

## 🤝 Contributing

To modify the algorithm:

1. **Adjust hyperparameters**: Edit `CONFIG` at top of file
2. **Change candidate generation**: Modify `_generate_exhaustive_candidates()`
3. **Customize scoring**: Update `_cheap_heuristic_score()` or `evaluate_placement()`
4. **Add new constraints**: Extend interaction checks in validation functions

Test changes with:
```bash
# Quick validation
python main.py --config test.json --turns 100

# Full benchmark
python main.py --config test.json --turns 1000 --repeat 5
```

---

**Last Updated**: October 2025  
**Version**: 1028 (Pattern Replication + Optimizations)  
**License**: MIT
