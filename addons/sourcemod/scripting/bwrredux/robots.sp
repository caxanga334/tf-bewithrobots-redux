// Robots Templates

#define MAX_ROBOTS (1<<10)

int g_cbindex = 0; // Current robot index
int g_maxrobots = 0; // Number of robots that was registered

enum struct etemplates
{
	int pluginID; // the plugin that will handle this robot
	TFClassType class; // the robot class
	int cost; // resource cost
	int index; // robot list internal index
	int type; // robot type
	int supply; // available count
	int role; // robot role
	float percent; // wave percentage
	int spawns; // How many times this robot has spawned in the current wave
	float lastspawn; // The last time this robot spawned in the current wave
}
etemplates g_eTemplates[MAX_ROBOTS];

void RegisterRobotTemplate(int pluginID, TFClassType class, int cost, int index, int type, int supply, int role, float percent)
{
	if(g_cbindex >= MAX_ROBOTS)
	{
		ThrowError("Maximum number of robots reached!");
	}

	if(class == TFClass_Unknown)
	{
		ThrowError("Invalid robot class! Plugin ID \"%i\", Robot Index \"%i\"", pluginID, index);
	}

	g_eTemplates[g_cbindex].pluginID = pluginID;
	g_eTemplates[g_cbindex].class = class;
	g_eTemplates[g_cbindex].cost = cost;
	g_eTemplates[g_cbindex].index = index;
	g_eTemplates[g_cbindex].type = type;
	g_eTemplates[g_cbindex].supply = supply;
	g_eTemplates[g_cbindex].percent = percent;
	g_eTemplates[g_cbindex].role = role;

	g_cbindex++;
	g_maxrobots++;
}

/**
 * Resets spawn and lastspawn values for each template
 */
void Robots_ResetWaveData()
{
	for(int i = 0;i < g_maxrobots;i++)
	{
		g_eTemplates[i].spawns = 0;
		g_eTemplates[i].lastspawn = -1.0;
	}
}

/**
 * Gets the amount of robots registered.
 *
 * @return          The number of robots registered. -1 if no robot was registered.
 */
int Robots_GetMax()
{
	return g_maxrobots - 1;
}

// Gets the template class
TFClassType Robots_GetClass(int template)
{
	return g_eTemplates[template].class;
}

