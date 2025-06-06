--[[ TO DO

	-- Weird SC bug (also occurs in SB) 288,289
	-- Need to count strikes that are blinked/parried by mob towards multihit_count
	-- Need to count kicks

]]

require('common')

spike_effect_valid = {true,false,false,false,false,false,false,false,false,false,false,false,false,false,false}
add_effect_valid = {true,true,true,true,false,false,false,false,false,false,true,false,true,false,false}
skillchain_messages = T{288,289,290,291,292,293,294,295,296,297,298,299,300,301,302,385,386,387,388,389,390,391,392,393,394,395,396,397,398,732,767,768,769,770}
-- 161 is add effect drain, which as best I can tell, does not actually deal additional damage. 0 damage strikes from bloody bolts do not report any drain (e.g. weapon weakness Limbus zone) and it's known Blood Weapon doesn't do extra damage.
-- Other sources haven't been tested, but there would be no way to tell the difference between those and a more common source (blood weapon, primarily)
add_effect_messages = T{163, 229}
skillchain_names = {
    [288] = "Skillchain: Light",
    [289] = "Skillchain: Darkness",
    [290] = "Skillchain: Gravitation",
    [291] = "Skillchain: Fragmentation",
    [292] = "Skillchain: Distortion",
    [293] = "Skillchain: Fusion",
    [294] = "Skillchain: Compression",
    [295] = "Skillchain: Liquefaction",
    [296] = "Skillchain: Induration",
    [297] = "Skillchain: Reverberation",
    [298] = "Skillchain: Transfixion",
    [299] = "Skillchain: Scission",
    [300] = "Skillchain: Detonation",
    [301] = "Skillchain: Impaction",
    [302] = "Skillchain: Cosmic Elucidation",
    [385] = "Skillchain: Light",
    [386] = "Skillchain: Darkness",
    [387] = "Skillchain: Gravitation",
    [388] = "Skillchain: Fragmentation",
    [389] = "Skillchain: Distortion",
    [390] = "Skillchain: Fusion",
    [391] = "Skillchain: Compression",
    [392] = "Skillchain: Liquefaction",
    [393] = "Skillchain: Induration",
    [394] = "Skillchain: Reverberation",
    [395] = "Skillchain: Transfixion",
    [396] = "Skillchain: Scission",
    [397] = "Skillchain: Detonation",
    [398] = "Skillchain: Impaction",
    [732] = "Skillchain: Universal Enlightenment",
    [767] = "Skillchain: Radiance",
    [768] = "Skillchain: Umbra",
    [769] = "Skillchain: Radiance",
    [770] = "Skillchain: Umbra",
}
local defense_action_messages = {
	[1] = 'hit',
	[67] = 'hit', --crit
	[106] = 'intimidate', 
	[15] = 'evade', [282] = 'evade',
	[373] = 'absorb',
	[536] = 'retaliate', [535] = 'retaliate',
    [33] = 'counter',
}
local offense_action_messages = {
	[1] = 'melee',
	[67] = 'crit',
	[15] = 'miss', [63] = 'miss',
	[352] = 'ranged', [576] = 'ranged', [577] = 'ranged',
	[353] = 'r_crit',
	[354] = 'r_miss',
	[185] = 'ws', [197] = 'ws', [187] = 'ws',
	[188] = 'ws_miss',
	[2] = 'spell', [227] = 'spell',
	[252] = 'mb', [265] = 'mb', [274] = 'mb', [379] = 'mb', [747] = 'mb', [748] = 'mb',
	[82] = 'enfeeb', [236] = 'enfeeb', [754] = 'enfeeb', [755] = 'enfeeb',
	[85] = 'enfeeb_miss', [284] = 'enfeeb_miss', [653] = 'enfeeb_miss', [654] = 'enfeeb_miss', [655] = 'enfeeb_miss', [656] = 'enfeeb_miss',
	[110] = 'ja', [317] = 'ja', [522] = 'ja', [802] = 'ja',
	[158] = 'ja_miss', [324] = 'ja_miss',
	[157] = 'Barrage',
	[77] = 'Sange',
	[264] = 'aoe'
}

parser = require('parser') -- from atom0s

