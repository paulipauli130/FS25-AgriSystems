# AgriSystems – Development Roadmap

This document describes the planned development stages of FS25 AgriSystems.

The roadmap is a living document and may change as development progresses, technical limitations are discovered and community feedback is collected.

**Current overall status: Planning**

---

## Phase 1 – Project Foundation

**Status: In Progress**

- [ ] Establish repository structure.
- [ ] Define project architecture.
- [ ] Create technical documentation.
- [ ] Establish coding and contribution guidelines.
- [ ] Research Farming Simulator 25 scripting APIs.
- [ ] Create initial mod templates.
- [ ] Establish configuration and logging systems.

## Phase 2 – AgriSystems Spray & Hygiene

### 2.1 Sprayer Engineering

**Priority: High**

- [ ] Investigate available sprayer data and game APIs.
- [ ] Implement nozzle wear.
- [ ] Implement nozzle blockage.
- [ ] Implement pressure and flow-rate calculations.
- [ ] Implement application accuracy.
- [ ] Add configuration options.

### 2.2 Spray Drift

**Priority: High**

- [ ] Research available weather data.
- [ ] Implement wind-dependent drift calculations.
- [ ] Consider boom height and nozzle characteristics.
- [ ] Calculate affected areas outside the target field.
- [ ] Implement configurable drift effects.

### 2.3 Sprayer Cleaning

**Priority: Medium**

- [ ] Implement tank residue tracking.
- [ ] Implement pipe and filter contamination.
- [ ] Add cleaning procedures.
- [ ] Add rinsing and cleaning-water consumption.
- [ ] Implement contamination during product changes.

### 2.4 Field Contamination

**Priority: Medium**

- [ ] Define contamination types.
- [ ] Track contamination on agricultural machinery.
- [ ] Implement transfer between fields.
- [ ] Consider weed seeds, plant residues and pathogens.
- [ ] Add cleaning and prevention mechanics.

## Phase 3 – AgriSystems Farm Biosecurity

### 3.1 Livestock and Quarantine

- [ ] Implement quarantine for newly purchased animals.
- [ ] Define quarantine periods.
- [ ] Implement configurable disease risks.
- [ ] Track animal groups and their health status.

### 3.2 Disease Transmission

- [ ] Define transmission mechanisms.
- [ ] Implement configurable infection risks.
- [ ] Consider contact between animal groups.
- [ ] Add disease prevention measures.

### 3.3 Farm Hygiene

- [ ] Implement barn hygiene.
- [ ] Implement vehicle and equipment hygiene.
- [ ] Implement visitor access and hygiene management.
- [ ] Add cleaning and disinfection procedures.

### 3.4 Biosecurity Score

- [ ] Define the scoring system.
- [ ] Evaluate hygiene and prevention measures.
- [ ] Display farm biosecurity status.
- [ ] Add configurable thresholds and penalties.

## Phase 4 – User Interface and Configuration

- [ ] Develop a consistent user interface.
- [ ] Add configurable module settings.
- [ ] Provide clear status information.
- [ ] Add notifications where appropriate.
- [ ] Support individual module activation and deactivation.

## Phase 5 – Testing and Compatibility

- [ ] Test all modules in single-player.
- [ ] Test multiplayer synchronisation.
- [ ] Test dedicated server behaviour.
- [ ] Check compatibility with other mods.
- [ ] Investigate performance impact.
- [ ] Fix reported bugs.

## Phase 6 – Public Releases

- [ ] Prepare release documentation.
- [ ] Create installation instructions.
- [ ] Finalise configuration defaults.
- [ ] Prepare ModHub submission where applicable.
- [ ] Publish the first stable releases.

---

## Development Principles

- Each major module should be independently configurable.
- Both mods should work independently.
- No mandatory external website or online service.
- Multiplayer support should be considered from the beginning.
- Features must be tested in-game before being marked as completed.
- Roadmap items are plans, not promises of implementation.

---

## Community Involvement

Community members can help by:

- Suggesting improvements.
- Reporting bugs.
- Testing development builds.
- Discussing gameplay mechanics.
- Contributing code and documentation.

Use GitHub Issues and Discussions to participate in development.
