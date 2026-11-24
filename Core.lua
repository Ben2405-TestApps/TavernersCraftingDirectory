local ADDON, TCD = ...
TCD = TCD or {}
_G.TCD = TCD
TCD.VERSION = "0.4.0-alpha"
TCD.PREFIX = "TCDIR"
TCD.DB_VERSION = 3
TCD.Colors = {gold={0.88,0.68,0.28},parchment={0.91,0.84,0.67},muted={0.72,0.66,0.53},green={0.35,0.78,0.42},red={0.85,0.38,0.30}}
local function PlayerKey()
  local name, realm
  if UnitFullName then name, realm = UnitFullName("player") end
  name = name or UnitName("player")
  realm = realm or GetRealmName() or "Unknown"
  return name .. "-" .. realm, name, realm
end
TCD.PlayerKey = PlayerKey
function TCD:Print(msg) DEFAULT_CHAT_FRAME:AddMessage("|cffd9a441[Taverners]|r " .. tostring(msg)) end
function TCD:SafeText(v) return tostring(v or ""):gsub("|","/"):gsub("[\r\n]"," "):gsub(";","/") end
function TCD:InitDB()
  if type(TavernersCraftingDB) ~= "table" then TavernersCraftingDB = {} end
  self.DB = TavernersCraftingDB
  self.DB.version = self.DB_VERSION
  self.DB.profiles = self.DB.profiles or {}
  self.DB.requests = self.DB.requests or {}
  self.DB.altLinks = self.DB.altLinks or {}
  self.DB.settings = self.DB.settings or {shareOnLogin=false}
  if self.InitFeatures then self:InitFeatures() end
  local key,name,realm = PlayerKey()
  self.DB.profiles[key] = self.DB.profiles[key] or {key=key,name=name,realm=realm,professions={},recipes={}}
  self.profile = self.DB.profiles[key]
  self.profile.professions = self.profile.professions or {}
  self.profile.recipes = self.profile.recipes or {}
  self.currentKey = key
end
function TCD:OnEvent(event,...)
  if event == "ADDON_LOADED" then
    local loaded = ...
    if loaded ~= ADDON then return end
    self:InitDB()
    if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then C_ChatInfo.RegisterAddonMessagePrefix(self.PREFIX) end
    self:Print("Crafting Directory " .. self.VERSION .. " loaded. Type /tcd.")
    self:RefreshProfessionData()
    if self.DB.settings.shareOnLogin then C_Timer.After(8,function() TCD:RequestGuildSync() end) end
  elseif event == "PLAYER_LOGIN" then
    C_Timer.After(3,function() TCD:RefreshProfessionData(); if GuildRoster then GuildRoster() end; TCD:RefreshGuildRoster() end)
  elseif event == "CHAT_MSG_ADDON" then
    local prefix,msg,channel,sender = ...
    if prefix == self.PREFIX then self:HandleAddonMessage(msg,channel,sender) end
  elseif event == "TRADE_SKILL_SHOW" or event == "TRADE_SKILL_LIST_UPDATE" then
    C_Timer.After(0.6,function() TCD:ScanOpenProfession() end)
  elseif event == "GUILD_ROSTER_UPDATE" then
    self:RefreshGuildRoster()
    if self.RefreshUI then self:RefreshUI() end
  end
end
local ev = CreateFrame("Frame")
TCD.EventFrame = ev
for _,name in ipairs({"ADDON_LOADED","PLAYER_LOGIN","CHAT_MSG_ADDON","GUILD_ROSTER_UPDATE","TRADE_SKILL_SHOW","TRADE_SKILL_LIST_UPDATE"}) do pcall(function() ev:RegisterEvent(name) end) end
ev:SetScript("OnEvent",function(_,event,...) TCD:OnEvent(event,...) end)
SLASH_TAVERNERSCRAFTINGDIRECTORY1="/tcd"
SLASH_TAVERNERSCRAFTINGDIRECTORY2="/taverners"
SlashCmdList.TAVERNERSCRAFTINGDIRECTORY=function(msg)
  local cmd,rest=(msg or ""):match("^(%S*)%s*(.-)$")
  cmd=(cmd or ""):lower()
  if cmd=="scan" then TCD:RefreshProfessionData(); TCD:ScanOpenProfession()
  elseif cmd=="sync" then TCD:RequestGuildSync()
  elseif cmd=="request" and rest~="" then TCD:CreateRequest(rest)
  elseif cmd=="alt" and rest~="" then TCD:SetMainCharacter(rest)
  elseif cmd=="unalt" then TCD:ClearMainCharacter()
  elseif cmd=="done" and rest~="" then TCD:CompleteRequest(rest)
  elseif cmd=="wishlist" and rest~="" then local item,qty=rest:match("^(.-)%s+(%d+)$"); TCD:AddWishlist(item or rest,qty)
  elseif cmd=="claim" and rest~="" then TCD:ClaimRequest(rest)
  elseif cmd=="materials" and rest~="" then local item,qty=rest:match("^(.-)%s+(%d+)$"); local data,err=TCD:GetMaterialSummary(item or rest,qty); if data then TCD:Print("Materials for "..(item or rest)..":"); for _,m in ipairs(data.materials) do TCD:Print(m.name.." x"..m.quantity) end else TCD:Print(err) end
  elseif cmd=="commend" and rest~="" then local wanted=rest:lower(); for key,p in pairs(TCD.DB.profiles) do if key:lower()==wanted or (p.name or ""):lower()==wanted then TCD:AddCommendation(key); return end end; TCD:Print("Crafter profile not found.")
  elseif cmd=="export" then TCD:ShowExport()
  elseif cmd=="status" then
    local n,p=0,0; for _ in pairs(TCD.profile.recipes or {}) do n=n+1 end; for _ in pairs(TCD.DB.profiles or {}) do p=p+1 end
    TCD:Print(n.." recipes on this character; "..p.." crafter profiles stored.")
  elseif cmd=="help" then TCD:Print("/tcd | scan | sync | request <item> | wishlist <item> [qty] | claim <request ID> | materials <item> [qty] | commend <crafter> | export | alt <main> | unalt | done <request ID> | status")
  else TCD:ToggleUI() end
end
