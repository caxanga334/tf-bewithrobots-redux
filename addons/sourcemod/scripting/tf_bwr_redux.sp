#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <autoexecconfig>
#define REQUIRE_PLUGIN
#include <tf2attributes>
#include <tf2utils>
#undef REQUIRE_EXTENSIONS
#include <steamworks>
#define REQUIRE_EXTENSIONS
#define AUTOLOAD_EXTENSIONS
#include <sdkhooks>
#include <dhooks>
#include <cbasenpc>
#include <bwrr_stocks>
#include <bwrr_api>

#define PLUGIN_VERSION "2.0.0-alpha"
#define TF_CURRENCY_PACK_CUSTOM 9

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
bool g_islateload;

char g_strModelRobots[][] = {"", "models/bots/scout/bot_scout.mdl", "models/bots/sniper/bot_sniper.mdl", "models/bots/soldier/bot_soldier.mdl", "models/bots/demo/bot_demo.mdl", "models/bots/medic/bot_medic.mdl", "models/bots/heavy/bot_heavy.mdl", "models/bots/pyro/bot_pyro.mdl", "models/bots/spy/bot_spy.mdl", "models/bots/engineer/bot_engineer.mdl"};
int g_iModelIndexRobots[sizeof(g_strModelRobots)];
char g_strModelHumans[][] =  {"", "models/player/scout.mdl", "models/player/sniper.mdl", "models/player/soldier.mdl", "models/player/demo.mdl", "models/player/medic.mdl", "models/player/heavy.mdl", "models/player/pyro.mdl", "models/player/spy.mdl", "models/player/engineer.mdl"};
int g_iModelIndexHumans[sizeof(g_strModelHumans)];

enum struct erobotplayer
{
	bool isrobot; // Is a robot player
	bool carrier; // Is a bomb carrier
	bool deploying; // Is deploying the bomb
	bool gatebot; // Is a gatebot
	int templateindex; // Index of the current template
	int type; // Current robot type
	int bomblevel; // Current bomb level
	float nextbombupgradetime; // Bomb upgrade timer
	float deployingtime; // Bomb deploying timer
	float lastspawntime; // The last time this player spawned
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
	public void Miniboss(bool value)
	{
		SetEntProp( this.index, Prop_Send, "m_bIsMiniBoss", view_as<int>(value) );
	}
	public void ResetData()
	{
		g_eRobotPlayer[this.index].isrobot = false;
		g_eRobotPlayer[this.index].carrier = false;
		g_eRobotPlayer[this.index].deploying = false;
		g_eRobotPlayer[this.index].gatebot = false;
		g_eRobotPlayer[this.index].templateindex = -1;
		g_eRobotPlayer[this.index].type = BWRR_RobotType_Invalid;
		g_eRobotPlayer[this.index].bomblevel = 0;
		g_eRobotPlayer[this.index].nextbombupgradetime = 0.0;
		g_eRobotPlayer[this.index].deployingtime = 0.0;
		g_eRobotPlayer[this.index].lastspawntime = 0.0;
	}
	public void OnDeathReset()
	{
		g_eRobotPlayer[this.index].carrier = false;
		g_eRobotPlayer[this.index].deploying = false;
		g_eRobotPlayer[this.index].gatebot = false;
		g_eRobotPlayer[this.index].templateindex = -1;
		g_eRobotPlayer[this.index].type = BWRR_RobotType_Invalid;
		g_eRobotPlayer[this.index].bomblevel = 0;
		g_eRobotPlayer[this.index].nextbombupgradetime = 0.0;
		g_eRobotPlayer[this.index].deployingtime = 0.0;	
	}
}

#include "bwrredux/api.sp"
#include "bwrredux/gamedata.sp"
#include "bwrredux/detours.sp"
#include "bwrredux/sdk.sp"
#include "bwrredux/convars.sp"
#include "bwrredux/commands.sp"
#include "bwrredux/gameevents.sp"
#include "bwrredux/functions.sp"
#include "bwrredux/robots.sp"
#include "bwrredux/director.sp"

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

	if(g_islateload) // To-do: Add late loading logic
	{
		PrintToServer("[BWRR] Late load detected!");
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
}

public void TF2_OnWaitingForPlayersStart()
{
	PrintToServer("TF2_OnWaitingForPlayersStart");
}

public void TF2_OnWaitingForPlayersEnd()
{
	PrintToServer("TF2_OnWaitingForPlayersEnd");
}

public void OnClientPutInServer(int client)
{

}

public void OnClientDisconnect(int client)
{
	RobotPlayer rp = RobotPlayer(client);
	rp.ResetData();
}