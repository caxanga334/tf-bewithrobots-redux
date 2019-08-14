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
//#include "botvsmann/teammanager.sp"

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
	AddCommandListener( Listener_JoinTeam, "jointeam" );
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

public Action Listener_JoinTeam( int client, char[] sCmd, int nArgs )
{
	if(!IsMvM() || IsFakeClient(client) || !IsClientInGame(client))
		return Plugin_Continue;
		
	char team[16]
	TFTeam iTeam = TFTeam_Unassigned;
	
	if( StrEqual( team, "red", false ) )
		iTeam = TFTeam_Red;
	else if( StrEqual( team, "blue", false ) )
		iTeam = TFTeam_Blue;
	else if( StrEqual( team, "spectate", false ) || StrEqual( team, "spectator", false ) )
		iTeam = TFTeam_Spectator;
	else if( !StrEqual( sCmd, "autoteam", false ) )
		return Plugin_Continue;
		
	if(iTeam == TFTeam_Red)
	{
		CreateTimer(0.0, Timer_TurnHuman, GetClientUserId( client ));
		return Plugin_Handled;
	}
	else if(iTeam == TFTeam_Blue)
	{
		CreateTimer(0.0, Timer_TurnRobot, GetClientUserId( client ));
		return Plugin_Handled;
	}
	
	return Plugin_Handled;
}

public Action Command_JoinBLU( int client, int nArgs )
{
	if( !IsMvM() || IsClientInGame(client) || IsFakeClient(client) )
		return Plugin_Continue;
	
	FakeClientCommand( client, "jointeam blue" );
	
	return Plugin_Handled;
}
public Action:Command_JoinTeamRed( iClient, nArgs )
{
	if( !IsMvM() || IsClientInGame(client) || IsFakeClient(iClient) )
		return Plugin_Continue;
		
	FakeClientCommand( iClient, "jointeam red" );

	return Plugin_Handled;
}

public Action Timer_TurnHuman( Handle hTimer, int iUserID )
{
	int iClient = GetClientOfUserId( iUserID );
	
	if( !IsClientInGame(iClient) )
		return Plugin_Stop;
	
	
	if( !IsFakeClient(iClient) )
	{
		SetVariantString( "" );
		AcceptEntityInput( iClient, "SetCustomModel" );
		SetEntPropFloat( iClient, Prop_Send, "m_flModelScale", 1.0 );
	}
	
	return Plugin_Stop;
}
public Action Timer_TurnRobot( Handle hTimer, int iUserID )
{
	int iClient = GetClientOfUserId( iUserID );
	
	if( !IsClientInGame(iClient) )
		return Plugin_Stop;
	
	if( !IsFakeClient(iClient) )
	{
		SetEntProp( iClient, Prop_Send, "m_nBotSkill", BotSkill_Easy );
		SetEntProp( iClient, Prop_Send, "m_bIsMiniBoss", _:false );
	}
	
	int iEntFlags = GetEntityFlags( iClient );
	SetEntityFlags( iClient, iEntFlags|FL_FAKECLIENT );
	ChangeClientTeam( iClient, _:TFTeam_Blue );
	SetEntityFlags( iClient, iEntFlags&~FL_FAKECLIENT );
	
	return Plugin_Stop;
}