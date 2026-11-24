# Taverners Crafting Directory
Version 0.4.0-alpha | The Taverners Guild | Interface 16001 (confirm against the live WoW Forever client).

The Taverners Crafting Hall is a guild-shared crafter and recipe directory with request coordination, wishlists, recognition, material summaries and portable text backups.

## Features
- Crafter profiles, profession skill levels and recipe records.
- Guild-wide recipe search. Search supports `prof:Tailoring` to filter by profession.
- Guild sync for profiles, recipes, wishlists, notes and recognition totals.
- Main/alt links.
- Crafting request board with open, claimed and completed states.
- Recipe wishlist shared with online addon users.
- Material requirement estimates based on the recipe data currently recorded by the addon.
- Crafter commendations and completed-request contribution counters.
- Crafter notes stored and synchronised.
- Hall dashboard with profile, recipe, profession, request and wishlist totals.
- Backup/export window containing a portable text snapshot of the directory.

## Commands
- `/tcd` open the directory
- `/tcd scan` scan the open profession
- `/tcd sync` exchange available data with online guild members running the addon
- `/tcd request <item>` post a crafting request
- `/tcd claim <request ID>` claim a request
- `/tcd done <request ID>` mark a request complete
- `/tcd wishlist <item> [quantity]` add a recipe/item to the wishlist
- `/tcd materials <item> [quantity]` show known materials needed
- `/tcd commend <crafter name>` record a commendation
- `/tcd export` open the text backup window
- `/tcd alt <main name>` and `/tcd unalt` manage alt links
- `/tcd status` show local directory counts
- `/tcd help` show commands

## Installation and use
1. Extract the addon folder into WoW Forever's AddOns directory.
2. Enable it at character select.
3. Open each profession and run `/tcd scan`.
4. Run `/tcd sync` while guild members with the addon are online.
5. Use the Hall, Requests and Wishlist views in the main window.

## Important data and compatibility notes
- This alpha has not been tested in the live WoW Forever client.
- The scanner depends on profession APIs exposed by the client; recipe/material coverage may vary.
- Guild addon messages only reach members who are online, in the same guild, and running this addon. Sync is peer-to-peer, not a server.
- Each character stores its own local saved variables. Received information remains local to that installation until shared onward.
- The backup window currently provides a human-readable portable text export. It is not yet an automatic cloud backup or one-click restore format.
- Material summaries are estimates based on known reagent data and may not represent optional reagents or alternative crafting choices.
- Commendations and contribution counters are community signals, not verified transaction records.
- Main/alt links are directory associations, not secure account identity verification.
- Interface number 16001 must be confirmed against the current live client.

## Testing feedback
Please provide the exact WoW Forever client build and any Lua error text/stack trace. Test with at least two guild members online and running the same addon version.
