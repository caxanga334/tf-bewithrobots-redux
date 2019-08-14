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

enum
{
	BotSkill_Easy,
	BotSkill_Normal,
	BotSkill_Hard,
	BotSkill_Expert
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
	RegAdminCmd( "sm_bvm_debug", Command_Debug, ADMFLAG_ROOT, "Debug command" );
	
	// EVENTS
	HookEvent("mvm_begin_wave", E_WaveStart);
	HookEvent("mvm_wave_complete", E_WaveEnd);
	HookEvent("mvm_wave_failed", E_WaveFailed);
	HookEvent("mvm_mission_complete", E_MissionComplete);
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
		new i = FindEntityByClassname(-1, "tf_logic_mann_vs_machine");
		if (i > MaxClients && IsValidEntity(i)) ismvm = true;
		found = true;
	}
	return ismvm;
}

// #####COMMANDS#####

public Action Command_JoinBLU( int client, int nArgs )
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
	
	return Plugin_Handled;
}
public Action Command_JoinRED( int client, int nArgs )
{
	if( !IsMvM() || !IsClientInGame(client) || IsFakeClient(client) )
		return Plugin_Continue;
		
	TF2_ChangeClientTeam(client, TFTeam_Red);

	return Plugin_Handled;
}

public Action Command_Debug( int client, int nArgs )
{
	int iClasses = OR_GetAvailableClasses();
	ReplyToCommand(client, "Available Classes: %i", iClasses);
	
	if(iClasses & 128)
	{
		ReplyToCommand(client, "Found sniper");
	}
	
	return Plugin_Handled;
}

// EVENTS
public Action E_WaveStart(Event event, const char[] name, bool dontBroadcast)
{
	OR_Update();
}

public Action E_WaveEnd(Event event, const char[] name, bool dontBroadcast)
{
	OR_Update();
}

public Action E_WaveFailed(Event event, const char[] name, bool dontBroadcast)
{
	OR_Update();
}

public Action E_MissionComplete(Event event, const char[] name, bool dontBroadcast)
{
	OR_Update(); // placeholder
}