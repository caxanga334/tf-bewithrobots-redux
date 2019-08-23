#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <tf2attributes>
#include <tf2_isPlayerInSpawn>
#include <tf2wearables>
#include <morecolors>
#define REQUIRE_EXTENSIONS
#define AUTOLOAD_EXTENSIONS
#include <sdkhooks>
#include <tf2items>
#include "botvsmann/objectiveres.sp"
#include "botvsmann/bot_variants.sp"
#include "botvsmann/functions.sp"

#define PLUGIN_VERSION "0.0.1"

// TODO
/**
- add particle for when engineers spawn on map hint
- set building levels for human robot engineers
- add code for humans to deploy the bomb
**/

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
int iBotEffect[MAXPLAYERS + 1];
TFClassType BotClass[MAXPLAYERS + 1];

// bomb
bool g_bIsCarrier[MAXPLAYERS + 1]; // true if the player is carrying the bomb

ArrayList ay_avclass; // array containing available classes
ArrayList array_spawns; // spawn points for human players

// others
bool g_bUpgradeStation[MAXPLAYERS + 1];
char MapName[64];

// convars
ConVar c_iMinRed;
ConVar c_iMinRedinProg; // minimum red players to join BLU while the wave is in progress.
ConVar c_iGiantChance;
ConVar c_iGiantMinRed; // minimum red players to allow giants.
ConVar c_iMaxBlu; // maximum blu players allowed
ConVar c_bAutoTeamBalance;
ConVar c_bSmallMap; // change robot scale to avoid getting stuck in maps such as mvm_2fort
ConVar c_svTag; // server tags

UserMsg ID_MVMResetUpgrade = INVALID_MESSAGE_ID;

enum SpawnType
{
	Spawn_Normal = 0,
	Spawn_Giant = 1,
	Spawn_Sniper = 2,
	Spawn_Spy = 3,
	Spawn_Buster = 4,
	Spawn_Boss = 5
}

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

enum
{
	BotEffect_None = 0,
	BotEffect_AlwaysCrits = 1,
	BotEffect_FullCharge = 2,
	BotEffect_InfiniteCloak = 4,
	BotEffect_AutoDisguise = 8,
	BotEffect_AlwaysMiniCrits = 16,
	BotEffect_TeleportToHint = 32, // teleport engineers to a nest near the bomb.
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
	c_iMinRed = CreateConVar("sm_bvm_minred", "4", "Minimum amount of players on RED team to allow joining ROBOTs.", FCVAR_NONE, true, 0.0, true, 10.0);
	c_iMinRedinProg = CreateConVar("sm_bvm_minred_inprog", "7", "Minimum amount of players on RED team to allow joining ROBOTs while the wave is in progress.", FCVAR_NONE, true, 0.0, true, 10.0);
	c_iGiantChance = CreateConVar("sm_bvm_giantchance", "30", "Chance in percentage to human players to spawn as a giant. 0 = Disabled.", FCVAR_NONE, true, 0.0, true, 100.0);
	c_iGiantMinRed = CreateConVar("sm_bvm_giantminred", "5", "Minimum amount of players on RED team to allow human giants. 0 = Disabled.", FCVAR_NONE, true, 0.0, true, 8.0);
	c_iMaxBlu = CreateConVar("sm_bvm_maxblu", "4", "Maximum amount of players in BLU team.", FCVAR_NONE, true, 1.0, true, 5.0);
	c_bAutoTeamBalance = CreateConVar("sm_bvm_autoteambalance", "1", "Balance teams at wave start?", FCVAR_NONE, true, 0.0, true, 1.0);
	c_bSmallMap = CreateConVar("sm_bvm_smallmap", "0", "Use small robot size for human players. Enable if players are getting stuck.", FCVAR_NONE, true, 0.0, true, 1.0);
	c_svTag = FindConVar("sv_tags");
	
	// convar hooks
	if( c_svTag != null )
	{
		c_svTag.AddChangeHook(OnTagsChanged);
	}
	
	// translations
	LoadTranslations("botsvsmann.phrases");
	LoadTranslations("common.phrases");
	
	// commands
	RegConsoleCmd( "sm_joinred", Command_JoinRED, "Joins RED team." );
	RegConsoleCmd( "sm_joinblu", Command_JoinBLU, "Joins BLU/Robot team." );
	RegConsoleCmd( "sm_joinblue", Command_JoinBLU, "Joins BLU/Robot team." );
	RegConsoleCmd( "sm_bwr", Command_JoinBLU, "Joins BLU/Robot team." );
	RegConsoleCmd( "sm_bewithrobots", Command_JoinBLU, "Joins BLU/Robot team." );
	RegConsoleCmd( "sm_robotclass", Command_BotClass, "Changes your robot variant." );
	RegConsoleCmd( "sm_rc", Command_BotClass, "Changes your robot variant." );
	RegAdminCmd( "sm_bvm_debug", Command_Debug, ADMFLAG_ROOT, "Debug command" );
	RegAdminCmd( "sm_bvm_forcebot", Command_ForceBot, ADMFLAG_ROOT, "Forces a specific robot variant on the target." );
	RegAdminCmd( "sm_bvm_move", Command_MoveTeam, ADMFLAG_BAN, "Changes the target player team." );
	
	// listener
	AddCommandListener( Listener_Ready, "tournament_player_readystate" );
	AddCommandListener( Listener_Suicide, "kill" );
	AddCommandListener( Listener_Suicide, "explode" );
	AddCommandListener( Listener_Suicide, "dropitem" ); // not a suicide command but same blocking rule
	AddCommandListener( Listener_Build, "build" );
	
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
	HookEvent( "teamplay_flag_event", E_FlagPickup );
	HookEvent( "teamplay_flag_event", E_FlagDrop );
	HookEvent( "post_inventory_application", E_Inventory );
	
	ID_MVMResetUpgrade = GetUserMessageId("MVMResetPlayerUpgradeSpending");
	if(ID_MVMResetUpgrade == INVALID_MESSAGE_ID)
		LogError("Unable to hook user message.");
		
	HookUserMessage(ID_MVMResetUpgrade, MsgHook_MVMRespec);
	
	ay_avclass = new ArrayList(10);
	array_spawns = new ArrayList();
	
	AutoExecConfig(true, "plugin.botsvsmachine");
}

public void OnMapStart()
{
	if(!IsMvM())
	{
		SetFailState("This plugin is for Mann vs Machine Only.") // probably easier than add IsMvM everywhere
	}
	
	CheckMapForEntities();
	GetCurrentMap(MapName, sizeof(MapName));
	
	int i;
	
	while ((i = FindEntityByClassname(i, "func_upgradestation")) != -1)
	{
		if(IsValidEntity(i))
		{
			SDKHook(i, SDKHook_StartTouch, OnTouchUpgradeStation);
		} 
	}
	
	ay_avclass.Clear();
	
	// add custom tag
	AddPluginTag("BVM");
	
	// prechace
	PrecacheSound(")mvm/mvm_tele_deliver.wav");
}

