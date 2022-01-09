// Game events

void SetupGameEvents()
{
	HookEvent("mvm_begin_wave", Event_WaveStart);
	HookEvent("mvm_wave_complete", Event_WaveEnd);
	HookEvent("mvm_wave_failed", Event_WaveFailed);
	HookEvent("mvm_mission_complete", Event_MissionComplete);
	HookEvent("player_changeclass", Event_ChangeClass);
	HookEvent("player_team", Event_PlayerTeam, EventHookMode_Pre);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("teamplay_flag_event", Event_Teamplay_Flag);
	HookEvent("post_inventory_application", Event_Inventory);
}

public Action Event_WaveStart(Event event, const char[] name, bool dontBroadcast)
{
	PrintToServer("Wave Start");
	RequestFrame(Frame_OnWaveStart);
	return Plugin_Continue;
}

public Action Event_WaveEnd(Event event, const char[] name, bool dontBroadcast)
{
	PrintToServer("Wave End");
	RequestFrame(Frame_OnWaveEnd);
	return Plugin_Continue;
}

public Action Event_WaveFailed(Event event, const char[] name, bool dontBroadcast)
{
	PrintToServer("Wave Failed");
	RequestFrame(Frame_OnWaveFailed);
	return Plugin_Continue;
}

public Action Event_MissionComplete(Event event, const char[] name, bool dontBroadcast)
{
	PrintToServer("Mission Complete");
	return Plugin_Continue;
}

public Action Event_ChangeClass(Event event, const char[] name, bool dontBroadcast)
{
	PrintToServer("Change class");
	return Plugin_Continue;
}

public Action Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
	int userid = event.GetInt("userid");
	int client = GetClientOfUserId(userid);

	if(IsClientInGame(client))
	{
		RobotPlayer rp = RobotPlayer(client);

		if(rp.isrobot)
		{
			event.BroadcastDisabled = true; // Supress change team messages from BLU players
		}
	}

	return Plugin_Continue;
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	int team = event.GetInt("team");

	if(team == view_as<int>(TFTeam_Blue))
	{
		if(!IsFakeClient(client))
		{
			RequestFrame(DirectorFrame_PostSpawn, GetClientSerial(client));
		}
	}

	return Plugin_Continue;
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("userid"));
	int killer = GetClientOfUserId(event.GetInt("attacker"));
	int deathflags = event.GetInt("death_flags");

	if(deathflags & TF_DEATHFLAG_DEADRINGER)
		return Plugin_Continue;

	Director_OnPlayerDeath(victim, killer);

	return Plugin_Continue;
}

public Action Event_Inventory(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	TFTeam team = TF2_GetClientTeam(client);

	if(!IsFakeClient(client) && team == TFTeam_Blue)
	{
		Director_GiveInventory(client);
	}

	return Plugin_Continue;
}

public Action Event_Teamplay_Flag(Event event, const char[] name, bool dontBroadcast)
{
	if(event.GetInt("eventtype") == TF_FLAGEVENT_PICKEDUP)
	{
		int client = event.GetInt("player");
		RobotPlayer rp = RobotPlayer(client);
		if(!IsFakeClient(client) && TF2_GetClientTeam(client) == TFTeam_Blue)
		{
			rp.carrier = true;
			if(TF2_IsGiant(client))
			{
				rp.bomblevel = 4;
				TF2_SpeakConcept(MP_CONCEPT_MVM_GIANT_HAS_BOMB, view_as<int>(TFTeam_Red), "");
			}
			else
			{
				rp.bomblevel = 0;
				rp.nextbombupgradetime = GetGameTime() + c_bomb_upgrade1.FloatValue;
				TF2_SpeakConcept(MP_CONCEPT_MVM_BOMB_PICKUP, view_as<int>(TFTeam_Red), "");
			}
			RequestFrame(Frame_UpdateBombHUD, GetClientSerial(client));
		}
	}
	if(event.GetInt("eventtype") == TF_FLAGEVENT_DROPPED)
	{
		int client = event.GetInt("player");
		RobotPlayer rp = RobotPlayer(client);
		if(!IsFakeClient(client) && TF2_GetClientTeam(client) == TFTeam_Blue)
		{
			rp.carrier = false;
			rp.deploying = false;
			rp.deployingtime = 0.0;
			rp.nextbombupgradetime = 0.0;
		}
	}

	return Plugin_Continue;
}

void Frame_OnWaveStart()
{
	Director_OnWaveStart();
	Robots_ResetWaveData();
}

void Frame_OnWaveEnd()
{
	Director_OnWaveEnd();
	Robots_ResetWaveData();
}

void Frame_OnWaveFailed()
{
	Director_OnWaveFailed();
	Robots_ResetWaveData();
}