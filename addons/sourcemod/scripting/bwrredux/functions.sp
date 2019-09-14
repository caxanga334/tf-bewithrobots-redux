// functions that can be removed from the main file

// selects a random player from a team
int GetRandomPlayer(TFTeam Team, bool bIncludeBots = false)
{
	int players_available[MAXPLAYERS+1];
	int counter = 0; // counts how many valid players we have
	for (int i = 1; i <= MaxClients; i++)
	{
		if(bIncludeBots)
		{
			if(IsClientInGame(i) && TF2_GetClientTeam(i) == Team)
			{
				players_available[counter] = i; // stores the client userid
				counter++;
			}			
		}
		else
		{
			if(IsClientInGame(i) && !IsFakeClient(i) && TF2_GetClientTeam(i) == Team)
			{
				players_available[counter] = i; // stores the client userid
				counter++;
			}				
		}

	}
	
	// now we should have an array filled with user ids and exactly how many players we have in game.
	int iRandomMax = counter - 1;
	int iRandom = GetRandomInt(0,iRandomMax); // get a random number between 0 and counted players
	// now we get the user id from the array cell selected via iRandom
	return players_available[iRandom];
}

// IsMvM code by FlaminSarge
bool IsMvM(bool forceRecalc = false)
{
	static bool found = false;
	static bool ismvm = false;
	if (forceRecalc)
	{
		found = false;
		ismvm = false;
	}
	if (!found)
	{
		int i = FindEntityByClassname(-1, "tf_logic_mann_vs_machine");
		if (i > MaxClients && IsValidEntity(i)) ismvm = true;
		found = true;
	}
	return ismvm;
}

void TeleportSpyRobot(int client)
{
	int target = GetRandomClientFromTeam( view_as<int>(TFTeam_Red), false);
	float TargetPos[3], CenterPos[3];
	char targetname[MAX_NAME_LENGTH];
	
	GetClientName(target, targetname, sizeof(targetname));
	GetClientAbsOrigin(target, TargetPos);
	TargetPos[0] += GetRandomFloat(-1000.0, 1000.0);
	TargetPos[1] += GetRandomFloat(-1000.0, 1000.0);
	TargetPos[2] += GetRandomFloat(-300.0, 300.0);
	
	CNavArea NavArea = NavMesh_GetNearestArea(TargetPos, false, 2000.0, false, true);
	NavArea.GetCenter(CenterPos);
	CenterPos[2] += 25.0;
	TeleportEntity(client, CenterPos, NULL_VECTOR, NULL_VECTOR);
	CPrintToChat(client, "{blue}You spawned near {green}%s", targetname);
}

// searches for an engineer nest close to the bomb
int FindEngineerNestNearBomb()
{
	float nVec[3]; // nest pos
	float bVec[3]; // bomb pos
	float current_dist;
	float smallest_dist = 15000.0;
	int iTargetNest = -1; // the closest nest found.
	int i = -1;
	int iBomb = -1; // the bomb we're going to use to check distance.
	int iBombOwner = -1; // bomb carrier
	
	while( (i = FindEntityByClassname(i, "item_teamflag" )) != -1 )
	{
		if( IsValidEntity(i) && GetEntProp( i, Prop_Send, "m_bDisabled" ) == 0 ) // ignore disabled bombs
		{
			iBomb = i; // use the first bomb found.
			iBombOwner = GetEntPropEnt( i, Prop_Send, "m_hOwnerEntity" );
			break;
		}
	}
	
	if( iBomb == -1 )
		return -1; // no bomb found
	
	i = -1;
	while( (i = FindEntityByClassname(i, "bot_hint_engineer_nest" )) != -1 )
	{
		if( IsValidEntity(i) )
		{
			if( iBombOwner == -1 || iBombOwner > MaxClients)
			{
				GetEntPropVector(iBomb, Prop_Send, "m_vecOrigin", bVec); // bomb
			}
			else // if the bomb is carried by a player, use the eye position of the carrier instead
			{
				GetClientEyePosition(iBombOwner, bVec);
			}
			GetEntPropVector(i, Prop_Send, "m_vecOrigin", nVec); // nest
			
			current_dist = GetVectorDistance(bVec, nVec);
			
			if( current_dist < smallest_dist )
			{
				iTargetNest = i;
				smallest_dist = current_dist;
			}
		}
	}
	
	return iTargetNest;
}

