local ADDON, TCD = ...
TCD = TCD or _G.TCD

local function NewID()
  local _,name,realm=TCD.PlayerKey()
  return tostring(time()).."-"..(name or "Crafter").."-"..math.random(100,999)
end

function TCD:InitFeatures()
  local db=self.DB
  db.wishlist=db.wishlist or {}
  db.crafterStats=db.crafterStats or {}
  db.crafterNotes=db.crafterNotes or {}
  db.filters=db.filters or {profession="All",onlineOnly=false}
  db.featureVersion=1
end

function TCD:AddWishlist(item, quantity)
  item=self:SafeText(item)
  if item=="" then return end
  local _,name,realm=self.PlayerKey()
  local entry={id=NewID(),item=item,quantity=math.max(1,tonumber(quantity) or 1),player=name,realm=realm,created=time(),status="wanted"}
  table.insert(self.DB.wishlist,1,entry)
  while #self.DB.wishlist>100 do table.remove(self.DB.wishlist) end
  self:SendGuildPacket(table.concat({"W",entry.id,self:SafeText(name),self:SafeText(realm),item,tostring(entry.quantity)},"|"))
  self:Print("Added "..item.." to the guild recipe wishlist.")
  if self.RefreshUI then self:RefreshUI() end
end

function TCD:ClaimRequest(id)
  local found
  for _,r in ipairs(self.DB.requests or {}) do
    if r.id==id and r.status~="completed" then
      r.status="claimed"; r.claimedBy=self.profile.name; r.claimedAt=time(); found=r; break
    end
  end
  if not found then self:Print("Open request not found."); return end
  self:SendGuildPacket(table.concat({"C",self:SafeText(found.id),self:SafeText(self.profile.name),self:SafeText(self.profile.realm)},"|"))
  self:Print("You claimed: "..found.item)
  if self.RefreshUI then self:RefreshUI() end
end

function TCD:AddCommendation(characterKey)
  if not characterKey or characterKey=="" then return end
  local stats=self.DB.crafterStats[characterKey] or {commendations=0,completed=0}
  stats.commendations=(stats.commendations or 0)+1
  stats.lastCommended=time()
  self.DB.crafterStats[characterKey]=stats
  self:SendGuildPacket(table.concat({"K",self:SafeText(characterKey),tostring(stats.commendations)},"|"))
  self:Print("Commendation recorded for "..(self.DB.profiles[characterKey] and self.DB.profiles[characterKey].name or characterKey)..".")
end

function TCD:SetCrafterNote(characterKey,note)
  if not characterKey or characterKey=="" then return end
  note=self:SafeText(note)
  self.DB.crafterNotes[characterKey]=note
  self:SendGuildPacket(table.concat({"N",self:SafeText(characterKey),note},"|"))
  if self.RefreshUI then self:RefreshUI() end
end

function TCD:HandleFeaturePacket(f)
  local kind=f[1]
  if kind=="W" and f[2] and f[5] then
    local exists=false
    for _,v in ipairs(self.DB.wishlist) do if v.id==f[2] then exists=true end end
    if not exists then
      table.insert(self.DB.wishlist,1,{id=f[2],player=f[3],realm=f[4],item=f[5],quantity=tonumber(f[6]) or 1,created=time(),status="wanted",shared=true})
      while #self.DB.wishlist>100 do table.remove(self.DB.wishlist) end
      self:Print("Wishlist: "..f[3].." is looking for "..f[5])
    end
  elseif kind=="C" and f[2] then
    for _,r in ipairs(self.DB.requests) do
      if r.id==f[2] and r.status~="completed" then
        r.status="claimed"; r.claimedBy=f[3]; r.claimedRealm=f[4]; r.claimedAt=time()
      end
    end
  elseif kind=="K" and f[2] then
    local stats=self.DB.crafterStats[f[2]] or {commendations=0,completed=0}
    stats.commendations=math.max(stats.commendations or 0,tonumber(f[3]) or 0)
    self.DB.crafterStats[f[2]]=stats
  elseif kind=="N" and f[2] then
    self.DB.crafterNotes[f[2]]=f[3] or ""
  end
end

