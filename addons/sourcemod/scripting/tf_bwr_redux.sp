#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <autoexecconfig>
#include <multicolors>
#define REQUIRE_PLUGIN
#include <tf2attributes>
#include <tf2wearables>
#undef REQUIRE_EXTENSIONS
#include <SteamWorks>
#define REQUIRE_EXTENSIONS
#define AUTOLOAD_EXTENSIONS
#include <sdkhooks>
#include <tf2items>
#include <dhooks>

#pragma semicolon 1

#define PLUGIN_VERSION "0.1.12"

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
bool p_bInSpawn[MAXPLAYERS + 1]; // Local cache to know if a player is in spawn

// bomb
bool g_bIsCarrier[MAXPLAYERS + 1]; // true if the player is carrying the bomb
int g_iBombCarrierUpgradeLevel[MAXPLAYERS + 1];
float g_flNextBombUpgradeTime[MAXPLAYERS + 1];
Handle HT_BombDeployTimer;

ArrayList array_avclass; // array containing available classes
ArrayList array_avgiants; // array containing available giant classes
ArrayList array_spawns; // spawn points for human players

// others
bool g_bUpgradeStation[MAXPLAYERS + 1];
float g_flNextBusterTime;
float g_flLastForceBot[MAXPLAYERS + 1]; // Last time a player forced a bot
bool g_bBotMenuIsGiant[MAXPLAYERS + 1];
TFClassType g_BotMenuSelectedClass[MAXPLAYERS + 1];
bool g_bWelcomeMsg[MAXPLAYERS + 1]; // Did we show the welcome message?
int g_iBusterIndex; // Index of a sentry buster player
float g_flBusterVisionTimer; // timer for buster wallhack

int g_iLaserSprite;
int g_iHaloSprite;

// convars
ConVar c_iMinRed; // minimum red players to join BLU
ConVar c_iMinRedinProg; // minimum red players to join BLU while the wave is in progress.
ConVar c_iGiantChance; // change to spawn as a giant robot
ConVar c_iGiantMinRed; // minimum red players to allow giants.
ConVar c_iMaxBlu; // maximum blu players allowed
ConVar c_flBluRespawnTime; // blu players respawn time
ConVar c_bAutoTeamBalance;
ConVar c_bSmallMap; // change robot scale to avoid getting stuck in maps such as mvm_2fort
ConVar c_flBusterDelay; // delay between human sentry buster spawns.
ConVar c_iBusterMinKills; // minimum amount of kills a sentry needs to have before becoming a threat
ConVar c_svTag; // server tags
ConVar c_bDebug; // Enable debug mode
ConVar c_flForceDelay; // Delay between force bot command usage
ConVar c_flFDGiant; // Extra delay added when the forced bot is a giant
ConVar c_strNBFile; // Normal bot template file
ConVar c_strGBFile; // Giant bot template file
ConVar c_bLimitClasses; // Limit playable classes to the ones used in the current wave

// user messages
UserMsg ID_MVMResetUpgrade = INVALID_MESSAGE_ID;

// SDK
Handle g_hSDKPlaySpecificSequence;
Handle g_hSDKDispatchParticleEffect;
Handle g_hGetEventChangeAttributes;
Handle g_hSDKWorldSpaceCenter;
Handle g_hCFilterTFBotHasTag;

enum ParticleAttachment
{
	PATTACH_ABSORIGIN = 0,			// Create at absorigin, but don't follow
	PATTACH_ABSORIGIN_FOLLOW,		// Create at absorigin, and update to follow the entity
	PATTACH_CUSTOMORIGIN,			// Create at a custom origin, but don't follow
	PATTACH_POINT,					// Create on attachment point, but don't follow
	PATTACH_POINT_FOLLOW,			// Create on attachment point, and update to follow the entity
	PATTACH_WORLDORIGIN,			// Used for control points that don't attach to an entity
	PATTACH_ROOTBONE_FOLLOW,		// Create at the root bone of the entity, and update to follow
	MAX_PATTACH_TYPES,
};

enum SpawnType
{
	Spawn_Normal = 0,
	Spawn_Giant = 1,
	Spawn_Sniper = 2,
	Spawn_Spy = 3,
	Spawn_Buster = 4,
	Spawn_Boss = 5
};

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
	BotAttrib_AlwaysCrits = 1, // 100% crit chance
	BotAttrib_FullCharge = 2, // spawns with full charge (medic, soldier buff)
	BotAttrib_InfiniteCloak = 4, // Spies never run out of cloak
	BotAttrib_AutoDisguise = 8, // Automatically give a disguise to the spy
	BotAttrib_AlwaysMiniCrits = 16, // 100% minicrit chance
	BotAttrib_TeleportToHint = 32, // teleport engineers to a nest near the bomb.
	BotAttrib_CannotCarryBomb = 64, // Blocks players from carrying the bomb
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
	property int BombLevel
	{
		public get() { return g_iBombCarrierUpgradeLevel[this.index]; }
		public set( int value ) { g_iBombCarrierUpgradeLevel[this.index] = value; }
	}
	property float UpgradeTime
	{
		public get() { return g_flNextBombUpgradeTime[this.index]; }
		public set( float value ) { g_flNextBombUpgradeTime[this.index] = value; }
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
	property bool InSpawn
	{
		public get() { return p_bInSpawn[this.index]; }
		public set( bool value ) { p_bInSpawn[this.index] = value; }
	}
	public void MiniBoss(bool value)
	{
		SetEntProp( this.index, Prop_Send, "m_bIsMiniBoss", view_as<int>(value) );
	}
	public void BotSkill(int value)
	{
		SetEntProp( this.index, Prop_Send, "m_nBotSkill", value );
	}
}

#include "bwrredux/bot_variants.sp"
#include "bwrredux/objectiveres.sp"
#include "bwrredux/functions.sp"
#include "bwrredux/boss.sp"
 
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
	EngineVersion ev = GetEngineVersion();
	
	if( ev == Engine_TF2 )
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
	// Sets the file for the include, must be done before using most other functions
	// The .cfg file extension can be left off
	AutoExecConfig_SetFile("plugin.bwrredux");

	// convars
	CreateConVar("sm_bwrr_version", PLUGIN_VERSION, "Be With Robots: Redux plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	c_iMinRed = AutoExecConfig_CreateConVar("sm_bwrr_minred", "5", "Minimum amount of players on RED team to allow joining ROBOTs.", FCVAR_NONE, true, 0.0, true, 10.0);
	c_iMinRedinProg = AutoExecConfig_CreateConVar("sm_bwrr_minred_inprog", "7", "Minimum amount of players on RED team to allow joining ROBOTs while the wave is in progress.", FCVAR_NONE, true, 0.0, true, 10.0);
	c_iGiantChance = AutoExecConfig_CreateConVar("sm_bwrr_giantchance", "30", "Chance in percentage to human players to spawn as a giant. 0 = Disabled.", FCVAR_NONE, true, 0.0, true, 100.0);
	c_iGiantMinRed = AutoExecConfig_CreateConVar("sm_bwrr_giantminred", "5", "Minimum amount of players on RED team to allow human giants. 0 = Disabled.", FCVAR_NONE, true, 0.0, true, 8.0);
	c_iMaxBlu = AutoExecConfig_CreateConVar("sm_bwrr_maxblu", "4", "Maximum amount of players in BLU team.", FCVAR_NONE, true, 1.0, true, 5.0);
	c_bAutoTeamBalance = AutoExecConfig_CreateConVar("sm_bwrr_autoteambalance", "1", "Balance teams at wave start?", FCVAR_NONE, true, 0.0, true, 1.0);
	c_bSmallMap = AutoExecConfig_CreateConVar("sm_bwrr_smallmap", "0", "Use small robot size for human players. Enable if players are getting stuck.", FCVAR_NONE, true, 0.0, true, 1.0);
	c_flBusterDelay = AutoExecConfig_CreateConVar("sm_bwrr_sentry_buster_delay", "95.0", "Delay between human sentry buster spawn.", FCVAR_NONE, true, 30.0, true, 1200.0);
	c_iBusterMinKills = AutoExecConfig_CreateConVar("sm_bwrr_sentry_buster_minkills", "15", "Minimum amount of kills a sentry gun must have to become a threat.", FCVAR_NONE, true, 5.0, true, 50.0);
	c_flBluRespawnTime = AutoExecConfig_CreateConVar("sm_bwrr_blu_respawn_time", "15.0", "Respawn Time for BLU Players.", FCVAR_NONE, true, 5.0, true, 30.0);
	c_bDebug = AutoExecConfig_CreateConVar("sm_bwrr_debug_enabled", "0.0", "Enable/Disable the debug mode.", FCVAR_NONE, true, 0.0, true, 1.0);
	c_flForceDelay = AutoExecConfig_CreateConVar("sm_bwrr_force_delay", "30.0", "Base delay for sm_robotmenu usage (Normal Robots).", FCVAR_NONE, true, 1.0, true, 600.0);
	c_flFDGiant = AutoExecConfig_CreateConVar("sm_bwrr_force_giant_delay", "60.0", "Base delay for sm_robotmenu usage (Giant Robots).", FCVAR_NONE, true, 1.0, true, 600.0);
	c_strNBFile = AutoExecConfig_CreateConVar("sm_bwrr_botnormal_file", "robots_normal.cfg", "The file to load normal robots templates from. The file name length (including extension) must not exceed 32 characters.", FCVAR_NONE);
	c_strGBFile = AutoExecConfig_CreateConVar("sm_bwrr_botgiant_file", "robots_giant.cfg", "The file to load giant robots templates from. The file name length (including extension) must not exceed 32 characters.", FCVAR_NONE);
	c_bLimitClasses = AutoExecConfig_CreateConVar("sm_bwrr_limit_classes", "1", "Limit playable classes on the BLU team to classes that are used in the current wave", FCVAR_NONE, true, 0.0, true, 1.0);
	
	// Uses AutoExecConfig internally using the file set by AutoExecConfig_SetFile
	AutoExecConfig_ExecuteFile();
	
	// Cleaning is an optional operation that removes whitespaces that might have been introduced and formats the file in a certain way
	// It is an expensive operation (file operations is relatively slow) and should be done at the end when the file will not be written to anymore
	AutoExecConfig_CleanFile();
	
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
	//CreateTimer(180.0, Timer_Announce, _, TIMER_REPEAT);
	
	// commands
	RegConsoleCmd( "sm_joinred", Command_JoinRED, "Joins RED team." );
	RegConsoleCmd( "sm_joinblu", Command_JoinBLU, "Joins BLU/Robot team." );
	RegConsoleCmd( "sm_joinblue", Command_JoinBLU, "Joins BLU/Robot team." );
	RegConsoleCmd( "sm_bwr", Command_JoinBLU, "Joins BLU/Robot team." );
	RegConsoleCmd( "sm_bewithrobots", Command_JoinBLU, "Joins BLU/Robot team." );
	RegConsoleCmd( "sm_robotclass", Command_BotClass, "Changes your robot variant." );
	RegConsoleCmd( "sm_rc", Command_BotClass, "Changes your robot variant." );
	RegConsoleCmd( "sm_bwrr_players", Command_ShowPlayers, "Shows the players in each team" );
	RegConsoleCmd( "sm_robotinfo", Command_RobotInfo, "Prints information about a specific robot" );
	RegConsoleCmd( "sm_waveinfo", Command_WaveInfo, "Prints information about the current wave." );
	RegConsoleCmd( "sm_bossinfo", Command_BossInfo, "Prints information about the current boss." );
	RegConsoleCmd( "sm_robotmenu", Command_RobotMenu, "Opens the robot selection menu." );
	RegConsoleCmd( "sm_rm", Command_RobotMenu, "Opens the robot selection menu." );
	RegConsoleCmd( "sm_bwrrhelp", Command_BWRRHelpMenu, "Opens the Be With Robots Redux help menu." );
	RegAdminCmd( "sm_bwrr_debug", Command_Debug, ADMFLAG_ROOT, "Prints some debug messages." );
	RegAdminCmd( "sm_bwrr_forcebot", Command_ForceBot, ADMFLAG_ROOT, "Forces a specific robot variant on the target." );
	RegAdminCmd( "sm_bwrr_move", Command_MoveTeam, ADMFLAG_BAN, "Changes the target player team." );
	RegAdminCmd( "sm_bwrr_getorigin", Command_GetOrigin, ADMFLAG_ROOT, "Prints your current coordinates." );
	
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
	HookEvent( "teamplay_flag_event", E_Teamplay_Flag );
	HookEvent( "teamplay_flag_event", E_Teamplay_Flag );
	HookEvent( "post_inventory_application", E_Inventory );
	HookEvent( "player_builtobject", E_BuildObject, EventHookMode_Pre );
	
	// User messages
	
	ID_MVMResetUpgrade = GetUserMessageId("MVMResetPlayerUpgradeSpending");
	if(ID_MVMResetUpgrade == INVALID_MESSAGE_ID)
		LogError("Unable to hook user message.");
		
	HookUserMessage(ID_MVMResetUpgrade, MsgHook_MVMRespec);
	
	// SDK calls
	
	Handle hConf = LoadGameConfigFile("tf2.bwrr");
	
	if( hConf == null ) LogError("Failed to load gamedata file tf2.bwrr.txt");
	
	// bool CTFPlayer::PlaySpecificSequence( const char *pAnimationName )
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hConf, SDKConf_Signature, "CTFPlayer::PlaySpecificSequence");
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);		//Sequence name
	if ((g_hSDKPlaySpecificSequence = EndPrepSDKCall()) == null) SetFailState("Failed to create SDKCall for CTFPlayer::PlaySpecificSequence signature!");
	
	//This call will play a particle effect
	StartPrepSDKCall(SDKCall_Static);
	PrepSDKCall_SetFromConf(hConf, SDKConf_Signature, "DispatchParticleEffect");
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);		//pszParticleName
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);	//iAttachType
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);	//pEntity
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);		//pszAttachmentName
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);			//bResetAllParticlesOnEntity 
	if ((g_hSDKDispatchParticleEffect = EndPrepSDKCall()) == null) SetFailState("Failed to create SDKCall for DispatchParticleEffect signature!");
	
	// Used to get an entity center
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hConf, SDKConf_Virtual, "CBaseEntity::WorldSpaceCenter");
	PrepSDKCall_SetReturnInfo(SDKType_Vector, SDKPass_ByRef);
	if ((g_hSDKWorldSpaceCenter = EndPrepSDKCall()) == null) SetFailState("Failed to create SDKCall for CBaseEntity::WorldSpaceCenter offset!");
	
	// Used to allow humans to capture gates
	int iOffset = GameConfGetOffset(hConf, "CFilterTFBotHasTag::PassesFilterImpl");	
	if(iOffset == -1) SetFailState("Failed to get offset of CFilterTFBotHasTag::PassesFilterImpl");
	g_hCFilterTFBotHasTag = DHookCreate(iOffset, HookType_Entity, ReturnType_Bool, ThisPointer_CBaseEntity, CFilterTFBotHasTag);
	DHookAddParam(g_hCFilterTFBotHasTag, HookParamType_CBaseEntity);	//Entity index of the entity using the filter
	DHookAddParam(g_hCFilterTFBotHasTag, HookParamType_CBaseEntity);	//Entity index that triggered the filter
	
	//CTFBot::GetEventChangeAttributes
	g_hGetEventChangeAttributes = DHookCreateDetour(Address_Null, CallConv_THISCALL, ReturnType_Int, ThisPointer_CBaseEntity);
	if (!g_hGetEventChangeAttributes) SetFailState("Failed to setup detour for CTFBot::GetEventChangeAttributes");
	
	if (!DHookSetFromConf(g_hGetEventChangeAttributes, hConf, SDKConf_Signature, "CTFBot::GetEventChangeAttributes"))
	{
		SetFailState("Failed to load CTFBot::GetEventChangeAttributes signature from gamedata");
	}
	
	// HookParamType_Unknown
	DHookAddParam(g_hGetEventChangeAttributes, HookParamType_CharPtr);
	
	if (!DHookEnableDetour(g_hGetEventChangeAttributes, false, CTFBot_GetEventChangeAttributes))     SetFailState("Failed to detour CTFBot::GetEventChangeAttributes.");
	if (!DHookEnableDetour(g_hGetEventChangeAttributes, true, CTFBot_GetEventChangeAttributes_Post)) SetFailState("Failed to detour CTFBot::GetEventChangeAttributes_Post.");
	
	delete hConf;
	
	RT_InitArrays();
	Config_Init();
	Boss_InitArrays();
	
	array_avclass = new ArrayList(10);
	array_avgiants = new ArrayList(10);
	array_spawns = new ArrayList();
}

