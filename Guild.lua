local ADDON, TCD = ...
TCD = TCD or _G.TCD
local function ShortName(name)
  if not name then return nil end
  return (name:match("^([^%-]+)") or name):lower()
end
function TCD:RefreshGuildRoster()
  self.GuildOnline = {}
  if not IsInGuild or not IsInGuild() then return end
  if not GetNumGuildMembers or not GetGuildRosterInfo then return end
  for i=1,GetNumGuildMembers() do
    local name,_,_,_,_,_,_,_,online = GetGuildRosterInfo(i)
    if name then self.GuildOnline[ShortName(name)]=online and true or false; self.GuildOnline[name:lower()]=online and true or false end
  end
end
function TCD:IsProfileOnline(profile)
  if not profile then return false end
  local short=ShortName(profile.name)
  return short and self.GuildOnline and (self.GuildOnline[short] or self.GuildOnline[(profile.name or ""):lower()]) or false
end
function TCD:GetMainKey(key)
  local seen={}
  while self.DB.altLinks[key] and not seen[key] do seen[key]=true; key=self.DB.altLinks[key] end
  return key
end
function TCD:GetAltKeys(mainKey)
  local result={}; mainKey=self:GetMainKey(mainKey)
  for alt,target in pairs(self.DB.altLinks or {}) do if self:GetMainKey(target)==mainKey then result[#result+1]=alt end end
  table.sort(result); return result
end
function TCD:SetMainCharacter(mainName)
  local wanted=ShortName(mainName); local found
  for key,p in pairs(self.DB.profiles or {}) do
    if key:lower()==mainName:lower() or (p.name or ""):lower()==wanted then found=key; break end
  end
  if not found then self:Print("No saved profile found for "..mainName..". Log into that character with the addon and sync it first."); return end
  if found==self.currentKey then self:ClearMainCharacter(); return end
  self.DB.altLinks[self.currentKey]=self:GetMainKey(found)
  self:BroadcastAltLink()
  self:Print(self.profile.name.." is now linked as an alt of "..(self.DB.profiles[self:GetMainKey(found)].name or found)..".")
  if self.RefreshUI then self:RefreshUI() end
end
function TCD:ClearMainCharacter()
  self.DB.altLinks[self.currentKey]=nil
  self:BroadcastAltLink()
  self:Print("Main/alt link cleared for this character.")
  if self.RefreshUI then self:RefreshUI() end
end
function TCD:BroadcastAltLink()
  if self.SendGuildPacket then self:SendGuildPacket(table.concat({"A",self:SafeText(self.currentKey),self:SafeText(self.DB.altLinks[self.currentKey] or "")},"|")) end
end
