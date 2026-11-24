local ADDON, TCD = ...
TCD = TCD or _G.TCD
local Core = _G.TavernersCore

function TCD:RefreshGuildRoster()
  Core.Guild:RefreshRoster()
  self.GuildOnline = Core.Guild.online
end
function TCD:IsProfileOnline(profile)
  return profile and Core.Guild:IsOnline(profile.name) or false
end
function TCD:GetMainKey(key)
  return Core.Profiles:GetMainKey(self.DB, key)
end
function TCD:GetAltKeys(mainKey)
  return Core.Profiles:GetAltKeys(self.DB, mainKey)
end
function TCD:SetMainCharacter(mainName)
  local wanted = Core.Identity:ShortName(mainName)
  local found
  for key, profile in pairs(self.DB.profiles or {}) do
    if key:lower() == mainName:lower() or (profile.name or ""):lower() == wanted then found = key; break end
  end
  if not found then
    self:Print("No saved profile found for " .. mainName .. ". Log into that character with the addon and sync it first.")
    return
  end
  if found == self.currentKey then self:ClearMainCharacter(); return end
  Core.Profiles:Link(self.DB, self.currentKey, found)
  self:BroadcastAltLink()
  self:Print(self.profile.name .. " is now linked as an alt of " .. (self.DB.profiles[self:GetMainKey(found)].name or found) .. ".")
  if self.RefreshUI then self:RefreshUI() end
end
function TCD:ClearMainCharacter()
  Core.Profiles:Unlink(self.DB, self.currentKey)
  self:BroadcastAltLink()
  self:Print("Main/alt link cleared for this character.")
  if self.RefreshUI then self:RefreshUI() end
end
function TCD:BroadcastAltLink()
  if self.SendGuildPacket then
    self:SendGuildPacket(table.concat({"A", self:SafeText(self.currentKey), self:SafeText(self.DB.altLinks[self.currentKey] or "")}, "|"))
  end
end
