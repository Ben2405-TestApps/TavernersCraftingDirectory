# Taverners Crafting Directory

Version 0.3.0-alpha | The Taverners Guild | Client target: Interface 16001 (verify against the current WoW Forever client build).

A guild recipe and crafter directory. Members install the addon, scan their professions, then share records through guild addon messages.

## Guild features in this alpha
- Crafter profiles and profession skill records shared between online guild members.
- Guild-wide recipe search across profiles received by your character.
- /tcd sync asks online addon users to share their current profile and shares your own.
- Main/alt linking with /tcd alt <main character name> and /tcd unalt.
- Guild crafting requests with /tcd request <item>.
- Requests are stored locally, shared to online addon users, and can be marked complete with /tcd done <request ID>.
- Online/offline status is checked against the guild roster.
- Addon messages are queued to reduce message bursts.
- Recipe scanner attempts to capture output and reagents where the client exposes TradeSkill schematic data.

## Install and first test
1. Download the ZIP from GitHub Actions.
2. Extract TavernersCraftingDirectory into your WoW Forever AddOns folder.
3. Enable the addon and log in.
4. Open each profession window and allow the scan to run, or use /tcd scan.
5. Open /tcd, then select Share with Guild or run /tcd sync.
6. Ask another guild member with the addon installed to run /tcd sync too.

Every member contributing data needs the addon installed and must be online for the initial exchange. Profiles received by your character are saved locally. There is no central server or automatic cross-account cloud database.

## Main and alt characters
Log in to the alt and use /tcd alt MainCharacterName. The main character needs to have a profile in your local directory first (log into it with the addon and sync). Use /tcd unalt to remove the link. Alt links are shared with addon users in the guild.

## Requests
Use /tcd request Primal Life to post a request. The Requests view lists open and completed requests. Use /tcd done <request ID> to mark one complete; request IDs are shown in the Requests view.

## Compatibility and limitations
- This alpha has not yet been tested in the live WoW Forever client.
- The client interface number and profession API branch must be confirmed in-game.
- Profession scanning may need adjustment if the client uses different Classic-era TradeSkill APIs.
- Some item names may remain blank until the client has cached item data.
- Guild sharing requires all participating members to have this addon installed and be online during exchange.
- Online/offline status depends on the guild roster API.
- Main/alt links are a convenience directory association, not a secure account identity check.
- No cloud storage, remote web dashboard, or automatic guild-wide persistent database exists yet.

## Commands
/tcd | /tcd scan | /tcd sync | /tcd request <item> | /tcd alt <main name> | /tcd unalt | /tcd done <request ID> | /tcd status | /tcd help

## Test feedback
Please report the exact client build, Lua error text, whether the profession window was open, and which other guild member was online during sync.