-- See https://github.com/atom0s/XiPackets/tree/main/world/server/0x0028
-- Converts to https://github.com/Windower/Lua/wiki/Action-Event (mostly)
function parser_to_windower_act(data)
	local parsed_packet = parser.parse(data)
	local act = {}

	-- Junk packet from server. Ignore it. (Thanks DSP!)
	if parsed_packet.trg_sum == 0 then
		return nil
	end
	
	act.actor_id     = parsed_packet.m_uID
	act.category     = parsed_packet.cmd_no
	act.param        = parsed_packet.cmd_arg
	act.target_count = parsed_packet.trg_sum
	act.unknown      = 0 -- not necessary but FIXME?
	act.recast       = parsed_packet.info
	act.targets      = T{}
	
	for _, v in ipairs (parsed_packet.target) do
		local target = T{}
		
		target.id           = v.m_uID
		target.action_count = v.result_sum
		target.actions      = T{}
		for _, action in ipairs (v.result) do
			local new_action = T{}
			
			new_action.reaction  = action.miss -- These values are different compared to windower, so the code outside of this function was adjusted.
			new_action.animation = action.sub_kind
			new_action.effect    = action.info
			new_action.stagger   = action.scale
			new_action.param     = action.value
			new_action.message   = action.message
			new_action.unknown   = action.bit

			if action.has_proc then
				new_action.has_add_effect       = true
				new_action.add_effect_animation = action.proc_kind
				new_action.add_effect_effect    = action.proc_info
				new_action.add_effect_param     = action.proc_value
				new_action.add_effect_message   = action.proc_message
			else
				new_action.has_add_effect       = false
				new_action.add_effect_animation = 0
				new_action.add_effect_effect    = 0
				new_action.add_effect_param     = 0
				new_action.add_effect_message   = 0
			end
			
			if action.has_react then
				new_action.has_spike_effect       = true
				new_action.spike_effect_animation = action.react_kind
				new_action.spike_effect_effect    = action.react_info
				new_action.spike_effect_param     = action.react_value
				new_action.spike_effect_message   = action.react_message
			else 
				new_action.has_spike_effect       = false
				new_action.spike_effect_animation = 0
				new_action.spike_effect_effect    = 0
				new_action.spike_effect_param     = 0
				new_action.spike_effect_message   = 0
			end
			
			table.insert(target.actions, new_action)
		end

		table.insert(act.targets, target)
	end
	
	return act
end

local res = {}

res.action_messages = require('action_messages')

