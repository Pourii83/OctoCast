-- Main-hand melee swing timer
-- Uses SuperWoW's UNIT_CASTEVENT when available, otherwise the combat log.

local OC = OctoCast
local mod = OC:NewModule("swing", "Swing")

function mod:OnEnable()
  local bar = self.bar
  if SUPERWOW_VERSION then
    bar:RegisterEvent("UNIT_CASTEVENT")
    bar:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:PLAYER_ENTERING_WORLD()
  else
    bar:RegisterEvent("CHAT_MSG_COMBAT_SELF_HITS")
    bar:RegisterEvent("CHAT_MSG_COMBAT_SELF_MISSES")
  end
  bar:RegisterEvent("UNIT_ATTACK_SPEED")
end

function mod:Swing()
  local bar = self.bar
  if bar.unlocked then return end
  local speed = UnitAttackSpeed("player")
  if not speed or speed <= 0 then return end
  self.start, self.speed = GetTime(), speed
  bar:SetColor(OC.db.colors.swing)
  bar.text:SetText("")
  bar:SetProgress(0)
  bar:Begin()
end

function mod:PLAYER_ENTERING_WORLD()
  local _, guid = UnitExists("player")
  self.guid = guid
end

function mod:UNIT_CASTEVENT()
  if arg1 == self.guid and arg3 == "MAINHAND" then self:Swing() end
end

mod.CHAT_MSG_COMBAT_SELF_HITS = mod.Swing
mod.CHAT_MSG_COMBAT_SELF_MISSES = mod.Swing

-- keep the swing's progress when haste changes mid-swing
function mod:UNIT_ATTACK_SPEED()
  if arg1 ~= "player" or not self.bar.active then return end
  local speed = UnitAttackSpeed("player")
  if not speed or speed <= 0 then return end
  local now = GetTime()
  local frac = (now - self.start) / self.speed
  self.speed = speed
  self.start = now - frac * speed
end

function mod:OnUpdate()
  if not self.start then return end
  local now = GetTime()
  local left = self.start + self.speed - now
  if left <= 0 then
    self.bar:Finish(false)
    return
  end
  self.bar:SetProgress((now - self.start) / self.speed)
  if self.db.showTimer then
    self.bar.timer:SetText(string.format("%.1f", left))
  else
    self.bar.timer:SetText("")
  end
end
