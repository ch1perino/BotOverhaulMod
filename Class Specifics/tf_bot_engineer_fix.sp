#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#define PLUGIN_VERSION  "1.2"

public Plugin myinfo = 
{
	name = "Engineer Bot Fix",
	author = "EfeDursun125 / Tweaks by Showin",
	description = "Engineer bots now can upgrade teleporters and more fixes.",
	version = PLUGIN_VERSION,
	url = "https://steamcommunity.com/id/EfeDursun91/"
}

float moveForward(float vel[3],float MaxSpeed)
{
	vel[0] = MaxSpeed;
	return vel;
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

stock int Client_GetClosest(float vecOrigin_center[3], int client)
{
	float vecOrigin_edict[3];
	float distance = -1.0;
	int closestEdict = -1;
	for(int i=1;i<=MaxClients;i++)
	{
		if(!IsFakeClient(client))
		{
			if ((i == client))
				continue;
			GetEntPropVector(i, Prop_Data, "m_vecOrigin", vecOrigin_edict);
			GetClientEyePosition(i, vecOrigin_edict);
			if(IsPointVisibleTank(vecOrigin_center, vecOrigin_edict) && ClientViews(client, i))
			{
				float edict_distance = GetVectorDistance(vecOrigin_center, vecOrigin_edict);
				if((edict_distance < distance) || (distance == -1.0))
				{
					distance = edict_distance;
					closestEdict = i;
				}
			}
		}
	}
	return closestEdict;
}

stock bool ClientViews(int Viewer, int Target, float fMaxDistance=0.0, float fThreshold=0.70)
{
    // Retrieve view and target eyes position
    float fViewPos[3];   GetClientEyePosition(Viewer, fViewPos);
    float fViewAng[3];   GetClientEyeAngles(Viewer, fViewAng);
    float fViewDir[3];
    float fTargetPos[3]; GetClientEyePosition(Target, fTargetPos);
    float fTargetDir[3];
    float fDistance[3];
	
    // Calculate view direction
    fViewAng[0] = fViewAng[2] = 0.0;
    GetAngleVectors(fViewAng, fViewDir, NULL_VECTOR, NULL_VECTOR);
    
    // Calculate distance to viewer to see if it can be seen.
    fDistance[0] = fTargetPos[0]-fViewPos[0];
    fDistance[1] = fTargetPos[1]-fViewPos[1];
    fDistance[2] = 0.0;
    if (fMaxDistance != 0.0)
    {
        if (((fDistance[0]*fDistance[0])+(fDistance[1]*fDistance[1])) >= (fMaxDistance*fMaxDistance))
            return false;
    }
    
    // Check dot product. If it's negative, that means the viewer is facing
    // backwards to the target.
    NormalizeVector(fDistance, fTargetDir);
    if (GetVectorDotProduct(fViewDir, fTargetDir) < fThreshold) return false;
    
    // Now check if there are no obstacles in between through raycasting
    Handle hTrace = TR_TraceRayFilterEx(fViewPos, fTargetPos, MASK_PLAYERSOLID_BRUSHONLY, RayType_EndPoint, ClientViewsFilter);
    if (TR_DidHit(hTrace)) {CloseHandle(hTrace); return false;}
    CloseHandle(hTrace);
    
    // Done, it's visible
    return true;
}

public bool ClientViewsFilter(int Entity, int Mask, any Junk)
{
    if (Entity >= 1 && Entity <= MaxClients) return false;
    return true;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3]) // TO DO : Fix wranings
{
	if(IsValidClient(client))
	{
		if(IsFakeClient(client))
		{
			if(IsPlayerAlive(client))
			{
				TFClassType class = TF2_GetPlayerClass(client);
				if(class == TFClass_Engineer)
				{				
					int iSentry = TF2_GetObject(client, TFObject_Sentry, TFObjectMode_None);
					int iTeleporter = TF2_GetObject(client, TFObject_Teleporter, TFObjectMode_Exit);
					if(iTeleporter != INVALID_ENT_REFERENCE && IsValidEntity(iTeleporter) && iSentry != INVALID_ENT_REFERENCE && IsValidEntity(iSentry) && IsWeaponSlotActive(client, 2))
					{
						int iTeamNumObj = GetEntProp(iTeleporter, Prop_Send, "m_iTeamNum");
						if(GetClientTeam(client) == iTeamNumObj)
						{
							float clientOrigin[3];
							float teleporterOrigin[3];
							float sentryOrigin[3];
							GetClientAbsOrigin(client, clientOrigin);
							GetEntPropVector(iTeleporter, Prop_Send, "m_vecOrigin", teleporterOrigin);
							GetEntPropVector(iTeleporter, Prop_Send, "m_vecOrigin", sentryOrigin);
							
							float camangle[3];
							float clientEyes[3];
							float fEntityLocation[3];
							GetClientEyePosition(client, clientEyes);
							float vec[3];
							float angle[3];
							GetEntPropVector(iTeleporter, Prop_Send, "m_vecOrigin", fEntityLocation);
							GetEntPropVector(iTeleporter, Prop_Data, "m_angRotation", angle);
							fEntityLocation[2] += 10.0;
							MakeVectorFromPoints(fEntityLocation, clientEyes, vec);
							GetVectorAngles(vec, camangle);
							camangle[0] *= -1.0;
							camangle[1] += 180.0;
							ClampAngle(camangle);

							float chainDistance;
							chainDistance = GetVectorDistance(clientOrigin, teleporterOrigin);
							
							int iTeleporterLevel = GetEntProp(iTeleporter, Prop_Send, "m_iUpgradeLevel");
							int iTeleporterSapped = GetEntProp(iTeleporter, Prop_Send, "m_bHasSapper");
							int iTeleporterHealth = GetEntProp(iTeleporter, Prop_Send, "m_iHealth");
							int iTeleporterMaxHealth = GetEntProp(iTeleporter, Prop_Send, "m_iMaxHealth");
							
							int iSentrySapped = GetEntProp(iSentry, Prop_Send, "m_bHasSapper");
							int iSentryHealth = GetEntProp(iSentry, Prop_Send, "m_iHealth");
							int iSentryMaxHealth = GetEntProp(iSentry, Prop_Send, "m_iMaxHealth");
							
							if(iSentrySapped == 0 && iSentryHealth >= iSentryMaxHealth && iTeleporterLevel < 3 && GetHealth(client) >= 125.0 && GetMetal(client) > 130 && chainDistance < 300.0 || iSentrySapped == 0 && iSentryHealth >= iSentryMaxHealth && iTeleporterHealth <= (iTeleporterMaxHealth / 1.5) && chainDistance < 300.0 || iSentrySapped == 0 && iSentryHealth >= iSentryMaxHealth && iTeleporterSapped == 1 && chainDistance < 300.0)
							{			
								if(chainDistance > 100.0)
								{							
									TF2_LookAtBuilding(client, teleporterOrigin, 0.075);
									vel = moveForward(vel,320.0);
									buttons |= IN_DUCK;
									buttons |= IN_ATTACK;
								}
								else
								{
									TF2_LookAtBuilding(client, teleporterOrigin, 0.075);
									buttons |= IN_DUCK;
									buttons |= IN_ATTACK;
								}
							}
						}
					}

					// Always build teles
					int iResupply = GetNearestEntity(client, "info_player_teamspawn*"); 
					if(iResupply != INVALID_ENT_REFERENCE && IsValidEntity(iResupply))
					{							
						float clientOrigin[3];
						float iResupplyorigin[3];
						GetClientAbsOrigin(client, clientOrigin);
						GetEntPropVector(iResupply, Prop_Send, "m_vecOrigin", iResupplyorigin);
								
						//clientOrigin[2] += 5.0;
						//iResupplyorigin[2] += 5.0;
								
						float chainDistance;
						chainDistance = GetVectorDistance(clientOrigin, iResupplyorigin);
								
						if(chainDistance < 500.0)
						{
							FakeClientCommandThrottled(client, "build 1 0" );
							buttons |= IN_ATTACK;
						}
					}
				}
			}
		}
	}
	
	return Plugin_Continue;
}