function TCD:GetDashboardStats()
  local profiles,recipes,professions,open,wanted=0,0,0,0,0
  local seenProf={}
  for _,p in pairs(self.DB.profiles or {}) do
    profiles=profiles+1
    for _,r in pairs(p.recipes or {}) do recipes=recipes+1 end
    for _,v in ipairs(p.professions or {}) do seenProf[v.name]=true end
  end
  for _ in pairs(seenProf) do professions=professions+1 end
  for _,r in ipairs(self.DB.requests or {}) do if r.status~="completed" then open=open+1 end end
  for _,w in ipairs(self.DB.wishlist or {}) do if w.status=="wanted" then wanted=wanted+1 end end
  return {profiles=profiles,recipes=recipes,professions=professions,openRequests=open,wishlist=wanted}
end

function TCD:FindRecipe(item)
  local q=(item or ""):lower()
  for key,p in pairs(self.DB.profiles or {}) do
    for _,r in pairs(p.recipes or {}) do
      if (r.outputName or r.name or ""):lower():find(q,1,true) then return r,p,key end
    end
  end
end

function TCD:GetMaterialSummary(item,quantity)
  local r,p,key=self:FindRecipe(item)
  if not r then return nil,"No matching recipe is currently in the directory." end
  local multiplier=math.max(1,tonumber(quantity) or 1)
  local batches=math.ceil(multiplier/math.max(1,tonumber(r.outputCount) or 1))
  local result={}
  for _,m in ipairs(r.reagents or {}) do
    result[#result+1]={name=m.name or ("Item "..tostring(m.itemID or "?")),quantity=(tonumber(m.quantity) or 1)*batches}
  end
  return {recipe=r,profile=p,key=key,materials=result,batches=batches}
end

function TCD:ExportDirectory()
  local lines={"TAVERNERS-CRAFTING-DIRECTORY|1","Exported|"..tostring(time())}
  for key,p in pairs(self.DB.profiles or {}) do
    lines[#lines+1]=table.concat({"P",self:SafeText(key),self:SafeText(p.name),self:SafeText(p.realm)},"|")
    for _,prof in ipairs(p.professions or {}) do
      lines[#lines+1]=table.concat({"S",self:SafeText(key),self:SafeText(prof.name),tostring(prof.skill or 0),tostring(prof.maxSkill or 0)},"|")
    end
    for _,r in pairs(p.recipes or {}) do
      local mats={}
      for _,m in ipairs(r.reagents or {}) do mats[#mats+1]=self:SafeText(m.name).." x"..tostring(m.quantity or 1) end
      lines[#lines+1]=table.concat({"R",self:SafeText(key),self:SafeText(r.profession),self:SafeText(r.name),self:SafeText(r.outputName or r.name),table.concat(mats,","),tostring(r.outputCount or 1)},"|")
    end
  end
  for _,r in ipairs(self.DB.requests or {}) do
    lines[#lines+1]=table.concat({"Q",self:SafeText(r.id),self:SafeText(r.player),self:SafeText(r.realm),self:SafeText(r.item),self:SafeText(r.status)},"|")
  end
  for _,w in ipairs(self.DB.wishlist or {}) do
    lines[#lines+1]=table.concat({"W",self:SafeText(w.id),self:SafeText(w.player),self:SafeText(w.realm),self:SafeText(w.item),tostring(w.quantity or 1)},"|")
  end
  return table.concat(lines,"\n")
end

function TCD:ShowExport()
  if not self.ExportFrame then
    local f=CreateFrame("Frame","TCDExportFrame",UIParent,"BasicFrameTemplateWithInset")
    f:SetSize(620,390); f:SetPoint("CENTER"); f:SetFrameStrata("DIALOG")
    f.title= f:CreateFontString(nil,"OVERLAY","GameFontHighlight"); f.title:SetPoint("TOP",0,-8); f.title:SetText("Taverners Directory Backup")
    local hint=f:CreateFontString(nil,"OVERLAY","GameFontNormalSmall"); hint:SetPoint("TOPLEFT",14,-34); hint:SetText("Select all and copy this backup text into a safe document.")
    local scroll=CreateFrame("ScrollFrame",nil,f,"UIPanelScrollFrameTemplate"); scroll:SetPoint("TOPLEFT",14,-58); scroll:SetPoint("BOTTOMRIGHT",-34,14)
    local edit=CreateFrame("EditBox",nil,scroll); edit:SetMultiLine(true); edit:SetAutoFocus(false); edit:SetFontObject(ChatFontNormal); edit:SetWidth(550); edit:SetScript("OnEscapePressed",function() f:Hide() end)
    scroll:SetScrollChild(edit); f.edit=edit; self.ExportFrame=f
  end
  self.ExportFrame.edit:SetText(self:ExportDirectory())
  self.ExportFrame:Show()
end
