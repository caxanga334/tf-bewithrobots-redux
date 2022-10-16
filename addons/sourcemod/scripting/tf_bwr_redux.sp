#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <autoexecconfig>
#include <multicolors>
#define REQUIRE_PLUGIN
#include <tf2attributes>
#include <tf2wearables>
#undef REQUIRE_EXTENSIONS
#include <steamworks>
#define REQUIRE_EXTENSIONS
#define AUTOLOAD_EXTENSIONS
#include <sdkhooks>
#include <tf2items>
#include <dhooks>

// debug
//#define DEBUG_PLAYER // player related debug 
//#define DEBUG_GENERAL // general debug
//#define DEBUG_CRASHFIX // crash fixes debug
// visible weapons?
//#define VISIBLE_WEAPONS

#define PLUGIN_VERSION "1.3.0-32ply"

// giant sounds
#define ROBOT_SND_GIANT_SCOUT "mvm/giant_scout/giant_scout_loop.wav"
#define ROBOT_SND_GIANT_SOLDIER "mvm/giant_soldier/giant_soldier_loop.wav"
#define ROBOT_SND_GIANT_PYRO "mvm/giant_pyro/giant_pyro_loop.wav"
#define ROBOT_SND_GIANT_DEMOMAN "mvm/giant_demoman/giant_demoman_loop.wav"
#define ROBOT_SND_GIANT_HEAVY ")mvm/giant_heavy/giant_heavy_loop.wav"
#define ROBOT_SND_SENTRY_BUSTER "mvm/sentrybuster/mvm_sentrybuster_loop.wav"

#define TF_CURRENCY_PACK_CUSTOM 9

// player robot variants prefix: p_
int p_iBotType[MAXPLAYERS + 1]; // Robot type
int p_iBotVariant[MAXPLAYERS + 1]; // Robot variant
int p_iBotAttrib[MAXPLAYERS + 1]; // Special robot attributes
TFClassType p_BotClass[MAXPLAYERS + 1]; // Robot class
bool p_bInSpawn[MAXPLAYERS + 1]; // Local cache to know if a player is in spawn
bool p_bIsGatebot[MAXPLAYERS + 1]; // Is the player a gatebot
bool p_bIsReloadingBarrage[MAXPLAYERS + 1]; // Is loading a barrage?
bool p_bIsBusterDetonating[MAXPLAYERS + 1]; // Is the sentry buster detonating?
float p_flProtTime[MAXPLAYERS + 1]; // Spawn protection timer
float p_flBusterTimer[MAXPLAYERS + 1]; // Sentry Buster detonation control timer

// bomb
bool g_bIsCarrier[MAXPLAYERS + 1]; // true if the player is carrying the bomb
bool g_bIsDeploying[MAXPLAYERS + 1]; // Is the player deploying the bomb?
int g_iBombCarrierUpgradeLevel[MAXPLAYERS + 1]; // Bomb upgrade level
float g_flNextBombUpgradeTime[MAXPLAYERS + 1]; // Bomb upgrade timer
float g_flBombDeployTime[MAXPLAYERS + 1]; // Bomb deploy timer

ArrayList array_avclass; // array containing available classes
ArrayList array_avgiants; // array containing available giant classes

// others
bool g_bUpgradeStation[MAXPLAYERS + 1]; // Player touched upgrade station
bool g_bBotMenuIsGiant[MAXPLAYERS + 1]; // Player selected a giant robot on sm_robotmenu
bool g_bWelcomeMsg[MAXPLAYERS + 1]; // Did we show the welcome message?
bool g_bLateLoad; // Late load check
bool g_bFreezePlayers; // Should we freeze BLU players?
float g_flNextBusterTime; // sentry buster time
float g_flLastForceBot[MAXPLAYERS + 1]; // Last time a player forced a bot
float g_flBusterVisionTimer; // timer for buster wallhack
float g_flinstructiontime[MAXPLAYERS + 1]; // Last time we gave an instruction to a player 
float g_flJoinRobotBanTime[MAXPLAYERS + 1]; // Join blu/robot ban time
float g_flNextCommand[MAXPLAYERS + 1]; // delayed command timer
TFClassType g_BotMenuSelectedClass[MAXPLAYERS + 1]; // the class the player selected on sm_robotmenu
Handle g_hHUDReload;

char g_strModelRobots[][] = {"", "models/bots/scout/bot_scout.mdl", "models/bots/sniper/bot_sniper.mdl", "models/bots/soldier/bot_soldier.mdl", "models/bots/demo/bot_demo.mdl", "models/bots/medic/bot_medic.mdl", "models/bots/heavy/bot_heavy.mdl", "models/bots/pyro/bot_pyro.mdl", "models/bots/spy/bot_spy.mdl", "models/bots/engineer/bot_engineer.mdl"};
int g_iModelIndexRobots[sizeof(g_strModelRobots)];
char g_strModelHumans[][] =  {"", "models/player/scout.mdl", "models/player/sniper.mdl", "models/player/soldier.mdl", "models/player/demo.mdl", "models/player/medic.mdl", "models/player/heavy.mdl", "models/player/pyro.mdl", "models/player/spy.mdl", "models/player/engineer.mdl"};
int g_iModelIndexHumans[sizeof(g_strModelHumans)];

// gatebot
float g_flGateStunTime;

int g_iLaserSprite;
int g_iHaloSprite;
bool g_bPluginError; // Allows the plugin to soft fail

// convars
ConVar c_PluginVersion; // Plugin version
ConVar c_iMinRed; // minimum red players to join BLU
ConVar c_iMinRedinProg; // minimum red players to join BLU while the wave is in progress.
ConVar c_iGiantChance; // change to spawn as a giant robot
ConVar c_iGiantMinRed; // minimum red players to allow giants.
ConVar c_iMaxBlu; // maximum blu players allowed
ConVar c_bAutoTeamBalance; // Is Auto team balance enabled?
ConVar c_flBusterDelay; // delay between human sentry buster spawns.
ConVar c_iBusterMinKills; // minimum amount of kills a sentry needs to have before becoming a threat
ConVar c_svTag; // server tags
ConVar c_flForceDelay; // Delay between force bot command usage
ConVar c_flFDGiant; // Extra delay added when the forced bot is a giant
ConVar c_strNBFile; // Normal bot template file
ConVar c_strGBFile; // Giant bot template file
ConVar c_bLimitClasses; // Limit playable classes to the ones used in the current wave
ConVar c_iGatebotChance; // change to spawn as a gatebot
ConVar c_bAntiJoinSpam; // Anti-spam
ConVar c_fl666CritChance; // Wave 666 100% Crits chance.
ConVar c_flBluProtectionTime; // How many seconds of spawn protection human BLU players have
ConVar c_strBusterProfiles; // List of sentry busters profiles to load.
ConVar c_bFixSpawnHole; // Create additional func_respawnroom to fix holes
ConVar c_bDropCurrency; // Should human players drop currency when killed
ConVar c_b32PlayersEnabled; // 32 Player mode enabled

// user messages
UserMsg ID_MVMResetUpgrade = INVALID_MESSAGE_ID;

// SDK
Handle g_hSDKPlaySpecificSequence;
Handle g_hSDKDispatchParticleEffect;
Handle g_hSDKPointIsWithin;
Handle g_hGetEventChangeAttributes;
Handle g_hSDKWorldSpaceCenter;
Handle g_hCFilterTFBotHasTag;
Handle g_hSDKRemoveObject;
Handle g_hSDKGetMaxClip;
Handle g_hSDKGetClip;
Handle g_hSDKIsFlagHome;
Handle g_hSDKPickupFlag;
Handle g_hCTFPlayerShouldGib;
Handle g_hSDKSpeakConcept;
Handle g_hCTFPLayerCanBeForcedToLaugh;
Handle g_hSDKPushAwayPlayers;
Handle g_hSDKDropCurrency;
Handle g_hSDKPointInRespawnRoom;
//Handle g_hSDKCTFPlayerCanBuild;
//Handle g_hCTeamGetNumPlayers;

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
	BotAttrib_AlwaysCrits = (1 << 0), // 100% crit chance
	BotAttrib_FullCharge = (1 << 1), // spawns with full charge (medic, soldier buff)
	BotAttrib_InfiniteCloak = (1 << 2), // Spies never run out of cloak
	BotAttrib_AutoDisguise = (1 << 3), // Automatically give a disguise to the spy
	BotAttrib_AlwaysMiniCrits = (1 << 4), // 100% minicrit chance
	BotAttrib_TeleportToHint = (1 << 5), // teleport engineers to a nest near the bomb.
	BotAttrib_CannotCarryBomb = (1 << 6), // Blocks players from carrying the bomb
	BotAttrib_CannotBuildTele = (1 << 7), // disallow engineers to build teleporters
	BotAttrib_HoldFireFullReload = (1 << 8), // Waits until the weapon is fully loaded to fire again
	BotAttrib_AlwaysFireWeapon = (1 << 9), // Always fire weapon
	BotAttrib_IgniteOnHit = (1 << 10), // Ignite players when hit
	BotAttrib_StunOnHit = (1 << 11), // Stuns players when hit
	BotAttrib_BulletImmune = (1 << 12), // Applies TFCond_BulletImmune to the client
	BotAttrib_BlastImmune = (1 << 13), // Applies TFCond_BlastImmune to the client
	BotAttrib_FireImmune = (1 << 14), // Applies TFCond_FireImmune to the client
	BotAttrib_BonkNerf = (1 << 15), // Nerf scout's energy drink when deploying the bomb
	BotAttrib_DestroyBuildings = (1 << 16), // Destroy engineer's building on death
};

#define BOTATTRIB_MAX 17

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

// Build checks will return one of these for a player

enum
{
	CB_CAN_BUILD = 0,		// Player is allowed to build this object
	CB_CANNOT_BUILD,		// Player is not allowed to build this object
	CB_LIMIT_REACHED,		// Player has reached the limit of the number of these objects allowed
	CB_NEED_RESOURCES,		// Player doesn't have enough resources to build this object
	CB_NEED_ADRENALIN,		// Commando doesn't have enough adrenalin to build a rally flag
	CB_UNKNOWN_OBJECT,		// Error message, tried to build unknown object
};

