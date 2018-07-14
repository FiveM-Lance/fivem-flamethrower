local config = {}
config.intensity = 5.0
config.timeUntilReload = 30.0

local holdingfthrow = false
local usingfthrow = false
local fthrowModel = "prop_minigun_01"
local animDict = "weapons@heavy@minigun"
local animName = "idle_2_aim_right_med"
local particleDict = "core"
local particleName = "exp_sht_flame"
local actionTime = 30
local fthrow_net = nil

---------------------------------------------------------------------------
-- Toggling fthrow --
---------------------------------------------------------------------------
RegisterNetEvent("fthrow:Togglefthrow")
AddEventHandler("fthrow:Togglefthrow", function()
    if not holdingfthrow then
        RequestModel(GetHashKey(fthrowModel))
        while not HasModelLoaded(GetHashKey(fthrowModel)) do
            Citizen.Wait(100)
        end

        RequestAnimDict(animDict)
        while not HasAnimDictLoaded(animDict) do
            Citizen.Wait(100)
        end

        local plyCoords = GetOffsetFromEntityInWorldCoords(GetPlayerPed(PlayerId()), 0.0, 0.0, -5.0)
        local fthrowspawned = CreateObject(GetHashKey(fthrowModel), plyCoords.x, plyCoords.y, plyCoords.z, 1, 1, 1)
        Citizen.Wait(1000)
        local netid = ObjToNet(fthrowspawned)
        SetNetworkIdExistsOnAllMachines(netid, true)
        NetworkSetNetworkIdDynamic(netid, true)
        SetNetworkIdCanMigrate(netid, false)
        AttachEntityToEntity(fthrowspawned, GetPlayerPed(PlayerId()), GetPedBoneIndex(GetPlayerPed(PlayerId()), 28422), 0.49, -0.05, 0.0, 270.0, 0.0, 0.0, 1, 1, 0, 1, 0, 1)
        TaskPlayAnim(GetPlayerPed(PlayerId()), 1.0, -1, -1, 50, 0, 0, 0, 0) -- 50 = 32 + 16 + 2
        TaskPlayAnim(GetPlayerPed(PlayerId()), animDict, animName, 1.0, -1, -1, 50, 0, 0, 0, 0)
        fthrow_net = netid
        holdingfthrow = true
    else
        ClearPedSecondaryTask(GetPlayerPed(PlayerId()))
        DetachEntity(NetToObj(fthrow_net), 1, 1)
        DeleteEntity(NetToObj(fthrow_net))
        fthrow_net = nil
        holdingfthrow = false
        usingfthrow = false
    end
end)

---------------------------------------------------------------------------
-- Start Particles --
---------------------------------------------------------------------------
RegisterNetEvent("fthrow:StartParticles")
AddEventHandler("fthrow:StartParticles", function(fthrowid)
    local entity = NetToObj(fthrowid)

    RequestNamedPtfxAsset(particleDict)
    while not HasNamedPtfxAssetLoaded(particleDict) do
        Citizen.Wait(100)
    end

    UseParticleFxAssetNextCall(particleDict)
    local particleEffect = StartParticleFxLoopedOnEntity(particleName, entity, 0.5, 0.005, 0.0, 0.0, -95.0, 180.0, config.intensity, false, false, false)
    SetTimeout(10000, function()
        usingfthrow = false
    end)
    
    --local particleEffect = StartParticleFxLoopedOnEntity(particleName, entity, -0.75, 0.005, 0.0, 180.0, -75.0, 0.0, 2.5, 0.0, 0.0, 0.0)
end)

---------------------------------------------------------------------------
-- Stop Particles --
---------------------------------------------------------------------------
RegisterNetEvent("fthrow:StopParticles")
AddEventHandler("fthrow:StopParticles", function(fthrowid)
    local entity = NetToObj(fthrowid)
    RemoveParticleFxFromEntity(entity)
end)

---------------------------------------------------------------------------
-- Get Vehicle Closest Door --
---------------------------------------------------------------------------
Citizen.CreateThread(function()
    while true do
        if holdingfthrow then
            if IsPedInAnyVehicle(GetPlayerPed(-1), false) then
                TriggerEvent("fthrow:Togglefthrow")
            end
            for i=140, 143 do
                DisableControlAction(0, i, true)
            end
            if IsControlJustPressed(0, 24) and usingfthrow == false then
                Timer()
            end
        else
            for i=140, 143 do
                EnableControlAction(0, i, true)
            end
        end
        Citizen.Wait(0)
    end
end)

function Timer()
    Citizen.CreateThread(function()
        usingfthrow = true
        local time = config.timeUntilReload
        local count = time
        TriggerServerEvent("fthrow:SyncStartParticles", fthrow_net)
        while IsControlPressed(0, 24) and count > 0 do

            if not holdingfthrow then
                usingfthrow = false
                TriggerServerEvent("fthrow:SyncStopParticles", fthrow_net)
                return
            end
            
            Citizen.Wait(500)
            count = count - 0.5
        end
        TriggerServerEvent("fthrow:SyncStopParticles", fthrow_net)
        usingfthrow = false
    end)
end

function Notification(message)
	SetNotificationTextEntry("STRING")
	AddTextComponentString(message)
	DrawNotification(0, 1)
end