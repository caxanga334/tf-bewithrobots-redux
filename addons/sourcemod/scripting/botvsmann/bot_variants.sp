// pootis robots here

// remove items from the player
void StripItems( int client, bool RemoveWeapons = true )
{	
	if( !IsClientInGame(client) || IsFakeClient( client ) || !IsPlayerAlive( client ) )
		return;
		
	int iEntity;
	int iOwner;
	
	if(RemoveWeapons)
	{
		int iPrimary = TF2_GetPlayerLoadoutSlot(client, TF2LoadoutSlot_Primary, true);
		if(iPrimary != -1)
		{
			TF2_RemovePlayerWearable(client, iPrimary);
		}
		int iSecondary = TF2_GetPlayerLoadoutSlot(client, TF2LoadoutSlot_Secondary, true);
		if(iSecondary != -1)
		{
			TF2_RemovePlayerWearable(client, iSecondary);
		}
		
		TF2_RemoveAllWeapons(client);
	}
	
	TF2_RemoveAllWearables(client);
	TF2_RemoveAllTaunts(client);
	
	iEntity = -1;
	while( ( iEntity = FindEntityByClassname( iEntity, "tf_powerup_bottle" ) ) > MaxClients )
	{
		iOwner = GetEntPropEnt( iEntity, Prop_Send, "m_hOwnerEntity" );
		if( iOwner == client )
			AcceptEntityInput( iEntity, "Kill" );
	}
	iEntity = -1;
	while( ( iEntity = FindEntityByClassname( iEntity, "tf_usableitem" ) ) > MaxClients )
	{
		iOwner = GetEntPropEnt( iEntity, Prop_Send, "m_hOwnerEntity" );
		if( iOwner == client )
			AcceptEntityInput( iEntity, "Kill" );
	}
}

// use TF2Items for giving weapons
int SpawnWeapon(int client,char[] name,int index,int level,int qual,bool bWearable = false)
{
	Handle hWeapon = TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION|PRESERVE_ATTRIBUTES);
	TF2Items_SetClassname(hWeapon, name);
	TF2Items_SetItemIndex(hWeapon, index);
	TF2Items_SetLevel(hWeapon, level);
	TF2Items_SetQuality(hWeapon, qual);
	
	if (hWeapon==null)
		return -1;
		
	int entity = TF2Items_GiveNamedItem(client, hWeapon);
	CloseHandle(hWeapon);
	if( IsValidEdict( entity ) )
	{
		if( bWearable )
		{
			TF2_EquipPlayerWearable(client, entity);
		}
		else
			EquipPlayerWeapon( client, entity );
	}
	return entity;
}

void GiveNormalInventory(int client ,int botvariant)
{
	TFClassType TFClass = TF2_GetPlayerClass(client);
	int iWeapon;
	
	switch( TFClass )
	{
		case TFClass_Scout:
		{
			if(botvariant == 0) // standard scout
			{
				SpawnWeapon( client, "tf_weapon_scattergun", 13, 1, 6, false ); // client, classname, item index, level, quality, Is Wearable?
			}
			else if(botvariant == 1) // melee scout
			{
				SpawnWeapon( client, "tf_weapon_bat", 0, 1, 6, false );
			}
		}
		case TFClass_Soldier:
		{
			if(botvariant == 0) // standard soldier
			{
				SpawnWeapon( client, "tf_weapon_rocketlauncher", 18, 1, 6, false );
				SpawnWeapon( client, "tf_weapon_shovel", 6, 1, 6, false );
			}
			else if(botvariant == 1) // direct hit soldier
			{
				SpawnWeapon( client, "tf_weapon_rocketlauncher_directhit", 127, 1, 6, false );
				SpawnWeapon( client, "tf_weapon_shovel", 6, 1, 6, false );				
			}			
		}
		case TFClass_Pyro:
		{
			if(botvariant == 0)
			{
				
			}
			else if(botvariant == 1)
			{
				
			}			
		}
		case TFClass_DemoMan:
		{
			if(botvariant == 0)
			{
				
			}
			else if(botvariant == 1)
			{
				
			}			
		}
		case TFClass_Heavy:
		{
			if(botvariant == 0)
			{
				SpawnWeapon( client, "tf_weapon_minigun", 15, 1, 6, false );
			}
			else if(botvariant == 1)
			{
				iWeapon = SpawnWeapon( client, "tf_weapon_minigun", 15, 1, 6, false );
				TF2Attrib_SetByName(iWeapon, "damage bonus", 3.0);
			}			
		}
		case TFClass_Engineer:
		{
			if(botvariant == 0)
			{
				
			}
			else if(botvariant == 1)
			{
				
			}			
		}
		case TFClass_Medic:
		{
			if(botvariant == 0)
			{
				
			}
			else if(botvariant == 1)
			{
				
			}			
		}
		case TFClass_Sniper:
		{
			if(botvariant == 0)
			{
				
			}
			else if(botvariant == 1)
			{
				
			}
		}
		case TFClass_Spy:
		{
			if(botvariant == 0)
			{
				
			}
			else if(botvariant == 1)
			{
				
			}
		}
	}
}

