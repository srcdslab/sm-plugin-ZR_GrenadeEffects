#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <zombiereloaded>

#define FLASH 0
#define SMOKE 1

#define SOUND_FREEZE			"physics/glass/glass_impact_bullet4.wav"
#define SOUND_FREEZE_EXPLODE	"ui/freeze_cam.wav"

#define FragColor 	{255,75,75,255}
#define FlashColor 	{255,255,255,255}
#define SmokeColor	{75,255,75,255}
#define FreezeColor	{75,75,255,255}

#define MAX_EDICTS 2048

float NULL_VELOCITY[3] = {0.0, 0.0, 0.0};

int
	g_iStyle
	, BeamSprite
	, g_iGlowSprite
	, g_iBeamsprite
	, g_iHalosprite
	, g_iEdictCount;

bool
	g_bEnable
	, g_bTrails
	, g_bVFX_HE, g_bVFX_Smoke
	, g_bNapalm_HE
	, g_bSmoke_Freeze
	, g_bFlash_Light;

float
	g_fFlash_LightDistance, g_fFlash_LightDuration
	, g_fSmoke_FreezeDistance, g_fSmoke_FreezeDuration
	, g_fNapalm_HE_Duration;

ConVar
	g_hCvar_Enable
	, g_hCvar_VFX_Trails, g_hCvar_VFX_Style, g_hCvar_VFX_HE, g_hCvar_VFX_Smoke
	, g_hCvar_Napalm_HE, g_hCvar_Napalm_HE_Class_Duration, g_hCvar_Napalm_HE_Duration
	, g_hCvar_SmokeFreeze, g_hCvar_SmokeFreeze_Distance, g_hCvar_SmokeFreeze_Duration
	, g_hCvar_Flash_Light, g_hCvar_Flash_Light_Distance, g_hCvar_Flash_Light_Duration;

Handle
	g_hFreeze_Timer[MAXPLAYERS+1]
	, g_hfwdOnClientFreeze = INVALID_HANDLE, g_hfwdOnClientFreezed = INVALID_HANDLE
	, g_hfwdOnClientIgnite = INVALID_HANDLE, g_hfwdOnClientIgnited = INVALID_HANDLE;

public Plugin myinfo = 
{
	name = "[ZR] Grenade Effects",
	author = "FrozDark (HLModders.ru LLC), .Rushaway",
	description = "Adds Grenades Special Effects.",
	version = "2.3.0",
	url = "http://www.hlmod.ru"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	g_hfwdOnClientFreeze = CreateGlobalForward("ZR_OnClientFreeze", ET_Hook, Param_Cell, Param_Cell, Param_FloatByRef);
	g_hfwdOnClientFreezed = CreateGlobalForward("ZR_OnClientFreezed", ET_Ignore, Param_Cell, Param_Cell, Param_Float);

	g_hfwdOnClientIgnite = CreateGlobalForward("ZR_OnClientIgnite", ET_Hook, Param_Cell, Param_Cell, Param_FloatByRef);
	g_hfwdOnClientIgnited = CreateGlobalForward("ZR_OnClientIgnited", ET_Ignore, Param_Cell, Param_Cell, Param_Float);

	return APLRes_Success;
}

