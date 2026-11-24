local ADDON, TCD = ...
TCD = TCD or _G.TCD
local function Split(s,sep)
  local out={}; for part in (s..sep):gmatch("(.-)"..sep) do out[#out+1]=part end; return out
end
TCD.SendQueue = TCD.SendQueue or {}
local queueRunning=false
function TCD:SendGuildPacket(message)
  if not IsInGuild or not IsInGuild() then self:Print("Join a guild before syncing."); return false end
  if type(message)~="string" or #message>240 then self:Print("A sync record was too long and was skipped."); return false end
  table.insert(self.SendQueue,message)
  if not queueRunning then
    queueRunning=true
    local function Pump()
      local nextMessage=table.remove(TCD.SendQueue,1)
      if nextMessage then
        if C_ChatInfo and C_ChatInfo.SendAddonMessage then C_ChatInfo.SendAddonMessage(TCD.PREFIX,nextMessage,"GUILD")
        elseif SendAddonMessage then SendAddonMessage(TCD.PREFIX,nextMessage,"GUILD") end
        C_Timer.After(0.35,Pump)
      else queueRunning=false end
    end
    C_Timer.After(0.1,Pump)
  end
  return true
end
function TCD:RequestGuildSync()
  if not IsInGuild or not IsInGuild() then self:Print("You need to be in a guild to sync."); return end
  self:SendGuildPacket("H")
  self:ShareProfile()
  self:Print("Guild sync requested. Online members with the addon will share their profiles.")
end
function TCD:ShareProfile()
  if not self.profile then return end
  local p=self.profile; local _,class=UnitClass("player")
  self:SendGuildPacket(table.concat({"P",self:SafeText(p.key),self:SafeText(p.name),self:SafeText(p.realm),self:SafeText(class)},"|"))
  for _,prof in ipairs(p.professions or {}) do self:SendGuildPacket(table.concat({"S",self:SafeText(p.key),self:SafeText(prof.name),prof.skill or 0,prof.maxSkill or 0},"|")) end
  local sent=0
  for _,r in pairs(p.recipes or {}) do
    local mats={}; for _,m in ipairs(r.reagents or {}) do mats[#mats+1]=self:SafeText(m.name or m.itemID).." x"..tostring(m.quantity or 1) end
    local msg=table.concat({"R",self:SafeText(p.key),self:SafeText(r.profession),self:SafeText(r.name),self:SafeText(r.outputName or r.name),table.concat(mats,","),tostring(r.outputCount or 1)},"|")
    if self:SendGuildPacket(msg) then sent=sent+1 end
  end
  self:SendGuildPacket(table.concat({"A",self:SafeText(self.currentKey),self:SafeText(self.DB.altLinks[self.currentKey] or "")},"|"))
  self:Print("Queued your profile and "..sent.." recipe records for guild sharing.")
end
function TCD:HandleAddonMessage(msg,channel,sender)
  if channel~="GUILD" or type(msg)~="string" then return end
  local f=Split(msg,"|"); local kind=f[1]
  if kind=="H" then self:ShareProfile(); return
  elseif kind=="P" and f[2] and f[3] then
    local key=f[2]; local p=self.DB.profiles[key] or {key=key,professions={},recipes={}}
    p.key=key; p.name=f[3]; p.realm=f[4]; p.class=f[5]; p.lastSeen=time(); p.lastSender=sender; self.DB.profiles[key]=p
  elseif kind=="S" and f[2] and f[3] then
    local key=f[2]; local p=self.DB.profiles[key] or {key=key,professions={},recipes={}}
    p.professions=p.professions or {}; local found=false
    for i,v in ipairs(p.professions) do if v.name==f[3] then p.professions[i]={name=f[3],skill=tonumber(f[4]) or 0,maxSkill=tonumber(f[5]) or 0}; found=true; break end end
    if not found then p.professions[#p.professions+1]={name=f[3],skill=tonumber(f[4]) or 0,maxSkill=tonumber(f[5]) or 0} end
    p.lastSeen=time(); self.DB.profiles[key]=p
  elseif kind=="R" and f[2] and f[4] then
    local key=f[2]; local p=self.DB.profiles[key] or {key=key,professions={},recipes={}}
    p.recipes=p.recipes or {}; local mats={}
    for _,v in ipairs(Split(f[6] or "",",")) do local n,q=v:match("^(.-) x(%d+)$"); if n then mats[#mats+1]={name=n,quantity=tonumber(q)} end end
    p.recipes[f[4]..":"..(f[3] or "")]={name=f[4],profession=f[3],outputName=f[5],reagents=mats,outputCount=tonumber(f[7]) or 1,shared=true}
    p.lastSeen=time(); self.DB.profiles[key]=p
  elseif kind=="A" and f[2] then
    if f[3] and f[3]~="" then self.DB.altLinks[f[2]]=f[3] else self.DB.altLinks[f[2]]=nil end
  elseif kind=="Q" and f[2] and f[3] and f[4] and f[5] then
    self.DB.requests=self.DB.requests or {}; local exists=false
    for _,r in ipairs(self.DB.requests) do if r.id==f[2] then exists=true; break end end
    if not exists then table.insert(self.DB.requests,1,{id=f[2],player=f[3],realm=f[4],item=f[5],created=time(),status="open",sender=sender}); while #self.DB.requests>50 do table.remove(self.DB.requests) end; self:Print("Crafting request from "..f[3]..": "..f[5]) end
  elseif kind=="D" and f[2] then
    for _,r in ipairs(self.DB.requests or {}) do if r.id==f[2] then r.status="completed"; r.completed=time() end end
  end
  if self.RefreshUI then self:RefreshUI() end
end
function TCD:CreateRequest(item)
  item=self:SafeText(item); if item=="" then return end
  local _,name,realm=self.PlayerKey(); local id=tostring(time()).."-"..name
  local request={id=id,player=name,realm=realm,item=item,created=time(),status="open"}
  table.insert(self.DB.requests,1,request); while #self.DB.requests>50 do table.remove(self.DB.requests) end
  self:SendGuildPacket(table.concat({"Q",id,self:SafeText(name),self:SafeText(realm),item},"|"))
  self:Print("Crafting request posted to the guild: "..item)
  if self.RefreshUI then self:RefreshUI() end
end
function TCD:CompleteRequest(id)
  local found
  for _,r in ipairs(self.DB.requests or {}) do if r.id==id or (r.id and r.id:find(id,1,true)) then r.status="completed"; r.completed=time(); found=r; break end end
  if not found then self:Print("Request ID not found. Check the Requests view."); return end
  self:SendGuildPacket("D|"..self:SafeText(found.id))
  self:Print("Request marked complete: "..found.item)
  if self.RefreshUI then self:RefreshUI() end
end
