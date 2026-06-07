# Hole Rush Visual Modernization

## Backup
A full copy was saved before changes:
`c:\Users\RemyB\Documents\hole-rush-backup-20260606-084835`

## What changed (visual/polish only)
- Unified design tokens in `UIStyles` (blue/gold mobile palette)
- Button press bounce via `UIStyles.bind_button()`
- Scene fade transitions via `main.gd` + `scene_transition.gd` (preloaded, not autoload)
- Procedural WAV audio in `audio/`
- Modern shop overlay (`shop_screen.tscn`)
- HUD / victory / game over / level prep theme alignment
- Win/lose sound hooks (gameplay logic unchanged)

## Android test
1. Open project in Godot 4.6+
2. **Project → Reload Current Project** (imports new `audio/*.wav`)
3. Play (F5): home → level → win/lose → coin fly-back
4. **Project → Export → Android** (existing preset)
5. Install APK on device; verify touch, audio toggles in Settings, coin persistence

## Restore backup
Copy contents from backup folder over project (exclude `.godot` if you want a clean reimport).
