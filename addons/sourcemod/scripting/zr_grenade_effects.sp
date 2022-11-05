#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#include <zombiereloaded>

#define FLASH 0
#define SMOKE 1

#define SOUND_FREEZE	"physics/glass/glass_impact_bullet4.wav"
#define SOUND_FREEZE_EXPLODE	"ui/freeze_cam.wav"

#define FragColor 	{255,75,75,255}
#define FlashColor 	{255,255,255,255}
#define SmokeColor	{75,255,75,255}
#define FreezeColor	{75,75,255,255}

float NULL_VELOCITY[3] = {0.0, 0.0, 0.0};

int BeamSprite
	, GlowSprite
	, g_beamsprite
	, g_halosprite;

bool b_enable
	, b_trails
	, b_napalm_he
	, b_smoke_freeze
	, b_flash_light;

float f_flash_light_distance
 	, f_flash_light_duration
	, f_smoke_freeze_distance
	, f_smoke_freeze_duration
	, f_napalm_he_duration;

Handle h_greneffects_enable
	, h_greneffects_trails
	, h_greneffects_napalm_he
	, h_greneffects_napalm_he_duration
	, h_greneffects_smoke_freeze
	, h_greneffects_smoke_freeze_distance
	, h_greneffects_smoke_freeze_duration
	, h_greneffects_flash_light
	, h_greneffects_flash_light_distance
	, h_greneffects_flash_light_duration
	, h_fwdOnClientFreeze
	, h_fwdOnClientFreezed
	, h_fwdOnClientIgnite
	, h_fwdOnClientIgnited;

Handle h_freeze_timer[MAXPLAYERS+1];

public Plugin myinfo = 
{
	name = "[ZR] Grenade Effects",
	author = "FrozDark (HLModders.ru LLC)",
	description = "Adds Grenades Special Effects.",
	version = "2.1.0",
	url = "http://www.hlmod.ru"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	h_fwdOnClientFreeze = CreateGlobalForward("ZR_OnClientFreeze", ET_Hook, Param_Cell, Param_Cell, Param_FloatByRef);
	h_fwdOnClientFreezed = CreateGlobalForward("ZR_OnClientFreezed", ET_Ignore, Param_Cell, Param_Cell, Param_Float);
	
	h_fwdOnClientIgnite = CreateGlobalForward("ZR_OnClientIgnite", ET_Hook, Param_Cell, Param_Cell, Param_FloatByRef);
	h_fwdOnClientIgnited = CreateGlobalForward("ZR_OnClientIgnited", ET_Ignore, Param_Cell, Param_Cell, Param_Float);
	
	return APLRes_Success;
}

