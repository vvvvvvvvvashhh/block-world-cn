-- SPDX-License-Identifier: GPL-3.0-or-later
local storage = core.get_mod_storage()
local raw_events = storage:get_string("events")
local events = raw_events ~= "" and core.parse_json(raw_events) or {}
local function log(kind, data)
 events[#events+1]={time=os.time(),kind=kind,data=data}
 while #events>200 do table.remove(events,1) end
 storage:set_string("events",core.write_json(events))
 core.safe_file_write(core.get_worldpath().."/action-receipts.json",core.write_json(events,true))
end
core.register_on_dignode(function(pos,node,player)
 if player and player:is_player() then log("dig",{pos=pos,node=node.name,player=player:get_player_name()}) end
end)
core.register_on_placenode(function(pos,node,player)
 if player then log("place",{pos=pos,node=node.name,player=player:get_player_name()}) end
end)
core.register_on_craft(function(stack,player,oldgrid)
 local items={};for _,s in ipairs(oldgrid) do items[#items+1]=s:to_string() end
 log("craft",{result=stack:to_string(),ingredients=items,player=player:get_player_name()})
end)
local function snapshot(player,kind)
 local inv={};for k,list in pairs(player:get_inventory():get_lists()) do inv[k]={};for i,s in ipairs(list) do inv[k][i]=s:to_string() end end
 log(kind,{pos=player:get_pos(),hp=player:get_hp(),inventory=inv,player=player:get_player_name()})
end
local function lighting(p)
 p:set_lighting({shadows={intensity=0.48},volumetric_light={strength=0.10},saturation=1.04,
  exposure={luminance_min=-3.5,luminance_max=-2.5,exposure_correction=0.12,speed_dark_bright=800,speed_bright_dark=400},
  bloom={intensity=0.08,strength_factor=0.65,radius=2}})
end
core.register_on_joinplayer(function(p)
 core.after(0.5,function() if p and p:is_player() then lighting(p);snapshot(p,"join") end end)
end)
core.register_on_respawnplayer(function(p) core.after(0.5,function() if p and p:is_player() then lighting(p) end end) end)
core.register_on_leaveplayer(function(p) snapshot(p,"leave") end)
core.register_on_shutdown(function() for _,p in ipairs(core.get_connected_players()) do snapshot(p,"shutdown") end end)
core.register_chatcommand("guide",{description="中文生存入门",func=function(name)
 core.show_formspec(name,"local_experience:guide","formspec_version[6]size[10,7]"..
 "textarea[0.5,0.5;9,5.5;;;第一天：\n1. 按住左键砍树，收集原木。\n2. E 打开背包，原木放入合成栏，取出木板。\n3. 四格各放一块木板制作工作台。\n4. 工作台里合成木棍、木镐；采石升级工具。\n5. 收集食物和羊毛，建造有门与火把的庇护所。\n\n右键工作台、熔炉、箱子会打开真实容器。\n配方书显示全部制作方式。Esc 可暂停与退出存档。]button_exit[3,6;4,0.7;done;返回游戏]")
 return true
end})
