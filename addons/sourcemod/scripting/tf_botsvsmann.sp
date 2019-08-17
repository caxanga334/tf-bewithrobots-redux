#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
// #include <tf2attributes>
// #include <tf2_isPlayerInSpawn>
// #include <tf2wearables>
#include <morecolors>
#define REQUIRE_EXTENSIONS
#define AUTOLOAD_EXTENSIONS
#include <tf2items>
#include "botvsmann/objectiveres.sp"
#include "botvsmann/bot_variants.sp"

#define PLUGIN_VERSION "0.0.1"

// maximum class variants that exists
#define MAX_SCOUT 1
#define MAX_SCOUT_GIANT 1
#define MAX_SOLDIER 1
#define MAX_SOLDIER_GIANT 1
#define MAX_PYRO 1
#define MAX_PYRO_GIANT 1
#define MAX_DEMO 1
#define MAX_DEMO_GIANT 1
#define MAX_HEAVY 1
#define MAX_HEAVY_GIANT 1
#define MAX_ENGINEER 1
#define MAX_ENGINEER_GIANT 1
#define MAX_MEDIC 1
#define MAX_MEDIC_GIANT 1
#define MAX_SNIPER 1
#define MAX_SNIPER_GIANT 1
#define MAX_SPY 1
#define MAX_SPY_GIANT 1

// player robot variants
int iBotType[MAXPLAYERS + 1];
int iBotVariant[MAXPLAYERS + 1];
TFClassType BotClass[MAXPLAYERS + 1];

ArrayList ay_avclass; // array containing available classes

// others
bool g_bUpgradeStation[MAXPLAYERS + 1];

// convars
ConVar c_iMinRed;
ConVar c_iGiantChance;

enum
{
	BotSkill_Easy,
	BotSkill_Normal,
	BotSkill_Hard,
	BotSkill_Expert
};

enum
{
	Bot_Normal = 0,
	Bot_Small = 1,
	Bot_Big = 2,
	Bot_Giant = 3,
	Bot_Buster = 4,
	Bot_Boss = 5,
};
 
public Plugin myinfo =
{
	name = "[TF2] Robots vs Mann",
	author = "caxanga334",
	description = "Allows players to play as a robot in MvM",
	version = PLUGIN_VERSION,
	url = "https://github.com/caxanga334"
};

stock APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	char gamefolder[32]
	GetGameFolderName(gamefolder, sizeof(gamefolder));
	if(!StrEqual(gamefolder, "tf")
	{
		LogError("This plugin is for TF2 only!");
		return APLRes_Failure;
	}
	else
	{
		return APLRes_Success;
	}
}

public void OnPluginStart()
{	
	// convars
	CreateConVar("sm_botvsmann_version", PLUGIN_VERSION, "Robots vs Mann plugin version.", FCVAR_NOTIFY);
	c_iMinRed = CreateConVar("sm_bvm_minred", 3, "Minimum amount of players on RED team to allow joining ROBOTs.", FCVAR_NOTIFY, true, 0.0, true, 10.0);
	c_iGiantChance = CreateConVar("sm_bmv_giantchance", 30, "Chance in percentage to human players to spawn as a giant. 0 = Disabled.", FCVAR_NOTIFY, true, 0.0, true, 100.0);

	RegConsoleCmd( "sm_joinred", Command_JoinRED, "Joins RED team." );
	RegConsoleCmd( "sm_joinblu", Command_JoinBLU, "Joins BLU/Robot team." );
	RegConsoleCmd( "sm_joinblue", Command_JoinBLU, "Joins BLU/Robot team." );
	RegConsoleCmd( "sm_bwr", Command_JoinBLU, "Joins BLU/Robot team." );
	RegConsoleCmd( "sm_bewithrobots", Command_JoinBLU, "Joins BLU/Robot team." );
	RegAdminCmd( "sm_bvm_debug", Command_Debug, ADMFLAG_ROOT, "Debug command" );
	
	// EVENTS
	HookEvent( "mvm_begin_wave", E_WaveStart );
	HookEvent( "mvm_wave_complete", E_WaveEnd );
	HookEvent( "mvm_wave_failed", E_WaveFailed );
	HookEvent( "mvm_mission_complete", E_MissionComplete );
	HookEvent( "player_changeclass", E_ChangeClass );
	HookEvent( "player_death", E_PlayerDeath );
	HookEvent( "player_death", E_Pre_PlayerDeath, EventHookMode_Pre );
	HookEvent( "player_spawn", E_Pre_PlayerSpawn, EventHookMode_Pre );
	HookEvent( "player_spawn", E_PlayerSpawn );
	HookEvent( "post_inventory_application", E_Inventory );
	
	ay_avclass = new ArrayList(10);
}

public void OnMapStart()
{
	if(!IsMvM())
	{
		SetFailState("This plugin is for Mann vs Machine Only.") // probably easier than add IsMvM everywhere
	}
}

/* public OnClientConnected(client)
{

} */

public OnClientDisconnect(client)
{
	iBotType[client] = Bot_Normal;
	iBotVariant[client] = 0;
	g_bUpgradeStation[client] = false;
}

