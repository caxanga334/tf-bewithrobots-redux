#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <morecolors>
#include <caxanga334>
#define REQUIRE_PLUGIN
#include <tf2attributes>
#include <tf2_isPlayerInSpawn>
#include <tf2wearables>
#include <navmesh>
#define REQUIRE_EXTENSIONS
#define AUTOLOAD_EXTENSIONS
#include <sdkhooks>
#include <tf2items>
#undef REQUIRE_EXTENSIONS
#include <SteamWorks>
#include "bwrredux/objectiveres.sp"
#include "bwrredux/bot_variants.sp"
#include "bwrredux/functions.sp"

#define PLUGIN_VERSION "0.0.8"

// maximum class variants that exists
#define MAX_SCOUT 6
#define MAX_SCOUT_GIANT 1
#define MAX_SOLDIER 6
#define MAX_SOLDIER_GIANT 1
#define MAX_PYRO 3
#define MAX_PYRO_GIANT 1
#define MAX_DEMO 3
#define MAX_DEMO_GIANT 1
#define MAX_HEAVY 1
#define MAX_HEAVY_GIANT 1
#define MAX_ENGINEER 3
#define MAX_ENGINEER_GIANT 1
#define MAX_MEDIC 1
#define MAX_MEDIC_GIANT 1
#define MAX_SNIPER 1
#define MAX_SNIPER_GIANT 1
#define MAX_SPY 3
#define MAX_SPY_GIANT 1
// giant sounds
#define ROBOT_SND_GIANT_SCOUT "mvm/giant_scout/giant_scout_loop.wav"
#define ROBOT_SND_GIANT_SOLDIER "mvm/giant_soldier/giant_soldier_loop.wav"
#define ROBOT_SND_GIANT_PYRO "mvm/giant_pyro/giant_pyro_loop.wav"
#define ROBOT_SND_GIANT_DEMOMAN "mvm/giant_demoman/giant_demoman_loop.wav"
#define ROBOT_SND_GIANT_HEAVY ")mvm/giant_heavy/giant_heavy_loop.wav"
#define ROBOT_SND_SENTRY_BUSTER "mvm/sentrybuster/mvm_sentrybuster_loop.wav"

// player robot variants prefix: p_
int p_iBotType[MAXPLAYERS + 1];
int p_iBotVariant[MAXPLAYERS + 1];
int p_iBotAttrib[MAXPLAYERS + 1];
TFClassType p_BotClass[MAXPLAYERS + 1];
bool p_bSpawned[MAXPLAYERS + 1]; // store if a player has recently spawned.
TFTeam p_iBotTeam[MAXPLAYERS + 1]; // player's team.

// bomb
bool g_bIsCarrier[MAXPLAYERS + 1]; // true if the player is carrying the bomb
Handle HT_BombDeployTimer;

ArrayList array_avclass; // array containing available classes
ArrayList array_spawns; // spawn points for human players

// others
bool g_bUpgradeStation[MAXPLAYERS + 1];
float g_flNextBusterTime;
Handle HT_HumanRobotWaveSpawn;

// convars
ConVar c_iMinRed;
ConVar c_iMinRedinProg; // minimum red players to join BLU while the wave is in progress.
ConVar c_iGiantChance;
ConVar c_iGiantMinRed; // minimum red players to allow giants.
ConVar c_iMaxBlu; // maximum blu players allowed
ConVar c_flBluRespawnTime; // blu players respawn time
ConVar c_bAutoTeamBalance;
ConVar c_bSmallMap; // change robot scale to avoid getting stuck in maps such as mvm_2fort
ConVar c_flBusterDelay; // delay between human sentry buster spawns.
ConVar c_iBusterMinKills; // minimum amount of kills a sentry needs to have before becoming a threat;
ConVar c_svTag; // server tags

// user messages
UserMsg ID_MVMResetUpgrade = INVALID_MESSAGE_ID;

// offsets
int g_iOffsetMissionBot;
int g_iOffsetSupportLimited;

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
	BotAttrib_None = 0,
	BotAttrib_AlwaysCrits = 1,
	BotAttrib_FullCharge = 2,
	BotAttrib_InfiniteCloak = 4,
	BotAttrib_AutoDisguise = 8,
	BotAttrib_AlwaysMiniCrits = 16,
	BotAttrib_TeleportToHint = 32, // teleport engineers to a nest near the bomb.
	BotAttrib_CannotCarryBomb = 64,
	BotAttrib_CannotBuildTele = 128, // disallow engineers to build teleporters
};

// Methodmaps

methodmap RoboPlayer
{
	public RoboPlayer(int index) { return view_as<RoboPlayer>(index); }
	property int index 
	{ 
		public get()	{ return view_as<int>(this); }
	}
	property int Type
	{
		public get()	{ return p_iBotType[this.index]; }
		public set( int value ) { p_iBotType[this.index] = value; }
	}
	property int Variant
	{
		public get()	{ return p_iBotVariant[this.index]; }
		public set( int value ) { p_iBotVariant[this.index] = value; }
	}
	property int Attributes
	{
		public get()	{ return p_iBotAttrib[this.index]; }
		public set( int value ) { p_iBotAttrib[this.index] = value; }
	}
	property TFClassType Class
	{
		public get()	{ return p_BotClass[this.index]; }
		public set( TFClassType class ) { p_BotClass[this.index] = class; }
	}
	property bool Carrier
	{
		public get()	{ return g_bIsCarrier[this.index]; }
		public set( bool value ) { g_bIsCarrier[this.index] = value; }
	}
}
 
