local Utils = require('modules/Utils')
local Vars = require('modules/Vars')

local Mappins = {}

--- Updates the map pins root state
---@param this any
function Mappins.BaseMappinBaseController_UpdateRootState(this)
	local player = Game.GetPlayer():GetWorldPosition()
	local position = this:GetMappin():GetWorldPosition()

	for _, v in pairs(Vars.pins) do
		local pin = v
		if (pin.position ~= nil and Utils.isSamePosition(pin.position, position)) then
			if (pin.range ~= 0 and pin.range ~= nil) then
				if Utils.isNearPosition(player, pin.position, pin.range) then
					this:SetRootVisible(true)
					else
					this:SetRootVisible(false)
				end
			end
			v.widget = this.iconWidget
			v.controller = this
			v.mappinEntity = this:GetMappin()
			v.distanceToPlayer = Utils.calculateDistance(player, v.position)
			if v.tracked ~= nil then
				if #this.taggedWidgets > 0 then
					if this:GetProfile():ShowTrackedIcon() then
						for i = 0, #this.taggedWidgets do
							inkWidgetRef.SetVisible(this.taggedWidgets[i], v.tracked)
						end
						local animPlayer = this:GetAnimPlayer_Tracked()
						animPlayer:PlayOrPause(v.tracked)
					end
				end
			end
			if pin.style ~= nil then
				if pin.style.icon ~= nil then
					local record = TweakDBInterface.GetUIIconRecord('ChoiceIcons.' .. pin.style.icon)
					if(record ~= nil) then
						v.widget:SetTexturePart(record:AtlasPartName())
						v.widget:SetAtlasResource(record:AtlasResourcePath())
					end
				end
				if pin.style.color ~= nil then
					this.iconWidget:SetTintColor(Utils.getColorStyle(pin.style.color))
				end
			end
			break
		end
	end
end

--- Customizes the tooltip of the map pins
---@param self any
---@param data any
---@param menu any
function Mappins.WorldMapTooltipController_SetData(self, data, menu)
	if data ~= nil and data.mappin ~= nil then
		local position = data.mappin:GetWorldPosition()
		for _, v in pairs(Vars.pins) do
			local pin = v
			if (pin.position ~= nil and Utils.isSamePosition(pin.position, position)) then
				inkWidgetRef.SetVisible(self.descText, true)
				inkTextRef.SetText(self.titleText, pin.title)
				inkTextRef.SetText(self.descText, pin.desc)
				break
			end
		end
	end
end

return Mappins