// IsMvM code by FlaminSarge
bool IsMvM(bool forceRecalc = false)
{
	static bool found = false;
	static bool ismvm = false;
	if (forceRecalc)
	{
		found = false;
		ismvm = false;
	}
	if (!found)
	{
		int i = FindEntityByClassname(-1, "tf_logic_mann_vs_machine");
		if (i > MaxClients && IsValidEntity(i)) ismvm = true;
		found = true;
	}
	return ismvm;
}

/****************************************************
					COMMANDS
*****************************************************/

public Action Command_JoinBLU( int client, int nArgs )
{
	MovePlayerToBLU(client);	
	return Plugin_Handled;
}
public Action Command_JoinRED( int client, int nArgs )
{
	if( !IsClientInGame(client) || IsFakeClient(client) )
		return Plugin_Continue;
		
	TF2_ChangeClientTeam(client, TFTeam_Red);

	return Plugin_Handled;
}

public Action Command_Debug( int client, int nArgs )
{
	int iClasses = OR_GetAvailableClasses();
	ReplyToCommand(client, "Available Classes: %i", iClasses);
	
	return Plugin_Handled;
}

/****************************************************
					EVENTS
*****************************************************/

public Action E_WaveStart(Event event, const char[] name, bool dontBroadcast)
{
	OR_Update();
	UpdateClassArray();
}

public Action E_WaveEnd(Event event, const char[] name, bool dontBroadcast)
{
	OR_Update();
	UpdateClassArray();
}

public Action E_WaveFailed(Event event, const char[] name, bool dontBroadcast)
{
	OR_Update();
	UpdateClassArray();
}

public Action E_MissionComplete(Event event, const char[] name, bool dontBroadcast)
{
	OR_Update(); // placeholder
}

public Action E_ChangeClass(Event event, const char[] name, bool dontBroadcast)
{
	PrintToChatAll("E_ChangeClass");
}

public Action E_Pre_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	PrintToChatAll("E_Pre_PlayerSpawn");
}

public Action E_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	PrintToChatAll("E_PlayerSpawn");
}

public Action E_Pre_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	PrintToChatAll("E_Pre_PlayerDeath");
}

public Action E_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	PrintToChatAll("E_PlayerDeath");
}

public Action E_Inventory(Event event, const char[] name, bool dontBroadcast)
{
	int client = event.GetInt("userid");
	TFTeam Team = TF2_GetClientTeam(client);
	
	if(Team == TFTeam_Blue && !IsFakeClient(client) && IsClientInGame(client))
	{
		if( iBotVariant[client] >= 0 )
		{
			StripItems(client, true);
		}
		else
		{
			StripItems(client, false);
		}

	}
}


/****************************************************
					FUNCTIONS
*****************************************************/

// ***PLAYER***

// moves player to BLU team.
void MovePlayerToBLU(int client)
{
	if( !IsFakeClient(client) )
	{
		SetEntProp( client, Prop_Send, "m_nBotSkill", BotSkill_Easy );
		SetEntProp( client, Prop_Send, "m_bIsMiniBoss", _:false );
	}
	
	int iEntFlags = GetEntityFlags( client );
	SetEntityFlags( client, iEntFlags | FL_FAKECLIENT );
	//ChangeClientTeam( client, _:TFTeam_Blue );
	TF2_ChangeClientTeam(client, TFTeam_Blue);
	SetEntityFlags( client, iEntFlags );
	
	OR_Update();
	UpdateClassArray();
	PickRandomRobot(client);
}

// updates ay_avclass
// uses the data from tf_objective_resource to determine which classes should be available.
// use the function OR_Update to read the tf_objective_resource's data.
void UpdateClassArray()
{
	int iAvailable = OR_GetAvailableClasses();
	
	ay_avclass.Clear();
	
	if(iAvailable & 1) // scout
	{
		ay_avclass.Push(1); // this number is the same as TFClassType enum
	}
	if(iAvailable & 2) // soldier
	{
		ay_avclass.Push(3);
	}
	if(iAvailable & 4) // pyro
	{
		ay_avclass.Push(7);
	}
	if(iAvailable & 8) // demoman
	{
		ay_avclass.Push(4);
	}
	if(iAvailable & 16) // heavy
	{
		ay_avclass.Push(6);
	}
	if(iAvailable & 32) // engineer
	{
		ay_avclass.Push(9);
	}
	if(iAvailable & 64) // medic
	{
		ay_avclass.Push(5);
	}
	if(iAvailable & 128) // sniper
	{
		ay_avclass.Push(2);
	}
	if(iAvailable & 256) // spy
	{
		ay_avclass.Push(8);
	}
}

