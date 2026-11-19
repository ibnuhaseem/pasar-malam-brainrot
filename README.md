# Pasar Malam Brainrot

A 3D Roblox brainrot game for make.fun's "Make the best AI Roblox brainrot game" bounty (roblox-brainrot-01).
An Indonesian night market: absurd meme characters walk the market lane, players buy them, carry them home to
their stall, and earn money every second — while a Satpol PP raid can confiscate anything carried outside.

## The game

- **The loop:** characters spawn at the north gate and walk the lane → click one to buy it → carry it to your
  stall → press E (or click the green pad) to place it → it earns $/second → COLLECT the pending cash → buy rarer ones.
- **The cast:** 18 Part-built characters (no meshes, no decals), from Common Tukang Gorengan to Secret Raja Pasar
  Malam, on a rarity ladder with 5 mutations (Pedas x2, Manis x2, Goreng x3, Es x3, Pelangi x5).
- **Tension:** Razia Satpol PP every ~2.5 minutes — a siren warns for 20 seconds, then anyone carrying a character
  outside their own stall loses it. Other players can steal from unlocked stalls; locking a stall blocks stealing.
- **Progression:** Naik Kelas (rebirth) Gerobak → Kios → Ruko → Mall, each doubling income; Pesanan (missions) pay
  out cash; Buku Menu tracks the whole collection. Progress (cash, rebirth, collection, missions) saves in a DataStore.

## Build

Rojo 7.7.1 builds the place from `src/` and `default.project.json`:

    rojo build default.project.json --output game.rbxl

Luau syntax is checked with `luau-compile --only-parse src/**/*.luau`.

`main.ts` (Node 22, standard library only) hands the game in: it copies `game.rbxl`, `src/`, `screenshots/` and
`PLAY.json` to `/output`, leaving out every name that starts with a dot, and writes `/output/dossier.json` with
`vendor/makefun-roblox.ts`, the kit's copy, unchanged.

    mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts

## Publish (only the Roblox account owner can do this, in Studio)

1. Open `game.rbxl` in Roblox Studio and publish it as a new experience named **Pasar Malam Brainrot**.
2. In the experience description, include the play code `makefun-parsley-gadget-windmill`.
3. Answer Roblox's content questions, set the experience **Public**.
4. Upload an icon (512x512) and a thumbnail on the Creator Dashboard; the first thumbnail must be one of the
   screenshots under `screenshots/` (take 3–4 in Studio while the game runs, 1280x720, each ≤256 KiB).
5. Fill in `PLAY.json` with the real `place_id` and `universe_id`, commit, and submit.

The rules are on the bounty's page (/bounty/roblox-brainrot-01) and in the kit's RULES.txt.
