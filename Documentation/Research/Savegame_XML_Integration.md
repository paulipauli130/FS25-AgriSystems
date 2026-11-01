# Persistence Integration Notes — correction

FS25 Placeable and Vehicle save methods pass each specialization an XML key that already includes the registered specialization name. The savegame schema must register directly under that specialization base key. Both AgriSystems specializations now use their own registered specialization name as the save node:
- Spray & Hygiene: agriSystemsSprayer
- Farm Biosecurity: agriSystemsHusbandry

The per-specialization save/load keys and schema paths have been aligned. This is verified against the public FS25 LUADOC Placeable/Vehicle serialization pattern, but still requires an actual in-game save/reload test.
