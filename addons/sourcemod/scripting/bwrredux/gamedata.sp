// Gamedata handling

Handle g_hSDKPlaySpecificSequence;
Handle g_hGetEventChangeAttributes;
Handle g_hSDKWorldSpaceCenter;
Handle g_hCFilterTFBotHasTag;
Handle g_hSDKRemoveObject;
Handle g_hSDKPickupFlag;
Handle g_hCTFPlayerShouldGib;
Handle g_hSDKSpeakConcept;
Handle g_hCTFPLayerCanBeForcedToLaugh;
Handle g_hSDKPushAwayPlayers;
Handle g_hSDKDropCurrency;
Handle g_hSDKSetBuilder;

void SetupGamedata()
{
	GameData gm = new GameData("bwrr.games");
	bool sigfailure;
	
	// bool CTFPlayer::PlaySpecificSequence( const char *pAnimationName )
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gm, SDKConf_Signature, "CTFPlayer::PlaySpecificSequence");
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);		//Sequence name
	if((g_hSDKPlaySpecificSequence = EndPrepSDKCall()) == null) { LogError("Failed to create SDKCall for CTFPlayer::PlaySpecificSequence signature!"); sigfailure = true; }
	
	//This call is used to remove an objects owner
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gm, SDKConf_Signature, "CTFPlayer::RemoveObject");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);	//CBaseObject
	if((g_hSDKRemoveObject = EndPrepSDKCall()) == null) { LogError("Failed To create SDKCall for CTFPlayer::RemoveObject signature!"); sigfailure = true; }
	
	// Used to get an entity center
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(gm, SDKConf_Virtual, "CBaseEntity::WorldSpaceCenter");
	PrepSDKCall_SetReturnInfo(SDKType_Vector, SDKPass_ByRef);
	if((g_hSDKWorldSpaceCenter = EndPrepSDKCall()) == null) { LogError("Failed to create SDKCall for CBaseEntity::WorldSpaceCenter offset!"); sigfailure = true; }
	
	// Make players speak concept
	StartPrepSDKCall(SDKCall_GameRules);
	PrepSDKCall_SetFromConf(gm, SDKConf_Signature, "CMultiplayRules::HaveAllPlayersSpeakConceptIfAllowed");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain); // int iConcept
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain); // int iTeam
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer); // const char *modifiers
	if((g_hSDKSpeakConcept = EndPrepSDKCall()) == null) { LogError("Failed to create SDKCall for CMultiplayRules::HaveAllPlayersSpeakConceptIfAllowed signature!"); sigfailure = true; }
	
	// Push players away
	StartPrepSDKCall(SDKCall_GameRules);
	PrepSDKCall_SetFromConf(gm, SDKConf_Signature, "CTFGameRules::PushAllPlayersAway");
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_Plain); // Vector& vFromThisPoint
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain); // float flRange
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain); // float flForce
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain); // int nTeam
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_ByValue); // CUtlVector< CTFPlayer* > *pPushedPlayers
	if((g_hSDKPushAwayPlayers = EndPrepSDKCall()) == null) { LogError("Failed to create SDKCall for CTFGameRules::PushAllPlayersAway signature!"); sigfailure = true; }
	
	// Drop currency
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gm, SDKConf_Signature, "CTFPlayer::DropCurrencyPack");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_ByValue); // CurrencyRewards_t nSize
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain); // int nAmount
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain); // bool bForceDistribute
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer); // CBasePlayer* pMoneyMaker
	if((g_hSDKDropCurrency = EndPrepSDKCall()) == null) { LogError("Failed to create SDKCall for CTFPlayer::DropCurrencyPack signature!"); sigfailure = true; }
	
	//This call forces a player to pickup the intel
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(gm, SDKConf_Virtual, "CCaptureFlag::PickUp");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);	//CCaptureFlag
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);			//silent pickup? or maybe it doesnt exist im not sure.
	if((g_hSDKPickupFlag = EndPrepSDKCall()) == null) { LogError("Failed to create SDKCall for CCaptureFlag::PickUp offset!"); sigfailure = true; }

	// Set builder
	// void CBaseObject::SetBuilder( CTFPlayer *pBuilder )
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(gm, SDKConf_Virtual, "CBaseObject::SetBuilder");
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer, VDECODE_FLAG_ALLOWNULL | VDECODE_FLAG_ALLOWNOTINGAME);
	if((g_hSDKSetBuilder = EndPrepSDKCall()) == null) { LogStackTrace("Failed to create SDKCall for CBaseObject::SetBuilder offset!"); sigfailure = true; }

	SetupDetours(gm, sigfailure);

	delete gm;
	
	if(sigfailure) { SetFailState("One or more signatures failed!"); }
}