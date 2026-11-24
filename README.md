# Taverners Crafting Directory

Version 0.2.0-alpha | The Taverners Guild

Guild recipe and crafter directory. Members install the addon, scan professions, then share their records through the guild addon-message channel.

## Included in this alpha
- Local character crafter profile and profession skill capture.
- Learned recipe scan when a profession window is open.
- Best-effort recipe output and reagent capture when the client exposes TradeSkill schematic data.
- Guild sharing of crafter, profession and recipe records.
- Recipe search by output, recipe name, profession or crafter.
- Crafting request broadcast using /tcd request <item>.
- Guild request list.
- Commands: /tcd, /tcd scan, /tcd sync, /tcd request <item>, /tcd status, /tcd help.

## Install
1. Download the ZIP from GitHub Actions or Releases.
2. Extract TavernersCraftingDirectory into your WoW Forever AddOns folder.
3. Ensure TavernersCraftingDirectory.toc is directly inside the addon folder.
4. Enable the addon, log in, open each profession window once, then use /tcd and Share with Guild.

Every guild member who contributes needs the addon installed and must be online to share. This is not cloud storage.

## Compatibility
The TOC currently targets interface 120001. If the client marks it out of date, temporarily enable Load out of date AddOns or change the Interface value to the build reported by /dump select(4, GetBuildInfo()). The WoW Forever client build and TradeSkill API variants still need live validation. The scanner uses guarded API calls because Blizzard has changed profession APIs between client branches.

## Alpha limitations
- No live WoW Forever client test has been performed yet.
- Classic-era clients may expose different profession APIs; scanning may need a compatibility adapter after the first in-game test.
- Output names may be blank until item data is cached.
- Sync is online guild chat only.
- Main/alt linking and cloud storage are planned, not included.
- This is a test build, not a production-ready authoritative recipe database.

## Bug reports
Please include your exact client build, Lua error text, profession window state, and profession being scanned.
