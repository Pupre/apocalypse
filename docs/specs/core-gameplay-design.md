# Apocalypse Hybrid Survival Game Design

- Status: approved
- Created: 2026-03-31
- Last updated: 2026-03-31
- Scope: pre-production core gameplay backbone

## Purpose

Define the core gameplay structure for a mobile apocalypse survival game that combines real-time outdoor traversal with text-driven indoor exploration. This document fixes the design spine first and deliberately leaves the main story premise flexible.

## Game Definition

- Genre: hybrid survival roguelike
- Platform target: mobile
- Camera: 2D top-down for outdoor play
- Run structure: one survivor per run; death ends the run
- Tone target: apocalypse immersion first, day-planning strategy second

## Player Fantasy

The player is not a chosen hero. They are an ordinary survivor trying to stay alive one more day in a collapsing world. Survival comes from planning, scavenging, improvising, and deciding what to risk today to still have a tomorrow.

## Core Pillars

1. Shared time economy across all activities
2. Real-time outdoor risk and route pressure
3. Text-driven indoor exploration and judgment
4. Tradeoffs between immediate gain and long-term survivability
5. Distinct survivor builds created through jobs and traits
6. Temporary settlement and relocation instead of a permanent home

## World Assumption

The exact apocalypse cause remains intentionally open at this stage. It may be nuclear fallout, hazardous lifeforms, toxic spores, or another hostile outside condition. Because the story premise is still open, the game uses a neutral concept for now:

- `outside exposure resource`: a story-dependent survival limiter for staying outdoors

If the story settles on a specific apocalypse cause, this can be expressed through the matching protective or survival device for that fiction. The gameplay role stays the same even if the narrative wrapper changes.

## Core Loop

1. Create a survivor using a job and trait build.
2. Start from a temporary safe location.
3. Decide how to spend the day: indoor exploration, outdoor excursion, resting, or relocation prep.
4. Travel outside in real time to reach buildings, objectives, or escape danger.
5. Enter buildings and explore them through text-based hour-by-hour choices.
6. Manage hunger, supplies, fatigue, time, and the outside exposure resource.
7. Convert a useful building into a temporary base if it is worth holding.
8. Strip the local area for value until travel distance and danger make the location inefficient.
9. Relocate with only what can realistically be carried or hauled.
10. Repeat until the survivor dies.

## Time Model

### Shared Day Clock

- A day is 24 in-game hours.
- Indoor and outdoor activities share the same daily clock.
- Time is the main strategic resource of each day.

### Indoor Time

- Indoor exploration is turn-based.
- Default unit: 1 indoor action consumes 1 in-game hour.
- Large buildings cannot usually be fully explored in one day.

### Outdoor Time

- Outdoor play is real-time.
- Baseline: 1 real second = 1 in-game minute.
- Result: 60 real seconds = 1 in-game hour.
- Outdoor hesitation, detours, combat, fleeing, and inefficient routing all directly consume the same day resource used by indoor exploration.

### Design Intent

The point of the clock is not constant panic. The point is that all action has an opportunity cost. Spending time outside means less time inside. Spending time inside means less time to travel, respond, relocate, or rescue.

## Outdoor Gameplay

### Role

Outdoor gameplay is the high-risk layer of the game world.

### Format

- Real-time 2D top-down traversal
- Unsafe by default
- The player must route through danger rather than safely fast-travel between buildings

### Common Outdoor Activities

- Reach nearby buildings
- Chase distant opportunities such as rescue calls
- Scavenge exposed locations
- Avoid enemies
- Fight when escape is not efficient
- Carry loot back
- Relocate to a new base

### Outdoor Constraints

- Shared time clock
- Outside exposure resource
- Enemy threat
- Carry weight and hauling limitations
- Route inefficiency caused by danger, detours, and bad positioning

### Outdoor Reward Profile

Outdoor rewards are not simply "better" than indoor rewards. They are different in kind.

- More likely to produce unique opportunities
- More likely to create unusual or high-impact finds
- More likely to force reactive decisions
- Still capable of producing normal supplies

## Indoor Gameplay

### Role

Indoor gameplay is the lower-risk but still dangerous judgment layer of the game.

### Format

- Text-driven exploration
- Choice-based actions
- Slower and more deliberate than outdoor play

### Common Indoor Actions

- Move between floors or rooms
- Search containers
- Investigate suspicious signs
- Open locked spaces
- Decide whether to push deeper or withdraw
- Rest
- Sleep

### Indoor Risk Profile

Indoor spaces are not safe. They are safer than outdoors on average.

