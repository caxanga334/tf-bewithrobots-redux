// pootis robots here

// defines
#define MAX_TEMPLATE_TYPE 2
#define MAX_ROBOTS_TEMPLATE 128
#define MAX_ROBOTS_WEAPONS 6
#define MAX_ROBOTS_ATTRIBUTES 64
#define CONST_ROBOT_CLASSES 10
#define MAXLEN_CONFIG_STRING 128

// Globals
char g_strConfigFile[PLATFORM_MAX_PATH];

// Big list of arrays
/**
* Prefixes
* g_BN - Bot Stock Normal
* g_BG - Bot Stock Giant
**/
// == STOCK NORMAL ROBOTS ==
char g_BNTemplateName[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES][MAXLEN_CONFIG_STRING];
char g_BNRobotAttribs[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES][MAXLEN_CONFIG_STRING];
char g_BNDescription[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES][MAXLEN_CONFIG_STRING];
int g_BNWeaponIndex[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES][MAX_ROBOTS_WEAPONS];
int g_BNBitsAttribs[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES];
int g_BNHealth[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES];
int g_BNType[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES];
float g_BNScale[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES];
float g_BNCooldown[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES];
char g_BNWeaponClass[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES][MAX_ROBOTS_WEAPONS][MAXLEN_CONFIG_STRING];
char g_BNCharAttrib[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES][MAX_ROBOTS_ATTRIBUTES][MAXLEN_CONFIG_STRING];
float g_BNCharAttribValue[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES][MAX_ROBOTS_ATTRIBUTES];
// Weapon 1
char g_BNWeap1Attrib[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES][MAX_ROBOTS_ATTRIBUTES][MAXLEN_CONFIG_STRING];
float g_BNWeap1AttribValue[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES][MAX_ROBOTS_ATTRIBUTES];
// Weapon 2
char g_BNWeap2Attrib[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES][MAX_ROBOTS_ATTRIBUTES][MAXLEN_CONFIG_STRING];
float g_BNWeap2AttribValue[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES][MAX_ROBOTS_ATTRIBUTES];
// Weapon 3
char g_BNWeap3Attrib[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES][MAX_ROBOTS_ATTRIBUTES][MAXLEN_CONFIG_STRING];
float g_BNWeap3AttribValue[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES][MAX_ROBOTS_ATTRIBUTES];
// Weapon 4
char g_BNWeap4Attrib[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES][MAX_ROBOTS_ATTRIBUTES][MAXLEN_CONFIG_STRING];
float g_BNWeap4AttribValue[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES][MAX_ROBOTS_ATTRIBUTES];
// Weapon 5
char g_BNWeap5Attrib[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES][MAX_ROBOTS_ATTRIBUTES][MAXLEN_CONFIG_STRING];
float g_BNWeap5AttribValue[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES][MAX_ROBOTS_ATTRIBUTES];
// Weapon 6
char g_BNWeap6Attrib[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES][MAX_ROBOTS_ATTRIBUTES][MAXLEN_CONFIG_STRING];
float g_BNWeap6AttribValue[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES][MAX_ROBOTS_ATTRIBUTES];
// == STOCK GIANT ROBOTS ==
char g_BGTemplateName[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES][MAXLEN_CONFIG_STRING];
char g_BGRobotAttribs[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES][MAXLEN_CONFIG_STRING];
char g_BGDescription[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES][MAXLEN_CONFIG_STRING];
int g_BGWeaponIndex[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES][MAX_ROBOTS_WEAPONS];
int g_BGBitsAttribs[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES];
int g_BGHealth[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES];
int g_BGType[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES];
float g_BGScale[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES];
float g_BGCooldown[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES];
char g_BGWeaponClass[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES][MAX_ROBOTS_WEAPONS][MAXLEN_CONFIG_STRING];
char g_BGCharAttrib[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES][MAX_ROBOTS_ATTRIBUTES][MAXLEN_CONFIG_STRING];
float g_BGCharAttribValue[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES][MAX_ROBOTS_ATTRIBUTES];
// Weapon 1
char g_BGWeap1Attrib[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES][MAX_ROBOTS_ATTRIBUTES][MAXLEN_CONFIG_STRING];
float g_BGWeap1AttribValue[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES][MAX_ROBOTS_ATTRIBUTES];
// Weapon 2
char g_BGWeap2Attrib[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES][MAX_ROBOTS_ATTRIBUTES][MAXLEN_CONFIG_STRING];
float g_BGWeap2AttribValue[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES][MAX_ROBOTS_ATTRIBUTES];
// Weapon 3
char g_BGWeap3Attrib[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES][MAX_ROBOTS_ATTRIBUTES][MAXLEN_CONFIG_STRING];
float g_BGWeap3AttribValue[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES][MAX_ROBOTS_ATTRIBUTES];
// Weapon 4
char g_BGWeap4Attrib[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES][MAX_ROBOTS_ATTRIBUTES][MAXLEN_CONFIG_STRING];
float g_BGWeap4AttribValue[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES][MAX_ROBOTS_ATTRIBUTES];
// Weapon 5
char g_BGWeap5Attrib[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES][MAX_ROBOTS_ATTRIBUTES][MAXLEN_CONFIG_STRING];
float g_BGWeap5AttribValue[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES][MAX_ROBOTS_ATTRIBUTES];
// Weapon 6
char g_BGWeap6Attrib[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES][MAX_ROBOTS_ATTRIBUTES][MAXLEN_CONFIG_STRING];
float g_BGWeap6AttribValue[MAX_ROBOTS_TEMPLATE][CONST_ROBOT_CLASSES][MAX_ROBOTS_ATTRIBUTES];

// enum structs for config files
enum struct eRobotsGlobal
{
	int numtemplates[CONST_ROBOT_CLASSES];
}
eRobotsGlobal g_nBotTemplate[MAX_TEMPLATE_TYPE];

enum
{
	TemplateType_Normal = 0,
	TemplateType_Giant = 1,
};

