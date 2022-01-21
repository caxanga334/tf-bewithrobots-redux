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
 * Gets the object builder
 * 
 * @param entity     The entity index of the object
 * @return           Builder entity index
 */
int TF2_GetBuilder(int entity)
{
	return GetEntPropEnt(entity, Prop_Send, "m_hBuilder");
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

void OnObjectBuilt(int entity)
{
	if(entity == INVALID_ENT_REFERENCE)
		return;

	if(GetEntProp(entity, Prop_Send, "m_iTeamNum") != view_as<int>(TFTeam_Blue))
		return;

	int builder = TF2_GetBuilder(entity);
	if(IsValidClient(builder) && IsFakeClient(builder))
		return;

	float origin[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", origin);
	TF2_PushAllPlayers(origin, 400.0, 500.0, view_as<int>(TFTeam_Red));

	PrintToChatAll("Object Spawned: %i %N", entity, builder);

	switch(TF2_GetObjectType(entity))
	{
		case TFObject_Sentry:
		{
			OnSentrySpawn(entity);
		}
		case TFObject_Dispenser:
		{
			OnDispenserSpawn(entity);
		}
		case TFObject_Teleporter:
		{
			OnTeleporterSpawn(entity);
		}
	}
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
	else if(IsValidEntity(attacker))
	{
		char classname[64];
		GetEntityClassname(attacker, classname, sizeof(classname));

		if(strcmp(classname, "obj_sentrygun", false) == 0)
		{
			int builder = TF2_GetBuilder(attacker);
			if(IsValidClient(builder) && TF2_GetClientTeam(builder) == TFTeam_Red)
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
}

/**
 * Checks if there are enough space to build a teleporter
 * 
 * @param entity     Teleporter entity index.
 */
bool CanBuildTeleporterExit(int entity)
{
	float mins[3], maxs[3], origin[3];

	TF2_GetPlayerHullSize(mins, maxs);
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", origin);
	ScaleVector(mins, 2.15);
	ScaleVector(maxs, 2.15);

	Handle trace = TR_TraceHullFilterEx(origin, origin, mins, maxs, MASK_PLAYERSOLID, TraceFilter_Teleporter, entity);
	bool hit = TR_DidHit(trace);
	
	int builder = TF2_GetBuilder(entity);
	if(IsValidClient(builder) && hit)
	{
		DrawBox(builder, origin, mins, maxs, {255, 0, 0, 255}, 7.0);
		PrintCenterText(builder, "NOT ENOUGH SPACE TO BUILD A TELEPORTER");
		EmitSoundToClient(builder, "buttons/button10.wav", SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_RAIDSIREN);
	}

	delete trace;
	return !hit; // Didhit will be true when the tele can't be built but this should return false
}

void OnSentrySpawn(int entity)
{
	int builder = TF2_GetBuilder(entity);

	if(IsValidClient(builder))
	{
		RobotPlayer rp = RobotPlayer(builder);
		Action result;
		Call_StartForward(g_OnObjectSpawn);
		Call_PushCell(builder);
		Call_PushCell(g_eTemplates[rp.templateindex].pluginID);
		Call_PushCell(TF2_GetPlayerClass(builder));
		Call_PushCell(g_eTemplates[rp.templateindex].index);
		Call_PushCell(g_eTemplates[rp.templateindex].type);
		Call_PushCell(entity);
		Call_PushCell(TF2_GetObjectType(entity));
		Call_Finish(result);

		if(result == Plugin_Continue) // Default Behavior
		{
			if(!TF2_IsMiniBuilding(entity) || !TF2_IsDisposableBuilding(entity))
			{
				DispatchKeyValue(entity, "defaultupgrade", "2");
			}
		}
	}
}

void OnDispenserSpawn(int entity)
{
	int builder = TF2_GetBuilder(entity);

	if(IsValidClient(builder))
	{
		RobotPlayer rp = RobotPlayer(builder);
		Action result;
		Call_StartForward(g_OnObjectSpawn);
		Call_PushCell(builder);
		Call_PushCell(g_eTemplates[rp.templateindex].pluginID);
		Call_PushCell(TF2_GetPlayerClass(builder));
		Call_PushCell(g_eTemplates[rp.templateindex].index);
		Call_PushCell(g_eTemplates[rp.templateindex].type);
		Call_PushCell(entity);
		Call_PushCell(TF2_GetObjectType(entity));
		Call_Finish(result);

		if(result == Plugin_Continue) // Default Behavior
		{
			TF2_SetMiniBuilding(entity);
			SetEntPropFloat(entity, Prop_Send, "m_flModelScale", 0.90);
			SetVariantInt(100);
			AcceptEntityInput(entity, "SetHealth");	
		}
	}
}

void OnTeleporterSpawn(int entity)
{
	if(!CanBuildTeleporterExit(entity))
	{
		RemoveEntity(entity);
		return;
	}

	int builder = TF2_GetBuilder(entity);

	if(IsValidClient(builder))
	{
		RobotPlayer rp = RobotPlayer(builder);
		Action result;
		Call_StartForward(g_OnObjectSpawn);
		Call_PushCell(builder);
		Call_PushCell(g_eTemplates[rp.templateindex].pluginID);
		Call_PushCell(TF2_GetPlayerClass(builder));
		Call_PushCell(g_eTemplates[rp.templateindex].index);
		Call_PushCell(g_eTemplates[rp.templateindex].type);
		Call_PushCell(entity);
		Call_PushCell(TF2_GetObjectType(entity));
		Call_Finish(result);

		if(result == Plugin_Continue) // Default Behavior
		{
			DispatchKeyValue(entity, "defaultupgrade", "2");
			SetEntProp(entity, Prop_Data, "m_iMaxHealth", 300);
			SetVariantInt(300);
			AcceptEntityInput(entity, "SetHealth");
		}

		CreateTimer(0.1, Timer_OnBuildTeleporter, EntIndexToEntRef(entity), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
}

Action Timer_OnBuildTeleporter(Handle timer, any data)
{
	int entity = EntRefToEntIndex(data);

	if(entity == INVALID_ENT_REFERENCE)
	{
		return Plugin_Stop;
	}

	float percent = GetEntPropFloat(entity, Prop_Send, "m_flPercentageConstructed");

	if(percent >= 0.99)
	{
		SetEntProp(entity, Prop_Data, "m_iMaxHealth", 300);
		SetVariantInt(300);
		AcceptEntityInput(entity, "SetHealth");
		Announcer_MakeAnnouncement(Announcement_Teleporter);
		HookSingleEntityOutput(entity, "OnDestroyed", OnBLUTeleporterDestroyed, true);
		float origin[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", origin);
		origin[2] -= 500.0;
		CreateTemporaryParticleSystem(origin, "teleporter_mvm_bot_persist", -1.0, entity);
		return Plugin_Stop;
	}

	return Plugin_Continue;
}

void OnBLUTeleporterDestroyed(const char[] output, int caller, int activator, float delay)
{
	AcceptEntityInput(caller, "KillHierarchy", caller, caller);
}