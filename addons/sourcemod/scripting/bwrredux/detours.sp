// Dynamic detours

void SetupDetours(GameData gm, bool &sigfailure)
{
	// Used to allow humans to capture gates
	int iOffset = GameConfGetOffset(gm, "CFilterTFBotHasTag::PassesFilterImpl");	
	if(iOffset == -1) { LogError("Failed to get offset of CFilterTFBotHasTag::PassesFilterImpl"); sigfailure = true; }
	g_hCFilterTFBotHasTag = DHookCreate(iOffset, HookType_Entity, ReturnType_Bool, ThisPointer_CBaseEntity, CFilterTFBotHasTag);
	DHookAddParam(g_hCFilterTFBotHasTag, HookParamType_CBaseEntity);	//Entity index of the entity using the filter
	DHookAddParam(g_hCFilterTFBotHasTag, HookParamType_CBaseEntity);	//Entity index that triggered the filter
	
	iOffset = GameConfGetOffset(gm, "CTFPlayer::ShouldGib");
	if(iOffset == -1) { SetFailState("Failed to get offset of CTFPlayer::ShouldGib"); }
	g_hCTFPlayerShouldGib = DHookCreate(iOffset, HookType_Entity, ReturnType_Bool, ThisPointer_CBaseEntity, CTFPlayer_ShouldGib);
	DHookAddParam(g_hCTFPlayerShouldGib, HookParamType_ObjectPtr, -1, DHookPass_ByRef);
	
	/**iOffset = GameConfGetOffset(gm, "CTeam::GetNumPlayers");
	if(iOffset == -1) { SetFailState("Failed to get offset of CTeam::GetNumPlayers"); }
	g_hCTeamGetNumPlayers = DHookCreate(iOffset, HookType_Entity, ReturnType_Int, ThisPointer_CBaseEntity, CTeam_GetNumPlayers); **/
	
	//CTFBot::GetEventChangeAttributes
	g_hGetEventChangeAttributes = DHookCreateDetour(Address_Null, CallConv_THISCALL, ReturnType_Int, ThisPointer_CBaseEntity);
	if(!g_hGetEventChangeAttributes) { SetFailState("Failed to setup detour for CTFBot::GetEventChangeAttributes"); }
	
	if(!DHookSetFromConf(g_hGetEventChangeAttributes, gm, SDKConf_Signature, "CTFBot::GetEventChangeAttributes"))
	{
		LogError("Failed to load CTFBot::GetEventChangeAttributes signature from gamedata");
		sigfailure = true;
	}
	
	// HookParamType_Unknown
	DHookAddParam(g_hGetEventChangeAttributes, HookParamType_CharPtr);
	
	if(!DHookEnableDetour(g_hGetEventChangeAttributes, false, CTFBot_GetEventChangeAttributes)) { SetFailState("Failed to detour CTFBot::GetEventChangeAttributes."); }
	if(!DHookEnableDetour(g_hGetEventChangeAttributes, true, CTFBot_GetEventChangeAttributes_Post)) { SetFailState("Failed to detour CTFBot::GetEventChangeAttributes_Post."); }
	
	g_hCTFPLayerCanBeForcedToLaugh = DHookCreateDetour(Address_Null, CallConv_THISCALL, ReturnType_Bool, ThisPointer_CBaseEntity);
	if(!g_hCTFPLayerCanBeForcedToLaugh) { SetFailState("Failed to setup detour for CTFPlayer::CanBeForcedToLaugh"); }
	
	if(!DHookSetFromConf(g_hCTFPLayerCanBeForcedToLaugh, gm, SDKConf_Signature, "CTFPlayer::CanBeForcedToLaugh"))
	{
		LogError("Failed to load CTFPlayer::CanBeForcedToLaugh signature from gamedata");
		sigfailure = true;
	}
	
	if(!DHookEnableDetour(g_hCTFPLayerCanBeForcedToLaugh, false, CTFPLayer_CanBeForcedToLaugh)) { SetFailState("Failed to detour CTFPlayer::CanBeForcedToLaugh"); }
	if(!DHookEnableDetour(g_hCTFPLayerCanBeForcedToLaugh, true, CTFPLayer_CanBeForcedToLaugh_Post)) { SetFailState("Failed to detour CTFPlayer::CanBeForcedToLaugh_Post"); }    
}

// Crash fix for maps that use event change attributes. Returns NULL (0) for human clients
public MRESReturn CTFBot_GetEventChangeAttributes(int pThis, Handle hReturn, Handle hParams) 
{
	if(IsValidClient(pThis) && !IsFakeClient(pThis))
	{
		DHookSetReturn(hReturn, 0);
		return MRES_Supercede;
	}

	return MRES_Ignored; 
}

