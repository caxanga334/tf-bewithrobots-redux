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

int iBotType[MAXPLAYERS + 1];
int iBotVariant[MAXPLAYERS + 1];

TFClassType BotClass[MAXPLAYERS + 1];

ArrayList ay_avclass; // array containing available classes

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
	version = "0.0.1",
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
	PrintToChatAll("E_Inventory");
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
}

// updates ay_avclass
void UpdateClassArray()
{
	int iAvailable = OR_GetAvailableClasses();
	
	ay_avclass.Clear();
	
	if(iAvailable & 1) // scout
	{
		ay_avclass.Push(1);
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
	
	//int iAvailable = OR_GetAvailableClasses();
	int iSize = GetArraySize(ay_avclass) - 1;
	int iRandom = GetRandomInt(0, iSize);
	int iClass = ay_avclass.Get(iRandom);
	TFClassType Class;
	
	// convert int to tfclass
	switch( iClass )
	{
		case 1:
		{
			Class = TFClass_Scout;
		}
		case 2:
		{
			Class = TFClass_Sniper;
		}
		case 3:
		{
			Class = TFClass_Soldier;
		}
		case 4:
		{
			Class = TFClass_DemoMan;
		}
		case 5:
		{
			Class = TFClass_Medic;
		}
		case 6:
		{
			Class = TFClass_Heavy;
		}
		case 7:
		{
			Class = TFClass_Pyro;
		}
		case 8:
		{
			Class = TFClass_Spy;
		}
		case 9:
		{
			Class = TFClass_Engineer;
		}
	}
	
	//PrintToChatAll("iRandom: %i, iSize: %i", iRandom, iSize);
	//TF2_SetPlayerClass(client, Class, _, true);
	
	BotClass[client] = Class;
	
	
	// sentry buster
/* 	if(iAvailable & 512)
	{
		
	} */
}

// selects a random variant based on the player's class
void PickRandomVariant(TFClassType TFClass)
{
	if( GetRandomInt(0, 100) <= 0)
	{
		// giant
		
	}
	else
	{
		// normal
	}
}