// remove items from the player
void StripItems( int client, bool RemoveWeapons = true )
{	
	if( !IsClientInGame(client) || IsFakeClient( client ) || !IsPlayerAlive( client ) )
		return;
		
	int iEntity;
	int iOwner;
	
	if(RemoveWeapons)
	{
		iEntity = -1;
		while( ( iEntity = FindEntityByClassname( iEntity, "tf_wearable_demoshield" ) ) > MaxClients )
		{
			iOwner = GetEntPropEnt( iEntity, Prop_Send, "m_hOwnerEntity" );
			if( iOwner == client )
			{
				TF2_RemoveWearable( client, iEntity );
				AcceptEntityInput( iEntity, "Kill" );
			}
		}
		
		iEntity = -1;
		while( ( iEntity = FindEntityByClassname( iEntity, "tf_wearable_razorback" ) ) > MaxClients )
		{
			iOwner = GetEntPropEnt( iEntity, Prop_Send, "m_hOwnerEntity" );
			if( iOwner == client )
			{
				TF2_RemoveWearable( client, iEntity );
				AcceptEntityInput( iEntity, "Kill" );
			}
		}
		
		TF2_RemoveAllWeapons(client);
		// bug: sappers and toolboxes aren't removed however this shouldn't be a problem.
	}
	
	if( !OR_IsHalloweenMission() ) // Allow players to have wearables on wave 666
	{
		iEntity = -1;
		while( ( iEntity = FindEntityByClassname( iEntity, "tf_wearable" ) ) > MaxClients )
		{
			iOwner = GetEntPropEnt( iEntity, Prop_Send, "m_hOwnerEntity" );
			if( iOwner == client )
			{
				TF2_RemoveWearable( client, iEntity );
				AcceptEntityInput( iEntity, "Kill" );
			}
		}
	}
	
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

// remove items from the player
void StripWeapons( int client )
{	
	if( !IsClientInGame(client) || IsFakeClient( client ) || !IsPlayerAlive( client ) )
		return;
		
	int iEntity;
	int iOwner;
	
	iEntity = -1;
	while( ( iEntity = FindEntityByClassname( iEntity, "tf_wearable_demoshield" ) ) > MaxClients )
	{
		iOwner = GetEntPropEnt( iEntity, Prop_Send, "m_hOwnerEntity" );
		if( iOwner == client )
		{
			TF2_RemoveWearable( client, iEntity );
			AcceptEntityInput( iEntity, "Kill" );
		}
	}
	
	iEntity = -1;
	while( ( iEntity = FindEntityByClassname( iEntity, "tf_wearable_razorback" ) ) > MaxClients )
	{
		iOwner = GetEntPropEnt( iEntity, Prop_Send, "m_hOwnerEntity" );
		if( iOwner == client )
		{
			TF2_RemoveWearable( client, iEntity );
			AcceptEntityInput( iEntity, "Kill" );
		}
	}
	
	TF2_RemoveAllWeapons(client);
	// bug: sappers and toolboxes aren't removed however this shouldn't be a problem.
}

bool IsWeaponWearable(char[] classname)
{
	char strWearables[3][] = {"tf_wearable_demoshield", "tf_wearable_razorback", "tf_wearable"};
	
	for(int i = 0;i < sizeof(strWearables);i++)
	{
		if(StrEqual(classname, strWearables[i], false))
			return true;
	}
	
	return false;
}

// Returns the class base health
int GetClassBaseHealth(TFClassType Class)
{
	switch( Class )
	{
		case TFClass_Scout: return 125;
		case TFClass_Sniper: return 125;
		case TFClass_Soldier: return 200;
		case TFClass_DemoMan: return 175;
		case TFClass_Heavy: return 300;
		case TFClass_Pyro: return 175;
		case TFClass_Engineer: return 125;
		case TFClass_Medic: return 150;
		case TFClass_Spy: return 125;
	}
	
	return 300;
}

// Health for own loadout giants
int GetOwnGiantHealth(TFClassType Class)
{
	switch( Class )
	{
		case TFClass_Scout: return 1200;
		case TFClass_Sniper: return 1200;
		case TFClass_Soldier: return 3800;
		case TFClass_DemoMan: return 3300;
		case TFClass_Heavy: return 5000;
		case TFClass_Pyro: return 3300;
		case TFClass_Engineer: return 1200;
		case TFClass_Medic: return 4500;
		case TFClass_Spy: return 1200;
	}
	
	return 300;
}

// use TF2Items for giving weapons
int SpawnWeapon(int client,char[] name,int index,int level,int qual,bool bWearable = false)
{
	if( IsFakeClient(client) )
		return -1;

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

// Give weapons to the player
// type: 0 - normal, 1 - giant
void RT_GiveInventory(int client, int type = 0, int templateindex)
{
	if( IsFakeClient(client) )
		return;

	TFClassType TFClass = TF2_GetPlayerClass(client);
	int iClass = view_as<int>(TFClass);
	int iWeapon;
	char buffer[255];
	
	TF2Attrib_RemoveAll(client);
	
	if(type == 0) // Normal
	{
		if(templateindex <= g_nBotTemplate[TemplateType_Normal].numtemplates[iClass]) // This is a stock robot
		{
			for(int i = 0;i < MAX_ROBOTS_ATTRIBUTES;i++)
			{
				if( StrEqual(g_BNCharAttrib[templateindex][iClass][i], "null", true) )
				{
					break;
				}
				
				strcopy(buffer, sizeof(buffer), g_BNCharAttrib[templateindex][iClass][i]);
				TF2Attrib_SetByName(client, buffer, g_BNCharAttribValue[templateindex][iClass][i]);
			}
			
			TF2Attrib_ClearCache(client);

			// Spawn Weapons
			for(int i = 0;i < MAX_ROBOTS_WEAPONS;i++)
			{
				switch( i )
				{
					case 0:
					{
						strcopy(buffer, sizeof(buffer), g_BNWeaponClass[templateindex][iClass][i]);
						if(!StrEqual(buffer, "null", false)) // check if a weapon exists
						{
							iWeapon = SpawnWeapon(client, buffer, g_BNWeaponIndex[templateindex][iClass][i], 1, 6, IsWeaponWearable(buffer));
							for(int y = 0;y < MAX_ROBOTS_ATTRIBUTES;y++)
							{
								if( StrEqual(g_BNWeap1Attrib[templateindex][iClass][y], "null", true ) )
								{
									break;
								}
								strcopy(buffer, sizeof(buffer), g_BNWeap1Attrib[templateindex][iClass][y]);
								TF2Attrib_SetByName(iWeapon, buffer, g_BNWeap1AttribValue[templateindex][iClass][y]);
							}
							TF2Attrib_ClearCache(iWeapon);
						}						
					}
					case 1:
					{
						strcopy(buffer, sizeof(buffer), g_BNWeaponClass[templateindex][iClass][i]);
						if(!StrEqual(buffer, "null", false)) // check if a weapon exists
						{
							iWeapon = SpawnWeapon(client, buffer, g_BNWeaponIndex[templateindex][iClass][i], 1, 6, IsWeaponWearable(buffer));
							for(int y = 0;y < MAX_ROBOTS_ATTRIBUTES;y++)
							{
								if( StrEqual(g_BNWeap2Attrib[templateindex][iClass][y], "null", true ) )
								{
									break;
								}
								strcopy(buffer, sizeof(buffer), g_BNWeap2Attrib[templateindex][iClass][y]);
								TF2Attrib_SetByName(iWeapon, buffer, g_BNWeap2AttribValue[templateindex][iClass][y]);
							}
							TF2Attrib_ClearCache(iWeapon);
						}						
					}
					case 2:
					{
						strcopy(buffer, sizeof(buffer), g_BNWeaponClass[templateindex][iClass][i]);
						if(!StrEqual(buffer, "null", false)) // check if a weapon exists
						{
							iWeapon = SpawnWeapon(client, buffer, g_BNWeaponIndex[templateindex][iClass][i], 1, 6, IsWeaponWearable(buffer));
							for(int y = 0;y < MAX_ROBOTS_ATTRIBUTES;y++)
							{
								if( StrEqual(g_BNWeap3Attrib[templateindex][iClass][y], "null", true ) )
								{
									break;
								}
								strcopy(buffer, sizeof(buffer), g_BNWeap3Attrib[templateindex][iClass][y]);
								TF2Attrib_SetByName(iWeapon, buffer, g_BNWeap3AttribValue[templateindex][iClass][y]);
							}
							TF2Attrib_ClearCache(iWeapon);
						}						
					}
					case 3:
					{
						strcopy(buffer, sizeof(buffer), g_BNWeaponClass[templateindex][iClass][i]);
						if(!StrEqual(buffer, "null", false)) // check if a weapon exists
						{
							iWeapon = SpawnWeapon(client, buffer, g_BNWeaponIndex[templateindex][iClass][i], 1, 6, IsWeaponWearable(buffer));
							for(int y = 0;y < MAX_ROBOTS_ATTRIBUTES;y++)
							{
								if( StrEqual(g_BNWeap4Attrib[templateindex][iClass][y], "null", true ) )
								{
									break;
								}
								strcopy(buffer, sizeof(buffer), g_BNWeap4Attrib[templateindex][iClass][y]);
								TF2Attrib_SetByName(iWeapon, buffer, g_BNWeap4AttribValue[templateindex][iClass][y]);
							}
							TF2Attrib_ClearCache(iWeapon);
						}						
					}
					case 4:
					{
						strcopy(buffer, sizeof(buffer), g_BNWeaponClass[templateindex][iClass][i]);
						if(!StrEqual(buffer, "null", false)) // check if a weapon exists
						{
							iWeapon = SpawnWeapon(client, buffer, g_BNWeaponIndex[templateindex][iClass][i], 1, 6, IsWeaponWearable(buffer));
							for(int y = 0;y < MAX_ROBOTS_ATTRIBUTES;y++)
							{
								if( StrEqual(g_BNWeap5Attrib[templateindex][iClass][y], "null", true ) )
								{
									break;
								}
								strcopy(buffer, sizeof(buffer), g_BNWeap5Attrib[templateindex][iClass][y]);
								TF2Attrib_SetByName(iWeapon, buffer, g_BNWeap5AttribValue[templateindex][iClass][y]);
							}
							TF2Attrib_ClearCache(iWeapon);
						}						
					}
					case 5:
					{
						strcopy(buffer, sizeof(buffer), g_BNWeaponClass[templateindex][iClass][i]);
						if(!StrEqual(buffer, "null", false)) // check if a weapon exists
						{
							iWeapon = SpawnWeapon(client, buffer, g_BNWeaponIndex[templateindex][iClass][i], 1, 6, IsWeaponWearable(buffer));
							for(int y = 0;y < MAX_ROBOTS_ATTRIBUTES;y++)
							{
								if( StrEqual(g_BNWeap6Attrib[templateindex][iClass][y], "null", true ) )
								{
									break;
								}
								strcopy(buffer, sizeof(buffer), g_BNWeap6Attrib[templateindex][iClass][y]);
								TF2Attrib_SetByName(iWeapon, buffer, g_BNWeap6AttribValue[templateindex][iClass][y]);
							}
							TF2Attrib_ClearCache(iWeapon);
						}						
					}
				}
			}
		}
	}
	else // Giants
	{
		if(templateindex <= g_nBotTemplate[TemplateType_Giant].numtemplates[iClass]) // This is a stock robot
		{	
			for(int i = 0;i < MAX_ROBOTS_ATTRIBUTES;i++)
			{
				if( StrEqual(g_BGCharAttrib[templateindex][iClass][i], "null", true) )
				{
					break;
				}
				
				strcopy(buffer, sizeof(buffer), g_BGCharAttrib[templateindex][iClass][i]);
				TF2Attrib_SetByName(client, buffer, g_BGCharAttribValue[templateindex][iClass][i]);
				LogMessage("Applying client attribute %s (value %f ) on %N", buffer, g_BGCharAttribValue[templateindex][iClass][i], client);
			}
			
			TF2Attrib_ClearCache(client);

			// Spawn Weapons
			for(int i = 0;i < MAX_ROBOTS_WEAPONS;i++)
			{
				switch( i )
				{
					case 0:
					{
						strcopy(buffer, sizeof(buffer), g_BGWeaponClass[templateindex][iClass][i]);
						if(!StrEqual(buffer, "null", false)) // check if a weapon exists
						{
							iWeapon = SpawnWeapon(client, buffer, g_BGWeaponIndex[templateindex][iClass][i], 1, 6, IsWeaponWearable(buffer));
							for(int y = 0;y < MAX_ROBOTS_ATTRIBUTES;y++)
							{
								if( StrEqual(g_BGWeap1Attrib[templateindex][iClass][y], "null", true ) )
								{
									LogMessage("Found null attribute at index %i for robot %s", y,g_BGTemplateName[templateindex][iClass]);
									break;
								}
								strcopy(buffer, sizeof(buffer), g_BGWeap1Attrib[templateindex][iClass][y]);
								TF2Attrib_SetByName(iWeapon, buffer, g_BGWeap1AttribValue[templateindex][iClass][y]);
							}
							TF2Attrib_ClearCache(iWeapon);
						}						
					}
					case 1:
					{
						strcopy(buffer, sizeof(buffer), g_BGWeaponClass[templateindex][iClass][i]);
						if(!StrEqual(buffer, "null", false)) // check if a weapon exists
						{
							iWeapon = SpawnWeapon(client, buffer, g_BGWeaponIndex[templateindex][iClass][i], 1, 6, IsWeaponWearable(buffer));
							for(int y = 0;y < MAX_ROBOTS_ATTRIBUTES;y++)
							{
								if( StrEqual(g_BGWeap2Attrib[templateindex][iClass][y], "null", true ) )
								{
									break;
								}
								strcopy(buffer, sizeof(buffer), g_BGWeap2Attrib[templateindex][iClass][y]);
								TF2Attrib_SetByName(iWeapon, buffer, g_BGWeap2AttribValue[templateindex][iClass][y]);
							}
							TF2Attrib_ClearCache(iWeapon);
						}						
					}
					case 2:
					{
						strcopy(buffer, sizeof(buffer), g_BGWeaponClass[templateindex][iClass][i]);
						if(!StrEqual(buffer, "null", false)) // check if a weapon exists
						{
							iWeapon = SpawnWeapon(client, buffer, g_BGWeaponIndex[templateindex][iClass][i], 1, 6, IsWeaponWearable(buffer));
							for(int y = 0;y < MAX_ROBOTS_ATTRIBUTES;y++)
							{
								if( StrEqual(g_BGWeap3Attrib[templateindex][iClass][y], "null", true ) )
								{
									break;
								}
								strcopy(buffer, sizeof(buffer), g_BGWeap3Attrib[templateindex][iClass][y]);
								TF2Attrib_SetByName(iWeapon, buffer, g_BGWeap3AttribValue[templateindex][iClass][y]);
							}
							TF2Attrib_ClearCache(iWeapon);
						}						
					}
					case 3:
					{
						strcopy(buffer, sizeof(buffer), g_BGWeaponClass[templateindex][iClass][i]);
						if(!StrEqual(buffer, "null", false)) // check if a weapon exists
						{
							iWeapon = SpawnWeapon(client, buffer, g_BGWeaponIndex[templateindex][iClass][i], 1, 6, IsWeaponWearable(buffer));
							for(int y = 0;y < MAX_ROBOTS_ATTRIBUTES;y++)
							{
								if( StrEqual(g_BGWeap4Attrib[templateindex][iClass][y], "null", true ) )
								{
									break;
								}
								strcopy(buffer, sizeof(buffer), g_BGWeap4Attrib[templateindex][iClass][y]);
								TF2Attrib_SetByName(iWeapon, buffer, g_BGWeap4AttribValue[templateindex][iClass][y]);
							}
							TF2Attrib_ClearCache(iWeapon);
						}						
					}
					case 4:
					{
						strcopy(buffer, sizeof(buffer), g_BGWeaponClass[templateindex][iClass][i]);
						if(!StrEqual(buffer, "null", false)) // check if a weapon exists
						{
							iWeapon = SpawnWeapon(client, buffer, g_BGWeaponIndex[templateindex][iClass][i], 1, 6, IsWeaponWearable(buffer));
							for(int y = 0;y < MAX_ROBOTS_ATTRIBUTES;y++)
							{
								if( StrEqual(g_BGWeap5Attrib[templateindex][iClass][y], "null", true ) )
								{
									break;
								}
								strcopy(buffer, sizeof(buffer), g_BGWeap5Attrib[templateindex][iClass][y]);
								TF2Attrib_SetByName(iWeapon, buffer, g_BGWeap5AttribValue[templateindex][iClass][y]);
							}
							TF2Attrib_ClearCache(iWeapon);
						}						
					}
					case 5:
					{
						strcopy(buffer, sizeof(buffer), g_BGWeaponClass[templateindex][iClass][i]);
						if(!StrEqual(buffer, "null", false)) // check if a weapon exists
						{
							iWeapon = SpawnWeapon(client, buffer, g_BGWeaponIndex[templateindex][iClass][i], 1, 6, IsWeaponWearable(buffer));
							for(int y = 0;y < MAX_ROBOTS_ATTRIBUTES;y++)
							{
								if( StrEqual(g_BGWeap6Attrib[templateindex][iClass][y], "null", true ) )
								{
									break;
								}
								strcopy(buffer, sizeof(buffer), g_BGWeap6Attrib[templateindex][iClass][y]);
								TF2Attrib_SetByName(iWeapon, buffer, g_BGWeap6AttribValue[templateindex][iClass][y]);
							}
							TF2Attrib_ClearCache(iWeapon);
						}						
					}
				}
			}
		}
	}
}

// Sets the robot health
void RT_SetHealth(int client, TFClassType TFClass, int templateindex, int type = 0)
{
	int iClass = view_as<int>(TFClass);
	int iHealth;
	float flHealth;
	
	if( templateindex < 0 )
	{
		switch( type )
		{
			case 0: // Normal
			{
				SetEntProp(client, Prop_Send, "m_iHealth", GetClassBaseHealth(TFClass));
				SetEntProp(client, Prop_Data, "m_iHealth", GetClassBaseHealth(TFClass));	
			}
			case 1: // Giant
			{
				SetEntProp(client, Prop_Send, "m_iHealth", GetOwnGiantHealth(TFClass));
				SetEntProp(client, Prop_Data, "m_iHealth", GetOwnGiantHealth(TFClass));					
			}
		}
		
		return; 
	}
	
	switch( type )
	{
		case 0: // Normal
		{
			if(g_BNHealth[templateindex][iClass] > 0)
			{
				iHealth = (g_BNHealth[templateindex][iClass] - GetClassBaseHealth(TFClass));
				flHealth = float(iHealth);
				TF2Attrib_SetByName(client, "hidden maxhealth non buffed", flHealth);
				TF2Attrib_ClearCache(client);
				SetEntProp(client, Prop_Send, "m_iHealth", g_BNHealth[templateindex][iClass]);
				SetEntProp(client, Prop_Data, "m_iHealth", g_BNHealth[templateindex][iClass]);
				if(IsDebugging()) { PrintToConsole(client, "Setting Robot Health: %i (%i)", g_BNHealth[templateindex][iClass], iHealth); }
			}
			else
			{
				SetEntProp(client, Prop_Send, "m_iHealth", GetClassBaseHealth(TFClass));
				SetEntProp(client, Prop_Data, "m_iHealth", GetClassBaseHealth(TFClass));					
			}
		}
		case 1: // Giant
		{
			if(g_BGHealth[templateindex][iClass] > 0)
			{
				iHealth = (g_BGHealth[templateindex][iClass] - GetClassBaseHealth(TFClass));
				flHealth = float(iHealth);
				TF2Attrib_SetByName(client, "hidden maxhealth non buffed", flHealth);
				TF2Attrib_ClearCache(client);
				SetEntProp(client, Prop_Send, "m_iHealth", g_BGHealth[templateindex][iClass]);
				SetEntProp(client, Prop_Data, "m_iHealth", g_BGHealth[templateindex][iClass]);
				if(IsDebugging()) { PrintToConsole(client, "Setting Robot Health: %i (%i)", g_BGHealth[templateindex][iClass], iHealth); }
			}
			else
			{
				SetEntProp(client, Prop_Send, "m_iHealth", GetClassBaseHealth(TFClass));
				SetEntProp(client, Prop_Data, "m_iHealth", GetClassBaseHealth(TFClass));					
			}
		}
	}	
}

// Returns the robot name
void RT_GetTemplateName(char[] tpltname, int size, TFClassType TFClass, int templateindex, int type = 0)
{
	char buffer[255];
	int iClass = view_as<int>(TFClass);
	
	if(templateindex < 0)
	{
		switch( TFClass )
		{
			case TFClass_Scout:
			{
				strcopy(buffer, sizeof(buffer), "Your Own Scout");
			}
			case TFClass_Soldier:
			{
				strcopy(buffer, sizeof(buffer), "Your Own Soldier");
			}
			case TFClass_Pyro:
			{
				strcopy(buffer, sizeof(buffer), "Your Own Pyro");
			}
			case TFClass_DemoMan:
			{
				strcopy(buffer, sizeof(buffer), "Your Own Demoman");
			}
			case TFClass_Heavy:
			{
				strcopy(buffer, sizeof(buffer), "Your Own Heavy");
			}
			case TFClass_Engineer:
			{
				strcopy(buffer, sizeof(buffer), "Your Own Engineer");
			}
			case TFClass_Medic:
			{
				strcopy(buffer, sizeof(buffer), "Your Own Medic");
			}
			case TFClass_Sniper:
			{
				strcopy(buffer, sizeof(buffer), "Your Own Sniper");
			}
			case TFClass_Spy:
			{
				strcopy(buffer, sizeof(buffer), "Your Own Spy");
			}
			default:
			{
				strcopy(buffer, sizeof(buffer), "Your Own Loadout");
			}
		}
		Format(tpltname, size, "%s", buffer);
		return;
	}
	
	switch( type )
	{
		case 0: // Normal
		{
			if(templateindex <= g_nBotTemplate[TemplateType_Normal].numtemplates[iClass]) // stock
			{
				strcopy(buffer, 255, g_BNTemplateName[templateindex][iClass]);
			}
		}
		case 1: // Giant
		{
			if(templateindex <= g_nBotTemplate[TemplateType_Giant].numtemplates[iClass]) // stock
			{
				strcopy(buffer, 255, g_BGTemplateName[templateindex][iClass]);
			}	
		}
		default:
		{
			LogError("RT_GetTemplateName received invalid type!");
		}
	}
	
	Format(tpltname, size, "%s", buffer);
	return;
}

// Returns the robot description
void RT_GetDescription(char[] desc, int size, TFClassType TFClass, int templateindex, int type = 0)
{
	char buffer[255];
	int iClass = view_as<int>(TFClass);
	
	if(templateindex < 0) { return; }
	
	switch( type )
	{
		case 0: // Normal
		{
			if(templateindex <= g_nBotTemplate[TemplateType_Normal].numtemplates[iClass]) // stock
			{
				strcopy(buffer, 255, g_BNDescription[templateindex][iClass]);
			}
		}
		case 1: // Giant
		{
			if(templateindex <= g_nBotTemplate[TemplateType_Giant].numtemplates[iClass]) // stock
			{
				strcopy(buffer, 255, g_BGDescription[templateindex][iClass]);
			}	
		}
	}
	
	Format(desc, size, "%s", buffer);
}

// Returns the robot attributes
int RT_GetAttributesBits(TFClassType TFClass, int templateindex, int type = 0)
{
	int iBits = 0;
	int iClass = view_as<int>(TFClass);
	
	switch( type )
	{
		case 0: // Normal
		{
			if(templateindex <= g_nBotTemplate[TemplateType_Normal].numtemplates[iClass]) // stock
			{
				iBits = g_BNBitsAttribs[templateindex][iClass];
			}
		}
		case 1: // Giant
		{
			if(templateindex <= g_nBotTemplate[TemplateType_Giant].numtemplates[iClass]) // stock
			{
				iBits = g_BGBitsAttribs[templateindex][iClass];
			}			
		}
	}
	
	return iBits;
}

// Returns the robot type
int RT_GetType(TFClassType TFClass, int templateindex, int type = 0)
{
	int iRobotType = 0;
	int iClass = view_as<int>(TFClass);
	
	switch( type )
	{
		case 0: // Normal
		{
			if(templateindex <= g_nBotTemplate[TemplateType_Normal].numtemplates[iClass]) // stock
			{
				iRobotType = g_BNType[templateindex][iClass];
			}
		}
		case 1: // Giant
		{
			if(templateindex <= g_nBotTemplate[TemplateType_Giant].numtemplates[iClass]) // stock
			{
				iRobotType = g_BGType[templateindex][iClass];
			}			
		}
	}
	
	return iRobotType;
}

// returns the robot scale
float RT_GetScale(TFClassType TFClass, int templateindex, int type = 0)
{
	if( templateindex < 0 ) { return 1.0; }
	
	int iClass = view_as<int>(TFClass);
	
	switch( type )
	{
		case 0: // Normal
		{
			if(templateindex <= g_nBotTemplate[TemplateType_Normal].numtemplates[iClass]) // stock
			{
				return g_BNScale[templateindex][iClass];
			}
		}
		case 1: // Giant
		{
			if(templateindex <= g_nBotTemplate[TemplateType_Giant].numtemplates[iClass]) // stock
			{
				return g_BGScale[templateindex][iClass];
			}			
		}
	}
	
	return 1.0;
}

// returns the robot cooldown for the sm_robotmenu command
float RT_GetCooldown(TFClassType TFClass, int templateindex, int type = 0)
{
	if( templateindex < 0 ) { return 30.0; } // fixed 30 seconds cooldown for own loadouts
	
	int iClass = view_as<int>(TFClass);
	
	switch( type )
	{
		case 0: // Normal
		{
			if(templateindex <= g_nBotTemplate[TemplateType_Normal].numtemplates[iClass]) // stock
			{
				return g_BNCooldown[templateindex][iClass];
			}
		}
		case 1: // Giant
		{
			if(templateindex <= g_nBotTemplate[TemplateType_Giant].numtemplates[iClass]) // stock
			{
				return g_BGCooldown[templateindex][iClass];
			}			
		}
	}
	
	return 1.0;
}

// add attributes to own variants
void SetOwnAttributes(int client , bool bGiant)
{
	if( IsFakeClient(client) )
		return;
		
	TF2Attrib_RemoveAll(client); // bug fix

	TFClassType TFClass = TF2_GetPlayerClass(client);
	int iWeapon;
	
	if( bGiant )
	{
		switch( TFClass )
		{
			case TFClass_Scout:
			{
				iWeapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
				TF2Attrib_SetByName(iWeapon, "hidden maxhealth non buffed", 1475.0);
				TF2Attrib_SetByName(iWeapon, "damage force reduction", 0.7);
				TF2Attrib_SetByName(iWeapon, "airblast vulnerability multiplier", 0.7);
				TF2Attrib_SetByName(iWeapon, "override footstep sound set", 5.0);
				return;
			}
			case TFClass_Soldier:
			{
				iWeapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
				TF2Attrib_SetByName(iWeapon, "hidden maxhealth non buffed", 3600.0);
				TF2Attrib_SetByName(iWeapon, "move speed bonus", 0.5);
				TF2Attrib_SetByName(iWeapon, "damage force reduction", 0.4);
				TF2Attrib_SetByName(iWeapon, "airblast vulnerability multiplier", 0.4);
				TF2Attrib_SetByName(iWeapon, "override footstep sound set", 3.0);
				return;
			}
			case TFClass_Pyro:
			{
				iWeapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
				TF2Attrib_SetByName(iWeapon, "hidden maxhealth non buffed", 2825.0);
				TF2Attrib_SetByName(iWeapon, "move speed bonus", 0.5);
				TF2Attrib_SetByName(iWeapon, "damage force reduction", 0.6);
				TF2Attrib_SetByName(iWeapon, "airblast vulnerability multiplier", 0.6);
				TF2Attrib_SetByName(iWeapon, "override footstep sound set", 6.0);
				return;
			}
			case TFClass_DemoMan:
			{
				iWeapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
				TF2Attrib_SetByName(iWeapon, "hidden maxhealth non buffed", 3125.0);
				TF2Attrib_SetByName(iWeapon, "move speed bonus", 0.5);
				TF2Attrib_SetByName(iWeapon, "damage force reduction", 0.5);
				TF2Attrib_SetByName(iWeapon, "airblast vulnerability multiplier", 0.5);
				TF2Attrib_SetByName(iWeapon, "override footstep sound set", 4.0);
				return;
			}
			case TFClass_Heavy:
			{
				iWeapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
				TF2Attrib_SetByName(iWeapon, "hidden maxhealth non buffed", 4700.0);
				TF2Attrib_SetByName(iWeapon, "move speed bonus", 0.5);
				TF2Attrib_SetByName(iWeapon, "damage force reduction", 0.3);
				TF2Attrib_SetByName(iWeapon, "airblast vulnerability multiplier", 0.3);
				TF2Attrib_SetByName(iWeapon, "override footstep sound set", 2.0);
				return;
			}
			case TFClass_Engineer:
			{
				iWeapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
				TF2Attrib_SetByName(iWeapon, "hidden maxhealth non buffed", 1775.0);
				TF2Attrib_SetByName(iWeapon, "move speed bonus", 0.5);
				TF2Attrib_SetByName(iWeapon, "damage force reduction", 0.4);
				TF2Attrib_SetByName(iWeapon, "airblast vulnerability multiplier", 0.4);
				TF2Attrib_SetByName(iWeapon, "override footstep sound set", 4.0);
				TF2Attrib_SetByName(iWeapon, "cannot pick up buildings", 1.0);
				return;
			}
			case TFClass_Medic:
			{
				iWeapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
				TF2Attrib_SetByName(iWeapon, "hidden maxhealth non buffed", 4350.0);
				TF2Attrib_SetByName(iWeapon, "move speed bonus", 0.5);
				TF2Attrib_SetByName(iWeapon, "damage force reduction", 0.6);
				TF2Attrib_SetByName(iWeapon, "airblast vulnerability multiplier", 0.6);
				return;
			}
			case TFClass_Sniper:
			{
				iWeapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
				TF2Attrib_SetByName(iWeapon, "hidden maxhealth non buffed", 1275.0);
				TF2Attrib_SetByName(iWeapon, "move speed bonus", 0.5);
				TF2Attrib_SetByName(iWeapon, "damage force reduction", 0.4);
				TF2Attrib_SetByName(iWeapon, "airblast vulnerability multiplier", 0.4);
				TF2Attrib_SetByName(iWeapon, "override footstep sound set", 4.0);
				return;
			}
			case TFClass_Spy:
			{
				iWeapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
				TF2Attrib_SetByName(iWeapon, "hidden maxhealth non buffed", 1175.0);
				TF2Attrib_SetByName(iWeapon, "move speed bonus", 0.5);
				TF2Attrib_SetByName(iWeapon, "damage force reduction", 0.4);
				TF2Attrib_SetByName(iWeapon, "airblast vulnerability multiplier", 0.4);
				TF2Attrib_SetByName(iWeapon, "override footstep sound set", 4.0);
				return;
			}
		}
	}
	else
	{
		switch( TFClass )
		{
/* 			case TFClass_Scout:
			{
			}
			case TFClass_Soldier:
			{
						
			}
			case TFClass_Pyro:
			{
			
			}
			case TFClass_DemoMan:
			{

			}
			case TFClass_Heavy:
			{
		
			} */
			case TFClass_Engineer:
			{
				iWeapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
				TF2Attrib_SetByName(iWeapon, "hidden maxhealth non buffed", 375.0);
				TF2Attrib_SetByName(iWeapon, "cannot pick up buildings", 1.0);
				return;
			}
/* 			case TFClass_Medic:
			{

			}
			case TFClass_Sniper:
			{

			} */
			case TFClass_Spy:
			{
				iWeapon = GetPlayerWeaponSlot(client, 4); // spy invis watch
				TF2Attrib_SetByName(iWeapon, "mult cloak meter regen rate", 4.0); // own spy doesn't have inf cloak
			}
		}
	}
}

void GiveBusterInventory(int client)
{
	if( IsFakeClient(client) )
		return;

	int iWeapon = -1;
	iWeapon = SpawnWeapon( client, "tf_weapon_stickbomb", 307, 1, 6, false );
	TF2Attrib_SetByName(iWeapon, "hidden maxhealth non buffed", 2325.0);
	TF2Attrib_SetByName(iWeapon, "move speed bonus", 1.34);
	TF2Attrib_SetByName(iWeapon, "damage force reduction", 0.5);
	TF2Attrib_SetByName(iWeapon, "airblast vulnerability multiplier", 0.5);
	TF2Attrib_SetByName(iWeapon, "override footstep sound set", 7.0);
	TF2Attrib_SetByName(iWeapon, "cannot be backstabbed", 1.0);
}

// ==== ROBOT TEMPLATE CONFIG FILES ====
/* void RT_InitArrays()
{

} */

void RT_ClearArrays()
{
	for(int i = 0;i < MAX_ROBOTS_TEMPLATE;i++)
	{
		for(int y = 1;y < CONST_ROBOT_CLASSES;y++)
		{
			for(int x = 0;x < MAX_ROBOTS_ATTRIBUTES;x++)
			{
				// Normal
				g_BNCharAttrib[i][y][x] = "null";
				g_BNCharAttribValue[i][y][x] = 0.0;
				g_BNWeap1Attrib[i][y][x] = "null";
				g_BNWeap1AttribValue[i][y][x] = 0.0;	
				g_BNWeap2Attrib[i][y][x] = "null";
				g_BNWeap2AttribValue[i][y][x] = 0.0;	
				g_BNWeap3Attrib[i][y][x] = "null";
				g_BNWeap3AttribValue[i][y][x] = 0.0;
				g_BNWeap4Attrib[i][y][x] = "null";
				g_BNWeap4AttribValue[i][y][x] = 0.0;
				g_BNWeap5Attrib[i][y][x] = "null";
				g_BNWeap5AttribValue[i][y][x] = 0.0;
				g_BNWeap6Attrib[i][y][x] = "null";
				g_BNWeap6AttribValue[i][y][x] = 0.0;
				// Giants
				g_BGCharAttrib[i][y][x] = "null";
				g_BGCharAttribValue[i][y][x] = 0.0;
				g_BGWeap1Attrib[i][y][x] = "null";
				g_BGWeap1AttribValue[i][y][x] = 0.0;	
				g_BGWeap2Attrib[i][y][x] = "null";
				g_BGWeap2AttribValue[i][y][x] = 0.0;	
				g_BGWeap3Attrib[i][y][x] = "null";
				g_BGWeap3AttribValue[i][y][x] = 0.0;
				g_BGWeap4Attrib[i][y][x] = "null";
				g_BGWeap4AttribValue[i][y][x] = 0.0;
				g_BGWeap5Attrib[i][y][x] = "null";
				g_BGWeap5AttribValue[i][y][x] = 0.0;
				g_BGWeap6Attrib[i][y][x] = "null";
				g_BGWeap6AttribValue[i][y][x] = 0.0;
			}
			
			for(int x = 0;x < MAX_ROBOTS_WEAPONS;x++)
			{
				// Normal
				g_BNWeaponClass[i][y][x] = "null";
				// Giant
				g_BGWeaponClass[i][y][x] = "null";
			}
		}
	}
	
	// Reset the number of robots template available
	for(int i = 0;i < MAX_TEMPLATE_TYPE;i++)
	{
		for(int y = 1;y < CONST_ROBOT_CLASSES;y++)
		{
			g_nBotTemplate[i].numtemplates[y] = 0;
		}
	}
}

// Parse data after reading the config files.
void RT_PostLoad()
{
	char strBits[12][MAXLEN_CONFIG_STRING];
	char strValidAttribs[8][MAXLEN_CONFIG_STRING] = {"alwayscrits", "fullcharge", "infinitecloak", "autodisguise", "alwaysminicrits", "teleporttohint", "nobomb", "noteleexit"};
	int AttribValue[8] = {1,2,4,8,16,32,64,128};
	int iNum, iBits;

	for(int i = 0;i < MAX_ROBOTS_TEMPLATE;i++)
	{
		for(int y = 1;y < CONST_ROBOT_CLASSES;y++)
		{
			if(strlen(g_BNRobotAttribs[i][y]) > 0)
			{
				iBits = 0;
				iNum = ExplodeString(g_BNRobotAttribs[i][y], ",", strBits, sizeof(strBits), sizeof(strBits[]));
				for(int x = 0;x < iNum;x++)
				{
					for(int z = 0;z < sizeof(strValidAttribs);z++)
					{
						if(StrEqual(strBits[x], strValidAttribs[z], false))
						{
							iBits += AttribValue[z];
							break;
						}
					}
				}
				g_BNBitsAttribs[i][y] = iBits;
			}
		}
	}
	
	for(int i = 0;i < MAX_ROBOTS_TEMPLATE;i++)
	{
		for(int y = 1;y < CONST_ROBOT_CLASSES;y++)
		{
			if(strlen(g_BGRobotAttribs[i][y]) > 0)
			{
				iBits = 0;
				iNum = ExplodeString(g_BGRobotAttribs[i][y], ",", strBits, sizeof(strBits), sizeof(strBits[]));
				for(int x = 0;x < iNum;x++)
				{
					for(int z = 0;z < sizeof(strValidAttribs);z++)
					{
						if(StrEqual(strBits[x], strValidAttribs[z], false))
						{
							iBits += AttribValue[z];
							break;
						}
					}
				}
				g_BGBitsAttribs[i][y] = iBits;
			}
		}
	}
}

// Stock Normal Robots
void RT_LoadCfgNormal()
{
	char filename[32];
	
	Format(filename, sizeof(filename), "%s", NormalBotsFile());

	BuildPath(Path_SM, g_strConfigFile, sizeof(g_strConfigFile), "configs/bwrr/");
	
	Format(g_strConfigFile, sizeof(g_strConfigFile), "%s%s", g_strConfigFile, filename);
	
	if(!FileExists(g_strConfigFile))
	{
		SetFailState("Failed to load config file %s", g_strConfigFile);
	}
	
	
	KeyValues kv = new KeyValues("RobotTemplate");
	kv.ImportFromFile(g_strConfigFile);
	int iCounter = 0;
	char strClassKey[10][] = {"unknownclass" ,"scout", "sniper", "soldier", "demoman", "medic", "heavy", "pyro", "spy", "engineer"}; // must be the same as TFClassType enum
	
	// Jump into the first subsection
	if (!kv.GotoFirstSubKey())
	{
		delete kv;
		return;
	}
	kv.GoBack();
	
    // Iterate over subsections at the same nesting level
	// iCounter is the robot ID/index
	// j is the Class ID. !!! J MUST match TFClassType
	char buffer[255];
	do
	{
		for(int j = 1;j < sizeof(strClassKey);j++)
		{
			kv.GetSectionName(buffer, sizeof(buffer));
			if(kv.JumpToKey(strClassKey[j]))
			{
				kv.GetSectionName(buffer, sizeof(buffer));
				if(kv.GotoFirstSubKey(true))
				{
					iCounter = 0;
					do
					{
						KvGetString(kv, "name", g_BNTemplateName[iCounter][j], MAXLEN_CONFIG_STRING);
						KvGetString(kv, "robotattributes", g_BNRobotAttribs[iCounter][j], MAXLEN_CONFIG_STRING);
						g_BNHealth[iCounter][j] = kv.GetNum("health", 0);
						g_BNType[iCounter][j] = kv.GetNum("type", 0);
						g_BNScale[iCounter][j] = kv.GetFloat("scale", 0.0);
						g_BNCooldown[iCounter][j] = kv.GetFloat("cooldown", 0.0);
						KvGetString(kv, "description", g_BNDescription[iCounter][j], MAXLEN_CONFIG_STRING);
						
						if(kv.JumpToKey("playerattributes"))
						{
							kv.GetSectionName(buffer, sizeof(buffer));
							if(kv.GotoFirstSubKey(false))
							{
								int x = 0;
								do
								{ // Store Player Attributes
									kv.GetSectionName(g_BNCharAttrib[iCounter][j][x], MAXLEN_CONFIG_STRING); // Get Attribute Name
									g_BNCharAttribValue[iCounter][j][x] = kv.GetFloat("");// Attribute Value
									x++;
								} while(kv.GotoNextKey(false));
								kv.GoBack();
							}
							kv.GoBack();
						}
						
						char strWeaponsKey[MAX_ROBOTS_WEAPONS][] = {"primaryweapon", "secondaryweapon", "meleeweapon", "pda1weapon", "pda2weapon", "pda3weapon"};
						
						int x;
						for(int i = 0;i < sizeof(strWeaponsKey);i++) // Read Weapons
						{
							x = 0;
							if(kv.JumpToKey(strWeaponsKey[i]))
							{
								//kv.GetString("classname", buffer, sizeof(buffer), "");
								kv.GetString("classname", g_BNWeaponClass[iCounter][j][i], MAXLEN_CONFIG_STRING, "null"); // Store Weapon Classname
								g_BNWeaponIndex[iCounter][j][i] = kv.GetNum("index"); // Store Weapon Definition Index
								
								if(kv.GotoFirstSubKey())
								{
									if(kv.GotoFirstSubKey(false)) // Read Weapon's Attributes
									{
										do
										{
											switch( i )
											{
												case 0:
												{
													kv.GetSectionName(g_BNWeap1Attrib[iCounter][j][x], MAXLEN_CONFIG_STRING); // Get Attribute Name
													g_BNWeap1AttribValue[iCounter][j][x] = kv.GetFloat("");// Attribute Value
													x++;
												}
												case 1:
												{
													kv.GetSectionName(g_BNWeap2Attrib[iCounter][j][x], MAXLEN_CONFIG_STRING); // Get Attribute Name
													g_BNWeap2AttribValue[iCounter][j][x] = kv.GetFloat("");// Attribute Value
													x++;
												}
												case 2:
												{
													kv.GetSectionName(g_BNWeap3Attrib[iCounter][j][x], MAXLEN_CONFIG_STRING); // Get Attribute Name
													g_BNWeap3AttribValue[iCounter][j][x] = kv.GetFloat("");// Attribute Value
													x++;
												}
												case 3:
												{
													kv.GetSectionName(g_BNWeap4Attrib[iCounter][j][x], MAXLEN_CONFIG_STRING); // Get Attribute Name
													g_BNWeap4AttribValue[iCounter][j][x] = kv.GetFloat("");// Attribute Value
													x++;
												}
												case 4:
												{
													kv.GetSectionName(g_BNWeap5Attrib[iCounter][j][x], MAXLEN_CONFIG_STRING); // Get Attribute Name
													g_BNWeap5AttribValue[iCounter][j][x] = kv.GetFloat("");// Attribute Value
													x++;
												}
												case 5:
												{
													kv.GetSectionName(g_BNWeap6Attrib[iCounter][j][x], MAXLEN_CONFIG_STRING); // Get Attribute Name
													g_BNWeap6AttribValue[iCounter][j][x] = kv.GetFloat("");// Attribute Value
													x++;
												}												
											}
										} while(kv.GotoNextKey(false));
										kv.GoBack();
									}
									kv.GoBack();
								}
								kv.GoBack();
							}
						}
						iCounter++;
					} while(kv.GotoNextKey());
					g_nBotTemplate[TemplateType_Normal].numtemplates[j] = iCounter;
					kv.GoBack();
				}
				kv.GoBack();
			}		
		}
	} while (kv.GotoNextKey());
	
	delete kv;
}

// Stock Giant Robots
void RT_LoadCfgGiant()
{
	char filename[32];
	
	Format(filename, sizeof(filename), "%s", GiantBotsFile());

	BuildPath(Path_SM, g_strConfigFile, sizeof(g_strConfigFile), "configs/bwrr/");
	
	Format(g_strConfigFile, sizeof(g_strConfigFile), "%s%s", g_strConfigFile, filename);
	
	if(!FileExists(g_strConfigFile))
	{
		SetFailState("Failed to load config file %s", g_strConfigFile);
	}
	
	
	KeyValues kv = new KeyValues("RobotTemplate");
	kv.ImportFromFile(g_strConfigFile);
	int iCounter = 0;
	char strClassKey[10][] = {"unknownclass" ,"scout", "sniper", "soldier", "demoman", "medic", "heavy", "pyro", "spy", "engineer"}; // must be the same as TFClassType enum
	
	// Jump into the first subsection
	if (!kv.GotoFirstSubKey())
	{
		delete kv;
		return;
	}
	kv.GoBack();
	
    // Iterate over subsections at the same nesting level
	// iCounter is the robot ID/index
	// j is the Class ID. !!! J MUST match TFClassType
	char buffer[255];
	do
	{
		for(int j = 1;j < sizeof(strClassKey);j++)
		{
			kv.GetSectionName(buffer, sizeof(buffer));
			if(kv.JumpToKey(strClassKey[j]))
			{
				kv.GetSectionName(buffer, sizeof(buffer));
				if(kv.GotoFirstSubKey(true))
				{
					iCounter = 0;
					do
					{
						KvGetString(kv, "name", g_BGTemplateName[iCounter][j], MAXLEN_CONFIG_STRING);
						KvGetString(kv, "robotattributes", g_BGRobotAttribs[iCounter][j], MAXLEN_CONFIG_STRING);
						g_BGHealth[iCounter][j] = kv.GetNum("health", 0);
						g_BGType[iCounter][j] = kv.GetNum("type", 0);
						g_BGScale[iCounter][j] = kv.GetFloat("scale", 0.0);
						g_BGCooldown[iCounter][j] = kv.GetFloat("cooldown", 0.0);
						KvGetString(kv, "description", g_BGDescription[iCounter][j], MAXLEN_CONFIG_STRING);
						
						if(kv.JumpToKey("playerattributes"))
						{
							kv.GetSectionName(buffer, sizeof(buffer));
							if(kv.GotoFirstSubKey(false))
							{
								int x = 0;
								do
								{ // Store Player Attributes
									kv.GetSectionName(g_BGCharAttrib[iCounter][j][x], MAXLEN_CONFIG_STRING); // Get Attribute Name
									g_BGCharAttribValue[iCounter][j][x] = kv.GetFloat("");// Attribute Value
									x++;
								} while(kv.GotoNextKey(false));
								kv.GoBack();
							}
							kv.GoBack();
						}
						
						char strWeaponsKey[MAX_ROBOTS_WEAPONS][] = {"primaryweapon", "secondaryweapon", "meleeweapon", "pda1weapon", "pda2weapon", "pda3weapon"};
						
						int x;
						for(int i = 0;i < sizeof(strWeaponsKey);i++) // Read Weapons
						{
							x = 0;
							if(kv.JumpToKey(strWeaponsKey[i]))
							{
								//kv.GetString("classname", buffer, sizeof(buffer), "");
								kv.GetString("classname", g_BGWeaponClass[iCounter][j][i], MAXLEN_CONFIG_STRING, "null"); // Store Weapon Classname
								g_BGWeaponIndex[iCounter][j][i] = kv.GetNum("index"); // Store Weapon Definition Index
								
								if(kv.GotoFirstSubKey())
								{
									if(kv.GotoFirstSubKey(false)) // Read Weapon's Attributes
									{
										do
										{
											switch( i )
											{
												case 0:
												{
													kv.GetSectionName(g_BGWeap1Attrib[iCounter][j][x], MAXLEN_CONFIG_STRING); // Get Attribute Name
													g_BGWeap1AttribValue[iCounter][j][x] = kv.GetFloat("");// Attribute Value
													x++;
												}
												case 1:
												{
													kv.GetSectionName(g_BGWeap2Attrib[iCounter][j][x], MAXLEN_CONFIG_STRING); // Get Attribute Name
													g_BGWeap2AttribValue[iCounter][j][x] = kv.GetFloat("");// Attribute Value
													x++;
												}
												case 2:
												{
													kv.GetSectionName(g_BGWeap3Attrib[iCounter][j][x], MAXLEN_CONFIG_STRING); // Get Attribute Name
													g_BGWeap3AttribValue[iCounter][j][x] = kv.GetFloat("");// Attribute Value
													x++;
												}
												case 3:
												{
													kv.GetSectionName(g_BGWeap4Attrib[iCounter][j][x], MAXLEN_CONFIG_STRING); // Get Attribute Name
													g_BGWeap4AttribValue[iCounter][j][x] = kv.GetFloat("");// Attribute Value
													x++;
												}
												case 4:
												{
													kv.GetSectionName(g_BGWeap5Attrib[iCounter][j][x], MAXLEN_CONFIG_STRING); // Get Attribute Name
													g_BGWeap5AttribValue[iCounter][j][x] = kv.GetFloat("");// Attribute Value
													x++;
												}
												case 5:
												{
													kv.GetSectionName(g_BGWeap6Attrib[iCounter][j][x], MAXLEN_CONFIG_STRING); // Get Attribute Name
													g_BGWeap6AttribValue[iCounter][j][x] = kv.GetFloat("");// Attribute Value
													x++;
												}												
											}
										} while(kv.GotoNextKey(false));
										kv.GoBack();
									}
									kv.GoBack();
								}
								kv.GoBack();
							}
						}
						iCounter++;
					} while(kv.GotoNextKey());
					g_nBotTemplate[TemplateType_Giant].numtemplates[j] = iCounter;
					kv.GoBack();
				}
				kv.GoBack();
			}		
		}
	} while (kv.GotoNextKey());
	
	delete kv;
}

// Support Functions
// returns the number of templates available for the given class
// Remember that the first 
int RT_NumTemplates(bool bGiant = false,TFClassType Class)
{
	if(bGiant)
	{
		switch( Class )
		{
			case TFClass_Scout: return g_nBotTemplate[TemplateType_Giant].numtemplates[view_as<int>(TFClass_Scout)];
			case TFClass_Sniper: return g_nBotTemplate[TemplateType_Giant].numtemplates[view_as<int>(TFClass_Sniper)];
			case TFClass_Soldier: return g_nBotTemplate[TemplateType_Giant].numtemplates[view_as<int>(TFClass_Soldier)];
			case TFClass_DemoMan: return g_nBotTemplate[TemplateType_Giant].numtemplates[view_as<int>(TFClass_DemoMan)];
			case TFClass_Heavy: return g_nBotTemplate[TemplateType_Giant].numtemplates[view_as<int>(TFClass_Heavy)];
			case TFClass_Pyro: return g_nBotTemplate[TemplateType_Giant].numtemplates[view_as<int>(TFClass_Pyro)];
			case TFClass_Engineer: return g_nBotTemplate[TemplateType_Giant].numtemplates[view_as<int>(TFClass_Engineer)];
			case TFClass_Medic: return g_nBotTemplate[TemplateType_Giant].numtemplates[view_as<int>(TFClass_Medic)];
			case TFClass_Spy: return g_nBotTemplate[TemplateType_Giant].numtemplates[view_as<int>(TFClass_Spy)];
		}
	}
	else
	{
		switch( Class )
		{
			case TFClass_Scout: return g_nBotTemplate[TemplateType_Normal].numtemplates[view_as<int>(TFClass_Scout)];
			case TFClass_Sniper: return g_nBotTemplate[TemplateType_Normal].numtemplates[view_as<int>(TFClass_Sniper)];
			case TFClass_Soldier: return g_nBotTemplate[TemplateType_Normal].numtemplates[view_as<int>(TFClass_Soldier)];
			case TFClass_DemoMan: return g_nBotTemplate[TemplateType_Normal].numtemplates[view_as<int>(TFClass_DemoMan)];
			case TFClass_Heavy: return g_nBotTemplate[TemplateType_Normal].numtemplates[view_as<int>(TFClass_Heavy)];
			case TFClass_Pyro: return g_nBotTemplate[TemplateType_Normal].numtemplates[view_as<int>(TFClass_Pyro)];
			case TFClass_Engineer: return g_nBotTemplate[TemplateType_Normal].numtemplates[view_as<int>(TFClass_Engineer)];
			case TFClass_Medic: return g_nBotTemplate[TemplateType_Normal].numtemplates[view_as<int>(TFClass_Medic)];
			case TFClass_Spy: return g_nBotTemplate[TemplateType_Normal].numtemplates[view_as<int>(TFClass_Spy)];
		}		
	}
	
	return 0;
}