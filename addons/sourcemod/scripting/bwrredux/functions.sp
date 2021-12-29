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
			if(owner == client) {
				RemoveEntity(entity);
			}
		}
		
		entity = -1;
		while((entity = FindEntityByClassname(entity, "tf_usableitem")) > MaxClients)
		{
			owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
			if(owner == client) {
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
		if(entity != -1) {
			if(TF2Util_IsEntityWearable(entity)) {
				TF2_RemoveWearable(client, entity);
			}
			else {
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
stock void TF2_PickUpFlag(int client, int flag)
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
	
	if( update )
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