// giant inventory
void GiveGiantInventory(int client ,int botvariant)
{
	
}

// returns the variant name
// TODO: set names
char GetVariantName(TFClassType TFClass, int botvariant)
{
	char strBotName[64]
	
	switch( TFClass )
	{
		case TFClass_Scout:
		{
			switch( botvariant )
			{
				case -1: strcopy( strBotName, sizeof(strBotName), "Your own Scout" );
				case 0: strcopy( strBotName, sizeof(strBotName), "Standard Scout" );
				case 1: strcopy( strBotName, sizeof(strBotName), "Batsaber Scout" );
				default: strcopy( strBotName, sizeof(strBotName), "Undefined" );
			}
		}
		case TFClass_Soldier:
		{
			switch( botvariant )
			{
				case -1: strcopy( strBotName, sizeof(strBotName), "Your own Soldier" );
				case 0: strcopy( strBotName, sizeof(strBotName), "Standard Soldier" );
				case 1: strcopy( strBotName, sizeof(strBotName), "Batsaber Scout" );
				default: strcopy( strBotName, sizeof(strBotName), "Undefined" );
			}			
		}
		case TFClass_Pyro:
		{
			switch( botvariant )
			{
				case -1: strcopy( strBotName, sizeof(strBotName), "Your own Pyro" );
				case 0: strcopy( strBotName, sizeof(strBotName), "Standard Pyro" );
				case 1: strcopy( strBotName, sizeof(strBotName), "Batsaber Scout" );
				default: strcopy( strBotName, sizeof(strBotName), "Undefined" );
			}		
		}
		case TFClass_DemoMan:
		{
			switch( botvariant )
			{
				case -1: strcopy( strBotName, sizeof(strBotName), "Your own Demoman" );
				case 0: strcopy( strBotName, sizeof(strBotName), "Standard Demoman" );
				case 1: strcopy( strBotName, sizeof(strBotName), "Batsaber Scout" );
				default: strcopy( strBotName, sizeof(strBotName), "Undefined" );
			}		
		}
		case TFClass_Heavy:
		{
			switch( botvariant )
			{
				case -1: strcopy( strBotName, sizeof(strBotName), "Your own Heavy" );
				case 0: strcopy( strBotName, sizeof(strBotName), "Standard Heavy" );
				case 1: strcopy( strBotName, sizeof(strBotName), "Batsaber Scout" );
				default: strcopy( strBotName, sizeof(strBotName), "Undefined" );
			}		
		}
		case TFClass_Engineer:
		{
			switch( botvariant )
			{
				case -1: strcopy( strBotName, sizeof(strBotName), "Your own Engineer" );
				case 0: strcopy( strBotName, sizeof(strBotName), "Standard Engineer" );
				case 1: strcopy( strBotName, sizeof(strBotName), "Batsaber Scout" );
				default: strcopy( strBotName, sizeof(strBotName), "Undefined" );
			}			
		}
		case TFClass_Medic:
		{
			switch( botvariant )
			{
				case -1: strcopy( strBotName, sizeof(strBotName), "Your own Medic" );
				case 0: strcopy( strBotName, sizeof(strBotName), "Standard Medic" );
				case 1: strcopy( strBotName, sizeof(strBotName), "Batsaber Scout" );
				default: strcopy( strBotName, sizeof(strBotName), "Undefined" );
			}			
		}
		case TFClass_Sniper:
		{
			switch( botvariant )
			{
				case -1: strcopy( strBotName, sizeof(strBotName), "Your own Sniper" );
				case 0: strcopy( strBotName, sizeof(strBotName), "Standard Sniper" );
				case 1: strcopy( strBotName, sizeof(strBotName), "Batsaber Scout" );
				default: strcopy( strBotName, sizeof(strBotName), "Undefined" );
			}
		}
		case TFClass_Spy:
		{
			switch( botvariant )
			{
				case -1: strcopy( strBotName, sizeof(strBotName), "Your own Spy" );
				case 0: strcopy( strBotName, sizeof(strBotName), "Standard Spy" );
				case 1: strcopy( strBotName, sizeof(strBotName), "Batsaber Scout" );
				default: strcopy( strBotName, sizeof(strBotName), "Undefined" );
			}
		}
	}
}