bool IsDebugging() { return c_bDebug.BoolValue; }

bool IsSmallMap() { return c_bSmallMap.BoolValue; }

char NormalBotsFile()
{
	char buffer[32];
	c_strNBFile.GetString(buffer, sizeof(buffer));
	return buffer;
}

char GiantBotsFile()
{
	char buffer[32];
	c_strGBFile.GetString(buffer, sizeof(buffer));
	return buffer;
}


public void OnLibraryAdded(const char[] name)
{
	if(strcmp(name, "SteamWorks", false) == 0)
	{
		SteamWorks_SetGameDescription("Be With Robots Redux");
	}
}

public void OnConfigsExecuted()
{
	RT_ClearArrays(); // load config calls needed to be moved here in order to properly load a custom file set in the convars
	RT_LoadCfgNormal();
	RT_LoadCfgGiant();
	RT_PostLoad();
}

public void OnMapStart()
{
	if(!IsMvM(true))
	{
		SetFailState("This plugin is for Mann vs Machine Only."); // probably easier than add IsMvM everywhere
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
	
	i = -1;
	while ((i = FindEntityByClassname(i, "func_respawnroom")) != -1)
	{
		if(IsValidEntity(i))
		{
			HookRespawnRoom(i);
		}
	}
	
	RT_ClearArrays();
	RT_LoadCfgNormal();
	RT_LoadCfgGiant();
	RT_PostLoad();
	Config_LoadSpyTelePos();
	Config_LoadEngyTelePos();
	Config_LoadMap();
	
	array_avclass.Clear();
	array_avgiants.Clear();
	
	TF2_GetBombHatchPosition(true);
	
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
	PrecacheScriptSound("MVM.GiantHeavyEntrance");
	PrecacheScriptSound("MVM.Warning");
	g_iLaserSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
	g_iHaloSprite = PrecacheModel("materials/sprites/halo01.vmt");
	g_flBusterVisionTimer = 0.0;
}

public void TF2_OnWaitingForPlayersStart()
{
	AddAdditionalSpawnRooms();
}

public void OnClientDisconnect(int client)
{
	ResetRobotData(client);
	StopRobotLoopSound(client);
	g_bWelcomeMsg[client] = false;
	
	if( client == Boss_GetClient() )
	{
		Boss_Death();
		LogMessage("Client \"%L\" disconnected while playing as a boss robot.", client);
	}
	
	if( client == g_iBusterIndex )
		g_iBusterIndex = -1;
}

public void OnClientPostAdminCheck(int client)
{
	CreateTimer(20.0, Timer_HelpUnstuck, GetClientUserId(client)); // unstuck players from spectator team.
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
				else if( p_bInSpawn[i] )
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

stock void TF2Spawn_EnterSpawn(int client,int entity)
{
	if(TF2_GetClientTeam(client) == TFTeam_Blue && !IsFakeClient(client))
	{
		p_bInSpawn[client] = true;
		TF2_AddCondition(client, TFCond_UberchargedHidden, TFCondDuration_Infinite);
	}
}

stock void TF2Spawn_EnterSpawnOnce(int client,int entity)
{
	if(TF2_GetClientTeam(client) == TFTeam_Blue && !IsFakeClient(client))
	{
		RoboPlayer rp = RoboPlayer(client);
		if(rp.Carrier)
		{
			RequestFrame(UpdateBombHud, GetClientUserId(client));
		}
	}
}

stock void TF2Spawn_LeaveSpawn(int client,int entity)
{
	if(TF2_GetClientTeam(client) == TFTeam_Blue && !IsFakeClient(client))
	{
		RoboPlayer rp = RoboPlayer(client);
		TF2_RemoveCondition(client, TFCond_UberchargedHidden);
		rp.InSpawn = false;
		
		if(rp.Carrier)
		{
			switch( rp.BombLevel )
			{
				case 0: rp.UpgradeTime = GetGameTime() + GetConVarFloat(FindConVar("tf_mvm_bot_flag_carrier_interval_to_1st_upgrade"));
				case 1: rp.UpgradeTime = GetGameTime() + GetConVarFloat(FindConVar("tf_mvm_bot_flag_carrier_interval_to_2nd_upgrade"));
				case 2: rp.UpgradeTime = GetGameTime() + GetConVarFloat(FindConVar("tf_mvm_bot_flag_carrier_interval_to_3rd_upgrade"));
			}
			RequestFrame(UpdateBombHud, GetClientUserId(client));
		}
	}
}

public void OnEntityCreated(int entity,const char[] name)
{
	if ( strcmp( name, "func_capturezone", false) == 0 )
	{
		SDKHook(entity, SDKHook_StartTouch, OnTouchCaptureZone);
		SDKHook(entity, SDKHook_EndTouch, OnEndTouchCaptureZone);
	}
	else if ( strcmp( name, "entity_revive_marker", false) == 0 )
	{
		SDKHook(entity, SDKHook_SpawnPost, OnReviveMarkerSpawnPost);
	}
	else if( strcmp( name, "entity_medigun_shield", false ) == 0 )
	{
		if(IsValidEntity(entity))
		{
			int iOwner = GetEntPropEnt( entity, Prop_Send, "m_hOwnerEntity" );
			if( IsValidClient(iOwner) && TF2_GetClientTeam(iOwner) == TFTeam_Blue && !IsFakeClient(iOwner) )
			{
				SetVariantInt(1);
				AcceptEntityInput(entity, "Skin" );
			}
		}
	}
	else if( strcmp( name, "func_respawnroom", false) == 0 )
	{
		HookRespawnRoom(entity);
	}
	else if(strcmp(name, "filter_tf_bot_has_tag") == 0)
	{
		SDKHook(entity, SDKHook_SpawnPost, OnTFBotTagFilterSpawnPost);
	}
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	if( IsFakeClient(client) || !IsPlayerAlive(client) )
		return Plugin_Continue;
		
	RoboPlayer rp = RoboPlayer(client);
		
	if( TF2_GetClientTeam(client) == TFTeam_Blue )
	{
		if( rp.InSpawn )
		{
			if( buttons & IN_ATTACK ) // block attack buttons when robot players are inside their spawn room.
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
		
		if( rp.Type == Bot_Buster )
		{
			if( g_flBusterVisionTimer < GetEngineTime() )
			{
				g_flBusterVisionTimer = GetEngineTime() + 0.5;
				BusterWallhack(client);
			}
		
			if( buttons & IN_ATTACK ) // Allows sentry busters to detonate by pressing M1
			{
				if( !(TF2_IsPlayerInCondition(client, TFCond_Taunting)) )
				{
					FakeClientCommand(client, "taunt");
					return Plugin_Continue;
				}
			}
		}
		
		if( rp.Carrier && HT_BombDeployTimer == INVALID_HANDLE && !TF2_IsPlayerInCondition(client, TFCond_Taunting) && !TF2_IsPlayerInCondition(client, TFCond_UberchargedHidden) )
		{
			if( TF2_IsGiant(client) )
			{
				if( rp.BombLevel != 4 )
				{
					rp.BombLevel = 4;
					RequestFrame(UpdateBombHud, GetClientUserId(client));
				}
			}
			else
			{
				if( rp.BombLevel > 0 ) // apply defensive buff to nearby robots
				{
					float pPos[3];
					GetClientAbsOrigin(client, pPos);
					for(int i = 1; i <= MaxClients; i++)
					{
						if(i == client)
							continue;
					
						if(!IsClientInGame(i))
							continue;
							
						if(GetClientTeam(i) != GetClientTeam(client))
							continue;
						
						if(rp.BombLevel < 1)
							continue;
							
						float iPos[3];
						GetClientAbsOrigin(i, iPos);
						
						float flDistance = GetVectorDistance(pPos, iPos);
						
						if(flDistance <= 450.0)
						{
							TF2_AddCondition(i, TFCond_DefenseBuffNoCritBlock, 0.125);
						}
					}
				}
				
				if(rp.UpgradeTime <= GetGameTime() && rp.BombLevel < 3 && GetEntPropEnt(client, Prop_Send, "m_hGroundEntity") != -1) // time to upgrade
				{
					FakeClientCommandThrottled(client, "taunt");
					
					if(TF2_IsPlayerInCondition(client, TFCond_Taunting))
					{
						rp.BombLevel += 1;
						
						switch( rp.BombLevel )
						{
							case 1:
							{
								rp.UpgradeTime = GetGameTime() + GetConVarFloat(FindConVar("tf_mvm_bot_flag_carrier_interval_to_2nd_upgrade"));
								TF2_AddCondition(client, TFCond_DefenseBuffNoCritBlock, TFCondDuration_Infinite);
								SDKCall(g_hSDKDispatchParticleEffect, "mvm_levelup1", PATTACH_POINT_FOLLOW, client, "head", 0);
							}
							case 2:
							{
								rp.UpgradeTime = GetGameTime() + GetConVarFloat(FindConVar("tf_mvm_bot_flag_carrier_interval_to_3rd_upgrade"));
								
								Address pRegen = TF2Attrib_GetByName(client, "health regen");
								float flRegen = 0.0;
								if(pRegen != Address_Null)
									flRegen = TF2Attrib_GetValue(pRegen);
								
								TF2Attrib_SetByName(client, "health regen", flRegen + 45.0);
								SDKCall(g_hSDKDispatchParticleEffect, "mvm_levelup2", PATTACH_POINT_FOLLOW, client, "head", 0);
							}
							case 3:
							{
								TF2_AddCondition(client, TFCond_CritOnWin, TFCondDuration_Infinite);
								SDKCall(g_hSDKDispatchParticleEffect, "mvm_levelup3", PATTACH_POINT_FOLLOW, client, "head", 0);
							}
						}
						EmitGameSoundToAll("MVM.Warning", SOUND_FROM_WORLD);
						RequestFrame(UpdateBombHud, GetClientUserId(client));
					}
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
// Called when an entity touches an upgrade station entity
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

// Called when an entity touches the capture zone
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
		RoboPlayer rp = RoboPlayer(other);
		if( rp.Carrier )
		{
			float CarrierPos[3];
			GetClientAbsOrigin(other, CarrierPos);
			TF2_AddCondition(other, TFCond_FreezeInput, 2.3);
			TF2_PlaySequence(other, "primary_deploybomb");
			SetVariantInt(1);
			AcceptEntityInput(other, "SetForcedTauntCam");
			RequestFrame(DisableAnim, GetClientUserId(other));
			if( HT_BombDeployTimer == INVALID_HANDLE )
			{
				HT_BombDeployTimer = CreateTimer(2.1, Timer_DeployBomb, other);
				if( rp.Type == Bot_Giant || rp.Type == Bot_Boss )
					EmitGameSoundToAll("MVM.DeployBombGiant", other, SND_NOFLAGS, other, CarrierPos);
				else
					EmitGameSoundToAll("MVM.DeployBombSmall", other, SND_NOFLAGS, other, CarrierPos);
			}
		}
	}
	
	return Plugin_Continue;
}

// Called when an entity stop touching the flag capture zone
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
		RoboPlayer rp = RoboPlayer(other);
		if( rp.Carrier )
		{
			if( HT_BombDeployTimer != INVALID_HANDLE )
			{
				CloseHandle(HT_BombDeployTimer);
				HT_BombDeployTimer = INVALID_HANDLE;
				SetVariantInt(0);
				AcceptEntityInput(other, "SetForcedTauntCam");
				SetEntProp(other, Prop_Send, "m_bUseClassAnimations", 1);
			}
		}
	}
	
	return Plugin_Continue;
}

// Called when a player starts touching a respawn room
public Action OnStartTouchRespawn(int entity, int other)
{
	if( IsValidClient(other) )
	{
		TF2Spawn_EnterSpawn(other, entity);
		TF2Spawn_EnterSpawnOnce(other, entity);
	}
	
	return Plugin_Continue;
}

// Called when a player is touching a respawn room
public Action OnTouchRespawn(int entity, int other)
{
	if( IsValidClient(other) )
	{
		TF2Spawn_EnterSpawn(other, entity);
	}
	
	return Plugin_Continue;
}

// Called when a player stops touching a respawn room
public Action OnEndTouchRespawn(int entity, int other)
{
	if( IsValidClient(other) )
	{
		TF2Spawn_LeaveSpawn(other, entity);
	}
	
	return Plugin_Continue;
}

public void OnReviveMarkerSpawnPost(int entity)
{
	RequestFrame(KillReviveMaker, EntIndexToEntRef(entity));
}

public void OnTFBotTagFilterSpawnPost(int entity)
{
	DHookEntity(g_hCFilterTFBotHasTag, true, entity);
}

/****************************************************
					DETOURS
*****************************************************/

// Crash fix for mvm_mannhattan & other gate maps. Prevents this function being called on human players.
public MRESReturn CTFBot_GetEventChangeAttributes(int pThis, Handle hReturn, Handle hParams) 
{
	if( IsValidClient(pThis) && !IsFakeClient(pThis) )
	{
		LogMessage("CTFBot::CTFBot_GetEventChangeAttributes BLOCKED on client \"%L\"", pThis);
		
		DHookSetReturn(hReturn, 0);
		return MRES_Supercede;
	}

	return MRES_Ignored; 
}

public MRESReturn CTFBot_GetEventChangeAttributes_Post(int pThis, Handle hReturn, Handle hParams)
{
	if( IsValidClient(pThis) && !IsFakeClient(pThis) )
	{
		LogMessage("CTFBot::CTFBot_GetEventChangeAttributes_Post BLOCKED on client \"%L\"", pThis);
		
		DHookSetReturn(hReturn, 0);
		return MRES_Supercede;
	}
	
	return MRES_Ignored;
}

// Allow human robots to capture gates
public MRESReturn CFilterTFBotHasTag(int iFilter, Handle hReturn, Handle hParams)
{
	if(!GameRules_GetProp("m_bPlayingMannVsMachine") || DHookIsNullParam(hParams, 2) || DHookIsNullParam(hParams, 1))
		return MRES_Ignored;

	int iEntity = DHookGetParam(hParams, 1);
	int iOther  = DHookGetParam(hParams, 2);
	
	if(iOther <= 0 || iOther > MaxClients || !IsClientInGame(iOther))
		return MRES_Ignored;
	
	//Don't care about real bots
	if(IsFakeClient(iOther))
		return MRES_Ignored;
	
	if(!IsPlayerAlive(iOther))
	{
		DHookSetReturn(hReturn, false);
		return MRES_Supercede;
	}
	
	// Don't care if not from BLU team.
	if(GetClientTeam(iOther) != 3)
		return MRES_Ignored;

	bool bNegated = !!GetEntProp(iFilter, Prop_Data, "m_bNegated");
	
	bool bResult = true;
	if(bNegated)
		bResult = !bResult;
	
	char iEntityClassname[64];
	GetEntityClassname(iEntity, iEntityClassname, sizeof(iEntityClassname));
	
	//We don't care about you
	if(strcmp(iEntityClassname, "func_nav_prerequisite") == 0)
		return MRES_Ignored;
	
	//These work the opposite way
	if(strcmp(iEntityClassname, "trigger_add_tf_player_condition") == 0)
		bResult = !bResult;
	
	DHookSetReturn(hReturn, bResult);
	return MRES_Supercede;
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
		
	if( TF2_GetClientTeam(client) == TFTeam_Blue )
		return Plugin_Handled;
		
	if( GameRules_GetRoundState() == RoundState_TeamWin )
		return Plugin_Handled;
		
	if( !CheckCommandAccess(client, "bwrr_joinblue", 0) )
	{
		CPrintToChat(client,"%t", "No BLU Access");
		return Plugin_Handled;
	}
		
	if( array_avclass.Length < 1 ) // Block join BLU to avoid errors
	{
		PrintToChat(client, "Wave Data isn't ready, rebuilding... Please try again.");
		OR_Update();
		UpdateClassArray();
		return Plugin_Handled;
	}
	
	// Denied: Not enough players in RED to join while a wave is running.
	int iMinRed = c_iMinRedinProg.IntValue;
	if( GameRules_GetRoundState() == RoundState_RoundRunning && GetTeamClientCount(2) < iMinRed )
	{
		CPrintToChat(client,"%t", "Not in Prog");
		CPrintToChat(client,"%t","Num Red",iMinRed);
		return Plugin_Handled;
	}
	
	// Denied: Not enough players in RED to join.
	iMinRed = c_iMinRed.IntValue;
	if( GetTeamClientCount(2) < iMinRed )
	{
		CPrintToChat(client,"%t","Need Red");
		CPrintToChat(client,"%t","Num Red",iMinRed);
		return Plugin_Handled;
	}
	
	// Denied: BLU is at full capacity.
	if( GetHumanRobotCount() >= c_iMaxBlu.IntValue )
	{
		CPrintToChat(client, "%t", "Blu Full");
		return Plugin_Handled;
	}
	
	// Denied: Players cannot join BLU while ready.
	bool bReady = view_as<bool>(GameRules_GetProp( "m_bPlayerReady", _, client));
	if( bReady && GameRules_GetRoundState() == RoundState_BetweenRounds )
	{
		CPrintToChat(client,"%t","Unready");
		return Plugin_Handled;
	}
	
	// Denied: Player used an upgrade station.
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
		ReplyToCommand(client, "Halloween Popfile");
		
	if(OR_IsGiantAvaiable())
		ReplyToCommand(client, "Giants available");
		
	int i = -1;
	while( (i = FindEntityByClassname(i, "bot_hint_engineer_nest" )) != -1 )
	{
		if( IsValidEntity(i) )
		{
			ReplyToCommand(client, "bot_hint_engineer_nest found on the map!");
			break;
		}
	}
	
	ReplyToCommand(client, "Class Array Size: %i", array_avclass.Length);
	ReplyToCommand(client, "Giant Array Size: %i", array_avgiants.Length);
	ReplyToCommand(client, "Client Data: RT: %d, RV: %d, RA: %d", p_iBotType[client], p_iBotVariant[client], p_iBotAttrib[client]);
	
	return Plugin_Handled;
}

public Action Command_GetOrigin( int client, int nArgs )
{
	if( !IsValidClient(client) )
		return Plugin_Handled;
		
	float oVec[3];
	int iVec[3];
	GetClientAbsOrigin(client, oVec);
	iVec[0] = RoundToNearest(oVec[0]);
	iVec[1] = RoundToNearest(oVec[1]);
	iVec[2] = RoundToNearest(oVec[2]);
	iVec[2] += 10;
	ReplyToCommand(client, "Origin: \"%i %i %i\"", iVec[0], iVec[1], iVec[2]);
	
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
	
	if( strcmp(arg2, "scout", false) == 0 )
	{
		TargetClass = TFClass_Scout;
	}
	else if( strcmp(arg2, "soldier", false) == 0 )
	{
		TargetClass = TFClass_Soldier;
	}
	else if( strcmp(arg2, "pyro", false) == 0 )
	{
		TargetClass = TFClass_Pyro;
	}
	else if( strcmp(arg2, "demoman", false) == 0 )
	{
		TargetClass = TFClass_DemoMan;
	}
	else if( strcmp(arg2, "heavy", false) == 0 )
	{
		TargetClass = TFClass_Heavy;
	}
	else if( strcmp(arg2, "engineer", false) == 0 )
	{
		TargetClass = TFClass_Engineer;
	}
	else if( strcmp(arg2, "medic", false) == 0 )
	{
		TargetClass = TFClass_Medic;
	}
	else if( strcmp(arg2, "sniper", false) == 0 )
	{
		TargetClass = TFClass_Sniper;
	}
	else if( strcmp(arg2, "spy", false) == 0 )
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
	
	char strBotName[255];
	RT_GetTemplateName(strBotName, sizeof(strBotName), TargetClass, iArg4, iArg3);
	
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
			LogAction(client, target_list[i], "\"%L\" Forced a robot variant (%s|%s) on \"%L\".", client, arg2, strBotName, target_list[i]);
		}
		else
		{
			ReplyToCommand(client, "ERROR: This command can only be used on BLU team.");
			return Plugin_Handled;
		}
	}
	
	if (tn_is_ml)
	{
		ShowActivity2(client, "[SM] ", "Forced a robot variant (%s|%s) on %t.", arg2, strBotName, target_name);
	}
	else
	{
		ShowActivity2(client, "[SM] ", "Forced a robot variant (%s|%s) on %s.", arg2, strBotName, target_name);
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
				CReplyToCommand(client, "{springgreen}Wave data needs to be built. Building data...");
				OR_Update();
				UpdateClassArray();
				return Plugin_Handled;
			}
			else
			{
				MovePlayerToBLU(target_list[i]);
			}
		}
		else if( NewTargetTeam == TFTeam_Red )
		{
			MovePlayerToRED(target_list[i]);
		}
		else
		{
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
		
	if( !p_bInSpawn[client] && GameRules_GetRoundState() == RoundState_RoundRunning )
	{
		CReplyToCommand(client, "%t", "BotClassFailMsg");
		return Plugin_Handled;
	}

	if( Boss_GetClient() == client )
	{
		Boss_Death();
		LogAction(client, -1, "\"%L\" selected a new robot while playing as a boss.", client);
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
	
	ReplyToCommand(client, "%i player(s) in RED: %s", iRedCount, RedNames);
	ReplyToCommand(client, "%i player(s) in BLU: %s", iBluCount, BluNames);
	ReplyToCommand(client, "%i player(s) in SPEC: %s", iSpecCount, SpecNames);

	return Plugin_Handled;
}

public Action Command_RobotInfo( int client, int nArgs )
{
	if( nArgs < 3 )
	{
		ReplyToCommand(client, "Usage: sm_robotinfo <class> <type: 0 - normal | 1 - giant> <variant>");
		ReplyToCommand(client, "Valid Classes: scout,soldier,pyro,demoman,heavy,engineer,medic,sniper,spy");
		return Plugin_Handled;
	}
	
	char arg1[16], arg2[16], arg3[16], strVariantName[255];
	int iArg2, iArg3;
	TFClassType TargetClass = TFClass_Unknown;
	bool bGiants = false;
	
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	GetCmdArg(3, arg3, sizeof(arg3));
	iArg2 = StringToInt(arg2);
	iArg3 = StringToInt(arg3);
	
	if( iArg2 < 0 || iArg2 > 1 )
	{
		ReplyToCommand(client, "ERROR: Use 0 for Normal Bot and 1 for Giant Bot");
		return Plugin_Handled;
	}
	
	if(iArg2 != 0)
		bGiants = true;
	
	if( strcmp(arg1, "scout", false) == 0 )
	{
		TargetClass = TFClass_Scout;
	}
	else if( strcmp(arg1, "soldier", false) == 0 )
	{
		TargetClass = TFClass_Soldier;
	}
	else if( strcmp(arg1, "pyro", false) == 0 )
	{
		TargetClass = TFClass_Pyro;
	}
	else if( strcmp(arg1, "demoman", false) == 0 )
	{
		TargetClass = TFClass_DemoMan;
	}
	else if( strcmp(arg1, "heavy", false) == 0 )
	{
		TargetClass = TFClass_Heavy;
	}
	else if( strcmp(arg1, "engineer", false) == 0 )
	{
		TargetClass = TFClass_Engineer;
	}
	else if( strcmp(arg1, "medic", false) == 0 )
	{
		TargetClass = TFClass_Medic;
	}
	else if( strcmp(arg1, "sniper", false) == 0 )
	{
		TargetClass = TFClass_Sniper;
	}
	else if( strcmp(arg1, "spy", false) == 0 )
	{
		TargetClass = TFClass_Spy;
	}
	
	if( TargetClass == TFClass_Unknown )
	{
		ReplyToCommand(client, "ERROR: Invalid class.");
		ReplyToCommand(client, "Valid Classes: scout,soldier,pyro,demoman,heavy,engineer,medic,sniper,spy.");
		return Plugin_Handled;
	}
	
	if(IsValidVariant(bGiants, TargetClass, iArg3))
	{
		if(bGiants)
			RT_GetTemplateName(strVariantName, sizeof(strVariantName), TargetClass, iArg3, 1);
		else
			RT_GetTemplateName(strVariantName, sizeof(strVariantName), TargetClass, iArg3, 0);
			
		ReplyToCommand(client, "ID: %d", iArg3);
		ReplyToCommand(client, "Name: %s", strVariantName);
		
		if(IsClassAvailable(TargetClass, bGiants))
			ReplyToCommand(client, "Status: Available for the current wave");
		else
			ReplyToCommand(client, "Status: Unavailable for the current wave");
	}
	else
		ReplyToCommand(client, "ERROR: Invalid Variant.");
	
	return Plugin_Handled;
}

// Prints information about the current wave.
public Action Command_WaveInfo( int client, int nArgs )
{		
	int iABots, iCW, iMW;
	char strNormalBots[256], strGiantBots[256], buffer[128];

	iABots = OR_GetAvailableClasses();
	iCW = OR_GetCurrentWave();
	iMW = OR_GetMaxWave();
	
	if(iABots & scout_normal) // scout
	{
		Format(strNormalBots, sizeof(strNormalBots), "%s %s", strNormalBots, "Scout");
	}
	if(iABots & soldier_normal) // soldier
	{
		Format(strNormalBots, sizeof(strNormalBots), "%s %s", strNormalBots, "Soldier");
	}
	if(iABots & pyro_normal) // pyro
	{
		Format(strNormalBots, sizeof(strNormalBots), "%s %s", strNormalBots, "Pyro");
	}
	if(iABots & demoman_normal) // demoman
	{
		Format(strNormalBots, sizeof(strNormalBots), "%s %s", strNormalBots, "Demoman");
	}
	if(iABots & heavy_normal) // heavy
	{
		Format(strNormalBots, sizeof(strNormalBots), "%s %s", strNormalBots, "Heavy");
	}
	if(iABots & engineer_normal) // engineer
	{
		Format(strNormalBots, sizeof(strNormalBots), "%s %s", strNormalBots, "Engineer");
	}
	if(iABots & medic_normal) // medic
	{
		Format(strNormalBots, sizeof(strNormalBots), "%s %s", strNormalBots, "Medic");
	}
	if(iABots & sniper_normal) // sniper
	{
		Format(strNormalBots, sizeof(strNormalBots), "%s %s", strNormalBots, "Sniper");
	}
	if(iABots & spy_normal) // spy
	{
		Format(strNormalBots, sizeof(strNormalBots), "%s %s", strNormalBots, "Spy");
	}
	
	// Giants
	if(iABots & scout_giant) // scout
	{
		Format(strGiantBots, sizeof(strGiantBots), "%s %s", strGiantBots, "Scout");
	}
	if(iABots & soldier_giant) // soldier
	{
		Format(strGiantBots, sizeof(strGiantBots), "%s %s", strGiantBots, "Soldier");
	}
	if(iABots & pyro_giant) // pyro
	{
		Format(strGiantBots, sizeof(strGiantBots), "%s %s", strGiantBots, "Pyro");
	}
	if(iABots & demoman_giant) // demoman
	{
		Format(strGiantBots, sizeof(strGiantBots), "%s %s", strGiantBots, "Demoman");
	}
	if(iABots & heavy_giant) // heavy
	{
		Format(strGiantBots, sizeof(strGiantBots), "%s %s", strGiantBots, "Heavy");
	}
	if(iABots & engineer_giant) // engineer
	{
		Format(strGiantBots, sizeof(strGiantBots), "%s %s", strGiantBots, "Engineer");
	}
	if(iABots & medic_giant) // medic
	{
		Format(strGiantBots, sizeof(strGiantBots), "%s %s", strGiantBots, "Medic");
	}
	if(iABots & sniper_giant) // sniper
	{
		Format(strGiantBots, sizeof(strGiantBots), "%s %s", strGiantBots, "Sniper");
	}
	if(iABots & spy_giant) // spy
	{
		Format(strGiantBots, sizeof(strGiantBots), "%s %s", strGiantBots, "Spy");
	}
	
	if( !strNormalBots[0] )
		FormatEx(strNormalBots, sizeof(strNormalBots), "%s", "None");
		
	if( !strGiantBots[0] )
		FormatEx(strGiantBots, sizeof(strGiantBots), "%s", "None");
	
	OR_GetMissionName(buffer, sizeof(buffer));
	ReplyToCommand(client, "Mission: %s", buffer);
	ReplyToCommand(client, "Wave %d of %d", iCW, iMW);
	ReplyToCommand(client, "Available Robots:");
	ReplyToCommand(client, "Normal Robots: %s", strNormalBots);
	ReplyToCommand(client, "Giant Robots: %s", strGiantBots);
	
	return Plugin_Handled;
}

public Action Command_BossInfo( int client, int nArgs )
{
	char state[32], bossname[64];
	int iBossPlayer = Boss_GetClient();
	
	if( GameRules_GetRoundState() != RoundState_RoundRunning )
	{
		ReplyToCommand(client, "Boss data is only available after wave start.");
		return Plugin_Handled;
	}
	
	switch( g_BossState )
	{
		case BossState_Unavailable:
		{
			strcopy(state, sizeof(state), "Unavailable");
		}
		case BossState_Available:
		{
			strcopy(state, sizeof(state), "Available");
		}
		case BossState_InPlay:
		{
			strcopy(state, sizeof(state), "Active");
		}
		case BossState_Defeated:
		{
			strcopy(state, sizeof(state), "Defeated");
		}
	}
	
	Boss_GetName(bossname, sizeof(bossname));
	ReplyToCommand(client, "Boss State: %s", state);
	ReplyToCommand(client, "Selected Boss: %s", bossname);
	if( IsValidClient(iBossPlayer) && IsPlayerAlive(iBossPlayer) )
	{
		ReplyToCommand(client, "Active Boss: Controller: N || Health: %i", iBossPlayer, GetClientHealth(iBossPlayer));
	}
	
	if( GetTeamClientCount(2) < g_BossMinRed )
	{
		ReplyToCommand(client, "Not enough players in RED to allow bosses to spawn.");
	}
	
	float enginetime = GetEngineTime();
	if( g_BossTimer > enginetime )
	{
		int iSpawnTime = RoundToNearest( g_BossTimer - enginetime );
		if( iSpawnTime > 0 )
		{
			ReplyToCommand(client, "Boss will be able to spawn in %i seconds", iSpawnTime);
		}
	}
	
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
	if( strcmp( strTeam, "red", false ) == 0 )
	{
		FakeClientCommand(client, "sm_joinred");
		return Plugin_Handled;
	}
	else if( strcmp( strTeam, "blue", false ) == 0 )
	{
		FakeClientCommand(client, "sm_joinblue");
		return Plugin_Handled;
	}
	else if( strcmp( strTeam, "spectate", false ) == 0 || strcmp( strTeam, "spectator", false ) == 0 )
	{
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
	if( !IsValidClient(client) )
		return Plugin_Handled;
		
	if( IsFakeClient(client) )
		return Plugin_Continue;

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

	if( p_bInSpawn[client] )
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
	if(!IsValidClient(client))
		return Plugin_Handled;

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
					MENUS
*****************************************************/

public Action Command_RobotMenu( int client, int nArgs )
{		
	if(!IsValidClient(client))
		return Plugin_Handled;
		
	if(IsFakeClient(client))
		return Plugin_Handled;
		
	if(!IsPlayerAlive(client))
	{
		CReplyToCommand(client, "{cyan}Only living players can use this command.");
		return Plugin_Handled;
	}
		
	if(TF2_GetClientTeam(client) != TFTeam_Blue)
	{
		CReplyToCommand(client, "%t", "CmdErrorBLUOnly");
		return Plugin_Handled;
	}
		
	if(!p_bInSpawn[client] && GameRules_GetRoundState() == RoundState_RoundRunning )
	{
		CReplyToCommand(client, "%t", "BotClassFailMsg");
		return Plugin_Handled;
	}

	if( GetEngineTime() < g_flLastForceBot[client] )
	{
		int iWaitTime = RoundToNearest(g_flLastForceBot[client] - GetEngineTime());
		CReplyToCommand(client, "%t", "Wait Secs to Use", iWaitTime);
		return Plugin_Handled;
	}
		
	Menu menu = new Menu(MenuHandler_SelectBotType, MENU_ACTIONS_ALL);
	
	menu.SetTitle("Select a Robot Type");
	
	bool normalbots = OR_IsNormalAvaiable();
	bool giantbots = OR_IsGiantAvaiable();
	
	if(normalbots)
	{
		menu.AddItem("normal_bot", "Normal");
	}
	
	if(!normalbots)
	{
		if(giantbots) // Normal bots are not available, make giants available regardless of player count.
		{
			menu.AddItem("giant_bot", "Giant");
		}
	}
	else
	{
		if(giantbots)
		{
			if(GetTeamClientCount(view_as<int>(TFTeam_Red)) >= c_iGiantMinRed.IntValue )
			{ // Giants available if there are enough players on RED team.
				menu.AddItem("giant_bot", "Giant");
			}
		}
	}
	
	menu.ExitButton = true;
	menu.Display(client, 30);
 
	return Plugin_Handled;
}

// Select robot type
public int MenuHandler_SelectBotType(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[32];
			bool bFound = menu.GetItem(param2, info, sizeof(info));
			if(bFound)
			{
				if(strcmp(info, "normal_bot") == 0)
				{
					MenuFunc_ShowClassMenu(param1, false);
				}
				else if(strcmp(info, "giant_bot") == 0)
				{
					MenuFunc_ShowClassMenu(param1, true);
				}
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	
	return 0;
}

void MenuFunc_ShowClassMenu(int client, bool isgiant)
{
	TFClassType TFClass = TFClass_Unknown;
	Menu menu = new Menu(MenuHandler_SelectClass, MENU_ACTIONS_ALL);
	g_bBotMenuIsGiant[client] = isgiant;
	
	menu.SetTitle("Select a Class");
	
	for(int i = 1; i <= 9; i++)
	{
		TFClass = view_as<TFClassType>(i);
		if(IsClassAvailable(TFClass, isgiant))
		{
			switch(TFClass)
			{
				case TFClass_Scout: menu.AddItem("scout", "Scout");
				case TFClass_Soldier: menu.AddItem("soldier", "Soldier");
				case TFClass_Pyro: menu.AddItem("pyro", "Pyro");
				case TFClass_DemoMan: menu.AddItem("demoman", "Demoman");
				case TFClass_Heavy: menu.AddItem("heavy", "Heavy");
				case TFClass_Engineer: menu.AddItem("engineer", "Engineer");
				case TFClass_Medic: menu.AddItem("medic", "Medic");
				case TFClass_Sniper: menu.AddItem("sniper", "Sniper");
				case TFClass_Spy: menu.AddItem("spy", "Spy");
			}
		}
	}
	
	menu.Pagination = MENU_NO_PAGINATION;
	menu.ExitButton = false;
	menu.Display(client, 30);
	
	return;
}

// Selects a class
public int MenuHandler_SelectClass(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[32];
			TFClassType selectedclass = TFClass_Unknown;
			bool bFound = menu.GetItem(param2, info, sizeof(info));
			if(bFound)
			{
				if(strcmp(info, "scout") == 0)
				{	selectedclass = TFClass_Scout; }
				else if(strcmp(info, "soldier") == 0)
				{	selectedclass = TFClass_Soldier; }
				else if(strcmp(info, "pyro") == 0)
				{	selectedclass = TFClass_Pyro; }
				else if(strcmp(info, "demoman") == 0)
				{	selectedclass = TFClass_DemoMan; }
				else if(strcmp(info, "heavy") == 0)
				{	selectedclass = TFClass_Heavy; }
				else if(strcmp(info, "engineer") == 0)
				{	selectedclass = TFClass_Engineer; }
				else if(strcmp(info, "medic") == 0)
				{	selectedclass = TFClass_Medic; }
				else if(strcmp(info, "sniper") == 0)
				{	selectedclass = TFClass_Sniper; }
				else if(strcmp(info, "spy") == 0)
				{	selectedclass = TFClass_Spy; }
				
				MenuFunc_ShowVariantMenu(param1, selectedclass);
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	
	return 0;
}

void MenuFunc_ShowVariantMenu(int client, TFClassType variantclass)
{
	Menu menu = new Menu(MenuHandler_SelectVariant, MENU_ACTIONS_ALL);
	char variantid[8], variantname[255];
	
	g_BotMenuSelectedClass[client] = variantclass;
	menu.SetTitle("Select a Variant");
	
	if(g_bBotMenuIsGiant[client]) // client selected a giant robot
	{
		if( CheckCommandAccess(client, "bwrr_ownloadout", 0) )
		{
			menu.AddItem("-1", "Own Loadout");
		}
		
		for(int i = 0; i < RT_NumTemplates(g_bBotMenuIsGiant[client], variantclass);i++)
		{
			FormatEx(variantid, sizeof(variantid), "%i", i);
			RT_GetTemplateName(variantname, sizeof(variantname), variantclass, i, 1);
			menu.AddItem(variantid, variantname);
		}
	}
	else
	{
		if( CheckCommandAccess(client, "bwrr_ownloadout", 0) )
		{
			menu.AddItem("-1", "Own Loadout");
		}
		
		for(int i = 0; i < RT_NumTemplates(g_bBotMenuIsGiant[client], variantclass);i++)
		{
			FormatEx(variantid, sizeof(variantid), "%i", i);
			RT_GetTemplateName(variantname, sizeof(variantname), variantclass, i, 0);
			menu.AddItem(variantid, variantname);
		}
	}
	
	menu.ExitButton = true;
	menu.Display(client, 30);
}

public int MenuHandler_SelectVariant(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[32], botname[255];
			int id, type = Bot_Normal;
			bool bFound = menu.GetItem(param2, info, sizeof(info));
			if(bFound)
			{
				id = StringToInt(info);
				if(g_bBotMenuIsGiant[param1]) { type = Bot_Giant; } else { type = Bot_Normal; }
				SetRobotOnPlayer(param1, id, type, g_BotMenuSelectedClass[param1]);
				if( type == Bot_Normal ) 
				{ 
					RT_GetTemplateName(botname, sizeof(botname), g_BotMenuSelectedClass[param1], id, 0);
					g_flLastForceBot[param1] = GetEngineTime() + c_flForceDelay.FloatValue + RT_GetCooldown(g_BotMenuSelectedClass[param1], id, 0);
				} 
				else 
				{ 
					RT_GetTemplateName(botname, sizeof(botname), g_BotMenuSelectedClass[param1], id, 1);
					g_flLastForceBot[param1] = GetEngineTime() + c_flFDGiant.FloatValue + RT_GetCooldown(g_BotMenuSelectedClass[param1], id, 1);
				}
				if(GameRules_GetRoundState() == RoundState_BetweenRounds)
				{
					g_flLastForceBot[param1] = GetEngineTime() + 5.0; // small cooldown when the wave is not in progress
				}
				LogAction(param1, -1, "\"%L\" selected a robot (%s)", param1,botname);
				if( Boss_GetClient() == param1 )
				{
					Boss_Death();
					LogAction(param1, -1, "\"%L\" selected a new robot while playing as a boss.", param1);
				}
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
	
	return 0;
}

public Action Command_BWRRHelpMenu( int client, int nArgs )
{		
	if(!IsValidClient(client))
		return Plugin_Handled;
		
	if(IsFakeClient(client))
		return Plugin_Handled;
		
	Menu menu = new Menu(MenuHandler_HelpMenu, MENU_ACTIONS_ALL);
	
	menu.SetTitle("%T", "Menu_Help", LANG_SERVER);
	menu.AddItem("helpm1", "Joining BLU");
	menu.AddItem("helpm2", "Selecting a Robot");
	menu.AddItem("helpm3", "Sentry Busters");
	menu.AddItem("helpm4", "Spies");
	menu.AddItem("helpm5", "Engineers");
	menu.AddItem("helpm6", "About");
	menu.ExitButton = true;
	menu.Display(client, 30);
 
	return Plugin_Handled;
}

public int MenuHandler_HelpMenu(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[32];
			bool bFound = menu.GetItem(param2, info, sizeof(info));
			if(bFound)
			{
				if(strcmp(info, "helpm1") == 0)
				{
					MenuFunc_PrintHelp(1, param1);
				}
				else if(strcmp(info, "helpm2") == 0)
				{
					MenuFunc_PrintHelp(2, param1);
				}
				else if(strcmp(info, "helpm3") == 0)
				{
					MenuFunc_PrintHelp(3, param1);
				}
				else if(strcmp(info, "helpm4") == 0)
				{
					MenuFunc_PrintHelp(4, param1);
				}
				else if(strcmp(info, "helpm5") == 0)
				{
					MenuFunc_PrintHelp(5, param1);
				}
				else if(strcmp(info, "helpm6") == 0)
				{
					MenuFunc_PrintHelp(6, param1);
				}
			}			
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}

void MenuFunc_PrintHelp(int fid, int client)
{
	switch( fid )
	{
		case 1:
		{
			CPrintToChat(client, "%t", "Help_JoinBLU");
		}
		case 2:
		{
			CPrintToChat(client, "%t", "Help_SelectRobot");
		}
		case 3:
		{
			int i = c_iBusterMinKills.IntValue;
			int x = RoundToNearest(c_flBusterDelay.FloatValue);
			CPrintToChat(client, "%t", "Help_SentryBusterP1");
			CPrintToChat(client, "%t", "Help_SentryBusterP2", x, i);
		}
		case 4:
		{
			CPrintToChat(client, "%t", "Help_Spies");
		}
		case 5:
		{
			CPrintToChat(client, "%t", "Help_EngineersP1");
			CPrintToChat(client, "%t", "Help_EngineersP2");
			CPrintToChat(client, "%t", "Help_EngineersP3");
		}
		case 6:
		{
			CPrintToChat(client, "{cyan}Be With Robots Redux version {green}%s{cyan} by {deepskyblue}Anonymous Player", PLUGIN_VERSION);
			CPrintToChat(client, "{cyan}https://github.com/caxanga334/tf-bewithrobots-redux");
		}
		default:
		{
			LogError("How did we get here???");
		}
	}
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
	ResetRobotMenuCooldown();
	Boss_LoadWaveConfig();
}

public Action E_WaveEnd(Event event, const char[] name, bool dontBroadcast)
{
	CreateTimer(2.0, Timer_UpdateWaveData);
	for(int i = 1; i <= MaxClients; i++)
	{
		if( IsClientInGame(i) && !IsFakeClient(i) && TF2_GetClientTeam(i) == TFTeam_Blue )
		{
			CreateTimer(3.0, Timer_UpdateRobotClasses, i);
		}
	}
	ResetRobotMenuCooldown();
}

public Action E_WaveFailed(Event event, const char[] name, bool dontBroadcast)
{
	OR_Update();
	UpdateClassArray();
	ResetRobotMenuCooldown();
	CreateTimer(2.0, Timer_RemoveFromSpec);
}

public Action E_MissionComplete(Event event, const char[] name, bool dontBroadcast)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if( IsClientInGame(i) && !IsFakeClient(i) && TF2_GetClientTeam(i) == TFTeam_Blue )
		{
			MovePlayerToRED(i);
		}
	}
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
	
	if( !IsFakeClient(client) && !g_bWelcomeMsg[client] && TF2_GetClientTeam(client) == TFTeam_Red )
	{
		CreateTimer(5.0, Timer_ShowWelcMsg, client);
		g_bWelcomeMsg[client] = true;
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
		if( client == Boss_GetClient() )
		{
			Boss_Death();
		}
		
		if( client == g_iBusterIndex )
			g_iBusterIndex = -1;
	
		if( TF2_GetPlayerClass(client) == TFClass_Engineer )
		{
			AnnounceEngineerDeath(client);
			//CreateTimer(1.0, Timer_FixBuildings, client); // Not needed anymore
		}
		else if( TF2_GetPlayerClass(client) == TFClass_Spy )
		{
			if( GetClassCount(TFClass_Spy, TFTeam_Blue, true, false) <= 1 )
				EmitGSToRed("Announcer.mvm_spybot_death_all");
		}
		SetEntProp(client, Prop_Send, "m_bIsMiniBoss", 0);
		SetEntProp(client, Prop_Send, "m_bUseBossHealthBar", 0);
		if( p_iBotType[client] == Bot_Giant || p_iBotType[client] == Bot_Boss )
		{
			float SndPos[3];
			GetClientAbsOrigin(client, SndPos);
			EmitGameSoundToAll("MVM.GiantHeavyExplodes", client, SND_NOFLAGS, client, SndPos);
			float clientPosVec[3];
			GetClientAbsOrigin(client, clientPosVec);
			Robot_GibGiant(client, clientPosVec);
		}
		
		CreateTimer(c_flBluRespawnTime.FloatValue, Timer_RespawnBLUPlayer, client);
		CreateTimer(1.0, Timer_PickRandomRobot, client);
		StopRobotLoopSound(client);
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

				switch( p_iBotType[client] )
				{
					case Bot_Boss:
					{
						Boss_GiveInventory(client);
					}
					case Bot_Giant:
					{
						RT_GiveInventory(client, 1, p_iBotVariant[client]);
					}
					case Bot_Buster:
					{
						GiveBusterInventory(client);
					}
					default:
					{
						RT_GiveInventory(client, 0, p_iBotVariant[client]);
					}
				}
			}
			else
			{
				StripItems(client, false); // remove misc but not weapons, allow own loadout
			}
		}
	}
}

public Action E_Teamplay_Flag(Event event, const char[] name, bool dontBroadcast)
{
	if( event.GetInt("eventtype") == TF_FLAGEVENT_PICKEDUP )
	{
		int client = event.GetInt("player");
		RoboPlayer rp = RoboPlayer(client);
		if( !IsFakeClient(client) )
		{
			rp.Carrier = true;
			if(TF2_IsGiant(client))
			{
				rp.BombLevel = 4;
			}
			else
			{
				rp.BombLevel = 0;
				rp.UpgradeTime = GetGameTime() + GetConVarFloat(FindConVar("tf_mvm_bot_flag_carrier_interval_to_1st_upgrade")); 
			}
			RequestFrame(UpdateBombHud, GetClientUserId(client));
		}
	}
	if( event.GetInt("eventtype") == TF_FLAGEVENT_DROPPED )
	{
		int client = event.GetInt("player");
		RoboPlayer rp = RoboPlayer(client);
		if( !IsFakeClient(client) )
		{
			rp.Carrier = false;
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
	char strBotName[255], strBotDesc[255];
	int iTeleTarget = -1;
		
	if( TF2_GetClientTeam(client) == TFTeam_Blue && !IsFakeClient(client) )
	{
		g_bIsCarrier[client] = false;
		
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
				SetEntPropFloat( client, Prop_Send, "m_flRageMeter", 100.0 ); // Medigun's Shield
				int iWeapon = TF2_GetPlayerLoadoutSlot(client, TF2LoadoutSlot_Secondary);
				if( IsValidEdict( iWeapon ) )
					SetEntPropFloat( iWeapon, Prop_Send, "m_flChargeLevel", 1.0 );
			}
			else if( TFClass == TFClass_Soldier )
			{
				SetEntPropFloat( client, Prop_Send, "m_flRageMeter", 100.0 );
			}			
		}
		if( p_iBotAttrib[client] & BotAttrib_CannotCarryBomb )
		{
			BlockBombPickup(client);
		}
		
		if(OR_IsHalloweenMission())
		{
			TF2_AddCondition(client, TFCond_CritOnFlagCapture, TFCondDuration_Infinite);
		}
		
		switch( p_iBotType[client] )
		{
			case Bot_Giant:
			{
				RT_GetTemplateName(strBotName, sizeof(strBotName), TFClass, p_iBotVariant[client], 1);
				RT_GetDescription(strBotDesc, sizeof(strBotDesc), TFClass, p_iBotVariant[client], 1);
				SetEntProp( client, Prop_Send, "m_bIsMiniBoss", 1 ); // has nothing to do with variant name but same condition
				ApplyRobotLoopSound(client);
				RT_SetHealth(client, p_BotClass[client], p_iBotVariant[client], 1);				
			}
			case Bot_Boss:
			{
				Boss_GetName(strBotName, sizeof(strBotName));
				SetEntProp(client, Prop_Send, "m_bIsMiniBoss", 1);
				SetEntProp(client, Prop_Send, "m_bUseBossHealthBar", 1);
				Boss_SetHealth(client);
				ApplyRobotLoopSound(client);
				char plrname[MAX_NAME_LENGTH];
				GetClientName(client, plrname, sizeof(plrname));
				CPrintToChatAll("%t", "Boss_Spawn", plrname, strBotName, Boss_ComputeHealth());
				LogAction(client, -1, "Player \"%L\" spawned as a boss robot ( %s ).", client, strBotName);
				EmitGameSoundToAll("MVM.GiantHeavyEntrance", SOUND_FROM_PLAYER);
			}
			case Bot_Buster:
			{
				strBotName = "Sentry Buster";
				SetEntProp( client, Prop_Send, "m_bIsMiniBoss", 1 );
				EmitGSToRed("Announcer.MVM_Sentry_Buster_Alert");
				ApplyRobotLoopSound(client);
				SetEntProp(client, Prop_Send, "m_iHealth", 2500);
				SetEntProp(client, Prop_Data, "m_iHealth", 2500);
			}
			default:
			{
				RT_GetTemplateName(strBotName, sizeof(strBotName), TFClass, p_iBotVariant[client], 0);
				RT_GetDescription(strBotDesc, sizeof(strBotDesc), TFClass, p_iBotVariant[client], 1);
				StopRobotLoopSound(client);
				RT_SetHealth(client, p_BotClass[client], p_iBotVariant[client], 0);
			}
		}

		CPrintToChat(client, "%t", "Bot Spawn", strBotName);
		if( strlen(strBotDesc) > 3 ) { PrintToChat(client, "%s", strBotDesc); }
		SetRobotScale(client,TFClass);
		SetRobotModel(client,TFClass);
		
		// teleport player
		if( GameRules_GetRoundState() == RoundState_RoundRunning )
		{
			switch( TFClass )
			{
				case TFClass_Spy: // spies should always spawn on their hints
				{
					TF2_AddCondition(client, TFCond_Stealthed, 7.0);
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
						if( (p_iBotAttrib[client] & BotAttrib_TeleportToHint) ) // found nest
						{
							FindEngineerNestNearBomb(client);
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
	
	if(c_bDebug.BoolValue && TF2_GetClientTeam(client) == TFTeam_Blue)
	{
		PrintToChat(client, "Robot Type: %d", p_iBotType[client]);
		PrintToChat(client, "Robot Variant: %d", p_iBotVariant[client]);
		PrintToChat(client, "Robot Attributes: %d", p_iBotAttrib[client]);
		LogMessage("OnPlayerSpawn: \"%N\" Type: %d, Variant: %d, Attributes: %d", client, p_iBotType[client], p_iBotVariant[client], p_iBotAttrib[client]);
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
// Delayed set class to fix some small bugs
public Action Timer_SetRobotClass(Handle timer, any client)
{
	if( !IsValidClient(client) || IsFakeClient(client) )
		return Plugin_Stop;
		
	TF2_SetPlayerClass(client, p_BotClass[client], true, true);
	
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

public Action Timer_PickRandomRobot(Handle timer, any client)
{
	if( !IsValidClient(client) || IsFakeClient(client) )
		return Plugin_Stop;
		
	PickRandomRobot(client);
	
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
// Used to move players back to RED team when a wave fails
// TF2 automatically removes humans from BLU team when a wave is lost
public Action Timer_RemoveFromSpec(Handle timer, any client)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if( IsClientInGame(i) && !IsFakeClient(i) && TF2_GetClientTeam(i) == TFTeam_Spectator )
		{
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
		GetEdictClassname(index, classname, sizeof(classname));
		
		if( strcmp(classname, "obj_sentrygun", false) == 0 )
		{
			if( GetEntProp( index, Prop_Send, "m_bMiniBuilding" ) == 1 || GetEntProp( index, Prop_Send, "m_bDisposableBuilding" ) == 1 )
			{ // mini building, don't set to level 3
				DispatchKeyValue(index, "defaultupgrade", "0");
			}
			else // normal building, set to level 3
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
			{ // This engineer variant can't building teleporters
				SetVariantInt(9999);
				AcceptEntityInput(index, "RemoveHealth");
				PrintCenterText(iBuilder, "YOU CANNOT BUILD TELEPORTERS");
			}
			else if( TF2_GetObjectMode(index) == TFObjectMode_Entrance )
			{
				SetVariantInt(9999);
				AcceptEntityInput(index, "RemoveHealth");
				PrintCenterText(iBuilder, "BUILD EXIT");
			}
			else
			{
				if( CheckTeleportClamping(index, iBuilder) )
				{
					PrintCenterText(iBuilder, "NOT ENOUGH SPACE TO BUILD A TELEPORTER");
					CPrintToChat(iBuilder, "%t", "EngyTeleSpaceError");
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

/**public Action Timer_Announce(Handle timer)
{
	PrintToChatAll("Be With Robots Redux By Anonymous Player.");
	PrintToChatAll("https://github.com/caxanga334/tf-bewithrobots-redux");
}**/

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
		if( strcmp( strClassname, "info_particle_system", false ) == 0 )
			RemoveEntity(iParticle);
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
		GetEntityClassname(entity, Classname, sizeof(Classname));

		//Is a Particle:
		if(strcmp(Classname, "tf_ragdoll", false) == 0)
		{
			RemoveEntity(entity);
		}
	}
}
// Applies the giant sound, needs delay to compensate for latency
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

// Prints the welcome message
public Action Timer_ShowWelcMsg(Handle timer, any client)
{
	if( !IsValidClient(client) || IsFakeClient(client) )
		return Plugin_Stop;
		
	CPrintToChat(client, "%t", "Welcome_Msg");
	
	return Plugin_Stop;
}

public Action Timer_HelpUnstuck(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if( !IsValidClient(client) || IsFakeClient(client) )
		return Plugin_Stop;
	
	if( GetClientTeam(client) <= 1 )
	{
		// moving players automatically to RED causes them to be unable to close the MOTD with the mouse
		// to avoid issues, print a message telling players to type the join team command in chat.
		CPrintToChat(client, "%t", "Spec_Stuck");
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
	int iEntFlags = GetEntityFlags( client );
	SetEntityFlags( client, iEntFlags | FL_FAKECLIENT );
	TF2_ChangeClientTeam( client, TFTeam_Red );
	SetEntityFlags( client, iEntFlags );
	SetEntProp( client, Prop_Send, "m_bIsMiniBoss", 0 );
	TF2Attrib_RemoveAll(client);
	TF2Attrib_ClearCache(client);
	
	if( TF2_GetPlayerClass(client) == TFClass_Unknown )
		ShowVGUIPanel(client, "class_red");
}

// moves players to spectator
void MovePlayerToSpec(int client)
{
	if(IsFakeClient(client))
		return;

	StopRobotLoopSound(client);
	ScalePlayerModel(client, 1.0);
	ResetRobotData(client, true);
	SetVariantString( "" );
	AcceptEntityInput( client, "SetCustomModel" );
	SetEntProp( client, Prop_Send, "m_nBotSkill", BotSkill_Easy );
	SetEntProp( client, Prop_Send, "m_bIsMiniBoss", 0 );
	LogMessage("Player \"%L\" joined SPECTATOR team.", client);
	TF2_ChangeClientTeam(client, TFTeam_Spectator);
}

// moves player to BLU team.
void MovePlayerToBLU(int client)
{
	if(IsFakeClient(client))
		return;

	StopRobotLoopSound(client);
	ForcePlayerSuicide(client);
	SetEntProp( client, Prop_Send, "m_nBotSkill", BotSkill_Easy );
	SetEntProp( client, Prop_Send, "m_bIsMiniBoss", 0 );
	
	int iEntFlags = GetEntityFlags( client );
	SetEntityFlags( client, iEntFlags | FL_FAKECLIENT );
	TF2_ChangeClientTeam(client, TFTeam_Blue);
	SetEntityFlags( client, iEntFlags );
	LogMessage("Player \"%L\" joined BLU team.", client);
	
	ScalePlayerModel(client, 1.0);
	PickRandomRobot(client);
}

// returns the number of human players on BLU/ROBOT team
int GetHumanRobotCount()
{
	int count = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i))
		{			
			if(TF2_GetClientTeam(i) == TFTeam_Blue)
			{
				count++;
			}
		}
	}
	return count;
}



// updates array_avclass
// uses the data from tf_objective_resource to determine which classes should be available.
// use the function OR_Update to read the tf_objective_resource's data.
void UpdateClassArray()
{
	int iABots = OR_GetAvailableClasses();
	
	array_avclass.Clear();
	array_avgiants.Clear();
	
	if(iABots & scout_normal) // scout
	{
		array_avclass.Push(1); // this number is the same as TFClassType enum
	}
	if(iABots & soldier_normal) // soldier
	{
		array_avclass.Push(3);
	}
	if(iABots & pyro_normal) // pyro
	{
		array_avclass.Push(7);
	}
	if(iABots & demoman_normal) // demoman
	{
		array_avclass.Push(4);
	}
	if(iABots & heavy_normal) // heavy
	{
		array_avclass.Push(6);
	}
	if(iABots & engineer_normal) // engineer
	{
		array_avclass.Push(9);
	}
	if(iABots & medic_normal) // medic
	{
		array_avclass.Push(5);
	}
	if(iABots & sniper_normal) // sniper
	{
		array_avclass.Push(2);
	}
	if(iABots & spy_normal) // spy
	{
		array_avclass.Push(8);
	}
	
	// Giants
	if(iABots & scout_giant) // scout
	{
		array_avgiants.Push(1); // this number is the same as TFClassType enum
	}
	if(iABots & soldier_giant) // soldier
	{
		array_avgiants.Push(3);
	}
	if(iABots & pyro_giant) // pyro
	{
		array_avgiants.Push(7);
	}
	if(iABots & demoman_giant) // demoman
	{
		array_avgiants.Push(4);
	}
	if(iABots & heavy_giant) // heavy
	{
		array_avgiants.Push(6);
	}
	if(iABots & engineer_giant) // engineer
	{
		array_avgiants.Push(9);
	}
	if(iABots & medic_giant) // medic
	{
		array_avgiants.Push(5);
	}
	if(iABots & sniper_giant) // sniper
	{
		array_avgiants.Push(2);
	}
	if(iABots & spy_giant) // spy
	{
		array_avgiants.Push(8);
	}
}

// returns true if the specified class is available for the current wave
bool IsClassAvailable(TFClassType TFClass, bool bGiants = false)
{
	if( array_avclass.Length < 1 )
		return false;
		
	// Class limit disabled
	if( !c_bLimitClasses.BoolValue )
		return true;
		
	int iClass = view_as<int>(TFClass);
	
	if(bGiants)
	{
		if( array_avgiants.FindValue(iClass) != -1 )
			return true;
	}
	else
	{
		if( array_avclass.FindValue(iClass) != -1 )
			return true;
	}

	return false;	
}

// ***ROBOT VARIANT***
// Selects a random robot for the given client.
void PickRandomRobot(int client)
{
	if(!IsClientInGame(client) || IsFakeClient(client))
		return;
	
	int iSize, iRandom, iClass;
	bool bGiants = false;
	
	// First, check if we can spawn a buster or a boss robot.
	if(GameRules_GetRoundState() == RoundState_RoundRunning)
	{
		// Boss
		Boss_Think(); // Boss think function
		
		if( CheckCommandAccess(client, "bwrr_boss", 0) && Boss_CanSpawn() )
		{
			Boss_SetupPlayer(client);
			CreateTimer(0.1, Timer_SetRobotClass, client);
			return;
		}
	
		// Check cooldown, spawn conditions and permission
		if( GetGameTime() > g_flNextBusterTime && ShouldDispatchSentryBuster() && CheckCommandAccess(client, "bwrr_sentrybuster", 0) )
		{
			p_BotClass[client] = TFClass_DemoMan;
			p_iBotVariant[client] = 0;
			p_iBotType[client] = Bot_Buster;
			p_iBotAttrib[client] = BotAttrib_CannotCarryBomb;
			g_flNextBusterTime = GetGameTime() + c_flBusterDelay.FloatValue;
			g_iBusterIndex = client;
			CreateTimer(0.1, Timer_SetRobotClass, client);
			return;
		}
	}
	
	// Checks if giants are allowed.
	if( OR_IsGiantAvaiable && GetRandomInt(0, 100) <= c_iGiantChance.IntValue && GetTeamClientCount(2) >= c_iGiantMinRed.IntValue && array_avgiants.Length >= 1 )
	{
		bGiants = true;
	}
	
	if( array_avgiants.Length >= 1 && array_avclass.Length < 1 ) // Normal robots not available for the current wave.
		bGiants = true;
	
	if( bGiants && c_bLimitClasses.BoolValue ) // Spawn the player as a giant robot.
	{
		iSize = GetArraySize(array_avgiants) - 1;
		iRandom = GetRandomInt(0, iSize);
		iClass = array_avgiants.Get(iRandom);
	}
	else if( c_bLimitClasses.BoolValue ) // Spawn the player as a normal robot.
	{
		iSize = GetArraySize(array_avclass) - 1;
		iRandom = GetRandomInt(0, iSize);
		iClass = array_avclass.Get(iRandom);
	}
	else
	{
		iClass = GetRandomInt(1,9); // class limit disabled, pick a random one
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

	int iRandomMin = 0;
	
	if( CheckCommandAccess(client, "bwrr_ownloadout", 0) )
		iRandomMin = -1;
	
	CreateTimer(0.1, Timer_SetRobotClass, client);
	if( bGiants )
	{
		// giant
		p_iBotType[client] = Bot_Giant;
		switch( TFClass )
		{
			case TFClass_Scout:
			{
				p_iBotVariant[client] = GetRandomInt(iRandomMin, (RT_NumTemplates(true, TFClass) - 1));
				p_BotClass[client] = TFClass_Scout;
			}
			case TFClass_Soldier:
			{
				p_iBotVariant[client] = GetRandomInt(iRandomMin, (RT_NumTemplates(true, TFClass) - 1));
				p_BotClass[client] = TFClass_Soldier;
			}
			case TFClass_Pyro:
			{
				p_iBotVariant[client] = GetRandomInt(iRandomMin, (RT_NumTemplates(true, TFClass) - 1));
				p_BotClass[client] = TFClass_Pyro;
			}
			case TFClass_DemoMan:
			{
				p_iBotVariant[client] = GetRandomInt(iRandomMin, (RT_NumTemplates(true, TFClass) - 1));
				p_BotClass[client] = TFClass_DemoMan;
			}
			case TFClass_Heavy:
			{
				p_iBotVariant[client] = GetRandomInt(iRandomMin, (RT_NumTemplates(true, TFClass) - 1));
				p_BotClass[client] = TFClass_Heavy;
			}
			case TFClass_Engineer:
			{
				p_iBotVariant[client] = GetRandomInt(iRandomMin, (RT_NumTemplates(true, TFClass) - 1));
				p_BotClass[client] = TFClass_Engineer;
			}
			case TFClass_Medic:
			{
				p_iBotVariant[client] = GetRandomInt(iRandomMin, (RT_NumTemplates(true, TFClass) - 1));
				p_BotClass[client] = TFClass_Medic;
			}
			case TFClass_Sniper:
			{
				p_iBotVariant[client] = GetRandomInt(iRandomMin, (RT_NumTemplates(true, TFClass) - 1));
				p_BotClass[client] = TFClass_Sniper;
			}
			case TFClass_Spy:
			{
				p_iBotVariant[client] = GetRandomInt(iRandomMin, (RT_NumTemplates(true, TFClass) - 1));
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
				p_iBotVariant[client] = GetRandomInt(iRandomMin, (RT_NumTemplates(false, TFClass) - 1));
				p_BotClass[client] = TFClass_Scout;
			}
			case TFClass_Soldier:
			{
				p_iBotVariant[client] = GetRandomInt(iRandomMin, (RT_NumTemplates(false, TFClass) - 1));
				p_BotClass[client] = TFClass_Soldier;
			}
			case TFClass_Pyro:
			{
				p_iBotVariant[client] = GetRandomInt(iRandomMin, (RT_NumTemplates(false, TFClass) - 1));
				p_BotClass[client] = TFClass_Pyro;
			}
			case TFClass_DemoMan:
			{
				p_iBotVariant[client] = GetRandomInt(iRandomMin, (RT_NumTemplates(false, TFClass) - 1));
				p_BotClass[client] = TFClass_DemoMan;
			}
			case TFClass_Heavy:
			{
				p_iBotVariant[client] = GetRandomInt(iRandomMin, (RT_NumTemplates(false, TFClass) - 1));
				p_BotClass[client] = TFClass_Heavy;
			}
			case TFClass_Engineer:
			{
				p_iBotVariant[client] = GetRandomInt(iRandomMin, (RT_NumTemplates(false, TFClass) - 1));
				p_BotClass[client] = TFClass_Engineer;
			}
			case TFClass_Medic:
			{
				p_iBotVariant[client] = GetRandomInt(iRandomMin, (RT_NumTemplates(false, TFClass) - 1));
				p_BotClass[client] = TFClass_Medic;
			}
			case TFClass_Sniper:
			{
				p_iBotVariant[client] = GetRandomInt(iRandomMin, (RT_NumTemplates(false, TFClass) - 1));
				p_BotClass[client] = TFClass_Sniper;
			}
			case TFClass_Spy:
			{
				p_iBotVariant[client] = GetRandomInt(iRandomMin, (RT_NumTemplates(false, TFClass) - 1));
				p_BotClass[client] = TFClass_Spy;
			}
		}
		SetVariantExtras(client, TFClass, p_iBotVariant[client]);
	}
}

// Sets a specific robot on a player
void SetRobotOnPlayer(int client, int iVariant, int type, TFClassType TFClass)
{
	if(!IsValidClient(client) && !IsPlayerAlive(client))
		return;
		
	if(TF2_GetClientTeam(client) != TFTeam_Blue)
		return;
		
	if(type == Bot_Giant)
	{
		if(!IsValidVariant(true, TFClass, iVariant))
		{
			return;
		}
	}
	else
	{
		if(!IsValidVariant(false, TFClass, iVariant))
		{
			return;
		}
	}

	p_iBotType[client] = type;
	p_iBotVariant[client] = iVariant;
	p_BotClass[client] = TFClass;

	if(type == Bot_Giant)
		SetGiantVariantExtras(client, TFClass, iVariant);
	else
		SetVariantExtras(client, TFClass, iVariant);
		
	CreateTimer(0.1, Timer_SetRobotClass, client);
	CreateTimer(0.5, Timer_Respawn, client);
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
				if( iVariant >= -1 && iVariant <= (RT_NumTemplates(true, TFClass) - 1) ) // - 1 needed since arrays start with 0
					bValid = true;
			}
			else
			{
				if( iVariant >= -1 && iVariant <= (RT_NumTemplates(false, TFClass) - 1) )
					bValid = true;
			}
		}
		case TFClass_Soldier:
		{
			if( bGiants )
			{
				if( iVariant >= -1 && iVariant <= (RT_NumTemplates(true, TFClass) - 1) )
					bValid = true;
			}
			else
			{
				if( iVariant >= -1 && iVariant <= (RT_NumTemplates(false, TFClass) - 1) )
					bValid = true;
			}
		}
		case TFClass_Pyro:
		{
			if( bGiants )
			{
				if( iVariant >= -1 && iVariant <= (RT_NumTemplates(true, TFClass) - 1) )
					bValid = true;
			}
			else
			{
				if( iVariant >= -1 && iVariant <= (RT_NumTemplates(false, TFClass) - 1) )
					bValid = true;
			}
		}
		case TFClass_DemoMan:
		{
			if( bGiants )
			{
				if( iVariant >= -1 && iVariant <= (RT_NumTemplates(true, TFClass) - 1) )
					bValid = true;
			}
			else
			{
				if( iVariant >= -1 && iVariant <= (RT_NumTemplates(false, TFClass) - 1) )
					bValid = true;
			}
		}
		case TFClass_Heavy:
		{
			if( bGiants )
			{
				if( iVariant >= -1 && iVariant <= (RT_NumTemplates(true, TFClass) - 1) )
					bValid = true;
			}
			else
			{
				if( iVariant >= -1 && iVariant <= (RT_NumTemplates(false, TFClass) - 1) )
					bValid = true;
			}
		}
		case TFClass_Engineer:
		{
			if( bGiants )
			{
				if( iVariant >= -1 && iVariant <= (RT_NumTemplates(true, TFClass) - 1) )
					bValid = true;
			}
			else
			{
				if( iVariant >= -1 && iVariant <= (RT_NumTemplates(false, TFClass) - 1) )
					bValid = true;
			}
		}
		case TFClass_Medic:
		{
			if( bGiants )
			{
				if( iVariant >= -1 && iVariant <= (RT_NumTemplates(true, TFClass) - 1) )
					bValid = true;
			}
			else
			{
				if( iVariant >= -1 && iVariant <= (RT_NumTemplates(false, TFClass) - 1) )
					bValid = true;
			}
		}
		case TFClass_Sniper:
		{
			if( bGiants )
			{
				if( iVariant >= -1 && iVariant <= (RT_NumTemplates(true, TFClass) - 1) )
					bValid = true;
			}
			else
			{
				if( iVariant >= -1 && iVariant <= (RT_NumTemplates(false, TFClass) - 1) )
					bValid = true;
			}
		}
		case TFClass_Spy:
		{
			if( bGiants )
			{
				if( iVariant >= -1 && iVariant <= (RT_NumTemplates(true, TFClass) - 1) )
					bValid = true;
			}
			else
			{
				if( iVariant >= -1 && iVariant <= (RT_NumTemplates(false, TFClass) - 1) )
					bValid = true;
			}
		}
	}
	
	return bValid;
}

// Set attributes on the robots.
void SetVariantExtras(int client,TFClassType TFClass, int iVariant)
{
	p_iBotAttrib[client] = 0;
	
	if(iVariant < 0)
	{
		switch( TFClass )
		{
			case TFClass_Soldier:
			{
				p_iBotAttrib[client] |= BotAttrib_FullCharge;
			}
			case TFClass_Sniper:
			{
				p_iBotAttrib[client] |= BotAttrib_CannotCarryBomb;
			}
			case TFClass_Engineer:
			{
				p_iBotAttrib[client] |= (BotAttrib_CannotCarryBomb|BotAttrib_TeleportToHint);
			}
			case TFClass_Medic:
			{
				p_iBotAttrib[client] |= (BotAttrib_CannotCarryBomb|BotAttrib_FullCharge);
			}
			case TFClass_Spy:
			{
				p_iBotAttrib[client] |= (BotAttrib_CannotCarryBomb|BotAttrib_AutoDisguise);
			}
			default:
			{
				p_iBotAttrib[client] = 0;
			}
		}
		p_iBotType[client] = Bot_Normal;
		return;
	}

	int iRobotType = RT_GetType(TFClass, iVariant, 0);
	p_iBotAttrib[client] = RT_GetAttributesBits(TFClass, iVariant, 0);
	
	if(iRobotType < 0)
		iRobotType = 0;
	else if(iRobotType >= Bot_Giant)
		iRobotType = 0;
		
	p_iBotType[client] = iRobotType;
}

void SetGiantVariantExtras(int client,TFClassType TFClass, int iVariant)
{
	p_iBotAttrib[client] = 0;

	if(iVariant < 0)
	{
		switch( TFClass )
		{
			case TFClass_Soldier:
			{
				p_iBotAttrib[client] |= BotAttrib_FullCharge;
			}
			case TFClass_Sniper:
			{
				p_iBotAttrib[client] |= BotAttrib_CannotCarryBomb;
			}
			case TFClass_Engineer:
			{
				p_iBotAttrib[client] |= (BotAttrib_CannotCarryBomb|BotAttrib_TeleportToHint);
			}
			case TFClass_Medic:
			{
				p_iBotAttrib[client] |= (BotAttrib_CannotCarryBomb|BotAttrib_FullCharge);
			}
			case TFClass_Spy:
			{
				p_iBotAttrib[client] |= (BotAttrib_CannotCarryBomb|BotAttrib_AutoDisguise);
			}
			default:
			{
				p_iBotAttrib[client] = 0;
			}
		}
		p_iBotType[client] = Bot_Giant;
		return;
	}

	p_iBotAttrib[client] = RT_GetAttributesBits(TFClass, iVariant, 1);
}

// sets the player scale based on robot type
void SetRobotScale(int client, TFClassType TFClass)
{
	if( IsFakeClient(client) )
		return;

	bool bSmallMap = IsSmallMap();
	float flScale;
	
	// Check if a custom scale is set in the template files
	if( !bSmallMap && p_iBotVariant[client] >= 0 ) // not a small map
	{
		switch( p_iBotType[client] )
		{
			case Bot_Boss:
			{
				flScale = Boss_GetScale();
				if( flScale > 0.3 && flScale < 2.0) // limit custom scale between 0.3 and 2.0
				{
					ScalePlayerModel(client, flScale);
					return;
				}
			}
			case Bot_Giant:
			{
				flScale = RT_GetScale(TFClass, p_iBotVariant[client], 1);
				if( flScale > 0.3 && flScale < 2.0) // limit custom scale between 0.3 and 2.0
				{
					ScalePlayerModel(client, flScale);
					return;
				}
			}
			case Bot_Big, Bot_Small, Bot_Normal:
			{
				flScale = RT_GetScale(TFClass, p_iBotVariant[client], 0);
				if( flScale > 0.3 && flScale < 2.0) // limit custom scale between 0.3 and 2.0
				{
					ScalePlayerModel(client, flScale);
					return;
				}
			}
		}
	}
	
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
	p_bInSpawn[client] = false;
	g_bIsCarrier[client] = false;
	g_bUpgradeStation[client] = false;
	g_flLastForceBot[client] = GetEngineTime();
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
			FormatEx( strModel, sizeof( strModel ), "models/bots/demo/bot_sentry_buster.mdl" );
		}
		else
		{
			Format( strModel, sizeof( strModel ), "models/bots/%s/bot_%s.mdl", strModel, strModel );
		}
		
		if( OR_IsHalloweenMission() && p_iBotType[client] != Bot_Buster )
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
	{
		if( GetEntProp( iEnt, Prop_Send, "m_iTeamNum" ) == view_as<int>(TFTeam_Blue) && GetEntProp( iEnt, Prop_Data, "m_bDisabled" ) == 0 ) // ignore disabled spawn points
		{
			GetEntPropString( iEnt, Prop_Data, "m_iName", strSpawnName, sizeof(strSpawnName) );
			
			switch( iType )
			{
				case Spawn_Normal:
				{
					for(int i = 0;i < g_iSplitSize[0];i++)
					{
						if( strcmp( strSpawnName, g_strNormalSplit[i] ) == 0 )
						{
							array_spawns.Push( iEnt );
						}
					}					
				}
				case Spawn_Giant, Spawn_Buster, Spawn_Boss:
				{
					for(int i = 0;i < g_iSplitSize[1];i++)
					{
						if( strcmp( strSpawnName, g_strGiantSplit[i] ) == 0 )
						{
							array_spawns.Push( iEnt );
						}
					}
				}
				case Spawn_Sniper:
				{
					for(int i = 0;i < g_iSplitSize[2];i++)
					{
						if( strcmp( strSpawnName, g_strSniperSplit[i] ) == 0 )
						{
							array_spawns.Push( iEnt );
						}
					}
				}
				case Spawn_Spy:
				{
					for(int i = 0;i < g_iSplitSize[3];i++)
					{
						if( strcmp( strSpawnName, g_strSpySplit[i] ) == 0 )
						{
							array_spawns.Push( iEnt );
						}
					}				
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
			iTarget = GetRandomBLUPlayer();
			if( iTarget > 0 )
			{
				MovePlayerToRED(iTarget);
				CPrintToChat(iTarget, "%t", "Moved Blu Full");
				LogAction(iTarget, -1, "\"%L\" was moved to RED (full)", iTarget);
			}
		}
	}
	if( bAutoBalance )
	{
		// if the number of players in RED is less than the minimum to join BLU
		if( (iInRed + 1) < c_iMinRed.IntValue && iInBlu > 0 )
		{
			int iCount = c_iMinRed.IntValue - (iInRed + 1);
			if( iCount < c_iMinRed.IntValue )
				LogMessage("Auto Balancing teams. Count: %i, In RED: %i, In BLU: %i", iCount, iInRed, iInBlu);
			
			for( int i = 1; i <= iCount; i++ )
			{
				iTarget = GetRandomBLUPlayer();
				if( iTarget > 0 )
				{
					MovePlayerToRED(iTarget);
					CPrintToChat(iTarget, "%t", "Moved Blu Balance");
					LogAction(iTarget, -1, "\"%L\" was moved to RED (auto team balance)", iTarget);
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
	CreateTimer(0.5, Timer_ApplyRobotSound, client, TIMER_FLAG_NO_MAPCHANGE);
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
			if( TF2_GetClientTeam(i) == TFTeam_Blue )
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

// Allows all players to use sm_robotmenu again
void ResetRobotMenuCooldown()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		g_flLastForceBot[i] = 0.0;
	}
}