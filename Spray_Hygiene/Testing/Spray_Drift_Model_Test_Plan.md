# Spray Drift Model — Test Plan

## Scope

The model is a deterministic, bounded gameplay-risk estimator. It is not a physical droplet-transport or deposition simulator and has not been calibrated against field measurements. It is not connected to FS25 weather or sprayer callbacks.

## Deterministic checks

1. Empty parameters return risk 0 and a zero transport vector.
2. Zero wind speed returns risk 0.
3. Larger droplets do not increase the modelled droplet susceptibility.
4. Lower boom height does not increase the modelled height factor.
5. Increasing wind speed up to 8 m/s does not decrease wind factor.
6. windScale and maxRisk are bounded; risk always remains in 0–1.
7. NaN and infinite inputs fall back to safe defaults.
8. A non-zero explicit wind-to vector is normalized to unit length.
9. A zero vector remains zero; the model does not invent a direction.
10. Risk bands are low below 0.25, moderate from 0.25 to below 0.6, and high from 0.6 upward.

## Runtime integration gates

- Verify the sign convention of WindUpdater:getCurrentValues() direction components visually in the exact target FS25 patch before supplying them as wind-to direction.
- Confirm whether wind values are updated on clients, server, or both; gameplay decisions must remain server-authoritative.
- Establish real nozzle/drop-size and boom-height inputs from supported vehicle configuration data before using non-default values.
- Do not apply penalties, modify spray area processing, or change native fill consumption until a dedicated-server test confirms callback timing and compatibility with Precision Farming and AI.
- Compare risk behavior against controlled in-game scenarios before enabling the module by default.