void Robots_SetModel(int client, TFClassType class)
{
	if(IsFakeClient(client)) 
		return;

	char playermodel[PLATFORM_MAX_PATH];
	
	switch(class)
	{
		case TFClass_Scout: strcopy(playermodel, sizeof(playermodel), "scout");
		case TFClass_Sniper: strcopy(playermodel, sizeof(playermodel), "sniper");
		case TFClass_Soldier: strcopy(playermodel, sizeof(playermodel), "soldier");
		case TFClass_DemoMan: strcopy(playermodel, sizeof(playermodel), "demo");
		case TFClass_Medic: strcopy(playermodel, sizeof(playermodel), "medic");
		case TFClass_Heavy: strcopy(playermodel, sizeof(playermodel), "heavy");
		case TFClass_Pyro: strcopy(playermodel, sizeof(playermodel), "pyro");
		case TFClass_Spy: strcopy(playermodel, sizeof(playermodel), "spy");
		case TFClass_Engineer: strcopy(playermodel, sizeof(playermodel), "engineer");
		default: ThrowError("Set Model called for invalid class! %i", view_as<int>(class));
	}

	RobotPlayer rp = RobotPlayer(client);

	switch(rp.type)
	{
		case BWRR_RobotType_Giant, BWRR_RobotType_Boss:
		{
			switch(class)
			{
				case TFClass_Scout, TFClass_Soldier, TFClass_DemoMan, TFClass_Heavy, TFClass_Pyro:
				{
					Format(playermodel, sizeof(playermodel), "models/bots/%s_boss/bot_%s_boss.mdl", playermodel, playermodel);
				}
				default:
				{
					Format(playermodel, sizeof(playermodel), "models/bots/%s/bot_%s.mdl", playermodel, playermodel);
				}
			}
		}
		case BWRR_RobotType_Buster:
		{
			FormatEx(playermodel, sizeof(playermodel), "models/bots/demo/bot_sentry_buster.mdl");
		}
		default:
		{
			Format(playermodel, sizeof(playermodel), "models/bots/%s/bot_%s.mdl", playermodel, playermodel);
		}
	}

	Action result;

	Call_StartForward(g_OnApplyModel);
	Call_PushCell(client);
	Call_PushCell(g_eTemplates[rp.templateindex].pluginID);
	Call_PushCell(TF2_GetPlayerClass(client));
	Call_PushCell(g_eTemplates[rp.templateindex].index);
	Call_PushCell(g_eTemplates[rp.templateindex].type);
	Call_PushStringEx(playermodel, PLATFORM_MAX_PATH, SM_PARAM_STRING_UTF8 | SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
	Call_Finish(result);

	if(result == Plugin_Handled || result == Plugin_Stop)
	{
		SetVariantString("");
		AcceptEntityInput(client, "SetCustomModel");
		return;
	}

	SetVariantString(playermodel);
	AcceptEntityInput(client, "SetCustomModel");
	SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
}

void Robots_ClearModel(int client)
{
	SetVariantString("");
	AcceptEntityInput(client, "SetCustomModel");
}

float Robots_GetScaleSize(int client)
{
	RobotPlayer rp = RobotPlayer(client);
	float scale = 1.0;

	switch(rp.type)
	{
		case BWRR_RobotType_Boss: scale = 1.9;
		case BWRR_RobotType_Buster, BWRR_RobotType_Giant: scale = 1.75;
		default: scale = 1.0;
	}

	Call_StartForward(g_OnApplyScale);
	Call_PushCell(client);
	Call_PushCell(g_eTemplates[rp.templateindex].pluginID);
	Call_PushCell(TF2_GetPlayerClass(client));
	Call_PushCell(g_eTemplates[rp.templateindex].index);
	Call_PushCell(g_eTemplates[rp.templateindex].type);
	Call_PushFloatRef(scale);
	Call_Finish();

	return scale;
}

void Robots_SetScale(int client, const float scale)
{
	float mins[3],maxs[3];
	TF2_GetPlayerHullSize(mins, maxs);
	ScaleVector(mins, scale);
	ScaleVector(maxs, scale);

	SetEntPropVector(client, Prop_Send, "m_vecSpecifiedSurroundingMins", mins);
	SetEntPropVector(client, Prop_Send, "m_vecSpecifiedSurroundingMaxs", maxs);
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", scale);
}

void Robots_ClearScale(int client)
{
	float mins[3],maxs[3];
	TF2_GetPlayerHullSize(mins, maxs);

	SetEntPropVector(client, Prop_Send, "m_vecSpecifiedSurroundingMins", mins);
	SetEntPropVector(client, Prop_Send, "m_vecSpecifiedSurroundingMaxs", maxs);
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", 1.0);
}

void Robots_DefaultLoopSound(RobotPlayer rp, char[] sound, int size)
{
	switch(rp.type)
	{
		case BWRR_RobotType_Boss, BWRR_RobotType_Giant:
		{
			switch(TF2_GetPlayerClass(rp.index))
			{
				case TFClass_Scout: strcopy(sound, size, "mvm/giant_scout/giant_scout_loop.wav");
				case TFClass_Soldier: strcopy(sound, size, "mvm/giant_soldier/giant_soldier_loop.wav");
				case TFClass_Pyro: strcopy(sound, size, "mvm/giant_pyro/giant_pyro_loop.wav");
				case TFClass_DemoMan: strcopy(sound, size, "mvm/giant_demoman/giant_demoman_loop.wav");
				case TFClass_Heavy: strcopy(sound, size, "mvm/giant_heavy/giant_heavy_loop.wav");
			}
		}
		case BWRR_RobotType_Buster: strcopy(sound, size, "mvm/sentrybuster/mvm_sentrybuster_loop.wav");
	}
}

void Robots_SetLoopSound(int client)
{
	char sound[PLATFORM_MAX_PATH];
	int level = SNDLEVEL_TRAIN;
	RobotPlayer rp = RobotPlayer(client);
	Robots_DefaultLoopSound(rp, sound, sizeof(sound));

	if(rp.templateindex >= 0)
	{
		Action result;
		Call_StartForward(g_OnApplyLoopSound);
		Call_PushCell(client);
		Call_PushCell(g_eTemplates[rp.templateindex].pluginID);
		Call_PushCell(TF2_GetPlayerClass(client));
		Call_PushCell(g_eTemplates[rp.templateindex].index);
		Call_PushCell(g_eTemplates[rp.templateindex].type);
		Call_PushStringEx(sound, PLATFORM_MAX_PATH, SM_PARAM_STRING_UTF8 | SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
		Call_PushCellRef(level);
		Call_Finish(result);
	
		if(result == Plugin_Handled || result == Plugin_Stop)
		{
			return;
		}
	}

	if(strlen(sound) > 2)
	{
		rp.SetLoopSound(sound);
		EmitSoundToAll(sound, client, SNDCHAN_STATIC, level, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL);
	}
}