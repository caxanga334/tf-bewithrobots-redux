#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <autoexecconfig>
#include <smlib/math>
#include <stocksoup/sdkports/vector>
#include <stocksoup/tf/tempents_stocks>
#include <stocksoup/math>
#define REQUIRE_PLUGIN
#include <tf2attributes>
#include <tf2utils>
#undef REQUIRE_EXTENSIONS
#include <steamworks>
#define REQUIRE_EXTENSIONS
#define AUTOLOAD_EXTENSIONS
#include <tf2items>
#include <sdkhooks>
#include <dhooks>
#include <cbasenpc>
#include <bwrr_stocks>
#include <bwrr_api>

#define PLUGIN_VERSION "2.0.0-alpha"
#define TF_CURRENCY_PACK_CUSTOM 9
#define MAX_SUBPLUGINS 64

/**
 * -- BUGS --
 * Human spy eye particle is visible (NEEDS TESTING)
 * RED player spawned with robot model (NEEDS TESTING)
 * fix sentry buster mission (DONE)
 */

// debug
#define _bwrr_debug_

// Speak Concepts

enum
{
	MP_CONCEPT_MVM_BOMB_CARRIER_UPGRADE1 = 99,
	MP_CONCEPT_MVM_BOMB_CARRIER_UPGRADE2 = 100,
	MP_CONCEPT_MVM_BOMB_CARRIER_UPGRADE3 = 101,
	MP_CONCEPT_MVM_BOMB_PICKUP = 104,
	MP_CONCEPT_MVM_SENTRY_BUSTER = 105,
	MP_CONCEPT_MVM_SENTRY_BUSTER_DOWN = 106,
	MP_CONCEPT_MVM_SNIPER_CALLOUT = 107,
	MP_CONCEPT_MVM_GIANT_CALLOUT = 113,
	MP_CONCEPT_MVM_GIANT_HAS_BOMB = 114,
	MP_CONCEPT_MVM_GIANT_KILLED = 115,
	MP_CONCEPT_MVM_GIANT_KILLED_TEAMMATE = 116,
};

ArrayList g_subplugins_robots; // List of robots sub plugins
int g_subplugins_ID[MAX_SUBPLUGINS]; // List of robots sub plugins ID
bool g_islateload;

char g_strModelRobots[][] = {"", "models/bots/scout/bot_scout.mdl", "models/bots/sniper/bot_sniper.mdl", "models/bots/soldier/bot_soldier.mdl", "models/bots/demo/bot_demo.mdl", "models/bots/medic/bot_medic.mdl", "models/bots/heavy/bot_heavy.mdl", "models/bots/pyro/bot_pyro.mdl", "models/bots/spy/bot_spy.mdl", "models/bots/engineer/bot_engineer.mdl"};
int g_iModelIndexRobots[sizeof(g_strModelRobots)];
char g_strModelHumans[][] =  {"", "models/player/scout.mdl", "models/player/sniper.mdl", "models/player/soldier.mdl", "models/player/demo.mdl", "models/player/medic.mdl", "models/player/heavy.mdl", "models/player/pyro.mdl", "models/player/spy.mdl", "models/player/engineer.mdl"};
int g_iModelIndexHumans[sizeof(g_strModelHumans)];

float g_flNextCommand[MAXPLAYERS + 1]; // delayed command timer

int g_te_laser, g_te_halo;

enum struct erobotplayer
{
	bool isrobot;
	bool carrier;
	bool deploying;
	bool gatebot;
	bool inspawn;
	bool hasloopsound;
	bool isdetonating;
	int templateindex;
	int type;
	int bomblevel;
	float nextbombupgradetime;
	float deployingtime;
	float lastspawntime;
	float bustertimer;
	char loopsound[PLATFORM_MAX_PATH];
}
erobotplayer g_eRobotPlayer[MAXPLAYERS+1];