/* public void OnClientConnected(client)
{

} */

public void OnClientDisconnect(client)
{
	ResetRobotData(client);
}

public void OnGameFrame()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i))
		{		
			if(TF2_GetClientTeam(i) == TFTeam_Blue)
			{
				if( TF2Spawn_IsClientInSpawn2(i) )
				{
					TF2_AddCondition(i, TFCond_UberchargedHidden, 0.255);
				}
				
				if( iBotEffect[i] & BotEffect_InfiniteCloak )
				{
					SetEntPropFloat( i, Prop_Send, "m_flCloakMeter", 100.0 );
				}
				
				if( GameRules_GetRoundState() == RoundState_BetweenRounds )
				{
					TF2_AddCondition(i, TFCond_FreezeInput, 0.255);
				}
			}
		}
	}
}

public void TF2Spawn_EnterSpawn(client, entity)
{
	if(TF2_GetClientTeam(client) == TFTeam_Blue && !IsFakeClient(client))
	{
		TF2_AddCondition(client, TFCond_UberchargedHidden, TFCondDuration_Infinite);
	}	
}

public void TF2Spawn_LeaveSpawn(client, entity)
{
	if(TF2_GetClientTeam(client) == TFTeam_Blue && !IsFakeClient(client))
	{
		TF2_RemoveCondition(client, TFCond_UberchargedHidden);
		
		if( GameRules_GetRoundState() == RoundState_BetweenRounds )
		{
			TF2_RespawnPlayer(client);
		}
	}
}

public void OnEntityCreated(int iEntity,const char[] name)
{
	if ( StrEqual( name, "entity_revive_marker", false) )
	{
		CreateTimer(0.1, Timer_KillReviveMarker, iEntity);
	}
	if( StrEqual( name, "entity_medigun_shield", false ) )
	{
		if(IsValidEntity(iEntity))
		{
			int iOwner = GetEntPropEnt( iEntity, Prop_Send, "m_hOwnerEntity" );
			if( IsValidClient(iOwner) && TF2_GetClientTeam(iOwner) == TFTeam_Blue )
			{
				SetVariantInt(1);
				AcceptEntityInput(iEntity, "Skin" );
			}
		}
	}
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	if( IsFakeClient(client) || !IsPlayerAlive(client) )
		return Plugin_Continue;
		
	if( TF2_GetClientTeam(client) == TFTeam_Blue )
	{
		if( TF2Spawn_IsClientInSpawn2(client) )
		{
			if( buttons & IN_ATTACK )
			{
				buttons &= ~IN_ATTACK;
				buttons &= ~IN_ATTACK2;
				buttons &= ~IN_ATTACK3;
				return Plugin_Changed;
			}
			else if( buttons & IN_ATTACK2 )
			{
				buttons &= ~IN_ATTACK;
				buttons &= ~IN_ATTACK2;
				buttons &= ~IN_ATTACK3;
				return Plugin_Changed;
			}
			else if( buttons & IN_ATTACK3 )
			{
				buttons &= ~IN_ATTACK;
				buttons &= ~IN_ATTACK2;
				buttons &= ~IN_ATTACK3;
				return Plugin_Changed;
			}
		}
	}
	return Plugin_Continue;
}

/****************************************************
				CONVAR FUNCTIONS
*****************************************************/

public void OnTagsChanged(ConVar convar, char[] oldValue, char[] newValue)
{
	AddPluginTag("BVM");
}

/****************************************************
					SDKHOOKS
*****************************************************/

public Action OnTouchUpgradeStation(int entity, int other)
{
	if(IsValidClient(other))
	{
		if(!g_bUpgradeStation[other])
		{
			g_bUpgradeStation[other] = true;
		}
	}
}

/****************************************************
					COMMANDS
*****************************************************/

public Action Command_JoinBLU( int client, int nArgs )
{
	if( !IsClientInGame(client) || IsFakeClient(client) )
		return Plugin_Continue;
		
	if( TF2_GetClientTeam(client) == TFTeam_Blue )
		return Plugin_Handled;
		
	if( ay_avclass.Length < 1 )
	{
		CPrintToChat(client, "Wave Data isn't ready, rebuilding... Please try again."); // to-do: translate
		OR_Update();
		UpdateClassArray();
		return Plugin_Handled;
	}
	
	int iMinRed = c_iMinRedinProg.IntValue;
	if( GameRules_GetRoundState() == RoundState_RoundRunning && GetTeamClientCount(2) < iMinRed )
	{
		CPrintToChat(client,"%t", "Not in Prog");
		CPrintToChat(client,"%t","Num Red",iMinRed);
		return Plugin_Handled;
	}
	
	iMinRed = c_iMinRed.IntValue;
	if( GetTeamClientCount(2) < iMinRed )
	{
		CPrintToChat(client,"%t","Need Red");
		CPrintToChat(client,"%t","Num Red",iMinRed);
		return Plugin_Handled;
	}
	
	if( GetHumanRobotCount() > c_iMaxBlu.IntValue )
	{
		CPrintToChat(client, "%t", "Blu Full");
		return Plugin_Handled;
	}
	
	bool bReady = view_as<bool>(GameRules_GetProp( "m_bPlayerReady", _, client));
	if( bReady && GameRules_GetRoundState() == RoundState_BetweenRounds )
	{
		CPrintToChat(client,"%t","Unready");
		return Plugin_Handled;
	}
	
	if( g_bUpgradeStation[client] )
	{
		CPrintToChat(client,"%t","Used Upgrade");
		return Plugin_Handled;
	}
	
	MovePlayerToBLU(client);
	return Plugin_Handled;
}

public Action Command_JoinRED( int client, int nArgs )
{
	if( !IsClientInGame(client) || IsFakeClient(client) )
		return Plugin_Continue;
		
	if( TF2_GetClientTeam(client) == TFTeam_Red )
		return Plugin_Handled;
		
	TF2_ChangeClientTeam(client, TFTeam_Red);
	ScalePlayerModel(client, 1.0);
	ResetRobotData(client);
	SetVariantString( "" );
	AcceptEntityInput( client, "SetCustomModel" );
	LogMessage("Player \"%L\" joined RED team.", client);

	return Plugin_Handled;
}