public Plugin myinfo =
{
	name = "[TF2] Be With Robots Redux",
	author = "caxanga334",
	description = "Allows players to play as a robot in MvM",
	version = PLUGIN_VERSION,
	url = "https://github.com/caxanga334/tf-bewithrobots-redux"
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
	// game data
	Handle hConf = LoadGameConfigFile("bwr-redux");
	
	if(LookupOffset(g_iOffsetMissionBot,         "CTFPlayer", "m_nCurrency"))		    g_iOffsetMissionBot         -= GameConfGetOffset(hConf, "m_bMissionBot");
	if(LookupOffset(g_iOffsetSupportLimited,     "CTFPlayer", "m_nCurrency"))		    g_iOffsetSupportLimited     -= GameConfGetOffset(hConf, "m_bSupportLimited");

	// convars
	CreateConVar("sm_bwrr_version", PLUGIN_VERSION, "Be With Robots: Redux plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	c_iMinRed = CreateConVar("sm_bwrr_minred", "5", "Minimum amount of players on RED team to allow joining ROBOTs.", FCVAR_NONE, true, 0.0, true, 10.0);
	c_iMinRedinProg = CreateConVar("sm_bwrr_minred_inprog", "7", "Minimum amount of players on RED team to allow joining ROBOTs while the wave is in progress.", FCVAR_NONE, true, 0.0, true, 10.0);
	c_iGiantChance = CreateConVar("sm_bwrr_giantchance", "30", "Chance in percentage to human players to spawn as a giant. 0 = Disabled.", FCVAR_NONE, true, 0.0, true, 100.0);
	c_iGiantMinRed = CreateConVar("sm_bwrr_giantminred", "5", "Minimum amount of players on RED team to allow human giants. 0 = Disabled.", FCVAR_NONE, true, 0.0, true, 8.0);
	c_iMaxBlu = CreateConVar("sm_bwrr_maxblu", "4", "Maximum amount of players in BLU team.", FCVAR_NONE, true, 1.0, true, 5.0);
	c_bAutoTeamBalance = CreateConVar("sm_bwrr_autoteambalance", "1", "Balance teams at wave start?", FCVAR_NONE, true, 0.0, true, 1.0);
	c_bSmallMap = CreateConVar("sm_bwrr_smallmap", "0", "Use small robot size for human players. Enable if players are getting stuck.", FCVAR_NONE, true, 0.0, true, 1.0);
	c_flBusterDelay = CreateConVar("sm_bwrr_sentry_buster_delay", "95.0", "Delay between human sentry buster spawn.", FCVAR_NONE, true, 30.0, true, 1200.0);
	c_iBusterMinKills = CreateConVar("sm_bwrr_sentry_buster_minkills", "15", "Minimum amount of kills a sentry gun must have to become a threat.", FCVAR_NONE, true, 5.0, true, 50.0);
	c_flBluRespawnTime = CreateConVar("sm_bwrr_blu_respawn_time", "15.0", "Wave respawn time for BLU players.", FCVAR_NONE, true, 5.0, true, 30.0);
	
	c_svTag = FindConVar("sv_tags");
	
	// convar hooks
	if( c_svTag != null )
	{
		c_svTag.AddChangeHook(OnTagsChanged);
	}
	
	// translations
	LoadTranslations("bwrredux.phrases");
	LoadTranslations("common.phrases");
	
	// timers
	CreateTimer(180.0, Timer_Announce, _, TIMER_REPEAT);
	
	// commands
	RegConsoleCmd( "sm_joinred", Command_JoinRED, "Joins RED team." );
	RegConsoleCmd( "sm_joinblu", Command_JoinBLU, "Joins BLU/Robot team." );
	RegConsoleCmd( "sm_joinblue", Command_JoinBLU, "Joins BLU/Robot team." );
	RegConsoleCmd( "sm_bwr", Command_JoinBLU, "Joins BLU/Robot team." );
	RegConsoleCmd( "sm_bewithrobots", Command_JoinBLU, "Joins BLU/Robot team." );
	RegConsoleCmd( "sm_robotclass", Command_BotClass, "Changes your robot variant." );
	RegConsoleCmd( "sm_rc", Command_BotClass, "Changes your robot variant." );
	RegConsoleCmd( "sm_bwrr_players", Command_ShowPlayers, "Shows the players in each team" );
	RegAdminCmd( "sm_bwrr_debug", Command_Debug, ADMFLAG_ROOT, "Prints some debug messages." );
	RegAdminCmd( "sm_bwrr_forcebot", Command_ForceBot, ADMFLAG_ROOT, "Forces a specific robot variant on the target." );
	RegAdminCmd( "sm_bwrr_move", Command_MoveTeam, ADMFLAG_BAN, "Changes the target player team." );
	
	// listener
	AddCommandListener( Listener_JoinTeam, "jointeam" );
	AddCommandListener( Listener_Ready, "tournament_player_readystate" );
	AddCommandListener( Listener_Suicide, "kill" );
	AddCommandListener( Listener_Suicide, "explode" );
	AddCommandListener( Listener_Suicide, "dropitem" ); // not a suicide command but same blocking rule
	AddCommandListener( Listener_Suicide, "td_buyback" ); // not a suicide command but same blocking rule
	AddCommandListener( Listener_Build, "build" );
	AddCommandListener( Listener_CallVote, "callvote" );
	AddCommandListener( Listener_Taunt, "taunt" );
	AddCommandListener( Listener_Taunt, "+taunt" );
	
	
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
	HookEvent( "player_builtobject", E_BuildObject, EventHookMode_Pre );
	
	ID_MVMResetUpgrade = GetUserMessageId("MVMResetPlayerUpgradeSpending");
	if(ID_MVMResetUpgrade == INVALID_MESSAGE_ID)
		LogError("Unable to hook user message.");
		
	HookUserMessage(ID_MVMResetUpgrade, MsgHook_MVMRespec);
	
	array_avclass = new ArrayList(10);
	array_spawns = new ArrayList();
	
	AutoExecConfig(true, "plugin.bwrredux");
}

public void OnLibraryAdded(const char[] name)
{
	if(StrEqual(name, "SteamWorks", false))
	{
		SteamWorks_SetGameDescription("Be With Robots Redux");
	}
}

public void OnMapStart()
{
	if(!IsMvM(true))
	{
		SetFailState("This plugin is for Mann vs Machine Only.") // probably easier than add IsMvM everywhere
	}
	
	if(LibraryExists("SteamWorks"))
		SteamWorks_SetGameDescription("Be With Robots Redux");
	
	int i = -1;
	
	while ((i = FindEntityByClassname(i, "func_upgradestation")) != -1)
	{
		if(IsValidEntity(i))
		{
			SDKHook(i, SDKHook_StartTouch, OnTouchUpgradeStation);
		} 
	}
	
	array_avclass.Clear();
	
	// add custom tag
	AddPluginTag("BWRR");
	
	// prechace
	PrecacheSound("vo/mvm_spy_spawn01.mp3");
	PrecacheSound("vo/mvm_spy_spawn02.mp3");
	PrecacheSound("vo/mvm_spy_spawn03.mp3");
	PrecacheSound("vo/mvm_spy_spawn04.mp3");
	PrecacheSound("vo/mvm_spybot_death04.mp3");
	PrecacheSound("vo/mvm_spybot_death05.mp3");
	PrecacheSound("vo/mvm_spybot_death06.mp3");
	PrecacheSound("vo/mvm_spybot_death07.mp3");
	PrecacheSound("vo/announcer_mvm_eng_tele_activated01.mp3");
	PrecacheSound("vo/announcer_mvm_eng_tele_activated02.mp3");
	PrecacheSound("vo/announcer_mvm_eng_tele_activated03.mp3");
	PrecacheSound("vo/announcer_mvm_eng_tele_activated04.mp3");
	PrecacheSound("vo/announcer_mvm_eng_tele_activated05.mp3");
	PrecacheSound("vo/announcer_mvm_engbot_another01.mp3");
	PrecacheSound("vo/announcer_mvm_engbot_another02.mp3");
	PrecacheSound("vo/announcer_mvm_engbot_arrive01.mp3");
	PrecacheSound("vo/announcer_mvm_engbot_arrive02.mp3");
	PrecacheSound("vo/announcer_mvm_engbot_arrive03.mp3");
	PrecacheSound("vo/announcer_mvm_engbot_dead_notele01.mp3");
	PrecacheSound("vo/announcer_mvm_engbot_dead_notele02.mp3");
	PrecacheSound("vo/announcer_mvm_engbot_dead_notele03.mp3");
	PrecacheSound("vo/announcer_mvm_engbot_dead_tele01.mp3");
	PrecacheSound("vo/announcer_mvm_engbot_dead_tele02.mp3");
	PrecacheSound(")mvm/sentrybuster/mvm_sentrybuster_explode.wav");
	PrecacheSound(")mvm/sentrybuster/mvm_sentrybuster_spin.wav");
	PrecacheSound("vo/mvm_sentry_buster_alerts01.mp3");
	PrecacheSound("vo/mvm_sentry_buster_alerts04.mp3");
	PrecacheSound("vo/mvm_sentry_buster_alerts05.mp3");
	PrecacheSound("vo/mvm_sentry_buster_alerts06.mp3");
	PrecacheSound("vo/mvm_sentry_buster_alerts07.mp3");
}

/* public void OnClientConnected(client)
{

} */

public void OnClientDisconnect(client)
{
	p_iBotTeam[client] = TFTeam_Unassigned;
	ResetRobotData(client);
	StopRobotLoopSound(client);
}

public void OnGameFrame()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i))
		{		
			if(TF2_GetClientTeam(i) == TFTeam_Blue)
			{
				if( GameRules_GetRoundState() == RoundState_BetweenRounds )
				{
					TF2_AddCondition(i, TFCond_FreezeInput, 0.255);
					TF2_AddCondition(i, TFCond_UberchargedHidden, 0.255);
				}
				else if( TF2Spawn_IsClientInSpawn2(i) )
				{
					TF2_AddCondition(i, TFCond_UberchargedHidden, 0.255);
				}
				
				if( p_iBotAttrib[i] & BotAttrib_InfiniteCloak )
				{
					SetEntPropFloat( i, Prop_Send, "m_flCloakMeter", 100.0 );
				}
			}
		}
	}
}

public void TF2Spawn_EnterSpawn(int client,int entity)
{
	if(TF2_GetClientTeam(client) == TFTeam_Blue && !IsFakeClient(client))
	{
		TF2_AddCondition(client, TFCond_UberchargedHidden, TFCondDuration_Infinite);
	}	
}

public void TF2Spawn_LeaveSpawn(int client,int entity)
{
	if(TF2_GetClientTeam(client) == TFTeam_Blue && !IsFakeClient(client))
	{
		TF2_RemoveCondition(client, TFCond_UberchargedHidden);
		
		if( GameRules_GetRoundState() == RoundState_BetweenRounds && !p_bSpawned[client] )
		{
			TF2_RespawnPlayer(client);
		}
	}
}

