local ADDON, TCD = ...
TCD = TCD or {}
_G.TCD = TCD
TCD.VERSION = "0.2.0-alpha"
TCD.PREFIX = "TCDIR"
TCD.DB_VERSION = 2
TCD.Colors = {gold={0.88,0.68,0.28},parchment={0.91,0.84,0.67},muted={0.72,0.66,0.53}}

local function PlayerKey()
  local name, realm = UnitFullName and UnitFullName("player")
  name = name or UnitName("player")
  realm = realm or GetRealmName() or "Unknown"
  return name .. "-" .. realm, name, realm
end
TCD.PlayerKey = PlayerKey

function TCD:Print(msg)
  DEFAULT_CHAT_FRAME:AddMessage("|cffd9a441[Taverners]|r " .. tostring(msg))
end
function TCD:SafeText(v)
  return tostring(v or ""):gsub("|","/"):gsub("[\r\n]"," ")
end
function TCD:InitDB()
  if type(TavernersCraftingDB) ~= "table" then TavernersCraftingDB = {} end
  self.DB = TavernersCraftingDB
  self.DB.profiles = self.DB.profiles or {}
  self.DB.requests = self.DB.requests or {}
  self.DB.settings = self.DB.settings or {shareOnLogin=false}
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
    if self.DB.settings.shareOnLogin then C_Timer.After(8,function() TCD:ShareProfile() end) end
  elseif event == "PLAYER_LOGIN" then
    C_Timer.After(3,function() TCD:RefreshProfessionData() end)
  elseif event == "CHAT_MSG_ADDON" then
    local prefix,msg,channel,sender = ...
    if prefix == self.PREFIX then self:HandleAddonMessage(msg,channel,sender) end
  elseif event == "TRADE_SKILL_SHOW" or event == "TRADE_SKILL_LIST_UPDATE" then
    C_Timer.After(0.6,function() TCD:ScanOpenProfession() end)
  elseif event == "GUILD_ROSTER_UPDATE" then
    if self.RefreshUI then self:RefreshUI() end
  end
end
local ev = CreateFrame("Frame")
TCD.EventFrame = ev
for _,name in ipairs({"ADDON_LOADED","PLAYER_LOGIN","CHAT_MSG_ADDON","GUILD_ROSTER_UPDATE","TRADE_SKILL_SHOW","TRADE_SKILL_LIST_UPDATE"}) do
  pcall(function() ev:RegisterEvent(name) end)
end
ev:SetScript("OnEvent",function(_,event,...) TCD:OnEvent(event,...) end)

SLASH_TAVERNERSCRAFTINGDIRECTORY1="/tcd"
SLASH_TAVERNERSCRAFTINGDIRECTORY2="/taverners"
SlashCmdList.TAVERNERSCRAFTINGDIRECTORY=function(msg)
  local cmd,rest=(msg or ""):match("^(%S*)%s*(.-)$")
  cmd=(cmd or ""):lower()
  if cmd=="scan" then TCD:RefreshProfessionData(); TCD:ScanOpenProfession()
  elseif cmd=="sync" then TCD:ShareProfile()
  elseif cmd=="request" and rest~="" then TCD:CreateRequest(rest)
  elseif cmd=="status" then
    local n=0; for _ in pairs(TCD.profile.recipes or {}) do n=n+1 end
    TCD:Print(n .. " recipes saved. Open a profession window and use /tcd scan.")
  elseif cmd=="help" then TCD:Print("/tcd opens the directory; /tcd scan; /tcd sync; /tcd request <item>; /tcd status")
  else TCD:ToggleUI() end
end
