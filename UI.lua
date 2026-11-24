local ADDON, TCD = ...
TCD = TCD or _G.TCD
local function Text(parent,size,value,color)
  local fs=parent:CreateFontString(nil,"OVERLAY","GameFontNormal")
  fs:SetFont("Fonts\\FRIZQT__.TTF",size or 12,"")
  fs:SetText(value or "")
  if color then fs:SetTextColor(color[1],color[2],color[3]) end
  return fs
end
local function MakePanel(parent,w,h)
  local f=CreateFrame("Frame",nil,parent,"BackdropTemplate")
  f:SetSize(w,h)
  f:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",tile=true,tileSize=32,edgeSize=24,insets={left=8,right=8,top=8,bottom=8}})
  f:SetBackdropColor(0.12,0.085,0.055,0.96)
  return f
end
local function Btn(parent,label,w,fn)
  local b=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate"); b:SetSize(w,24); b:SetText(label); b:SetScript("OnClick",fn); return b
end
function TCD:CreateUI()
  if self.UI then return end
  local f=MakePanel(UIParent,760,520); f:SetPoint("CENTER"); f:SetMovable(true); f:EnableMouse(true); f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart",f.StartMoving); f:SetScript("OnDragStop",f.StopMovingOrSizing); f:SetClampedToScreen(true); f:Hide(); self.UI=f
  local title=Text(f,20,"THE TAVERNERS  •  CRAFTING DIRECTORY",self.Colors.gold); title:SetPoint("TOP",0,-22)
  local sub=Text(f,11,"A guild ledger of skilled hands, recipes and requests",self.Colors.muted); sub:SetPoint("TOP",title,"BOTTOM",0,-5)
  local close=CreateFrame("Button",nil,f,"UIPanelCloseButton"); close:SetPoint("TOPRIGHT",-7,-7)
  local left=MakePanel(f,220,420); left:SetPoint("TOPLEFT",18,-72)
  local right=MakePanel(f,490,420); right:SetPoint("TOPRIGHT",-18,-72)
  local head=Text(left,14,"Guild Crafters",self.Colors.gold); head:SetPoint("TOPLEFT",16,-16)
  local scan=Btn(left,"Scan Open Profession",185,function() TCD:RefreshProfessionData(); TCD:ScanOpenProfession(); TCD:RefreshUI() end); scan:SetPoint("TOPLEFT",16,-43)
  local sync=Btn(left,"Sync with Guild",185,function() TCD:RequestGuildSync() end); sync:SetPoint("TOPLEFT",scan,"BOTTOMLEFT",0,-6)
  local alt=CreateFrame("EditBox",nil,left,"InputBoxTemplate"); alt:SetSize(118,24); alt:SetPoint("TOPLEFT",16,-105); alt:SetAutoFocus(false); alt:SetText("")
  alt:SetScript("OnEnterPressed",function(self) TCD:SetMainCharacter(self:GetText()); self:ClearFocus() end)
  local link=Btn(left,"Link",55,function() TCD:SetMainCharacter(alt:GetText()) end); link:SetPoint("LEFT",alt,"RIGHT",5,0)
  local unlink=Btn(left,"Unlink",185,function() TCD:ClearMainCharacter() end); unlink:SetPoint("TOPLEFT",16,-134)
  local cs=CreateFrame("ScrollFrame",nil,left,"UIPanelScrollFrameTemplate"); cs:SetPoint("TOPLEFT",12,-166); cs:SetPoint("BOTTOMRIGHT",-30,14)
  local cc=CreateFrame("Frame",nil,cs); cc:SetSize(175,1); cs:SetScrollChild(cc); self.CrafterContent=cc
  local search=CreateFrame("EditBox",nil,right,"InputBoxTemplate"); search:SetSize(170,24); search:SetPoint("TOPLEFT",16,-16); search:SetAutoFocus(false); search:SetScript("OnTextChanged",function() TCD.CurrentView="recipes"; TCD:RefreshRecipes() end); self.SearchBox=search
  local all=Btn(right,"All",55,function() TCD.CurrentView="recipes"; TCD.selectedCrafter=nil; TCD:RefreshUI() end); all:SetPoint("LEFT",search,"RIGHT",10,0)
  local requests=Btn(right,"Requests",65,function() TCD:ShowRequests() end); requests:SetPoint("LEFT",all,"RIGHT",5,0)
  local wishlist=Btn(right,"Wishlist",65,function() TCD:ShowWishlist() end); wishlist:SetPoint("LEFT",requests,"RIGHT",5,0)
  local hall=Btn(right,"Hall",50,function() TCD:ShowDashboard() end); hall:SetPoint("TOPLEFT",16,-47)
  local backup=Btn(right,"Backup / Export",110,function() TCD:ShowExport() end); backup:SetPoint("LEFT",hall,"RIGHT",6,0)
  local rs=CreateFrame("ScrollFrame",nil,right,"UIPanelScrollFrameTemplate"); rs:SetPoint("TOPLEFT",12,-78); rs:SetPoint("BOTTOMRIGHT",-30,14)
  local rc=CreateFrame("Frame",nil,rs); rc:SetSize(430,1); rs:SetScrollChild(rc); self.RecipeContent=rc
  self:RefreshUI()
