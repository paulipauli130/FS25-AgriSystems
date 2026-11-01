# Runtime Validation — User Test Gate

The repository has source-reviewed engine integration, but it has not been run inside Farming Simulator 25. Do not use a valuable save without a backup.

## 1. Build the development ZIPs
1. Pull the latest main branch.
2. Open PowerShell in the repository root.
3. Run:
   
       .\tools\Build-Mods.ps1 -Clean

4. Confirm that the script creates:
   - Releases/FS25_AgriSystems_SprayHygiene.zip
   - Releases/FS25_AgriSystems_FarmBiosecurity.zip

If the script reports a missing file or localization, stop and send the error.

## 2. Record the game patch
Record the exact Farming Simulator 25 version shown in the game or in the first lines of log.txt. The public GDN LUADOC currently used for source review identifies Script/Engine v1.20.0.0; that is not proof that the local game uses the same patch.

## 3. Test Spray & Hygiene by itself
1. Back up the test save.
2. Enable only AgriSystems Spray & Hygiene.
3. Load the save and check log.txt for errors.
4. Use a sprayer and spray a small test area.
5. Save, exit to menu, reload and inspect log.txt again.
6. Confirm vanilla fill consumption and spray application still behave normally.

## 4. Test Farm Biosecurity by itself
1. Back up the test save.
2. Enable only AgriSystems Farm Biosecurity.
3. Load a save containing at least one animal husbandry.
4. Check log.txt for specialization, XML schema, stream or callback errors.
5. Advance at least one in-game hour.
6. Save, exit to menu, reload and inspect log.txt again.

The current logical cohort model aggregates all engine clusters of the same configured animal subtype within one husbandry. It does not yet distinguish same-subtype subgroups inside one pen.

## 5. Send back
The minimum information needed to continue safely:
- Exact FS25 game version/patch.
- Full log.txt from a test with Spray & Hygiene enabled alone.
- Full log.txt from a test with Farm Biosecurity enabled alone.
- Any error message or visible unexpected behavior.

Do not test both mods together first. Isolating them makes load-order and registration errors much easier to identify.

## Not yet covered
Dedicated-server, late-join, reconnect, Precision Farming, AI, Courseplay and full save migration tests remain outstanding.