// teleports a client to the entity origin.
// also adds engineer spawn particle
void TeleportEngineerToEntity(int iEntity, int client, float OffsetVec[3] = {0.0,0.0,0.0})
{
	float EntVec[3];
	float FinalVec[3];
	if( IsValidEntity(iEntity) )
	{
		GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", EntVec);
		AddVectors(EntVec, OffsetVec, FinalVec);
		TeleportEntity(client, FinalVec, NULL_VECTOR, NULL_VECTOR);
		CreateTEParticle("teleported_blue",FinalVec, _, _,3.0,iEntity,1,0);
		CreateTEParticle("teleported_mvm_bot",FinalVec, _, _,3.0,iEntity,1,0);
	}
}

// searches for a teleporter exit 
int FindBestBluTeleporter()
{
	float nVec[3]; // nest pos
	float bVec[3]; // bomb pos
	float current_dist;
	float smallest_dist = 15000.0;
	int iTargetTele = -1; // the closest nest found.
	int i = -1;
	int iBomb = -1; // the bomb we're going to use to check distance.
	int iBombOwner = -1;
	
	while( (i = FindEntityByClassname(i, "item_teamflag" )) != -1 )
	{
		if( IsValidEntity(i) && GetEntProp( i, Prop_Send, "m_bDisabled" ) == 0 ) // ignore disabled bombs
		{
			iBomb = i; // use the first bomb found.
			iBombOwner = GetEntPropEnt( i, Prop_Send, "m_hOwnerEntity" );
			break;
		}
	}
	
	if( iBomb == -1 )
		return -1; // no bomb found
	
	i = -1;
	while( (i = FindEntityByClassname(i, "obj_teleporter" )) != -1 )
	{
		if( IsValidEntity(i) )
		{
			if( GetEntProp( i, Prop_Send, "m_bHasSapper" ) == 0 && GetEntProp( i, Prop_Send, "m_iTeamNum" ) != view_as<int>(TFTeam_Red) && GetEntPropFloat(i, Prop_Send, "m_flPercentageConstructed") >= 0.99 )
			{ // teleporters from spectator are also valid since we started moving dead blu players to spec
				if( iBombOwner == -1 || iBombOwner > MaxClients)
				{
					GetEntPropVector(iBomb, Prop_Send, "m_vecOrigin", bVec); // bomb
				}
				else // if the bomb is carried by a player, use the eye position of the carrier instead
				{
					GetClientEyePosition(iBombOwner, bVec);
				}
				
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", nVec); // nest
				
				current_dist = GetVectorDistance(bVec, nVec);
				
				if( current_dist < smallest_dist )
				{
					iTargetTele = i;
					smallest_dist = current_dist;
				}
			}
		}
	}
	
	return iTargetTele;
}

// TeleportPlayerToEntity but for teleporters
void SpawnOnTeleporter(int teleporter,int client)
{
	float OriginVec[3];
	float Scale = GetEntPropFloat(client, Prop_Send, "m_flModelScale");
	if( IsValidEntity(teleporter) )
	{
		GetEntPropVector(teleporter, Prop_Send, "m_vecOrigin", OriginVec);
		
		if( Scale <= 1.0 )
		{
			OriginVec[2] += 16;
		}
		else if( Scale >= 1.1 && Scale <= 1.4 )
		{
			OriginVec[2] += 20;
		}
		else if( Scale >= 1.5 && Scale <= 1.6 )
		{
			OriginVec[2] += 23;
		}		
		else if( Scale >= 1.7 && Scale <= 1.8 )
		{
			OriginVec[2] += 26;
		}
		else if( Scale >= 1.9 )
		{
			OriginVec[2] += 50;
		}
		
		TF2_AddCondition(client, TFCond_UberchargedCanteen, 5.1); // 0.1 sec to compensate for a small delay
		TeleportEntity(client, OriginVec, NULL_VECTOR, NULL_VECTOR);
		EmitGameSoundToAll("MVM.Robot_Teleporter_Deliver", teleporter);
	}
}