public void OnPluginStart()
{
	// Global plugin
	g_hCvar_Enable = CreateConVar("zr_greneffect_enable", "1", "Enables/Disables the plugin", 0, true, 0.0, true, 1.0);

	// VFX
	g_hCvar_VFX_Trails = CreateConVar("zr_greneffect_trails", "1", "Enables/Disables Grenade Trails", 0, true, 0.0, true, 1.0);
	g_hCvar_VFX_Style = CreateConVar("zr_greneffect_style", "0", "Changes style [0 = Default | 1 = Smaller | 2 = Bigger]", 0, true, 0.0, true, 2.0);
	g_hCvar_VFX_HE = CreateConVar("zr_greneffect_he", "1", "Enables/Disables HE Grenade ring Effects when detonate", 0, true, 0.0, true, 1.0);
	g_hCvar_VFX_Smoke = CreateConVar("zr_greneffect_smoke", "1", "Enables/Disables Smoke Grenade ring Effects when detonate", 0, true, 0.0, true, 1.0);

	g_hCvar_Napalm_HE = CreateConVar("zr_greneffect_napalm_he", "1", "Changes a he grenade to a napalm grenade", 0, true, 0.0, true, 1.0);
	g_hCvar_Napalm_HE_Class_Duration = CreateConVar("zr_greneffect_napalm_he_class", "0", "Use the napalm duration from playerclasses.txt [0= No | 1= Yes]", 0, true, 0.0, true, 1.0);
	g_hCvar_Napalm_HE_Duration = CreateConVar("zr_greneffect_napalm_he_duration", "6", "The napalm duration", 0, true, 0.0);

	g_hCvar_SmokeFreeze = CreateConVar("zr_greneffect_smoke_freeze", "1", "Changes a smoke grenade to a freeze grenade", 0, true, 0.0, true, 1.0);
	g_hCvar_SmokeFreeze_Distance = CreateConVar("zr_greneffect_smoke_freeze_distance", "600", "The freeze grenade distance", 0, true, 100.0);
	g_hCvar_SmokeFreeze_Duration = CreateConVar("zr_greneffect_smoke_freeze_duration", "4", "The freeze duration in seconds", 0, true, 1.0);

	g_hCvar_Flash_Light = CreateConVar("zr_greneffect_flash_light", "1", "Changes a flashbang to a flashlight", 0, true, 0.0, true, 1.0);
	g_hCvar_Flash_Light_Distance = CreateConVar("zr_greneffect_flash_light_distance", "1000", "The light distance", 0, true, 100.0);
	g_hCvar_Flash_Light_Duration = CreateConVar("zr_greneffect_flash_light_duration", "15.0", "The light duration in seconds", 0, true, 1.0);

	g_bEnable = GetConVarBool(g_hCvar_Enable);
	g_bTrails = GetConVarBool(g_hCvar_VFX_Trails);
	g_iStyle = GetConVarInt(g_hCvar_VFX_Style);
	g_bVFX_HE = GetConVarBool(g_hCvar_VFX_HE);
	g_bVFX_Smoke = GetConVarBool(g_hCvar_VFX_Smoke);
	g_bNapalm_HE = GetConVarBool(g_hCvar_Napalm_HE);
	g_bSmoke_Freeze = GetConVarBool(g_hCvar_SmokeFreeze);
	g_bFlash_Light = GetConVarBool(g_hCvar_Flash_Light);

	g_fNapalm_HE_Duration = GetConVarFloat(g_hCvar_Napalm_HE_Duration);
	g_fSmoke_FreezeDistance = GetConVarFloat(g_hCvar_SmokeFreeze_Distance);
	g_fSmoke_FreezeDuration = GetConVarFloat(g_hCvar_SmokeFreeze_Duration);
	g_fFlash_LightDistance = GetConVarFloat(g_hCvar_Flash_Light_Distance);
	g_fFlash_LightDuration = GetConVarFloat(g_hCvar_Flash_Light_Duration);

	HookConVarChange(g_hCvar_Enable, OnConVarChanged);
	HookConVarChange(g_hCvar_VFX_Trails, OnConVarChanged);
	HookConVarChange(g_hCvar_VFX_Style, OnConVarChanged);
	HookConVarChange(g_hCvar_VFX_HE, OnConVarChanged);
	HookConVarChange(g_hCvar_VFX_Smoke, OnConVarChanged);
	HookConVarChange(g_hCvar_Napalm_HE, OnConVarChanged);
	HookConVarChange(g_hCvar_Napalm_HE_Duration, OnConVarChanged);
	HookConVarChange(g_hCvar_SmokeFreeze, OnConVarChanged);
	HookConVarChange(g_hCvar_SmokeFreeze_Distance, OnConVarChanged);
	HookConVarChange(g_hCvar_SmokeFreeze_Duration, OnConVarChanged);
	HookConVarChange(g_hCvar_Flash_Light, OnConVarChanged);
	HookConVarChange(g_hCvar_Flash_Light_Distance, OnConVarChanged);
	HookConVarChange(g_hCvar_Flash_Light_Duration, OnConVarChanged);

	AutoExecConfig(true, "grenade_effects", "zombiereloaded");

	HookEvent("round_start", OnRoundStart);
	HookEvent("player_death", OnPlayerDeath);
	HookEvent("player_hurt", OnPlayerHurt);
	HookEvent("hegrenade_detonate", OnHeDetonate);
	HookEvent("smokegrenade_detonate", OnSmokeDetonate);
	AddNormalSoundHook(NormalSHook);
}

