local ADDON, TCD = ...
TCD = TCD or _G.TCD
local function Call(fn,...)
  if type(fn)~="function" then return nil end
  local ok,a,b,c=pcall(fn,...); if ok then return a,b,c end
end
local function ItemName(id)
  if not id then return nil end
  local name
  if C_Item and C_Item.GetItemInfo then name=Call(C_Item.GetItemInfo,id) end
  if not name and GetItemInfo then name=Call(GetItemInfo,id) end
  return name
end
function TCD:RefreshProfessionData()
  if not self.profile then return end
  local list={}
  if GetProfessions and GetProfessionInfo then
    local ids={GetProfessions()}
    for _,idx in ipairs(ids) do
      if idx then
        local name,icon,skill,maxSkill=Call(GetProfessionInfo,idx)
        if name then list[#list+1]={name=name,icon=icon,skill=tonumber(skill) or 0,maxSkill=tonumber(maxSkill) or 0} end
      end
    end
  end
  self.profile.professions=list
  self.profile.updated=time()
  return list
end
local function GetRecipeIDs()
  if C_TradeSkillUI and C_TradeSkillUI.GetAllRecipeIDs then
    local ids=Call(C_TradeSkillUI.GetAllRecipeIDs)
    if type(ids)=="table" then return ids end
  end
  local ids={}
  if GetNumTradeSkills and GetTradeSkillInfo then
    for i=1,(GetNumTradeSkills() or 0) do
      local name,kind=GetTradeSkillInfo(i)
      if name and kind~="header" and kind~="subheader" then ids[#ids+1]={legacyIndex=i,name=name} end
    end
  end
  return ids
end
function TCD:ScanOpenProfession()
  if not self.profile then return end
  local profession
  if GetTradeSkillLine then profession=Call(GetTradeSkillLine) end
  if type(profession)=="table" then profession=profession.professionName or profession.name end
  if not profession or profession=="" then return end
  local scanned,new=0,0
  for _,v in ipairs(GetRecipeIDs()) do
    local id=type(v)=="table" and v.recipeID or v
    local info
    if id and C_TradeSkillUI and C_TradeSkillUI.GetRecipeInfo then info=Call(C_TradeSkillUI.GetRecipeInfo,id) end
    local name=(type(info)=="table" and info.name) or (type(v)=="table" and v.name)
    if name and (type(info)~="table" or info.learned~=false) then
      local rec={id=id or (type(v)=="table" and v.legacyIndex),name=name,profession=profession,outputName=nil,outputCount=1,reagents={}}
      local schematic
      if id and C_TradeSkillUI and C_TradeSkillUI.GetRecipeSchematic then schematic=Call(C_TradeSkillUI.GetRecipeSchematic,id,false) end
      if type(schematic)=="table" then
        rec.outputItemID=schematic.outputItemID
        rec.outputName=ItemName(rec.outputItemID)
        rec.outputCount=schematic.quantityMin or schematic.quantity or 1
        for _,slot in ipairs(schematic.reagentSlotSchematics or {}) do
          local reagentID=slot.reagent and slot.reagent.itemID
          if not reagentID and slot.reagents and slot.reagents[1] then reagentID=slot.reagents[1].itemID end
          if reagentID then rec.reagents[#rec.reagents+1]={itemID=reagentID,name=ItemName(reagentID),quantity=slot.quantityRequired or slot.quantity or 1} end
        end
      end
      local key=tostring(rec.id or rec.name)..":"..profession
      if not self.profile.recipes[key] then new=new+1 end
      self.profile.recipes[key]=rec
      scanned=scanned+1
    end
  end
  self.profile.updated=time()
  if scanned>0 then
    self:Print("Scanned "..scanned.." recipes from "..profession.." ("..new.." new).")
    if self.RefreshUI then self:RefreshUI() end
  end
end
