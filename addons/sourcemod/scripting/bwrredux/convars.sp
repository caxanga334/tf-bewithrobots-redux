// Console variables

ConVar c_minred; // Minimum number of players on RED team before allowing players to join BLU team.
ConVar c_maxblu; // Maximum number of players allowed to join BLU team.
ConVar c_director_rpt; // AI Director Resources per Think

void SetupConVars()
{
	AutoExecConfig_SetFile("plugin.bwrredux");

	CreateConVar("sm_bwrr_version", PLUGIN_VERSION, "Be With Robots: Redux plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	c_minred = AutoExecConfig_CreateConVar("sm_bwrr_minred", "5", "Minimum amount of players on RED team to allow joining ROBOTs.", FCVAR_NONE, true, 0.0, true, 10.0);
	c_maxblu = AutoExecConfig_CreateConVar("sm_bwrr_maxblu", "4", "Maximum amount of players in BLU team.", FCVAR_NONE, true, 1.0, true, 10.0);
	c_director_rpt = AutoExecConfig_CreateConVar("sm_bwrr_director_rpt", "5", "How many resources the AI Director gets per think.", FCVAR_NONE, true, 1.0, true, 10000.0);

	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
}