methodmap RobotPlayer
{
	public RobotPlayer(int index) { return view_as<RobotPlayer>(index); }
	property int index 
	{ 
		public get()	{ return view_as<int>(this); }
	}
	property bool isrobot
	{
		public get() { return g_eRobotPlayer[this.index].isrobot; }
		public set( bool value ) { g_eRobotPlayer[this.index].isrobot = value; }
	}
	property bool carrier
	{
		public get() { return g_eRobotPlayer[this.index].carrier; }
		public set( bool value ) { g_eRobotPlayer[this.index].carrier = value; }
	}
	property bool deploying
	{
		public get() { return g_eRobotPlayer[this.index].deploying; }
		public set( bool value ) { g_eRobotPlayer[this.index].deploying = value; }
	}
	property bool gatebot
	{
		public get() { return g_eRobotPlayer[this.index].gatebot; }
		public set( bool value ) { g_eRobotPlayer[this.index].gatebot = value; }
	}
	property bool inspawn
	{
		public get() { return g_eRobotPlayer[this.index].inspawn; }
		public set( bool value ) { g_eRobotPlayer[this.index].inspawn = value; }
	}
	property bool hasloopsound
	{
		public get() { return g_eRobotPlayer[this.index].hasloopsound; }
		public set( bool value ) { g_eRobotPlayer[this.index].hasloopsound = value; }
	}
	property bool isdetonating
	{
		public get() { return g_eRobotPlayer[this.index].isdetonating; }
		public set( bool value ) { g_eRobotPlayer[this.index].isdetonating = value; }
	}
	property int templateindex
	{
		public get() { return g_eRobotPlayer[this.index].templateindex; }
		public set( int value ) { g_eRobotPlayer[this.index].templateindex = value; }
	}
	property int type
	{
		public get() { return g_eRobotPlayer[this.index].type; }
		public set( int value ) { g_eRobotPlayer[this.index].type = value; }
	}
	property int bomblevel
	{
		public get() { return g_eRobotPlayer[this.index].bomblevel; }
		public set( int value ) { g_eRobotPlayer[this.index].bomblevel = value; }
	}
	property float nextbombupgradetime
	{
		public get() { return g_eRobotPlayer[this.index].nextbombupgradetime; }
		public set( float value ) { g_eRobotPlayer[this.index].nextbombupgradetime = value; }
	}
	property float lastspawntime
	{
		public get() { return g_eRobotPlayer[this.index].lastspawntime; }
		public set( float value ) { g_eRobotPlayer[this.index].lastspawntime = value; }
	}
	property float deployingtime
	{
		public get() { return g_eRobotPlayer[this.index].deployingtime; }
		public set( float value ) { g_eRobotPlayer[this.index].deployingtime = value; }
	}
	property float bustertimer
	{
		public get() { return g_eRobotPlayer[this.index].bustertimer; }
		public set( float value ) { g_eRobotPlayer[this.index].bustertimer = value; }
	}
	public void SetMiniboss(bool value)
	{
		SetEntProp(this.index, Prop_Send, "m_bIsMiniBoss", view_as<int>(value));
	}
	public void ResetData()
	{
		g_eRobotPlayer[this.index].isrobot = false;
		g_eRobotPlayer[this.index].carrier = false;
		g_eRobotPlayer[this.index].deploying = false;
		g_eRobotPlayer[this.index].gatebot = false;
		g_eRobotPlayer[this.index].inspawn = false;
		g_eRobotPlayer[this.index].isdetonating = false;
		g_eRobotPlayer[this.index].templateindex = -1;
		g_eRobotPlayer[this.index].type = BWRR_RobotType_Invalid;
		g_eRobotPlayer[this.index].bomblevel = 0;
		g_eRobotPlayer[this.index].nextbombupgradetime = 0.0;
		g_eRobotPlayer[this.index].deployingtime = 0.0;
		g_eRobotPlayer[this.index].lastspawntime = 0.0;
		g_eRobotPlayer[this.index].bustertimer = 0.0;
	}
	public void OnDeathReset()
	{
		g_eRobotPlayer[this.index].carrier = false;
		g_eRobotPlayer[this.index].deploying = false;
		g_eRobotPlayer[this.index].gatebot = false;
		g_eRobotPlayer[this.index].inspawn = false;
		g_eRobotPlayer[this.index].isdetonating = false;
		g_eRobotPlayer[this.index].templateindex = -1;
		g_eRobotPlayer[this.index].type = BWRR_RobotType_Invalid;
		g_eRobotPlayer[this.index].bomblevel = 0;
		g_eRobotPlayer[this.index].nextbombupgradetime = 0.0;
		g_eRobotPlayer[this.index].deployingtime = 0.0;
		g_eRobotPlayer[this.index].bustertimer = 0.0;
		this.SetMiniboss(false);
	}
	public void OnSpawn()
	{
		g_eRobotPlayer[this.index].lastspawntime = GetGameTime();
	}
	public void SetRobot(int type, int index)
	{
		g_eRobotPlayer[this.index].type = type;
		g_eRobotPlayer[this.index].templateindex = index;
	}
	public void GetRobot(int &type, int &index)
	{
		type = g_eRobotPlayer[this.index].type;
		index = g_eRobotPlayer[this.index].templateindex;
	}
	public void StartDeploying(float time)
	{
		g_eRobotPlayer[this.index].deployingtime = time + GetGameTime();
		g_eRobotPlayer[this.index].deploying = true;
	}
	public void StopDeploying()
	{
		g_eRobotPlayer[this.index].deployingtime = 0.0;
		g_eRobotPlayer[this.index].deploying = false;
	}
	public void SetLoopSound(char[] sound)
	{
		g_eRobotPlayer[this.index].hasloopsound = true;
		strcopy(g_eRobotPlayer[this.index].loopsound, PLATFORM_MAX_PATH, sound);
	}
	public void StopLoopSound()
	{
		g_eRobotPlayer[this.index].hasloopsound = false;
		StopSound(this.index, SNDCHAN_STATIC, g_eRobotPlayer[this.index].loopsound);
	}
	public void BeginToDetonate(const float delay)
	{
		g_eRobotPlayer[this.index].isdetonating = true;
		g_eRobotPlayer[this.index].bustertimer = GetGameTime() + delay;
	}
	public void OnBusterExplode()
	{
		g_eRobotPlayer[this.index].isdetonating = false;
		g_eRobotPlayer[this.index].bustertimer = 0.0;	
	}
}

