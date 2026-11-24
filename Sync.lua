local ADDON, TCD = ...
TCD = TCD or _G.TCD
local function Split(s,sep)
  local out={}; for part in (s..sep):gmatch("(.-)"..sep) do out[#out+1]=part end; return out
end
local function Send(msg)
  if not IsInGuild or not IsInGuild() then TCD:Print("Join a guild before syncing."); return end
  if C_ChatInfo and C_ChatInfo.SendAddonMessage then C_ChatInfo.SendAddonMessage(TCD.PREFIX,msg,"GUILD")
  elseif SendAddonMessage then SendAddonMessage(TCD.PREFIX,msg,"GUILD") end
end
function TCD:ShareProfile()
  if not self.profile then return end
  local p=self.profile
  local _,class=UnitClass("player")
  Send(table.concat({"P",self:SafeText(p.name),self:SafeText(p.realm),self:SafeText(class)},"|"))
  for _,prof in ipairs(p.professions or {}) do
    Send(table.concat({"S",self:SafeText(p.name),self:SafeText(p.realm),self:SafeText(prof.name),prof.skill or 0,prof.maxSkill or 0},"|"))
  end
  local sent=0
  for _,r in pairs(p.recipes or {}) do
    local mats={}
    for _,m in ipairs(r.reagents or {}) do mats[#mats+1]=self:SafeText(m.name or m.itemID).." x"..tostring(m.quantity or 1) end
    local msg=table.concat({"R",self:SafeText(p.name),self:SafeText(p.realm),self:SafeText(r.profession),self:SafeText(r.name),self:SafeText(r.outputName or r.name),table.concat(mats,","),tostring(r.outputCount or 1)},"|")
    if #msg<=240 then Send(msg); sent=sent+1 end
  end
  self:Print("Shared profile and "..sent.." recipes. Other members need the addon installed.")
end
function TCD:HandleAddonMessage(msg,channel,sender)
  if channel~="GUILD" or type(msg)~="string" then return end
  local f=Split(msg,"|")
  if f[1]=="HELLO" then C_Timer.After(1,function() TCD:ShareProfile() end); return end
  if f[1]=="P" and f[2] and f[3] then
    local key=f[2].."-"..f[3]
    local p=self.DB.profiles[key] or {key=key,name=f[2],realm=f[3],professions={},recipes={}}
    p.class=f[4]; p.lastSeen=time(); self.DB.profiles[key]=p
  elseif f[1]=="S" and f[2] and f[3] and f[4] then
    local key=f[2].."-"..f[3]
    local p=self.DB.profiles[key] or {key=key,name=f[2],realm=f[3],professions={},recipes={}}
    p.professions=p.professions or {}
    local updated=false
    for i,v in ipairs(p.professions) do if v.name==f[4] then p.professions[i]={name=f[4],skill=tonumber(f[5]) or 0,maxSkill=tonumber(f[6]) or 0}; updated=true end end
    if not updated then p.professions[#p.professions+1]={name=f[4],skill=tonumber(f[5]) or 0,maxSkill=tonumber(f[6]) or 0} end
    p.lastSeen=time(); self.DB.profiles[key]=p
  elseif f[1]=="R" and f[2] and f[3] and f[5] then
    local key=f[2].."-"..f[3]
    local p=self.DB.profiles[key] or {key=key,name=f[2],realm=f[3],professions={},recipes={}}
    p.recipes=p.recipes or {}
    local mats={}
    for _,v in ipairs(Split(f[7] or "",",")) do
      local n,q=v:match("^(.-) x(%d+)$")
      if n then mats[#mats+1]={name=n,quantity=tonumber(q)} end
    end
    p.recipes[f[5]..":"..f[4]]={name=f[5],profession=f[4],outputName=f[6],reagents=mats,outputCount=tonumber(f[8]) or 1,shared=true}
    p.lastSeen=time(); self.DB.profiles[key]=p
  elseif f[1]=="Q" and f[2] and f[3] and f[4] then
    self.DB.requests=self.DB.requests or {}
    table.insert(self.DB.requests,1,{player=f[2],realm=f[3],item=f[4],created=time(),sender=sender})
    while #self.DB.requests>50 do table.remove(self.DB.requests) end
    self:Print("Crafting request: "..f[2].." needs "..f[4])
  end
  if self.RefreshUI then self:RefreshUI() end
end
function TCD:CreateRequest(item)
  local _,name=self.PlayerKey()
  Send(table.concat({"Q",name,GetRealmName() or "Unknown",self:SafeText(item)},"|"))
  self:Print("Crafting request sent: "..item)
end
