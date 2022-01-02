// Extras functions

// Checks if the client is a valid client index
bool IsValidClient(int client)
{
	if(client < 1 || client > MaxClients) { return false; }
	return IsClientInGame(client);
}

// Checks if the current gamemode is MvM
bool IsPlayingMannVsMachine()
{
	return !!GameRules_GetProp("m_bPlayingMannVsMachine");
}

// Checks if the wave is in progress
stock bool IsMvMWaveRunning()
{
	return GameRules_GetRoundState() == RoundState_RoundRunning;
}

/**
 * Changes the client team and clears them of BWRR related stuff
 *
 * @param client			The client to be moved
 * @param team				The team to move the client to
 */
void TF2BWR_ChangeClientTeam(int client, TFTeam team)
{
	int flag = TF2_GetClientFlag(client);
	
	if(IsValidEntity(flag))
	{
		TF2_ResetFlag(flag);
	}

	RobotPlayer rp = RobotPlayer(client);
	rp.ResetData();
	TF2_ClearClient(client);

	if(team == TFTeam_Blue)
	{
		Director_AddClientToQueue(client);
	}
	else
	{
		Robots_ClearModel(client);
		Robots_ClearScale(client);
		TF2MvM_ChangeClientTeam(client, team);
	}
}

// Changes the client team and bypasses game restrictions.
void TF2MvM_ChangeClientTeam(int client, TFTeam team)
{
	int entityflags = GetEntityFlags(client);
	SetEntityFlags(client, entityflags | FL_FAKECLIENT); // Fake client flag is needed to bypass restrictions
	TF2_ChangeClientTeam(client, team);
	SetEntityFlags(client, entityflags);
}

/**
 * Removes all weapons and attributes from a client
 *
 * @param client			The client to clear weapons and attributes
 * @param removeweapons		Remove weapons?
 * @param removewearables	Remove wearables (cosmetics)?
 */
void TF2_ClearClient(int client, bool removeweapons = true, bool removewearables = true)
{
	if(!IsClientInGame(client) || IsFakeClient(client) || !IsPlayerAlive(client))
		return;

	int entity, owner;

	if(removeweapons)
	{
		entity = -1;
		while((entity = FindEntityByClassname(entity, "tf_wearable_demoshield")) > MaxClients)
		{
			owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
			if(owner == client)
			{
				TF2_RemoveWearable( client, entity );
				RemoveEntity(entity);
			}
		}
		
		entity = -1;
		while((entity = FindEntityByClassname(entity, "tf_wearable_razorback")) > MaxClients)
		{
			owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
			if(owner == client)
			{
				TF2_RemoveWearable(client, entity);
				RemoveEntity(entity);
			}
		}

		RemoveAllWeapons(client);
	}

	if(removewearables)
	{
		entity = -1;
		while((entity = FindEntityByClassname(entity, "tf_wearable")) > MaxClients)
		{
			owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
			if(owner == client)
			{
				TF2_RemoveWearable(client, entity);
				RemoveEntity(entity);
			}
		}

		entity = -1;
		while((entity = FindEntityByClassname(entity, "tf_powerup_bottle")) > MaxClients)
		{
			owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
			if(owner == client) 
			{
				RemoveEntity(entity);
			}
		}
		
		entity = -1;
		while((entity = FindEntityByClassname(entity, "tf_usableitem")) > MaxClients)
		{
			owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
			if(owner == client) 
			{
				RemoveEntity(entity);
			}
		}
	}

	TF2Attrib_RemoveAll(client);
	TF2Attrib_ClearCache(client);
}

void RemoveAllWeapons(int client)
{
	int entity;
	for(int i = 0; i <= TFWeaponSlot_Item2; i++)
	{
		entity = TF2Util_GetPlayerLoadoutEntity(client, i, true);
		if(entity != -1) 
		{
			if(TF2Util_IsEntityWearable(entity)) 
			{
				TF2_RemoveWearable(client, entity);
			}
			else 
			{
				RemovePlayerItem(client, entity);
			}

			RemoveEntity(entity);
		}
	}
}

/**
 * Forces a client to pick up a flag
 *
 * @param client	The client to give the flag to
 * @param flag		The flag entity to give to the client
 * @return     no return
 */
void TF2_PickUpFlag(int client, int flag)
{
	SDKCall(g_hSDKPickupFlag, flag, client, true);
}

/**
 * Forces a flag to reset
 *
 * @param flag		The flag entity index to reset
 * @return     no return
 */
void TF2_ResetFlag(int flag)
{
	if(IsValidEntity(flag))
	{
		AcceptEntityInput(flag, "ForceReset");
	}
}

/**
 * Gets the MvM bomb hatch world position
 *
 * @param update	Send true to update the cached value.
 * @return     origin vector
 */
stock float[] TF2_GetBombHatchPosition(bool update = false)
{
	static float origin[3];
	
	if(update)
	{
		int i = -1;
		while ((i = FindEntityByClassname(i, "func_capturezone")) != -1)
		{
			GetEntityWorldCenter(i, origin);
		}
		
		return origin;
	}
	else
	{
		return origin;
	}
}

// checks if a player is giant
bool TF2_IsGiant(int client)
{
	return view_as<bool>(GetEntProp(client, Prop_Send, "m_bIsMiniBoss"));
}