#include "bwrredux/api.sp"
#include "bwrredux/gamedata.sp"
#include "bwrredux/detours.sp"
#include "bwrredux/convars.sp"
#include "bwrredux/gameevents.sp"
#include "bwrredux/functions.sp"
#include "bwrredux/robots.sp"
#include "bwrredux/director.sp"
#include "bwrredux/sdk.sp"
#include "bwrredux/commands.sp"

public Plugin myinfo =
{
	name = "[TF2] Be With Robots Redux",
	author = "caxanga334",
	description = "Allows players to play as a robot in MvM",
	version = PLUGIN_VERSION,
	url = "https://github.com/caxanga334/tf-bewithrobots-redux"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion ev = GetEngineVersion();
	g_islateload = late;
	g_subplugins_robots = new ArrayList(64);
	RegPluginLibrary("tf_bwr_redux");
	SetupForwards();
	SetupNatives();
	SetupGameEvents();

	if(ev == Engine_TF2)
	{
		return APLRes_Success;
	}
	else
	{
		strcopy(error, err_max, "This plugin is for Team Fortress 2 only.");
		return APLRes_Failure;
	}
}

public void OnPluginStart()
{
	LoadTranslations("common.phrases.txt");
	LoadTranslations("bwrredux.phrases");

	SetupConVars();
	SetupPluginCommands();
	SetupCommandListeners();
	SetupGamedata();
	SetupEntityHooks();

	if(g_islateload) // To-do: Add late loading logic
	{
		PrintToServer("[BWRR] Late load detected!");
	}
}

public void OnAllPluginsLoaded()
{
	if(LibraryExists("SteamWorks"))
	{
		SteamWorks_SetGameDescription("Be With Robots Redux");
	}
}

public void OnLibraryAdded(const char[] name)
{
	if(strcmp(name, "SteamWorks") == 0)
	{
		SteamWorks_SetGameDescription("Be With Robots Redux");
	}
}

