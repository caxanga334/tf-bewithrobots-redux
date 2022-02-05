// Console variables

ConVar c_blu_limit_mode; // BLU limit mode selection.
ConVar c_minred; // Minimum number of players on RED team before allowing players to join BLU team.
ConVar c_redblu_ratio; // Ratio between RED and BLU players for the Ratio limit mode.
ConVar c_maxblu; // Maximum number of players allowed to join BLU team.
ConVar c_director_rpt_min; // AI Director Minimum Resources per Think
ConVar c_director_rpt_max; // AI Director Maximum Resources per Think
ConVar c_director_initial_resources; // AI Director initial resources on wave start
ConVar c_director_mm_cooldown_min; // Cooldown between missions
ConVar c_director_mm_cooldown_max; // Cooldown between missions
ConVar c_director_spawn_cooldown_min; // Spawn Cooldown min
ConVar c_director_spawn_cooldown_max; // Spawn Cooldown max
ConVar c_director_wait_for_bots; // Wait for at least 1 bot to spawn players
ConVar c_spman_spy_maxdist; // Maximum distance to teleport spy
ConVar c_engineer_limit; // Maximum number of human engineers
ConVar c_giant_limit; // Maximum number of human giants
ConVar c_sentry_min_kills; // Minimum amount of kills a sentry gun needs to have to be considered a threat
ConVar c_director_boss_wave_percent; // Minimum completed wave percentage to spawn bosses
ConVar c_director_boss_cooldown_min; // Minimum cooldown between boss spawn
ConVar c_director_boss_cooldown_max; // Minimum cooldown between boss spawn
ConVar c_director_boss_cooldown_init; // Initial cooldown between boss spawn at wave start
ConVar c_sentrybuster_default_range; // Default sentry buster explosion range
ConVar c_robots_min_size; // Absolute minimum robot scale
ConVar c_robots_max_size; // Absolute maximum robot scale

// Cvars from the game
ConVar c_bomb_upgrade1; // Bomb first upgrade time
ConVar c_bomb_upgrade2; // Bomb second upgrade time
ConVar c_bomb_upgrade3; // Bomb third upgrade time
ConVar c_engineer_distance; // Minimum distance between engineer teleport and bomb

