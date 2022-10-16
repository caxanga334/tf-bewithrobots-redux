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