// ***ROBOT VARIANT***
void PickRandomRobot(int client)
{
	if(!IsClientInGame(client))
		return;
	
	int iAvailable = OR_GetAvailableClasses();
	int iSize = GetArraySize(ay_avclass) - 1;
	int iRandom = GetRandomInt(0, iSize);
	int iClass = ay_avclass.Get(iRandom);
	bool bGiants = false;
	//TFClassType Class;
	
	// sentry buster
/* 	if(iAvailable & 512)
	{
		
	} */
	if(iAvailable & 1024)
	{
		bGiants = true;
	}	
	
	// convert int to tfclass
	switch( iClass )
	{
		case 1: // scout
		{
			PickRandomVariant( client, TFClass_Scout, bGiants);
		}
		case 2: // sniper
		{
			PickRandomVariant( client, TFClass_Sniper, false);
		}
		case 3: // soldier
		{
			PickRandomVariant( client, TFClass_Soldier, bGiants);
		}
		case 4: // demoman
		{
			PickRandomVariant( client, TFClass_DemoMan, bGiants);
		}
		case 5: // medic
		{
			PickRandomVariant( client, TFClass_Medic, bGiants);
		}
		case 6: // heavy
		{
			PickRandomVariant( client, TFClass_Heavy, bGiants);
		}
		case 7: // pyro
		{
			PickRandomVariant( client, TFClass_Pyro, bGiants);
		}
		case 8: // spy
		{
			PickRandomVariant( client, TFClass_Spy, false);
		}
		case 9: // engineer
		{
			PickRandomVariant( client, TFClass_Engineer, false);
		}
	}
	BotClass[client] = Class;
}

// selects a random variant based on the player's class
void PickRandomVariant(int client,TFClassType TFClass,bool bGiants = false)
{
	if( GetRandomInt(0, 100) <= c_iGiantChance.IntValue && bGiants )
	{
		// giant
		iBotType[client] = Bot_Giant;
		switch( TFClass )
		{
			case TFClass_Scout:
			{
				iBotVariant[client] = GetRandomInt(0, MAX_SCOUT_GIANT);
				BotClass[client] = TFClass_Scout;
			}
			case TFClass_Soldier:
			{
				iBotVariant[client] = GetRandomInt(0, MAX_SOLDIER_GIANT);
				BotClass[client] = TFClass_Soldier;
			}
			case TFClass_Pyro:
			{
				iBotVariant[client] = GetRandomInt(0, MAX_PYRO_GIANT);
				BotClass[client] = TFClass_Pyro;
			}
			case TFClass_DemoMan:
			{
				iBotVariant[client] = GetRandomInt(0, MAX_DEMO_GIANT);
				BotClass[client] = TFClass_DemoMan;
			}
			case TFClass_Heavy:
			{
				iBotVariant[client] = GetRandomInt(0, MAX_HEAVY_GIANT);
				BotClass[client] = TFClass_Heavy;
			}
			case TFClass_Engineer:
			{
				iBotVariant[client] = GetRandomInt(0, MAX_ENGINEER_GIANT);
				BotClass[client] = TFClass_Engineer;
			}
			case TFClass_Medic:
			{
				iBotVariant[client] = GetRandomInt(0, MAX_MEDIC_GIANT);
				BotClass[client] = TFClass_Medic;
			}
			case TFClass_Sniper:
			{
				iBotVariant[client] = GetRandomInt(0, MAX_SNIPER_GIANT);
				BotClass[client] = TFClass_Sniper;
			}
			case TFClass_Spy:
			{
				iBotVariant[client] = GetRandomInt(0, MAX_SPY_GIANT);
				BotClass[client] = TFClass_Spy;
			}
		}
	}
	else
	{
		// normal
		iBotType[client] = Bot_Normal;
		switch( TFClass )
		{
			case TFClass_Scout:
			{
				iBotVariant[client] = GetRandomInt(-1, MAX_SCOUT);
				BotClass[client] = TFClass_Scout;
			}
			case TFClass_Soldier:
			{
				iBotVariant[client] = GetRandomInt(-1, MAX_SOLDIER);
				BotClass[client] = TFClass_Soldier;
			}
			case TFClass_Pyro:
			{
				iBotVariant[client] = GetRandomInt(-1, MAX_PYRO);
				BotClass[client] = TFClass_Pyro;
			}
			case TFClass_DemoMan:
			{
				iBotVariant[client] = GetRandomInt(-1, MAX_DEMO);
				BotClass[client] = TFClass_DemoMan;
			}
			case TFClass_Heavy:
			{
				iBotVariant[client] = GetRandomInt(-1, MAX_HEAVY);
				BotClass[client] = TFClass_Heavy;
			}
			case TFClass_Engineer:
			{
				iBotVariant[client] = GetRandomInt(-1, MAX_ENGINEER);
				BotClass[client] = TFClass_Engineer;
			}
			case TFClass_Medic:
			{
				iBotVariant[client] = GetRandomInt(-1, MAX_MEDIC);
				BotClass[client] = TFClass_Medic;
			}
			case TFClass_Sniper:
			{
				iBotVariant[client] = GetRandomInt(-1, MAX_SNIPER);
				BotClass[client] = TFClass_Sniper;
			}
			case TFClass_Spy:
			{
				iBotVariant[client] = GetRandomInt(-1, MAX_SPY);
				BotClass[client] = TFClass_Spy;
			}
		}
	}
	
}