# Ryuji-Kisaragi

Godot 4.7.2 playable prototype for **Ryuji Kisaragi**, a hybrid Bajiquan and Shuai Jiao fighter built around grapples, explosive elbows, and short-range power strikes.

## Requirements

- Godot Engine **4.7.2**

## Project Structure

- `project.godot` - project configuration and input map
- `src/scenes/` - playable scenes (`main.tscn`, `player.tscn`, `dummy.tscn`)
- `src/scripts/` - gameplay scripts (state machine, combat, HUD flow)
- `src/assets/` - asset folder placeholder for future original content

## Run

### From Godot Editor

1. Open this repository folder in Godot 4.7.2.
2. Run the default main scene (`src/scenes/main.tscn`).

### From Command Line

From the repository root:

```bash
godot4 --path .
```

(If your binary name is `godot`, use `godot --path .`.)

## Deploy to Azure Static Web Apps (#1)

This repository includes a GitHub Actions workflow that exports the Godot project for Web and deploys it to **Azure Static Web Apps**.

### 1) Create Azure Static Web App

1. In Azure Portal, create a new **Static Web App**.
2. Use any temporary build preset during creation (the repository workflow handles actual build/deploy).
3. Copy the deployment token from your Static Web App.

### 2) Configure GitHub Secret

In your GitHub repository settings, add this secret:

- `AZURE_STATIC_WEB_APPS_API_TOKEN` = your Azure Static Web Apps deployment token

### 3) Trigger Deployment

- The workflow file is at:
  - `/home/runner/work/Ryuji-Kisaragi/Ryuji-Kisaragi/.github/workflows/azure-static-web-apps.yml`
- It runs automatically on pushes to `main`, or manually via **Actions → Build and Deploy Godot Web to Azure Static Web Apps → Run workflow**.

### 4) Web Export Details

- Godot Web export preset is defined in:
  - `/home/runner/work/Ryuji-Kisaragi/Ryuji-Kisaragi/export_presets.cfg`
- Export output path:
  - `build/web/index.html`

## Controls

- `W A S D` - Move / footwork
- `J` - Light short-range strike
- `K` - Explosive elbow
- `L` - Grapple / throw
- `I` - Block (defensive guard)
- `R` - Reset training round

## Current Prototype Scope

- Controllable Ryuji with directional facing based on movement.
- Compact combat state machine (idle, move, block, attack phases).
- Three attacks with timing windows, hitboxes/hurtboxes, damage, knockback, and cooldowns.
- Training dummy with health, hit reaction flash, defeat state, and reset flow.
- Minimal HUD with health bars, status feedback, and control reminder.
- Procedural/vector-style visuals only (no external copyrighted assets).

## Visual Direction References

- Reference image (user-provided): `https://github.com/user-attachments/assets/30f16b8b-1062-4bcb-934a-7c61b16e156d`
- Additional user-provided references:
  - `https://github.com/user-attachments/assets/5f5718a9-55d4-4323-87b3-ffb56bc46aa8`
  - `https://github.com/user-attachments/assets/d2459a2d-a3c7-4f82-b4fd-14fdcf4776f5`

These are used as style direction only; no external image files are bundled in the repository.

## License

This repository remains licensed under the included **Apache License 2.0** (`LICENSE`).