public void OnPluginStart()
{
	h_greneffects_enable = CreateConVar("zr_greneffect_enable", "1", "Enables/Disables the plugin", 0, true, 0.0, true, 1.0);
	h_greneffects_trails = CreateConVar("zr_greneffect_trails", "1", "Enables/Disables Grenade Trails", 0, true, 0.0, true, 1.0);
	
	h_greneffects_napalm_he = CreateConVar("zr_greneffect_napalm_he", "1", "Changes a he grenade to a napalm grenade", 0, true, 0.0, true, 1.0);
	h_greneffects_napalm_he_duration = CreateConVar("zr_greneffect_napalm_he_duration", "6", "The napalm duration", 0, true, 0.0);
	
	h_greneffects_smoke_freeze = CreateConVar("zr_greneffect_smoke_freeze", "1", "Changes a smoke grenade to a freeze grenade", 0, true, 0.0, true, 1.0);
	h_greneffects_smoke_freeze_distance = CreateConVar("zr_greneffect_smoke_freeze_distance", "600", "The freeze grenade distance", 0, true, 100.0);
	h_greneffects_smoke_freeze_duration = CreateConVar("zr_greneffect_smoke_freeze_duration", "4", "The freeze duration in seconds", 0, true, 1.0);
	
	h_greneffects_flash_light = CreateConVar("zr_greneffect_flash_light", "1", "Changes a flashbang to a flashlight", 0, true, 0.0, true, 1.0);
	h_greneffects_flash_light_distance = CreateConVar("zr_greneffect_flash_light_distance", "1000", "The light distance", 0, true, 100.0);
	h_greneffects_flash_light_duration = CreateConVar("zr_greneffect_flash_light_duration", "15.0", "The light duration in seconds", 0, true, 1.0);
	
	b_enable = GetConVarBool(h_greneffects_enable);
	b_trails = GetConVarBool(h_greneffects_trails);
	b_napalm_he = GetConVarBool(h_greneffects_napalm_he);
	b_smoke_freeze = GetConVarBool(h_greneffects_smoke_freeze);
	b_flash_light = GetConVarBool(h_greneffects_flash_light);
	
	f_napalm_he_duration = GetConVarFloat(h_greneffects_napalm_he_duration);
	f_smoke_freeze_distance = GetConVarFloat(h_greneffects_smoke_freeze_distance);
	f_smoke_freeze_duration = GetConVarFloat(h_greneffects_smoke_freeze_duration);
	f_flash_light_distance = GetConVarFloat(h_greneffects_flash_light_distance);
	f_flash_light_duration = GetConVarFloat(h_greneffects_flash_light_duration);
	
	HookConVarChange(h_greneffects_enable, OnConVarChanged);
	HookConVarChange(h_greneffects_trails, OnConVarChanged);
	HookConVarChange(h_greneffects_napalm_he, OnConVarChanged);
	HookConVarChange(h_greneffects_napalm_he_duration, OnConVarChanged);
	HookConVarChange(h_greneffects_smoke_freeze, OnConVarChanged);
	HookConVarChange(h_greneffects_smoke_freeze_distance, OnConVarChanged);
	HookConVarChange(h_greneffects_smoke_freeze_duration, OnConVarChanged);
	HookConVarChange(h_greneffects_flash_light, OnConVarChanged);
	HookConVarChange(h_greneffects_flash_light_distance, OnConVarChanged);
	HookConVarChange(h_greneffects_flash_light_duration, OnConVarChanged);
	
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
	if (convar == h_greneffects_enable)
	{
		b_enable = view_as<bool>(StringToInt(newValue));
	}
	else if (convar == h_greneffects_trails)
	{
		b_trails = view_as<bool>(StringToInt(newValue));
	}
	else if (convar == h_greneffects_napalm_he)
	{
		b_napalm_he = view_as<bool>(StringToInt(newValue));
	}
	else if (convar == h_greneffects_napalm_he)
	{
		f_napalm_he_duration = StringToFloat(newValue);
	}
	else if (convar == h_greneffects_smoke_freeze)
	{
		b_smoke_freeze = view_as<bool>(StringToInt(newValue));
	}
	else if (convar == h_greneffects_flash_light)
	{
		b_flash_light = view_as<bool>(StringToInt(newValue));
	}
	else if (convar == h_greneffects_smoke_freeze_distance)
	{
		f_smoke_freeze_distance = StringToFloat(newValue);
	}
	else if (convar == h_greneffects_smoke_freeze_duration)
	{
		f_smoke_freeze_duration = StringToFloat(newValue);
	}
	else if (convar == h_greneffects_flash_light_distance)
	{
		f_flash_light_distance = StringToFloat(newValue);
	}
	else if (convar == h_greneffects_flash_light_duration)
	{
		f_flash_light_duration = StringToFloat(newValue);
	}
}

public void OnMapStart() 
{
	BeamSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
	GlowSprite = PrecacheModel("sprites/blueglow2.vmt");
	g_beamsprite = PrecacheModel("materials/sprites/lgtning.vmt");
	g_halosprite = PrecacheModel("materials/sprites/halo01.vmt");
	
	PrecacheSound(SOUND_FREEZE);
	PrecacheSound(SOUND_FREEZE_EXPLODE);
}

public void OnClientDisconnect(int client)
{
	if (IsClientInGame(client))
		ExtinguishEntity(client);
	if (h_freeze_timer[client] != INVALID_HANDLE)
	{
		KillTimer(h_freeze_timer[client]);
		h_freeze_timer[client] = INVALID_HANDLE;
	}
}

public void OnRoundStart(Event event, const char[] name, bool dontBroadcast) 
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (h_freeze_timer[client] != INVALID_HANDLE)
		{
			KillTimer(h_freeze_timer[client]);
			h_freeze_timer[client] = INVALID_HANDLE;
		}
	}
}

public void OnPlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	if (!b_napalm_he)
	{
		return;
	}
	char g_szWeapon[32];
	GetEventString(event, "weapon", g_szWeapon, sizeof(g_szWeapon));
	
	if (!StrEqual(g_szWeapon, "hegrenade", false))
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
	float dummy_duration = f_napalm_he_duration;
	result = Forward_OnClientIgnite(client, attacker, dummy_duration);
	
	switch (result)
	{
		case Plugin_Handled, Plugin_Stop :
		{
			return;
		}
		case Plugin_Continue :
		{
			dummy_duration = f_napalm_he_duration;
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
	if (!b_enable || !b_napalm_he)
	{
		return;
	}
	
	float origin[3];
	origin[0] = GetEventFloat(event, "x"); origin[1] = GetEventFloat(event, "y"); origin[2] = GetEventFloat(event, "z");
	
	TE_SetupBeamRingPoint(origin, 10.0, 400.0, g_beamsprite, g_halosprite, 1, 1, 0.2, 100.0, 1.0, FragColor, 0, 0);
	TE_SendToAll();
}

public void OnSmokeDetonate(Event event, const char[] name, bool dontBroadcast) 
{
	if (!b_enable || !b_smoke_freeze)
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
		if (GetVectorDistance(origin, targetOrigin) <= f_smoke_freeze_distance)
		{
			Handle trace = TR_TraceRayFilterEx(origin, targetOrigin, MASK_SOLID, RayType_EndPoint, FilterTarget, i);
		
			if ((TR_DidHit(trace) && TR_GetEntityIndex(trace) == i) || (GetVectorDistance(origin, targetOrigin) <= 100.0))
			{
				Freeze(i, client, f_smoke_freeze_duration);
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
					Freeze(i, client, f_smoke_freeze_duration);
				}
				
				CloseHandle(trace);
			}
		}
	}
	
	TE_SetupBeamRingPoint(origin, 10.0, f_smoke_freeze_distance, g_beamsprite, g_halosprite, 1, 1, 0.2, 100.0, 1.0, FreezeColor, 0, 0);
	TE_SendToAll();
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
	
	if (h_freeze_timer[client] != INVALID_HANDLE)
	{
		KillTimer(h_freeze_timer[client]);
		h_freeze_timer[client] = INVALID_HANDLE;
	}
	
	SetEntityMoveType(client, MOVETYPE_NONE);
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, NULL_VELOCITY);
	
	float vec[3];
	GetClientEyePosition(client, vec);
	vec[2] -= 50.0;
	EmitAmbientSound(SOUND_FREEZE, vec, client, SNDLEVEL_RAIDSIREN);

	TE_SetupGlowSprite(vec, GlowSprite, dummy_duration, 2.0, 50);
	TE_SendToAll();
	
	h_freeze_timer[client] = CreateTimer(dummy_duration, Unfreeze, client, TIMER_FLAG_NO_MAPCHANGE);
	
	Forward_OnClientFreezed(client, attacker, dummy_duration);
	
	return true;
}