enum struct eDisguisedStruct
{
	int g_iDisguisedTeam; // The spy's disguised team
	int g_iDisguisedClass; // The spy's disguised class
}
eDisguisedStruct g_nDisguised[MAXPLAYERS+1];

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
	property float ProtectionTime
	{
		public get() { return p_flProtTime[this.index]; }
		public set( float value ) { p_flProtTime[this.index] = value; }
	}
	property float BusterTime
	{
		public get() { return p_flBusterTimer[this.index]; }
		public set( float value ) { p_flBusterTimer[this.index] = value; }
	}
	property float DeployTime
	{
		public get() { return g_flBombDeployTime[this.index]; }
		public set( float value ) { g_flBombDeployTime[this.index] = value; }
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
	property bool Gatebot
	{
		public get() { return p_bIsGatebot[this.index]; }
		public set( bool value ) { p_bIsGatebot[this.index] = value; }
	}
	property bool ReloadingBarrage
	{
		public get() { return p_bIsReloadingBarrage[this.index]; }
		public set( bool value ) { p_bIsReloadingBarrage[this.index] = value; }
	}
	property bool Deploying
	{
		public get() { return g_bIsDeploying[this.index]; }
		public set( bool value ) { g_bIsDeploying[this.index] = value; }
	}
	property bool Detonating
	{
		public get() { return p_bIsBusterDetonating[this.index]; }
		public set( bool value ) { p_bIsBusterDetonating[this.index] = value; }
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
#include "bwrredux/buster.sp"
#include "bwrredux/experimental.sp"

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
	g_bLateLoad = late;
	
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
	// Sets the file for the include, must be done before using most other functions
	// The .cfg file extension can be left off
	AutoExecConfig_SetFile("plugin.bwrredux");

	// convars
	c_PluginVersion = CreateConVar("sm_bwrr_version", PLUGIN_VERSION, "Be With Robots: Redux plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	c_iMinRed = AutoExecConfig_CreateConVar("sm_bwrr_minred", "5", "Minimum amount of players on RED team to allow joining ROBOTs.", FCVAR_NONE, true, 0.0, true, 10.0);
	c_iMinRedinProg = AutoExecConfig_CreateConVar("sm_bwrr_minred_inprog", "7", "Minimum amount of players on RED team to allow joining ROBOTs while the wave is in progress.", FCVAR_NONE, true, 0.0, true, 10.0);
	c_iGiantChance = AutoExecConfig_CreateConVar("sm_bwrr_giantchance", "30", "Chance in percentage to human players to spawn as a giant. 0 = Disabled.", FCVAR_NONE, true, 0.0, true, 100.0);
	c_iGiantMinRed = AutoExecConfig_CreateConVar("sm_bwrr_giantminred", "5", "Minimum amount of players on RED team to allow human giants. 0 = Disabled.", FCVAR_NONE, true, 0.0, true, 8.0);
	c_iMaxBlu = AutoExecConfig_CreateConVar("sm_bwrr_maxblu", "4", "Maximum amount of players in BLU team.", FCVAR_NONE, true, 1.0, true, 30.0);
	c_bAutoTeamBalance = AutoExecConfig_CreateConVar("sm_bwrr_autoteambalance", "1", "Balance teams at wave start?", FCVAR_NONE, true, 0.0, true, 1.0);
	c_flBusterDelay = AutoExecConfig_CreateConVar("sm_bwrr_sentry_buster_delay", "60.0", "Delay between human sentry buster spawn.", FCVAR_NONE, true, 30.0, true, 1200.0);
	c_iBusterMinKills = AutoExecConfig_CreateConVar("sm_bwrr_sentry_buster_minkills", "15", "Minimum amount of kills a sentry gun must have to become a threat.", FCVAR_NONE, true, 5.0, true, 50.0);
	c_flForceDelay = AutoExecConfig_CreateConVar("sm_bwrr_force_delay", "30.0", "Base delay for sm_robotmenu usage (Normal Robots).", FCVAR_NONE, true, 1.0, true, 600.0);
	c_flFDGiant = AutoExecConfig_CreateConVar("sm_bwrr_force_giant_delay", "60.0", "Base delay for sm_robotmenu usage (Giant Robots).", FCVAR_NONE, true, 1.0, true, 600.0);
	c_strNBFile = AutoExecConfig_CreateConVar("sm_bwrr_botnormal_file", "robots_normal.cfg", "The file to load normal robots templates from. The file name length (including extension) must not exceed 32 characters.", FCVAR_NONE);
	c_strGBFile = AutoExecConfig_CreateConVar("sm_bwrr_botgiant_file", "robots_giant.cfg", "The file to load giant robots templates from. The file name length (including extension) must not exceed 32 characters.", FCVAR_NONE);
	c_bLimitClasses = AutoExecConfig_CreateConVar("sm_bwrr_limit_classes", "1", "Limit playable classes on the BLU team to classes that are used in the current wave", FCVAR_NONE, true, 0.0, true, 1.0);
	c_iGatebotChance = AutoExecConfig_CreateConVar("sm_bwrr_gatebot_chance", "25", "Chance to spawn as a gatebot on gate maps. 0 = Disabled.", FCVAR_NONE, true, 0.0, true, 100.0);
	c_bAntiJoinSpam = AutoExecConfig_CreateConVar("sm_bwrr_antispam", "1.0", "Enables/Disables the cooldown system on the join BLU command. 1 = Enabled, 0 = Disabled.", FCVAR_NONE, true, 0.0, true, 1.0);
	c_fl666CritChance = AutoExecConfig_CreateConVar("sm_bwrr_wave666_fullcrit_chance", "75.0", "Chance to spawn with full crits on Wave 666 missions.", FCVAR_NONE, true, 0.0, true, 100.0);
	c_flBluProtectionTime = AutoExecConfig_CreateConVar("sm_bwrr_blu_spawnprotection_time", "60.0", "How many seconds of spawn protection human BLU players have.", FCVAR_NONE, true, 60.0, true, 300.0);
	c_strBusterProfiles = AutoExecConfig_CreateConVar("sm_bwrr_sentry_buster_profiles", "valve", "List of sentry busters profiles to load separated by comma.", FCVAR_NONE);
	c_bFixSpawnHole = AutoExecConfig_CreateConVar("sm_bwrr_fix_spawnroom_holes", "1.0", "Should the plugin create func_respawnroom to fix holes?", FCVAR_NONE, true, 0.0, true, 1.0);
	c_bDropCurrency = AutoExecConfig_CreateConVar("sm_bwrr_spawn_currency", "1.0", "Should the plugin spawn currency when human BLU players are killed.", FCVAR_NONE, true, 0.0, true, 1.0);
	c_b32PlayersEnabled = AutoExecConfig_CreateConVar("sm_bwrr_experimental_32players_enabled", "0", "Enables the experimental 32 players support.", FCVAR_NOTIFY, true, 0.0, true, 1.0);

	
	// Uses AutoExecConfig internally using the file set by AutoExecConfig_SetFile
	AutoExecConfig_ExecuteFile();
	
	// Cleaning is an optional operation that removes whitespaces that might have been introduced and formats the file in a certain way
	// It is an expensive operation (file operations is relatively slow) and should be done at the end when the file will not be written to anymore
	AutoExecConfig_CleanFile();
	
	// Add Changehook
	c_strNBFile.AddChangeHook(OnRobotTemplateFileChanged);
	c_strGBFile.AddChangeHook(OnRobotTemplateFileChanged);
	
	c_svTag = FindConVar("sv_tags");
	
	// convar hooks
	if(c_svTag != null)
	{
		c_svTag.AddChangeHook(OnTagsChanged);
	}
	
	// translations
	LoadTranslations("bwrredux.phrases");
	LoadTranslations("common.phrases");
	
	// commands
	RegConsoleCmd("sm_joinred", Command_JoinRED, "Joins RED team.");
	RegConsoleCmd("sm_joinblu", Command_JoinBLU, "Joins BLU/Robot team.");
	RegConsoleCmd("sm_joinblue", Command_JoinBLU, "Joins BLU/Robot team.");
	RegConsoleCmd("sm_bwr", Command_JoinBLU, "Joins BLU/Robot team.");
	RegConsoleCmd("sm_bewithrobots", Command_JoinBLU, "Joins BLU/Robot team.");
	RegConsoleCmd("sm_robotclass", Command_BotClass, "Changes your robot variant.");
	RegConsoleCmd("sm_rc", Command_BotClass, "Changes your robot variant.");
	RegConsoleCmd("sm_bwrr_players", Command_ShowPlayers, "Shows the players in each team");
	RegConsoleCmd("sm_robotinfo", Command_RobotInfo, "Prints information about a specific robot");
	RegConsoleCmd("sm_waveinfo", Command_WaveInfo, "Prints information about the current wave.");
	RegConsoleCmd("sm_bossinfo", Command_BossInfo, "Prints information about the current boss.");
	RegConsoleCmd("sm_robotmenu", Command_RobotMenu, "Opens the robot selection menu.");
	RegConsoleCmd("sm_rm", Command_RobotMenu, "Opens the robot selection menu.");
	RegConsoleCmd("sm_bwrrhelp", Command_BWRRHelpMenu, "Opens the Be With Robots Redux help menu.");
	RegAdminCmd("sm_bwrr_debug", Command_Debug, ADMFLAG_ROOT, "Prints some debug messages.");
	RegAdminCmd("sm_bwrr_debug_spy", Command_Debug_Spy, ADMFLAG_ROOT, "Debug spy teleport.");
	RegAdminCmd("sm_bwrr_debug_spytrace", Command_Debug_Spy_Trace, ADMFLAG_ROOT, "Debug spy teleport trace LOS check.");
	RegAdminCmd("sm_bwrr_debug_engy", Command_Debug_Engy, ADMFLAG_ROOT, "Debug engineer teleport.");
	RegAdminCmd("sm_bwrr_show_teleport_positions", Command_Show_Tele_Pos, ADMFLAG_ROOT, "Shows positions where spies and engineers are teleported.");
	RegAdminCmd("sm_bwrr_show_spawn_points", Command_Show_SpawnPoints, ADMFLAG_ROOT, "Shows spawn points in the map.");
	RegAdminCmd("sm_bwrr_tracehull", Command_TraceHull, ADMFLAG_ROOT, "Performs a trace hull in your current position");
	RegAdminCmd("sm_bwrr_forcebot", Command_ForceBot, ADMFLAG_ROOT, "Forces a specific robot variant on the target.");
	RegAdminCmd("sm_bwrr_forceboss", Command_ForceBoss, ADMFLAG_ROOT, "Forces a specific boss on the target.");
	RegAdminCmd("sm_bwrr_move", Command_MoveTeam, ADMFLAG_BAN, "Changes the target player team.");
	RegAdminCmd("sm_bwrr_getorigin", Command_GetOrigin, ADMFLAG_ROOT, "Prints your current coordinates.");
	RegAdminCmd("sm_bwrr_editor", Command_Editor, ADMFLAG_ROOT, "Opens the editor.");
	RegAdminCmd("sm_bwrr_reload", Command_Reload, ADMFLAG_ROOT, "Reloads the map config.");
	RegAdminCmd("sm_bwrr_add_cooldown", Command_BanBLU, ADMFLAG_BAN, "Add joinblu cooldown to the target.");
	
	// listener
	AddCommandListener(Listener_JoinTeam, "jointeam");
	AddCommandListener(Listener_Ready, "tournament_player_readystate");
	AddCommandListener(Listener_Suicide, "kill");
	AddCommandListener(Listener_Suicide, "explode");
	AddCommandListener(Listener_Suicide, "dropitem"); // not a suicide command but same blocking rule
	AddCommandListener(Listener_Suicide, "td_buyback"); // not a suicide command but same blocking rule
	AddCommandListener(Listener_Build, "build");
	AddCommandListener(Listener_CallVote, "callvote");
	AddCommandListener(Listener_Taunt, "taunt");
	AddCommandListener(Listener_Taunt, "+taunt");
	
	
	// EVENTS
	HookEvent("mvm_begin_wave", E_WaveStart);
	HookEvent("mvm_wave_complete", E_WaveEnd);
	HookEvent("mvm_wave_failed", E_WaveFailed);
	HookEvent("mvm_mission_complete", E_MissionComplete);
	HookEvent("player_changeclass", E_ChangeClass);
	HookEvent("player_death", E_PlayerDeath);
	HookEvent("player_death", E_Pre_PlayerDeath, EventHookMode_Pre);
	HookEvent("player_spawn", E_Pre_PlayerSpawn, EventHookMode_Pre);
	HookEvent("player_spawn", E_PlayerSpawn);
	HookEvent("teamplay_flag_event", E_Teamplay_Flag);
	HookEvent("post_inventory_application", E_Inventory);
	HookEvent("player_builtobject", E_BuildObject, EventHookMode_Pre);
	HookEvent("pve_win_panel", E_MVM_WinPanel);
	
	// Entities
	HookEntityOutput("team_control_point", "OnCapTeam1", OnGateCaptureRED);
	HookEntityOutput("team_control_point", "OnCapTeam2", OnGateCaptureBLU);
	
	// User messages
	
	ID_MVMResetUpgrade = GetUserMessageId("MVMResetPlayerUpgradeSpending");
	if(ID_MVMResetUpgrade == INVALID_MESSAGE_ID) {
		LogError("Unable to hook user message.");
	}
	HookUserMessage(ID_MVMResetUpgrade, MsgHook_MVMRespec);
	
	// SDK calls
	
	Handle hConf = LoadGameConfigFile("tf2.bwrr");
	bool sigfailure;
	
	if( hConf == null ) { SetFailState("Failed to load gamedata file tf2.bwrr.txt"); }
	
	// bool CTFPlayer::PlaySpecificSequence( const char *pAnimationName )
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hConf, SDKConf_Signature, "CTFPlayer::PlaySpecificSequence");
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);		//Sequence name
	if((g_hSDKPlaySpecificSequence = EndPrepSDKCall()) == null) { LogError("Failed to create SDKCall for CTFPlayer::PlaySpecificSequence signature!"); sigfailure = true; }
	
	//This call will play a particle effect
	StartPrepSDKCall(SDKCall_Static);
	PrepSDKCall_SetFromConf(hConf, SDKConf_Signature, "DispatchParticleEffect");
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);		//pszParticleName
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);	//iAttachType
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);	//pEntity
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);		//pszAttachmentName
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);			//bResetAllParticlesOnEntity 
	if((g_hSDKDispatchParticleEffect = EndPrepSDKCall()) == null) { LogError("Failed to create SDKCall for DispatchParticleEffect signature!"); sigfailure = true; }
	
	// This allows us to check if a vector is within a cbasetrigger entity
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hConf, SDKConf_Signature, "CBaseTrigger::PointIsWithin");
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_Plain);
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
	if((g_hSDKPointIsWithin = EndPrepSDKCall()) == null) { LogError("Failed to create SDKCall for CBaseTrigger::PointIsWithin signature!"); sigfailure = true; }
	
	//This call is used to remove an objects owner
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hConf, SDKConf_Signature, "CTFPlayer::RemoveObject");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);	//CBaseObject
	if((g_hSDKRemoveObject = EndPrepSDKCall()) == null) { LogError("Failed To create SDKCall for CTFPlayer::RemoveObject signature!"); sigfailure = true; }
	
	// Used to get an entity center
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hConf, SDKConf_Virtual, "CBaseEntity::WorldSpaceCenter");
	PrepSDKCall_SetReturnInfo(SDKType_Vector, SDKPass_ByRef);
	if((g_hSDKWorldSpaceCenter = EndPrepSDKCall()) == null) { LogError("Failed to create SDKCall for CBaseEntity::WorldSpaceCenter offset!"); sigfailure = true; }
	
	// Used to check if the bomb is at home
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hConf, SDKConf_Signature, "CCaptureFlag::IsHome");
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_ByValue);
	if((g_hSDKIsFlagHome = EndPrepSDKCall()) == null) { LogError("Failed to create SDKCall for CCaptureFlag::IsHome signature!"); sigfailure = true; }
	
	// Make players speak concept
	StartPrepSDKCall(SDKCall_GameRules);
	PrepSDKCall_SetFromConf(hConf, SDKConf_Signature, "CMultiplayRules::HaveAllPlayersSpeakConceptIfAllowed");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain); // int iConcept
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain); // int iTeam
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer); // const char *modifiers
	if((g_hSDKSpeakConcept = EndPrepSDKCall()) == null) { LogError("Failed to create SDKCall for CMultiplayRules::HaveAllPlayersSpeakConceptIfAllowed signature!"); sigfailure = true; }
	
	// Push players away
	StartPrepSDKCall(SDKCall_GameRules);
	PrepSDKCall_SetFromConf(hConf, SDKConf_Signature, "CTFGameRules::PushAllPlayersAway");
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_Plain); // Vector& vFromThisPoint
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain); // float flRange
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain); // float flForce
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain); // int nTeam
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_ByValue); // CUtlVector< CTFPlayer* > *pPushedPlayers
	if((g_hSDKPushAwayPlayers = EndPrepSDKCall()) == null) { LogError("Failed to create SDKCall for CTFGameRules::PushAllPlayersAway signature!"); sigfailure = true; }
	
	// Drop currency
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hConf, SDKConf_Signature, "CTFPlayer::DropCurrencyPack");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_ByValue); // CurrencyRewards_t nSize
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain); // int nAmount
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain); // bool bForceDistribute
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer); // CBasePlayer* pMoneyMaker
	if((g_hSDKDropCurrency = EndPrepSDKCall()) == null) { LogError("Failed to create SDKCall for CTFPlayer::DropCurrencyPack signature!"); sigfailure = true; }
	
	//This call forces a player to pickup the intel
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hConf, SDKConf_Virtual, "CCaptureFlag::PickUp");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);	//CCaptureFlag
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);			//silent pickup? or maybe it doesnt exist im not sure.
	if((g_hSDKPickupFlag = EndPrepSDKCall()) == null) { LogError("Failed to create SDKCall for CCaptureFlag::PickUp offset!"); sigfailure = true; }

	// Checks if a point is inside a respawn room
	// PointInRespawnRoom(CBaseEntity const*,Vector const&,bool)
	StartPrepSDKCall(SDKCall_Static);
	PrepSDKCall_SetFromConf(hConf, SDKConf_Signature, "PointInRespawnRoom");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer, VDECODE_FLAG_ALLOWNULL);
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef, _, VENCODE_FLAG_COPYBACK);
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
	if((g_hSDKPointInRespawnRoom = EndPrepSDKCall()) == null) { LogError("Failed to create SDKCall for PointInRespawnRoom!"); sigfailure = true; }
	
	// Used to allow humans to capture gates
	int iOffset = GameConfGetOffset(hConf, "CFilterTFBotHasTag::PassesFilterImpl");	
	if(iOffset == -1) { LogError("Failed to get offset of CFilterTFBotHasTag::PassesFilterImpl"); sigfailure = true; }
	g_hCFilterTFBotHasTag = DHookCreate(iOffset, HookType_Entity, ReturnType_Bool, ThisPointer_CBaseEntity, CFilterTFBotHasTag);
	DHookAddParam(g_hCFilterTFBotHasTag, HookParamType_CBaseEntity);	//Entity index of the entity using the filter
	DHookAddParam(g_hCFilterTFBotHasTag, HookParamType_CBaseEntity);	//Entity index that triggered the filter
	
	iOffset = GameConfGetOffset(hConf, "CTFPlayer::ShouldGib");
	if(iOffset == -1) { SetFailState("Failed to get offset of CTFPlayer::ShouldGib"); }
	g_hCTFPlayerShouldGib = DHookCreate(iOffset, HookType_Entity, ReturnType_Bool, ThisPointer_CBaseEntity, CTFPlayer_ShouldGib);
	DHookAddParam(g_hCTFPlayerShouldGib, HookParamType_ObjectPtr, -1, DHookPass_ByRef);
	
	/**iOffset = GameConfGetOffset(hConf, "CTeam::GetNumPlayers");
	if(iOffset == -1) { SetFailState("Failed to get offset of CTeam::GetNumPlayers"); }
	g_hCTeamGetNumPlayers = DHookCreate(iOffset, HookType_Entity, ReturnType_Int, ThisPointer_CBaseEntity, CTeam_GetNumPlayers); **/
	
	//This call gets the maximum clip 1 of a weapon
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hConf, SDKConf_Virtual, "CTFWeaponBase::GetMaxClip1");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);	//Clip
	if((g_hSDKGetMaxClip = EndPrepSDKCall()) == null) { LogError("Failed to create SDKCall for CTFWeaponBase::GetMaxClip1 offset!"); sigfailure = true; }
	
	//This call gets clip 1 of a weapon
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hConf, SDKConf_Virtual, "CTFWeaponBase::Clip1");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);	//Clip
	if((g_hSDKGetClip = EndPrepSDKCall()) == null) { LogError("Failed to create SDKCall for CTFWeaponBase::GetMaxClip1 offset!"); sigfailure = true; }
	
	//CTFBot::GetEventChangeAttributes
	g_hGetEventChangeAttributes = DHookCreateDetour(Address_Null, CallConv_THISCALL, ReturnType_Int, ThisPointer_CBaseEntity);
	if(!g_hGetEventChangeAttributes) { SetFailState("Failed to setup detour for CTFBot::GetEventChangeAttributes"); }
	
	if(!DHookSetFromConf(g_hGetEventChangeAttributes, hConf, SDKConf_Signature, "CTFBot::GetEventChangeAttributes"))
	{
		LogError("Failed to load CTFBot::GetEventChangeAttributes signature from gamedata");
		sigfailure = true;
	}
	
	// HookParamType_Unknown
	DHookAddParam(g_hGetEventChangeAttributes, HookParamType_CharPtr);
	
	if(!DHookEnableDetour(g_hGetEventChangeAttributes, false, CTFBot_GetEventChangeAttributes)) { SetFailState("Failed to detour CTFBot::GetEventChangeAttributes."); }
	if(!DHookEnableDetour(g_hGetEventChangeAttributes, true, CTFBot_GetEventChangeAttributes_Post)) { SetFailState("Failed to detour CTFBot::GetEventChangeAttributes_Post."); }
	
	g_hCTFPLayerCanBeForcedToLaugh = DHookCreateDetour(Address_Null, CallConv_THISCALL, ReturnType_Bool, ThisPointer_CBaseEntity);
	if(!g_hCTFPLayerCanBeForcedToLaugh) { SetFailState("Failed to setup detour for CTFPlayer::CanBeForcedToLaugh"); }
	
	if(!DHookSetFromConf(g_hCTFPLayerCanBeForcedToLaugh, hConf, SDKConf_Signature, "CTFPlayer::CanBeForcedToLaugh"))
	{
		LogError("Failed to load CTFPlayer::CanBeForcedToLaugh signature from gamedata");
		sigfailure = true;
	}
	
	if(!DHookEnableDetour(g_hCTFPLayerCanBeForcedToLaugh, false, CTFPLayer_CanBeForcedToLaugh)) { SetFailState("Failed to detour CTFPlayer::CanBeForcedToLaugh"); }
	if(!DHookEnableDetour(g_hCTFPLayerCanBeForcedToLaugh, true, CTFPLayer_CanBeForcedToLaugh_Post)) { SetFailState("Failed to detour CTFPlayer::CanBeForcedToLaugh_Post"); }

	// CTFPlayer::CanBuild
/**	g_hSDKCTFPlayerCanBuild = DHookCreateDetour(Address_Null, CallConv_THISCALL, ReturnType_Int, ThisPointer_CBaseEntity);
	if(!g_hSDKCTFPlayerCanBuild) { SetFailState("Failed to setup detour for CTFPlayer::CanBuild"); }

	if(!DHookSetFromConf(g_hSDKCTFPlayerCanBuild, hConf, SDKConf_Signature, "CTFPlayer::CanBuild"))
	{
		LogError("Failed to load CTFPlayer::CanBuild signature from gamedata");
		sigfailure = true;
	}

	if(!DHookEnableDetour(g_hSDKCTFPlayerCanBuild, false, CTFPlayer_CanBuild)) { SetFailState("Failed to detour CTFPlayer::CanBuild"); }
	//if(!DHookEnableDetour(g_hSDKCTFPlayerCanBuild, false, CTFPlayer_CanBuild_Post)) { SetFailState("Failed to detour CTFPlayer::CanBuild_Post"); }
**/	
	delete hConf;
	
	if(sigfailure) { SetFailState("One or more signatures failed!"); }
	
#if defined DEBUG_GENERAL
	LogMessage("Finished loading signatures.");
#endif
	
	RT_InitArrays();
	Config_Init();
	Boss_InitArrays();
	Buster_InitArrays();
	
	array_avclass = new ArrayList(10);
	array_avgiants = new ArrayList(10);
	
	g_hHUDReload = CreateHudSynchronizer();
	
	if(g_bLateLoad)
	{
		LogMessage("Plugin was late loaded, changing level is recommended to fully load the plugin.");
		HookEntitiesOnLateLoad();
		for(int i = 1;i <=MaxClients;i++)
		{
			if(IsClientInGame(i))
			{
				OnClientPutInServer(i);
			}
		}
	}
}

void GetNormalBotTFile(char[] filename, int size)
{
	c_strNBFile.GetString(filename, size);
}

void GetGiantBotTFile(char[] filename, int size)
{
	c_strGBFile.GetString(filename, size);
}

void OnRobotTemplateFileChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	// Reload config files if the convar is changed.
	RT_ClearArrays();
	RT_LoadCfgNormal();
	RT_LoadCfgGiant();
	RT_PostLoad();	
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
	g_bPluginError = false;

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
	Config_LoadMap();
	
	array_avclass.Clear();
	array_avgiants.Clear();
	
	TF2_GetBombHatchPosition(true);
	g_flGateStunTime = 0.0;
	g_BossTimer = 0.0;
	g_flBusterVisionTimer = 0.0;
	g_bSkipSpawnRoom = false;
	BotNoticeBackstabChance(true);
	BotNoticeBackstabMaxRange(true);
	AnnounceBombDeployWarning(true);
	ComputeEngineerTeleportVectors();
	
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
	PrecacheSound("player/spy_shield_break.wav");
	PrecacheScriptSound("MVM.GiantHeavyEntrance");
	PrecacheScriptSound("MVM.Warning");
	PrecacheScriptSound("Announcer.MVM_Bomb_Alert_Deploying");
	g_iLaserSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
	g_iHaloSprite = PrecacheModel("materials/sprites/halo01.vmt");
	
	for(int x = 1;x < sizeof(g_iModelIndexHumans);x++) { g_iModelIndexHumans[x] = PrecacheModel(g_strModelHumans[x]); }
	for(int x = 1;x < sizeof(g_iModelIndexRobots);x++) { g_iModelIndexRobots[x] = PrecacheModel(g_strModelRobots[x]); }
	
	// Update plugin version convar
	c_PluginVersion.SetString(PLUGIN_VERSION);
}

public void TF2_OnWaitingForPlayersStart()
{
	AddAdditionalSpawnRooms();
	CreateTimer(1.0, Timer_CheckGates, _, TIMER_FLAG_NO_MAPCHANGE);
	g_bFreezePlayers = true;
	OR_Update();
	Boss_LoadWaveConfig();
	PushForcedClasses();
	UpdateClassArray();
}

public void TF2_OnWaitingForPlayersEnd()
{
	g_bFreezePlayers = false;
	for(int i = 1;i <= MaxClients;i++)
	{
		p_flProtTime[i] = GetGameTime() + c_flBluProtectionTime.FloatValue;
	}
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, SDKOnPlayerTakeDamage);
	DHookEntity(g_hCTFPlayerShouldGib, true, client);
	g_flinstructiontime[client] = 0.0;
	g_flJoinRobotBanTime[client] = 0.0;

	if (!IsFakeClient(client)) // Prevents infinite loop
	{
		CreateTimer(5.0, Timer_RemoveMvMBots, .flags = TIMER_FLAG_NO_MAPCHANGE);
	}
}

public void OnClientDisconnect(int client)
{
	ResetRobotData(client);
	StopRobotLoopSound(client);
	g_bWelcomeMsg[client] = false;
	g_flNextCommand[client] = 0.0;
	
	if(client == Boss_GetClient())
	{
		Boss_Death();
		LogMessage("Client \"%L\" disconnected while playing as a boss robot.", client);
	}
	
	// if the client disconnects while having more than 10 seconds remaining on the cooldown
	float flcooldowntime = g_flJoinRobotBanTime[client] - GetGameTime();
	if(flcooldowntime > 10.0)
	{
		LogMessage("Client \"%L\" disconnected while on cooldown. (Time remaining: %.1f).", client, flcooldowntime);
	}
}

public void OnClientDisconnect_Post(int client)
{
	if(GameRules_GetRoundState() == RoundState_BetweenRounds)
	{
		RequestFrame(FrameCheckForUnbalance);
	}
}

public void OnClientPostAdminCheck(int client)
{
	CreateTimer(20.0, Timer_HelpUnstuck, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE); // unstuck players from spectator team.
}

