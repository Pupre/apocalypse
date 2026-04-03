# Survival Stats First Pass Design

- Status: approved
- Created: 2026-04-02
- Last updated: 2026-04-02
- Scope: first production-facing survival stat layer for the prototype

## Purpose

Define the first survival stat system that gives scavenging a concrete motive and ties indoor and outdoor play into a shared survival loop.

This document fixes the first-pass design for `허기`, `갈증`, `체력`, and `피로` so those systems can be implemented consistently before secondary stat checks, deeper item simulation, and richer medical systems are added later.

## Design Role

This is the prototype's first true survival-pressure layer.

- It must create a clear reason to scavenge and consume resources
- It must reinforce the difference between indoor and outdoor activity
- It must connect naturally to existing time, inventory, sleep, and item systems
- It must leave room for later character-stat checks without forcing a redesign

## Core Goals

1. Make food, water, rest, medicine, and stimulants meaningful to moment-to-moment decision-making
2. Make time pressure matter beyond simple exploration opportunity cost
3. Make exhaustion affect how quickly and safely the player can act
4. Keep player-facing readability high even while internal calculations stay granular
5. Preserve room for future skill/stat checks, condition systems, and stronger simulation

## Included Survival Stats

The first pass includes exactly four survival stats.

- `허기`
- `갈증`
- `체력`
- `피로`

No additional core survival meters are introduced in this pass.

Specifically excluded from this scope:

- disease
- infection
- morale
- stamina as a separate meter
- radiation / contamination as a separate meter
- detailed wound types

## Internal vs Player-Facing Representation

### Internal Model

All four survival stats use internal numeric values.

- internal logic tracks exact values
- items and events can modify exact values
- balance tuning remains possible without changing player-facing UI language

### Player-Facing Model

The UI should show these stats as readable stages rather than raw permanent numbers.

- stage labels are always visible in both indoor and outdoor play
- exact numeric values are visible only in a detail panel or item interaction context

This split preserves readability while keeping the systems tunable.

## Stat Roles

### Hunger

`허기` is a medium-term survival pressure.

- it decreases over time
- it decreases faster when the player performs actions
- it decreases more slowly than thirst
- while above zero, it does not directly penalize the player in this first pass
- when it reaches zero, the player begins taking ongoing health damage until the hunger problem is addressed

### Thirst

`갈증` is the faster and more urgent pressure.

- it decreases over time
- it decreases faster when the player performs actions
- it decreases faster than hunger
- while above zero, it does not directly penalize the player in this first pass
- when it reaches zero, the player begins taking ongoing health damage until the thirst problem is addressed
- thirst damage should be more urgent than hunger damage

### Health

`체력` is the downstream damage layer rather than the primary timer.

- it does not naturally recover in normal play
- it is reduced by attacks, accidents, event consequences, and starvation/dehydration states
- it only recovers through explicit recovery methods

First-pass health recovery sources:

- medical items
- future recovery actions specifically marked for health recovery

Plain passage of time does not restore health.

### Fatigue

`피로` is the activity-pressure layer.

- it increases over time
- it increases more when the player performs actions
- outdoor activity should raise it more aggressively than indoor activity
- it does not directly damage health in this first pass
- its role is to make the player slower and less efficient before later systems attach harder penalties to it

## Zero-State Rules

### Hunger or Thirst at Zero

If either `허기` or `갈증` reaches zero:

- health starts decreasing continuously
- health loss continues until the missing need is addressed
- thirst-driven decline is harsher than hunger-driven decline

This rule is intentionally binary in the first pass:

- above zero: no direct performance penalty
- at zero: ongoing health damage

This keeps the early survival loop readable and avoids muddy partial penalties.

## Time and Environment Pressure

### Passive Decay

`허기`, `갈증`, and `피로` all change as time passes.

- passive time passage always matters
- the player cannot simply stand still forever without survival consequences

### Action-Based Decay

Actions increase pressure beyond passive decay.

- moving to a new indoor zone contributes to hunger, thirst, and fatigue
- searching, forced entry, and other deliberate actions contribute additional hunger, thirst, and fatigue
- outdoor movement and exposure contribute more than comparable indoor actions

### Indoor vs Outdoor Difference

The outdoor layer is harsher.

- thirst rises faster outside
- fatigue rises faster outside
- hunger also rises outside, but less dramatically than thirst