end
function TCD:RefreshCrafters()
  local c=self.CrafterContent; if not c then return end
  for _,child in ipairs({c:GetChildren()}) do child:Hide(); child:SetParent(nil) end
  local keys={}; for k in pairs(self.DB.profiles or {}) do keys[#keys+1]=k end; table.sort(keys)
  local y=-4
  for _,key in ipairs(keys) do
    local p=self.DB.profiles[key]; local n=0; for _ in pairs(p.recipes or {}) do n=n+1 end
    local b=CreateFrame("Button",nil,c); b:SetSize(170,28); b:SetPoint("TOPLEFT",2,y)
    b.text=b:CreateFontString(nil,"OVERLAY","GameFontNormal"); b.text:SetPoint("LEFT",4,0); b.text:SetJustifyH("LEFT")
    local online=TCD:IsProfileOnline(p)
    local mainKey=TCD:GetMainKey(key)
    local suffix=(mainKey~=key and " [alt]" or "")
    b.text:SetText((online and "|cff55dd66●|r " or "|cff888888○|r ")..(p.name or key)..suffix.." ("..n..")")
    if key==self.currentKey then b.text:SetTextColor(0.95,0.78,0.40) end
    b:SetScript("OnClick",function() TCD.selectedCrafter=key; TCD.CurrentView="recipes"; TCD:RefreshUI() end)
    y=y-30
  end
  c:SetHeight(math.max(1,-y+10))
end
function TCD:RefreshRecipes()
  local c=self.RecipeContent; if not c then return end
  for _,child in ipairs({c:GetChildren()}) do child:Hide(); child:SetParent(nil) end
  local query=self.SearchBox and self.SearchBox:GetText():lower() or ""
  local keys={}
  if self.selectedCrafter then keys[1]=self.selectedCrafter else for k in pairs(self.DB.profiles or {}) do keys[#keys+1]=k end end
  local rows={}
  for _,key in ipairs(keys) do
    local p=self.DB.profiles[key]
    for _,r in pairs((p and p.recipes) or {}) do
      local hay=table.concat({r.name or "",r.outputName or "",r.profession or "",p.name or ""}," "):lower()
      local profFilter=query:match("^prof:(.+)$")
      local matches=profFilter and (r.profession or ""):lower():find(profFilter,1,true) or (not profFilter and (query=="" or hay:find(query,1,true)))
      if matches then rows[#rows+1]={p=p,r=r} end
    end
  end
  table.sort(rows,function(a,b) return (a.r.outputName or a.r.name or "")<(b.r.outputName or b.r.name or "") end)
  local y=-4
  for _,row in ipairs(rows) do
    local r,p=row.r,row.p
    local box=CreateFrame("Frame",nil,c,"BackdropTemplate"); box:SetSize(420,58); box:SetPoint("TOPLEFT",2,y)
    box:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8"}); box:SetBackdropColor(0.24,0.18,0.11,0.72)
    local name=Text(box,13,r.outputName or r.name or "Unknown recipe",self.Colors.gold); name:SetPoint("TOPLEFT",9,-7)
    local detail=Text(box,10,(r.profession or "Profession").."  •  "..(p.name or "Unknown crafter"),self.Colors.parchment); detail:SetPoint("TOPLEFT",name,"BOTTOMLEFT",0,-4)
    local mats={}; for _,m in ipairs(r.reagents or {}) do mats[#mats+1]=(m.name or ("Item "..tostring(m.itemID))).." x"..tostring(m.quantity or 1) end
    local mat=Text(box,9,#mats>0 and ("Materials: "..table.concat(mats,", ")) or ("Recipe: "..(r.name or "?")),self.Colors.muted); mat:SetPoint("BOTTOMLEFT",9,7)
    y=y-62
  end
  c:SetHeight(math.max(1,-y+10))
end
function TCD:ShowRequests()
  self.CurrentView="requests"
  local c=self.RecipeContent; if not c then return end
  for _,child in ipairs({c:GetChildren()}) do child:Hide(); child:SetParent(nil) end
  local y=-5; local h=Text(c,14,"Guild Crafting Requests",self.Colors.gold); h:SetPoint("TOPLEFT",8,y); y=y-28
  for _,r in ipairs(self.DB.requests or {}) do
    local line=Text(c,11,(r.player or "Unknown")..": "..(r.item or "").."  ["..(r.status or "open").."]",self.Colors.parchment); line:SetPoint("TOPLEFT",8,y)
    local idLine=Text(c,9,"ID: "..tostring(r.id or "?"),self.Colors.muted); idLine:SetPoint("TOPLEFT",8,y-13)
    if r.status=="open" and r.id then local claim=Btn(c,"Claim",55,function() TCD:ClaimRequest(r.id) end); claim:SetPoint("TOPRIGHT",-68,y+2) end
    if r.status~="completed" and r.id then local done=Btn(c,"Done",55,function() TCD:CompleteRequest(r.id) end); done:SetPoint("TOPRIGHT",-8,y+2) end
    y=y-34
  end
  if #(self.DB.requests or {})==0 then local e=Text(c,11,"No requests yet. Use /tcd request <item>.",self.Colors.muted); e:SetPoint("TOPLEFT",8,y) end
  c:SetHeight(math.max(1,-y+20))
end
function TCD:RefreshUI()
  if not self.UI then return end
  self:RefreshGuildRoster()
  self:RefreshCrafters()
  if self.CurrentView=="requests" then self:ShowRequests() elseif self.CurrentView=="dashboard" then self:ShowDashboard() elseif self.CurrentView=="wishlist" then self:ShowWishlist() else self:RefreshRecipes() end
end
function TCD:ToggleUI() if not self.UI then self:CreateUI() end; if self.UI:IsShown() then self.UI:Hide() else self.UI:Show(); self:RefreshUI() end end

function TCD:ShowDashboard()
  self.CurrentView="dashboard"
  local c=self.RecipeContent; if not c then return end
  for _,child in ipairs({c:GetChildren()}) do child:Hide(); child:SetParent(nil) end
  local s=self:GetDashboardStats()
  local y=-8
  local h=Text(c,18,"THE TAVERNERS CRAFTING HALL",self.Colors.gold); h:SetPoint("TOPLEFT",10,y); y=y-34
  local intro=Text(c,11,"The guild's shared ledger of skilled hands, recipes and requests.",self.Colors.parchment); intro:SetPoint("TOPLEFT",10,y); y=y-34
  local lines={
    "Registered crafter profiles: "..s.profiles,
    "Known recipes: "..s.recipes,
    "Professions represented: "..s.professions,
    "Open / claimed requests: "..s.openRequests,
    "Wishlist entries: "..s.wishlist
  }
  for _,line in ipairs(lines) do local t=Text(c,13,line,self.Colors.parchment); t:SetPoint("TOPLEFT",16,y); y=y-27 end
  y=y-8
  local recent=Text(c,14,"Recently updated crafters",self.Colors.gold); recent:SetPoint("TOPLEFT",10,y); y=y-25
  local profiles={}; for _,p in pairs(self.DB.profiles or {}) do profiles[#profiles+1]=p end
  table.sort(profiles,function(a,b) return (a.updated or a.lastSeen or 0)>(b.updated or b.lastSeen or 0) end)
  for i=1,math.min(8,#profiles) do
    local p=profiles[i]; local t=Text(c,10,(p.name or "Unknown").."  •  "..tostring(p.class or "Crafter"),self.Colors.muted); t:SetPoint("TOPLEFT",16,y); y=y-19
  end
  c:SetHeight(math.max(1,-y+20))
end

function TCD:ShowWishlist()
  self.CurrentView="wishlist"
  local c=self.RecipeContent; if not c then return end
  for _,child in ipairs({c:GetChildren()}) do child:Hide(); child:SetParent(nil) end
  local y=-8; local h=Text(c,15,"Guild Recipe Wishlist",self.Colors.gold); h:SetPoint("TOPLEFT",8,y); y=y-28
  for _,w in ipairs(self.DB.wishlist or {}) do
    local line=Text(c,12,(w.item or "Unknown").." x"..tostring(w.quantity or 1),self.Colors.parchment); line:SetPoint("TOPLEFT",10,y)
    local by=Text(c,9,"Wanted by "..(w.player or "Unknown").."  •  "..(w.status or "wanted"),self.Colors.muted); by:SetPoint("TOPLEFT",10,y-15)
    local material=Btn(c,"Materials",75,function()
      local data,err=TCD:GetMaterialSummary(w.item,w.quantity)
      if not data then TCD:Print(err) else
        TCD:Print("Materials for "..w.item..":")
        for _,m in ipairs(data.materials) do TCD:Print(m.name.." x"..m.quantity) end
      end
    end); material:SetPoint("TOPRIGHT",-8,y+2)
    y=y-40
  end
  if #(self.DB.wishlist or {})==0 then local e=Text(c,11,"No wishlist entries. Use /tcd wishlist <item> [quantity].",self.Colors.muted); e:SetPoint("TOPLEFT",10,y) end
  c:SetHeight(math.max(1,-y+20))
end