stock void ClampAngle(float fAngles[3])
{
	while(fAngles[0] > 89.0)  fAngles[0]-=360.0;
	while(fAngles[0] < -89.0) fAngles[0]+=360.0;
	while(fAngles[1] > 180.0) fAngles[1]-=360.0;
	while(fAngles[1] <-180.0) fAngles[1]+=360.0;
}

stock int GetMetal(int client)
{
	return GetEntProp(client, Prop_Data, "m_iAmmo", 4, 3);
}

stock int GetHealth(int client)
{
	return GetEntProp(client, Prop_Send, "m_iHealth");
}

stock bool IsWeaponSlotActive(int iClient, int iSlot)
{
    return GetPlayerWeaponSlot(iClient, iSlot) == GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
}

stock bool IsPointVisibleTank(const float start[3], const float end[3])
{
	TR_TraceRayFilter(start, end, MASK_PLAYERSOLID, RayType_EndPoint, TraceEntityFilterStuffTank);
	return TR_GetFraction() >= 0.9;
}

public bool TraceEntityFilterStuffTank(int entity, int mask)
{
	int maxentities = GetMaxEntities();
	return entity > maxentities;
}

bool IsValidClient(int client) 
{
    if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) ) 
        return false; 
     
    return true; 
}

float g_flNextCommand[MAXPLAYERS + 1];
stock bool FakeClientCommandThrottled(int client, const char[] command)
{
	if(g_flNextCommand[client] > GetGameTime())
		return false;
	
	FakeClientCommand(client, command);
	
	g_flNextCommand[client] = GetGameTime() + 1.0;
	
	return true;
}