void SetupConVars()
{
	AutoExecConfig_SetFile("plugin.bwrredux");

	CreateConVar("sm_bwrr_version", PLUGIN_VERSION, "Be With Robots: Redux plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	c_blu_limit_mode = AutoExecConfig_CreateConVar("sm_bwrr_blu_limit_mode", "0", "BLU team limit mode. 0 = Fixed number. 1 = Ratio.", FCVAR_NONE, true, 0.0, true, 1.0);
	c_minred = AutoExecConfig_CreateConVar("sm_bwrr_minred", "6", "Minimum amount of players on RED team to allow joining ROBOTs.", FCVAR_NONE, true, 0.0, true, 10.0);
	c_redblu_ratio = AutoExecConfig_CreateConVar("sm_bwrr_redblu_ratio", "4", "Ratio of RED:BLU players for the ratio limit mode.", FCVAR_NONE, true, 2.0, true, 5.0);
	c_maxblu = AutoExecConfig_CreateConVar("sm_bwrr_maxblu", "4", "Maximum amount of players in BLU team.", FCVAR_NONE, true, 1.0, true, 10.0);
	c_director_rpt_min = AutoExecConfig_CreateConVar("sm_bwrr_director_rpt_min", "10", "Minimum resources the AI Director gets per think.", FCVAR_NONE, true, 1.0, true, 500.0);
	c_director_rpt_max = AutoExecConfig_CreateConVar("sm_bwrr_director_rpt_max", "100", "Maximum resources the AI Director gets per think.", FCVAR_NONE, true, 50.0, true, 5000.0);
	c_director_initial_resources = AutoExecConfig_CreateConVar("sm_bwrr_director_init_resources", "400", "Initial AI Director resources on wave start.", FCVAR_NONE, true, 100.0, true, 50000.0);
	c_spman_spy_maxdist = AutoExecConfig_CreateConVar("sm_bwrr_spman_spy_max_dist", "2048.0", "Maximum distance to teleport a spy", FCVAR_NONE, true, 1024.0, true, 8192.0);
	c_director_mm_cooldown_min = AutoExecConfig_CreateConVar("sm_bwrr_director_mm_cooldown_min", "30.0", "Minimum cooldown between (engineer, sniper, spy, sentry buster) missions.", FCVAR_NONE, true, 5.0, true, 90.0);
	c_director_mm_cooldown_max = AutoExecConfig_CreateConVar("sm_bwrr_director_mm_cooldown_max", "90.0", "Maximum cooldown between (engineer, sniper, spy, sentry buster) missions.", FCVAR_NONE, true, 30.0, true, 300.0);
	c_engineer_limit = AutoExecConfig_CreateConVar("sm_bwrr_max_engineers", "1", "Maximum number of human engineers active at the same time.", FCVAR_NONE, true, 1.0, true, 4.0);
	c_director_spawn_cooldown_min = AutoExecConfig_CreateConVar("sm_bwrr_director_spawn_cooldown_min", "5.0", "Minimum cooldown between player spawns.", FCVAR_NONE, true, 3.0, true, 20.0);
	c_director_spawn_cooldown_max = AutoExecConfig_CreateConVar("sm_bwrr_director_spawn_cooldown_max", "12.0", "Maximum cooldown between player spawns.", FCVAR_NONE, true, 8.0, true, 30.0);
	c_director_wait_for_bots = AutoExecConfig_CreateConVar("sm_bwrr_director_wait_for_bots", "1", "Should the AI Director wait for at least one bot to be active before spawning human players? 1 = Enabled. 0 = Disabled.", FCVAR_NONE, true, 0.0, true, 1.0);
	c_giant_limit = AutoExecConfig_CreateConVar("sm_bwrr_max_giants", "2", "Maximum number of human giants active at the same time. 0 = No limit.", FCVAR_NONE, true, 0.0, true, 3.0);
	c_sentry_min_kills = AutoExecConfig_CreateConVar("sm_bwrr_sentry_min_kills", "15", "Minimum amount of kills a RED sentry gun needs to have to be considered a threat.", FCVAR_NONE, true, 1.0, true, 60.0);
	c_director_boss_wave_percent = AutoExecConfig_CreateConVar("sm_bwrr_director_boss_min_wave_percent", "0.66", "Minimum percentage of complete waves needed to allow boss robots to spawn", FCVAR_NONE, true, 0.0, true, 0.9);
	c_director_boss_cooldown_init = AutoExecConfig_CreateConVar("sm_bwrr_director_boss_cooldown_init", "30.0", "Initial boss spawn cooldown at wave start.", FCVAR_NONE, true, 0.0, true, 900.0);
	c_director_boss_cooldown_min = AutoExecConfig_CreateConVar("sm_bwrr_director_boss_cooldown_min", "75.0", "Minimum boss spawn cooldown.", FCVAR_NONE, true, 10.0, true, 300.0);
	c_director_boss_cooldown_max = AutoExecConfig_CreateConVar("sm_bwrr_director_boss_cooldown_max", "180.0", "Maximum boss spawn cooldown.", FCVAR_NONE, true, 60.0, true, 900.0);
	c_robots_min_size = AutoExecConfig_CreateConVar("sm_bwrr_robots_min_size", "0.65", "Maximum robot scaled size.", FCVAR_NONE, true, 0.4, true, 1.0);
	c_robots_max_size = AutoExecConfig_CreateConVar("sm_bwrr_robots_max_size", "1.9", "Maximum robot scaled size.", FCVAR_NONE, true, 1.0, true, 2.1);

	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();

	c_bomb_upgrade1 = FindConVar("tf_mvm_bot_flag_carrier_interval_to_1st_upgrade");
	c_bomb_upgrade2 = FindConVar("tf_mvm_bot_flag_carrier_interval_to_2nd_upgrade");
	c_bomb_upgrade3 = FindConVar("tf_mvm_bot_flag_carrier_interval_to_3rd_upgrade");
	c_engineer_distance = FindConVar("tf_bot_engineer_mvm_hint_min_distance_from_bomb");
	c_sentrybuster_default_range = FindConVar("tf_bot_suicide_bomb_range");

	if(c_bomb_upgrade1 == null || c_bomb_upgrade2 == null || c_bomb_upgrade3 == null)
	{
		SetFailState("Failed to get bomb upgrade convars.");
	}
	else if(c_engineer_distance == null)
	{
		SetFailState("Failed to find ConVar \"tf_bot_engineer_mvm_hint_min_distance_from_bomb\"!");
	}
	else if(c_sentrybuster_default_range == null)
	{
		SetFailState("Failed to find ConVar \"tf_bot_suicide_bomb_range\"!");
	}
}