public void OnConVarChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (convar == g_hCvar_Enable)
	{
		g_bEnable = view_as<bool>(StringToInt(newValue));
	}
	else if (convar == g_hCvar_VFX_Trails)
	{
		g_bTrails = view_as<bool>(StringToInt(newValue));
	}
	else if (convar == g_hCvar_VFX_Style)
	{
		g_iStyle = StringToInt(newValue);
	}
	else if (convar == g_hCvar_VFX_HE)
	{
		g_bVFX_HE = view_as<bool>(StringToInt(newValue));
	}
	else if (convar == g_hCvar_VFX_Smoke)
	{
		g_bVFX_Smoke = view_as<bool>(StringToInt(newValue));
	}
	else if (convar == g_hCvar_Napalm_HE)
	{
		g_bNapalm_HE = view_as<bool>(StringToInt(newValue));
	}
	else if (convar == g_hCvar_Napalm_HE)
	{
		g_fNapalm_HE_Duration = StringToFloat(newValue);
	}
	else if (convar == g_hCvar_SmokeFreeze)
	{
		g_bSmoke_Freeze = view_as<bool>(StringToInt(newValue));
	}
	else if (convar == g_hCvar_Flash_Light)
	{
		g_bFlash_Light = view_as<bool>(StringToInt(newValue));
	}
	else if (convar == g_hCvar_SmokeFreeze_Distance)
	{
		g_fSmoke_FreezeDistance = StringToFloat(newValue);
	}
	else if (convar == g_hCvar_SmokeFreeze_Duration)
	{
		g_fSmoke_FreezeDuration = StringToFloat(newValue);
	}
	else if (convar == g_hCvar_Flash_Light_Distance)
	{
		g_fFlash_LightDistance = StringToFloat(newValue);
	}
	else if (convar == g_hCvar_Flash_Light_Duration)
	{
		g_fFlash_LightDuration = StringToFloat(newValue);
	}
}

public void OnMapStart() 
{
	BeamSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
	g_iGlowSprite = PrecacheModel("sprites/blueglow2.vmt");
	g_iBeamsprite = PrecacheModel("materials/sprites/lgtning.vmt");
	g_iHalosprite = PrecacheModel("materials/sprites/halo01.vmt");

	PrecacheSound(SOUND_FREEZE);
	PrecacheSound(SOUND_FREEZE_EXPLODE);
}

public void OnClientDisconnect(int client)
{
	if (IsClientInGame(client))
		ExtinguishEntity(client);
	if (g_hFreeze_Timer[client] != INVALID_HANDLE)
	{
		KillTimer(g_hFreeze_Timer[client]);
		g_hFreeze_Timer[client] = INVALID_HANDLE;
	}
}

public void OnRoundStart(Event event, const char[] name, bool dontBroadcast) 
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (g_hFreeze_Timer[client] != INVALID_HANDLE)
		{
			KillTimer(g_hFreeze_Timer[client]);
			g_hFreeze_Timer[client] = INVALID_HANDLE;
		}
	}
}

public void OnPlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bNapalm_HE)
	{
		return;
	}
	char g_szWeapon[32];
	GetEventString(event, "weapon", g_szWeapon, sizeof(g_szWeapon));

	if (strcmp(g_szWeapon, "hegrenade", false) != 0)
	{
		return;
	}

	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (ZR_IsClientHuman(client))
	{
		return;
	}

	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

	Action result;
	float fNapalmClassDuration = 0.0;

	if (g_hCvar_Napalm_HE_Class_Duration.BoolValue)
		fNapalmClassDuration = ZR_ClassGetNapalmTime(client);

	float dummy_duration = fNapalmClassDuration > 0.0 ? fNapalmClassDuration : g_fNapalm_HE_Duration;
	result = Forward_OnClientIgnite(client, attacker, dummy_duration);

	switch (result)
	{
		case Plugin_Handled, Plugin_Stop :
		{
			return;
		}
		case Plugin_Continue :
		{
			dummy_duration = g_fNapalm_HE_Duration;
		}
	}

	IgniteEntity(client, dummy_duration);

	Forward_OnClientIgnited(client, attacker, dummy_duration);
}

