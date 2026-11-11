# Loot-roll regression checks

Run duplicate_rolls.lua from the addon directory with a Lua interpreter.
It loads the production Main, RollLogic, RollTracking and Frames files.

Checks cover repeated loot/system messages, local and remote player choices,
two identical simultaneous drops, different properties on the same item ID,
manual Greed button behaviour, monitoring cancellation, late chat after a local
choice, winner/receipt deduplication, Luck Tracker being disabled, and normal
single-item automatic Need/Greed.

An item link does not identify a copy when two links are identical. These rolls
display ? counters and use manual choices; they are never assigned by table
iteration order or by assuming which copy a player selected first. A recently
closed copy is retained for 15 seconds to stop late chat changing a new roll.

The release workflow excludes tests from the package. No tests access WoW or
send messages to another player. Identical drops still need an in-game check
to confirm frame visibility and event timing on the client.