function parse_action_packet(data)
	if pause then return end
	
	local act = parser_to_windower_act(data)
	if not act then
		return
	end
	
	local player = AshitaCore:GetMemoryManager():GetPlayer()
	local NPC_name, PC_name
   
	act.actor = player_info(act.actor_id)
	if not act.actor then
		return
	end
	
	local multihit_count,multihit_count2 = nil
	local aoe_type = 'ws'
	
	for i,targ in pairs(act.targets) do
		multihit_count,multihit_count2 = 0,0
        for n,m in pairs(targ.actions) do

            -- special case for counters
            if m.message == 0 and m.has_spike_effect and m.spike_effect_animation == 63 and m.spike_effect_message == 33 then
                target = player_info(targ.id)
				NPC_name = nickname(act.actor.name:gsub(" ","_"):gsub("'",""))
				PC_name = construct_PC_name(target)

                register_data(NPC_name,PC_name,'counter',m.spike_effect_param)
            end

            if m.message ~= 0 and res.action_messages[m.message] ~= nil then	
				target = player_info(targ.id)

				-- if mob is actor, record defensive data
				if act.actor.type == 'mob' and settings.record[target.type] then
					NPC_name = nickname(act.actor.name:gsub(" ","_"):gsub("'",""))
					PC_name = construct_PC_name(target)
					if target.name == player.name then
						if settings.index_shield and get_shield() then
							PC_name = PC_name:sub(1, 6)..'-'..get_shield():sub(1, 3)..''
						end
						if settings.index_reprisal and buffs.Reprisal then PC_name = PC_name .. 'R' end
						if settings.index_palisade and buffs.Palisade then PC_name = PC_name .. 'P' end
						if settings.index_battuta and buffs.Battuta then PC_name = PC_name .. 'B' end
					end

					local action = defense_action_messages[m.message]
					local engaged = (target.status==1) and true or false

					if m.reaction == 4 and act.category == 1 then --block
						register_data(NPC_name,PC_name,'block',m.param)
						if engaged then
							register_data(NPC_name,PC_name,'nonparry')
						end
					elseif m.reaction == 3 and act.category == 1 then --parry
						register_data(NPC_name,PC_name,'parry')
					elseif m.reaction == 2 and act.category == 1 then --guard
						register_data(NPC_name,PC_name,'guard', m.param)
					elseif action == 'hit' then --hit or crit
						register_data(NPC_name,PC_name,action,m.param)
						if engaged then
							register_data(NPC_name,PC_name,'nonparry')
							if buffs.Retaliation and not m.has_spike_effect then
								register_data(NPC_name,PC_name,'nonret')
							end
						end
						if act.category == 1 then
							register_data(NPC_name,PC_name,'nonblock',m.param)
						end
					elseif T{'intimidate','evade'}:contains(action) then --intimidate
						register_data(NPC_name,PC_name,action)
					end

					if action == 'absorb' then  --absorb (can happen during block)
						register_data(NPC_name,PC_name,'absorb',m.param)
					end					
					
					if m.has_spike_effect then --offensive data (when player has Reprisal or counters, etc.) spike_effect_effect = 2 for counters
						local spike_action = defense_action_messages[m.spike_effect_message]
						if m.spike_effect_param then
							register_data(NPC_name,PC_name,'spike',m.spike_effect_param)
						end
						if spike_action == 'retaliate' then
							register_data(NPC_name,PC_name,'retrate')
						end
					end
					
				-- if player is actor, record offensive data
				elseif target.type == 'mob' and settings.record[act.actor.type] then
					NPC_name = nickname(target.name:gsub(" ","_"):gsub("'",""))
					PC_name = construct_PC_name(act.actor)

					local action = offense_action_messages[m.message]

					if T{"melee","crit","miss"}:contains(action) then
						register_data(NPC_name,PC_name,action,m.param)
						if m.animation==0 then --main hand
							multihit_count = multihit_count + 1
						elseif m.animation==1 then --off hand
							multihit_count2 = multihit_count2 + 1
						end	
					elseif T{'ranged','r_crit','r_miss'}:contains(action) then
						register_data(NPC_name,PC_name,action,m.param)
					elseif T{'ws','ws_miss'}:contains(action) then
						register_data(NPC_name,PC_name,action,m.param,'ws',act.param)
						aoe_type = 'ws'
					elseif T{'spell','mb'}:contains(action) then
						register_data(NPC_name,PC_name,action,m.param,'spell',act.param)
						aoe_type = 'spell'
					elseif T{'enfeeb','enfeeb_miss'}:contains(action) then
						register_data(NPC_name,PC_name,action,nil,'spell',act.param)
					elseif T{'ja','ja_miss'}:contains(action) then
						register_data(NPC_name,PC_name,action,m.param,'ja',act.param)
						aoe_type = 'ja'
					elseif T{'Barrage','Sange'}:contains(action) then
						register_data(NPC_name,PC_name,'ja',m.param,'ja',action)
					elseif action == 'aoe' then
						register_data(NPC_name,PC_name,aoe_type,m.param,aoe_type,act.param)
					end

					if m.has_add_effect and m.add_effect_message ~= 0 and add_effect_valid[act.category] then
						if skillchain_messages:contains(m.add_effect_message) then
							PC_name = "SC-"..PC_name:sub(1, 3)							
							register_data(NPC_name,PC_name,'sc',m.add_effect_param)
							if skillchain_names and skillchain_names[m.add_effect_message] then debug('sc ('..PC_name..') '..skillchain_names[m.add_effect_message]..' '..m.add_effect_param) end
						elseif add_effect_messages:contains(m.add_effect_message) and m.add_effect_param > 0 then
							register_data(NPC_name,PC_name,'add',m.add_effect_param)
						end
					end
					
					if m.has_spike_effect and m.spike_effect_message ~= 0 and spike_effect_valid[act.category] then --defensive data (when mob counters, has blazespikes, etc.) // Can you block a counter, and can I tell that you blocked a counter?
						--print('Monster spikes: Effect: '..m.spike_effect_effect)
					end
				end				
			end
		end
	end
	
	if multihit_count and multihit_count > 0 then
		register_data(NPC_name,PC_name,tostring(multihit_count))
	end
	if multihit_count2 and multihit_count2 > 0 then
		register_data(NPC_name,PC_name,tostring(multihit_count2))
	end
	
	--Handle auto-export
	if PC_name and autoexport and autoexport_tracker == autoexport_interval then
		export_parse(autoexport)
	end
	autoexport_tracker = (autoexport_tracker % autoexport_interval) + 1