Possible indoor threats include:

- Hidden survivors
- Ambushes
- Traps
- Structural hazards
- Noise consequences
- Loss of items
- Lost time
- Forced unconsciousness or temporary incapacitation

### Indoor Reward Profile

- Stable supply acquisition
- Food, water, medicine, tools, and daily-use goods
- Base conversion opportunities
- Rare finds are possible, but not the main expectation

## Risk and Reward Relationship

The target rule is:

- Outdoors = high risk
- Indoors = lower risk
- Reward difference is based more on type than on raw quality

This avoids a false binary where one mode is always the "correct" farming route.

### Reward Bias

- Outdoors leans toward unique, unusual, and situationally powerful gains
- Indoors leans toward reliable survival maintenance and structured exploration progress
- Neither side is exclusive; both normal and exceptional outcomes can occur in both layers

## Survivor Creation

### Structure

Each run starts by creating a survivor through:

- a job
- a mix of positive and negative traits

### Design Goal

The system should create meaningful tradeoffs, not perfect builds.

Example build logic:

- fast runner, but unlucky indoors
- high carry strength, but poor stamina recovery
- light sleeper, but panic-prone

### Trait Impact Areas

- movement speed
- fatigue gain
- sleep efficiency
- carry capacity
- combat stability
- indoor find quality bias
- event handling advantages or disadvantages

## Fatigue and Sleep

### Sleep Rules

- Sleep is never forced by the system.
- Sleep is only chosen while indoors.
- The player chooses when to sleep.
- Wake-up time is not fixed.

### Sleep Duration Inputs

Sleep duration is influenced by:

- current fatigue
- survivor stats
- relevant traits

### Fatigue Model

- Staying awake longer gives more actions now.
- The cost is increased future sleep demand and reduced performance before sleep.
- Fatigue should compound enough that abuse is dangerous.

### Immediate Fatigue Penalties

Fatigue must affect both gameplay layers before the player goes to sleep.

- Outdoors: weaker efficiency, worse escape margin, or higher resource drain
- Indoors: lower exploration effectiveness, worse event outcomes, or lost opportunities

### Sleep Utility Items

Items like an alarm clock can interrupt sleep early.

- This lets the player reclaim time
- Fatigue recovery is partial
- If fatigue is too severe, the item can fail to wake the survivor

### UX Requirement

The hidden formula can be complex, but the player-facing feedback must stay readable.

The game should show:

- current fatigue band
- expected sleep duration before confirming sleep
- expected wake-up time
- expected alarm reliability if an alarm-type item is used

## Temporary Bases and Relocation

### Base Philosophy

The game is not built around one permanent headquarters.

- A strong building can serve as a temporary base
- The player may hold it for several days
- Local efficiency eventually falls as nearby resources are exhausted

### Why Relocate

Relocation happens because:

- nearby loot runs become too time-expensive
- danger increases
- opportunity shifts elsewhere
- remaining in place becomes strategically inefficient

### Relocation Tension

The player cannot take everything.

- Bags, carts, and hauling tools increase transfer volume
- More hauling often means slower and riskier outdoor movement
- Moving base is a strategic compression problem: what matters enough to carry forward

## Stored Items in Old Bases

Items left behind remain in the world, but are not guaranteed forever.

### Current Rule

Loss risk depends mainly on human accessibility rather than abstract danger.

- Easy-to-reach areas are more likely to be looted by other survivors
- Hard-to-access or hostile areas are worse to revisit but better for hiding supplies

This creates distinct choices between:

- comfortable living spots
- secure stash locations

## Event Design Principle

The game should not rely on arbitrary punishment.

When possible, risky events should be foreshadowed through clues so the player can make an informed guess.

Examples of clue language:

- lingering warmth
- recent footprints
- strange silence
- signs of forced entry
- disturbed shelves

The goal is not full prediction. The goal is to let the player infer danger and feel responsible for the choice they make next.

## Design Boundaries for This Spec

This document intentionally fixes the backbone only. It deliberately leaves these areas open:

- the main story cause of the apocalypse
- the final name and fiction wrapper of the outside exposure resource
- the full combat model
- the full stat sheet
- content tables for jobs, traits, events, or item lists

Those are follow-up design tasks built on top of this foundation.

## Summary

This game is a mobile hybrid survival roguelike built around one shared day clock. Outdoor play is real-time, dangerous, and route-sensitive. Indoor play is text-based, slower, and more deliberate. The player survives by balancing time, fatigue, supplies, exposure, and relocation pressure while piloting a flawed survivor build through a hostile apocalypse.
