local _, iNIF = ...

local function ItemPayload(link)
    if not iNIF.IsSafeValue(link) or type(link) ~= "string" then return nil end
    return link:match("|H(item:[^|]+)|h")
end

-- Keep different random properties separate, even when the item IDs match.
function iNIF.LootRollItemsMatch(first, second)
    if not iNIF.IsSafeValue(first) or not iNIF.IsSafeValue(second) then return false end
    local firstPayload, secondPayload = ItemPayload(first), ItemPayload(second)
    if firstPayload and secondPayload then return firstPayload == secondPayload end
    return iNIF.LootItemsMatch(first, second)
end

function iNIF.WarnAmbiguousLootRoll()
    iNIF.Print(iNIF.L.DuplicateRollManual)
end

local function MarkAmbiguous(rollID, roll)
    roll.ambiguousItem = true
    local wasMonitoring = roll.checkboxEnabled and roll.greedClicked
    roll.checkboxEnabled, roll.greedClicked = false, false
    local frame = roll.frame
    if not frame or frame.rollID ~= rollID then
        for _, candidate in ipairs(iNIF.GetLootRollFrames()) do
            if candidate.rollID == rollID then frame = candidate; break end
        end
    end
    if frame and frame.rollID == rollID then
        if frame.iNIF_Checkbox then frame.iNIF_Checkbox:SetChecked(false) end
        if wasMonitoring then frame:Show() end
    end
    iNIF.UpdateRollCounters(rollID)
end

function iNIF.PrepareLootRoll(rollID)
    local roll = iNIF.activeRolls[rollID]
    if not roll then return end
    roll.decisions = roll.decisions or {}
    local announce = false
    for otherID, other in pairs(iNIF.activeRolls) do
        if otherID ~= rollID and iNIF.LootRollItemsMatch(roll.itemLink, other.itemLink) then
            if not other.ambiguousItem then announce = true end
            MarkAmbiguous(otherID, other)
            MarkAmbiguous(rollID, roll)
            iNIF:DebugMsg("Identical item rolls " .. rollID .. " and " .. otherID
                .. ": chat has no copy ID; monitoring paused and counters show ?.", 3)
        end
    end
    -- CANCEL_LOOT_ROLL can follow our own choice while other players' chat is
    -- still arriving. Keep that copy from being mistaken for this new roll.
    for _, completed in ipairs(iNIF.recentlyCompletedRolls) do
        local other = completed.roll
        if GetTime() - completed.endTime <= 15 and iNIF.LootRollItemsMatch(roll.itemLink, other.itemLink) then
            if not other.ambiguousItem then announce = true end
            other.ambiguousItem = true
            MarkAmbiguous(rollID, roll)
            iNIF:DebugMsg("Roll " .. rollID .. " matches a recently closed copy; late chat remains ambiguous.", 3)
        end
    end
    if announce then iNIF.WarnAmbiguousLootRoll() end
end

-- A chat choice names an item, not a particular copy. Resolve it only when
-- exactly one roll matches. Explicit IDs may come from a roll-specific source.
function iNIF.ResolveLootDecision(playerName, itemLink, decision, explicitRollID)
    local playerKey = iNIF.GetPlayerKey(playerName)
    if not playerKey then return nil end
    local selectedID, selected
    if explicitRollID ~= nil then
        if not iNIF.IsSafeValue(explicitRollID) or type(explicitRollID) ~= "number" then return nil end
        selectedID, selected = explicitRollID, iNIF.activeRolls[explicitRollID]
        if not selected or not iNIF.LootRollItemsMatch(itemLink, selected.itemLink) then return nil end
    else
        for rollID, roll in pairs(iNIF.activeRolls) do
            if iNIF.LootRollItemsMatch(itemLink, roll.itemLink) then
                if selected or roll.ambiguousItem then
                    iNIF:DebugMsg("Ignored ambiguous " .. decision .. " chat for identical items; player "
                        .. playerName .. "; no roll copy ID.", 3)
                    return nil
                end
                selectedID, selected = rollID, roll
            end
        end
    end
    if not selected or selected.processed then return nil end
    selected.decisions = selected.decisions or {}
    if selected.decisions[playerKey] then
        iNIF:DebugMsg("Ignored repeated loot choice from " .. playerName .. " for rollID " .. selectedID .. ".", 3)
        return nil
    end
    selected.decisions[playerKey] = decision
    return selectedID
end