end

---------------------------------------------------------
-- Function credit to Suji
---------------------------------------------------------
function construct_PC_name(PC)
	local name = PC.name
    local result = ''
    if PC.owner then
        if string.len(name) > 7 then
            result = string.sub(name, 1, 6)
        else
            result = name
        end
        result = result..'-'..string.sub(nickname(PC.owner.name), 1, 4)..''
    else
        result = nickname(name)
    end
    return string.sub(result,1,10)
end

function nickname(player_name)
	if renames[player_name] then
		return renames[player_name]
	else
		return player_name
	end
end

function init_mob_player_table(mob_name,player_name)
	if not database[mob_name] then
		database[mob_name] = {}
	end
	database[mob_name][player_name] = {}	
end

function register_data(NPC_name,PC_name,stat,val,spell_type,spell_id)    
    if not database[NPC_name] or not database[NPC_name][PC_name] then						
        init_mob_player_table(NPC_name,PC_name)
    end
    
	local spell_name = nil
	local stat_type = get_stat_type(stat) or 'unknown'

    local mob_player_table = database[NPC_name][PC_name]
	if not mob_player_table[stat_type] then
		mob_player_table[stat_type] = {}
	end

	if not mob_player_table[stat_type][stat] then
		mob_player_table[stat_type][stat] = {}
	end
	
	if stat_type == "category" then --handle WS, spells, and JA
		if type(spell_id) == 'number' then
			local spell           = nil
			local resourceManager = AshitaCore:GetResourceManager()

			if spell_type == "ws" then
				spell = resourceManager:GetAbilityById(spell_id)
			elseif spell_type == "ja" then
				spell = resourceManager:GetAbilityById(spell_id + 0x200)
			elseif spell_type == "spell" then
				spell = resourceManager:GetSpellById(spell_id)
			end

			if spell and spell.Name[1] then
				spell_name = spell.Name[1]
			else
				spell_name = "unknown"
			end
		elseif type(spell_id) == 'string' then spell_name = spell_id end
		
		if not spell_name then
			message('There was an error recording that action...')
			return
		end
		
		spell_name = spell_name:gsub(" ","_"):gsub("'",""):gsub(":","")
		
		if not mob_player_table[stat_type][stat][spell_name] then
			mob_player_table[stat_type][stat][spell_name] = {['tally'] = 0}
		end
		
		mob_player_table[stat_type][stat][spell_name].tally = mob_player_table[stat_type][stat][spell_name].tally + 1
		
		if val then
			if not mob_player_table[stat_type][stat][spell_name].damage then
				mob_player_table[stat_type][stat][spell_name].damage = val
			else
				mob_player_table[stat_type][stat][spell_name].damage = mob_player_table[stat_type][stat][spell_name].damage + val
			end
			
			if damage_types:contains(stat) then
				if not mob_player_table.total_damage then
					mob_player_table.total_damage = val
				else
					mob_player_table.total_damage = mob_player_table.total_damage + val
				end
			end
		end
	else --handle everything else
		if not mob_player_table[stat_type][stat].tally then
			mob_player_table[stat_type][stat].tally = 0 
		end
		
		mob_player_table[stat_type][stat].tally = mob_player_table[stat_type][stat].tally + 1
		
		if val then
			if not mob_player_table[stat_type][stat].damage then
				mob_player_table[stat_type][stat].damage = val
			else
				mob_player_table[stat_type][stat].damage = mob_player_table[stat_type][stat].damage + val
			end
			
			if damage_types:contains(stat) then
				if not mob_player_table.total_damage then
					mob_player_table.total_damage = val
				else
					mob_player_table.total_damage = mob_player_table.total_damage + val
				end
			end
		end	
	end