ArrayList CollectValidSpawnPoints(int client)
{
	ArrayList spawns = new ArrayList();
	int entity;
	float origin[3];

	while((entity = FindEntityByClassname(entity, "info_player_teamspawn")) != INVALID_ENT_REFERENCE)
	{
		if(GetEntProp(entity, Prop_Send, "m_iTeamNum") == view_as<int>(TFTeam_Blue) && GetEntProp(entity, Prop_Data, "m_bDisabled") == 0)
		{
			GetEntPropVector(entity, Prop_Send, "m_vecOrigin", origin);
			// To-do: Add nav mesh validation
			if(IsSafeAreaToTeleport(client, origin))
			{
				spawns.Push(entity);
			}
		}
	}

	return spawns;
}

/**
 * Performs a trace hull to check if it's safe to teleport (client won't get stuck)
 *
 * @param client			The client to get the bounds from
 * @param origin			The origin to test
 * @return					TRUE if the area is safe
 */
bool IsSafeAreaToTeleport(int client, float origin[3])
{
	Handle trace = null;
	float mins[3], maxs[3];
	GetEntPropVector(client, Prop_Send, "m_vecMins", mins);
	GetEntPropVector(client, Prop_Send, "m_vecMaxs", maxs);
	trace = TR_TraceHullFilterEx(origin, origin, mins, maxs, MASK_PLAYERSOLID, TraceFilter_IgnorePlayers);
	bool result = TR_DidHit(trace);
	delete trace;
	return !result;
}

// Trace filter that ignores all clients/players
bool TraceFilter_IgnorePlayers(int entity, int contentsMask)
{
	if(entity > 0 && entity <= MaxClients)
	{
		return false;
	}

	return true;
}

void TF2BWR_DeployBomb(int client)
{
	RobotPlayer rp = RobotPlayer(client);
	float time = FindConVar("tf_deploying_bomb_time").FloatValue + 0.5;
	float origin[3], hatch[3], result[3], angles[3];

	GetClientAbsOrigin(client, origin);
	hatch = TF2_GetBombHatchPosition(true);
	SubtractVectors(hatch, origin, result);
	NormalizeVector(result, result);
	GetVectorAngles(result, angles);
	angles[0] = 0.0;
	angles[2] = 0.0;
	TeleportEntity(client, NULL_VECTOR, angles, {0.0, 0.0, 0.0});
	SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 0);
	TF2_PlaySequence(client, "primary_deploybomb");
	TF2_AddCondition(client, TFCond_FreezeInput, time);
	SetVariantInt(1);
	AcceptEntityInput(client, "SetForcedTauntCam");	
	RequestFrame(Frame_DisableAnimation, GetClientSerial(client));

	switch(rp.type)
	{
		case BWRR_RobotType_Boss, BWRR_RobotType_Giant:
		{
			EmitGameSoundToAll("MVM.DeployBombSmall", client, SND_NOFLAGS, _, origin);
		}
		default:
		{
			EmitGameSoundToAll("MVM.DeployBombGiant", client, SND_NOFLAGS, _, origin);
		}
	}
}

// code from Pelipoika's bot control
void Frame_DisableAnimation(int serial)
{
	static int count = 0;

	int client = GetClientFromSerial(serial);

	if(client)
	{
		if(count > 6)
		{
			float vecClientPos[3], vecTargetPos[3];
			GetClientAbsOrigin(client, vecClientPos);
			vecTargetPos = TF2_GetBombHatchPosition();
			float v[3], ang[3];
			SubtractVectors(vecTargetPos, vecClientPos, v);
			NormalizeVector(v, v);
			GetVectorAngles(v, ang);
			ang[0] = 0.0;
			SetVariantString("1");
			AcceptEntityInput(client, "SetCustomModelRotates");
			SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 0);
			char strVec[16];
			Format(strVec, sizeof(strVec), "0 %f 0", ang[1]);
			SetVariantString(strVec);
			AcceptEntityInput(client, "SetCustomModelRotation");
			count = 0;
		}
		else
		{
			TF2_PlaySequence(client, "primary_deploybomb");
			SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 0);
			RequestFrame(Frame_DisableAnimation, serial);
			count++;
		}
	}
	else
	{
		count = 0;
	}
}

void TF2BWR_CancelDeployBomb(int client)
{
	SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
	TF2_RemoveCondition(client, TFCond_FreezeInput);
}

void TF2BWR_TriggerBombHatch(int client)
{
	int entity = FindEntityByClassname(-1, "func_capturezone");
	LogAction(client, -1, "\"%L\" deployed the bomb.", client);
	PrintToChatAll("%N deployed the bomb!", client);
	if(entity != -1)
	{
		FireEntityOutput(entity, "OnCapture", entity);
		FireEntityOutput(entity, "OnCapTeam2", entity);
	}
	else
	{
		ThrowError("Could not find func_capturezone");
	}
}

// code from Pelipoika's bot control
// executes a fake command with a delay between executions
bool FakeClientCommandThrottled(int client, const char[] command)
{
	if(g_flNextCommand[client] > GetGameTime())
		return false;
	
	FakeClientCommand(client, command);
	
	g_flNextCommand[client] = GetGameTime() + 0.4;
	
	return true;
}

// code from Pelipoika's bot control
// Updates the bomb level show on the HUD
void Frame_UpdateBombHUD(int serial)
{
	int client = GetClientFromSerial(serial);

	if(client)
	{
		RobotPlayer rp = RobotPlayer(client);
		int entity = FindEntityByClassname(-1, "tf_objective_resource");
		SetEntProp(entity, Prop_Send, "m_nFlagCarrierUpgradeLevel", rp.bomblevel);
		SetEntPropFloat(entity, Prop_Send, "m_flMvMBaseBombUpgradeTime", rp.inspawn ? -1.0 : GetGameTime());
		SetEntPropFloat(entity, Prop_Send, "m_flMvMNextBombUpgradeTime", rp.inspawn ? -1.0 : rp.nextbombupgradetime);
	}
}