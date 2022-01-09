// Console variables

ConVar c_minred; // Minimum number of players on RED team before allowing players to join BLU team.
ConVar c_maxblu; // Maximum number of players allowed to join BLU team.
ConVar c_director_rpt; // AI Director Resources per Think
//ConVar c_spman_spy_mindist; // Minimum distance to teleport spy
ConVar c_spman_spy_maxdist; // Maximum distance to teleport spy
//ConVar c_spman_spy_tries; // Number of trie to find a teleport point for spies

// Cvars from the game
ConVar c_bomb_upgrade1; // Bomb first upgrade time
ConVar c_bomb_upgrade2; // Bomb second upgrade time
ConVar c_bomb_upgrade3; // Bomb third upgrade time
ConVar c_engineer_distance; // Minimum distance between engineer teleport and bomb

void SetupConVars()
{
	AutoExecConfig_SetFile("plugin.bwrredux");

	CreateConVar("sm_bwrr_version", PLUGIN_VERSION, "Be With Robots: Redux plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	c_minred = AutoExecConfig_CreateConVar("sm_bwrr_minred", "5", "Minimum amount of players on RED team to allow joining ROBOTs.", FCVAR_NONE, true, 0.0, true, 10.0);
	c_maxblu = AutoExecConfig_CreateConVar("sm_bwrr_maxblu", "4", "Maximum amount of players in BLU team.", FCVAR_NONE, true, 1.0, true, 10.0);
	c_director_rpt = AutoExecConfig_CreateConVar("sm_bwrr_director_rpt", "10", "How many resources the AI Director gets per think.", FCVAR_NONE, true, 1.0, true, 10000.0);
	//c_spman_spy_mindist = AutoExecConfig_CreateConVar("sm_bwrr_spman_spy_min_dist", "300.0", "Minimum distance to teleport a spy", FCVAR_NONE, true, 200.0, true, 900.0);
	c_spman_spy_maxdist = AutoExecConfig_CreateConVar("sm_bwrr_spman_spy_max_dist", "2048.0", "Maximum distance to teleport a spy", FCVAR_NONE, true, 1024.0, true, 8192.0);
	//c_spman_spy_tries = AutoExecConfig_CreateConVar("sm_bwrr_spman_spy_tries", "3", "Maximum amount of tries to search for a spy teleport position", FCVAR_NONE, true, 1.0, true, 100.0);

	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();

	c_bomb_upgrade1 = FindConVar("tf_mvm_bot_flag_carrier_interval_to_1st_upgrade");
	c_bomb_upgrade2 = FindConVar("tf_mvm_bot_flag_carrier_interval_to_2nd_upgrade");
	c_bomb_upgrade3 = FindConVar("tf_mvm_bot_flag_carrier_interval_to_3rd_upgrade");
	c_engineer_distance = FindConVar("tf_bot_engineer_mvm_hint_min_distance_from_bomb");

	if(c_bomb_upgrade1 == null || c_bomb_upgrade2 == null || c_bomb_upgrade3 == null)
	{
		SetFailState("Failed to get bomb upgrade convars.");
	}
	else if(c_engineer_distance == null)
	{
		SetFailState("Failed to find ConVar \"tf_bot_engineer_mvm_hint_min_distance_from_bomb\"!");
	}
}