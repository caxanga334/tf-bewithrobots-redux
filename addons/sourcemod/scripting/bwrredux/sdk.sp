// SDK calls, SDK hooks

void SetupEntityHooks()
{
	HookEntityOutput("team_control_point", "OnCapTeam1", OnGateCaptureByREDTeam);
	HookEntityOutput("team_control_point", "OnCapTeam2", OnGateCaptureByBLUTeam);
}

void OnGateCaptureByREDTeam(const char[] output, int caller, int activator, float delay)
{
	CreateTimer(1.0, Timer_CheckGates, _, TIMER_FLAG_NO_MAPCHANGE);
}

void OnGateCaptureByBLUTeam(const char[] output, int caller, int activator, float delay)
{
	CreateTimer(1.0, Timer_CheckGates, _, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(2.0, Timer_UpdateGatebotStatus, _, TIMER_FLAG_NO_MAPCHANGE);
}

void TF2_PlaySequence(int client, const char[] sequence)
{
	SDKCall(g_hSDKPlaySpecificSequence, client, sequence);
}

/**
 * Removes an object from a player
 *
 * @param client		The client to remove from
 * @param obj			The object entity index to remove
 */
void TF2_RemoveObject(int client, int obj)
{
	SDKCall(g_hSDKRemoveObject, client, obj);
}

/**
 * Sets the object builder
 * 
 * @param entity	  The entity to set the builder
 * @param builder     The builder entity index or -1 for NULL
 */
void TF2_SetBuilder(int entity, int builder = INVALID_ENT_REFERENCE)
{
	SDKCall(g_hSDKSetBuilder, entity, builder);
}

/**
 * Gets the entity world center
 *
 * @param ent		The entity to get the center from
 * @param origin	origin vector to store
 * @return     no return
 */
void GetEntityWorldCenter(int ent, float[] origin)
{
	if(!IsValidEntity(ent))
	{
		ThrowError("void GetEntityWorldCenter(int ent, float[] origin) received invalid ent! %i", ent);
		return;
	}
	
	SDKCall(g_hSDKWorldSpaceCenter, ent, origin);
}

/**
 * Description
 *
 * @param concept		Speak Concept ID (see enum)
 * @param team			Team ID to speak the concept
 * @param modifiers		To do: What does this do?
 * @return     no return
 */
void TF2_SpeakConcept(int concept, int team, char[] modifiers)
{
	SDKCall(g_hSDKSpeakConcept, concept, team, modifiers);
}

/**
 * Pushes all player in the given position (MvM engineer Push)
 *
 * @param vPos			The origin to create the push
 * @param range			The push effect range
 * @param force			The push effect force
 * @param team			Which team should be pushed
 * @return     no return
 */
void TF2_PushAllPlayers(float vPos[3], float range, float force, int team)
{
	SDKCall(g_hSDKPushAwayPlayers, vPos, range, force, team, 0);
}

/**
 * Spawns a currency pack
 *
 * @param client			The client to drop from
 * @param type				Currency pack type
 * @param amount			How much is this currency pack worth
 * @param forceddistribute	Force distribution? (Instantly awards players the currency, same behavior when bots are killed by snipers)
 * @param moneymaker		The client who triggered the drop (generally the client who killed the client sent to the first param)
 * @return     no return
 */
stock void TF2_DropCurrencyPack(int client, int type, int amount, bool forcedistribute, int moneymaker)
{
	SDKCall(g_hSDKDropCurrency, client, type, amount, forcedistribute, moneymaker);
}

void SetupHook_SpawnRoom(int spawnroom)
{
	SDKHook(spawnroom, SDKHook_StartTouchPost, OnStartTouchSpawnRoom);
	SDKHook(spawnroom, SDKHook_EndTouchPost, OnEndTouchSpawnRoom);
	SDKHook(spawnroom, SDKHook_TouchPost, OnTouchSpawnRoom);
}

void OnStartTouchSpawnRoom(int entity, int other)
{
	if(IsValidClient(other))
	{
		TF2BWR_OnClientStartTouchSpawn(other);
	}
}

void OnEndTouchSpawnRoom(int entity, int other)
{
	if(IsValidClient(other))
	{
		TF2BWR_OnClientEndTouchSpawn(other);
	}
}

void OnTouchSpawnRoom(int entity, int other)
{
	if(IsValidClient(other))
	{
		TF2BWR_OnClientTouchSpawn(other);
	}
}

void TF2BWR_OnClientStartTouchSpawn(int client)
{
	RobotPlayer rp = RobotPlayer(client);
	rp.inspawn = true;

	if(rp.carrier)
	{
		RequestFrame(Frame_UpdateBombHUD, GetClientSerial(client));
	}

	if(rp.isrobot && rp.templateindex >= 0)
	{
		Call_StartForward(g_OnEnterSpawn);
		Call_PushCell(client);
		Call_PushCell(g_eTemplates[rp.templateindex].pluginID);
		Call_PushCell(TF2_GetPlayerClass(client));
		Call_PushCell(g_eTemplates[rp.templateindex].index);
		Call_PushCell(g_eTemplates[rp.templateindex].type);
		Call_Finish();
	}
}

void TF2BWR_OnClientEndTouchSpawn(int client)
{
	RobotPlayer rp = RobotPlayer(client);
	rp.inspawn = false;
	
	if(rp.carrier)
	{
		switch(rp.bomblevel)
		{
			case 0: rp.nextbombupgradetime = GetGameTime() + c_bomb_upgrade1.FloatValue;
			case 1: rp.nextbombupgradetime = GetGameTime() + c_bomb_upgrade2.FloatValue;
			case 2: rp.nextbombupgradetime = GetGameTime() + c_bomb_upgrade3.FloatValue;
			case 3,4: rp.nextbombupgradetime = GetGameTime();
		}
		RequestFrame(Frame_UpdateBombHUD, GetClientSerial(client));
	}

	if(rp.isrobot)
	{
		SetEntPropFloat(client, Prop_Send, "m_flStealthNoAttackExpire", GetGameTime() + 1.5);
		TF2_AddCondition(client, TFCond_UberchargedHidden, 1.0);

		if(rp.templateindex >= 0)
		{
			Call_StartForward(g_OnLeaveSpawn);
			Call_PushCell(client);
			Call_PushCell(g_eTemplates[rp.templateindex].pluginID);
			Call_PushCell(TF2_GetPlayerClass(client));
			Call_PushCell(g_eTemplates[rp.templateindex].index);
			Call_PushCell(g_eTemplates[rp.templateindex].type);
			Call_Finish();
		}
	}
}

void TF2BWR_OnClientTouchSpawn(int client)
{
	RobotPlayer rp = RobotPlayer(client);

	if(!rp.inspawn)
	{
		rp.inspawn = true;

		if(rp.isrobot && rp.templateindex >= 0)
		{
			Call_StartForward(g_OnEnterSpawn);
			Call_PushCell(client);
			Call_PushCell(g_eTemplates[rp.templateindex].pluginID);
			Call_PushCell(TF2_GetPlayerClass(client));
			Call_PushCell(g_eTemplates[rp.templateindex].index);
			Call_PushCell(g_eTemplates[rp.templateindex].type);
			Call_Finish();	
		}
	}
}

void OnStartTouchCaptureZone(int entity, int other)
{
	if(IsValidClient(other))
	{
		RobotPlayer rp = RobotPlayer(other);

		if(rp.carrier)
		{
			rp.StartDeploying(FindConVar("tf_deploying_bomb_time").FloatValue + 0.5);
			TF2BWR_DeployBomb(other);
		}
	}
}

void OnEndTouchCaptureZone(int entity, int other)
{
	if(IsValidClient(other))
	{
		RobotPlayer rp = RobotPlayer(other);

		if(rp.carrier)
		{
			rp.StopDeploying();
			TF2BWR_CancelDeployBomb(other);
		}		
	}
}

void OnTFBotTagFilterSpawnPost(int entity)
{
	DHookEntity(g_hCFilterTFBotHasTag, true, entity);
}

void OnReviveMarkerSpawnPost(int entity)
{
	RequestFrame(Frame_RemoveReviveMaker, EntIndexToEntRef(entity));
}

void OnAmmoPackSpawnPost(int entity)
{
	RequestFrame(Frame_RemoveAmmoPack, EntIndexToEntRef(entity));
}

void OnPlayerTakeDamageAlivePost(int victim, int attacker, int inflictor, float damage, int damagetype, int weapon, const float damageForce[3], const float damagePosition[3], int damagecustom)
{
	if(!IsClientInGame(victim))
		return;

	if(TF2_GetClientTeam(victim) == TFTeam_Red)
		return;

	if(IsValidClient(attacker))
	{
		if(TF2_GetClientTeam(attacker) == TFTeam_Red)
		{
			if(g_PlayerData[attacker].timer <= GetGameTime())
			{
				g_PlayerData[attacker].damage = RoundToCeil(damage);
				g_PlayerData[attacker].timer = GetGameTime() + 90.0;
			}
			else
			{
				g_PlayerData[attacker].damage += RoundToCeil(damage);
				g_PlayerData[attacker].timer = GetGameTime() + 90.0;				
			}
		}
	}
}