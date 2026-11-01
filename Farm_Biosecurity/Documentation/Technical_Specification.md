# AgriSystems Farm Biosecurity — Technical Specification

Status: implementation-ready design; runtime gates explicitly retained. Target: FS25 PC/Mac, single-player and dedicated-server multiplayer. Independent package: `FS25_AgriSystems_FarmBiosecurity.zip`.

## 1. Scope and boundaries
Model livestock quarantine, group disease exposure/progression, separation and movement restrictions, vehicle/trailer/equipment/visitor hygiene, barn hygiene and a derived Biosecurity Score. V1 uses a small configurable set of abstract game disease profiles and group-level state. It is not veterinary diagnosis or clinical treatment advice. Avoid named pathogen accuracy claims. Vaccination is not universal immunity and is excluded from v1 unless separately specified by disease profile.

## 2. Server authority and registration
Server owns progression, exposure, quarantine, hygiene, score, persistence and validation. Clients request actions only. Validate sender, farm permission, placeable access, distance, action eligibility and resource costs. Initial snapshot on join; compact deltas on dirty state. Register a namespaced placeable specialization only for types containing PlaceableHusbandryAnimals during the proper type-validation phase; idempotent injection; skip unsupported placeables.

Local FS25 source confirms PlaceableHusbandryAnimals creates AnimalClusterSystem, exposes getClusters/getCluster/getClusterById/getClusterSystem, updates server-side, delegates save/load and initial stream to cluster system, and announces changes via AnimalClusterUpdateEvent.

## 3. Animal identity and reconciliation
Engine cluster IDs are runtime-only: generated from counter, not stored in cluster save XML, regenerated on load, transmitted in initial stream, and changed by clone/split/merge/removal. Cluster system maintains current idToIndex mapping. Compatible clusters may merge; one ID survives based on iteration. Never use engine cluster ID as persistent identity.
Persist mod-generated husbandry ID and mod-owned group record IDs; maintain transient engine-ID mapping only for current session. Reconcile on each cluster update and after load. Match unchanged groups only where evidence is unambiguous. Split: copy infection/exposure/quarantine conservatively to descendants. Merge: highest infection/exposure state wins; quarantine and stricter restrictions remain if either source has them. Ambiguous mapping must not clear infection/quarantine; log and choose conservative state. Keep historical records bounded.

## 4. Gameplay model
### Disease profiles
Data-driven ID/name, incubation duration, infectious duration/recovery progression, transmission route flags (animal contact, shared equipment, vehicle/visitor, environment), infectiousness, severity progression, recovery rate, quarantine duration/restrictions and outcome weights. Use in-game time units and server deterministic seed. Exposure requires an actual modeled contact opportunity; no spontaneous random infection. Group-level state only in v1.
### Exposure
Bounded risk: `risk = clamp(baseRate × sourceInfectiousness × contactIntensity × routeFactor × hygieneFactor × susceptibility, 0, riskMax)`. Contact intensity derives from shared groups/resources/equipment/transport/visitor events. Hygiene reduces route factor. Susceptibility is a gameplay parameter, not a breed/medical inference. Evaluate on events or coarse intervals, never every frame. Separate exposed, incubating, infectious, recovering and recovered/temporary-protection states.
### Quarantine
Purchased/returning groups receive configurable in-game quarantine duration. Completion requires elapsed time and configured hygiene checks. Physical animal movement may not be natively blocked; provide advisory, mod-mediated restriction and/or configurable risk/penalty modes. Persist quarantine through save/load and group reconciliation.
### Hygiene
Bounded contamination for vehicle/trailer, equipment, visitor/staff entry and barn/pen environment. Cleaning and disinfection are distinct: remove organic dirt first, apply abstract disinfectant, satisfy configured contact time. Dirty surfaces cannot receive full disinfection effectiveness. Costs/time/effectiveness configurable; no real-world concentration claims.
### Biosecurity Score
Derived 0–100 from quarantine compliance, active exposure/disease load, barn hygiene, vehicle/equipment cleanliness and visitor controls. Show component breakdown and actionable causes. Score is never source of truth and cannot overwrite disease state. Normalize weights; missing data is not silently treated as perfect compliance.

## 5. Configuration
Versioned authoritative save settings: disease toggle/profiles/progression interval; quarantine toggle/duration/mode/enforce-on-purchase; hygiene cleaning/disinfection effectiveness/contact time; access policy/vehicle contamination; score weights/thresholds; debug/log level. Validate ranges and IDs; safe defaults on invalid/missing values; ignore unknown keys; migration preserves old saves. Local modSettings only UI preferences.

## 6. Persistence
Unique mod-owned XML root/schema. Persist husbandry mod IDs, group records, exposure/disease/quarantine states, barn/vehicle/equipment/visitor contamination, authoritative settings and migration version. Do not persist engine cluster IDs as identity; rebuild transient mapping after load. Invalid XML/unknown records must not block save load. Prune/archive orphan records with bounded retention.

## 7. Networking/actions
Actions include inspect status, request quarantine action, clean/disinfect equipment or barn, visitor/access action. Events carry bounded primitives and valid network refs. Never accept client infection state, score, contamination or timestamps as authority. Server computes costs and outcomes, checks permissions and broadcasts deltas. Initial stream supports late join; no full database every tick.

## 8. UI
Farm biosecurity dashboard: quarantined/at-risk groups, active exposure/infection alerts (clearly distinguish exposure from confirmed infection), barn/vehicle/equipment hygiene, visitor warnings, Biosecurity Score and breakdown, available actions. English/German localization; in-game UI only.

## 9. Performance/compatibility
Group-level simulation; event-driven husbandry updates plus bounded progression interval. No per-frame scan of animals/vehicles. Cache placeables and invalidate on deletion. Bound history/records and replicate only dirty state. Skip unsupported animal systems safely; log incompatible cluster behavior. Test base maps and modded husbandry, dedicated server and load order.

## 10. Acceptance tests
Purchase triggers quarantine; save/load retains it. Disease only follows valid exposure; progression states and time scale behave consistently. Split/merge/reproduction/riding/death/sale cannot silently clear quarantine/infection. Load regenerates engine IDs and mod reconciliation remains conservative. Clean-before-disinfect and contact-time rules work. Vehicle/visitor/equipment routes create configured exposures. Score updates from components reproducibly. Client cannot forge state. Late join/reconnect/restart sync. Invalid settings/XML recover. Large herds avoid per-frame full scans. Uninstall leaves vanilla save functional.

## 11. Runtime release gates
Test cluster reconciliation in purchase/sale/split/merge/reproduction/riding/death/save-load/late join; dedicated-server authority; placeable type validation order; alternate animal systems; progression under game time scales. Run matching GIANTS TestRunner and actual SP/dedicated-server regression tests.

## 12. Packaging
ZIP root contains modDesc.xml and runtime assets only; exclude docs/tests/research/.git/tools/logs. Independent package; filename `FS25_AgriSystems_FarmBiosecurity.zip`.