public void OnMapStart()
{
	if(!IsPlayingMannVsMachine())
	{
		SetFailState("This plugins is for Mann vs Machine only!");
	}

	for(int x = 1;x < sizeof(g_iModelIndexHumans);x++) { g_iModelIndexHumans[x] = PrecacheModel(g_strModelHumans[x]); }
	for(int x = 1;x < sizeof(g_iModelIndexRobots);x++) { g_iModelIndexRobots[x] = PrecacheModel(g_strModelRobots[x]); }

	PrecacheScriptSound("MVM.DeployBombSmall");
	PrecacheScriptSound("MVM.DeployBombGiant");
	PrecacheScriptSound("MVM.Warning");
	PrecacheScriptSound("MVM.Robot_Engineer_Spawn");
	PrecacheScriptSound("Announcer.MVM_Spy_Alert");
	PrecacheScriptSound("Announcer.MVM_Sentry_Buster_Alert");
	PrecacheScriptSound("Announcer.MVM_Sentry_Buster_Alert_Another");
	PrecacheScriptSound("Announcer.mvm_spybot_death_all");
	PrecacheScriptSound("Announcer.MVM_First_Engineer_Teleport_Spawned");
	PrecacheScriptSound("Announcer.MVM_Another_Engineer_Teleport_Spawned");
	PrecacheScriptSound("Announcer.MVM_An_Engineer_Bot_Is_Dead");
	PrecacheScriptSound("Announcer.MVM_An_Engineer_Bot_Is_Dead_But_Not_Teleporter");
	PrecacheScriptSound("Announcer.MVM_Engineer_Teleporter_Activated");
	PrecacheScriptSound("MVM.GiantCommonExplodes");
	PrecacheScriptSound("MVM.SentryBusterExplode");
	PrecacheScriptSound("MVM.SentryBusterSpin");
	PrecacheScriptSound("MVM.SentryBusterIntro");
	PrecacheSound("buttons/button10.wav");

	for(int i = 0;i < sizeof(g_flAnnouncements);i++) { g_flAnnouncements[i] = 0.0; }

	g_te_laser = PrecacheModel("materials/sprites/laserbeam.vmt");
	g_te_halo = PrecacheModel("materials/sprites/halo01.vmt");
}

public void OnMapEnd()
{
	delete g_eDirector.timer;
}

public void TF2_OnWaitingForPlayersStart()
{
	CreateTimer(1.0, Timer_CheckGates, _, TIMER_FLAG_NO_MAPCHANGE);
}

public void TF2_OnWaitingForPlayersEnd()
{
	CreateTimer(1.0, Timer_CheckGates, _, TIMER_FLAG_NO_MAPCHANGE);
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamageAlivePost, OnPlayerTakeDamageAlivePost);
}