// emits game sound to all players in RED
void EmitGSToRed(const char[] gamesound)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if( IsClientInGame(i) && !IsFakeClient(i) )
		{
			if( TF2_GetClientTeam(i) == TFTeam_Red )
			{
				EmitGameSoundToClient(i, gamesound);
			}
		}
	}
}

// emits sound to all players in RED
/* void EmitSoundToRed(const char[] soundpath)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if( IsClientInGame(i) && !IsFakeClient(i) )
		{
			if( TF2_GetClientTeam(i) == TFTeam_Red )
			{
				EmitSoundToClient(i, soundpath);
			}
		}
	}
} */

// announces when a robot engineer is killed.
void AnnounceEngineerDeath(int client)
{
	bool bFoundTele = false;
	int i = -1;
	int iOwner = -1;
	
	if( IsClientInGame(client) && !IsFakeClient(client) )
	{
		while( (i = FindEntityByClassname(i, "obj_teleporter" )) != -1 )
		{
			if( IsValidEntity(i) )
			{
				if( GetEntProp( i, Prop_Send, "m_iTeamNum" ) == view_as<int>(TFTeam_Blue) )
				{				
					iOwner = GetEntPropEnt( i, Prop_Send, "m_hBuilder" );
					if( iOwner == client )
					{
						bFoundTele = true;
						break;
					}
				}
			}
		}
		if( bFoundTele ) // found a teleporter
		{
			EmitGSToRed("Announcer.MVM_An_Engineer_Bot_Is_Dead_But_Not_Teleporter");
		}
		else if( GameRules_GetRoundState() == RoundState_RoundRunning )
		{
			EmitGSToRed("Announcer.MVM_An_Engineer_Bot_Is_Dead");
		}
	}
}

// returns the number of classes in a team.
int GetClassCount(TFClassType TFClass, TFTeam Team, bool bIncludeBots = false, bool bIncludeDead = true)
{
	int iClassNum = 0;
	for(int i = 1; i <= MaxClients; i++)
	{
		if( IsClientInGame(i) )
		{
			if( bIncludeBots )
			{
				if( TF2_GetClientTeam(i) == Team )
				{
					if( TF2_GetPlayerClass(i) == TFClass )
					{
						if( bIncludeDead )
							iClassNum++;
						else if( IsPlayerAlive(i) )
							iClassNum++;
					}
				}
			}
			else
			{
				if( !IsFakeClient(i) )
				{
					if( TF2_GetClientTeam(i) == Team )
					{
						if( TF2_GetPlayerClass(i) == TFClass )
						{
							if( bIncludeDead )
								iClassNum++;
							else if( IsPlayerAlive(i) )
								iClassNum++;
						}
					}
				}
			}
		}
	}
	
	return iClassNum;
}

// returns the entity index of the first available weapon
int GetFirstAvailableWeapon(int client)
{
	int iWeapon = -1;
	int iSlot = 0;
	
	while( iSlot <= 5 )
	{
		iWeapon = GetPlayerWeaponSlot(client, iSlot);
		iSlot++
		if( iWeapon != -1 )
		{
			break;
		}
	}
	
	return iWeapon;
}

void BlockBombPickup(int client)
{
	if( IsFakeClient(client) )
		return;

	int iWeapon = GetFirstAvailableWeapon(client);
	if( iWeapon != -1 )
	{
		TF2Attrib_SetByName(iWeapon, "cannot pick up intelligence", 1.0);
	}
}