public void OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	OnClientDisconnect(GetClientOfUserId(GetEventInt(event, "userid")));
}

public void OnHeDetonate(Event event, const char[] name, bool dontBroadcast) 
{
	if (!g_bEnable || !g_bVFX_HE)
	{
		return;
	}

	float origin[3];
	origin[0] = GetEventFloat(event, "x"); origin[1] = GetEventFloat(event, "y"); origin[2] = GetEventFloat(event, "z");

	switch (g_iStyle)
	{
		case 1:
			TE_SetupBeamRingPoint(origin, 10.0, 400.0, g_iBeamsprite, g_iHalosprite, 1, 1, 0.2, 10.0, 1.0, FragColor, 0, 0);
		case 2:
			TE_SetupBeamRingPoint(origin, 10.0, 400.0, g_iBeamsprite, g_iHalosprite, 1, 1, 0.2, 190.0, 1.0, FragColor, 0, 0);
		default:
			TE_SetupBeamRingPoint(origin, 10.0, 400.0, g_iBeamsprite, g_iHalosprite, 1, 1, 0.2, 100.0, 1.0, FragColor, 0, 0);
	}
	TE_SendToAll();
}

public void OnSmokeDetonate(Event event, const char[] name, bool dontBroadcast) 
{
	if (!g_bEnable || !g_bSmoke_Freeze)
	{
		return;
	}

	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	float origin[3];
	origin[0] = GetEventFloat(event, "x"); origin[1] = GetEventFloat(event, "y"); origin[2] = GetEventFloat(event, "z");

	int index = MaxClients+1;
	float xyz[3];
	while ((index = FindEntityByClassname(index, "smokegrenade_projectile")) != -1)
	{
		GetEntPropVector(index, Prop_Send, "m_vecOrigin", xyz);
		if (xyz[0] == origin[0] && xyz[1] == origin[1] && xyz[2] == origin[2])
		{
			AcceptEntityInput(index, "kill");
		}
	}

	origin[2] += 10.0;

	float targetOrigin[3];
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i) || ZR_IsClientHuman(i))
		{
			continue;
		}

		GetClientAbsOrigin(i, targetOrigin);
		targetOrigin[2] += 2.0;
		if (GetVectorDistance(origin, targetOrigin) <= g_fSmoke_FreezeDistance)
		{
			Handle trace = TR_TraceRayFilterEx(origin, targetOrigin, MASK_SOLID, RayType_EndPoint, FilterTarget, i);

			if ((TR_DidHit(trace) && TR_GetEntityIndex(trace) == i) || (GetVectorDistance(origin, targetOrigin) <= 100.0))
			{
				Freeze(i, client, g_fSmoke_FreezeDuration);
				CloseHandle(trace);
			}

			else
			{
				CloseHandle(trace);

				GetClientEyePosition(i, targetOrigin);
				targetOrigin[2] -= 2.0;

				trace = TR_TraceRayFilterEx(origin, targetOrigin, MASK_SOLID, RayType_EndPoint, FilterTarget, i);

				if ((TR_DidHit(trace) && TR_GetEntityIndex(trace) == i) || (GetVectorDistance(origin, targetOrigin) <= 100.0))
				{
					Freeze(i, client, g_fSmoke_FreezeDuration);
				}

				CloseHandle(trace);
			}
		}
	}

	if (g_bVFX_Smoke)
	{
		switch (g_iStyle)
		{
			case 1:
				TE_SetupBeamRingPoint(origin, 10.0, g_fSmoke_FreezeDistance, g_iBeamsprite, g_iHalosprite, 1, 1, 0.2, 20.0, 1.0, FreezeColor, 0, 0);
			case 2:
				TE_SetupBeamRingPoint(origin, 10.0, g_fSmoke_FreezeDistance, g_iBeamsprite, g_iHalosprite, 1, 1, 0.2, 180.0, 1.0, FreezeColor, 0, 0);
			default:
				TE_SetupBeamRingPoint(origin, 10.0, g_fSmoke_FreezeDistance, g_iBeamsprite, g_iHalosprite, 1, 1, 0.2, 100.0, 1.0, FreezeColor, 0, 0);
		}
		TE_SendToAll();
	}

	LightCreate(SMOKE, origin);
}