-- FIXME when implementing loggin
--    if val and settings.logger:find(function(el) if PC_name==el or (el:endswith('*') and PC_name:startswith(tostring(el:gsub('*','')))) then return true end return false end) then
--        log_data(PC_name,NPC_name,stat,val,spell_name)
--    end
end


function get_shield()
	local current_equip = windower.ffxi.get_items().equipment
	local shield_id, shield_bag = 0,0
	for i,v in pairs(current_equip) do
		if i == 'sub' then
			shield_id = v
		elseif i=='sub_bag' then
			shield_bag = v
		end
	end
	
	if shield_id==0 then
		return nil
	end
	
	-- res.items[shield]
	shield = windower.ffxi.get_items(shield_bag,shield_id)
	return res.items[shield.id].english
end


-- from Thorny
function GetIndexFromId(serverId)
    local index = bit.band(serverId, 0x7FF);
    local entMgr = AshitaCore:GetMemoryManager():GetEntity();
    if (entMgr:GetServerId(index) == serverId) then
        return index;
    end
    for i = 1,2303 do
        if entMgr:GetServerId(i) == serverId then
            return i;
        end
    end
    return 0;
end

---------------------------------------------------------
-- Function credit to Byrth
---------------------------------------------------------
function player_info(id)
    local player_table = {}
	
    local typ,owner
	
	local idx = GetIndexFromId(id)
	local entityManager = AshitaCore:GetMemoryManager():GetEntity()
	
    player_table.name = entityManager:GetName(idx)
	player_table.id = idx
	player_table.type='debug'
	player_table.owner = nil
	player_table.status = entityManager:GetStatus(idx)
	
    if player_table.name == nil then
        return {name=nil,id=nil,type='debug',owner=nil}
    end
	
    local party = AshitaCore:GetMemoryManager():GetParty()
	
	local partyPets    = {}
	local partyFellows = {}
    for i = 0, 17 do
		if party:GetMemberIsActive(i) == 1 then
			local partyID = party:GetMemberTargetIndex(i)

			if i == 0 and partyID == player_table.id then
				typ = 'me'
			elseif i > 0 and partyID == player_table.id then
				typ = 'party'
				
				if i > 5 then
					typ = 'alliance'
				end
				
				-- dynamic entity
				if player_table.id > 0x700 then
					if entityManager:GetTrustOwnerTargetIndex(partyID) ~= 0 then
						typ = 'trust'
					end
				end
			end

			partyPets[entityManager:GetPetTargetIndex(partyID)] = party:GetMemberName(i)
			partyFellows[entityManager:GetFellowTargetIndex(partyID)] = party:GetMemberName(i)
		end
    end

    if not typ then
		if bit.band(entityManager:GetSpawnFlags(player_table.id), 0x10) ~= 0 then
			typ = 'mob'
		elseif partyPets[player_table.id] then
			typ = 'pet'
			owner = {}
			owner.name = partyPets[player_table.id]
		elseif partyFellows[player_table.id] then
			typ = 'fellow'
			owner = {}
			owner.name = partyFellows[player_table.id]
		else
            typ = 'other'
        end
    end
    if not typ then typ = 'debug' end
	
    return {name=player_table.name,status=player_table.status,id=id,type=typ,owner=(owner or nil)}
end


--Copyright (c) 2013~2016, F.R
--All rights reserved.

--Redistribution and use in source and binary forms, with or without
--modification, are permitted provided that the following conditions are met:

--    * Redistributions of source code must retain the above copyright
--      notice, this list of conditions and the following disclaimer.
--    * Redistributions in binary form must reproduce the above copyright
--      notice, this list of conditions and the following disclaimer in the
--      documentation and/or other materials provided with the distribution.
--    * Neither the name of <addon name> nor the
--      names of its contributors may be used to endorse or promote products
--      derived from this software without specific prior written permission.

--THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
--ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
--WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
--DISCLAIMED. IN NO EVENT SHALL <your name> BE LIABLE FOR ANY
--DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
--(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
--LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
--ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
--(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
--SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