public Action Command_Debug( int client, int nArgs )
{
	int iClasses = OR_GetAvailableClasses();
	int iCur = OR_GetCurrentWave();
	int iTotalWaveNum = OR_GetMaxWave();
	
	ReplyToCommand(client, "Available Classes: %i", iClasses);
	ReplyToCommand(client, "Current Wave: %i, Max Wave: %i", iCur, iTotalWaveNum);
	
	if(OR_IsHalloweenMission())
	{
		ReplyToCommand(client, "Halloween Popfile");
	}
	
	ReplyToCommand(client, "Class Array Size: %i", ay_avclass.Length);
	
	TFClassType TFClass;
	char strClass[16]
	for( int i = 1; i <= 9; i++ )
	{
		TFClass = view_as<TFClassType>(i);
		if( IsClassAvailable(TFClass) )
		{
			switch( TFClass )
			{
				case TFClass_Scout: strcopy(strClass, 16, "Scout");
				case TFClass_Soldier: strcopy(strClass, 16, "Soldier");
				case TFClass_Pyro: strcopy(strClass, 16, "Pyro");
				case TFClass_DemoMan: strcopy(strClass, 16, "Demoman");
				case TFClass_Heavy: strcopy(strClass, 16, "Heavy");
				case TFClass_Engineer: strcopy(strClass, 16, "Engineer");
				case TFClass_Medic: strcopy(strClass, 16, "Medic");
				case TFClass_Sniper: strcopy(strClass, 16, "Sniper");
				case TFClass_Spy: strcopy(strClass, 16, "Spy");
			}
			ReplyToCommand(client, "Found %s", strClass);
		}
	}
	
	bool bReady = view_as<bool>(GameRules_GetProp( "m_bPlayerReady", _, client));
	if( bReady )
	{
		ReplyToCommand(client, "Ready");
	}
	else
	{
		ReplyToCommand(client, "Not Ready");
	}
	
	return Plugin_Handled;
}