// add particle to the robot engineer teleporter
void AddParticleToTeleporter(int entity)
{
	int particle = CreateEntityByName("info_particle_system");

	char targetname[64];
	float VecOrigin[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", VecOrigin);
	VecOrigin[2] -= 500;
	TeleportEntity(particle, VecOrigin, NULL_VECTOR, NULL_VECTOR);

	Format(targetname, sizeof(targetname), "tele_target_%i", entity);
	DispatchKeyValue(entity, "targetname", targetname);

	DispatchKeyValue(particle, "targetname", "bwrr_tele_particle");
	DispatchKeyValue(particle, "parentname", targetname);
	DispatchKeyValue(particle, "effect_name", "teleporter_mvm_bot_persist");
	DispatchSpawn(particle);
	SetVariantString(targetname);
	AcceptEntityInput(particle, "SetParent", particle, particle);
	SetEntPropEnt(particle, Prop_Send, "m_hOwnerEntity", entity);
	ActivateEntity(particle);
	AcceptEntityInput(particle, "start");
}

void OnDestroyedTeleporter(const char[] output, int caller, int activator, float delay)
{
	AcceptEntityInput(caller,"KillHierarchy");
}

bool CheckTeleportClamping(int telepoter)
{
	float VecTeleporter[3], RayAngles[3], RayEndPos[3];
	float fldistance;
	GetEntPropVector(telepoter, Prop_Send, "m_vecOrigin", VecTeleporter);
	VecTeleporter[2] += 5;
	
	bool bSmallMap = IsSmallMap();
	Handle Tracer = null;
	
	RayAngles[0] = 270.0; // up
	RayAngles[1] = 0.0;
	RayAngles[2] = 0.0;
	Tracer = TR_TraceRayFilterEx(VecTeleporter, RayAngles, MASK_SHOT, RayType_Infinite, TraceFilterIgnorePlayers, telepoter)
	if( Tracer != null && TR_DidHit(Tracer) )
	{
		TR_GetEndPosition(RayEndPos, Tracer);
		fldistance = GetVectorDistance(VecTeleporter, RayEndPos);
		if( bSmallMap )
		{
			if(fldistance < 120)
			{
				CloseHandle(Tracer);
				return true;
			}
		}
		else
		{
			if(fldistance < 185)
			{
				CloseHandle(Tracer);
				return true;
			}			
		}
	}

	CloseHandle(Tracer);
	Tracer = null;	
	RayAngles[0] = 225.0; // angled roof check
	RayAngles[1] = 0.0;
	RayAngles[2] = 0.0;
	Tracer = TR_TraceRayFilterEx(VecTeleporter, RayAngles, MASK_SHOT, RayType_Infinite, TraceFilterIgnorePlayers, telepoter)
	if( Tracer != null && TR_DidHit(Tracer) )
	{
		TR_GetEndPosition(RayEndPos, Tracer);
		fldistance = GetVectorDistance(VecTeleporter, RayEndPos);
		if( bSmallMap )
		{
			if(fldistance < 70)
			{
				CloseHandle(Tracer);
				return true;
			}
		}
		else
		{
			if(fldistance < 110)
			{
				CloseHandle(Tracer);
				return true;
			}			
		}
	}
	
	CloseHandle(Tracer);
	Tracer = null;	
	RayAngles[0] = 225.0; // angled roof check
	RayAngles[1] = 90.0;
	RayAngles[2] = 0.0;
	Tracer = TR_TraceRayFilterEx(VecTeleporter, RayAngles, MASK_SHOT, RayType_Infinite, TraceFilterIgnorePlayers, telepoter)
	if( Tracer != null && TR_DidHit(Tracer) )
	{
		TR_GetEndPosition(RayEndPos, Tracer);
		fldistance = GetVectorDistance(VecTeleporter, RayEndPos);
		if( bSmallMap )
		{
			if(fldistance < 70)
			{
				CloseHandle(Tracer);
				return true;
			}
		}
		else
		{
			if(fldistance < 110)
			{
				CloseHandle(Tracer);
				return true;
			}			
		}
	}
	
	CloseHandle(Tracer);
	Tracer = null;	
	RayAngles[0] = 225.0; // angled roof check
	RayAngles[1] = 180.0;
	RayAngles[2] = 0.0;
	Tracer = TR_TraceRayFilterEx(VecTeleporter, RayAngles, MASK_SHOT, RayType_Infinite, TraceFilterIgnorePlayers, telepoter)
	if( Tracer != null && TR_DidHit(Tracer) )
	{
		TR_GetEndPosition(RayEndPos, Tracer);
		fldistance = GetVectorDistance(VecTeleporter, RayEndPos);
		if( bSmallMap )
		{
			if(fldistance < 70)
			{
				CloseHandle(Tracer);
				return true;
			}
		}
		else
		{
			if(fldistance < 110)
			{
				CloseHandle(Tracer);
				return true;
			}			
		}
	}
	
	CloseHandle(Tracer);
	Tracer = null;	
	RayAngles[0] = 225.0; // angled roof check
	RayAngles[1] = 270.0;
	RayAngles[2] = 0.0;
	Tracer = TR_TraceRayFilterEx(VecTeleporter, RayAngles, MASK_SHOT, RayType_Infinite, TraceFilterIgnorePlayers, telepoter)
	if( Tracer != null && TR_DidHit(Tracer) )
	{
		TR_GetEndPosition(RayEndPos, Tracer);
		fldistance = GetVectorDistance(VecTeleporter, RayEndPos);
		if( bSmallMap )
		{
			if(fldistance < 70)
			{
				CloseHandle(Tracer);
				return true;
			}
		}
		else
		{
			if(fldistance < 110)
			{
				CloseHandle(Tracer);
				return true;
			}			
		}
	}
	
	CloseHandle(Tracer);
	Tracer = null;
	RayAngles[0] = 0.0;
	RayAngles[1] = 0.0; // front
	RayAngles[2] = 0.0;
	Tracer = TR_TraceRayFilterEx(VecTeleporter, RayAngles, MASK_SHOT, RayType_Infinite, TraceFilterIgnorePlayers, telepoter)
	if( Tracer != null && TR_DidHit(Tracer) )
	{
		TR_GetEndPosition(RayEndPos, Tracer);
		fldistance = GetVectorDistance(VecTeleporter, RayEndPos);
		if( bSmallMap )
		{
			if(fldistance < 36)
			{
				CloseHandle(Tracer);
				return true;
			}
		}
		else
		{
			if(fldistance < 68)
			{
				CloseHandle(Tracer);
				return true;
			}			
		}
	}
	
	CloseHandle(Tracer);
	Tracer = null;
	RayAngles[0] = 0.0;
	RayAngles[1] = 90.0;
	RayAngles[2] = 0.0;
	Tracer = TR_TraceRayFilterEx(VecTeleporter, RayAngles, MASK_SHOT, RayType_Infinite, TraceFilterIgnorePlayers, telepoter)
	if( Tracer != null && TR_DidHit(Tracer) )
	{
		TR_GetEndPosition(RayEndPos, Tracer);
		fldistance = GetVectorDistance(VecTeleporter, RayEndPos);
		if( bSmallMap )
		{
			if(fldistance < 36)
			{
				CloseHandle(Tracer);
				return true;
			}
		}
		else
		{
			if(fldistance < 68)
			{
				CloseHandle(Tracer);
				return true;
			}			
		}
	}
	
	CloseHandle(Tracer);
	Tracer = null;
	RayAngles[0] = 0.0;
	RayAngles[1] = 180.0;
	RayAngles[2] = 0.0;
	Tracer = TR_TraceRayFilterEx(VecTeleporter, RayAngles, MASK_SHOT, RayType_Infinite, TraceFilterIgnorePlayers, telepoter)
	if( Tracer != null && TR_DidHit(Tracer) )
	{
		TR_GetEndPosition(RayEndPos, Tracer);
		fldistance = GetVectorDistance(VecTeleporter, RayEndPos);
		if( bSmallMap )
		{
			if(fldistance < 36)
			{
				CloseHandle(Tracer);
				return true;
			}
		}
		else
		{
			if(fldistance < 68)
			{
				CloseHandle(Tracer);
				return true;
			}			
		}
	}
	
	CloseHandle(Tracer);
	Tracer = null;
	RayAngles[0] = 0.0;
	RayAngles[1] = 270.0;
	RayAngles[2] = 0.0;
	Tracer = TR_TraceRayFilterEx(VecTeleporter, RayAngles, MASK_SHOT, RayType_Infinite, TraceFilterIgnorePlayers, telepoter)
	if( Tracer != null && TR_DidHit(Tracer) )
	{
		TR_GetEndPosition(RayEndPos, Tracer);
		fldistance = GetVectorDistance(VecTeleporter, RayEndPos);
		if( bSmallMap )
		{
			if(fldistance < 36)
			{
				CloseHandle(Tracer);
				return true;
			}
		}
		else
		{
			if(fldistance < 68)
			{
				CloseHandle(Tracer);
				return true;
			}			
		}
	}
	
	CloseHandle(Tracer);
	Tracer = null;
	RayAngles[0] = 0.0;
	RayAngles[1] = 45.0;
	RayAngles[2] = 0.0;
	Tracer = TR_TraceRayFilterEx(VecTeleporter, RayAngles, MASK_SHOT, RayType_Infinite, TraceFilterIgnorePlayers, telepoter)
	if( Tracer != null && TR_DidHit(Tracer) )
	{
		TR_GetEndPosition(RayEndPos, Tracer);
		fldistance = GetVectorDistance(VecTeleporter, RayEndPos);
		if( bSmallMap )
		{
			if(fldistance < 60)
			{
				CloseHandle(Tracer);
				return true;
			}
		}
		else
		{
			if(fldistance < 96)
			{
				CloseHandle(Tracer);
				return true;
			}			
		}
	}
	
	CloseHandle(Tracer);
	Tracer = null;
	RayAngles[0] = 0.0;
	RayAngles[1] = 135.0;
	RayAngles[2] = 0.0;
	Tracer = TR_TraceRayFilterEx(VecTeleporter, RayAngles, MASK_SHOT, RayType_Infinite, TraceFilterIgnorePlayers, telepoter)
	if( Tracer != null && TR_DidHit(Tracer) )
	{
		TR_GetEndPosition(RayEndPos, Tracer);
		fldistance = GetVectorDistance(VecTeleporter, RayEndPos);
		if( bSmallMap )
		{
			if(fldistance < 60)
			{
				CloseHandle(Tracer);
				return true;
			}
		}
		else
		{
			if(fldistance < 96)
			{
				CloseHandle(Tracer);
				return true;
			}			
		}
	}
	
	CloseHandle(Tracer);
	Tracer = null;
	RayAngles[0] = 0.0;
	RayAngles[1] = 225.0;
	RayAngles[2] = 0.0;
	Tracer = TR_TraceRayFilterEx(VecTeleporter, RayAngles, MASK_SHOT, RayType_Infinite, TraceFilterIgnorePlayers, telepoter)
	if( Tracer != null && TR_DidHit(Tracer) )
	{
		TR_GetEndPosition(RayEndPos, Tracer);
		fldistance = GetVectorDistance(VecTeleporter, RayEndPos);
		if( bSmallMap )
		{
			if(fldistance < 60)
			{
				CloseHandle(Tracer);
				return true;
			}
		}
		else
		{
			if(fldistance < 96)
			{
				CloseHandle(Tracer);
				return true;
			}			
		}
	}
	
	CloseHandle(Tracer);
	Tracer = null;
	RayAngles[0] = 0.0;
	RayAngles[1] = 315.0;
	RayAngles[2] = 0.0;
	Tracer = TR_TraceRayFilterEx(VecTeleporter, RayAngles, MASK_SHOT, RayType_Infinite, TraceFilterIgnorePlayers, telepoter)
	if( Tracer != null && TR_DidHit(Tracer) )
	{
		TR_GetEndPosition(RayEndPos, Tracer);
		fldistance = GetVectorDistance(VecTeleporter, RayEndPos);
		if( bSmallMap )
		{
			if(fldistance < 60)
			{
				CloseHandle(Tracer);
				return true;
			}
		}
		else
		{
			if(fldistance < 96)
			{
				CloseHandle(Tracer);
				return true;
			}			
		}
	}
	
	CloseHandle(Tracer);
	return false
}

bool TraceFilterIgnorePlayers(int entity, int contentsMask)
{
    if(entity >= 1 && entity <= MaxClients)
    {
        return false;
    }
    if(entity != 0)
        return false;
  
    return true;
}

// explodes the bomb hatch using the tank's logic_relay
void TriggerHatchExplosion()
{
	int i = -1;
	while ((i = FindEntityByClassname(i, "logic_relay")) != -1)
	{
		if(IsValidEntity(i))
		{
			char strName[50];
			GetEntPropString(i, Prop_Data, "m_iName", strName, sizeof(strName));
			if(strcmp(strName, "boss_deploy_relay") == 0)
			{
				AcceptEntityInput(i, "Trigger");
				break;
			}
			else if(strcmp(strName, "bwr_round_win_relay") == 0)
			{
				AcceptEntityInput(i, "Trigger");
				break;
			}
		} 
	}
}

void CreateTEParticle(	char strParticle[128],
						float OriginVec[3]=NULL_VECTOR,
						float StartVec[3]=NULL_VECTOR,
						float AnglesVec[3]=NULL_VECTOR,
						float flDelay=0.0,
						int iEntity=-1,
						int iAttachType=-1,
						int iAttachPoint=-1 )
{
	int ParticleTable = FindStringTable("ParticleEffectNames");
	if( ParticleTable == INVALID_STRING_TABLE )
	{
		LogError("Could not find String Table \"ParticleEffectNames\"");
		return;
	}
	int iCounter = GetStringTableNumStrings(ParticleTable);
	int iParticleIndex = INVALID_STRING_INDEX;
	char Temp[128];
	
	for(int i = 0;i < iCounter; i++)
	{
		ReadStringTable(ParticleTable, i, Temp, sizeof(Temp));
		if(StrEqual(Temp, strParticle, false))
		{
			iParticleIndex = i;
			break;
		}
	}
	if( iParticleIndex == INVALID_STRING_INDEX )
	{
		LogError("Could not find particle named \"%s\"", strParticle);
		return;
	}
	
	TE_Start("TFParticleEffect");
	TE_WriteFloat("m_vecOrigin[0]", OriginVec[0]);
	TE_WriteFloat("m_vecOrigin[1]", OriginVec[1]);
	TE_WriteFloat("m_vecOrigin[2]", OriginVec[2]);
	TE_WriteFloat("m_vecStart[0]", StartVec[0]);
	TE_WriteFloat("m_vecStart[1]", StartVec[1]);
	TE_WriteFloat("m_vecStart[2]", StartVec[2]);
	TE_WriteVector("m_vecAngles", AnglesVec);
	TE_WriteNum("m_iParticleSystemIndex", iParticleIndex);
	
	if( iEntity != -1 )
	{
		TE_WriteNum("entindex", iEntity);
	}
	if( iAttachType != -1 )
	{
		TE_WriteNum("m_iAttachType", iAttachType);
	}
	if( iAttachPoint != -1 )
	{
		TE_WriteNum("m_iAttachmentPointIndex", iAttachPoint);
	}
	
	TE_SendToAll(flDelay);
}

void SentryBuster_Explode( client )
{
	if( !IsPlayerAlive(client) )
		return;
	
	CreateTimer( 1.98, Timer_SentryBuster_Explode, client, TIMER_FLAG_NO_MAPCHANGE );
	EmitGameSoundToAll("MVM.SentryBusterSpin");
	
	SetEntProp( client, Prop_Data, "m_takedamage", 0, 1 );
}

bool CanSeeTarget(int iEntity,int iOther, float flMaxDistance = 0.0 )
{
	if( iEntity <= 0 || iOther <= 0 || !IsValidEntity(iEntity) || !IsValidEntity(iOther) )
		return false;
	
	float vecStart[3];
	float vecStartMaxs[3];
	float vecTarget[3];
	float vecTargetMaxs[3];
	float vecEnd[3];
	
	GetEntPropVector( iEntity, Prop_Data, "m_vecOrigin", vecStart );
	GetEntPropVector( iEntity, Prop_Send, "m_vecMaxs", vecStartMaxs );
	GetEntPropVector( iOther, Prop_Data, "m_vecOrigin", vecTarget );
	GetEntPropVector( iOther, Prop_Send, "m_vecMaxs", vecTargetMaxs );
	
	vecStart[2] += vecStartMaxs[2] / 2.0;
	vecTarget[2] += vecTargetMaxs[2] / 2.0;
	
	if( flMaxDistance > 0.0 )
	{
		float flDistance = GetVectorDistance( vecStart, vecTarget );
		if( flDistance > flMaxDistance )
		{
			return false;
		}
	}
	
	Handle hTrace = TR_TraceRayFilterEx( vecStart, vecTarget, MASK_VISIBLE, RayType_EndPoint, TraceFilterSentryBuster, iEntity );
	if( !TR_DidHit( hTrace ) )
	{
		CloseHandle( hTrace );
		return false;
	}
	
	int iHitEnt = TR_GetEntityIndex( hTrace );
	TR_GetEndPosition( vecEnd, hTrace );
	CloseHandle( hTrace );
	
	if( iHitEnt == iOther || GetVectorDistanceMeter( vecEnd, vecTarget ) <= 1.0 )
	{
		return true;
	}
	
	return false;
}

float GetVectorDistanceMeter( const float vec1[3], const float vec2[3], bool squared = false )
{
	return ( GetVectorDistance( vec1, vec2, squared ) / 50.00 );
}

bool TraceFilterSentryBuster(int iEntity,int iContentsMask, any buster )
{
	if( iEntity < 0 || !IsValidEntity(iEntity) )
		return false;
		
	if( iEntity == buster )
		return false;
		
	if( IsValidClient(iEntity) )
	{
		if( IsClientInGame(iEntity) && IsPlayerAlive(iEntity) )
		{
			return true;
		}
	}
	
	char strClassName[64];
	GetEntityClassname(iEntity, strClassName, sizeof(strClassName));
	
	if( StrContains(strClassName, "obj_", false ) )
	{
		if( GetEntProp( iEntity, Prop_Send, "m_iTeamNum" ) != view_as<int>(TFTeam_Blue) )
		{
			return true;
		}
		else
			return false;
	}
	
	return false;
}

void DealDamage(int entity, int inflictor, int attacker, float damage, int damageType, int weapon=-1, const float damageForce[3]=NULL_VECTOR, const float damagePosition[3]=NULL_VECTOR)
{
	if( entity > 0 && IsValidEntity(entity) && ( entity > MaxClients || IsClientInGame(entity) && IsPlayerAlive(entity) ) && damage > 0 )
	{
		SDKHooks_TakeDamage(entity, inflictor, attacker, damage, damageType, weapon, damageForce, damagePosition);
	}
}

int CreateParticle( float flOrigin[3], const char[] strParticle, float flDuration = -1.0 )
{
	int iParticle = CreateEntityByName( "info_particle_system" );
	if( IsValidEdict( iParticle ) )
	{
		DispatchKeyValue( iParticle, "effect_name", strParticle );
		DispatchKeyValue( iParticle, "targetname", "bwrr_particle_effect" );
		DispatchSpawn( iParticle );
		TeleportEntity( iParticle, flOrigin, NULL_VECTOR, NULL_VECTOR );
		ActivateEntity( iParticle );
		AcceptEntityInput( iParticle, "Start" );
		if( flDuration >= 0.0 )
			CreateTimer( flDuration, Timer_DeleteParticle, EntIndexToEntRef(iParticle) );
	}
	return iParticle;
}

void Robot_GibGiant(int client, float OriginVec[3])
{
	if( IsFakeClient(client) )
		return;

	int Ent;

	//Initialize:
	Ent = CreateEntityByName("tf_ragdoll");

	//Write:
	SetEntPropVector(Ent, Prop_Send, "m_vecRagdollOrigin", OriginVec); 
	SetEntProp(Ent, Prop_Send, "m_iPlayerIndex", client); 
	SetEntPropVector(Ent, Prop_Send, "m_vecForce", NULL_VECTOR);
	SetEntPropVector(Ent, Prop_Send, "m_vecRagdollVelocity", NULL_VECTOR);
	SetEntProp(Ent, Prop_Send, "m_bGib", 1);

	//Send:
	DispatchSpawn(Ent);

	//Remove Body:
	CreateTimer(0.1, Timer_RemoveBody, client, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(8.0, Timer_RemoveGibs, Ent, TIMER_FLAG_NO_MAPCHANGE);
}

// code from bot control
bool LookupOffset(int &iOffset, const char[] strClass, const char[] strProp)
{
	iOffset = FindSendPropInfo(strClass, strProp);
	if(iOffset <= 0)
	{
		LogMessage("Could not locate offset for %s::%s!", strClass, strProp);
		return false;
	}

	return true;
}