public MRESReturn CTFBot_GetEventChangeAttributes_Post(int pThis, Handle hReturn, Handle hParams)
{
	if(IsValidClient(pThis) && !IsFakeClient(pThis))
	{	
		DHookSetReturn(hReturn, 0);
		return MRES_Supercede;
	}
	
	return MRES_Ignored;
}

// Allow human robots to capture gates
public MRESReturn CFilterTFBotHasTag(int iFilter, Handle hReturn, Handle hParams)
{
	if(!IsPlayingMannVsMachine() || DHookIsNullParam(hParams, 2) || DHookIsNullParam(hParams, 1)) {
		return MRES_Ignored;
	}

	int entity = DHookGetParam(hParams, 1);
	int other  = DHookGetParam(hParams, 2);
	
	if(other <= 0 || other > MaxClients || !IsClientInGame(other)) {
		return MRES_Ignored;
	}
	
	//Don't care about real bots
	if(IsFakeClient(other)) {
		return MRES_Ignored;
	}
	
	if(!IsPlayerAlive(other))
	{
		DHookSetReturn(hReturn, false);
		return MRES_Supercede;
	}
	
	// Don't care if not from BLU team.
	if(GetClientTeam(other) != 3) {
		return MRES_Ignored;
	}
	
	// Don't allow taking gates if stun is active
	/**if(IsGateStunActive()) {
		return MRES_Ignored;
	} **/
		
	if(TF2_GetPlayerClass(other) == TFClass_Spy)
	{
		if(TF2_IsPlayerInCondition(other, TFCond_Disguised) || TF2_IsPlayerInCondition(other, TFCond_Cloaked) || TF2_IsPlayerInCondition(other, TFCond_Stealthed))
			return MRES_Ignored; // Don't allow disguised or cloaked spies to cap
	}

	bool bNegated = !!GetEntProp(iFilter, Prop_Data, "m_bNegated");
	RobotPlayer rp = RobotPlayer(other);
	bool bResult = rp.gatebot;
	if(bNegated)
		bResult = !bResult;
	
	char classname[64];
	GetEntityClassname(entity, classname, sizeof(classname));
	
	//We don't care about you
	if(strcmp(classname, "func_nav_prerequisite") == 0) {
		return MRES_Ignored;
	}
	
	//These work the opposite way
	if(strcmp(classname, "trigger_add_tf_player_condition") == 0) {
		bResult = !bResult;
	}
	
	DHookSetReturn(hReturn, bResult);
	return MRES_Supercede;
}

// Code from Pelipoika's Bot Control
public MRESReturn CTFPlayer_ShouldGib(int pThis, Handle hReturn, Handle hParams)
{
	if(!DHookIsNullParam(hParams, 1) && TF2_GetClientTeam(pThis) == TFTeam_Blue)
	{
		bool is_miniboss = view_as<bool>(GetEntProp(pThis, Prop_Send, "m_bIsMiniBoss"));
		float m_flModelScale = GetEntPropFloat(pThis, Prop_Send, "m_flModelScale");
		
		if(is_miniboss || m_flModelScale > 1.0)
		{
			DHookSetReturn(hReturn, true);
			return MRES_Supercede;
		}
		
		bool is_engie  = (TF2_GetPlayerClass(pThis) == TFClass_Engineer);
		bool is_medic  = (TF2_GetPlayerClass(pThis) == TFClass_Medic);
		bool is_sniper = (TF2_GetPlayerClass(pThis) == TFClass_Sniper);
		bool is_spy    = (TF2_GetPlayerClass(pThis) == TFClass_Spy);
		
		if (is_engie || is_medic || is_sniper || is_spy) {
			DHookSetReturn(hReturn, false);
			return MRES_Supercede;
		}
	}
	
	return MRES_Ignored;
}

// Prevent human BLU players from being forced to laugh
public MRESReturn CTFPLayer_CanBeForcedToLaugh(int pThis, Handle hReturn)
{
	if(TF2_GetClientTeam(pThis) == TFTeam_Blue && !IsFakeClient(pThis))
	{
		DHookSetReturn(hReturn, false);
		return MRES_Supercede;
	}
	
	return MRES_Ignored;
}

public MRESReturn CTFPLayer_CanBeForcedToLaugh_Post(int pThis, Handle hReturn)
{
	if(TF2_GetClientTeam(pThis) == TFTeam_Blue && !IsFakeClient(pThis))
	{
		DHookSetReturn(hReturn, false);
		return MRES_Supercede;
	}
	
	return MRES_Ignored;
}