public Action Command_ForceBot( int client, int nArgs )
{
	char arg1[MAX_NAME_LENGTH], arg2[16], arg3[4], arg4[4];
	bool bForceGiants = false;
	
	if( nArgs < 4 )
	{
		ReplyToCommand(client, "Usage: sm_bvm_forcebot <target> <class> <type: 0 normal | 1 giant> <variant id>");
		ReplyToCommand(client, "Valid Classes: scout,soldier,pyro,demoman,heavy,engineer,medic,sniper,spy");
		return Plugin_Handled;
	}
	
	GetCmdArg(1, arg1, sizeof(arg1));
	
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
	
	if((target_count = ProcessTargetString(arg1, client, target_list, MAXPLAYERS, COMMAND_FILTER_NO_BOTS, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	TFClassType TargetClass = TFClass_Unknown;
	
	GetCmdArg(2, arg2, sizeof(arg2));
	
	if( StrEqual(arg2, "scout", false) )
	{
		TargetClass = TFClass_Scout;
	}
	else if( StrEqual(arg2, "soldier", false) )
	{
		TargetClass = TFClass_Soldier;
	}
	else if( StrEqual(arg2, "pyro", false) )
	{
		TargetClass = TFClass_Pyro;
	}
	else if( StrEqual(arg2, "demoman", false) )
	{
		TargetClass = TFClass_DemoMan;
	}
	else if( StrEqual(arg2, "heavy", false) )
	{
		TargetClass = TFClass_Heavy;
	}
	else if( StrEqual(arg2, "engineer", false) )
	{
		TargetClass = TFClass_Engineer;
	}
	else if( StrEqual(arg2, "medic", false) )
	{
		TargetClass = TFClass_Medic;
	}
	else if( StrEqual(arg2, "sniper", false) )
	{
		TargetClass = TFClass_Sniper;
	}
	else if( StrEqual(arg2, "spy", false) )
	{
		TargetClass = TFClass_Spy;
	}
	
	if( TargetClass == TFClass_Unknown )
	{
		ReplyToCommand(client, "ERROR: Invalid class");
		ReplyToCommand(client, "Valid Classes: scout,soldier,pyro,demoman,heavy,engineer,medic,sniper,spy");
		return Plugin_Handled;
	}
	
	GetCmdArg(3, arg3, sizeof(arg3));
	int iArg3 = StringToInt(arg3);
	if( iArg3 < 0 || iArg3 > 1 )
	{
		ReplyToCommand(client, "ERROR: Use 0 for Normal Bot and 1 for Giant Bot");
		return Plugin_Handled;
	}
	else if( iArg3 == 1 )
	{
		bForceGiants = true;
	}
	
	GetCmdArg(4, arg4, sizeof(arg4));
	int iArg4 = StringToInt(arg4);
	
	if( IsValidVariant(bForceGiants, TargetClass, iArg4) )
	{
		ReplyToCommand(client, "ERROR: Invalid Variant");
		return Plugin_Handled;
	}
	
	for(int i = 0; i < target_count; i++)
	{
		if( TF2_GetClientTeam(target_list[i]) == TFTeam_Blue )
		{
			iBotVariant[target_list[i]] = iArg4;
			BotClass[target_list[i]] = TargetClass;
			if(bForceGiants)
			{
				iBotType[target_list[i]] = Bot_Giant;
				SetGiantVariantExtras(target_list[i],TargetClass, iArg4);
			}
			else
			{
				iBotType[target_list[i]] = Bot_Normal;
				SetVariantExtras(target_list[i],TargetClass, iArg4);
			}
			TF2_SetPlayerClass(target_list[i], TargetClass, _, true);
			TF2_RespawnPlayer(target_list[i]);
			LogAction(client, target_list[i], "\"%L\" Forced a robot variant on \"%L\".", client, target_list[i]);
		}
		else
		{
			ReplyToCommand(client, "ERROR: This command can only be used on BLU team.");
			return Plugin_Handled;
		}
	}
	
	if (tn_is_ml)
	{
		ShowActivity2(client, "[SM] ", "Forced a robot variant on %t.", target_name);
	}
	else
	{
		ShowActivity2(client, "[SM] ", "Forced a robot variant on %s.", target_name);
	}
	return Plugin_Handled;
}

public Action Command_MoveTeam( int client, int nArgs )
{
	char arg1[MAX_NAME_LENGTH], arg2[16];
	TFTeam NewTargetTeam = TFTeam_Spectator; // default to spectator if no team is specified
	int iArgTeam = 1;
	
	if( nArgs < 1 )
	{
		ReplyToCommand(client, "Usage: sm_bvm_move <target> <team: 1 - Spectator, 2 - Red, 3 - Blue>");
		return Plugin_Handled;
	}
	
	GetCmdArg(1, arg1, sizeof(arg1));
	
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
	
	if((target_count = ProcessTargetString(arg1, client, target_list, MAXPLAYERS, COMMAND_FILTER_NO_BOTS, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	if( nArgs == 2 )
	{
		GetCmdArg(2, arg2, sizeof(arg2));
		iArgTeam = StringToInt(arg2);
		if( iArgTeam <= 0 || iArgTeam > 3 )
		{
			ReplyToCommand(client, "ERROR: Invalid Team. Valid Teams: 1 - Spectator, 2 - Red, 3 - Blue");
			return Plugin_Handled;
		}
		else
		{
			NewTargetTeam = view_as<TFTeam>(iArgTeam);
		}
	}
	
	char strLogTeam[16];
	
	switch( iArgTeam )
	{
		case 1: strcopy(strLogTeam, 16, "Spectator");
		case 2: strcopy(strLogTeam, 16, "RED");
		case 3: strcopy(strLogTeam, 16, "BLU");
	}
	
	for(int i = 0; i < target_count; i++)
	{
		if( NewTargetTeam == TFTeam_Blue )
		{
			if( ay_avclass.Length < 1 )
			{
				ReplyToCommand(client, "Wave data needs to be built. Building data...");
				OR_Update();
				UpdateClassArray();
				return Plugin_Handled;
			}
			else
			{
				MovePlayerToBLU(target_list[i]);
			}
		}
		else
		{
			TF2_ChangeClientTeam(target_list[i], NewTargetTeam);
			ScalePlayerModel(target_list[i], 1.0);
		}
		LogAction(client, target_list[i], "\"%L\" changed \"%L\"'s team to %s", client, target_list[i], strLogTeam);
	}
	
	if (tn_is_ml)
	{
		ShowActivity2(client, "[SM] ", "Changed %t's team to %s.", target_name, strLogTeam);
	}
	else
	{
		ShowActivity2(client, "[SM] ", "Changed %s's team to %s.", target_name, strLogTeam);
	}
	
	return Plugin_Handled;
}

public Action Command_BotClass( int client, int nArgs )
{
	if( !IsClientInGame(client) || IsFakeClient(client) )
		return Plugin_Continue;
		
	if( TF2_GetClientTeam(client) == TFTeam_Red )
		return Plugin_Handled;
		
	if( !TF2Spawn_IsClientInSpawn2(client) )
	{
		ReplyToCommand(client, "This command can only be used inside the spawn");
		return Plugin_Handled;
	}

	PickRandomRobot(client);
	CreateTimer(0.5, Timer_Respawn, client);

	return Plugin_Handled;
}

/****************************************************
					LISTENER
*****************************************************/

public Action Listener_Ready(int client, const char[] command, int argc)
{
	if( TF2_GetClientTeam(client) == TFTeam_Blue )
	{ // todo: add translated message
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Action Listener_Suicide(int client, const char[] command, int argc)
{
	if( TF2_GetClientTeam(client) == TFTeam_Blue )
	{
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Action Listener_Build(int client, const char[] command, int argc)
{
	if( TF2_GetClientTeam(client) == TFTeam_Blue && TF2Spawn_IsClientInSpawn2(client) )
	{
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

/****************************************************
					EVENTS
*****************************************************/

public Action E_WaveStart(Event event, const char[] name, bool dontBroadcast)
{
	OR_Update();
	UpdateClassArray();
	CheckTeams();
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
	int client = GetClientOfUserId(event.GetInt("userid"));
	TFClassType TFClass = view_as<TFClassType>(event.GetInt("class"));
	
	if( TF2_GetClientTeam(client) == TFTeam_Blue )
	{
		if( IsClassAvailable(TFClass) )
		{
			BotClass[client] = TFClass;
			PickRandomVariant(client,TFClass,false);
			SetVariantExtras(client,TFClass, iBotVariant[client]);
		}
		else
		{
			PickRandomVariant(client,BotClass[client],false);
			SetVariantExtras(client,BotClass[client], iBotVariant[client]);
			TF2_SetPlayerClass(client,BotClass[client]);
		}
	}
}

public Action E_Pre_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if( TF2_GetClientTeam(client) == TFTeam_Blue )
	{
		if( iBotEffect[client] & BotEffect_AlwaysCrits )
		{
			TF2_AddCondition(client, TFCond_CritOnFlagCapture, TFCondDuration_Infinite);
		}
		if( iBotEffect[client] & BotEffect_AlwaysMiniCrits )
		{
			TF2_AddCondition(client, TFCond_Buffed, TFCondDuration_Infinite);
		}		
	}
}

public Action E_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	CreateTimer(0.1, Timer_OnPlayerSpawn, client);
	
	if( ay_avclass.Length < 1 )
	{
		OR_Update();
		UpdateClassArray();
	}
}

public Action E_Pre_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int deathflags = event.GetInt("death_flags");
	if(deathflags & TF_DEATHFLAG_DEADRINGER)
		return Plugin_Handled;
		
	int client = GetClientOfUserId(event.GetInt("userid"));
	if( GameRules_GetRoundState() == RoundState_BetweenRounds && TF2_GetClientTeam(client) == TFTeam_Blue )
	{
		event.SetBool("silent_kill", true);
	}
	
	return Plugin_Continue;
}

public Action E_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if( TF2_GetClientTeam(client) == TFTeam_Blue )
	{
		PickRandomRobot(client);
	}
}

public Action E_Inventory(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if(IsValidClient(client))
	{
		TFTeam Team = TF2_GetClientTeam(client);
		
		if(Team == TFTeam_Blue && !IsFakeClient(client) && IsClientInGame(client))
		{
			if( iBotVariant[client] >= 0 )
			{
				StripItems(client, true); // true: remove weapons
				
				if( iBotType[client] == Bot_Giant )
				{
					GiveGiantInventory(client,iBotVariant[client]);
				}
				else
				{
					GiveNormalInventory(client,iBotVariant[client]);
				}
			}
			else
			{
				StripItems(client, false); // remove misc but not weapons, allow own loadout
			}
		}
	}
}

public Action E_FlagPickup(Event event, const char[] name, bool dontBroadcast)
{
	if( event.GetInt("eventtype") == TF_FLAGEVENT_PICKEDUP )
	{
		int client = event.GetInt("player");
		if( !IsFakeClient(client) )
		{
			g_bIsCarrier[client] = true;
		}
	}
}

public Action E_FlagDrop(Event event, const char[] name, bool dontBroadcast)
{
	if( event.GetInt("eventtype") == TF_FLAGEVENT_DROPPED )
	{
		int client = event.GetInt("player");
		if( !IsFakeClient(client) )
		{
			g_bIsCarrier[client] = false;
		}
	}
}

/****************************************************
					USER MESSAGE
*****************************************************/

public Action MsgHook_MVMRespec(UserMsg msg_id, BfRead msg, const int[] players, int playersNum, bool reliable, bool init)
{
	int client = BfReadByte(msg); //client that used the respec    
	OnRefund(client);
}

/****************************************************
					TIMERS
*****************************************************/

public Action Timer_OnPlayerSpawn(Handle timer, any client)
{
	int iTeleTarget = -1;
	
	if( IsClientInGame(client) && IsFakeClient(client) )  // teleport bots to teleporters
	{
		iTeleTarget = FindBestBluTeleporter();
		if( iTeleTarget != -1 )
		{
			SpawnOnTeleporter(iTeleTarget,client);
		}
		else
		{
			return Plugin_Stop;
		}
		return Plugin_Handled;
	}
		
	TFClassType TFClass = TF2_GetPlayerClass(client);
	char strBotName[128];
		
	if( TF2_GetClientTeam(client) == TFTeam_Blue )
	{
		//TF2_AddCondition(client, TFCond_UberchargedHidden, TFCondDuration_Infinite);
		
		if( TFClass == TFClass_Spy && iBotEffect[client] & BotEffect_AutoDisguise )
		{
			int iTarget = GetRandomPlayer(TFTeam_Red, false);
			if( iTarget >= 1 && iTarget <= MaxClients )
			{
				TF2_DisguisePlayer(client, TFTeam_Red, TF2_GetPlayerClass(iTarget), iTarget);
			}
		}
		
		// TO DO: pyro's gas passer and phlog
		if( iBotEffect[client] & BotEffect_FullCharge )
		{
			if( TFClass == TFClass_Medic )
			{
				int iWeapon = TF2_GetPlayerLoadoutSlot(client, TF2LoadoutSlot_Secondary);
				if( IsValidEdict( iWeapon ) )
					SetEntPropFloat( iWeapon, Prop_Send, "m_flChargeLevel", 1.0 );
			}
			else if( TFClass == TFClass_Soldier )
			{
				SetEntPropFloat( client, Prop_Send, "m_flRageMeter", 100.0 );
			}			
		}
		
		if(OR_IsHalloweenMission())
		{
			TF2_AddCondition(client, TFCond_CritOnFlagCapture, TFCondDuration_Infinite);
		}
		
		// prints the robot variant name to the player.
		if( iBotType[client] == Bot_Giant )
		{
			strBotName = GetGiantVariantName(TFClass, iBotVariant[client]);
		}
		else
		{
			strBotName = GetNormalVariantName(TFClass, iBotVariant[client]);
		}
		CPrintToChat(client, "%t", "Bot Spawn", strBotName);
		SetRobotScale(client);
		SetRobotModel(client,TFClass);
		
		// teleport player
		if( GameRules_GetRoundState() == RoundState_RoundRunning )
		{
			switch( TFClass )
			{
				case TFClass_Spy: // spies should always spawn on their hints
				{
					iTeleTarget = FindNearestSpyHint();
					if( iTeleTarget != -1 ) // found spy hint
					{
						TF2_AddCondition(client, TFCond_StealthedUserBuffFade, 2.0);
						TeleportPlayerToEntity(iTeleTarget, client)
						
					}
					else
					{
						iTeleTarget = FindBestBluTeleporter();
						if( iTeleTarget != -1 ) // found teleporter
						{
							TF2_AddCondition(client, TFCond_StealthedUserBuffFade, 5.0);
							SpawnOnTeleporter(iTeleTarget,client);
						}
						else
						{
							TeleportToSpawnPoint(client, TFClass);
						}
					}		
				}
				case TFClass_Engineer:
				{
					iTeleTarget = FindBestBluTeleporter();
					if( iTeleTarget != -1 ) // first search for teleporter
					{
						SpawnOnTeleporter(iTeleTarget,client);						
					}
					else // no teleporter found
					{
						iTeleTarget = FindEngineerNestNearBomb();
						if( iTeleTarget != -1 ) // found teleporter
						{
							TeleportPlayerToEntity(iTeleTarget, client);
						}
						else
						{
							TeleportToSpawnPoint(client, TFClass);
						}
					}					
				}
				default: // other classes
				{
					iTeleTarget = FindBestBluTeleporter();
					if( iTeleTarget != -1 ) // found teleporter
					{
						SpawnOnTeleporter(iTeleTarget,client);
					}
					else
					{
						TeleportToSpawnPoint(client, TFClass);
					}
				}
			}
		}
		else
		{
			TeleportToSpawnPoint(client, TFClass);
		}
		
		// apply attributes to own loadout
		if( iBotVariant[client] == -1 )
		{
			if( iBotType[client] == Bot_Giant )
				SetOwnAttributes(client ,true);
			else
				SetOwnAttributes(client ,false);
				
			TF2_RegeneratePlayer(client);
		}
	}
	
	return Plugin_Handled;
}

public Action Timer_SetRobotClass(Handle timer, any client)
{
	if( !IsClientInGame(client) )
		return Plugin_Stop;
		
	TF2_SetPlayerClass(client, BotClass[client], _, true);
	
	return Plugin_Handled;
}

public Action Timer_Respawn(Handle timer, any client)
{
	if( !IsClientInGame(client) )
		return Plugin_Stop;
		
	TF2_RespawnPlayer(client);
	
	return Plugin_Handled;
}

public Action Timer_KillReviveMarker(Handle timer, any revivemarker)
{
	if( IsValidEntity(revivemarker) )
	{
		char classname[64];
		if( GetEntityClassname(revivemarker, classname, sizeof(classname)) )
		{
			if( StrEqual(classname, "entity_revive_marker", false) )
			{
				int client = GetEntPropEnt(revivemarker, Prop_Send, "m_hOwner");
				if( TF2_GetClientTeam(client) == TFTeam_Blue )
				{
					AcceptEntityInput(revivemarker,"Kill");
				}
			}
		}
	}
	
	return Plugin_Handled;
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
		SetEntProp( client, Prop_Send, "m_bIsMiniBoss", view_as<int>(false) );
	}
	
	int iEntFlags = GetEntityFlags( client );
	SetEntityFlags( client, iEntFlags | FL_FAKECLIENT );
	TF2_ChangeClientTeam(client, TFTeam_Blue);
	SetEntityFlags( client, iEntFlags );
	LogMessage("Player \"%L\" joined BLU team.", client);
	
	ScalePlayerModel(client, 1.0);
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

// returns true if the specified class is available for the current wave
bool IsClassAvailable(TFClassType TFClass)
{
	if( ay_avclass.Length < 1 )
		return false;
		
	int iClass = view_as<int>(TFClass);
	
	if( ay_avclass.FindValue(iClass) != -1 )
		return true;

	return false;	
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
}

// selects a random variant based on the player's class
void PickRandomVariant(int client,TFClassType TFClass,bool bGiants = false)
{
	//TF2_SetPlayerClass(client, TFClass);
	CreateTimer(0.1, Timer_SetRobotClass, client);
	if( GetRandomInt(0, 100) <= c_iGiantChance.IntValue && bGiants && GetTeamClientCount(2) >= c_iGiantMinRed.IntValue )
	{
		// giant
		iBotType[client] = Bot_Giant;
		switch( TFClass )
		{
			case TFClass_Scout:
			{
				iBotVariant[client] = GetRandomInt(-1, MAX_SCOUT_GIANT);
				BotClass[client] = TFClass_Scout;
			}
			case TFClass_Soldier:
			{
				iBotVariant[client] = GetRandomInt(-1, MAX_SOLDIER_GIANT);
				BotClass[client] = TFClass_Soldier;
			}
			case TFClass_Pyro:
			{
				iBotVariant[client] = GetRandomInt(-1, MAX_PYRO_GIANT);
				BotClass[client] = TFClass_Pyro;
			}
			case TFClass_DemoMan:
			{
				iBotVariant[client] = GetRandomInt(-1, MAX_DEMO_GIANT);
				BotClass[client] = TFClass_DemoMan;
			}
			case TFClass_Heavy:
			{
				iBotVariant[client] = GetRandomInt(-1, MAX_HEAVY_GIANT);
				BotClass[client] = TFClass_Heavy;
			}
			case TFClass_Engineer:
			{
				iBotVariant[client] = GetRandomInt(-1, MAX_ENGINEER_GIANT);
				BotClass[client] = TFClass_Engineer;
			}
			case TFClass_Medic:
			{
				iBotVariant[client] = GetRandomInt(-1, MAX_MEDIC_GIANT);
				BotClass[client] = TFClass_Medic;
			}
			case TFClass_Sniper:
			{
				iBotVariant[client] = GetRandomInt(-1, MAX_SNIPER_GIANT);
				BotClass[client] = TFClass_Sniper;
			}
			case TFClass_Spy:
			{
				iBotVariant[client] = GetRandomInt(-1, MAX_SPY_GIANT);
				BotClass[client] = TFClass_Spy;
			}
		}
		SetGiantVariantExtras(client, TFClass, iBotVariant[client]);
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
		SetVariantExtras(client, TFClass, iBotVariant[client]);
	}
}

/**
 * Checks if a robot variant is valid.
 *
 * @param bGiants       	Is the robot a giant?
 * @param TFClass     	The player class
 * @param iVariant      	The variant ID
 * @return              True if the variant is valid, false otherwise.
 */
bool IsValidVariant(bool bGiants, TFClassType TFClass, int iVariant)
{
	switch( TFClass )
	{
		case TFClass_Scout:
		{
			if( bGiants )
			{
				if( iVariant < -1 || iVariant > MAX_SCOUT_GIANT )
					return false;
			}
			else
			{
				if( iVariant < -1 || iVariant > MAX_SCOUT )
					return false;
			}
		}
		case TFClass_Soldier:
		{
			if( bGiants )
			{
				if( iVariant < -1 || iVariant > MAX_SOLDIER_GIANT )
					return false;
			}
			else
			{
				if( iVariant < -1 || iVariant > MAX_SOLDIER )
					return false;
			}
		}
		case TFClass_Pyro:
		{
			if( bGiants )
			{
				if( iVariant < -1 || iVariant > MAX_PYRO_GIANT )
					return false;
			}
			else
			{
				if( iVariant < -1 || iVariant > MAX_PYRO )
					return false;
			}
		}
		case TFClass_DemoMan:
		{
			if( bGiants )
			{
				if( iVariant < -1 || iVariant > MAX_DEMO_GIANT )
					return false;
			}
			else
			{
				if( iVariant < -1 || iVariant > MAX_DEMO )
					return false;
			}
		}
		case TFClass_Heavy:
		{
			if( bGiants )
			{
				if( iVariant < -1 || iVariant > MAX_HEAVY_GIANT )
					return false;
			}
			else
			{
				if( iVariant < -1 || iVariant > MAX_HEAVY )
					return false;
			}
		}
		case TFClass_Engineer:
		{
			if( bGiants )
			{
				if( iVariant < -1 || iVariant > MAX_ENGINEER_GIANT )
					return false;
			}
			else
			{
				if( iVariant < -1 || iVariant > MAX_ENGINEER )
					return false;
			}
		}
		case TFClass_Medic:
		{
			if( bGiants )
			{
				if( iVariant < -1 || iVariant > MAX_MEDIC_GIANT )
					return false;
			}
			else
			{
				if( iVariant < -1 || iVariant > MAX_MEDIC )
					return false;
			}
		}
		case TFClass_Sniper:
		{
			if( bGiants )
			{
				if( iVariant < -1 || iVariant > MAX_SNIPER_GIANT )
					return false;
			}
			else
			{
				if( iVariant < -1 || iVariant > MAX_SNIPER )
					return false;
			}
		}
		case TFClass_Spy:
		{
			if( bGiants )
			{
				if( iVariant < -1 || iVariant > MAX_SPY_GIANT )
					return false;
			}
			else
			{
				if( iVariant < -1 || iVariant > MAX_SPY )
					return false;
			}
		}
	}
	
	return true;
}

// set effects and bot mode for variants
void SetVariantExtras(int client,TFClassType TFClass, int iVariant)
{
	iBotEffect[client] = 0; //reset
	
	switch( TFClass )
	{
/* 		case TFClass_Scout:
		{
			
		} */
		case TFClass_Soldier:
		{
			switch( iVariant )
			{
				case -1: iBotEffect[client] += BotEffect_FullCharge;
			}
		}
/* 		case TFClass_Pyro:
		{
			
		}
		case TFClass_DemoMan:
		{
			
		}
		case TFClass_Heavy:
		{
			
		} */
		case TFClass_Engineer:
		{
			switch( iVariant )
			{
				case -1: iBotEffect[client] += BotEffect_TeleportToHint;
				case 1: iBotEffect[client] += BotEffect_TeleportToHint;
			}			
		}
		case TFClass_Medic:
		{
			iBotEffect[client] += BotEffect_FullCharge;
		}
/* 		case TFClass_Sniper:
		{
			
		} */
		case TFClass_Spy:
		{
			iBotEffect[client] += BotEffect_AutoDisguise; // global to all spies
			switch( iVariant )
			{
				case 0: iBotEffect[client] += BotEffect_InfiniteCloak;
			}
		}
	}
}

void SetGiantVariantExtras(int client,TFClassType TFClass, int iVariant)
{
	iBotEffect[client] = 0; //reset
	
	switch( TFClass )
	{
/* 		case TFClass_Scout:
		{
			
		} */
		case TFClass_Soldier:
		{
			switch( iVariant )
			{
				case -1: iBotEffect[client] += BotEffect_FullCharge;
				case 1: iBotEffect[client] += BotEffect_AlwaysCrits;
			}			
		}
/* 		case TFClass_Pyro:
		{
			
		}
		case TFClass_DemoMan:
		{
			
		}
		case TFClass_Heavy:
		{
			
		}
		case TFClass_Engineer:
		{
			
		}
		case TFClass_Medic:
		{
			
		}
		case TFClass_Sniper:
		{
			
		} */
		case TFClass_Spy:
		{
			iBotEffect[client] += BotEffect_AutoDisguise; // global to all spies
		}
	}
}

// sets the player scale based on robot type
void SetRobotScale(client)
{
	bool bSmallMap = c_bSmallMap.BoolValue;
	
	if( bSmallMap )
	{
		if( iBotType[client] == Bot_Giant || iBotType[client] == Bot_Boss || iBotType[client] == Bot_Buster || iBotType[client] == Bot_Big )
		{
			ScalePlayerModel(client, 1.10);
		}
		else if( iBotType[client] == Bot_Small )
		{
			ScalePlayerModel(client, 0.65);
		}
		else
		{
			ScalePlayerModel(client, 1.00);
		}
	}
	else
	{
		if( iBotType[client] == Bot_Giant || iBotType[client] == Bot_Buster )
		{
			ScalePlayerModel(client, 1.75);
		}
		else if( iBotType[client] == Bot_Boss )
		{
			ScalePlayerModel(client, 1.90);
		}
		else if( iBotType[client] == Bot_Big )
		{
			ScalePlayerModel(client, 1.5); // placeholder, not all classes uses 1.65 for big mode
		}
		else if( iBotType[client] == Bot_Small )
		{
			ScalePlayerModel(client, 0.65);
		}
		else
		{
			ScalePlayerModel(client, 1.00);
		}
	}
}

// change player size and update hitbox
void ScalePlayerModel(const int client, const float fScale)
{
	static const float vecTF2PlayerMin[3] = { -24.5, -24.5, 0.0 }, vecTF2PlayerMax[3] = { 24.5,  24.5, 83.0 };

	float vecScaledPlayerMin[3];
	float vecScaledPlayerMax[3];

	vecScaledPlayerMin = vecTF2PlayerMin;
	vecScaledPlayerMax = vecTF2PlayerMax;

	ScaleVector(vecScaledPlayerMin, fScale);
	ScaleVector(vecScaledPlayerMax, fScale);

	SetEntPropVector(client, Prop_Send, "m_vecSpecifiedSurroundingMins", vecScaledPlayerMin);
	SetEntPropVector(client, Prop_Send, "m_vecSpecifiedSurroundingMaxs", vecScaledPlayerMax);
	SetEntPropFloat( client, Prop_Send, "m_flModelScale", fScale );
}

// fired when a players refund
void OnRefund(int client)
{
	if(g_bUpgradeStation[client])
	{
		g_bUpgradeStation[client] = false;
	}
}

void ResetRobotData(int client)
{
	iBotType[client] = Bot_Normal;
	iBotVariant[client] = 0;
	iBotEffect[client] = 0;
	BotClass[client] = TFClass_Unknown;
	g_bIsCarrier[client] = false;
	g_bUpgradeStation[client] = false;
}

// sets robot model
void SetRobotModel(int client, TFClassType TFClass)
{
	char strModel[PLATFORM_MAX_PATH];
	
	switch( TFClass )
	{
		case TFClass_Scout: strcopy( strModel, sizeof(strModel), "scout" );
		case TFClass_Sniper: strcopy( strModel, sizeof(strModel), "sniper" );
		case TFClass_Soldier: strcopy( strModel, sizeof(strModel), "soldier" );
		case TFClass_DemoMan: strcopy( strModel, sizeof(strModel), "demo" );
		case TFClass_Medic: strcopy( strModel, sizeof(strModel), "medic" );
		case TFClass_Heavy: strcopy( strModel, sizeof(strModel), "heavy" );
		case TFClass_Pyro: strcopy( strModel, sizeof(strModel), "pyro" );
		case TFClass_Spy: strcopy( strModel, sizeof(strModel), "spy" );
		case TFClass_Engineer: strcopy( strModel, sizeof(strModel), "engineer" );
	}
	
	if( strlen(strModel) > 0 )
	{
		if( iBotType[client] == Bot_Giant || iBotType[client] == Bot_Boss )
		{
			if( TFClass == TFClass_DemoMan || TFClass == TFClass_Heavy || TFClass == TFClass_Pyro || TFClass == TFClass_Scout || TFClass == TFClass_Soldier )
				Format( strModel, sizeof( strModel ), "models/bots/%s_boss/bot_%s_boss.mdl", strModel, strModel );
			else
				Format( strModel, sizeof( strModel ), "models/bots/%s/bot_%s.mdl", strModel, strModel );
		}
		else if( iBotType[client] == Bot_Buster )
		{
			Format( strModel, sizeof( strModel ), "models/bots/demo/bot_sentry_buster.mdl" );
		}
		else
		{
			Format( strModel, sizeof( strModel ), "models/bots/%s/bot_%s.mdl", strModel, strModel );
		}
		
		if( OR_IsHalloweenMission() )
		{
			SetVariantString( "" );
			AcceptEntityInput( client, "SetCustomModel" );
		}
		else
		{
			SetVariantString( strModel );
			AcceptEntityInput( client, "SetCustomModel" );
			SetEntProp( client, Prop_Send, "m_bUseClassAnimations", 1 );
		}
	}
}

// teleports robot players to random spawn points
void TeleportToSpawnPoint(int client, TFClassType TFClass)
{
	int iSpawn;
	float vecOrigin[3];
	float vecAngles[3];
	
	if( iBotType[client] == Bot_Giant || iBotType[client] == Bot_Big )
	{
		iSpawn = FindRandomSpawnPoint( Spawn_Giant );
	}
	else if( iBotType[client] == Bot_Buster )
	{
		iSpawn = FindRandomSpawnPoint( Spawn_Buster );		
	}
	else if( iBotType[client] == Bot_Boss )
	{
		iSpawn = FindRandomSpawnPoint( Spawn_Boss );		
	}
	else if( TFClass == TFClass_Sniper )
	{
		iSpawn = FindRandomSpawnPoint( Spawn_Sniper );
	}
	else if( TFClass == TFClass_Spy )
	{
		iSpawn = FindRandomSpawnPoint( Spawn_Spy );
	}
	else
	{
		iSpawn = FindRandomSpawnPoint( Spawn_Normal );
	}
	
	if( iSpawn > MaxClients && IsValidEntity(iSpawn) )
	{
		GetEntPropVector( iSpawn, Prop_Send, "m_vecOrigin", vecOrigin );
		GetEntPropVector( iSpawn, Prop_Data, "m_angRotation", vecAngles );		
		TeleportEntity(client, vecOrigin, vecAngles, NULL_VECTOR);
	}
}

// finds a random spawn point for human players
int FindRandomSpawnPoint( SpawnType iType )
{
	int iEnt = -1;
	char strSpawnName[64];
	
	array_spawns.Clear();
	
	while( ( iEnt = FindEntityByClassname( iEnt, "info_player_teamspawn") ) != -1 )
		if( GetEntProp( iEnt, Prop_Send, "m_iTeamNum" ) == view_as<int>(TFTeam_Blue) && GetEntProp( iEnt, Prop_Data, "m_bDisabled" ) == 0 ) // ignore disabled spawn points
		{
			GetEntPropString( iEnt, Prop_Data, "m_iName", strSpawnName, sizeof(strSpawnName) );
			
			if( iType == Spawn_Normal )
			{
				if( StrEqual( strSpawnName, "spawnbot" ) )
				{
					array_spawns.Push( iEnt );
				}
				else if( StrEqual( strSpawnName, "spawnbot_bvm" ) ) // custom spawn point
				{
					array_spawns.Push( iEnt );
				}
				else if( StrEqual( strSpawnName, "spawnbot_invasion" ) )
				{
					array_spawns.Push( iEnt );
				}
				else if( StrEqual( strSpawnName, "spawnbot_lower" ) )
				{
					array_spawns.Push( iEnt );
				}
				else if( StrEqual( strSpawnName, "spawnbot_left" ) )
				{
					array_spawns.Push( iEnt );
				}
				else if( StrEqual( strSpawnName, "spawnbot_right" ) )
				{
					array_spawns.Push( iEnt );
				}
				else if( StrEqual( strSpawnName, "spawnbot_single_flag" ) )
				{
					array_spawns.Push( iEnt );
				}
				else if( StrEqual( strSpawnName, "spawnbot_main0" ) ) // mannhattan
				{
					array_spawns.Push( iEnt );
				}
				else if( StrEqual( strSpawnName, "spawnbot_main1" ) )
				{
					array_spawns.Push( iEnt );
				}
				else if( StrEqual( strSpawnName, "spawnbot_main2" ) )
				{
					array_spawns.Push( iEnt );
				}
				else if( StrEqual( strSpawnName, "spawnbot_upper0" ) )
				{
					array_spawns.Push( iEnt );
				}
				else if( StrEqual( strSpawnName, "spawnbot_upper1" ) )
				{
					array_spawns.Push( iEnt );
				}
				else if( StrEqual( strSpawnName, "spawnbot_upper2" ) )
				{
					array_spawns.Push( iEnt );
				}
			}
			else if( iType == Spawn_Giant || iType == Spawn_Buster )
			{
				if( StrEqual( strSpawnName, "spawnbot_giant" ) )
				{
					array_spawns.Push( iEnt );
				}
				else if( StrEqual( strSpawnName, "spawnbot_main0_squad" ) ) // mannhattan
				{
					array_spawns.Push( iEnt );
				}
				else if( StrEqual( strSpawnName, "spawnbot_main1" ) )
				{
					array_spawns.Push( iEnt );
				}
				else if( StrEqual( strSpawnName, "spawnbot_main2_giants" ) )
				{
					array_spawns.Push( iEnt );
				}
				else if( StrEqual( strSpawnName, "spawnbot_mission_sentry_buster" ) && iType == Spawn_Buster )
				{
					array_spawns.Push( iEnt );
				}
				else if( StrEqual( strSpawnName, "spawnbot_mission_sentrybuster" ) && iType == Spawn_Buster )
				{
					array_spawns.Push( iEnt );
				}
			}
			else if( iType == Spawn_Sniper )
			{
				if( StrEqual( strSpawnName, "spawnbot_mission_sniper" ) )
				{
					array_spawns.Push( iEnt );
				}
				else if( StrEqual( strSpawnName, "spawnbot_mission_sniper0" ) )
				{
					array_spawns.Push( iEnt );
				}
				else if( StrEqual( strSpawnName, "spawnbot_mission_sniper1" ) )
				{
					array_spawns.Push( iEnt );
				}
				else if( StrEqual( strSpawnName, "spawnbot_mission_sniper2" ) )
				{
					array_spawns.Push( iEnt );
				}
				else if( StrEqual( strSpawnName, "spawnbot_mission_sniper3" ) )
				{
					array_spawns.Push( iEnt );
				}
			}
			else if( iType == Spawn_Spy )
			{
				if( StrEqual( strSpawnName, "spawnbot_mission_spy" ) )
				{
					array_spawns.Push( iEnt );
				}
			}
			else if( iType == Spawn_Boss )
			{
				// look for boss spawn points first
				if( StrEqual( strSpawnName, "spawnbot_chief" ) )
				{
					array_spawns.Push( iEnt );
				}
				else if( StrEqual( strSpawnName, "spawnbot_boss" ) )
				{
					array_spawns.Push( iEnt );
				}

				// if none is found, use giant spawn points.
				if( array_spawns.Length < 1 )
				{
					if( StrEqual( strSpawnName, "spawnbot_giant" ) )
					{
						array_spawns.Push( iEnt );
					}
					else if( StrEqual( strSpawnName, "spawnbot_main0_squad" ) ) // mannhattan
					{
						array_spawns.Push( iEnt );
					}
					else if( StrEqual( strSpawnName, "spawnbot_main1" ) )
					{
						array_spawns.Push( iEnt );
					}
					else if( StrEqual( strSpawnName, "spawnbot_main2_giants" ) )
					{
						array_spawns.Push( iEnt );
					}			
				}
			}
		}
	if( array_spawns.Length > 0 )
	{
		int iCell = GetRandomInt(0, (array_spawns.Length - 1));
		return array_spawns.Get(iCell);
	}
		
	return -1;
}

// add plugin tag to sv_tags
void AddPluginTag(const char[] tag)
{
	char tags[255];
	c_svTag.GetString(tags, sizeof(tags));

	if (!(StrContains(tags, tag, false)>-1))
	{
		char newTags[255];
		Format(newTags, sizeof(newTags), "%s,%s", tags, tag);
		c_svTag.SetString(newTags, _, true);
		c_svTag.GetString(tags, sizeof(tags));
	}
}

// checks for team balance
void CheckTeams()
{
	int iMaxBlu = c_iMaxBlu.IntValue;
	int iInBlu = GetHumanRobotCount();
	int iInRed = GetTeamClientCount(2);
	int iTarget;
	bool bAutoBalance = c_bAutoTeamBalance.BoolValue;
	// checks BLU player count
	if( iInBlu > iMaxBlu && iInBlu > 0 )
	{
		int iOverLimit = iInBlu - iMaxBlu;
		for( int i = 1; i <= iOverLimit; i++ )
		{
			iTarget = GetRandomPlayer(TFTeam_Blue, false);
			if( iTarget > 0 )
			{
				TF2_ChangeClientTeam(iTarget, TFTeam_Red);
				CPrintToChat(iTarget, "%t", "Moved Blu Full");
			}
		}
	}
	if( bAutoBalance )
	{
		// if the number of players in RED is less than the minimum to join BLU
		if( iInRed < c_iMinRed.IntValue && iInBlu > 0 )
		{
			int iCount = c_iMinRed.IntValue - iInRed;
			for( int i = 1; i <= iCount; i++ )
			{
				iTarget = GetRandomPlayer(TFTeam_Blue, false);
				if( iTarget > 0 )
				{
					TF2_ChangeClientTeam(iTarget, TFTeam_Red);
					CPrintToChat(iTarget, "%t", "Moved Blu Balance");
				}
			}
		}
	}
}