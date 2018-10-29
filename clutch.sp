#pragma semicolon 1 

#define PLUGIN_AUTHOR "Franc1sco franug and hAlexrr" // credits to hAlexrr because i used this as base - https://forums.alliedmods.net/showthread.php?p=2621710#post2621710
#define PLUGIN_VERSION "1.0" 

#include <sourcemod> 
#include <sdktools> 
#include <cstrike> 

#pragma newdecls required 

ConVar sm_players_alive_clutch; 

int g_iOpponents; 
int g_iClutchFor; 

EngineVersion g_Game;

public Plugin myinfo =  
{ 
    name = "Player Clutched", 
    author = PLUGIN_AUTHOR, 
    description = "Gives an announcement when a player clutches the round", 
    version = PLUGIN_VERSION, 
    url = "https://github.com/Franc1sco/Clutch-Announce" 
}; 

public void OnPluginStart() 
{ 
	sm_players_alive_clutch = CreateConVar("sm_players_alive_clutch", "3", "The amount of players needed to be alive on the opposite team for it to be considered a clutch"); 
	
	HookEvent("round_end", Event_RoundEnd); 
	HookEvent("player_death", Event_Death); 
	
	g_Game = GetEngineVersion();
} 

public void OnMapStart() 
{
	// ballon effect only for csgo
	if (g_Game == Engine_CSGO)
	{
		//// Vortex - https://forums.alliedmods.net/showthread.php?t=299964 
		PrecacheSound("weapons/party_horn_01.wav"); // End 
	}
} 

// events when players could be decreased
public void OnClientDisconnect_Post(int client)
{
	CheckAlive();
}

public Action Event_Death(Event event, char[] name, bool dontBroadcast) 
{ 
	CheckAlive();
} 

public void CheckAlive()
{
	// if already in a clutch situation then dont continue
	if(g_iClutchFor > 0)
		return;
		
	// get alive cts and ts
	int g_iTeamCT, g_iTeamT; 
	for (int i = 1; i <= MaxClients; i++) 
	{ 
		if(IsClientInGame(i) && IsPlayerAlive(i)) 
		{ 
			if(GetClientTeam(i) == CS_TEAM_CT) 
				g_iTeamCT++; 
			else if(GetClientTeam(i) == CS_TEAM_T) 
				g_iTeamT++; 
		} 
	} 
	
	// if only 1 player alive in the then and enought players in the other team
	
	if(g_iTeamT == 1  && g_iTeamCT >= sm_players_alive_clutch.IntValue) 
	{ 
		g_iClutchFor = CS_TEAM_T; // get clutch team
		g_iOpponents = g_iTeamCT; // get oponnents number
	} 
	else if(g_iTeamCT == 1  && g_iTeamT >= sm_players_alive_clutch.IntValue) 
	{ 
		g_iClutchFor = CS_TEAM_CT;
		g_iOpponents = g_iTeamT; 
	} 
} 

public Action Event_RoundEnd(Event event, char[] name, bool dontBroadcast) 
{ 
	if(g_iClutchFor != 0 && g_iOpponents >= sm_players_alive_clutch.IntValue) 
	{
		// if team winner is equal to the clutch player
		if(GetEventInt(event, "winner") == g_iClutchFor)
		{
			// get the last player alive that is should be the protagonist
			int client = GetClutchPlayerIndex();
			if(client > 0)
			{
				// msg and ballon effect
        		PrintToChatAll(" [\x06CLUTCH\x01] Player %N has clutched a 1v%i", client, g_iOpponents); 
        		PrintCenterTextAll("Player %N has clutched a 1v%i", client, g_iOpponents); 
        		
        		// ballon effect only for csgo
        		if (g_Game == Engine_CSGO)
        			CreateParticle(client, "weapon_confetti_balloons", 5.0); 
        	}
		}
	}
	g_iClutchFor = 0;
	g_iOpponents = 0; 
} 

int GetClutchPlayerIndex()
{
	int index;
	
	for (int i = 1; i <= MaxClients; i++) 
	{ 
		if(IsClientInGame(i) && IsPlayerAlive(i)) 
		{ 
			if(GetClientTeam(i) == g_iClutchFor) 
				index = i;
		} 
	} 	
    
	return index;
}

// Vortex - https://forums.alliedmods.net/showthread.php?t=299964 
stock void CreateParticle(int ent, char[] particleType, float time) 
{ 
    int particle = CreateEntityByName("info_particle_system"); 
     
    char name[64]; 
     
    if (IsValidEdict(particle)) 
    { 
        float position[3]; 
        GetEntPropVector(ent, Prop_Send, "m_vecOrigin", position); 
        TeleportEntity(particle, position, NULL_VECTOR, NULL_VECTOR); 
        GetEntPropString(ent, Prop_Data, "m_iName", name, sizeof(name)); 
        DispatchKeyValue(particle, "targetname", "tf2particle"); 
        DispatchKeyValue(particle, "parentname", name); 
        DispatchKeyValue(particle, "effect_name", particleType); 
        DispatchSpawn(particle); 
        SetVariantString(name); 
        AcceptEntityInput(particle, "SetParent", particle, particle, 0); 
        ActivateEntity(particle); 
        AcceptEntityInput(particle, "start"); 
        CreateTimer(time, DeleteParticle, particle); 
    } 
    EmitSoundToAll("weapons/party_horn_01.wav");   
} 

public Action DeleteParticle(Handle timer, any particle) 
{ 
    if (IsValidEntity(particle)) 
    { 
        char classN[64]; 
        GetEdictClassname(particle, classN, sizeof(classN)); 
        if (StrEqual(classN, "info_particle_system", false)) 
        { 
            AcceptEntityInput(particle, "Kill");
        } 
    } 
}