This supports the survival fantasy that outdoor travel is a more punishing use of time than indoor exploration.

## Consumption Rules

### Eating and Drinking

Food and drink can be used anywhere.

- indoor
- outdoor
- while exploring
- while repositioning

But using them is still a time-spending action.

- eating costs time
- drinking costs time
- they are not free instant actions

This preserves the strategic value of stopping to recover.

### Item Presentation

When the player inspects an item, the UI should show:

- a short flavor description
- exact stat changes such as `허기 +15`, `갈증 +30`, `체력 +10`

This applies to consumables and recovery items.

## Rest and Sleep

### Rest

`휴식` returns in this design, but it is not the same as sleep.

- rest is available only in zones marked as relatively safe
- rest lowers fatigue a little
- rest is a short-term endurance tool, not a full recovery loop
- rest does not replace sleep

Rest availability is content-driven.

- each zone or event can decide whether rest is available
- not every indoor space should allow it
- safe rooms, break rooms, secured offices, and future base-like spaces are valid candidates

### Sleep

`취침` remains the major recovery action for fatigue.

- sleep costs a large amount of time
- sleep restores fatigue much more strongly than rest
- sleep duration still depends on the broader sleep design already discussed elsewhere

### Sleep While Survival Stats Continue

During sleep:

- hunger still decreases
- thirst still decreases

But both should decrease more slowly than while the player is awake and active.

## Fatigue Penalties in First Pass

Only first-pass fatigue penalties are defined here.

### Indoor Penalty

Fatigue increases the time cost of indoor actions.

- moving between zones takes longer
- searching takes longer
- interacting takes longer

### Outdoor Penalty

Fatigue reduces outdoor movement efficiency.

- the player moves more slowly
- long outdoor runs become progressively less efficient

### Delayed Future Expansion

This design explicitly reserves future fatigue penalties for later systems.

Not in this pass:

- reduced skill-check odds
- accuracy penalties
- direct injury from tired actions
- hallucination or perception penalties

But the design should leave fatigue structured so those can be added later without breaking the first-pass model.

## Stimulants and Anti-Fatigue Items

Fatigue-management items are split into two categories.

### Everyday Stimulants

These are common and weak.

- coffee
- energy drinks
- weak caffeine tablets
- similar ordinary stimulants

They provide small immediate relief but do not truly erase fatigue debt.

### Strong Stimulants

These are rare and stronger.

- strong medication
- emergency stimulants
- harsher pharmaceutical options

They provide larger immediate relief, but they carry clearer downside.

### Design Rule

Stimulants do not truly solve fatigue.

- they reduce immediate felt fatigue
- they let the player keep moving temporarily
- they do not erase the deeper recovery need

Future downside hooks may include:

- rebound fatigue
- increased hunger or thirst
- health stress
- reduced later recovery quality

The exact balancing values are not fixed here, but the design role is fixed: stimulants buy time rather than create free recovery.

## Item Categories Supported by This Design

The first-pass survival layer should make these item groups meaningful:

- normal food
- durable food
- water
- flavored drinks and soft drinks
- medical recovery items
- everyday stimulants
- strong stimulants

This also prepares the project for richer item distinctions later, such as:

- fast but poor nutrition
- heavy but efficient hydration
- spoiled vs durable food
- cooked vs uncooked recovery value

Those distinctions are future extensions, not first-pass requirements.

## UI Expectations

### Always-Visible Information

Indoor and outdoor UI should always expose the stage-level survival state for:

- hunger
- thirst
- health
- fatigue

### Detail-Level Information

Exact numeric values should appear in:

- item detail panels
- future status detail panels
- future character inspection panels

### Tone

The UI should support quick reading.

- stage labels first
- exact numbers only when inspected
- item effects written as direct, exact deltas

## Relationship to Future Character Stats

This design must stay compatible with future secondary stat systems such as:

- strength
- agility
- intelligence
- luck

Those later systems may gate actions and probabilistic outcomes such as:

- forcing doors
- bypassing locks
- handling tools
- dealing with physical strain

Fatigue is intentionally designed to become a major modifier in those future checks, but those probability systems are outside this document's scope.

## Out of Scope

This design does not define:

- exact numeric balance values for decay rates
- exact thresholds for UI stage labels
- exact stimulant rebound formulas
- the full future stat-check probability model
- long-term disease or contamination systems

Those are implementation and tuning concerns that should follow this approved behavioral structure.
