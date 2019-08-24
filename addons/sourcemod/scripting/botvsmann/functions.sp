// functions that can be removed from the main file

// returns the number of human players on BLU/ROBOT team
int GetHumanRobotCount()
{
	int count = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i))
		{			
			if(TF2_GetClientTeam(i) == TFTeam_Blue)
			{
				count++;
			}
		}
	}
	return count;
}

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

bool IsValidClient( int client )
{
	if( client <= 0 ) return false;
	if( client > MaxClients ) return false;
	if( !IsClientConnected(client) ) return false;
	return IsClientInGame(client);
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

// searches for a info_target to teleport spies to.
int FindNearestSpyHint()
{
	float pVec[3];
	float nVec[3];
	int found = -1;
	float MAX_DIST = 10000.0;
	float found_dist = MAX_DIST;
	float aux_dist;
	int i5 = -1;
	while((i5 = FindEntityByClassname(i5, "info_target")) != -1)
	{
		if(IsValidEntity(i5))
		{
			char strName[64];
			GetEntPropString(i5, Prop_Data, "m_iName", strName, sizeof(strName));
			if(strcmp(strName, "bvm_spy_spawnpoint") == 0)
			{
				GetEntPropVector(i5, Prop_Send, "m_vecOrigin", nVec);
				for (int i = 1; i <= MaxClients; i++)
				{
					if (IsClientInGame(i) && IsPlayerAlive(i) && TF2_GetClientTeam(i) == TFTeam_Red )
					{
						GetClientEyePosition(i, pVec);
						aux_dist = GetVectorDistance(pVec, nVec, false);
						if(aux_dist < found_dist && aux_dist > 2000) // to not spawn in the line of fire
						{
							found = i5;
							found_dist = aux_dist;
						}
					}
				}
			}
		}
	}
	return found;
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
void TeleportPlayerToEntity(int iEntity, int client)
{
	float OriginVec[3];
	if( IsValidEntity(iEntity) )
	{
		GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", OriginVec);
		TeleportEntity(client, OriginVec, NULL_VECTOR, NULL_VECTOR);
	}
}

// checks for spy & engineers teleport entities.
void CheckMapForEntities()
{
	int i = -1;
	bool bSpy;
	bool bEngineer;
	char map[PLATFORM_MAX_PATH];
	char display[PLATFORM_MAX_PATH];
	
	GetCurrentMap(map, sizeof(map));
	GetMapDisplayName(map, display, sizeof(display));
	
	while((i = FindEntityByClassname(i, "info_target")) != -1)
	{
		if(IsValidEntity(i))
		{
			char strName[64];
			GetEntPropString(i, Prop_Data, "m_iName", strName, sizeof(strName));
			if(strcmp(strName, "bvm_spy_spawnpoint") == 0)
			{
				bSpy = true;
				break;
			}
		}
	}
	
	i = -1;
	while((i = FindEntityByClassname(i, "bot_hint_engineer_nest")) != -1)
	{
		if(IsValidEntity(i))
		{
			bEngineer = true;
		}
	}
	
	if( !bSpy )
		LogError("Spy teleport is not supported by the map: %s", display);
		
	if( !bEngineer )
		LogError("Engineer teleport is not supported by the map: %s", display);
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
			if( GetEntProp( i, Prop_Send, "m_bHasSapper" ) == 0 && GetEntProp( i, Prop_Send, "m_iTeamNum" ) == view_as<int>(TFTeam_Blue) && GetEntPropFloat(i, Prop_Send, "m_flPercentageConstructed") >= 0.99 )
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
		EmitSoundToAll(")mvm/mvm_tele_deliver.wav", teleporter, SNDCHAN_STATIC, SNDLEVEL_SCREAMING);
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
void EmitSoundToRed(const char[] soundpath)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if( IsClientInGame(i) && !IsFakeClient(i) )
		{
			if( TF2_GetClientTeam(i) == TFTeam_Red )
			{
				EmitGameSoundToClient(i, soundpath);
			}
		}
	}
}

// announces when a robot engineer is killed.
void AnnounceEngineerDeath(int client)
{
	bool bFoundTele = false;
	int i = -1;
	int iOwner;
	
	if( IsClientInGame(client) && !IsFakeClient(client) )
	{
		while( (i = FindEntityByClassname(i, "obj_teleporter" )) != -1 )
		{
			if( IsValidEntity(i) )
			{
				if( GetEntProp( i, Prop_Send, "m_iTeamNum" ) == view_as<int>(TFTeam_Blue) )
				{				
					iOwner = GetEntPropEnt( i, Prop_Send, "m_hOwnerEntity" );
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
		else
		{
			EmitGSToRed("Announcer.MVM_An_Engineer_Bot_Is_Dead");
		}
	}
}