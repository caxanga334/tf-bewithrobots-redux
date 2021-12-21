// SDK calls, SDK hooks

stock void TF2_PlaySequence(int client, const char[] sequence)
{
	SDKCall(g_hSDKPlaySpecificSequence, client, sequence);
}

stock int GetWeaponMaxClip(int weapon)
{
	return SDKCall(g_hSDKGetMaxClip, weapon);
}

stock int GetWeaponClip(int weapon)
{
	return SDKCall(g_hSDKGetClip, weapon);
}

stock void SetWeaponClip(int weapon, int clip)
{
	int offset = FindSendPropInfo("CTFWeaponBase", "m_iClip1");
	SetEntData(weapon, offset, clip, 4, true);
}

// remove objects from the given player
stock void SDKTFPlayerRemoveObject(int client, int obj)
{
	SDKCall(g_hSDKRemoveObject, client, obj);
}

/**
 * Gets the entity world center
 *
 * @param ent		The entity to get the center from
 * @param origin	origin vector to store
 * @return     no return
 */
stock void GetEntityWorldCenter(int ent, float[] origin)
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
stock void TF2_SpeakConcept(int concept, int team, char[] modifiers)
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
stock void TF2_PushAllPlayers(float vPos[3], float range, float force, int team)
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