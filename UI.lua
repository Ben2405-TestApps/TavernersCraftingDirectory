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
  local sync=Btn(left,"Share with Guild",185,function() TCD:ShareProfile() end); sync:SetPoint("TOPLEFT",scan,"BOTTOMLEFT",0,-6)
  local cs=CreateFrame("ScrollFrame",nil,left,"UIPanelScrollFrameTemplate"); cs:SetPoint("TOPLEFT",12,-112); cs:SetPoint("BOTTOMRIGHT",-30,14)
  local cc=CreateFrame("Frame",nil,cs); cc:SetSize(175,1); cs:SetScrollChild(cc); self.CrafterContent=cc
  local search=CreateFrame("EditBox",nil,right,"InputBoxTemplate"); search:SetSize(250,24); search:SetPoint("TOPLEFT",16,-16); search:SetAutoFocus(false); search:SetScript("OnTextChanged",function() TCD:RefreshRecipes() end); self.SearchBox=search
  local all=Btn(right,"All Recipes",95,function() TCD.selectedCrafter=nil; TCD:RefreshUI() end); all:SetPoint("LEFT",search,"RIGHT",10,0)
  local requests=Btn(right,"Requests",85,function() TCD:ShowRequests() end); requests:SetPoint("LEFT",all,"RIGHT",6,0)
  local rs=CreateFrame("ScrollFrame",nil,right,"UIPanelScrollFrameTemplate"); rs:SetPoint("TOPLEFT",12,-54); rs:SetPoint("BOTTOMRIGHT",-30,14)
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
    b.text:SetText((p.name or key).." ("..n..")")
    if key==self.currentKey then b.text:SetTextColor(0.95,0.78,0.40) end
    b:SetScript("OnClick",function() TCD.selectedCrafter=key; TCD:RefreshUI() end)
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
      if query=="" or hay:find(query,1,true) then rows[#rows+1]={p=p,r=r} end
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
  local c=self.RecipeContent; if not c then return end
  for _,child in ipairs({c:GetChildren()}) do child:Hide(); child:SetParent(nil) end
  local y=-5; local h=Text(c,14,"Guild Crafting Requests",self.Colors.gold); h:SetPoint("TOPLEFT",8,y); y=y-28
  for _,r in ipairs(self.DB.requests or {}) do
    local line=Text(c,11,(r.player or "Unknown")..": "..(r.item or ""),self.Colors.parchment); line:SetPoint("TOPLEFT",8,y); y=y-22
  end
  if #(self.DB.requests or {})==0 then local e=Text(c,11,"No requests yet. Use /tcd request <item>.",self.Colors.muted); e:SetPoint("TOPLEFT",8,y) end
  c:SetHeight(math.max(1,-y+20))
end
function TCD:RefreshUI() if not self.UI then return end; self:RefreshCrafters(); self:RefreshRecipes() end
function TCD:ToggleUI() if not self.UI then self:CreateUI() end; if self.UI:IsShown() then self.UI:Hide() else self.UI:Show(); self:RefreshUI() end end