public Action Unfreeze(Handle timer, any client)
{
	if (h_freeze_timer[client] != INVALID_HANDLE)
	{
		SetEntityMoveType(client, MOVETYPE_WALK);
		h_freeze_timer[client] = INVALID_HANDLE;
	}
	
	return Plugin_Continue;
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (!b_enable)
	{
		return;
	}
	
	if (!strcmp(classname, "hegrenade_projectile"))
	{
		BeamFollowCreate(entity, FragColor);
		if (b_napalm_he)
		{
			IgniteEntity(entity, 2.0);
		}
	}
	else if (!strcmp(classname, "flashbang_projectile"))
	{
		if (b_flash_light)
		{
			CreateTimer(1.3, DoFlashLight, entity, TIMER_FLAG_NO_MAPCHANGE);
		}
		BeamFollowCreate(entity, FlashColor);
	}
	else if (!strcmp(classname, "smokegrenade_projectile"))
	{
		if (b_smoke_freeze)
		{
			BeamFollowCreate(entity, FreezeColor);
			CreateTimer(1.3, CreateEvent_SmokeDetonate, entity, TIMER_FLAG_NO_MAPCHANGE);
		}
		else
		{
			BeamFollowCreate(entity, SmokeColor);
		}
	}
	else if (b_smoke_freeze && !strcmp(classname, "env_particlesmokegrenade"))
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
	if (b_trails)
	{
		TE_SetupBeamFollow(entity, BeamSprite,	0, 1.0, 10.0, 10.0, 5, color);
		TE_SendToAll();	
	}
}

void LightCreate(int grenade, float pos[3])   
{  
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
			DispatchKeyValueFloat(iEntity, "distance", f_flash_light_distance);
			EmitSoundToAll("items/nvg_on.wav", iEntity, SNDCHAN_WEAPON);
			CreateTimer(f_flash_light_duration, Delete, iEntity, TIMER_FLAG_NO_MAPCHANGE);
		}
		case SMOKE : 
		{
			DispatchKeyValue(iEntity, "_light", "75 75 255 255");
			DispatchKeyValueFloat(iEntity, "distance", f_smoke_freeze_distance);
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
	if (b_smoke_freeze && !strcmp(sample, "^weapons/smokegrenade/sg_explode.wav"))
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

/*
		F O R W A R D S
	------------------------------------------------
*/

Action Forward_OnClientFreeze(int client, int attacker, float &time)
{
	Action result;
	result = Plugin_Continue;
	
	Call_StartForward(h_fwdOnClientFreeze);
	Call_PushCell(client);
	Call_PushCell(attacker);
	Call_PushFloatRef(time);
	Call_Finish(result);
	
	return result;
}

void Forward_OnClientFreezed(int client, int attacker, float time)
{
	Call_StartForward(h_fwdOnClientFreezed);
	Call_PushCell(client);
	Call_PushCell(attacker);
	Call_PushFloat(time);
	Call_Finish();
}

Action Forward_OnClientIgnite(int client, int attacker, float &time)
{
	Action result;
	result = Plugin_Continue;
	
	Call_StartForward(h_fwdOnClientIgnite);
	Call_PushCell(client);
	Call_PushCell(attacker);
	Call_PushFloatRef(time);
	Call_Finish(result);
	
	return result;
}

void Forward_OnClientIgnited(int client, int attacker, float time)
{
	Call_StartForward(h_fwdOnClientIgnited);
	Call_PushCell(client);
	Call_PushCell(attacker);
	Call_PushFloat(time);
	Call_Finish();
}