public bool FilterTarget(int entity, int contentsMask, any data)
{
	return (data == entity);
}

public Action DoFlashLight(Handle timer, any entity)
{
	if (!IsValidEdict(entity))
	{
		return Plugin_Stop;
	}

	char g_szClassname[64];
	GetEdictClassname(entity, g_szClassname, sizeof(g_szClassname));
	if (!strcmp(g_szClassname, "flashbang_projectile", false))
	{
		float origin[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", origin);
		origin[2] += 50.0;
		LightCreate(FLASH, origin);
		AcceptEntityInput(entity, "kill");
	}

	return Plugin_Stop;
}

bool Freeze(int client, int attacker, float &time)
{
	Action result;
	float dummy_duration = time; 
	result = Forward_OnClientFreeze(client, attacker, dummy_duration);

	switch (result)
	{
		case Plugin_Handled, Plugin_Stop :
		{
			return false;
		}
		case Plugin_Continue :
		{
			dummy_duration = time;
		}
	}

	if (g_hFreeze_Timer[client] != INVALID_HANDLE)
	{
		KillTimer(g_hFreeze_Timer[client]);
		g_hFreeze_Timer[client] = INVALID_HANDLE;
	}

	SetEntityMoveType(client, MOVETYPE_NONE);
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, NULL_VELOCITY);

	float vec[3];
	GetClientEyePosition(client, vec);
	vec[2] -= 50.0;
	EmitAmbientSound(SOUND_FREEZE, vec, client, SNDLEVEL_RAIDSIREN);

	TE_SetupGlowSprite(vec, g_iGlowSprite, dummy_duration, 2.0, 50);
	TE_SendToAll();

	g_hFreeze_Timer[client] = CreateTimer(dummy_duration, Unfreeze, client, TIMER_FLAG_NO_MAPCHANGE);

	Forward_OnClientFreezed(client, attacker, dummy_duration);

	return true;
}

public Action Unfreeze(Handle timer, any client)
{
	if (g_hFreeze_Timer[client] != INVALID_HANDLE)
	{
		SetEntityMoveType(client, MOVETYPE_WALK);
		g_hFreeze_Timer[client] = INVALID_HANDLE;
	}

	return Plugin_Continue;
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (!g_bEnable)
	{
		return;
	}

	if (!strcmp(classname, "hegrenade_projectile"))
	{
		BeamFollowCreate(entity, FragColor);
		if (g_bNapalm_HE)
		{
			IgniteEntity(entity, 2.0);
		}
	}
	else if (!strcmp(classname, "flashbang_projectile"))
	{
		if (g_bFlash_Light)
		{
			CreateTimer(1.3, DoFlashLight, entity, TIMER_FLAG_NO_MAPCHANGE);
		}
		BeamFollowCreate(entity, FlashColor);
	}
	else if (!strcmp(classname, "smokegrenade_projectile"))
	{
		if (g_bSmoke_Freeze)
		{
			BeamFollowCreate(entity, FreezeColor);
			CreateTimer(1.3, CreateEvent_SmokeDetonate, entity, TIMER_FLAG_NO_MAPCHANGE);
		}
		else
		{
			BeamFollowCreate(entity, SmokeColor);
		}
	}
	else if (g_bSmoke_Freeze && !strcmp(classname, "env_particlesmokegrenade"))
	{
		AcceptEntityInput(entity, "Kill");
	}
}