stock void TF2Spawn_TouchingSpawn(int client,int entity)
{
	if(TF2_GetClientTeam(client) == TFTeam_Blue && !IsFakeClient(client))
	{
		p_bInSpawn[client] = true;
		g_flinstructiontime[client] = GetGameTime() + 1.0;
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
		rp.InSpawn = false;
		
		if(rp.Carrier)
		{
			switch(rp.BombLevel)
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
	if (strcmp(name, "func_capturezone", false) == 0)
	{
		SDKHook(entity, SDKHook_StartTouch, OnTouchCaptureZone);
		SDKHook(entity, SDKHook_EndTouch, OnEndTouchCaptureZone);
	}
	else if (strcmp(name, "entity_revive_marker", false) == 0)
	{
		SDKHook(entity, SDKHook_SpawnPost, OnReviveMarkerSpawnPost);
	}
	else if(strcmp(name, "entity_medigun_shield", false ) == 0)
	{
		if(IsValidEntity(entity))
		{
			int iOwner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
			if(IsValidClient(iOwner) && TF2_GetClientTeam(iOwner) == TFTeam_Blue && !IsFakeClient(iOwner))
			{
				SetVariantInt(1);
				AcceptEntityInput(entity, "Skin" );
			}
		}
	}
	else if(strcmp(name, "func_respawnroom", false) == 0)
	{
		HookRespawnRoom(entity);
	}
	else if(strcmp(name, "filter_tf_bot_has_tag") == 0)
	{
		SDKHook(entity, SDKHook_SpawnPost, OnTFBotTagFilterSpawnPost);
	}
	else if(strcmp(name, "tf_ammo_pack") == 0)
	{
		SDKHook(entity, SDKHook_SpawnPost, OnAmmoPackSpawnPost);
	}
	/**else if(strcmp(name, "tf_team") == 0)
	{
		DHookEntity(g_hCTeamGetNumPlayers, true, entity);
	}**/
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	if(!IsClientInGame(client) || IsFakeClient(client) || !IsPlayerAlive(client))
		return Plugin_Continue;
		
	RoboPlayer rp = RoboPlayer(client);
	TFClassType class = TF2_GetPlayerClass(client);
	
	if(class == TFClass_Spy)
	{
		int iDisguisedClass = GetEntProp(client, Prop_Send, "m_nDisguiseClass");
		int iDisguisedTeam = GetEntProp(client, Prop_Send, "m_nDisguiseTeam");
		if(g_nDisguised[client].g_iDisguisedClass != iDisguisedClass || g_nDisguised[client].g_iDisguisedTeam != iDisguisedTeam)
		{
			if(iDisguisedClass == 0 && iDisguisedTeam == 0)
			{
				SpyDisguiseClear(client);
			}
			else 
			{
				SpyDisguiseThink(client, iDisguisedClass, iDisguisedTeam);

				g_nDisguised[client].g_iDisguisedClass = iDisguisedClass;
				g_nDisguised[client].g_iDisguisedTeam = iDisguisedTeam;
			}
		}
	}
	else
	{
		SpyDisguiseClear(client);
	}
		
	if(TF2_GetClientTeam(client) == TFTeam_Blue)
	{
		int iActiveWeapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
		BWRR_InstructPlayer(client);
	
		if(rp.InSpawn)
		{
			if(rp.ProtectionTime > GetGameTime() || g_bFreezePlayers)
			{
				TF2_AddCondition(client, TFCond_UberchargedHidden, 0.255);
			}
		
			int index;
			
			if(IsValidEntity(iActiveWeapon)) { index = GetEntProp(iActiveWeapon, Prop_Send, "m_iItemDefinitionIndex"); }
			
			// Block attack unless the player is a medic using the medigun
			// or a soldier using The Buff Banner or The Battalion's Backup or The Concheror
			// or a scout using Bonk! Atomic Punch or Crit-a-Cola or Festive Bonk!
			if(!(class == TFClass_Medic && GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary) == iActiveWeapon) && !CanWeaponBeUsedInsideSpawn(index))
			{
				SetEntPropFloat(client, Prop_Send, "m_flStealthNoAttackExpire", GetGameTime() + 0.5);	
			}
		}
		
		if(rp.Attributes & BotAttrib_InfiniteCloak)
		{
			SetEntPropFloat(client, Prop_Send, "m_flCloakMeter", 100.0);
		}
		
		if(rp.Attributes & BotAttrib_AlwaysFireWeapon && !rp.ReloadingBarrage && !rp.InSpawn)
		{
			buttons |= IN_ATTACK;
		}
		
		if(IsValidEntity(iActiveWeapon))
		{
			if(rp.Attributes & BotAttrib_HoldFireFullReload)
			{
				int iClip = GetWeaponClip(iActiveWeapon);
				int iMaxClip = GetWeaponMaxClip(iActiveWeapon);	
				
				if(iClip <= 0 || (!rp.ReloadingBarrage && buttons & IN_RELOAD)) // Enter barrage reload if empty or when manually reloading
				{
					rp.ReloadingBarrage = true;
				}
				else if(rp.ReloadingBarrage) // reloading barrage
				{
					SetEntPropFloat(client, Prop_Send, "m_flStealthNoAttackExpire", GetGameTime() + 0.5);
					buttons &= ~IN_ATTACK; // block attack
					buttons &= ~IN_ATTACK2;
					
					SetHudTextParams(-1.0, -0.55, 0.25, 255, 150, 0, 255, 0, 0.0, 0.0, 0.0);
					ShowSyncHudText(client, g_hHUDReload, "RELOADING... (%i / %i)", iClip, iMaxClip);
					
					if(iClip >= iMaxClip)
					{
						SetHudTextParams(-1.0, -0.55, 1.75, 0, 255, 0, 255, 0, 0.0, 0.0, 0.0);
						ShowSyncHudText(client, g_hHUDReload, "READY TO FIRE! (%i / %i)", iClip, iMaxClip);
						rp.ReloadingBarrage = false;
					}
				}
			}
		}
		
		if(g_bFreezePlayers) // Freeze players by changing move type instead of adding TFCond_FreezeInput. This allows players to look around.
		{
			SetEntityMoveType(client, MOVETYPE_NONE);
			SetEntPropFloat(client, Prop_Send, "m_flStealthNoAttackExpire", GetGameTime() + 0.5); // always block attack while frozen
			buttons &= ~IN_ATTACK;
			buttons &= ~IN_ATTACK2;
			buttons &= ~IN_ATTACK3;
		}
		else
		{
			if(GetEntityMoveType(client) == MOVETYPE_NONE) {
				SetEntityMoveType(client, MOVETYPE_WALK);
			}
		}
		
		if(rp.Type == Bot_Buster)
		{
			if(rp.Detonating) // Sentry Buster is detonating.
			{
				if(rp.BusterTime <= GetGameTime())
				{
					SentryBuster_CreateExplosion(client);
				}
			}
			else
			{
				if(g_flBusterVisionTimer <= GetGameTime())
				{
					g_flBusterVisionTimer = GetGameTime() + 6.0;
					//PrintToConsole(client, "Calling BusterWallhack %.1f", g_flBusterVisionTimer);
					BusterWallhack(client);
				}
			
				if(buttons & IN_ATTACK && GetEntPropEnt(client, Prop_Send, "m_hGroundEntity") != -1 && !rp.InSpawn) // Allows sentry busters to detonate by pressing M1
				{
					buttons &= ~IN_ATTACK;
					SetEntPropFloat(client, Prop_Send, "m_flStealthNoAttackExpire", GetGameTime() + 0.5);
					SentryBuster_Explode(client);
				}
			}
		}
		
		if(rp.Carrier && TF2_HasFlag(client))
		{
			// Bomb deploy
			if(g_bIsDeploying[client])
			{
				if(rp.Attributes & BotAttrib_BonkNerf && TF2_IsPlayerInCondition(client, TFCond_Bonked))
				{
					float meter = GetEntPropFloat(client, Prop_Send, "m_flEnergyDrinkMeter");
					if(meter > 1.0)
					{
#if defined DEBUG_PLAYER
						CPrintToChat(client, "{green}[DEBUG] {cyan}Applying Bonk Nerf! (%.1f)", meter);
#endif
						SetEntPropFloat(client, Prop_Send, "m_flEnergyDrinkMeter", 1.0);
					}
				}
			
				if(rp.DeployTime <= GetGameTime())
				{
					char strPlrName[MAX_NAME_LENGTH];
					GetClientName(client, strPlrName, sizeof(strPlrName));
					CPrintToChatAll("%t", "Bomb Deploy", strPlrName);
					LogAction(client, -1, "Player \"%L\" deployed the bomb.", client);
					TriggerHatchExplosion();
					rp.Deploying = false;
					rp.Carrier = false;
				}
			}
			
			if(!TF2_IsPlayerInCondition(client, TFCond_Taunting) && !TF2_IsPlayerInCondition(client, TFCond_UberchargedHidden) && !g_bIsDeploying[client])
			{
				if(TF2_IsGiant(client))
				{
					if(rp.BombLevel != 4)
					{
						rp.BombLevel = 4;
						RequestFrame(UpdateBombHud, GetClientUserId(client));
						TF2_SpeakConcept(MP_CONCEPT_MVM_GIANT_HAS_BOMB, view_as<int>(TFTeam_Red), "");
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
							if(i == client) {
								continue;
							}
						
							if(!IsClientInGame(i)) {
								continue;
							}
								
							if(GetClientTeam(i) != GetClientTeam(client)) {
								continue;
							}
							
							if(rp.BombLevel < 1) {
								continue;
							}
								
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
									TF2_SpeakConcept(MP_CONCEPT_MVM_BOMB_CARRIER_UPGRADE1, view_as<int>(TFTeam_Red), "");
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
									TF2_SpeakConcept(MP_CONCEPT_MVM_BOMB_CARRIER_UPGRADE2, view_as<int>(TFTeam_Red), "");
								}
								case 3:
								{
									TF2_AddCondition(client, TFCond_CritOnWin, TFCondDuration_Infinite);
									SDKCall(g_hSDKDispatchParticleEffect, "mvm_levelup3", PATTACH_POINT_FOLLOW, client, "head", 0);
									TF2_SpeakConcept(MP_CONCEPT_MVM_BOMB_CARRIER_UPGRADE3, view_as<int>(TFTeam_Red), "");
								}
							}
							EmitGameSoundToAll("MVM.Warning", SOUND_FROM_WORLD);
							RequestFrame(UpdateBombHud, GetClientUserId(client));
						}
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
		if(TF2_GetClientTeam(other) == TFTeam_Blue)
		{
			ForcePlayerSuicide(other);
			return Plugin_Continue;
		}
		if(!g_bUpgradeStation[other])
		{
			g_bUpgradeStation[other] = true;
		}
	}

	return Plugin_Continue;
}

// Called when an entity touches the capture zone
public Action OnTouchCaptureZone(int entity, int other)
{
	if(!IsValidClient(other)) {
		return Plugin_Continue;
	}

	if(IsFakeClient(other)) {
		return Plugin_Continue;
	}
		
	if(TF2_GetClientTeam(other) != TFTeam_Blue) {
		return Plugin_Continue;
	}
		
	if(GameRules_GetRoundState() == RoundState_TeamWin) {
		return Plugin_Handled;
	}
		
	if(!TF2_HasFlag(other)) {
		return Plugin_Handled;
	}

	RoboPlayer rp = RoboPlayer(other);
	if(rp.Carrier)
	{
		float CarrierPos[3];
		float flConVarTime = GetConVarFloat(FindConVar("tf_deploying_bomb_time")) + 0.5;
		GetClientAbsOrigin(other, CarrierPos);
		TF2_AddCondition(other, TFCond_FreezeInput, flConVarTime);
		TF2_PlaySequence(other, "primary_deploybomb");
		SetVariantInt(1);
		AcceptEntityInput(other, "SetForcedTauntCam");
		RequestFrame(DisableAnim, GetClientUserId(other));
		rp.Deploying = true;
		rp.DeployTime = GetGameTime() + flConVarTime;
		AnnounceBombDeployWarning();
		if(rp.Type == Bot_Giant || rp.Type == Bot_Boss)
			EmitGameSoundToAll("MVM.DeployBombGiant", other, SND_NOFLAGS, other, CarrierPos);
		else
			EmitGameSoundToAll("MVM.DeployBombSmall", other, SND_NOFLAGS, other, CarrierPos);
	}
	
	return Plugin_Continue;
}

// Called when an entity stop touching the flag capture zone
public Action OnEndTouchCaptureZone(int entity, int other)
{
	if(!IsValidClient(other)) {
		return Plugin_Continue;
	}

	if(IsFakeClient(other)) {
		return Plugin_Continue;
	}
		
	if(TF2_GetClientTeam(other) != TFTeam_Blue) {
		return Plugin_Continue;
	}
		
	if(GameRules_GetRoundState() == RoundState_TeamWin) {
		return Plugin_Handled;
	}
	
	if(!TF2_HasFlag(other)) {
		return Plugin_Handled;
	}
		
	RoboPlayer rp = RoboPlayer(other);
	if(rp.Carrier)
	{
		SetVariantInt(0);
		AcceptEntityInput(other, "SetForcedTauntCam");
		SetEntProp(other, Prop_Send, "m_bUseClassAnimations", 1);
		TF2_RemoveCondition(other, TFCond_FreezeInput);
		rp.Deploying = false;
		rp.DeployTime = -1.0;
	}
	
	return Plugin_Continue;
}

// Called when a player starts touching a respawn room
public Action OnStartTouchRespawn(int entity, int other)
{
	if(IsValidClient(other))
	{
		TF2Spawn_EnterSpawnOnce(other, entity);
	}
	
	return Plugin_Continue;
}

// Called when a player is touching a respawn room
public Action OnTouchRespawn(int entity, int other)
{
	if(IsValidClient(other))
	{
		TF2Spawn_TouchingSpawn(other, entity);
	}
	
	return Plugin_Continue;
}

// Called when a player stops touching a respawn room
public Action OnEndTouchRespawn(int entity, int other)
{
	if(IsValidClient(other))
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

public void OnAmmoPackSpawnPost(int entity)
{
	RequestFrame(KillAmmoPack, EntIndexToEntRef(entity));
}

public Action SDKOnPlayerTakeDamage(int victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if(victim <= 0 || victim > MaxClients) {
		return Plugin_Continue;
	}
		
	if(!IsClientInGame(victim) || IsFakeClient(victim)) {
		return Plugin_Continue;
	}
		
	if(GetClientTeam(victim) == view_as<int>(TFTeam_Blue))
	{
		if(p_iBotType[victim] == Bot_Buster)
		{
			int health = GetClientHealth(victim);
			int idamage = RoundToNearest(damage);
			
			// detonate a buster if it's going to die and it's on the ground
			if(health - idamage <= 0 && GetEntPropEnt(victim, Prop_Data, "m_hGroundEntity") != -1)
			{
				FakeClientCommand(victim, "taunt");
				SetEntProp(victim, Prop_Data, "m_takedamage", 0, 1);
				damage = 0.0;
				return Plugin_Changed;
			}
		}
	}
	
	if(attacker <= 0 || attacker > MaxClients) {
		return Plugin_Continue;
	}
	
	// Bots will always notice backstabs that doesn't kill them
	if(damagecustom == TF_CUSTOM_BACKSTAB && damagetype & DMG_CRIT && TF2_IsGiant(victim))
	{
		// Alert giant players they're getting backstabbed
		EmitSoundToClient(victim, "player/spy_shield_break.wav");
		PrintCenterText(victim, "!!!!!! YOU WERE BACKSTABBED !!!!!");
	}
	
	if(GetClientTeam(attacker) == view_as<int>(TFTeam_Blue) && GetClientTeam(victim) == view_as<int>(TFTeam_Red)) {
		if(damagecustom != TF_CUSTOM_BURNING && damagecustom != TF_CUSTOM_BURNING_ARROW && damagecustom != TF_CUSTOM_BURNING_FLARE && damagecustom != TF_CUSTOM_PLAYER_SENTRY) {
			RoboPlayer rp = RoboPlayer(attacker);
			if(rp.Attributes & BotAttrib_IgniteOnHit) {
				BWRR_IgniteOnHit(attacker, victim);
			}
			if(rp.Attributes & BotAttrib_StunOnHit) {
				BWRR_StunOnHit(attacker, victim);
			}
		}
	}
	
	return Plugin_Continue;
}

/****************************************************
					DETOURS
*****************************************************/

// Crash fix for maps that use event change attributes. Returns NULL (0) for human clients
public MRESReturn CTFBot_GetEventChangeAttributes(int pThis, Handle hReturn, Handle hParams) 
{
	if(IsValidClient(pThis) && !IsFakeClient(pThis))
	{
#if defined DEBUG_CRASHFIX
		LogMessage("CTFBot::CTFBot_GetEventChangeAttributes returning NULL for client \"%L\"", pThis);
#endif
		
		DHookSetReturn(hReturn, 0);
		return MRES_Supercede;
	}

	return MRES_Ignored; 
}

public MRESReturn CTFBot_GetEventChangeAttributes_Post(int pThis, Handle hReturn, Handle hParams)
{
	if(IsValidClient(pThis) && !IsFakeClient(pThis))
	{
#if defined DEBUG_CRASHFIX	
		LogMessage("CTFBot::CTFBot_GetEventChangeAttributes_Post returning NULL for client \"%L\"", pThis);
#endif
		
		DHookSetReturn(hReturn, 0);
		return MRES_Supercede;
	}
	
	return MRES_Ignored;
}

// Allow human robots to capture gates
public MRESReturn CFilterTFBotHasTag(int iFilter, Handle hReturn, Handle hParams)
{
	if(!GameRules_GetProp("m_bPlayingMannVsMachine") || DHookIsNullParam(hParams, 2) || DHookIsNullParam(hParams, 1)) {
		return MRES_Ignored;
	}

	int iEntity = DHookGetParam(hParams, 1);
	int iOther  = DHookGetParam(hParams, 2);
	
	if(iOther <= 0 || iOther > MaxClients || !IsClientInGame(iOther)) {
		return MRES_Ignored;
	}
	
	//Don't care about real bots
	if(IsFakeClient(iOther)) {
		return MRES_Ignored;
	}
	
	if(!IsPlayerAlive(iOther))
	{
		DHookSetReturn(hReturn, false);
		return MRES_Supercede;
	}
	
	// Don't care if not from BLU team.
	if(GetClientTeam(iOther) != 3) {
		return MRES_Ignored;
	}
	
	// Don't allow taking gates if stun is active
	if(IsGateStunActive()) {
		return MRES_Ignored;
	}
		
	if(TF2_GetPlayerClass(iOther) == TFClass_Spy)
	{
		if(TF2_IsPlayerInCondition(iOther, TFCond_Disguised) || TF2_IsPlayerInCondition(iOther, TFCond_Cloaked) || TF2_IsPlayerInCondition(iOther, TFCond_Stealthed))
			return MRES_Ignored; // Don't allow disguised or cloaked spies to cap
	}

	bool bNegated = !!GetEntProp(iFilter, Prop_Data, "m_bNegated");
	
	bool bResult = p_bIsGatebot[iOther];
	if(bNegated)
		bResult = !bResult;
	
	char classname[64];
	GetEntityClassname(iEntity, classname, sizeof(classname));
	
	//We don't care about you
	if(strcmp(classname, "func_nav_prerequisite") == 0) {
		return MRES_Ignored;
	}
	
	//These work the opposite way
	if(strcmp(classname, "trigger_add_tf_player_condition") == 0) {
		bResult = !bResult;
	}
	
	DHookSetReturn(hReturn, bResult);
	return MRES_Supercede;
}

// Code from Pelipoika's Bot Control
public MRESReturn CTFPlayer_ShouldGib(int pThis, Handle hReturn, Handle hParams)
{
	if(!DHookIsNullParam(hParams, 1) && TF2_GetClientTeam(pThis) == TFTeam_Blue)
	{
		bool is_miniboss = view_as<bool>(GetEntProp(pThis, Prop_Send, "m_bIsMiniBoss"));
		float m_flModelScale = GetEntPropFloat(pThis, Prop_Send, "m_flModelScale");
		
		if(is_miniboss || m_flModelScale > 1.0)
		{
			DHookSetReturn(hReturn, true);
			return MRES_Supercede;
		}
		
		bool is_engie  = (TF2_GetPlayerClass(pThis) == TFClass_Engineer);
		bool is_medic  = (TF2_GetPlayerClass(pThis) == TFClass_Medic);
		bool is_sniper = (TF2_GetPlayerClass(pThis) == TFClass_Sniper);
		bool is_spy    = (TF2_GetPlayerClass(pThis) == TFClass_Spy);
		
		if (is_engie || is_medic || is_sniper || is_spy) {
			DHookSetReturn(hReturn, false);
			return MRES_Supercede;
		}
	}
	
	return MRES_Ignored;
}

// Overrides the BLU team player count
// This will fix the issue where human BLU players prevents bots from spawning because the game thinks there aren't any free slots.
// BUGBUG!! Sentry guns won't attack enemy players
// TO DO: Find another way to fix this
/**public MRESReturn CTeam_GetNumPlayers(int pThis, Handle hReturn)
{
	if(!GameRules_GetProp("m_bPlayingMannVsMachine")) // Don't care in non mvm
		return MRES_Ignored;
		
	if(GetEntProp(pThis, Prop_Send, "m_iTeamNum") != view_as<int>(TFTeam_Blue)) // We only care about BLU team
		return MRES_Ignored;
		
	int numplayers = DHookGetReturn(hReturn);
	int humans = GetHumanRobotCount();
	
	if(humans <= 0) // No Humans in BLU team, don't care
		return MRES_Ignored;
		
	numplayers -= humans; // subtract human count from player count
	
	if(numplayers < 0)
		numplayers = 0;
		
	DHookSetReturn(hReturn, numplayers);
	CPrintToChatAll("{green}CTeam::GetNumPlayers {snow}Player count for BLU team: %i", numplayers);
	
	return MRES_Supercede;
}**/

// Prevent human BLU players from being forced to laugh
public MRESReturn CTFPLayer_CanBeForcedToLaugh(int pThis, Handle hReturn)
{
	if(TF2_GetClientTeam(pThis) == TFTeam_Blue && !IsFakeClient(pThis))
	{
#if defined DEBUG_PLAYER
		CPrintToChat(pThis, "{green}[DEBUG] {snow}Overriding CTFPLayer::CanBeForcedToLaugh");
#endif
		DHookSetReturn(hReturn, false);
		return MRES_Supercede;
	}
	
	return MRES_Ignored;
}

public MRESReturn CTFPLayer_CanBeForcedToLaugh_Post(int pThis, Handle hReturn)
{
	if(TF2_GetClientTeam(pThis) == TFTeam_Blue && !IsFakeClient(pThis))
	{
#if defined DEBUG_PLAYER
		CPrintToChat(pThis, "{green}[DEBUG] {snow}Overriding CTFPLayer::CanBeForcedToLaugh (Post)");
#endif
		DHookSetReturn(hReturn, false);
		return MRES_Supercede;
	}
	
	return MRES_Ignored;
}

// Allow human BLU spies to "build" infinite sappers
// Disabled until a working windows sig is found
/**
public MRESReturn CTFPlayer_CanBuild(int pThis, Handle hReturn, Handle hParams)
{
	if(TF2_GetClientTeam(pThis) == TFTeam_Blue && !IsFakeClient(pThis) && TF2_GetPlayerClass(pThis) == TFClass_Spy)
	{
		DHookSetReturn(hReturn, CB_CAN_BUILD);
		return MRES_Supercede;
	}
	
	return MRES_Ignored;
}
**/
/* public MRESReturn CTFPlayer_CanBuild_Post(int pThis, Handle hReturn, Handle hParams)
{
	if(TF2_GetClientTeam(pThis) == TFTeam_Blue && !IsFakeClient(pThis) && TF2_GetPlayerClass(pThis) == TFClass_Spy)
	{
		DHookSetReturn(hReturn, CB_CAN_BUILD);
		return MRES_Supercede;
	}
	
	return MRES_Ignored;
} */

/****************************************************
					ENTITY OUTPUTS
*****************************************************/

void OnGateCaptureBLU(const char[] output, int caller, int activator, float delay)
{
	CreateTimer(1.0, Timer_GateCaptured, _, TIMER_FLAG_NO_MAPCHANGE);
	RequestFrame(GateCapturedByRobots);
}

void OnGateCaptureRED(const char[] output, int caller, int activator, float delay)
{
	CreateTimer(1.0, Timer_GateCaptured, _, TIMER_FLAG_NO_MAPCHANGE);
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
	if(!IsClientInGame(client) || IsFakeClient(client)) {
		return Plugin_Handled;
	}
		
	if(TF2_GetClientTeam(client) == TFTeam_Blue) {
		return Plugin_Handled;
	}
		
	if(GameRules_GetRoundState() == RoundState_TeamWin) {
		return Plugin_Handled;
	}
		
	if(g_bPluginError)
	{
		ReplyToCommand(client, "[BWRR] The plugin has been disabled due to an error. Please contact the server administrator.");
		return Plugin_Handled;
	}
		
	if(!CheckCommandAccess(client, "bwrr_joinblue", 0))
	{
		CPrintToChat(client,"%t", "No BLU Access");
		return Plugin_Handled;
	}
		
	if(!IsWaveDataBuilt()) // Block join BLU to avoid errors
	{
		PrintToChat(client, "Wave Data isn't ready, rebuilding... Please try again.");
		OR_Update();
		UpdateClassArray();
		return Plugin_Handled;
	}
	
	// Denied: Player is banned/on cooldown
	if(c_bAntiJoinSpam.BoolValue && g_flJoinRobotBanTime[client] > GetGameTime())
	{
		float fltime = g_flJoinRobotBanTime[client] - GetGameTime();
		CPrintToChat(client, "%t", "Blu_Banned", fltime);
		g_flJoinRobotBanTime[client] += 0.5; // Add 0.5 second to annony spammers
		return Plugin_Handled;
	}
	else
	{
		g_flJoinRobotBanTime[client] = GetGameTime() + 5.0; // Anti-spam
	}
	
	// Denied: Not enough players in RED to join while a wave is running.
	int iMinRed = c_iMinRedinProg.IntValue;
	int inred = GetTeamClientCount(2);
	if(GameRules_GetRoundState() == RoundState_RoundRunning && inred < iMinRed)
	{
		CPrintToChat(client,"%t", "Not in Prog");
		CPrintToChat(client,"%t","Num Red",iMinRed, inred);
		return Plugin_Handled;
	}
	
	// Denied: Not enough players in RED to join.
	iMinRed = c_iMinRed.IntValue;
	if(inred < iMinRed)
	{
		CPrintToChat(client,"%t","Need Red");
		CPrintToChat(client,"%t","Num Red",iMinRed, inred);
		return Plugin_Handled;
	}
	
	// Denied: BLU is at full capacity.
	if(GetHumanRobotCount() >= c_iMaxBlu.IntValue)
	{
		CPrintToChat(client, "%t", "Blu Full");
		return Plugin_Handled;
	}
	
	// Denied: Players cannot join BLU while ready.
	bool bReady = view_as<bool>(GameRules_GetProp( "m_bPlayerReady", _, client));
	if(bReady && GameRules_GetRoundState() == RoundState_BetweenRounds)
	{
		CPrintToChat(client,"%t","Unready");
		return Plugin_Handled;
	}
	
	// Denied: Player used an upgrade station.
	if(g_bUpgradeStation[client])
	{
		CPrintToChat(client,"%t","Used Upgrade");
		return Plugin_Handled;
	}
	
	PreChangeTeam(client, view_as<int>(TFTeam_Blue));
	return Plugin_Handled;
}

public Action Command_JoinRED( int client, int nArgs )
{
	if(!IsClientInGame(client) || IsFakeClient(client)) {
		return Plugin_Continue;
	}
		
	if(TF2_GetClientTeam(client) == TFTeam_Red) {
		return Plugin_Handled;
	}
	
	PreChangeTeam(client, view_as<int>(TFTeam_Red));

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
	while((i = FindEntityByClassname(i, "bot_hint_engineer_nest" )) != -1)
	{
		if(IsValidEntity(i))
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

public Action Command_Debug_Spy( int client, int nArgs )
{
	if(client == 0) {
		return Plugin_Handled;
	}
		
	if(g_aSpyTeleport.Length < 1)
	{
		ReplyToCommand(client, "Spy teleport array length is 0.");
		return Plugin_Handled;
	}
	
	if(nArgs < 1)
	{
		ReplyToCommand(client, "Usage: sm_bwrr_debug_spy <index>");
		ReplyToCommand(client, "Array size is %i\nRemember arrays indexes starts at 0.", g_aSpyTeleport.Length);
		return Plugin_Handled;
	}
	
	char sArg1[4];
	int iArg1;
	GetCmdArg(1, sArg1, sizeof(sArg1));
	iArg1 = StringToInt(sArg1);
	
	if(iArg1 < 0 || iArg1 >= g_aSpyTeleport.Length)
	{
		ReplyToCommand(client, "Index is out of bounds.");
		return Plugin_Handled;
	}
	
	float vecPos[3];
	g_aSpyTeleport.GetArray(iArg1, vecPos);
	TeleportEntity(client, vecPos, NULL_VECTOR, NULL_VECTOR);
	ReplyToCommand(client, "Teleported to index %i at %.1f %.1f %.1f", iArg1, vecPos[0], vecPos[1], vecPos[2]);

	return Plugin_Handled;
}

public Action Command_Debug_Spy_Trace( int client, int nArgs )
{
	ReplyToCommand(client, "Running test...");
	float vecPos[3];
	for(int i = 0;i < g_aSpyTeleport.Length;i++)
	{
		g_aSpyTeleport.GetArray(i, vecPos);
		SpyTeleport_RayCheck(i, vecPos, 1);
	}

	return Plugin_Handled;
}

public Action Command_Show_Tele_Pos(int client, int args)
{
	if(!client)
		return Plugin_Handled;

	float clientorigin[3], origin[3], pos2[3];
	GetClientAbsOrigin(client, clientorigin);
	float delay = 0.0;
	
	ReplyToCommand(client, "BLUE - Engineer (bot_hint_engineer_nest)");
	ReplyToCommand(client, "ORANGE - Engineer (config)");
	ReplyToCommand(client, "CYAN - Spy (config)");
	
	int i = -1;
	while((i = FindEntityByClassname(i, "bot_hint_engineer_nest")) != -1)
	{
		if(IsValidEntity(i))
		{
			GetEntPropVector(i, Prop_Send, "m_vecOrigin", origin);
			if(GetVectorDistance(clientorigin, origin) <= 2048.0) 
			{
				pos2[0] = origin[0];
				pos2[1] = origin[1];
				pos2[2] = origin[2];
				pos2[2] += 90.0;
				TE_SetupBeamPoints(origin, pos2, g_iLaserSprite, g_iHaloSprite, 0, 0, 10.0, 1.0, 1.0, 1, 1.0, {0, 0, 255, 255}, 0);
				TE_SendToClient(client, delay);
				delay += 0.1;
			}
		}
	}
	
	for(int y = 0;y < g_aEngyTeleport.Length;y++)
	{
		g_aEngyTeleport.GetArray(y, origin);
	
		if(GetVectorDistance(clientorigin, origin) >= 2048.0)
			continue;
		
		pos2[0] = origin[0];
		pos2[1] = origin[1];
		pos2[2] = origin[2];
		pos2[2] += 90.0;
		TE_SetupBeamPoints(origin, pos2, g_iLaserSprite, g_iHaloSprite, 0, 0, 10.0, 1.0, 1.0, 1, 1.0, { 251, 153, 2, 255 }, 0);
		TE_SendToClient(client, delay);
		delay += 0.1;
	}
	
	for(int y = 0;y < g_aSpyTeleport.Length;y++)
	{
		g_aSpyTeleport.GetArray(y, origin);
	
		if(GetVectorDistance(clientorigin, origin) >= 2048.0)
			continue;
		
		pos2[0] = origin[0];
		pos2[1] = origin[1];
		pos2[2] = origin[2];
		pos2[2] += 90.0;
		TE_SetupBeamPoints(origin, pos2, g_iLaserSprite, g_iHaloSprite, 0, 0, 10.0, 1.0, 1.0, 1, 1.0, { 0, 255, 255, 255 }, 0);
		TE_SendToClient(client, delay);
		delay += 0.1;
	}
	
	return Plugin_Handled;
}

public Action Command_Show_SpawnPoints(int client, int args)
{
	if(!client)
		return Plugin_Handled;
	
	char arg1[64], name[64];
	int entity;
	float delay = 0.0;
	float origin[3], pos2[3], clientorigin[3];
	GetClientAbsOrigin(client, clientorigin);
	
	if(args >= 1)
	{
		GetCmdArg(1, arg1, sizeof(arg1));
	}
	
	CPrintToChat(client, "{snow}RED - RED Team Spawn Point");
	CPrintToChat(client, "{snow}BLUE - BLU Team Spawn Point");
	CPrintToChat(client, "{snow}YELLOW - MARKED Team Spawn Point");
	
	while((entity = FindEntityByClassname(entity, "info_player_teamspawn")) != -1)
	{
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", origin);
		if(GetVectorDistance(clientorigin, origin) <= 2048.0)
		{
			GetEntPropString(entity, Prop_Data, "m_iName", name, sizeof(name));
			if(args >= 1 && strcmp(name, arg1, false) == 0) // First check for disabled points
			{
				pos2[0] = origin[0];
				pos2[1] = origin[1];
				pos2[2] = origin[2];
				pos2[2] += 90.0;
				TE_SetupBeamPoints(origin, pos2, g_iLaserSprite, g_iHaloSprite, 0, 0, 10.0, 1.0, 1.0, 1, 1.0, { 255, 255, 0, 255 }, 0);
				TE_SendToClient(client, delay);
				delay += 0.1;				
			}
			else if(GetEntProp(entity, Prop_Send, "m_iTeamNum") == view_as<int>(TFTeam_Red))
			{
				pos2[0] = origin[0];
				pos2[1] = origin[1];
				pos2[2] = origin[2];
				pos2[2] += 90.0;
				TE_SetupBeamPoints(origin, pos2, g_iLaserSprite, g_iHaloSprite, 0, 0, 10.0, 1.0, 1.0, 1, 1.0, { 255, 0, 0, 255 }, 0);
				TE_SendToClient(client, delay);
				delay += 0.1;
			}
			else if(GetEntProp(entity, Prop_Send, "m_iTeamNum") == view_as<int>(TFTeam_Blue))
			{
				pos2[0] = origin[0];
				pos2[1] = origin[1];
				pos2[2] = origin[2];
				pos2[2] += 90.0;
				TE_SetupBeamPoints(origin, pos2, g_iLaserSprite, g_iHaloSprite, 0, 0, 10.0, 1.0, 1.0, 1, 1.0, { 0, 0, 255, 255 }, 0);
				TE_SendToClient(client, delay);
				delay += 0.1;				
			}
		}
	}
	
	return Plugin_Handled;
}

public Action Command_TraceHull(int client, int args)
{
	if(!client)
		return Plugin_Handled;
	
	float mins[3], maxs[3], position[3];
	GetEntPropVector(client, Prop_Send, "m_vecMins", mins);
	GetEntPropVector(client, Prop_Send, "m_vecMaxs", maxs);
	GetClientAbsOrigin(client, position);
	Handle trace = TR_TraceHullFilterEx(position, position, mins, maxs, MASK_PLAYERSOLID, TraceFilterTeleporter, client);
	if(TR_DidHit(trace))
	{
		int hitentity = TR_GetEntityIndex(trace);
		char classname[64];
		GetEntityClassname(hitentity, classname, sizeof(classname));
		CPrintToChat(client, "{green}[TRACE HULL]{cyan} Collision with entity index \"%i\" classname \"%s\"", hitentity, classname);
	}
	else
	{
		CPrintToChat(client, "{green}[TRACE HULL]{cyan} No collision detected.");
	}
	
	delete trace;
	return Plugin_Handled;
}

public Action Command_Debug_Engy(int client, int nArgs)
{
	if(client == 0) {
		return Plugin_Handled;
	}
		
	if(g_aEngyTeleport.Length < 1)
	{
		ReplyToCommand(client, "Engineer teleport array length is 0.");
		return Plugin_Handled;
	}
	
	if(nArgs < 1)
	{
		ReplyToCommand(client, "Usage: sm_bwrr_debug_engy <index>");
		ReplyToCommand(client, "Array size is %i\nRemember arrays indexes starts at 0.", g_aEngyTeleport.Length);
		return Plugin_Handled;
	}
	
	char sArg1[4];
	int iArg1;
	GetCmdArg(1, sArg1, sizeof(sArg1));
	iArg1 = StringToInt(sArg1);
	
	if(iArg1 < 0 || iArg1 >= g_aEngyTeleport.Length)
	{
		ReplyToCommand(client, "Index is out of bounds.");
		return Plugin_Handled;
	}
	
	float vecPos[3];
	g_aEngyTeleport.GetArray(iArg1, vecPos);
	TeleportEntity(client, vecPos, NULL_VECTOR, NULL_VECTOR);
	ReplyToCommand(client, "Teleported to index %i at %.1f %.1f %.1f", iArg1, vecPos[0], vecPos[1], vecPos[2]);

	return Plugin_Handled;
}

public Action Command_GetOrigin( int client, int nArgs )
{
	if(!IsValidClient(client)) {
		return Plugin_Handled;
	}
		
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

public Action Command_Editor( int client, int nArgs )
{
	if(client == 0) {
		return Plugin_Handled;
	}
		
	if(!IsClientInGame(client)) {
		return Plugin_Handled;
	}
		
	Menufunc_CreateEditorMenu(client);
	
	return Plugin_Handled;
}

public Action Command_Reload( int client, int nArgs )
{
	Config_LoadMap();
	ShowActivity2(client, "[SM] ", "Reloaded the map config.");
	LogAction(client, -1, "\"%L\" reloaded the map config.", client);
	return Plugin_Handled;
}

public Action Command_ForceBot( int client, int nArgs )
{
	char arg1[MAX_NAME_LENGTH], arg2[16], arg3[4], arg4[4];
	bool bForceGiants = false;
	
	if(nArgs < 4)
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
	
	if(strcmp(arg2, "scout", false) == 0)
	{
		TargetClass = TFClass_Scout;
	}
	else if(strcmp(arg2, "soldier", false) == 0)
	{
		TargetClass = TFClass_Soldier;
	}
	else if(strcmp(arg2, "pyro", false) == 0)
	{
		TargetClass = TFClass_Pyro;
	}
	else if(strcmp(arg2, "demoman", false) == 0)
	{
		TargetClass = TFClass_DemoMan;
	}
	else if(strcmp(arg2, "heavy", false) == 0)
	{
		TargetClass = TFClass_Heavy;
	}
	else if(strcmp(arg2, "engineer", false) == 0)
	{
		TargetClass = TFClass_Engineer;
	}
	else if(strcmp(arg2, "medic", false) == 0)
	{
		TargetClass = TFClass_Medic;
	}
	else if(strcmp(arg2, "sniper", false) == 0)
	{
		TargetClass = TFClass_Sniper;
	}
	else if(strcmp(arg2, "spy", false) == 0)
	{
		TargetClass = TFClass_Spy;
	}
	
	if(TargetClass == TFClass_Unknown)
	{
		ReplyToCommand(client, "ERROR: Invalid class");
		ReplyToCommand(client, "Valid Classes: scout,soldier,pyro,demoman,heavy,engineer,medic,sniper,spy");
		return Plugin_Handled;
	}
	
	GetCmdArg(3, arg3, sizeof(arg3));
	int iArg3 = StringToInt(arg3);
	if(iArg3 < 0 || iArg3 > 1)
	{
		ReplyToCommand(client, "ERROR: Use 0 for Normal Bot and 1 for Giant Bot");
		return Plugin_Handled;
	}
	else if(iArg3 == 1)
	{
		bForceGiants = true;
	}
	
	GetCmdArg(4, arg4, sizeof(arg4));
	int iArg4 = StringToInt(arg4);
	
	bool bValid = IsValidVariant(bForceGiants, TargetClass, iArg4);
	if(!bValid)
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
	
	if(tn_is_ml)
	{
		ShowActivity2(client, "[SM] ", "Forced a robot variant (%s|%s) on %t.", arg2, strBotName, target_name);
	}
	else
	{
		ShowActivity2(client, "[SM] ", "Forced a robot variant (%s|%s) on %s.", arg2, strBotName, target_name);
	}
	return Plugin_Handled;
}

public Action Command_ForceBoss( int client, int nArgs )
{
	char arg1[MAX_NAME_LENGTH], arg2[64];
	
	if(nArgs < 2)
	{
		ReplyToCommand(client, "Usage: sm_bwrr_forceboss <target> <boss profile>>");
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
	
	GetCmdArg(2, arg2, sizeof(arg2));
	
	if(!Boss_LoadProfile(arg2)) // Attempts to load the given boss profile
	{
		ReplyToCommand(client, "Invalid boss profile.");
		return Plugin_Handled;
	}
	
	for(int i = 0; i < target_count; i++)
	{
		if( TF2_GetClientTeam(target_list[i]) == TFTeam_Blue )
		{
			SetBossOnPlayer(target_list[i]); // This function doesn't load the boss profile, we must always call Boss_LoadProfile before this
			LogAction(client, target_list[i], "\"%L\" Forced a boss robot (%s) on \"%L\".", client, arg2, target_list[i]);
		}
		else
		{
			ReplyToCommand(client, "ERROR: This command can only be used on BLU team.");
			return Plugin_Handled;
		}
	}
	
	if (tn_is_ml)
	{
		ShowActivity2(client, "[SM] ", "Forced a boss robot on (%s) on %t.", arg2, target_name);
	}
	else
	{
		ShowActivity2(client, "[SM] ", "Forced a boss robot on (%s) on %s.", arg2, target_name);
	}
	return Plugin_Handled;
}

public Action Command_MoveTeam( int client, int nArgs )
{
	char arg1[MAX_NAME_LENGTH], arg2[16];
	TFTeam NewTargetTeam = TFTeam_Spectator; // default to spectator if no team is specified
	int iArgTeam = 1;
	
	if(nArgs < 1)
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
	
	if(nArgs == 2)
	{
		GetCmdArg(2, arg2, sizeof(arg2));
		iArgTeam = StringToInt(arg2);
		if(iArgTeam <= 0 || iArgTeam > 3)
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
	
	switch(iArgTeam)
	{
		case 1: strcopy(strLogTeam, 16, "Spectator");
		case 2: strcopy(strLogTeam, 16, "RED");
		case 3: strcopy(strLogTeam, 16, "BLU");
	}
	
	for(int i = 0; i < target_count; i++)
	{
		if(NewTargetTeam == TFTeam_Blue)
		{
			if(!IsWaveDataBuilt())
			{
				CReplyToCommand(client, "{springgreen}Wave data needs to be built. Building data...");
				OR_Update();
				UpdateClassArray();
				return Plugin_Handled;
			}
			else
			{
				PreChangeTeam(target_list[i], view_as<int>(TFTeam_Blue));
			}
		}
		else if(NewTargetTeam == TFTeam_Red)
		{
			PreChangeTeam(target_list[i], view_as<int>(TFTeam_Red));
		}
		else
		{
			PreChangeTeam(target_list[i], view_as<int>(TFTeam_Spectator), true);
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
	if(!IsClientInGame(client) || IsFakeClient(client)) {
		return Plugin_Handled;
	}
		
	if(TF2_GetClientTeam(client) == TFTeam_Red) {
		return Plugin_Handled;
	}
		
	if(!p_bInSpawn[client] && GameRules_GetRoundState() == RoundState_RoundRunning)
	{
		CReplyToCommand(client, "%t", "BotClassFailMsg");
		return Plugin_Handled;
	}

	if(Boss_GetClient() == client)
	{
		Boss_Death();
		LogAction(client, -1, "\"%L\" selected a new robot while playing as a boss.", client);
	}
	
	int flag = TF2_GetClientFlag(client);
	if(IsValidEntity(flag)) {
		TF2_ResetFlag(flag);
	}
	PickRandomRobot(client);
	CreateTimer(0.5, Timer_Respawn, client, TIMER_FLAG_NO_MAPCHANGE);

	return Plugin_Handled;
}

public Action Command_ShowPlayers( int client, int nArgs )
{
		
	int iRedCount = 0, iBluCount = 0, iSpecCount = 0;
	char RedNames[256], BluNames[256], SpecNames[256];
	char plrname[256];
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i))
		{
			if(TF2_GetClientTeam(i) == TFTeam_Red)
			{
				GetClientName(i, plrname, sizeof(plrname));
				Format(RedNames, sizeof(RedNames), "%s %s", plrname, RedNames);
				iRedCount++;
			}
			else if(TF2_GetClientTeam(i) == TFTeam_Blue )
			{
				GetClientName(i, plrname, sizeof(plrname));
				Format(BluNames, sizeof(BluNames), "%s %s", plrname, BluNames);
				iBluCount++;
			}
			else if(TF2_GetClientTeam(i) == TFTeam_Spectator || TF2_GetClientTeam(i) == TFTeam_Unassigned)
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
	if(nArgs < 3)
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
	
	if(iArg2 < 0 || iArg2 > 1)
	{
		ReplyToCommand(client, "ERROR: Use 0 for Normal Bot and 1 for Giant Bot");
		return Plugin_Handled;
	}
	
	if(iArg2 != 0)
		bGiants = true;
	
	if(strcmp(arg1, "scout", false) == 0)
	{
		TargetClass = TFClass_Scout;
	}
	else if(strcmp(arg1, "soldier", false) == 0)
	{
		TargetClass = TFClass_Soldier;
	}
	else if(strcmp(arg1, "pyro", false) == 0)
	{
		TargetClass = TFClass_Pyro;
	}
	else if(strcmp(arg1, "demoman", false) == 0)
	{
		TargetClass = TFClass_DemoMan;
	}
	else if(strcmp(arg1, "heavy", false) == 0)
	{
		TargetClass = TFClass_Heavy;
	}
	else if(strcmp(arg1, "engineer", false) == 0)
	{
		TargetClass = TFClass_Engineer;
	}
	else if(strcmp(arg1, "medic", false) == 0)
	{
		TargetClass = TFClass_Medic;
	}
	else if(strcmp(arg1, "sniper", false) == 0)
	{
		TargetClass = TFClass_Sniper;
	}
	else if(strcmp(arg1, "spy", false) == 0)
	{
		TargetClass = TFClass_Spy;
	}
	
	if(TargetClass == TFClass_Unknown)
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
	
	if(GameRules_GetRoundState() != RoundState_RoundRunning)
	{
		ReplyToCommand(client, "Boss data is only available after wave start.");
		return Plugin_Handled;
	}
	
	switch(g_BossState)
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
	if(Boss_IsGatebot()) {
		Format(bossname, sizeof(bossname), "Gatebot %s", bossname);
	}
	ReplyToCommand(client, "Boss State: %s", state);
	ReplyToCommand(client, "Selected Boss: %s", bossname);
	if(IsValidClient(iBossPlayer) && IsPlayerAlive(iBossPlayer))
	{
		ReplyToCommand(client, "Active Boss: Controller: %N || Health: %i", iBossPlayer, GetClientHealth(iBossPlayer));
	}
	
	if(GetTeamClientCount(2) < g_BossMinRed)
	{
		ReplyToCommand(client, "Not enough players in RED to allow bosses to spawn.");
	}
	
	float enginetime = GetGameTime();
	if(g_BossTimer > enginetime)
	{
		int iSpawnTime = RoundToNearest( g_BossTimer - enginetime );
		if(iSpawnTime > 0)
		{
			ReplyToCommand(client, "Boss will be able to spawn in %i seconds", iSpawnTime);
		}
	}
	
	return Plugin_Handled;
}

public Action Command_BanBLU( int client, int nArgs )
{
	if(nArgs < 1)
	{
		ReplyToCommand(client, "Usage: sm_bwrr_add_cooldown <target> <time>");
		return Plugin_Handled;
	}
	
	char arg1[MAX_NAME_LENGTH];
	GetCmdArg(1, arg1, sizeof(arg1));
	
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
	
	if((target_count = ProcessTargetString(arg1, client, target_list, MAXPLAYERS, COMMAND_FILTER_NO_BOTS, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	if(nArgs == 1)
	{
		ReplyToCommand(client, "No time specified.");
		return Plugin_Handled;
	}
	
	char arg2[8];
	GetCmdArg(2, arg2, sizeof(arg2));
	float bantime = StringToFloat(arg2);
	
	for(int i = 0; i < target_count; i++)
	{
		g_flJoinRobotBanTime[target_list[i]] = GetGameTime() + bantime;
		LogAction(client, target_list[i], "\"%L\" add %.1f join BLU cooldown time to \"%L\".", client, bantime, target_list[i]);
	}
	
	if (tn_is_ml)
	{
		ShowActivity2(client, "[SM] ", "Added %.1f join BLU cooldown time to %t.", bantime, target_name);
	}
	else
	{
		ShowActivity2(client, "[SM] ", "Added %.1f join BLU cooldown time to %s.", bantime, target_name);
	}
	
	return Plugin_Handled;
}

/****************************************************
					LISTENER
*****************************************************/

public Action Listener_JoinTeam(int client, const char[] command, int argc)
{
	if(!IsValidClient(client)) {
		return Plugin_Handled;
	}
		
	if(IsFakeClient(client)) {
		return Plugin_Continue;
	}
		
	char strTeam[16];
	GetCmdArg(1, strTeam, sizeof(strTeam));
	if(strcmp( strTeam, "red", false ) == 0)
	{
		Command_JoinRED(client, 0);
		return Plugin_Handled;
	}
	else if(strcmp( strTeam, "blue", false ) == 0)
	{
		Command_JoinBLU(client, 0);
		return Plugin_Handled;
	}
	else if(strcmp(strTeam, "spectate", false) == 0 || strcmp(strTeam, "spectator", false) == 0)
	{
		PreChangeTeam(client, view_as<int>(TFTeam_Spectator));
		return Plugin_Handled;
	}
	
	Command_JoinRED(client, 0); // Default to RED team.
	return Plugin_Handled;
}

public Action Listener_Ready(int client, const char[] command, int argc)
{
	if(!IsClientInGame(client)) {
		return Plugin_Continue;
	}

	if(TF2_GetClientTeam(client) == TFTeam_Blue)
	{
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Action Listener_Suicide(int client, const char[] command, int argc)
{
	if(!IsClientInGame(client)) {
		return Plugin_Continue;
	}
		
	if(IsFakeClient(client)) {
		return Plugin_Continue;
	}

	if(TF2_GetClientTeam(client) == TFTeam_Blue)
	{
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Action Listener_Build(int client, const char[] command, int argc)
{
	if(!IsClientInGame(client)) {
		return Plugin_Continue;
	}

	if(TF2_GetClientTeam(client) != TFTeam_Blue) {
		return Plugin_Continue;
	}
		
	if(IsFakeClient(client)) {
		return Plugin_Continue;
	}

	if(p_bInSpawn[client])
	{
		return Plugin_Handled;
	}
	
	char strArg1[8], strArg2[8];
	GetCmdArg(1, strArg1, sizeof(strArg1));
	GetCmdArg(2, strArg2, sizeof(strArg2));
	
	TFObjectType objType = view_as<TFObjectType>(StringToInt(strArg1));
	TFObjectMode objMode = view_as<TFObjectMode>(StringToInt(strArg2));
	
	if(objType == TFObject_Teleporter && objMode == TFObjectMode_Entrance)
		return Plugin_Handled;
		
	if(objType == TFObject_Teleporter && (p_iBotAttrib[client] & BotAttrib_CannotBuildTele ))
		return Plugin_Handled;
	
	return Plugin_Continue;
}

public Action Listener_CallVote(int client, const char[] command, int argc)
{
	if(!IsValidClient(client)) {
		return Plugin_Handled;
	}

	if(TF2_GetClientTeam(client) == TFTeam_Blue)
	{
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Action Listener_Taunt(int client, const char[] command, int argc)
{
	if(!IsClientInGame(client))
		return Plugin_Continue;

	if(IsFakeClient(client))
		return Plugin_Continue;
		
	RoboPlayer rp = RoboPlayer(client);
	
	if(TF2_GetClientTeam(client) == TFTeam_Blue)
	{
		if(rp.InSpawn) // Block taunts while inside spawn
			return Plugin_Handled;
		
		if(rp.Type == Bot_Buster)
		{
			if(!rp.Detonating)
			{
				SentryBuster_Explode(client);
			}
		}
	}
	
	return Plugin_Continue;
}

/****************************************************
					MENUS
*****************************************************/

public Action Command_RobotMenu( int client, int nArgs )
{		
	if(!IsValidClient(client)) {
		return Plugin_Handled;
	}
		
	if(IsFakeClient(client)) {
		return Plugin_Handled;
	}
		
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

	if(GetGameTime() < g_flLastForceBot[client])
	{
		float flWaitTime = g_flLastForceBot[client] - GetGameTime();
		CReplyToCommand(client, "%t", "Wait Secs to Use", flWaitTime);
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
		if(CheckCommandAccess(client, "bwrr_ownloadout", 0))
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
		if(CheckCommandAccess(client, "bwrr_ownloadout", 0))
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
				if(g_bBotMenuIsGiant[param1]) {
					type = Bot_Giant; 
				} 
				else { 
					type = Bot_Normal; 
				}
				
				int flag = TF2_GetClientFlag(param1);
				if(IsValidEntity(flag)) { 
					TF2_ResetFlag(flag); 
				}
				
				SetRobotOnPlayer(param1, id, type, g_BotMenuSelectedClass[param1]);
				if(type == Bot_Normal) 
				{ 
					RT_GetTemplateName(botname, sizeof(botname), g_BotMenuSelectedClass[param1], id, 0);
					g_flLastForceBot[param1] = GetGameTime() + c_flForceDelay.FloatValue + RT_GetCooldown(g_BotMenuSelectedClass[param1], id, 0);
				} 
				else 
				{ 
					RT_GetTemplateName(botname, sizeof(botname), g_BotMenuSelectedClass[param1], id, 1);
					g_flLastForceBot[param1] = GetGameTime() + c_flFDGiant.FloatValue + RT_GetCooldown(g_BotMenuSelectedClass[param1], id, 1);
				}
				if(GameRules_GetRoundState() == RoundState_BetweenRounds)
				{
					g_flLastForceBot[param1] = GetGameTime() + 5.0; // small cooldown when the wave is not in progress
				}
				if(CheckCommandAccess(param1, "bwrr_gatebot", 0) && IsGatebotAvailable() && Math_GetRandomInt(0,100) <= c_iGatebotChance.IntValue)
				{
					p_bIsGatebot[param1] = true;
				}
				LogAction(param1, -1, "\"%L\" selected a robot (%s)", param1,botname);
				if(Boss_GetClient() == param1)
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
	if(!IsValidClient(client)) {
		return Plugin_Handled;
	}
		
	if(IsFakeClient(client)) {
		return Plugin_Handled;
	}
		
	Menu menu = new Menu(MenuHandler_HelpMenu, MENU_ACTIONS_ALL);
	
	menu.SetTitle("%T", "Menu_Help", client);
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

	return 0;
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

// Create the select team menu
void Menu_ShowJoinTeam(int client)
{
	Menu menu = new Menu(MenuHandler_JoinTeam, MENU_ACTIONS_ALL);
	menu.SetTitle("%T", "Menu_Team_Title", client);
	menu.AddItem("teamred","RED");
	menu.AddItem("teamblu","BLU");
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
	
	return;
}

// Handler for the select team menu
public int MenuHandler_JoinTeam(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[32];
			bool bFound = menu.GetItem(param2, info, sizeof(info));
			if(bFound)
			{
				if(strcmp(info, "teamred") == 0)
				{
					Command_JoinRED(param1, 0);
				}
				else if(strcmp(info, "teamblu") == 0)
				{
					Command_JoinBLU(param1, 0);
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

void Menufunc_CreateEditorMenu(int client)
{
	Menu menu = new Menu(MenuHandler_Editor, MENU_ACTIONS_ALL);
	menu.SetTitle("BWRR Editor");
	menu.AddItem("spy", "Spy Teleport Point");
	menu.AddItem("engineer", "Engineer Teleport Point");
	menu.AddItem("showtelepos", "Show Teleport Points (2048 radius)");
	menu.AddItem("showspawn", "Show Spawn Points (2048 radius)");
	menu.AddItem("tracehull", "Trace Hull Test");
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_Editor(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[32];
			bool bFound = menu.GetItem(param2, info, sizeof(info));
			if(bFound)
			{
				if(strcmp(info, "spy") == 0)
				{
					Config_AddTeleportPoint(param1, 0);
					Menufunc_CreateEditorMenu(param1);
				}
				else if(strcmp(info, "engineer") == 0)
				{
					Config_AddTeleportPoint(param1, 1);
					Menufunc_CreateEditorMenu(param1);
				}
				else if(strcmp(info, "showtelepos") == 0)
				{
					Command_Show_Tele_Pos(param1, 0);
					Menufunc_CreateEditorMenu(param1);
				}
				else if(strcmp(info, "showspawn") == 0)
				{
					Command_Show_SpawnPoints(param1, 0);
					Menufunc_CreateEditorMenu(param1);
				}
				else if(strcmp(info, "tracehull") == 0)
				{
					Command_TraceHull(param1, 0);
					Menufunc_CreateEditorMenu(param1);
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

/**
 * Builds the engineer teleport menu
 *
 * @param client		The client to show the menu to
 * @return     no return
 */
void MenuFunc_CreateEngineerTeleportMenu(int client)
{
	char buffer[64];

	Menu menu = new Menu(MenuHandler_EngineerTeleport, MENU_ACTIONS_ALL);
	menu.SetTitle("%T", "Menu_Engineer_Teleport", client);
	FormatEx(buffer, sizeof(buffer), "%T", "Menu_Item_Random", client);
	menu.AddItem("random", buffer);
	FormatEx(buffer, sizeof(buffer), "%T", "Menu_Item_NearBomb", client);
	menu.AddItem("nearbomb", buffer);
	FormatEx(buffer, sizeof(buffer), "%T", "Menu_Item_NearAllies", client);
	menu.AddItem("nearally", buffer);
	menu.ExitButton = false;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_EngineerTeleport(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[16];
			bool bFound = menu.GetItem(param2, info, sizeof(info));
			if(bFound)
			{
				if(strcmp(info, "random") == 0)
				{
					BWRR_TeleportEngineer(param1, TeleportToRandom);
				}
				else if(strcmp(info, "nearbomb") == 0)
				{
					BWRR_TeleportEngineer(param1, TeleportToBomb);
				}
				else if(strcmp(info, "nearally") == 0)
				{
					BWRR_TeleportEngineer(param1, TeleportToAlly);
				}
			}				
		}
		case MenuAction_Cancel:
		{
			BWRR_TeleportEngineer(param1, TeleportToRandom);
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}

	return 0;
}

/**
 * Builds the spy teleport menu
 *
 * @param client		The client to show the menu to
 * @return     no return
 */
void MenuFunc_CreateSpyTeleportMenu(int client)
{
	char buffer[64];

	Menu menu = new Menu(MenuHandler_SpyTeleport, MENU_ACTIONS_ALL);
	menu.SetTitle("%T", "Menu_Spy_Teleport", client);
	FormatEx(buffer, sizeof(buffer), "%T", "Menu_Item_Random", client);
	menu.AddItem("-1", buffer);
	AddREDPlayersToMenu(menu);
	menu.ExitButton = false;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_SpyTeleport(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[16];
			bool bFound = menu.GetItem(param2, info, sizeof(info));
			if(bFound)
			{
				int iInfo = StringToInt(info);

				if(iInfo == -1) // Random
				{
					TeleportSpyRobot(param1);
				}
				else
				{
					int target = GetClientOfUserId(iInfo); // returns 0 on invalid so the TeleportSpyRobot will teleport to a random place anyways
					TeleportSpyRobot(param1, target);
				}
			}				
		}
		case MenuAction_Cancel:
		{
			TeleportSpyRobot(param1);
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}

	return 0;
}

/**
 * Builds the teleporter spawn menu
 *
 * @param client		The client to show the menu to
 * @return     no return
 */
void MenuFunc_CreateTeleSpawnMenu(int client)
{
	char buffer[64];

	Menu menu = new Menu(MenuHandler_TeleSpawn, MENU_ACTIONS_ALL);
	menu.SetTitle("%T", "Menu_Spawn_On_Teleporter", client);
	FormatEx(buffer, sizeof(buffer), "%T", "Yes", client);
	menu.AddItem("yes", buffer);
	FormatEx(buffer, sizeof(buffer), "%T", "No", client);
	menu.AddItem("no", buffer);
	menu.ExitButton = false;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_TeleSpawn(Menu menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[16];
			bool bFound = menu.GetItem(param2, info, sizeof(info));
			if(bFound)
			{
				if(strcmp(info, "yes", false) == 0)
				{
					BWRR_SpawnOnTeleporter(param1);
				}
				else
				{
					TeleportToSpawnPoint(param1, TF2_GetPlayerClass(param1));
				}
			}
		}
		case MenuAction_Cancel:
		{
			BWRR_SpawnOnTeleporter(param1);
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}

	return 0;
}

/****************************************************
					EVENTS
*****************************************************/

public Action E_WaveStart(Event event, const char[] name, bool dontBroadcast)
{
	Boss_LoadWaveConfig();
	OR_Update();
	PushForcedClasses();
	UpdateClassArray();
	CheckTeams();
	g_flNextBusterTime = GetGameTime() + c_flBusterDelay.FloatValue;
	ResetRobotMenuCooldown();
	SetBLURespawnWaveTime(1.0);
	CreateTimer(1.0, Timer_CheckGates, _, TIMER_FLAG_NO_MAPCHANGE);
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) <= 1)
		{ // Help players that may be stuck on spectator/unassigned team
			CreateTimer(5.0, Timer_HelpUnstuck, GetClientUserId(i), TIMER_FLAG_NO_MAPCHANGE);
		}
	}

	if (c_b32PlayersEnabled.BoolValue) // 32 players mode enable
	{
		RemoveAllMvMBots();
	}
		

	return Plugin_Continue;
}

public Action E_WaveEnd(Event event, const char[] name, bool dontBroadcast)
{
	// CreateTimer(2.0, Timer_UpdateWaveData);
	CreateTimer(2.0, Timer_CheckGates, _, TIMER_FLAG_NO_MAPCHANGE);
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i) && TF2_GetClientTeam(i) == TFTeam_Blue)
		{
			CreateTimer(3.0, Timer_UpdateRobotClasses, i, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	ResetRobotMenuCooldown();

	if (c_b32PlayersEnabled.BoolValue) // 32 players mode enable
	{
		RemoveAllMvMBots();
	}

	return Plugin_Continue;
}

public Action E_WaveFailed(Event event, const char[] name, bool dontBroadcast)
{
	OR_Update();
	UpdateClassArray();
	ResetRobotMenuCooldown();
	CreateTimer(2.0, Timer_RemoveFromSpec, _, TIMER_FLAG_NO_MAPCHANGE);

	if (c_b32PlayersEnabled.BoolValue) // 32 players mode enable
	{
		RemoveAllMvMBots();
	}

	return Plugin_Continue;
}

public Action E_MissionComplete(Event event, const char[] name, bool dontBroadcast)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i) && TF2_GetClientTeam(i) == TFTeam_Blue)
		{
			PreChangeTeam(i, view_as<int>(TFTeam_Red));
			g_flJoinRobotBanTime[i] = GetGameTime() + 40.0;
		}
	}

	return Plugin_Continue;
}

public Action E_ChangeClass(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	TFClassType TFClass = view_as<TFClassType>(event.GetInt("class"));
	
	if(TF2_GetClientTeam(client) == TFTeam_Blue && !IsFakeClient(client))
	{
		if(IsClassAvailable(TFClass))
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

	return Plugin_Continue;
}

public Action E_Pre_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if(TF2_GetClientTeam(client) == TFTeam_Blue && !IsFakeClient(client))
	{
		RoboPlayer rp = RoboPlayer(client);
		if(rp.Attributes & BotAttrib_AlwaysCrits)
		{
			TF2_AddCondition(client, TFCond_CritOnFlagCapture);
		}
		if(rp.Attributes & BotAttrib_AlwaysMiniCrits)
		{
			TF2_AddCondition(client, TFCond_Buffed);
		}
		if(rp.Attributes & BotAttrib_BulletImmune)
		{
			TF2_AddCondition(client, TFCond_BulletImmune);
		}
		if(rp.Attributes & BotAttrib_BlastImmune)
		{
			TF2_AddCondition(client, TFCond_BlastImmune);
		}
		if(rp.Attributes & BotAttrib_FireImmune)
		{
			TF2_AddCondition(client, TFCond_FireImmune);
		}
		rp.ProtectionTime = GetGameTime() + c_flBluProtectionTime.FloatValue;
	}

	return Plugin_Continue;
}

public Action E_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if( IsFakeClient(client) ) {
		CreateTimer(1.0, Timer_OnFakePlayerSpawn, client, TIMER_FLAG_NO_MAPCHANGE);
	}
	else {
		CreateTimer(0.3, Timer_OnPlayerSpawn, client, TIMER_FLAG_NO_MAPCHANGE);
	}
	
	if(!IsWaveDataBuilt())
	{
		OR_Update();
		UpdateClassArray();
	}
	
	if(!IsFakeClient(client) && !g_bWelcomeMsg[client] && TF2_GetClientTeam(client) == TFTeam_Red)
	{
		CreateTimer(5.0, Timer_ShowWelcMsg, client, TIMER_FLAG_NO_MAPCHANGE);
		g_bWelcomeMsg[client] = true;
	}

	return Plugin_Continue;
}

public Action E_Pre_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int deathflags = event.GetInt("death_flags");
	if(deathflags & TF_DEATHFLAG_DEADRINGER) {
		return Plugin_Handled;
	}
		
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(GameRules_GetRoundState() == RoundState_BetweenRounds && TF2_GetClientTeam(client) == TFTeam_Blue && !IsFakeClient(client))
	{
		event.SetBool("silent_kill", true);
	}
	
	return Plugin_Continue;
}

public Action E_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	int customkill = event.GetInt("customkill");
	TFTeam clientteam = TF2_GetClientTeam(client);
	
	int deathflags = event.GetInt("death_flags");
	if(deathflags & TF_DEATHFLAG_DEADRINGER)
		return Plugin_Handled;
		
	DeleteParticleOnPlayerDeath(client); // Check and delete any particle effect we might have added to the player.
	
	if(clientteam == TFTeam_Blue && customkill == TF_CUSTOM_BACKSTAB) // victim is on BLU and was killed by backstab
	{
		DataPack pack = new DataPack();
		pack.WriteCell(event.GetInt("userid"));
		pack.WriteCell(event.GetInt("attacker"));
		RequestFrame(FrameBLUBackstabbed, pack);
	}
	
	RoboPlayer rp = RoboPlayer(client);
	
	if(clientteam == TFTeam_Blue && !IsFakeClient(client))
	{
		if(TF2_IsGiant(client)) // Giant BLU human killed
		{
			TF2_SpeakConcept(MP_CONCEPT_MVM_GIANT_KILLED, view_as<int>(TFTeam_Red), "");
		}
		
		if(c_bDropCurrency.BoolValue && GameRules_GetRoundState() == RoundState_RoundRunning && !rp.InSpawn)
		{
			int amount;
			// Drop Currency
			switch(rp.Type)
			{
				case Bot_Boss:
				{
					amount = Boss_GetCurrency();
				}
				case Bot_Giant:
				{
					amount = RT_GetCurrency(TF2_GetPlayerClass(client), rp.Variant, 1);
				}
				case Bot_Buster: amount = 0;
				default:
				{
					amount = RT_GetCurrency(TF2_GetPlayerClass(client), rp.Variant, 0);
				}
			}
			
			if(amount > 0)
			{
				if(attacker > 0 && attacker <= MaxClients && TF2_GetClientTeam(attacker) == TFTeam_Red)
				{
					TF2_DropCurrencyPack(client, TF_CURRENCY_PACK_CUSTOM, amount, true, attacker);
#if defined DEBUG_PLAYER
				CPrintToChatAll("{green}[DEBUG] {gray}DropCurrency:: {cyan} Player: %N - Amount: %i", client, amount);
#endif
				}
			}
		}
	
		rp.Gatebot = false;
		rp.Detonating = false;
		rp.BusterTime = -1.0;
	
		if(client == Boss_GetClient())
		{
			Boss_Death();
		}
	
		if(TF2_GetPlayerClass(client) == TFClass_Engineer)
		{
			AnnounceEngineerDeath(client);
			RequestFrame(FrameEngineerDeath, GetClientUserId(client));
		}
		else if(TF2_GetPlayerClass(client) == TFClass_Spy)
		{
			if(GetClassCount(TFClass_Spy, TFTeam_Blue, true, false) <= 1)
				EmitGSToRed("Announcer.mvm_spybot_death_all");
		}
		SetEntProp(client, Prop_Send, "m_bIsMiniBoss", 0);
		SetEntProp(client, Prop_Send, "m_bUseBossHealthBar", 0);
		
		switch(rp.Type)
		{
			case Bot_Giant, Bot_Boss:
			{
				float clientPosVec[3];
				GetClientAbsOrigin(client, clientPosVec);
				EmitGameSoundToAll("MVM.GiantHeavyExplodes", client, SND_NOFLAGS, client, clientPosVec);
			}
		}
		
		RequestFrame(FramePickNewRobot, GetClientUserId(client));
		StopRobotLoopSound(client);
	}
	
	if(clientteam == TFTeam_Red && attacker > 0 && attacker <= MaxClients && !IsFakeClient(attacker)) // RED player was killed by human BLU player
	{
		if(TF2_IsGiant(attacker)) // Killed by giant human
		{
			TF2_SpeakConcept(MP_CONCEPT_MVM_GIANT_KILLED_TEAMMATE, view_as<int>(TFTeam_Red), "");
		}
	}

	SpyDisguiseClear(client);
	
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
			if(p_iBotVariant[client] >= 0)
			{
				StripItems(client, true); // true: remove weapons

				switch(p_iBotType[client])
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
						Buster_GiveInventory(client);
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

	return Plugin_Continue;
}

public Action E_Teamplay_Flag(Event event, const char[] name, bool dontBroadcast)
{
	if(event.GetInt("eventtype") == TF_FLAGEVENT_PICKEDUP)
	{
		int client = event.GetInt("player");
		RoboPlayer rp = RoboPlayer(client);
		if(!IsFakeClient(client))
		{
			rp.Carrier = true;
			if(TF2_IsGiant(client))
			{
				rp.BombLevel = 4;
				TF2_SpeakConcept(MP_CONCEPT_MVM_GIANT_HAS_BOMB, view_as<int>(TFTeam_Red), "");
			}
			else
			{
				rp.BombLevel = 0;
				rp.UpgradeTime = GetGameTime() + GetConVarFloat(FindConVar("tf_mvm_bot_flag_carrier_interval_to_1st_upgrade"));
				TF2_SpeakConcept(MP_CONCEPT_MVM_BOMB_PICKUP, view_as<int>(TFTeam_Red), "");
			}
			RequestFrame(UpdateBombHud, GetClientUserId(client));
		}
	}
	if(event.GetInt("eventtype") == TF_FLAGEVENT_DROPPED)
	{
		int client = event.GetInt("player");
		RoboPlayer rp = RoboPlayer(client);
		if(!IsFakeClient(client))
		{
			rp.Carrier = false;
			rp.Deploying = false;
			rp.DeployTime = -1.0;
		}
	}

	return Plugin_Continue;
}

public Action E_BuildObject(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	int index = event.GetInt("index");
	if(!IsFakeClient(client) && GetEntProp( index, Prop_Send, "m_iTeamNum" ) == view_as<int>(TFTeam_Blue))
	{
		CreateTimer(0.1, Timer_BuildObject, index, TIMER_FLAG_NO_MAPCHANGE);
	}

	return Plugin_Continue;
}

// Event: MvM Win Panel
public Action E_MVM_WinPanel(Event event, const char[] name, bool dontBroadcast)
{
	int winningteam = event.GetInt("winning_team");

	if(winningteam == view_as<int>(TFTeam_Blue) && c_bAntiJoinSpam.BoolValue)
	{
		for(int i = 1;i <= MaxClients;i++)
		{
			if(IsClientInGame(i) && !IsFakeClient(i) && TF2_GetClientTeam(i) == TFTeam_Blue)
			{ // Apply cooldown on BLU players when they win
				g_flJoinRobotBanTime[i] = GetGameTime() + 75.0;
				LogMessage("Applying join blu cooldown on \"%L\". Reason: ROBOT Victory.", i);
			}
		}
	}

	return Plugin_Continue;
}

/****************************************************
					USER MESSAGE
*****************************************************/

public Action MsgHook_MVMRespec(UserMsg msg_id, BfRead msg, const int[] players, int playersNum, bool reliable, bool init)
{
	int client = BfReadByte(msg); //client that used the respec    
	OnRefund(client);

	return Plugin_Continue;
}

/****************************************************
					TIMERS
*****************************************************/

public Action Timer_OnPlayerSpawn(Handle timer, any client)
{	
	if(!IsValidClient(client)) {
		return Plugin_Stop;
	}
		
	TFClassType TFClass = p_BotClass[client];
	char strBotName[255], strBotDesc[255];
	RoboPlayer rp = RoboPlayer(client);
		
	if(TF2_GetClientTeam(client) == TFTeam_Blue && !IsFakeClient(client))
	{
		if(TF2_GetPlayerClass(client) != rp.Class)
		{
			TF2_SetPlayerClass(client, rp.Class, _, true);
		}
	
		rp.Carrier = false;
		rp.ReloadingBarrage = false;
		g_flinstructiontime[client] = GetGameTime() + 2.0;
		
		int iActiveWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if(IsValidEntity(iActiveWeapon))
		{
			int iMaxClip = GetWeaponMaxClip(iActiveWeapon);
			int iClip = GetWeaponClip(iActiveWeapon);
			if(iClip != iMaxClip) // set weapon to full clip
			{
				SetWeaponClip(iActiveWeapon, iMaxClip);
			}
		}
		
		// Automatically disguise spy with 'AutoDisguise' attribute.
		if(TFClass == TFClass_Spy && rp.Attributes & BotAttrib_AutoDisguise)
		{
			int iTarget = GetRandomClientFromTeam(view_as<int>(TFTeam_Red), false);
			if(iTarget >= 1 && iTarget <= MaxClients)
			{
				TF2_DisguisePlayer(client, TFTeam_Red, TF2_GetPlayerClass(iTarget), iTarget);
			}
		}
		
		// Set full charge on the player
		if(rp.Attributes & BotAttrib_FullCharge)
		{
			switch(TFClass)
			{
				case TFClass_Scout:
				{
					SetEntPropFloat(client, Prop_Send, "m_flHypeMeter", 100.0);
				}
				case TFClass_Medic:
				{
					SetEntPropFloat(client, Prop_Send, "m_flRageMeter", 100.0); // Medigun's Shield
					int iWeapon = TF2_GetPlayerLoadoutSlot(client, TF2LoadoutSlot_Secondary);
					if(IsValidEntity(iWeapon))
						SetEntPropFloat(iWeapon, Prop_Send, "m_flChargeLevel", 1.0);				
				}
				case TFClass_Heavy: // Heavy with knockback rage attribute
				{
					SetEntPropFloat(client, Prop_Send, "m_flRageMeter", 100.0);
				}
				case TFClass_Soldier: // Soldier's banner
				{
					SetEntPropFloat(client, Prop_Send, "m_flRageMeter", 100.0);
					SetEntProp(client, Prop_Send, "m_iDecapitations", 10); // Airstrike
				}
				case TFClass_DemoMan: // Eyelander
				{
					SetEntProp(client, Prop_Send, "m_iDecapitations", 5);
				}
				case TFClass_Engineer: // Frontier Justice
				{
					SetEntProp(client, Prop_Send, "m_iRevengeCrits", 35);
				}
				case TFClass_Pyro: // Phlogistinator
				{
					SetEntPropFloat(client, Prop_Send, "m_flRageMeter", 100.0);
				}
				case TFClass_Sniper: // Hitman's Headtaker
				{
					SetEntPropFloat(client, Prop_Send, "m_flRageMeter", 100.0);
					SetEntProp(client, Prop_Send, "m_iDecapitations", 10); // Bazaar Bargain
				}
				case TFClass_Spy: // Diamond Back
				{
					SetEntProp(client, Prop_Send, "m_iRevengeCrits", 35);
				}
			}
		}

		if(rp.Attributes & BotAttrib_CannotCarryBomb)
		{
			BlockBombPickup(client);
		}
		else if(GameRules_GetRoundState() == RoundState_RoundRunning && !rp.Gatebot && (TFClass != TFClass_Spy || TFClass != TFClass_Engineer)) // Don't give the bomb on spawn for gatebots, spies and engineers.
		{
			RequestFrame(FrameCheckFlagForPickUp, GetClientUserId(client));
		}
		
		if(OR_IsHalloweenMission())
		{
			if(Math_RandomChance(c_fl666CritChance.IntValue))
				TF2_AddCondition(client, TFCond_CritOnFlagCapture, TFCondDuration_Infinite);
		}
		
		switch(rp.Type)
		{
			case Bot_Giant:
			{
				RT_GetTemplateName(strBotName, sizeof(strBotName), TFClass, p_iBotVariant[client], 1);
				RT_GetDescription(strBotDesc, sizeof(strBotDesc), TFClass, p_iBotVariant[client], 1);
				SetEntProp( client, Prop_Send, "m_bIsMiniBoss", 1 ); // has nothing to do with variant name but same condition
				ApplyRobotLoopSound(client);
				RT_SetHealth(client, p_BotClass[client], p_iBotVariant[client], 1);	
				if(Math_RandomChance(RT_GetFullCritsChance(p_BotClass[client], p_iBotVariant[client], 1))) {
					TF2_AddCondition(client, TFCond_CritOnFlagCapture, TFCondDuration_Infinite);
				}
			}
			case Bot_Boss:
			{
				char bossname[64];
				Boss_GetName(bossname, sizeof(bossname));
				Boss_GetName(strBotName, sizeof(strBotName));
				if(Boss_IsGatebot()) {
					Format(bossname, sizeof(bossname), "Gatebot %s", bossname);
				}
				SetEntProp(client, Prop_Send, "m_bIsMiniBoss", 1);
				SetEntProp(client, Prop_Send, "m_bUseBossHealthBar", 1);
				Boss_SetHealth(client);
				ApplyRobotLoopSound(client);
				char plrname[MAX_NAME_LENGTH];
				GetClientName(client, plrname, sizeof(plrname));
				CPrintToChatAll("%t", "Boss_Spawn", plrname, bossname, Boss_ComputeHealth());
				LogAction(client, -1, "Player \"%L\" spawned as a boss robot ( %s ).", client, bossname);
				EmitGameSoundToAll("MVM.GiantHeavyEntrance", SOUND_FROM_PLAYER);
			}
			case Bot_Buster:
			{
				Buster_GetName(strBotName, sizeof(strBotName));
				SetEntProp( client, Prop_Send, "m_bIsMiniBoss", 1 );
				EmitGSToRed("Announcer.MVM_Sentry_Buster_Alert");
				ApplyRobotLoopSound(client);
				Buster_SetHealth(client);
				CPrintToChat(client, "%t", "SB_Instructions");
				TF2_SpeakConcept(MP_CONCEPT_MVM_SENTRY_BUSTER, view_as<int>(TFTeam_Red), "");
			}
			default:
			{
				RT_GetTemplateName(strBotName, sizeof(strBotName), TFClass, p_iBotVariant[client], 0);
				RT_GetDescription(strBotDesc, sizeof(strBotDesc), TFClass, p_iBotVariant[client], 0);
				StopRobotLoopSound(client);
				RT_SetHealth(client, p_BotClass[client], p_iBotVariant[client], 0);
				if( IsGateStunActive() ) { 
					ApplyGateStunToClient(client); 
				}
				if(Math_RandomChance(RT_GetFullCritsChance(p_BotClass[client], p_iBotVariant[client], 1))) {
					TF2_AddCondition(client, TFCond_CritOnFlagCapture, TFCondDuration_Infinite);
				}
			}
		}
		
		if(rp.Gatebot)
		{
			Format(strBotName, sizeof(strBotName), "Gatebot %s", strBotName); // add Gatebot prefix to robot name
			GiveGatebotHat(client, TFClass);
			BlockBombPickup(client);
		}

		CPrintToChat(client, "%t", "Bot Spawn", strBotName);
		if(strlen(strBotDesc) > 3) { CPrintToChat(client, "%s", strBotDesc); }
		SetRobotScale(client,TFClass);
		SetRobotModel(client,TFClass);
		
		// teleport player
		if(GameRules_GetRoundState() == RoundState_RoundRunning)
		{
			if(rp.Type == Bot_Giant || rp.Type == Bot_Boss)
			{ // Don't speak during setup
				TF2_SpeakConcept(MP_CONCEPT_MVM_GIANT_CALLOUT, view_as<int>(TFTeam_Red), "");
			}

			if(IsGateStunActive())
			{
				TeleportToSpawnPoint(client, TFClass);
			}
			else
			{
				switch(TFClass)
				{
					case TFClass_Spy: // spies should always spawn near RED players
					{
						EmitGSToRed("Announcer.MVM_Spy_Alert");
						MenuFunc_CreateSpyTeleportMenu(client);
					}
					case TFClass_Engineer:
					{
						if(CanSpawnOnTeleporter()) // first search for teleporter
						{
							MenuFunc_CreateTeleSpawnMenu(client);
						}
						else // no teleporter found
						{
							if(rp.Attributes & BotAttrib_TeleportToHint) // Check if we should teleport this engineer
							{
								MenuFunc_CreateEngineerTeleportMenu(client); // Send the menu to allow the client to select where to teleport
							}
							else
							{
								TeleportToSpawnPoint(client, TFClass);
							}
						}
					}
					case TFClass_Sniper:
					{
						TF2_SpeakConcept(MP_CONCEPT_MVM_SNIPER_CALLOUT, view_as<int>(TFTeam_Red), "");
						if(CanSpawnOnTeleporter()) // found teleporter
						{
							MenuFunc_CreateTeleSpawnMenu(client);
						}
						else
						{
							TeleportToSpawnPoint(client, TFClass);
						}					
					}
					default: // other classes
					{
						if(CanSpawnOnTeleporter()) // found teleporter
						{
							MenuFunc_CreateTeleSpawnMenu(client);
						}
						else
						{
							TeleportToSpawnPoint(client, TFClass);
						}
					}
				}
			}
		}
		else
		{
			TeleportToSpawnPoint(client, TFClass);
		}
		
		// apply attributes to own loadout
		if(rp.Variant == -1)
		{
			if(rp.Type == Bot_Giant)
				SetOwnAttributes(client ,true);
			else
				SetOwnAttributes(client ,false);
				
			TF2_RegeneratePlayer(client);
			if(rp.Gatebot) { 
				GiveGatebotHat(client, TFClass); 
				BlockBombPickup(client);
			} // TF2_RegeneratePlayer will cause the hat to be removed, add it again.
		}
	}
#if defined DEBUG_PLAYER
	if(TF2_GetClientTeam(client) == TFTeam_Blue)
	{
		CPrintToChat(client, "{green}[DEBUG]{cyan} Robot Type: %d", rp.Type);
		CPrintToChat(client, "{green}[DEBUG]{cyan} Robot Variant: %d", rp.Variant);
		CPrintToChat(client, "{green}[DEBUG]{cyan} Robot Attributes: %d", rp.Attributes);
		CPrintToChat(client, "{green}[DEBUG]{cyan} Robot Class: %d (%d)", view_as<int>(rp.Class), view_as<int>(TFClass));
	}
#endif
	return Plugin_Stop;
}

public Action Timer_OnFakePlayerSpawn(Handle timer, any client)
{	
	if(IsClientInGame(client) && TF2_GetPlayerClass(client) != TFClass_Spy)  // teleport bots to teleporters
	{
		int teleporter;
		float center[3];
		GetEntityWorldCenter(client, center);
		if(TF2_IsPointInRespawnRoom(client, center, true) && FindBestTeleporter(teleporter))
		{
			SpawnOnTeleporter(teleporter, client);
		}
	}
	
	return Plugin_Stop;
}
// Delayed set class to fix some small bugs
public Action Timer_SetRobotClass(Handle timer, any client)
{
	if(!IsValidClient(client) || IsFakeClient(client)) {
		return Plugin_Stop;
	}
		
	TF2_SetPlayerClass(client, p_BotClass[client], true, true);
	
	return Plugin_Stop;
}

public Action Timer_Respawn(Handle timer, any client)
{
	if(!IsValidClient(client) || IsFakeClient(client)) {
		return Plugin_Stop;
	}
		
	TF2_RespawnPlayer(client);
	
	return Plugin_Stop;
}

/* public Action Timer_UpdateWaveData(Handle timer)
{
	OR_Update();
	Boss_LoadWaveConfig();
	PushForcedClasses();
	UpdateClassArray();
	
	return Plugin_Stop;
} */

public Action Timer_CheckGates(Handle timer)
{
	IsGatebotAvailable(true);
	return Plugin_Stop;
}

public Action Timer_GateCaptured(Handle timer)
{
	if(!IsGatebotAvailable(true))
	{
		ReverseGateBots();
	}
	return Plugin_Stop;
}

public Action Timer_UpdateRobotClasses(Handle timer, any client)
{
	PickRandomRobot(client);
	CreateTimer(0.5, Timer_Respawn, client, TIMER_FLAG_NO_MAPCHANGE);
	
	return Plugin_Stop;
}
// Used to move players back to RED team when a wave fails
// TF2 automatically removes humans from BLU team when a wave is lost
public Action Timer_RemoveFromSpec(Handle timer, any client)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i) && TF2_GetClientTeam(i) == TFTeam_Spectator)
		{
			PreChangeTeam(i, view_as<int>(TFTeam_Red));
		}
	}
	
	return Plugin_Stop;
}

public Action Timer_BuildObject(Handle timer, any index)
{
	char classname[32];
	
	if(IsValidEdict(index))
	{
		GetEdictClassname(index, classname, sizeof(classname));
		float vPos[3];
		GetEntPropVector(index, Prop_Send, "m_vecOrigin", vPos);
		TF2_PushAllPlayers(vPos, 400.0, 500.0, view_as<int>(TFTeam_Red)); // Push players
		
		if(strcmp(classname, "obj_sentrygun", false) == 0)
		{
			if(GetEntProp(index, Prop_Send, "m_bMiniBuilding") == 1 || GetEntProp(index, Prop_Send, "m_bDisposableBuilding") == 1)
			{ // mini building, don't set to level 3
				DispatchKeyValue(index, "defaultupgrade", "0");
			}
			else // normal building, set to level 3
			{
				DispatchKeyValue(index, "defaultupgrade", "2");
			}
		}
		else if(strcmp(classname, "obj_dispenser", false) == 0)
		{
			SetEntProp(index, Prop_Send, "m_bMiniBuilding", 1);
			SetEntPropFloat(index, Prop_Send, "m_flModelScale", 0.90);
			SetVariantInt(100);
			AcceptEntityInput(index, "SetHealth");			
		}
		else if(strcmp(classname, "obj_teleporter", false) == 0)
		{
			int iBuilder = GetEntPropEnt( index, Prop_Send, "m_hBuilder" );
			
			if(!IsValidClient(iBuilder))
				return Plugin_Stop;

			if(p_iBotAttrib[iBuilder] & BotAttrib_CannotBuildTele)
			{ // This engineer variant can't building teleporters
				SetVariantInt(9999);
				AcceptEntityInput(index, "RemoveHealth");
				PrintCenterText(iBuilder, "YOU CANNOT BUILD TELEPORTERS");
			}
			else if(TF2_GetObjectMode(index) == TFObjectMode_Entrance)
			{
				SetVariantInt(9999);
				AcceptEntityInput(index, "RemoveHealth");
				PrintCenterText(iBuilder, "BUILD EXIT");
			}
			else
			{
				if(CheckTeleportClamping(index, iBuilder))
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
	if(!IsValidEntity(index)) {
		return Plugin_Stop;
	}
		
	if(!HasEntProp(index, Prop_Send, "m_flPercentageConstructed")) {
		return Plugin_Stop;
	}
		
	float flProgress = GetEntPropFloat(index, Prop_Send, "m_flPercentageConstructed");
	
	if(flProgress >= 1.0)
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

public Action Timer_DeleteParticle(Handle timer, any iEntRef)
{
	int iParticle = EntRefToEntIndex( iEntRef );
	
	if(iParticle == INVALID_ENT_REFERENCE) {
		return Plugin_Stop;
	}
	
	if(IsValidEntity(iParticle))
	{
		char strClassname[64];
		GetEdictClassname( iParticle, strClassname, sizeof(strClassname) );
		if( strcmp( strClassname, "info_particle_system", false ) == 0 )
			RemoveEntity(iParticle);
	}
	
	return Plugin_Stop;
}

public Action Timer_RemoveBody(Handle timer, any client)
{
	if(!IsClientInGame(client)) {
		return Plugin_Stop;
	}

	if(IsFakeClient(client)) {
		return Plugin_Stop;
	}

	int ragdoll;
	ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");

	if(IsValidEntity(ragdoll)) 
		RemoveEntity(ragdoll);
		
	return Plugin_Stop;
}

public Action Timer_RemoveGibs(Handle timer, any entity)
{
	if(IsValidEntity(entity))
	{
		char classname[64];
		GetEntityClassname(entity, classname, sizeof(classname));
		if(strcmp(classname, "tf_ragdoll", false) == 0)
		{
			RemoveEntity(entity);
		}
	}

	return Plugin_Stop;
}

// Applies the giant sound, needs delay to compensate for latency
public Action Timer_ApplyRobotSound(Handle timer, any client)
{
	if(!IsValidClient(client) || IsFakeClient(client)) {
		return Plugin_Stop;
	}

	TFClassType TFClass = TF2_GetPlayerClass(client);
	switch(TFClass)
	{
		case TFClass_Scout: EmitSoundToAll(ROBOT_SND_GIANT_SCOUT, client, SNDCHAN_STATIC, 85);
		case TFClass_Soldier: EmitSoundToAll(ROBOT_SND_GIANT_SOLDIER, client, SNDCHAN_STATIC, 82);
		case TFClass_Pyro: EmitSoundToAll(ROBOT_SND_GIANT_PYRO, client, SNDCHAN_STATIC, 83);
		case TFClass_DemoMan:
		{
			if(p_iBotType[client] == Bot_Buster)
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
	if(!IsValidClient(client) || IsFakeClient(client)) {
		return Plugin_Stop;
	}
		
	CPrintToChat(client, "%t", "Welcome_Msg");
	
	return Plugin_Stop;
}

public Action Timer_HelpUnstuck(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	
	if(!IsValidClient(client) || IsFakeClient(client)) {
		return Plugin_Stop;
	}
	
	if(GetClientTeam(client) <= 1)
	{
		// moving players automatically to RED causes them to be unable to close the MOTD with the mouse
		// to avoid issues, print a message telling players to type the join team command in chat.
		CPrintToChat(client, "%t", "Spec_Stuck");
		Menu_ShowJoinTeam(client);
	}
	
	return Plugin_Stop;
}

/****************************************************
					FUNCTIONS
*****************************************************/

// ***PLAYER***

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

bool IsWaveDataBuilt()
{
	if(array_avclass.Length >= 1 || array_avgiants.Length >= 1)
	{
		return true;
	}
	
	return false;
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
	if(array_avclass.Length < 1)
		return false;
		
	// Class limit disabled
	if(!c_bLimitClasses.BoolValue)
		return true;

	if (c_b32PlayersEnabled.BoolValue) // 32 players mode enable
		return true;
		
	int iClass = view_as<int>(TFClass);
	
	if(bGiants)
	{
		if(array_avgiants.FindValue(iClass) != -1)
			return true;
	}
	else
	{
		if(array_avclass.FindValue(iClass) != -1)
			return true;
	}

	return false;	
}

// ***ROBOT VARIANT***
// Selects a random robot for the given client.
void PickRandomRobot(int client)
{
	if(!IsClientInGame(client) || IsFakeClient(client)) {
		return;
	}
	
	int iSize, iRandom, iClass;
	bool bGiants = false;
	RoboPlayer rp = RoboPlayer(client);
	
	// First, check if we can spawn a buster or a boss robot.
	if(GameRules_GetRoundState() == RoundState_RoundRunning)
	{
		// Boss
		Boss_Think(); // Boss think function
		
		if(CheckCommandAccess(client, "bwrr_boss", 0) && Boss_CanSpawn())
		{
			Boss_SetupPlayer(client);
			CreateTimer(0.1, Timer_SetRobotClass, client, TIMER_FLAG_NO_MAPCHANGE);
			return;
		}
	
		// Check cooldown, spawn conditions and permission
		if(CheckCommandAccess(client, "bwrr_sentrybuster", 0) && GetGameTime() > g_flNextBusterTime && ShouldDispatchSentryBuster())
		{
			Buster_SetupClient(client);
			g_flNextBusterTime = GetGameTime() + c_flBusterDelay.FloatValue;
			CreateTimer(0.1, Timer_SetRobotClass, client, TIMER_FLAG_NO_MAPCHANGE);
			return;
		}
	}
	
	rp.Gatebot = false;
	if(CheckCommandAccess(client, "bwrr_gatebot", 0) && IsGatebotAvailable() && Math_GetRandomInt(1,100) <= c_iGatebotChance.IntValue)
	{
		rp.Gatebot = true;
	}
	
	// Checks if giants are allowed.
	if(OR_IsGiantAvaiable && Math_GetRandomInt(1, 100) <= c_iGiantChance.IntValue && GetTeamClientCount(2) >= c_iGiantMinRed.IntValue && array_avgiants.Length >= 1)
	{
		bGiants = true;
	}
	
	if(array_avgiants.Length >= 1 && array_avclass.Length < 1) // Normal robots not available for the current wave.
		bGiants = true;
	
	if(bGiants && c_bLimitClasses.BoolValue) // Spawn the player as a giant robot.
	{
		iSize = GetArraySize(array_avgiants) - 1;
		iRandom = Math_GetRandomInt(0, iSize);
		iClass = array_avgiants.Get(iRandom);
	}
	else if(c_bLimitClasses.BoolValue) // Spawn the player as a normal robot.
	{
		iSize = GetArraySize(array_avclass) - 1;
		iRandom = Math_GetRandomInt(0, iSize);
		iClass = array_avclass.Get(iRandom);
	}
	else
	{
		iClass = Math_GetRandomInt(1,9); // class limit disabled, pick a random one
	}
	
	
	// select a random robot variant
	switch(iClass)
	{
		case 1: // scout
		{
			PickRandomVariant(client, TFClass_Scout, bGiants);
		}
		case 2: // sniper
		{
			PickRandomVariant(client, TFClass_Sniper, false);
		}
		case 3: // soldier
		{
			PickRandomVariant(client, TFClass_Soldier, bGiants);
		}
		case 4: // demoman
		{
			PickRandomVariant(client, TFClass_DemoMan, bGiants);
		}
		case 5: // medic
		{
			PickRandomVariant(client, TFClass_Medic, bGiants);
		}
		case 6: // heavy
		{
			PickRandomVariant(client, TFClass_Heavy, bGiants);
		}
		case 7: // pyro
		{
			PickRandomVariant(client, TFClass_Pyro, bGiants);
		}
		case 8: // spy
		{
			PickRandomVariant(client, TFClass_Spy, false);
		}
		case 9: // engineer
		{
			PickRandomVariant(client, TFClass_Engineer, false);
		}
	}
}

// selects a random variant based on the player's class
void PickRandomVariant(int client,TFClassType TFClass,bool bGiants = false)
{
	if(IsFakeClient(client)) {
		return;
	}

	int iRandomMin = 0;
	
	if(CheckCommandAccess(client, "bwrr_ownloadout", 0)) {
		iRandomMin = -1;
	}
	
	CreateTimer(0.1, Timer_SetRobotClass, client, TIMER_FLAG_NO_MAPCHANGE);
	if(bGiants)
	{
		// giant
		p_iBotType[client] = Bot_Giant;
		switch(TFClass)
		{
			case TFClass_Scout:
			{
				p_iBotVariant[client] = Math_GetRandomInt(iRandomMin, (RT_NumTemplates(true, TFClass) - 1));
				p_BotClass[client] = TFClass_Scout;
			}
			case TFClass_Soldier:
			{
				p_iBotVariant[client] = Math_GetRandomInt(iRandomMin, (RT_NumTemplates(true, TFClass) - 1));
				p_BotClass[client] = TFClass_Soldier;
			}
			case TFClass_Pyro:
			{
				p_iBotVariant[client] = Math_GetRandomInt(iRandomMin, (RT_NumTemplates(true, TFClass) - 1));
				p_BotClass[client] = TFClass_Pyro;
			}
			case TFClass_DemoMan:
			{
				p_iBotVariant[client] = Math_GetRandomInt(iRandomMin, (RT_NumTemplates(true, TFClass) - 1));
				p_BotClass[client] = TFClass_DemoMan;
			}
			case TFClass_Heavy:
			{
				p_iBotVariant[client] = Math_GetRandomInt(iRandomMin, (RT_NumTemplates(true, TFClass) - 1));
				p_BotClass[client] = TFClass_Heavy;
			}
			case TFClass_Engineer:
			{
				p_iBotVariant[client] = Math_GetRandomInt(iRandomMin, (RT_NumTemplates(true, TFClass) - 1));
				p_BotClass[client] = TFClass_Engineer;
			}
			case TFClass_Medic:
			{
				p_iBotVariant[client] = Math_GetRandomInt(iRandomMin, (RT_NumTemplates(true, TFClass) - 1));
				p_BotClass[client] = TFClass_Medic;
			}
			case TFClass_Sniper:
			{
				p_iBotVariant[client] = Math_GetRandomInt(iRandomMin, (RT_NumTemplates(true, TFClass) - 1));
				p_BotClass[client] = TFClass_Sniper;
			}
			case TFClass_Spy:
			{
				p_iBotVariant[client] = Math_GetRandomInt(iRandomMin, (RT_NumTemplates(true, TFClass) - 1));
				p_BotClass[client] = TFClass_Spy;
			}
		}
		SetGiantVariantExtras(client, TFClass, p_iBotVariant[client]);
	}
	else
	{
		// normal
		p_iBotType[client] = Bot_Normal;
		switch(TFClass)
		{
			case TFClass_Scout:
			{
				p_iBotVariant[client] = Math_GetRandomInt(iRandomMin, (RT_NumTemplates(false, TFClass) - 1));
				p_BotClass[client] = TFClass_Scout;
			}
			case TFClass_Soldier:
			{
				p_iBotVariant[client] = Math_GetRandomInt(iRandomMin, (RT_NumTemplates(false, TFClass) - 1));
				p_BotClass[client] = TFClass_Soldier;
			}
			case TFClass_Pyro:
			{
				p_iBotVariant[client] = Math_GetRandomInt(iRandomMin, (RT_NumTemplates(false, TFClass) - 1));
				p_BotClass[client] = TFClass_Pyro;
			}
			case TFClass_DemoMan:
			{
				p_iBotVariant[client] = Math_GetRandomInt(iRandomMin, (RT_NumTemplates(false, TFClass) - 1));
				p_BotClass[client] = TFClass_DemoMan;
			}
			case TFClass_Heavy:
			{
				p_iBotVariant[client] = Math_GetRandomInt(iRandomMin, (RT_NumTemplates(false, TFClass) - 1));
				p_BotClass[client] = TFClass_Heavy;
			}
			case TFClass_Engineer:
			{
				p_iBotVariant[client] = Math_GetRandomInt(iRandomMin, (RT_NumTemplates(false, TFClass) - 1));
				p_BotClass[client] = TFClass_Engineer;
			}
			case TFClass_Medic:
			{
				p_iBotVariant[client] = Math_GetRandomInt(iRandomMin, (RT_NumTemplates(false, TFClass) - 1));
				p_BotClass[client] = TFClass_Medic;
			}
			case TFClass_Sniper:
			{
				p_iBotVariant[client] = Math_GetRandomInt(iRandomMin, (RT_NumTemplates(false, TFClass) - 1));
				p_BotClass[client] = TFClass_Sniper;
			}
			case TFClass_Spy:
			{
				p_iBotVariant[client] = Math_GetRandomInt(iRandomMin, (RT_NumTemplates(false, TFClass) - 1));
				p_BotClass[client] = TFClass_Spy;
			}
		}
		SetVariantExtras(client, TFClass, p_iBotVariant[client]);
	}
}

// Sets a specific robot on a player
void SetRobotOnPlayer(int client, int iVariant, int type, TFClassType TFClass)
{
	if(!IsValidClient(client) && !IsPlayerAlive(client)) {
		return;
	}
		
	if(TF2_GetClientTeam(client) != TFTeam_Blue) {
		return;
	}
		
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

	RoboPlayer rp = RoboPlayer(client);
	rp.Type = type;
	rp.Variant = iVariant;
	rp.Class = TFClass;

	if(type == Bot_Giant)
		SetGiantVariantExtras(client, TFClass, iVariant);
	else
		SetVariantExtras(client, TFClass, iVariant);
		
	CreateTimer(0.1, Timer_SetRobotClass, client, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(0.5, Timer_Respawn, client, TIMER_FLAG_NO_MAPCHANGE);
}

void SetBossOnPlayer(int client)
{
	Boss_SetupPlayer(client);
	CreateTimer(0.1, Timer_SetRobotClass, client, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(0.5, Timer_Respawn, client, TIMER_FLAG_NO_MAPCHANGE);	
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
	switch(TFClass)
	{
		case TFClass_Scout:
		{
			if(bGiants)
			{
				if(iVariant >= -1 && iVariant <= (RT_NumTemplates(true, TFClass) - 1)) // - 1 needed since arrays start with 0
					bValid = true;
			}
			else
			{
				if(iVariant >= -1 && iVariant <= (RT_NumTemplates(false, TFClass) - 1))
					bValid = true;
			}
		}
		case TFClass_Soldier:
		{
			if(bGiants)
			{
				if(iVariant >= -1 && iVariant <= (RT_NumTemplates(true, TFClass) - 1))
					bValid = true;
			}
			else
			{
				if(iVariant >= -1 && iVariant <= (RT_NumTemplates(false, TFClass) - 1))
					bValid = true;
			}
		}
		case TFClass_Pyro:
		{
			if(bGiants)
			{
				if(iVariant >= -1 && iVariant <= (RT_NumTemplates(true, TFClass) - 1))
					bValid = true;
			}
			else
			{
				if(iVariant >= -1 && iVariant <= (RT_NumTemplates(false, TFClass) - 1))
					bValid = true;
			}
		}
		case TFClass_DemoMan:
		{
			if(bGiants)
			{
				if(iVariant >= -1 && iVariant <= (RT_NumTemplates(true, TFClass) - 1))
					bValid = true;
			}
			else
			{
				if(iVariant >= -1 && iVariant <= (RT_NumTemplates(false, TFClass) - 1))
					bValid = true;
			}
		}
		case TFClass_Heavy:
		{
			if(bGiants)
			{
				if(iVariant >= -1 && iVariant <= (RT_NumTemplates(true, TFClass) - 1))
					bValid = true;
			}
			else
			{
				if(iVariant >= -1 && iVariant <= (RT_NumTemplates(false, TFClass) - 1))
					bValid = true;
			}
		}
		case TFClass_Engineer:
		{
			if(bGiants)
			{
				if(iVariant >= -1 && iVariant <= (RT_NumTemplates(true, TFClass) - 1))
					bValid = true;
			}
			else
			{
				if(iVariant >= -1 && iVariant <= (RT_NumTemplates(false, TFClass) - 1))
					bValid = true;
			}
		}
		case TFClass_Medic:
		{
			if(bGiants)
			{
				if(iVariant >= -1 && iVariant <= (RT_NumTemplates(true, TFClass) - 1))
					bValid = true;
			}
			else
			{
				if(iVariant >= -1 && iVariant <= (RT_NumTemplates(false, TFClass) - 1))
					bValid = true;
			}
		}
		case TFClass_Sniper:
		{
			if(bGiants)
			{
				if(iVariant >= -1 && iVariant <= (RT_NumTemplates(true, TFClass) - 1))
					bValid = true;
			}
			else
			{
				if(iVariant >= -1 && iVariant <= (RT_NumTemplates(false, TFClass) - 1))
					bValid = true;
			}
		}
		case TFClass_Spy:
		{
			if(bGiants)
			{
				if(iVariant >= -1 && iVariant <= (RT_NumTemplates(true, TFClass) - 1))
					bValid = true;
			}
			else
			{
				if(iVariant >= -1 && iVariant <= (RT_NumTemplates(false, TFClass) - 1))
					bValid = true;
			}
		}
	}
	
	return bValid;
}

// Set attributes on the robots.
void SetVariantExtras(int client,TFClassType TFClass, int iVariant)
{
#if defined DEBUG_PLAYER
	CPrintToChat(client, "{green}[DEBUG]{orange} SetVariantExtras:: {cyan}Called for client %N class %i variant %i", client, view_as<int>(TFClass), iVariant);
#endif

	RoboPlayer rp = RoboPlayer(client);
	rp.Attributes = 0;
	
	if(iVariant < 0)
	{
		switch(TFClass)
		{
			case TFClass_Soldier:
			{
				rp.Attributes |= BotAttrib_FullCharge;
			}
			case TFClass_Sniper:
			{
				rp.Attributes |= BotAttrib_CannotCarryBomb;
			}
			case TFClass_Engineer:
			{
				rp.Attributes |= (BotAttrib_CannotCarryBomb|BotAttrib_TeleportToHint);
			}
			case TFClass_Medic:
			{
				rp.Attributes |= (BotAttrib_CannotCarryBomb|BotAttrib_FullCharge);
			}
			case TFClass_Spy:
			{
				rp.Attributes |= (BotAttrib_CannotCarryBomb|BotAttrib_AutoDisguise);
			}
			default:
			{
				rp.Attributes = 0;
			}
		}
		rp.Type = Bot_Normal;
		return;
	}

	int iRobotType = RT_GetType(TFClass, iVariant, 0);
	rp.Attributes = RT_GetAttributesBits(TFClass, iVariant, 0);
	
	if(iRobotType < 0)
		iRobotType = 0;
	else if(iRobotType >= Bot_Giant)
		iRobotType = 0;
		
	rp.Type = iRobotType;
}

void SetGiantVariantExtras(int client,TFClassType TFClass, int iVariant)
{
#if defined DEBUG_PLAYER
	CPrintToChat(client, "{green}[DEBUG]{orange} SetGiantVariantExtras:: {cyan}Called for client %N class %i variant %i", client, view_as<int>(TFClass), iVariant);
#endif

	RoboPlayer rp = RoboPlayer(client);
	rp.Attributes = 0;

	if(iVariant < 0)
	{
		switch(TFClass)
		{
			case TFClass_Soldier:
			{
				rp.Attributes |= BotAttrib_FullCharge;
			}
			case TFClass_Sniper:
			{
				rp.Attributes |= BotAttrib_CannotCarryBomb;
			}
			case TFClass_Engineer:
			{
				rp.Attributes |= (BotAttrib_CannotCarryBomb|BotAttrib_TeleportToHint);
			}
			case TFClass_Medic:
			{
				rp.Attributes |= (BotAttrib_CannotCarryBomb|BotAttrib_FullCharge);
			}
			case TFClass_Spy:
			{
				rp.Attributes |= (BotAttrib_CannotCarryBomb|BotAttrib_AutoDisguise);
			}
			default:
			{
				rp.Attributes = 0;
			}
		}
		rp.Type = Bot_Giant;
		return;
	}

	rp.Attributes = RT_GetAttributesBits(TFClass, iVariant, 1);
}

// sets the player scale based on robot type
void SetRobotScale(int client, TFClassType TFClass)
{
	if(IsFakeClient(client)) {
		return;
	}

	static const float minscale = 0.3;
	static const float maxscale_normal = 2.0;
	static const float maxscale_small = 1.2;
	bool smallmap = IsSmallMap();
	float scale = -1.0;
	RoboPlayer rp = RoboPlayer(client);
	
	if(rp.Variant >= 0)
	{
		switch(rp.Type)
		{
			case Bot_Boss:
			{
				scale = Boss_GetScale();
			}
			case Bot_Giant:
			{
				scale = RT_GetScale(TFClass, rp.Variant, 1);
			}
			case Bot_Buster:
			{
				scale = Buster_GetScale();
			}
			default:
			{
				scale = RT_GetScale(TFClass, rp.Variant, 0);
			}
		}
	}
	
	// Check if scale is in bounds.
	if(scale >= minscale && scale <= (smallmap ? maxscale_small : maxscale_normal))
	{
		ScalePlayerModel(client, scale);
		return;
	}
	
	// Apply default scale
	if(smallmap)
	{
		switch(rp.Type)
		{
			case Bot_Boss, Bot_Giant, Bot_Buster:
			{
				ScalePlayerModel(client, 1.2);
			}
			case Bot_Big:
			{
				ScalePlayerModel(client, 1.1);
			}
			case Bot_Small:
			{
				ScalePlayerModel(client, 0.65);
			}
			default:
			{
				ScalePlayerModel(client, 1.0);
			}
		}
	}
	else
	{
		switch(rp.Type)
		{
			case Bot_Boss:
			{
				ScalePlayerModel(client, 1.9);
			}
			case Bot_Giant, Bot_Buster:
			{
				ScalePlayerModel(client, 1.75);
			}
			case Bot_Big:
			{
				switch(TFClass)
				{
					case TFClass_Heavy: ScalePlayerModel(client, 1.5);
					case TFClass_DemoMan: ScalePlayerModel(client, 1.3);
					default: ScalePlayerModel(client, 1.4);
				}
			}
			case Bot_Small:
			{
				ScalePlayerModel(client, 0.65);
			}
			default:
			{
				ScalePlayerModel(client, 1.0);
			}
		}		
	}
}

// change player size and update hitbox
void ScalePlayerModel(const int client, const float fScale)
{
	if(IsFakeClient(client)) {
		return;
	}

	static const float vecTF2PlayerMin[3] = { -24.5, -24.5, 0.0 }, vecTF2PlayerMax[3] = { 24.5,  24.5, 83.0 };

	float vecScaledPlayerMin[3];
	float vecScaledPlayerMax[3];

	vecScaledPlayerMin = vecTF2PlayerMin;
	vecScaledPlayerMax = vecTF2PlayerMax;

	ScaleVector(vecScaledPlayerMin, fScale);
	ScaleVector(vecScaledPlayerMax, fScale);

	SetEntPropVector(client, Prop_Send, "m_vecSpecifiedSurroundingMins", vecScaledPlayerMin);
	SetEntPropVector(client, Prop_Send, "m_vecSpecifiedSurroundingMaxs", vecScaledPlayerMax);
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", fScale);
}

void ResetRobotData(int client, bool bStrip = false)
{
	if(IsFakeClient(client)) {
		return;
	}

	p_iBotType[client] = Bot_Normal;
	p_iBotVariant[client] = 0;
	p_iBotAttrib[client] = 0;
	p_BotClass[client] = TFClass_Unknown;
	p_bInSpawn[client] = false;
	p_bIsBusterDetonating[client] = false;
	g_bIsCarrier[client] = false;
	p_bIsGatebot[client] = false;
	g_bUpgradeStation[client] = false;
	g_flLastForceBot[client] = 0.0;
	g_flinstructiontime[client] = 0.0;
	g_bIsDeploying[client] = false;
	g_flBombDeployTime[client] = 0.0;
	p_flProtTime[client] = 0.0;
	p_flBusterTimer[client] = 0.0;
	if( bStrip )
		StripWeapons(client);
}

// sets robot model
void SetRobotModel(int client, TFClassType TFClass)
{
	if(IsFakeClient(client)) {
		return;
	}

	char strModel[PLATFORM_MAX_PATH];
	
	switch(TFClass)
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
		default: return;
	}
	
	if(OR_IsHalloweenMission() && p_iBotType[client] != Bot_Buster)
	{
		SetVariantString( "" );
		AcceptEntityInput( client, "SetCustomModel" );
		return;
	}

	switch(p_iBotType[client])
	{
		case Bot_Giant, Bot_Boss:
		{
			switch(TFClass)
			{
				case TFClass_Scout, TFClass_Soldier, TFClass_DemoMan, TFClass_Heavy, TFClass_Pyro:
				{
					Format(strModel, sizeof(strModel), "models/bots/%s_boss/bot_%s_boss.mdl", strModel, strModel);
				}
				default:
				{
					Format(strModel, sizeof(strModel), "models/bots/%s/bot_%s.mdl", strModel, strModel);
				}
			}
		}
		case Bot_Buster:
		{
			FormatEx( strModel, sizeof(strModel), "models/bots/demo/bot_sentry_buster.mdl");
		}
		default:
		{
			Format( strModel, sizeof(strModel), "models/bots/%s/bot_%s.mdl", strModel, strModel);
		}
	}

	SetVariantString(strModel);
	AcceptEntityInput(client, "SetCustomModel");
	SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
}

// teleports robot players to random spawn points
void TeleportToSpawnPoint(int client, TFClassType TFClass)
{
	if(IsFakeClient(client)) {
		return;
	}

	int iSpawn;
	float vecOrigin[3];
	float vecAngles[3];
	
	if(p_iBotType[client] == Bot_Giant || p_iBotType[client] == Bot_Big)
	{
		iSpawn = FindRandomSpawnPoint(Spawn_Giant);
	}
	else if(p_iBotType[client] == Bot_Buster)
	{
		iSpawn = FindRandomSpawnPoint(Spawn_Buster);		
	}
	else if(p_iBotType[client] == Bot_Boss)
	{
		iSpawn = FindRandomSpawnPoint(Spawn_Boss);		
	}
	else if(TFClass == TFClass_Sniper)
	{
		iSpawn = FindRandomSpawnPoint(Spawn_Sniper);
	}
	else if(TFClass == TFClass_Spy)
	{
		iSpawn = FindRandomSpawnPoint(Spawn_Spy);
	}
	else
	{
		iSpawn = FindRandomSpawnPoint(Spawn_Normal);
	}
	
	if(IsValidEntity(iSpawn))
	{
		GetEntPropVector(iSpawn, Prop_Send, "m_vecOrigin", vecOrigin);
		GetEntPropVector(iSpawn, Prop_Data, "m_angRotation", vecAngles);		
		TeleportEntity(client, vecOrigin, vecAngles, NULL_VECTOR);
#if defined DEBUG_GENERAL
		CPrintToChat(client, "{green}[SPAWN] {snow}Teleported to spawn point index %i origin %.1f %.1f %.1f angles %.1f %.1f %.1f", iSpawn, vecOrigin[0], vecOrigin[1], vecOrigin[2], vecAngles[0], vecAngles[1], vecAngles[2]);
		int colors[4] = { 20, 200, 255, 255 };
		float mins[3] = { -24.0, -24.0, 0.0 }; // Normal map
		float maxs[3] = { 24.0, 24.0, 82.0 };
		DrawBox(client, vecOrigin, mins, maxs, colors, 15.0);
#endif
	}
}

// finds a random spawn point for human players
int FindRandomSpawnPoint(SpawnType iType)
{
	int iEnt = -1;
	char strSpawnName[64];
	ArrayList array_spawns; // spawn points for human players
	array_spawns = new ArrayList();
	
	while((iEnt = FindEntityByClassname( iEnt, "info_player_teamspawn")) != -1)
	{
		if(GetEntProp(iEnt, Prop_Send, "m_iTeamNum") == view_as<int>(TFTeam_Blue) && GetEntProp(iEnt, Prop_Data, "m_bDisabled") == 0) // ignore disabled spawn points
		{
			GetEntPropString(iEnt, Prop_Data, "m_iName", strSpawnName, sizeof(strSpawnName));
			
			switch(iType)
			{
				case Spawn_Normal:
				{
					for(int i = 0;i < g_iSplitSize[0];i++)
					{
						if(strcmp( strSpawnName, g_strNormalSplit[i] ) == 0)
						{
							array_spawns.Push( iEnt );
						}
					}					
				}
				case Spawn_Giant, Spawn_Buster, Spawn_Boss:
				{
					for(int i = 0;i < g_iSplitSize[1];i++)
					{
						if(strcmp(strSpawnName, g_strGiantSplit[i] ) == 0)
						{
							array_spawns.Push( iEnt );
						}
					}
				}
				case Spawn_Sniper:
				{
					for(int i = 0;i < g_iSplitSize[2];i++)
					{
						if(strcmp(strSpawnName, g_strSniperSplit[i] ) == 0)
						{
							array_spawns.Push( iEnt );
						}
					}
				}
				case Spawn_Spy:
				{
					for(int i = 0;i < g_iSplitSize[3];i++)
					{
						if(strcmp( strSpawnName, g_strSpySplit[i] ) == 0)
						{
							array_spawns.Push( iEnt );
						}
					}				
				}
			}
		}
	}
	if(array_spawns.Length > 0)
	{
		int spawn = array_spawns.Get(Math_GetRandomInt(0, (array_spawns.Length - 1)));
		delete array_spawns;
		return spawn;
	}
	
	delete array_spawns;
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
	// checks BLU player count
	if(iInBlu > iMaxBlu && iInBlu > 0)
	{
		int iOverLimit = iInBlu - iMaxBlu;
		for(int i = 1; i <= iOverLimit; i++)
		{
			iTarget = GetRandomClientFromTeam(view_as<int>(TFTeam_Blue));
			if(iTarget > 0)
			{
				PreChangeTeam(iTarget, view_as<int>(TFTeam_Red));
				CPrintToChat(iTarget, "%t", "Moved Blu Full");
				LogAction(iTarget, -1, "\"%L\" was moved to RED (full)", iTarget);
			}
		}
	}
	if(c_bAutoTeamBalance.BoolValue)
	{
		// if the number of players in RED is less than the minimum to join BLU
		if((iInRed + 1) < c_iMinRed.IntValue && iInBlu > 0)
		{
			int iCount = c_iMinRed.IntValue - (iInRed + 1);
			if(iCount < c_iMinRed.IntValue)
				LogMessage("Auto Balancing teams. Count: %i, In RED: %i, In BLU: %i", iCount, iInRed, iInBlu);
			
			for(int i = 1; i <= iCount; i++)
			{
				iTarget = GetRandomClientFromTeam(view_as<int>(TFTeam_Blue));
				if(iTarget > 0)
				{
					PreChangeTeam(iTarget, view_as<int>(TFTeam_Red));
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
	if(IsFakeClient(client)) {
		return;
	}

	StopSound(client, SNDCHAN_STATIC, ROBOT_SND_GIANT_SCOUT);
	StopSound(client, SNDCHAN_STATIC, ROBOT_SND_GIANT_SOLDIER);
	StopSound(client, SNDCHAN_STATIC, ROBOT_SND_GIANT_PYRO);
	StopSound(client, SNDCHAN_STATIC, ROBOT_SND_GIANT_DEMOMAN);
	StopSound(client, SNDCHAN_STATIC, ROBOT_SND_SENTRY_BUSTER);
	StopSound(client, SNDCHAN_STATIC, ROBOT_SND_GIANT_HEAVY);
}

void ApplyRobotLoopSound(int client)
{
	if(IsFakeClient(client)) {
		return;
	}

	StopRobotLoopSound(client);
	CreateTimer(0.5, Timer_ApplyRobotSound, client, TIMER_FLAG_NO_MAPCHANGE);
}

// end wave spawn manager

// Allows all players to use sm_robotmenu again
void ResetRobotMenuCooldown()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		g_flLastForceBot[i] = 0.0;
	}
}