public void OnEntityCreated(int iEntity,const char[] name)
{
	if ( StrEqual( name, "func_capturezone", false) )
	{
		SDKHook(iEntity, SDKHook_Touch, OnTouchCaptureZone);
		SDKHook(iEntity, SDKHook_EndTouch, OnEndTouchCaptureZone);
	}
	else if ( StrEqual( name, "entity_revive_marker", false) )
	{
		CreateTimer(0.1, Timer_KillReviveMarker, iEntity);
	}
	else if( StrEqual( name, "entity_medigun_shield", false ) )
	{
		if(IsValidEntity(iEntity))
		{
			int iOwner = GetEntPropEnt( iEntity, Prop_Send, "m_hOwnerEntity" );
			if( IsValidClient(iOwner) && TF2_GetClientTeam(iOwner) == TFTeam_Blue && !IsFakeClient(iOwner) )
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
		
		if( p_iBotType[client] == Bot_Buster )
		{
			if( buttons & IN_ATTACK )
			{
				if( !(TF2_IsPlayerInCondition(client, TFCond_Taunting)) )
				{
					FakeClientCommand(client, "taunt");
					return Plugin_Continue;
				}
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
	AddPluginTag("BWRR");
}

/****************************************************
					SDKHOOKS
*****************************************************/

public Action OnTouchUpgradeStation(int entity, int other)
{
	if(IsValidClient(other) && !IsFakeClient(other))
	{
		if( TF2_GetClientTeam(other) == TFTeam_Blue )
		{
			ForcePlayerSuicide(other);
			return;
		}
		if(!g_bUpgradeStation[other])
		{
			g_bUpgradeStation[other] = true;
		}
	}
}

public Action OnTouchCaptureZone(int entity, int other)
{		
	if( IsValidClient(other) && IsFakeClient(other) )
		return Plugin_Continue;
		
	if( IsValidClient(other) && TF2_GetClientTeam(other) != TFTeam_Blue )
		return Plugin_Continue;
		
	if( GameRules_GetRoundState() == RoundState_TeamWin )
		return Plugin_Stop;

	if(IsValidClient(other))
	{
		if( g_bIsCarrier[other] )
		{
			float CarrierPos[3];
			GetClientAbsOrigin(other, CarrierPos);
			TF2_AddCondition(other, TFCond_FreezeInput, 2.3);
			if( HT_BombDeployTimer == INVALID_HANDLE )
			{
				HT_BombDeployTimer = CreateTimer(2.1, Timer_DeployBomb, other);
				if( p_iBotType[other] == Bot_Giant || p_iBotType[other] == Bot_Boss )
					EmitGameSoundToAll("MVM.DeployBombGiant", other, SND_NOFLAGS, other, CarrierPos);
				else
					EmitGameSoundToAll("MVM.DeployBombSmall", other, SND_NOFLAGS, other, CarrierPos);
			}
		}
	}
	
	return Plugin_Continue;
}

public Action OnEndTouchCaptureZone(int entity, int other)
{
	if( IsValidClient(other) && IsFakeClient(other) )
		return Plugin_Continue;
		
	if( IsValidClient(other) && TF2_GetClientTeam(other) != TFTeam_Blue )
		return Plugin_Continue;
		
	if( GameRules_GetRoundState() == RoundState_TeamWin )
		return Plugin_Stop;
		
	if(IsValidClient(other))
	{
		if( g_bIsCarrier[other] )
		{
			if( HT_BombDeployTimer != INVALID_HANDLE )
			{
				CloseHandle(HT_BombDeployTimer);
				HT_BombDeployTimer = INVALID_HANDLE;
			}
		}
	}
	
	return Plugin_Continue;
}

/****************************************************
					USER MESSAGES
*****************************************************/

// fired when a players refund
void OnRefund(int client)
{
	if(g_bUpgradeStation[client])
	{
		g_bUpgradeStation[client] = false;
	}
}

/****************************************************
					COMMANDS
*****************************************************/

public Action Command_JoinBLU( int client, int nArgs )
{
	if( !IsClientInGame(client) || IsFakeClient(client) )
		return Plugin_Handled;
		
	if( TF2_GetClientTeam(client) == TFTeam_Blue || p_iBotTeam[client] == TFTeam_Blue )
		return Plugin_Handled;
		
	if( GameRules_GetRoundState() == RoundState_TeamWin )
		return Plugin_Handled;
		
	if( array_avclass.Length < 1 )
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
	
	if( GetHumanRobotCount() >= c_iMaxBlu.IntValue )
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
	
	//MovePlayerToBLU(client);
	p_iBotTeam[client] = TFTeam_Blue;
	MovePlayerToSpec(client);
	CReplyToCommand(client, "{cyan}You have joined BLU queue. You will spawn when the {green}wave starts");
	return Plugin_Handled;
}

public Action Command_JoinRED( int client, int nArgs )
{
	if( !IsClientInGame(client) || IsFakeClient(client) )
		return Plugin_Continue;
		
	if( TF2_GetClientTeam(client) == TFTeam_Red )
		return Plugin_Handled;
	
	p_iBotTeam[client] = TFTeam_Red;
	MovePlayerToRED(client);

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
	
	ReplyToCommand(client, "Class Array Size: %i", array_avclass.Length);
	
	for(int i = 0;i <= MaxClients;i++)
	{
		if( IsValidClient(i) && !IsFakeClient(i) )
		{
			switch( p_iBotTeam[i] )
			{
				case TFTeam_Red: ReplyToCommand(client, "%N Team: RED", i);
				case TFTeam_Blue: ReplyToCommand(client, "%N Team: BLU", i);
				case TFTeam_Spectator: ReplyToCommand(client, "%N Team: SPECTATOR", i);
				case TFTeam_Unassigned: ReplyToCommand(client, "%N Team: UNASSIGNED", i);
			}
		}
	}
	
	return Plugin_Handled;
}

public Action Command_ForceBot( int client, int nArgs )
{
	char arg1[MAX_NAME_LENGTH], arg2[16], arg3[4], arg4[4];
	bool bForceGiants = false;
	
	if( nArgs < 4 )
	{
		ReplyToCommand(client, "Usage: sm_bwrr_forcebot <target> <class> <type: 0 normal | 1 giant> <variant id>");
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
	
	bool bValid = IsValidVariant(bForceGiants, TargetClass, iArg4);
	if( !bValid )
	{
		ReplyToCommand(client, "ERROR: Invalid Variant");
		return Plugin_Handled;
	}
	
	for(int i = 0; i < target_count; i++)
	{
		if( TF2_GetClientTeam(target_list[i]) == TFTeam_Blue )
		{
			p_iBotVariant[target_list[i]] = iArg4;
			p_BotClass[target_list[i]] = TargetClass;
			if(bForceGiants)
			{
				p_iBotType[target_list[i]] = Bot_Giant;
				SetGiantVariantExtras(target_list[i],TargetClass, iArg4);
			}
			else
			{
				p_iBotType[target_list[i]] = Bot_Normal;
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
		ReplyToCommand(client, "Usage: sm_bwrr_move <target> <team: 1 - Spectator, 2 - Red, 3 - Blue>");
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
			if( array_avclass.Length < 1 )
			{
				ReplyToCommand(client, "Wave data needs to be built. Building data...");
				OR_Update();
				UpdateClassArray();
				return Plugin_Handled;
			}
			else
			{
				p_iBotTeam[target_list[i]] = TFTeam_Blue;
				//MovePlayerToBLU(target_list[i]);
				RemovePlayerFromBLU(target_list[i]);
			}
		}
		else if( NewTargetTeam == TFTeam_Red )
		{
			p_iBotTeam[target_list[i]] = TFTeam_Red;
			MovePlayerToRED(target_list[i]);
		}
		else
		{
			p_iBotTeam[target_list[i]] = TFTeam_Spectator;
			MovePlayerToSpec(target_list[i]);
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
		return Plugin_Handled;
		
	if( TF2_GetClientTeam(client) == TFTeam_Red )
		return Plugin_Handled;
		
	if( !TF2Spawn_IsClientInSpawn2(client) && GameRules_GetRoundState() == RoundState_RoundRunning )
	{
		ReplyToCommand(client, "This command can only be used inside the spawn");
		return Plugin_Handled;
	}

	PickRandomRobot(client);
	CreateTimer(0.5, Timer_Respawn, client);

	return Plugin_Handled;
}

public Action Command_ShowPlayers( int client, int nArgs )
{
		
	int iRedCount = 0, iBluCount = 0, iSpecCount = 0;
	char RedNames[256], BluNames[256], SpecNames[256];
	char plrname[256];
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if( IsClientInGame(i) && !IsFakeClient(i) )
		{
			if( TF2_GetClientTeam(i) == TFTeam_Red )
			{
				GetClientName(i, plrname, sizeof(plrname));
				Format(RedNames, sizeof(RedNames), "%s %s", plrname, RedNames);
				iRedCount++;
			}
			else if( TF2_GetClientTeam(i) == TFTeam_Blue )
			{
				GetClientName(i, plrname, sizeof(plrname));
				Format(BluNames, sizeof(BluNames), "%s %s", plrname, BluNames);
				iBluCount++;
			}
			else if( TF2_GetClientTeam(i) == TFTeam_Spectator || TF2_GetClientTeam(i) == TFTeam_Unassigned )
			{
				GetClientName(i, plrname, sizeof(plrname));
				Format(SpecNames, sizeof(SpecNames), "%s %s", plrname, SpecNames);				
				iSpecCount++;
			}
		}
	}
	
	CReplyToCommand(client, "{green}%i {cyan}player(s) in RED: {green}%s", iRedCount, RedNames);
	CReplyToCommand(client, "{green}%i {cyan}player(s) in BLU: {green}%s", iBluCount, BluNames);
	CReplyToCommand(client, "{green}%i {cyan}player(s) in SPEC: {green}%s", iSpecCount, SpecNames);

	return Plugin_Handled;
}

/****************************************************
					LISTENER
*****************************************************/

public Action Listener_JoinTeam(int client, const char[] command, int argc)
{
	if( !IsValidClient(client) )
		return Plugin_Handled;
		
	if( IsFakeClient(client) )
		return Plugin_Continue;
		
	char strTeam[16];
	GetCmdArg(1, strTeam, sizeof(strTeam));
	if( StrEqual( strTeam, "red", false ) )
	{
		FakeClientCommand(client, "sm_joinred");
		return Plugin_Handled;
	}
	else if( StrEqual( strTeam, "blue", false ) )
	{
		FakeClientCommand(client, "sm_joinblue");
		return Plugin_Handled;
	}
	else if( StrEqual( strTeam, "spectate", false ) || StrEqual( strTeam, "spectator", false ) )
	{
		p_iBotTeam[client] = TFTeam_Spectator;
		MovePlayerToSpec(client);
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

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
	if( TF2_GetClientTeam(client) != TFTeam_Blue )
		return Plugin_Continue;
		
	if( IsFakeClient(client) )
		return Plugin_Continue;

	if( TF2Spawn_IsClientInSpawn2(client) )
	{
		return Plugin_Handled;
	}
	
	char strArg1[8], strArg2[8];
	GetCmdArg(1, strArg1, sizeof(strArg1));
	GetCmdArg(2, strArg2, sizeof(strArg2));
	
	TFObjectType objType = view_as<TFObjectType>(StringToInt(strArg1));
	TFObjectMode objMode = view_as<TFObjectMode>(StringToInt(strArg2));
	
	if( objType == TFObject_Teleporter && objMode == TFObjectMode_Entrance )
		return Plugin_Handled;
		
	if( objType == TFObject_Teleporter && (p_iBotAttrib[client] & BotAttrib_CannotBuildTele ))
		return Plugin_Handled;
	
	return Plugin_Continue;
}

public Action Listener_CallVote(int client, const char[] command, int argc)
{
	if( TF2_GetClientTeam(client) == TFTeam_Blue )
	{
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Action Listener_Taunt(int client, const char[] command, int argc)
{
	if( IsFakeClient(client) )
		return Plugin_Continue;
	
	if( TF2_GetClientTeam(client) == TFTeam_Blue && p_iBotType[client] == Bot_Buster )
	{
		SentryBuster_Explode(client);
		return Plugin_Continue;
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
	g_flNextBusterTime = GetGameTime() + c_flBusterDelay.FloatValue;
	CreateWaveTimer();
}

public Action E_WaveEnd(Event event, const char[] name, bool dontBroadcast)
{
	CreateTimer(2.0, Timer_UpdateWaveData);
	for(int i = 1; i <= MaxClients; i++)
	{
		if( IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i) && TF2_GetClientTeam(i) == TFTeam_Blue )
		{
			CreateTimer(3.0, Timer_UpdateRobotClasses, i);
		}
	}
	DeleteWaveTimer();
}

public Action E_WaveFailed(Event event, const char[] name, bool dontBroadcast)
{
	OR_Update();
	UpdateClassArray();
	CreateTimer(2.0, Timer_RemoveFromSpec);
	DeleteWaveTimer();
}

public Action E_MissionComplete(Event event, const char[] name, bool dontBroadcast)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if( IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i) && TF2_GetClientTeam(i) == TFTeam_Blue )
		{
			MovePlayerToSpec(i);
		}
	}
	DeleteWaveTimer();
}

public Action E_ChangeClass(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	TFClassType TFClass = view_as<TFClassType>(event.GetInt("class"));
	
	if( TF2_GetClientTeam(client) == TFTeam_Blue && !IsFakeClient(client) )
	{
		if( IsClassAvailable(TFClass) )
		{
			p_BotClass[client] = TFClass;
			PickRandomVariant(client,TFClass,false);
			SetVariantExtras(client,TFClass, p_iBotVariant[client]);
		}
		else
		{
			PickRandomVariant(client,p_BotClass[client],false);
			SetVariantExtras(client,p_BotClass[client], p_iBotVariant[client]);
			TF2_SetPlayerClass(client,p_BotClass[client]);
		}
	}
}

public Action E_Pre_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if( TF2_GetClientTeam(client) == TFTeam_Blue && !IsFakeClient(client) )
	{
		if( p_iBotAttrib[client] & BotAttrib_AlwaysCrits )
		{
			TF2_AddCondition(client, TFCond_CritOnFlagCapture, TFCondDuration_Infinite);
		}
		if( p_iBotAttrib[client] & BotAttrib_AlwaysMiniCrits )
		{
			TF2_AddCondition(client, TFCond_Buffed, TFCondDuration_Infinite);
		}		
	}
}

public Action E_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if( IsFakeClient(client) )
		CreateTimer(1.0, Timer_OnFakePlayerSpawn, client);
	else
		CreateTimer(0.3, Timer_OnPlayerSpawn, client);
	
	if( array_avclass.Length < 1 )
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
	if( GameRules_GetRoundState() == RoundState_BetweenRounds && TF2_GetClientTeam(client) == TFTeam_Blue && !IsFakeClient(client) )
	{
		event.SetBool("silent_kill", true);
	}
	
	return Plugin_Continue;
}

public Action E_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	int deathflags = event.GetInt("death_flags");
	if(deathflags & TF_DEATHFLAG_DEADRINGER)
		return Plugin_Handled;
	
	if( TF2_GetClientTeam(client) == TFTeam_Blue && !IsFakeClient(client) )
	{
		if( TF2_GetPlayerClass(client) == TFClass_Engineer )
		{
			AnnounceEngineerDeath(client);
		}
		else if( TF2_GetPlayerClass(client) == TFClass_Spy )
		{
			if( GetClassCount(TFClass_Spy, TFTeam_Blue, true, false) <= 1 )
				EmitGSToRed("Announcer.mvm_spybot_death_all");
		}
		SetEntProp( client, Prop_Send, "m_bIsMiniBoss", view_as<int>(false) );
		if( p_iBotType[client] == Bot_Giant || p_iBotType[client] == Bot_Boss )
		{
			float SndPos[3];
			GetClientAbsOrigin(client, SndPos);
			EmitGameSoundToAll("MVM.GiantHeavyExplodes", client, SND_NOFLAGS, client, SndPos);
			float clientPosVec[3];
			GetClientAbsOrigin(client, clientPosVec);
			Robot_GibGiant(client, clientPosVec);
		}
		
		CreateTimer(0.15, Timer_RemoveFromBLU, client);
	}
	
	return Plugin_Continue;
}

public Action E_Inventory(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if(IsValidClient(client) && !IsFakeClient(client))
	{
		TFTeam Team = TF2_GetClientTeam(client);
		
		if(Team == TFTeam_Blue && !IsFakeClient(client) && IsClientInGame(client))
		{
			if( p_iBotVariant[client] >= 0 )
			{
				StripItems(client, true); // true: remove weapons
				
				if( p_iBotType[client] == Bot_Giant )
				{
					GiveGiantInventory(client,p_iBotVariant[client]);
				}
				else if( p_iBotType[client] == Bot_Buster )
				{
					GiveBusterInventory(client);
				}
				else
				{
					GiveNormalInventory(client,p_iBotVariant[client]);
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

public Action E_BuildObject(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	int index = event.GetInt("index");
	if( !IsFakeClient(client) && GetEntProp( index, Prop_Send, "m_iTeamNum" ) == view_as<int>(TFTeam_Blue) )
	{
		CreateTimer(0.1, Timer_BuildObject, index);
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
	if( !IsValidClient(client) )
		return Plugin_Stop;
		
	TFClassType TFClass = TF2_GetPlayerClass(client);
	char strBotName[128];
	int iTeleTarget = -1;
		
	if( TF2_GetClientTeam(client) == TFTeam_Blue && !IsFakeClient(client) )
	{
		SetEntData(client, g_iOffsetMissionBot, 	1, _, true);	//Makes player death not decrement wave bot count
		SetEntData(client, g_iOffsetSupportLimited, 0, _, true);	//Makes player death not decrement wave bot count
	
		//TF2_AddCondition(client, TFCond_UberchargedHidden, TFCondDuration_Infinite);
		g_bIsCarrier[client] = false;
		p_bSpawned[client] = true;
		CreateTimer(0.2, Timer_RemoveSpawnedBool, client);
		
		
		if( TFClass == TFClass_Spy && p_iBotAttrib[client] & BotAttrib_AutoDisguise )
		{
			int iTarget = GetRandomPlayer(TFTeam_Red, false);
			if( iTarget >= 1 && iTarget <= MaxClients )
			{
				TF2_DisguisePlayer(client, TFTeam_Red, TF2_GetPlayerClass(iTarget), iTarget);
			}
		}
		
		// TO DO: pyro's gas passer and phlog
		if( p_iBotAttrib[client] & BotAttrib_FullCharge )
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
		else if( p_iBotAttrib[client] & BotAttrib_CannotCarryBomb )
		{
			BlockBombPickup(client);
		}
		
		if(OR_IsHalloweenMission())
		{
			TF2_AddCondition(client, TFCond_CritOnFlagCapture, TFCondDuration_Infinite);
		}
		
		// prints the robot variant name to the player.
		if( p_iBotType[client] == Bot_Giant )
		{
			strBotName = GetGiantVariantName(TFClass, p_iBotVariant[client]);
			SetEntProp( client, Prop_Send, "m_bIsMiniBoss", view_as<int>(true) ); // has nothing to do with variant name but same condition
			ApplyRobotLoopSound(client);
		}
		else if( p_iBotType[client] == Bot_Boss )
		{
			strBotName = "Boss";
			SetEntProp( client, Prop_Send, "m_bIsMiniBoss", view_as<int>(true) );
			ApplyRobotLoopSound(client);
		}
		else if( p_iBotType[client] == Bot_Buster )
		{
			strBotName = "Sentry Buster";
			SetEntProp( client, Prop_Send, "m_bIsMiniBoss", view_as<int>(true) );
			EmitGSToRed("Announcer.MVM_Sentry_Buster_Alert");
			ApplyRobotLoopSound(client);
		}
		else
		{
			strBotName = GetNormalVariantName(TFClass, p_iBotVariant[client]);
			StopRobotLoopSound(client);
		}
		CPrintToChat(client, "%t", "Bot Spawn", strBotName);
		SetRobotScale(client,TFClass);
		SetRobotModel(client,TFClass);
		
		// teleport player
		if( GameRules_GetRoundState() == RoundState_RoundRunning )
		{
			switch( TFClass )
			{
				case TFClass_Spy: // spies should always spawn on their hints
				{
					TF2_AddCondition(client, TFCond_Stealthed, 5.0);
					TeleportSpyRobot(client);
					EmitGSToRed("Announcer.MVM_Spy_Alert");
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
						if( iTeleTarget != -1 && (p_iBotAttrib[client] & BotAttrib_TeleportToHint) ) // found nest
						{
							TeleportEngineerToEntity(iTeleTarget, client);
							if( GetClassCount(TFClass_Engineer, TFTeam_Blue, true, false) > 1 )
							{
								EmitGSToRed("Announcer.MVM_Another_Engineer_Teleport_Spawned");
							}
							else
							{
								EmitGSToRed("Announcer.MVM_First_Engineer_Teleport_Spawned");
							}
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
		if( p_iBotVariant[client] == -1 )
		{
			if( p_iBotType[client] == Bot_Giant )
				SetOwnAttributes(client ,true);
			else
				SetOwnAttributes(client ,false);
				
			TF2_RegeneratePlayer(client);
		}
	}
	
	return Plugin_Stop;
}

public Action Timer_OnFakePlayerSpawn(Handle timer, any client)
{
	int iTeleTarget = -1;
	
	if( IsClientInGame(client) )  // teleport bots to teleporters
	{
		iTeleTarget = FindBestBluTeleporter();
		if( iTeleTarget != -1 )
		{
			SpawnOnTeleporter(iTeleTarget,client);
		}
		return Plugin_Stop;
	}
	
	return Plugin_Stop;
}

public Action Timer_SetRobotClass(Handle timer, any client)
{
	if( !IsValidClient(client) || IsFakeClient(client) )
		return Plugin_Stop;
		
	TF2_SetPlayerClass(client, p_BotClass[client], _, true);
	
	return Plugin_Stop;
}

public Action Timer_Respawn(Handle timer, any client)
{
	if( !IsValidClient(client) || IsFakeClient(client) )
		return Plugin_Stop;
		
	TF2_RespawnPlayer(client);
	
	return Plugin_Stop;
}

public Action Timer_RespawnBLUPlayer(Handle timer, any client)
{
	if( !IsValidClient(client) || IsPlayerAlive(client) || IsFakeClient(client) )
		return Plugin_Stop;
		
	TF2_RespawnPlayer(client);
	
	return Plugin_Stop;
}

public Action Timer_WaveSpawnBluHuman(Handle timer)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if( IsValidClient(i) && !IsFakeClient(i) && !IsPlayerAlive(i) && GameRules_GetRoundState() == RoundState_RoundRunning )
		{
			if( p_iBotTeam[i] == TFTeam_Blue && TF2_GetClientTeam(i) == TFTeam_Spectator )
			{
				MovePlayerToBLU(i);
				CreateTimer(1.0, Timer_RespawnBLUPlayer, i);
			}
		}
	}
}

public Action Timer_RemoveFromBLU(Handle timer, any client)
{
	if( !IsValidClient(client) || IsFakeClient(client) )
		return Plugin_Stop;
		
	RemovePlayerFromBLU(client);
	
	return Plugin_Stop;
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
	
	return Plugin_Stop;
}

public Action Timer_UpdateWaveData(Handle timer)
{
	OR_Update();
	UpdateClassArray();
	
	return Plugin_Stop;
}

public Action Timer_UpdateRobotClasses(Handle timer, any client)
{
	PickRandomRobot(client);
	CreateTimer(0.5, Timer_Respawn, client);
	
	return Plugin_Stop;
}

public Action Timer_RemoveFromSpec(Handle timer, any client)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if( IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i) && TF2_GetClientTeam(i) == TFTeam_Spectator )
		{
			p_iBotTeam[i] = TFTeam_Red;
			MovePlayerToRED(i);
		}
	}
	
	return Plugin_Stop;
}

public Action Timer_BuildObject(Handle timer, any index)
{
	char classname[32];
	
	if( IsValidEdict(index) )
	{
		GetEdictClassname(index, classname, sizeof(classname))
		
		if( strcmp(classname, "obj_sentrygun", false) == 0 )
		{
			if( GetEntProp( index, Prop_Send, "m_bMiniBuilding" ) == 1 || GetEntProp( index, Prop_Send, "m_bDisposableBuilding" ) == 1 )
			{
				DispatchKeyValue(index, "defaultupgrade", "0");
			}
			else
			{
				DispatchKeyValue(index, "defaultupgrade", "2");
			}
		}
		else if( strcmp(classname, "obj_dispenser", false) == 0 )
		{
			SetEntProp(index, Prop_Send, "m_bMiniBuilding", 1);
			SetEntPropFloat(index, Prop_Send, "m_flModelScale", 0.90);
			SetVariantInt(100);
			AcceptEntityInput(index, "SetHealth");			
		}
		else if( strcmp(classname, "obj_teleporter", false) == 0 )
		{
			int iBuilder = GetEntPropEnt( index, Prop_Send, "m_hBuilder" );
			if( p_iBotAttrib[iBuilder] & BotAttrib_CannotBuildTele )
			{
				SetVariantInt(9999);
				AcceptEntityInput(index, "RemoveHealth");
				PrintCenterText(iBuilder, "YOU CANNOT BUILD TELEPORTERS");
			}
			else if( TF2_GetObjectMode(index) == TFObjectMode_Entrance )
			{
				SetVariantInt(9999);
				AcceptEntityInput(index, "RemoveHealth");
			}
			else
			{
				if( CheckTeleportClamping(index) )
				{
					PrintCenterText(iBuilder, "NOT ENOUGH SPACE TO BUILD A TELEPORTER");
					SetVariantInt(9999);
					AcceptEntityInput(index, "RemoveHealth");
				}
				else
				{
					DispatchKeyValue(index, "defaultupgrade", "2");
					SetEntProp(index, Prop_Data, "m_iMaxHealth", 300);
					SetVariantInt(300);
					AcceptEntityInput(index, "SetHealth");
					CreateTimer(0.2, Timer_OnTeleporterFinished, index, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
				}
			}
		}
	}
	
	return Plugin_Stop;
}

public Action Timer_OnTeleporterFinished(Handle timer, any index)
{
	if( !IsValidEntity(index) )
		return Plugin_Stop;
		
	if( !HasEntProp(index, Prop_Send, "m_flPercentageConstructed") )
		return Plugin_Stop;
		
	float flProgress = GetEntPropFloat(index, Prop_Send, "m_flPercentageConstructed");
	
	if( flProgress >= 1.0 )
	{
		SetEntProp(index, Prop_Data, "m_iMaxHealth", 300);
		SetVariantInt(300);
		AcceptEntityInput(index, "SetHealth");
		EmitGSToRed("Announcer.MVM_Engineer_Teleporter_Activated");
		AddParticleToTeleporter(index);
		HookSingleEntityOutput(index, "OnDestroyed", OnDestroyedTeleporter, true);
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

public Action Timer_RemoveSpawnedBool(Handle timer, any client)
{
	if( p_bSpawned[client] )
		p_bSpawned[client] = false;
	
	return Plugin_Stop;
}

public Action Timer_DeployBomb(Handle timer, any client)
{
	if( !IsValidClient(client) || !IsClientInGame(client) || !IsPlayerAlive(client) || IsFakeClient(client) )
	{
		//CloseHandle(HT_BombDeployTimer);
		HT_BombDeployTimer = INVALID_HANDLE;
		return Plugin_Stop;
	}
		
	if( IsFakeClient(client) )
	{
		LogError("Timer_DeployBomb called for Fake Client.");
		//CloseHandle(HT_BombDeployTimer);
		HT_BombDeployTimer = INVALID_HANDLE;
		return Plugin_Stop;
	}
	
	if( !( GetEntityFlags(client) & FL_ONGROUND ) )
	{
		//CloseHandle(HT_BombDeployTimer);
		HT_BombDeployTimer = INVALID_HANDLE;
		return Plugin_Stop;
	}
	
	char strPlrName[MAX_NAME_LENGTH];
	GetClientName(client, strPlrName, sizeof(strPlrName));
	CPrintToChatAll("%t", "Bomb Deploy", strPlrName);
	LogAction(client, -1, "Player \"%L\" deployed the bomb.", client);
	TriggerHatchExplosion();
	
	//CloseHandle(HT_BombDeployTimer);
	HT_BombDeployTimer = INVALID_HANDLE;
	return Plugin_Stop;
}

public Action Timer_Announce(Handle timer)
{
	CPrintToChatAll("{cyan}Be With Robots Redux By {green}Anonymous Player{cyan}.");
	CPrintToChatAll("{cyan}https://github.com/caxanga334/tf-bewithrobots-redux");
}

public Action Timer_SentryBuster_Explode(Handle timer, any client)
{
	if( !IsValidClient(client) || !IsPlayerAlive(client) || p_iBotType[client] != Bot_Buster || IsFakeClient(client) )
		return Plugin_Stop;
	
	float flExplosionPos[3];
	GetClientAbsOrigin( client, flExplosionPos );
	int iWeapon = GetFirstAvailableWeapon(client);
	
	if( GameRules_GetRoundState() == RoundState_RoundRunning )
	{
		int i;
		for( i = 1; i <= MaxClients; i++ )
			if( i != client && IsValidClient(i) && IsPlayerAlive(i) )
				if( CanSeeTarget( client, i, 320.0 ) )
					DealDamage(i, client, client, 10000.0, DMG_BLAST, iWeapon);
		
		char strObjects[5][] = { "obj_sentrygun","obj_dispenser","obj_teleporter","obj_teleporter_entrance","obj_teleporter_exit" };
		for( int o = 0; o < sizeof(strObjects); o++ )
		{
			i = -1;
			while( ( i = FindEntityByClassname( i, strObjects[o] ) ) != -1 )
				if( GetEntProp( i, Prop_Send, "m_iTeamNum" ) != view_as<int>(TFTeam_Blue) && !GetEntProp( i, Prop_Send, "m_bCarried" ) && !GetEntProp( i, Prop_Send, "m_bPlacing" ) )
					if( CanSeeTarget( client, i, 320.0 ) )
						DealDamage(i, client, client, 10000.0, DMG_BLAST, iWeapon);
		}
	}
	
	CreateParticle( flExplosionPos, "fluidSmokeExpl_ring_mvm", 6.5 );
	CreateParticle( flExplosionPos, "explosionTrail_seeds_mvm", 5.5 );	//fluidSmokeExpl_ring_mvm  explosionTrail_seeds_mvm
	
	ForcePlayerSuicide( client );
	EmitGameSoundToAll("MVM.SentryBusterExplode", client, SND_NOFLAGS, client, flExplosionPos);
	
	return Plugin_Stop;
}

public Action Timer_DeleteParticle(Handle timer, any iEntRef)
{
	int iParticle = EntRefToEntIndex( iEntRef );
	if( IsValidEntity(iParticle) )
	{
		char strClassname[64];
		GetEdictClassname( iParticle, strClassname, sizeof(strClassname) );
		if( StrEqual( strClassname, "info_particle_system", false ) )
			AcceptEntityInput( iParticle, "Kill" );
	}
}

public Action Timer_RemoveBody(Handle timer, any client)
{
	if( IsFakeClient(client) )
		return Plugin_Stop;

	//Declare:
	int BodyRagdoll;

	//Initialize:
	BodyRagdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");

	//Remove:
	if(IsValidEdict(BodyRagdoll)) 
		RemoveEdict(BodyRagdoll);
		
	return Plugin_Stop;
}

public Action Timer_RemoveGibs(Handle timer, any entity)
{

	//Validate:
	if(IsValidEntity(entity))
	{

		//Declare:
		char Classname[64];

		//Initialize:
		GetEdictClassname(entity, Classname, sizeof(Classname));

		//Is a Particle:
		if(StrEqual(Classname, "tf_ragdoll", false))
		{

			//Delete:
			RemoveEdict(entity);
		}
	}
}

public Action Timer_ApplyRobotSound(Handle timer, any client)
{
	if( !IsValidClient(client) || IsFakeClient(client) )
		return Plugin_Stop;

	TFClassType TFClass = TF2_GetPlayerClass(client);
	switch( TFClass )
	{
		case TFClass_Scout: EmitSoundToAll(ROBOT_SND_GIANT_SCOUT, client, SNDCHAN_STATIC, 85);
		case TFClass_Soldier: EmitSoundToAll(ROBOT_SND_GIANT_SOLDIER, client, SNDCHAN_STATIC, 82);
		case TFClass_Pyro: EmitSoundToAll(ROBOT_SND_GIANT_PYRO, client, SNDCHAN_STATIC, 83);
		case TFClass_DemoMan:
		{
			if( p_iBotType[client] == Bot_Buster )
				EmitSoundToAll(ROBOT_SND_SENTRY_BUSTER, client, SNDCHAN_STATIC, SNDLEVEL_TRAIN);
			else
				EmitSoundToAll(ROBOT_SND_GIANT_DEMOMAN, client, SNDCHAN_STATIC, 82);
		}
		case TFClass_Heavy: EmitSoundToAll(ROBOT_SND_GIANT_HEAVY, client, SNDCHAN_STATIC, 83);
	}
	
	return Plugin_Stop;
}

/****************************************************
					FUNCTIONS
*****************************************************/

// ***PLAYER***

// moves player to RED
void MovePlayerToRED(int client)
{
	StopRobotLoopSound(client);
	ScalePlayerModel(client, 1.0);
	ResetRobotData(client, true);
	SetVariantString( "" );
	AcceptEntityInput( client, "SetCustomModel" );
	LogMessage("Player \"%L\" joined RED team.", client);
	ChangeClientTeam(client, view_as<int>(TFTeam_Red));
	SetEntProp(client, Prop_Send, "m_iTeamNum", view_as<int>(TFTeam_Red));
	SetEntProp( client, Prop_Send, "m_bIsABot", view_as<int>(false) );
	SetEntProp( client, Prop_Send, "m_bIsMiniBoss", view_as<int>(false) );
	
	if( TF2_GetPlayerClass(client) == TFClass_Unknown )
		ShowVGUIPanel(client, "class_red");
}

// moves players to spectator
void MovePlayerToSpec(int client)
{
	StopRobotLoopSound(client);
	ScalePlayerModel(client, 1.0);
	ResetRobotData(client, true);
	SetVariantString( "" );
	AcceptEntityInput( client, "SetCustomModel" );
	if( !IsFakeClient(client) )
	{
		SetEntProp( client, Prop_Send, "m_nBotSkill", BotSkill_Easy );
		SetEntProp( client, Prop_Send, "m_bIsMiniBoss", view_as<int>(false) );
		SetEntProp( client, Prop_Send, "m_bIsABot", view_as<int>(false) );
	}
	LogMessage("Player \"%L\" joined SPECTATOR team.", client);
	TF2_ChangeClientTeam(client, TFTeam_Spectator);
}

// moves player to BLU team.
void MovePlayerToBLU(int client)
{
	SetEntData(client, g_iOffsetMissionBot, 	1, _, true);	//Makes player death not decrement wave bot count
	SetEntData(client, g_iOffsetSupportLimited, 0, _, true);	//Makes player death not decrement wave bot count
	StopRobotLoopSound(client);
	ForcePlayerSuicide(client);
	if( !IsFakeClient(client) )
	{
		SetEntProp( client, Prop_Send, "m_nBotSkill", BotSkill_Easy );
		SetEntProp( client, Prop_Send, "m_bIsMiniBoss", view_as<int>(false) );
		SetEntProp( client, Prop_Send, "m_bIsABot", view_as<int>(true) );
	}
	
	int iEntFlags = GetEntityFlags( client );
	SetEntityFlags( client, iEntFlags | FL_FAKECLIENT );
	TF2_ChangeClientTeam(client, TFTeam_Blue);
	SetEntityFlags( client, iEntFlags );
	LogMessage("Player \"%L\" joined BLU team.", client);
	
	ScalePlayerModel(client, 1.0);
	PickRandomRobot(client);
}

// special funcstions that moves players to spectator without data reset
void RemovePlayerFromBLU(int client)
{
	StopRobotLoopSound(client);
	ScalePlayerModel(client, 1.0);
	SetVariantString( "" );
	AcceptEntityInput( client, "SetCustomModel" );
	if( !IsFakeClient(client) )
	{
		SetEntProp( client, Prop_Send, "m_nBotSkill", BotSkill_Easy );
		SetEntProp( client, Prop_Send, "m_bIsMiniBoss", view_as<int>(false) );
		SetEntProp( client, Prop_Send, "m_bIsABot", view_as<int>(false) );
	}
	TF2_ChangeClientTeam(client, TFTeam_Spectator);
}

// returns the number of human players on BLU/ROBOT team
int GetHumanRobotCount()
{
	int count = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i))
		{			
			if(p_iBotTeam[i] == TFTeam_Blue)
			{
				count++;
			}
		}
	}
	return count;
}

bool IsSmallMap()
{
	return c_bSmallMap.BoolValue;
}

// updates array_avclass
// uses the data from tf_objective_resource to determine which classes should be available.
// use the function OR_Update to read the tf_objective_resource's data.
void UpdateClassArray()
{
	int iAvailable = OR_GetAvailableClasses();
	
	array_avclass.Clear();
	
	if(iAvailable & 1) // scout
	{
		array_avclass.Push(1); // this number is the same as TFClassType enum
	}
	if(iAvailable & 2) // soldier
	{
		array_avclass.Push(3);
	}
	if(iAvailable & 4) // pyro
	{
		array_avclass.Push(7);
	}
	if(iAvailable & 8) // demoman
	{
		array_avclass.Push(4);
	}
	if(iAvailable & 16) // heavy
	{
		array_avclass.Push(6);
	}
	if(iAvailable & 32) // engineer
	{
		array_avclass.Push(9);
	}
	if(iAvailable & 64) // medic
	{
		array_avclass.Push(5);
	}
	if(iAvailable & 128) // sniper
	{
		array_avclass.Push(2);
	}
	if(iAvailable & 256) // spy
	{
		array_avclass.Push(8);
	}
}

// returns true if the specified class is available for the current wave
bool IsClassAvailable(TFClassType TFClass)
{
	if( array_avclass.Length < 1 )
		return false;
		
	int iClass = view_as<int>(TFClass);
	
	if( array_avclass.FindValue(iClass) != -1 )
		return true;

	return false;	
}

// ***ROBOT VARIANT***
void PickRandomRobot(int client)
{
	if(!IsClientInGame(client) || IsFakeClient(client))
		return;
	
	int iAvailable = OR_GetAvailableClasses();
	int iSize = GetArraySize(array_avclass) - 1;
	int iRandom = GetRandomInt(0, iSize);
	int iClass = array_avclass.Get(iRandom);
	bool bGiants = false;
	
	// sentry buster
	if(iAvailable & 512 && GameRules_GetRoundState() == RoundState_RoundRunning)
	{
		if( GetGameTime() > g_flNextBusterTime && ShouldDispatchSentryBuster() )
		{
			p_BotClass[client] = TFClass_DemoMan;
			p_iBotVariant[client] = 0;
			p_iBotType[client] = Bot_Buster;
			p_iBotAttrib[client] = BotAttrib_CannotCarryBomb;
			g_flNextBusterTime = GetGameTime() + c_flBusterDelay.FloatValue;
			CreateTimer(0.1, Timer_SetRobotClass, client);
			return;
		}
	}
	if(iAvailable & 1024)
	{
		bGiants = true;
	}	
	
	// select a random robot variant
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
	if( IsFakeClient(client) )
		return;

	//TF2_SetPlayerClass(client, TFClass);
	CreateTimer(0.1, Timer_SetRobotClass, client);
	if( GetRandomInt(0, 100) <= c_iGiantChance.IntValue && bGiants && GetTeamClientCount(2) >= c_iGiantMinRed.IntValue )
	{
		// giant
		p_iBotType[client] = Bot_Giant;
		switch( TFClass )
		{
			case TFClass_Scout:
			{
				p_iBotVariant[client] = GetRandomInt(-1, MAX_SCOUT_GIANT);
				p_BotClass[client] = TFClass_Scout;
			}
			case TFClass_Soldier:
			{
				p_iBotVariant[client] = GetRandomInt(-1, MAX_SOLDIER_GIANT);
				p_BotClass[client] = TFClass_Soldier;
			}
			case TFClass_Pyro:
			{
				p_iBotVariant[client] = GetRandomInt(-1, MAX_PYRO_GIANT);
				p_BotClass[client] = TFClass_Pyro;
			}
			case TFClass_DemoMan:
			{
				p_iBotVariant[client] = GetRandomInt(-1, MAX_DEMO_GIANT);
				p_BotClass[client] = TFClass_DemoMan;
			}
			case TFClass_Heavy:
			{
				p_iBotVariant[client] = GetRandomInt(-1, MAX_HEAVY_GIANT);
				p_BotClass[client] = TFClass_Heavy;
			}
			case TFClass_Engineer:
			{
				p_iBotVariant[client] = GetRandomInt(-1, MAX_ENGINEER_GIANT);
				p_BotClass[client] = TFClass_Engineer;
			}
			case TFClass_Medic:
			{
				p_iBotVariant[client] = GetRandomInt(-1, MAX_MEDIC_GIANT);
				p_BotClass[client] = TFClass_Medic;
			}
			case TFClass_Sniper:
			{
				p_iBotVariant[client] = GetRandomInt(-1, MAX_SNIPER_GIANT);
				p_BotClass[client] = TFClass_Sniper;
			}
			case TFClass_Spy:
			{
				p_iBotVariant[client] = GetRandomInt(-1, MAX_SPY_GIANT);
				p_BotClass[client] = TFClass_Spy;
			}
		}
		SetGiantVariantExtras(client, TFClass, p_iBotVariant[client]);
	}
	else
	{
		// normal
		p_iBotType[client] = Bot_Normal;
		switch( TFClass )
		{
			case TFClass_Scout:
			{
				p_iBotVariant[client] = GetRandomInt(-1, MAX_SCOUT);
				p_BotClass[client] = TFClass_Scout;
			}
			case TFClass_Soldier:
			{
				p_iBotVariant[client] = GetRandomInt(-1, MAX_SOLDIER);
				p_BotClass[client] = TFClass_Soldier;
			}
			case TFClass_Pyro:
			{
				p_iBotVariant[client] = GetRandomInt(-1, MAX_PYRO);
				p_BotClass[client] = TFClass_Pyro;
			}
			case TFClass_DemoMan:
			{
				p_iBotVariant[client] = GetRandomInt(-1, MAX_DEMO);
				p_BotClass[client] = TFClass_DemoMan;
			}
			case TFClass_Heavy:
			{
				p_iBotVariant[client] = GetRandomInt(-1, MAX_HEAVY);
				p_BotClass[client] = TFClass_Heavy;
			}
			case TFClass_Engineer:
			{
				p_iBotVariant[client] = GetRandomInt(-1, MAX_ENGINEER);
				p_BotClass[client] = TFClass_Engineer;
			}
			case TFClass_Medic:
			{
				p_iBotVariant[client] = GetRandomInt(-1, MAX_MEDIC);
				p_BotClass[client] = TFClass_Medic;
			}
			case TFClass_Sniper:
			{
				p_iBotVariant[client] = GetRandomInt(-1, MAX_SNIPER);
				p_BotClass[client] = TFClass_Sniper;
			}
			case TFClass_Spy:
			{
				p_iBotVariant[client] = GetRandomInt(-1, MAX_SPY);
				p_BotClass[client] = TFClass_Spy;
			}
		}
		SetVariantExtras(client, TFClass, p_iBotVariant[client]);
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
	bool bValid = false;
	switch( TFClass )
	{
		case TFClass_Scout:
		{
			if( bGiants )
			{
				if( iVariant >= -1 && iVariant <= MAX_SCOUT_GIANT )
					bValid = true;
			}
			else
			{
				if( iVariant >= -1 && iVariant <=  MAX_SCOUT )
					bValid = true;
			}
		}
		case TFClass_Soldier:
		{
			if( bGiants )
			{
				if( iVariant >= -1 && iVariant <= MAX_SOLDIER_GIANT )
					bValid = true;
			}
			else
			{
				if( iVariant >= -1 && iVariant <= MAX_SOLDIER )
					bValid = true;
			}
		}
		case TFClass_Pyro:
		{
			if( bGiants )
			{
				if( iVariant >= -1 && iVariant <= MAX_PYRO_GIANT )
					bValid = true;
			}
			else
			{
				if( iVariant >= -1 && iVariant <= MAX_PYRO )
					bValid = true;
			}
		}
		case TFClass_DemoMan:
		{
			if( bGiants )
			{
				if( iVariant >= -1 && iVariant <= MAX_DEMO_GIANT )
					bValid = true;
			}
			else
			{
				if( iVariant >= -1 && iVariant <= MAX_DEMO )
					bValid = true;
			}
		}
		case TFClass_Heavy:
		{
			if( bGiants )
			{
				if( iVariant >= -1 && iVariant <= MAX_HEAVY_GIANT )
					bValid = true;
			}
			else
			{
				if( iVariant >= -1 && iVariant <= MAX_HEAVY )
					bValid = true;
			}
		}
		case TFClass_Engineer:
		{
			if( bGiants )
			{
				if( iVariant >= -1 && iVariant <= MAX_ENGINEER_GIANT )
					bValid = true;
			}
			else
			{
				if( iVariant >= -1 && iVariant <= MAX_ENGINEER )
					bValid = true;
			}
		}
		case TFClass_Medic:
		{
			if( bGiants )
			{
				if( iVariant >= -1 && iVariant <= MAX_MEDIC_GIANT )
					bValid = true;
			}
			else
			{
				if( iVariant >= -1 && iVariant <= MAX_MEDIC )
					bValid = true;
			}
		}
		case TFClass_Sniper:
		{
			if( bGiants )
			{
				if( iVariant >= -1 && iVariant <= MAX_SNIPER_GIANT )
					bValid = true;
			}
			else
			{
				if( iVariant >= -1 && iVariant <= MAX_SNIPER )
					bValid = true;
			}
		}
		case TFClass_Spy:
		{
			if( bGiants )
			{
				if( iVariant >= -1 && iVariant <= MAX_SPY_GIANT )
					bValid = true;
			}
			else
			{
				if( iVariant >= -1 && iVariant <= MAX_SPY )
					bValid = true;
			}
		}
	}
	
	return bValid;
}

// set effects and bot mode for variants
void SetVariantExtras(int client,TFClassType TFClass, int iVariant)
{
	p_iBotAttrib[client] = 0; //reset
	
	switch( TFClass )
	{
		case TFClass_Scout:
		{
			switch( iVariant )
			{
				case 6: p_iBotType[client] = Bot_Big;
			}			
		}
		case TFClass_Soldier:
		{
			switch( iVariant )
			{
				case -1: p_iBotAttrib[client] += BotAttrib_FullCharge;
				case 2: p_iBotAttrib[client] += BotAttrib_FullCharge;
				case 3: p_iBotAttrib[client] += BotAttrib_FullCharge;
				case 4: p_iBotAttrib[client] += BotAttrib_FullCharge;
			}
		}
/* 		case TFClass_Pyro:
		{
			
		} */
		case TFClass_DemoMan:
		{
			switch( iVariant )
			{
				case 3: p_iBotType[client] = Bot_Big;
			}			
		}
/* 		case TFClass_Heavy:
		{
			
		} */
		case TFClass_Engineer:
		{
			p_iBotAttrib[client] += BotAttrib_CannotCarryBomb; // global
			switch( iVariant )
			{
				case -1: p_iBotAttrib[client] += BotAttrib_TeleportToHint;
				case 1: p_iBotAttrib[client] += BotAttrib_TeleportToHint;
				case 2: p_iBotAttrib[client] += (BotAttrib_TeleportToHint + BotAttrib_CannotBuildTele);
				case 3: p_iBotAttrib[client] += BotAttrib_CannotBuildTele;
			}			
		}
		case TFClass_Medic:
		{
			p_iBotAttrib[client] += (BotAttrib_FullCharge + BotAttrib_CannotCarryBomb);
		}
		case TFClass_Sniper:
		{
			switch( iVariant )
			{
				case -1: p_iBotAttrib[client] += BotAttrib_CannotCarryBomb;
				case 0: p_iBotAttrib[client] += BotAttrib_CannotCarryBomb;
			}
		}
		case TFClass_Spy:
		{
			p_iBotAttrib[client] += (BotAttrib_AutoDisguise + BotAttrib_CannotCarryBomb); // global to all spies
			switch( iVariant )
			{
				case 0: p_iBotAttrib[client] += BotAttrib_InfiniteCloak;
			}
		}
	}
}

void SetGiantVariantExtras(int client,TFClassType TFClass, int iVariant)
{
	p_iBotAttrib[client] = 0; //reset
	
	switch( TFClass )
	{
/* 		case TFClass_Scout:
		{
			
		} */
		case TFClass_Soldier:
		{
			switch( iVariant )
			{
				case -1: p_iBotAttrib[client] += BotAttrib_FullCharge;
				case 1: p_iBotAttrib[client] += BotAttrib_AlwaysCrits;
			}			
		}
/* 		case TFClass_Pyro:
		{
			
		} */
/* 		case TFClass_DemoMan:
		{
			
		} */
/* 		case TFClass_Heavy:
		{
			
		} */
		case TFClass_Engineer:
		{
			p_iBotAttrib[client] += BotAttrib_CannotCarryBomb;
		}
		case TFClass_Medic:
		{
			p_iBotAttrib[client] += (BotAttrib_FullCharge + BotAttrib_CannotCarryBomb);
		}
		case TFClass_Sniper:
		{
			p_iBotAttrib[client] += BotAttrib_CannotCarryBomb;
		}
		case TFClass_Spy:
		{
			p_iBotAttrib[client] += (BotAttrib_AutoDisguise + BotAttrib_CannotCarryBomb); // global to all spies
		}
	}
}

// sets the player scale based on robot type
void SetRobotScale(int client, TFClassType TFClass)
{
	if( IsFakeClient(client) )
		return;

	bool bSmallMap = IsSmallMap();
	
	if( bSmallMap )
	{
		if( p_iBotType[client] == Bot_Giant || p_iBotType[client] == Bot_Boss || p_iBotType[client] == Bot_Buster )
		{
			ScalePlayerModel(client, 1.20);
		}
		else if( p_iBotType[client] == Bot_Big )
		{
			ScalePlayerModel(client, 1.10);
		}
		else if( p_iBotType[client] == Bot_Small )
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
		if( p_iBotType[client] == Bot_Giant || p_iBotType[client] == Bot_Buster )
		{
			ScalePlayerModel(client, 1.75);
		}
		else if( p_iBotType[client] == Bot_Boss )
		{
			ScalePlayerModel(client, 1.90);
		}
		else if( p_iBotType[client] == Bot_Big )
		{
			switch( TFClass )
			{
				case TFClass_Scout: ScalePlayerModel(client, 1.4);
				case TFClass_Heavy: ScalePlayerModel(client, 1.5);
				case TFClass_DemoMan: ScalePlayerModel(client, 1.3);
				default: ScalePlayerModel(client, 1.4);
			}
		}
		else if( p_iBotType[client] == Bot_Small )
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
	if( IsFakeClient(client) )
		return;

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

void ResetRobotData(int client, bool bStrip = false)
{
	if( IsFakeClient(client) )
		return;

	p_iBotType[client] = Bot_Normal;
	p_iBotVariant[client] = 0;
	p_iBotAttrib[client] = 0;
	p_BotClass[client] = TFClass_Unknown;
	g_bIsCarrier[client] = false;
	g_bUpgradeStation[client] = false;
	p_bSpawned[client] = false;
	if( bStrip )
		StripWeapons(client);
}

// sets robot model
void SetRobotModel(int client, TFClassType TFClass)
{
	if( IsFakeClient(client) )
		return;

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
		if( p_iBotType[client] == Bot_Giant || p_iBotType[client] == Bot_Boss )
		{
			if( TFClass == TFClass_DemoMan || TFClass == TFClass_Heavy || TFClass == TFClass_Pyro || TFClass == TFClass_Scout || TFClass == TFClass_Soldier )
				Format( strModel, sizeof( strModel ), "models/bots/%s_boss/bot_%s_boss.mdl", strModel, strModel );
			else
				Format( strModel, sizeof( strModel ), "models/bots/%s/bot_%s.mdl", strModel, strModel );
		}
		else if( p_iBotType[client] == Bot_Buster )
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
	if( IsFakeClient(client) )
		return;

	int iSpawn;
	float vecOrigin[3];
	float vecAngles[3];
	
	if( p_iBotType[client] == Bot_Giant || p_iBotType[client] == Bot_Big )
	{
		iSpawn = FindRandomSpawnPoint( Spawn_Giant );
	}
	else if( p_iBotType[client] == Bot_Buster )
	{
		iSpawn = FindRandomSpawnPoint( Spawn_Buster );		
	}
	else if( p_iBotType[client] == Bot_Boss )
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
				else if( StrEqual( strSpawnName, "spawnbot_bwr" ) ) // custom spawn point
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
				else if( StrEqual( strSpawnName, "spawnbot_flank" ) )
				{
					array_spawns.Push( iEnt );
				}
				else if( StrEqual( strSpawnName, "spawnbot_side" ) )
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

// searches for red sentry guns
// also checks for kill num
bool ShouldDispatchSentryBuster()
{
	int i = -1;
	int iKills;
	while ((i = FindEntityByClassname(i, "obj_sentrygun")) != -1)
	{
		if( IsValidEntity(i) )
		{
			if( GetEntProp( i, Prop_Send, "m_iTeamNum" ) == view_as<int>(TFTeam_Red) )
			{
				iKills = GetEntProp(i, Prop_Send, "SentrygunLocalData", _, 0);
				if( iKills >= c_iBusterMinKills.IntValue ) // found threat
					return true;
			}
		}
	}
	
	return false;
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
			iTarget = GetRandomBLUPlayer();
			if( iTarget > 0 )
			{
				p_iBotTeam[iTarget] = TFTeam_Red;
				MovePlayerToRED(iTarget);
				CPrintToChat(iTarget, "%t", "Moved Blu Full");
			}
		}
	}
	if( bAutoBalance )
	{
		// if the number of players in RED is less than the minimum to join BLU
		if( iInRed < c_iMinRed.IntValue && iInBlu > 0 )
		{
			int iCount = c_iMinRed.IntValue - (iInRed + 1);
			if( iCount < c_iMinRed.IntValue )
				LogMessage("Auto Balancing teams. Count: %i, In RED: %i", iCount, iInRed);
			
			for( int i = 1; i <= iCount; i++ )
			{
				iTarget = GetRandomBLUPlayer();
				if( iTarget > 0 )
				{
					p_iBotTeam[iTarget] = TFTeam_Red;
					MovePlayerToRED(iTarget);
					CPrintToChat(iTarget, "%t", "Moved Blu Balance");
				}
			}
		}
	}
}

// applies giant robot loop sounds to clients
void StopRobotLoopSound(int client)
{
	if( IsFakeClient(client) )
		return;

	StopSound(client, SNDCHAN_STATIC, ROBOT_SND_GIANT_SCOUT);
	StopSound(client, SNDCHAN_STATIC, ROBOT_SND_GIANT_SOLDIER);
	StopSound(client, SNDCHAN_STATIC, ROBOT_SND_GIANT_PYRO);
	StopSound(client, SNDCHAN_STATIC, ROBOT_SND_GIANT_DEMOMAN);
	StopSound(client, SNDCHAN_STATIC, ROBOT_SND_SENTRY_BUSTER);
	StopSound(client, SNDCHAN_STATIC, ROBOT_SND_GIANT_HEAVY);
}

void ApplyRobotLoopSound(int client)
{
	if( IsFakeClient(client) )
		return;

	StopRobotLoopSound(client);
	CreateTimer(0.2, Timer_ApplyRobotSound, client, TIMER_FLAG_NO_MAPCHANGE);
}

// wave spawn manager

void CreateWaveTimer()
{
	if( HT_HumanRobotWaveSpawn != INVALID_HANDLE )	
	{
		KillTimer(HT_HumanRobotWaveSpawn);
		HT_HumanRobotWaveSpawn = INVALID_HANDLE;
	}
	HT_HumanRobotWaveSpawn = CreateTimer(c_flBluRespawnTime.FloatValue, Timer_WaveSpawnBluHuman, _, TIMER_REPEAT);
}

void DeleteWaveTimer()
{	
	if( HT_HumanRobotWaveSpawn != INVALID_HANDLE )	
	{
		KillTimer(HT_HumanRobotWaveSpawn);
		HT_HumanRobotWaveSpawn = INVALID_HANDLE;
	}	
}

// end wave spawn manager

// selects a random player from the BLU queue
int GetRandomBLUPlayer()
{
	int players_available[MAXPLAYERS+1];
	int counter = 0; // counts how many valid players we have
	for (int i = 1; i <= MaxClients; i++)
	{
		if( IsValidClient(i) && !IsFakeClient(i) )
		{
			if( p_iBotTeam[i] == TFTeam_Blue )
			{
				players_available[counter] = i; // stores the client userid
				counter++;				
			}
		}
	}
	
	// now we should have an array filled with user ids and exactly how many players we have in game.
	int iRandomMax = counter - 1;
	int iRandom = GetRandomInt(0,iRandomMax); // get a random number between 0 and counted players
	// now we get the user id from the array cell selected via iRandom
	return players_available[iRandom];
}