public Action CreateEvent_SmokeDetonate(Handle timer, any entity)
{
	if (!IsValidEdict(entity))
	{
		return Plugin_Stop;
	}

	char g_szClassname[64];
	GetEdictClassname(entity, g_szClassname, sizeof(g_szClassname));
	if (!strcmp(g_szClassname, "smokegrenade_projectile", false))
	{
		float origin[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", origin);
		int thrower = GetEntPropEnt(entity, Prop_Send, "m_hThrower");
		if(thrower < 1 || !IsClientInGame(thrower))
		{
			return Plugin_Stop;
		}

		int userid = GetClientUserId(thrower);

		Event event = CreateEvent("smokegrenade_detonate");

		event.SetInt("userid", userid);
		event.SetFloat("x", origin[0]);
		event.SetFloat("y", origin[1]);
		event.SetFloat("z", origin[2]);
		event.Fire();
	}

	return Plugin_Stop;
}

void BeamFollowCreate(int entity, int color[4])
{
	if (g_bTrails)
	{
		switch (g_iStyle)
		{
			case 1:
				TE_SetupBeamFollow(entity, BeamSprite,	0, 1.0, 2.0, 2.0, 5, color);
			case 2:
				TE_SetupBeamFollow(entity, BeamSprite,	0, 1.0, 18.0, 18.0, 5, color);
			default:
				TE_SetupBeamFollow(entity, BeamSprite,	0, 1.0, 10.0, 10.0, 5, color);
		}
		TE_SendToAll();	
	}
}

void LightCreate(int grenade, float pos[3])   
{  
	// Check if we will exceed the max edicts limit to prevent server crash
	GetEdictsCount();
	if(g_iEdictCount >= MAX_EDICTS - 148)
	{
		return;
	}

	int iEntity = CreateEntityByName("light_dynamic");
	if(!IsValidEntity(iEntity))
	{
		return;
	}

	DispatchKeyValue(iEntity, "inner_cone", "0");
	DispatchKeyValue(iEntity, "cone", "80");
	DispatchKeyValue(iEntity, "brightness", "1");
	DispatchKeyValueFloat(iEntity, "spotlight_radius", 150.0);
	DispatchKeyValue(iEntity, "pitch", "90");
	DispatchKeyValue(iEntity, "style", "1");
	switch(grenade)
	{
		case FLASH : 
		{
			DispatchKeyValue(iEntity, "_light", "255 255 255 255");
			DispatchKeyValueFloat(iEntity, "distance", g_fFlash_LightDistance);
			EmitSoundToAll("items/nvg_on.wav", iEntity, SNDCHAN_WEAPON);
			CreateTimer(g_fFlash_LightDuration, Delete, iEntity, TIMER_FLAG_NO_MAPCHANGE);
		}
		case SMOKE : 
		{
			DispatchKeyValue(iEntity, "_light", "75 75 255 255");
			DispatchKeyValueFloat(iEntity, "distance", g_fSmoke_FreezeDistance);
			EmitSoundToAll(SOUND_FREEZE_EXPLODE, iEntity, SNDCHAN_WEAPON);
			CreateTimer(0.2, Delete, iEntity, TIMER_FLAG_NO_MAPCHANGE);
		}
	}

	DispatchSpawn(iEntity);
	TeleportEntity(iEntity, pos, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(iEntity, "TurnOn");
}

public Action Delete(Handle timer, any entity)
{
	if (IsValidEntity(entity))
	{
		AcceptEntityInput(entity, "kill");
	}

	return Plugin_Continue;
}

public Action NormalSHook(int clients[64], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags)
{
	if (g_bSmoke_Freeze && !strcmp(sample, "^weapons/smokegrenade/sg_explode.wav"))
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

stock void GetEdictsCount()
{
	int iCount = 0;

	for (int entity = 1; entity <= MAX_EDICTS; entity++)
	{
		if (IsValidEdict(entity))
			iCount++;
	}

	g_iEdictCount = iCount;
}

/*
		F O R W A R D S
	------------------------------------------------
*/

Action Forward_OnClientFreeze(int client, int attacker, float &time)
{
	Action result;
	result = Plugin_Continue;

	Call_StartForward(g_hfwdOnClientFreeze);
	Call_PushCell(client);
	Call_PushCell(attacker);
	Call_PushFloatRef(time);
	Call_Finish(result);

	return result;
}

void Forward_OnClientFreezed(int client, int attacker, float time)
{
	Call_StartForward(g_hfwdOnClientFreezed);
	Call_PushCell(client);
	Call_PushCell(attacker);
	Call_PushFloat(time);
	Call_Finish();
}

Action Forward_OnClientIgnite(int client, int attacker, float &time)
{
	Action result;
	result = Plugin_Continue;

	Call_StartForward(g_hfwdOnClientIgnite);
	Call_PushCell(client);
	Call_PushCell(attacker);
	Call_PushFloatRef(time);
	Call_Finish(result);

	return result;
}

void Forward_OnClientIgnited(int client, int attacker, float time)
{
	Call_StartForward(g_hfwdOnClientIgnited);
	Call_PushCell(client);
	Call_PushCell(attacker);
	Call_PushFloat(time);
	Call_Finish();
}
