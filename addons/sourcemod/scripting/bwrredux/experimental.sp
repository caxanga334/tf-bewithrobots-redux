/*
 * Experimental 32 Players support.
 */

void RemoveAllMvMBots()
{
    for(int client = 1; client <= MaxClients; client++)
    {
        if (!IsClientInGame(client))
            continue;

        if (IsClientSourceTV(client)) // Don't kick STV bot
            continue;

        if (IsClientReplay(client)) // Don't kick replay bot
            continue;

        if (TF2_GetClientTeam(client) != TFTeam_Red && IsFakeClient(client)) // Kick all but red bots
        {
            KickClient(client, "[BWRR-32] Removing MvM bot!");
        }
    }
}

Action Timer_RemoveMvMBots(Handle timer)
{
    RemoveAllMvMBots();
    return Plugin_Stop;
}

Action Timer_PauseBotSpawning(Handle timer)
{
    int populator = FindEntityByClassname(-1, "point_populator_interface");

    if (populator != -1)
    {
        AcceptEntityInput(populator, "PauseBotSpawning");
        LogMessage("[BWRR-32] Pausing bot spawning!");
        
    }
    else
    {
        LogMessage("\"point_populator_interface\" entity not found, creating one!");
        CreatePopulatorInterface();
    }

    CreateTimer(1.0, Timer_RemoveMvMBots, .flags = TIMER_FLAG_NO_MAPCHANGE);

    return Plugin_Stop;
}

void CreatePopulatorInterface()
{
    int populator = CreateEntityByName("point_populator_interface");
    float origin[3];

    if (populator == -1) { LogError("Failed to create \"point_populator_interface\" entity!"); return; }

    origin = TF2_GetBombHatchPosition();
    TeleportEntity(populator, origin);
    DispatchSpawn(populator);
    ActivateEntity(populator);
    AcceptEntityInput(populator, "PauseBotSpawning");
    return;
}