#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <PathFollower>

bool g_bHealthIsLow[MAXPLAYERS+1];
bool g_bAmmoIsLow[MAXPLAYERS+1];
//float g_flFindNearestHealthTimer[MAXPLAYERS + 1];
//float g_flFindNearestAmmoTimer[MAXPLAYERS + 1];
float g_flNearestAmmoOrigin[MAXPLAYERS + 1][3];
//float g_flNearestHealthOrigin[MAXPLAYERS + 1][3];
float g_flGoal[MAXPLAYERS + 1][3];

// stuck monitoring
bool m_isStuck[MAXPLAYERS + 1];					// if true, we are stuck
float m_stuckTimer[MAXPLAYERS + 1];				// how long we've been stuck
float m_stuckPos[MAXPLAYERS + 1][3];			// where we got stuck
float m_moveRequestTimer[MAXPLAYERS + 1];

#define STUCK_RADIUS 200.0

public Plugin myinfo=
{
	name= "TEST",
	author= "Showin and EfeDursun125, Pelipoika",
	description= "PLR SUPPORT FOR BOTS.",
	version= "Something",
	url= "Shrek.com"
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3])
{
	if(IsValidClient(client))
	{
		if(IsFakeClient(client))
		{
			TFClassType class = TF2_GetPlayerClass(client);
			if(IsPlayerAlive(client) && class != TFClass_Engineer && class != TFClass_Spy && class != TFClass_Medic && class != TFClass_Sniper)
			{
				StuckMonitor(client);
				float clientEyes[3];
				float clientOrigin[3];
				GetClientEyePosition(client, clientEyes);
				GetClientAbsOrigin(client, clientOrigin);
				
				int MaxHealth = GetEntProp(client, Prop_Data, "m_iMaxHealth");
								
				//int ammopack = FindNearestAmmo(client);
				//int healthpack = FindNearestHealth(client);
				
				if(GetEntProp(client, Prop_Send, "m_bJumping"))
				{
					buttons |= IN_DUCK;
				}	
				
				if(TF2_GetNumHealers(client) == 0 && (GetHealth(client) < (MaxHealth / 1.5) || TF2_IsPlayerInCondition(client, TFCond_OnFire) || TF2_IsPlayerInCondition(client, TFCond_Bleeding)))
				{
					g_bHealthIsLow[client] = true;
				}
				else
				{
					g_bHealthIsLow[client] = false;
				}
				
				if(g_bAmmoIsLow[client] && !g_bHealthIsLow[client])
				{
					if (!(PF_Exists(client))) 
					{
						PF_Create(client, 48.0, 72.0, 1000.0, 0.6, MASK_PLAYERSOLID, 300.0, 1.0, 1.5);
					}
					
					PF_SetGoalVector(client, g_flNearestAmmoOrigin[client]);
					
					PF_StartPathing(client);
					
					PF_EnableCallback(client, PFCB_Approach, Approach);
					
					if(!IsPlayerAlive(client) || !PF_Exists(client))
						return Plugin_Continue;
					
					if(PF_Exists(client) && GetVectorDistance(clientOrigin, g_flNearestAmmoOrigin[client]) > 30.0)
					{
						TF2_MoveTo(client, g_flGoal[client], vel, angles);
					}
				}
				else if(g_bHealthIsLow[client])
				{
					if (!(PF_Exists(client))) 
					{
						PF_Create(client, 48.0, 72.0, 1000.0, 0.6, MASK_PLAYERSOLID, 300.0, 1.0, 1.5);
					}
					
					PF_SetGoalVector(client, g_flNearestAmmoOrigin[client]);
					
					PF_StartPathing(client);
					
					PF_EnableCallback(client, PFCB_Approach, Approach);
					
					if(!IsPlayerAlive(client) || !PF_Exists(client))
						return Plugin_Continue;
					
					if(PF_Exists(client) && GetVectorDistance(clientOrigin, g_flNearestAmmoOrigin[client]) > 30.0)
					{
						TF2_MoveTo(client, g_flGoal[client], vel, angles);
					}
				}
				else
				{
					int search = GetNearestEntity(client, "player"); 
					if(search != INVALID_ENT_REFERENCE && IsValidEntity(search) && IsPlayerAlive(search) && GetClientTeam(client) != GetClientTeam(search) && !TF2_IsPlayerInCondition(search, TFCond_Cloaked) && !TF2_IsPlayerInCondition(search, TFCond_Disguised))
					{		
						float searchOrigin[3];
						GetEntPropVector(search, Prop_Send, "m_vecOrigin", searchOrigin);
					
						if (!PF_Exists(client)) 
						{
							PF_Create(client, 48.0, 72.0, 1000.0, 0.6, MASK_PLAYERSOLID, 300.0, 1.0, 1.5);
							PF_EnableCallback(client, PFCB_Approach, Approach);
						}
					
						PF_SetGoalVector(client, searchOrigin);
					
						PF_StartPathing(client);
	
						TF2_MoveTo(client, g_flGoal[client], vel, angles);
						//PrintToChatAll("Moving");				
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

stock int TF2_GetNumHealers(int client)
{
    return GetEntProp(client, Prop_Send, "m_nNumHealers");
}

public bool TraceEntityFilterStuff(int entity, int mask)
{
	return entity > MaxClients;
}

bool IsValidClient(int client)
{
	if(!(1 <= client <= MaxClients) || !IsClientInGame(client))
	{
		return false;
	}
	return true;
}

public int GetNearestEntity(int client, char[] classname) // https://forums.alliedmods.net/showthread.php?t=318542
{
    int nearestEntity = -1;
    float clientVecOrigin[3], entityVecOrigin[3];
    
    //Get the distance between the first entity and client
    float distance, nearestDistance = -1.0;
    
    //Find all the entity and compare the distances
    int entity = -1;
    while ((entity = FindEntityByClassname(entity, classname)) != -1)
    {
        GetEntPropVector(entity, Prop_Data, "m_vecOrigin", entityVecOrigin);
        distance = GetVectorDistance(clientVecOrigin, entityVecOrigin);
        
        if (distance < nearestDistance || nearestDistance == -1.0)
        {
            nearestEntity = entity;
            nearestDistance = distance;
        }
    }
    
    return nearestEntity;
}

public int FindNearestAmmo(int client)
{
	char ClassName[32];
	float clientOrigin[3];
	float entityOrigin[3];
	float distance = -1.0;
	int nearestEntity = -1;
	for(int entity = 0; entity <= GetMaxEntities(); entity++)
	{
		if(IsValidEntity(entity))
		{
			GetEdictClassname(entity, ClassName, 32);
			
			if(!HasEntProp(entity, Prop_Send, "m_fEffects"))
				continue;
			
			if(GetEntProp(entity, Prop_Send, "m_fEffects") != 0)
				continue;
				
			if(StrContains(ClassName, "item_healthammokit", false) != -1 || StrContains(ClassName, "tf_ammo_pack", false) != -1 || StrContains(ClassName, "obj_dispenser", false) != -1 || StrContains(ClassName, "item_ammopack", false) != -1)
			{
				GetEntPropVector(entity, Prop_Data, "m_vecOrigin", entityOrigin);
				GetClientEyePosition(client, clientOrigin);
				
				float edict_distance = GetVectorDistance(clientOrigin, entityOrigin);
				if((edict_distance < distance) || (distance == -1.0))
				{
					distance = edict_distance;
					nearestEntity = entity;
				}
			}
		}
	}
	return nearestEntity;
}

public int FindNearestHealth(int client)
{
	char ClassName[32];
	float clientOrigin[3];
	float entityOrigin[3];
	float distance = -1.0;
	int nearestEntity = -1;
	for(int entity = 0; entity <= GetMaxEntities(); entity++)
	{
		if(IsValidEntity(entity))
		{
			GetEdictClassname(entity, ClassName, 32);
			
			if(!HasEntProp(entity, Prop_Send, "m_fEffects"))
				continue;
			
			if(GetEntProp(entity, Prop_Send, "m_fEffects") != 0)
				continue;
				
			if(StrContains(ClassName, "item_health", false) != -1 || StrContains(ClassName, "obj_dispenser", false) != -1 || StrContains(ClassName, "func_regen", false) != -1)
			{
				GetEntPropVector(entity, Prop_Data, "m_vecOrigin", entityOrigin);
				GetClientEyePosition(client, clientOrigin);
				
				float edict_distance = GetVectorDistance(clientOrigin, entityOrigin);
				if((edict_distance < distance) || (distance == -1.0))
				{
					distance = edict_distance;
					nearestEntity = entity;
				}
			}
		}
	}
	return nearestEntity;
}

stock int GetHealth(int client)
{
	return GetEntProp(client, Prop_Send, "m_iHealth");
}

stock void TF2_MoveTo(int client, float flGoal[3], float fVel[3], float fAng[3])
{
	float flPos[3];
	GetClientAbsOrigin(client, flPos);

	float newmove[3];
	SubtractVectors(flGoal, flPos, newmove);
    
	newmove[1] = -newmove[1];
    
	float sin = Sine(fAng[1] * FLOAT_PI / 180.0);
	float cos = Cosine(fAng[1] * FLOAT_PI / 180.0);                        
    
	fVel[0] = cos * newmove[0] - sin * newmove[1];
	fVel[1] = sin * newmove[0] + cos * newmove[1];
    
	NormalizeVector(fVel, fVel);
	ScaleVector(fVel, 450.0);
}

public void Approach(int bot_entidx, const float dst[3])
{
    g_flGoal[bot_entidx][0] = dst[0];
    g_flGoal[bot_entidx][1] = dst[1];
    g_flGoal[bot_entidx][2] = dst[2];
}

//Stuck check
stock void StuckMonitor(int client)
{
	// a timer is needed to smooth over a few frames of inactivity due to state changes, etc.
	// we only want to detect idle situations when the bot really doesn't "want" to move.
	const float idleTime = 0.25;
	if ( (GetGameTime() - m_moveRequestTimer[client]) > idleTime )
	{
		// we have no desire to move, and therefore cannot emit stuck events
		// prepare our internal state for when the bot starts to move next
		m_stuckPos[client] = GetAbsOrigin(client);
		m_stuckTimer[client] = GetGameTime();

		return;
	}
	
	if ( IsStuck(client) )
	{
		// we are/were stuck - have we moved enough to consider ourselves "dislodged"
		if ( GetVectorDistance(GetAbsOrigin(client), m_stuckPos[client]) > STUCK_RADIUS )
		{
			// we've just become un-stuck
			ClearStuckStatus(client, "UN-STUCK" );
		}
	}
	else
	{
		// we're not stuck - yet
		if ( GetVectorDistance(GetAbsOrigin(client), m_stuckPos[client]) > STUCK_RADIUS )
		{
			// we have moved - reset anchor
			m_stuckPos[client] = GetAbsOrigin(client);
			m_stuckTimer[client] = GetGameTime();
		}
		else
		{
			const float flDesiredSpeed = 300.0;
		
			// within stuck range of anchor. if we've been here too long, we're stuck
			float minMoveSpeed = 0.1 * flDesiredSpeed + 0.1;
			float escapeTime = STUCK_RADIUS / minMoveSpeed;
			
			if ( (GetGameTime() - m_stuckTimer[client]) > escapeTime )
			{
				// we have taken too long - we're stuck
				m_isStuck[client] = true;
				
				PrintToServer("StuckMonitor STUCK");
			}
		}
	}
}

//Reset stuck status to un-stuck
stock void ClearStuckStatus( int client, const char[] reason )
{
	if ( IsStuck(client) )
	{
		m_isStuck[client] = false;
	}

	// always reset stuck monitoring data in case we cleared preemptively are were not yet stuck
	m_stuckPos[client] = GetAbsOrigin(client);
	m_stuckTimer[client] = GetGameTime();
	
	//PrintToServer("ClearStuckStatus \"%s\"", reason);
}

stock bool IsStuck( int client )
{
	return m_isStuck[client];
}

stock float GetStuckDuration( int client )
{
	return IsStuck(client) ? (GetGameTime() - m_stuckTimer[client]) : 0.0;
}

stock float[] GetAbsOrigin(int client)
{
	if(client <= 0)
		return NULL_VECTOR;

	float v[3];
	GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", v);
	return v;
}