stock int TF2_GetObject(int client, TFObjectType type, TFObjectMode mode)
{
	int iObject = INVALID_ENT_REFERENCE;
	while ((iObject = FindEntityByClassname(iObject, "obj_*")) != -1)
	{
		TFObjectType iObjType = TF2_GetObjectType(iObject);
		TFObjectMode iObjMode = TF2_GetObjectMode(iObject);
		
		if(GetEntPropEnt(iObject, Prop_Send, "m_hBuilder") == client && iObjType == type && iObjMode == mode 
		&& !GetEntProp(iObject, Prop_Send, "m_bPlacing")
		&& !GetEntProp(iObject, Prop_Send, "m_bDisposableBuilding"))
		{			
			return iObject;
		}
	}
	
	return iObject;
}

stock void TF2_LookAtBuilding(int client, float flGoal[3], float flAimSpeed = 0.05) // Smooth Aim From Pelipoika
{
	float flPos[3];
	GetClientEyePosition(client, flPos);

	float flAng[3];
	GetClientEyeAngles(client, flAng);

	float FixBuildingAngle[3];
	FixBuildingAngle[1] += 180.0; // Fix For Aim Building's angle
    
	// get normalised direction from target to client
	float desired_dir[3];
	MakeVectorFromPoints(flPos, flGoal, desired_dir);
	GetVectorAngles(desired_dir, desired_dir);

	// ease the current direction to the target direction
	flAng[0] += AngleNormalize(desired_dir[0] - flAng[0]) * flAimSpeed;
	flAng[1] += AngleNormalize(desired_dir[1] - flAng[1]) + FixBuildingAngle[1] * flAimSpeed;
	
	TeleportEntity(client, NULL_VECTOR, flAng, NULL_VECTOR);
}

stock float fmodf(float number, float denom)
{
    return number - RoundToFloor(number / denom) * denom;
}

stock float AngleNormalize(float angle)
{
    angle = fmodf(angle, 360.0);
    if (angle > 89) 
    {
        angle -= 360;
    }
    if (angle < -89)
    {
        angle += 360;
    }
    
    return angle;
}