public void OnClientDisconnect(int client)
{
	RobotPlayer rp = RobotPlayer(client);
	rp.ResetData();

	if(rp.hasloopsound)
	{
		rp.StopLoopSound();
	}
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if(strcmp(classname, "func_respawnroom", false) == 0)
	{
		SetupHook_SpawnRoom(entity);
	}
	else if(strcmp(classname, "func_capturezone", false) == 0)
	{
		SDKHook(entity, SDKHook_StartTouchPost, OnStartTouchCaptureZone);
		SDKHook(entity, SDKHook_EndTouchPost, OnEndTouchCaptureZone);
	}
	else if(strcmp(classname, "filter_tf_bot_has_tag", false) == 0)
	{
		SDKHook(entity, SDKHook_SpawnPost, OnTFBotTagFilterSpawnPost);
	}
	else if (strcmp(classname, "entity_revive_marker", false) == 0)
	{
		SDKHook(entity, SDKHook_SpawnPost, OnReviveMarkerSpawnPost);
	}
	else if(strcmp(classname, "tf_ammo_pack") == 0)
	{
		SDKHook(entity, SDKHook_SpawnPost, OnAmmoPackSpawnPost);
	}
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	if(IsFakeClient(client))
		return Plugin_Continue;

	RobotPlayer rp = RobotPlayer(client);
	TFTeam team = TF2_GetClientTeam(client);
	float origin[3];
	GetClientAbsOrigin(client, origin);

	if(rp.isrobot && team == TFTeam_Blue && IsPlayerAlive(client))
	{
		if(rp.inspawn)
		{
			SetEntPropFloat(client, Prop_Send, "m_flStealthNoAttackExpire", GetGameTime() + 0.5);
			TF2_AddCondition(client, TFCond_UberchargedHidden, 1.0);
		}

		if(rp.deploying)
		{
			if(rp.deployingtime <= GetGameTime())
			{
				rp.StopDeploying();
				TF2BWR_TriggerBombHatch(client);
			}
		}

		if(rp.carrier && !rp.inspawn)
		{
			if(rp.bomblevel > 0) // apply defensive buff to nearby robots
			{
				for(int i = 1; i <= MaxClients; i++)
				{
					if(i == client) 
						continue;
				
					if(!IsClientInGame(i))
						continue;
						
					if(GetClientTeam(i) != GetClientTeam(client))
						continue;
					
					if(rp.bomblevel < 1)
						continue;
						
					float target[3];
					GetClientAbsOrigin(i, target);
					
					float flDistance = GetVectorDistance(origin, target);
					
					if(flDistance <= 450.0)
					{
						TF2_AddCondition(i, TFCond_DefenseBuffNoCritBlock, 0.125);
					}
				}
			}

			if(rp.nextbombupgradetime <= GetGameTime() && rp.bomblevel < 3 && GetEntPropEnt(client, Prop_Send, "m_hGroundEntity") != -1)
			{
				FakeClientCommandThrottled(client, "taunt");

				if(TF2_IsPlayerInCondition(client, TFCond_Taunting))
				{
					rp.bomblevel++;
					EmitGameSoundToAll("MVM.Warning", SOUND_FROM_WORLD);
					RequestFrame(Frame_UpdateBombHUD, GetClientSerial(client));

					Call_StartForward(g_OnBombUpgrade);
					Call_PushCell(client);
					Call_PushCell(g_eTemplates[rp.templateindex].pluginID);
					Call_PushCell(TF2_GetPlayerClass(client));
					Call_PushCell(g_eTemplates[rp.templateindex].index);
					Call_PushCell(g_eTemplates[rp.templateindex].type);
					Call_PushCell(rp.bomblevel);
					Call_Finish();

					switch(rp.bomblevel)
					{
						case 1:
						{
							rp.nextbombupgradetime = GetGameTime() + c_bomb_upgrade2.FloatValue;
							TF2_SpeakConcept(MP_CONCEPT_MVM_BOMB_CARRIER_UPGRADE1, view_as<int>(TFTeam_Red), "");
						}
						case 2:
						{
							Address pRegen = TF2Attrib_GetByName(client, "health regen");
							float flRegen = 0.0;
							if(pRegen != Address_Null)
							{
								flRegen = TF2Attrib_GetValue(pRegen);
							}
							TF2Attrib_SetByName(client, "health regen", flRegen + 45.0);
							rp.nextbombupgradetime = GetGameTime() + c_bomb_upgrade3.FloatValue;
							TF2_SpeakConcept(MP_CONCEPT_MVM_BOMB_CARRIER_UPGRADE2, view_as<int>(TFTeam_Red), "");
						}
						case 3:
						{
							TF2_AddCondition(client, TFCond_CritOnWin);
							TF2_SpeakConcept(MP_CONCEPT_MVM_BOMB_CARRIER_UPGRADE3, view_as<int>(TFTeam_Red), "");
						}
					}
				}
			}
		}

		/* SENTRY BUSTER */
		if(rp.type == BWRR_RobotType_Buster)
		{
			if(buttons & IN_ATTACK)
			{
				FakeClientCommandThrottled(client, "taunt");
			}

			if(TF2_IsPlayerInCondition(client, TFCond_Taunting))
			{
				Robots_OnBeginSentryBusterDetonation(client);
			}

			if(rp.isdetonating)
			{
				if(rp.bustertimer <= GetGameTime())
				{
					Robots_OnSentryBusterExplode(client);
				}
			}
		}
	}
	
	return Plugin_Continue;
}