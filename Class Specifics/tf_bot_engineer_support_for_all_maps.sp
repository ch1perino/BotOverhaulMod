#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <tf2_flag>
#include <PathFollower>

#define PLUGIN_VERSION  "1.2"

#pragma newdecls required

bool g_bSentryBuilded[MAXPLAYERS+1];
bool g_bSentryIsMaxLevel[MAXPLAYERS+1];
bool g_bSentryHealthIsFull[MAXPLAYERS+1];
bool g_bCanBuildSentryGun[MAXPLAYERS+1];
bool g_bDispenserBuilded[MAXPLAYERS+1];
bool g_bDispenserIsMaxLevel[MAXPLAYERS+1];
bool g_bDispenserHealthIsFull[MAXPLAYERS+1];
bool g_bCanBuildDispenser[MAXPLAYERS+1];

bool g_bIdleTime[MAXPLAYERS+1];
//bool g_AttackPlayers[MAXPLAYERS+1];

bool g_bRepairSentry[MAXPLAYERS+1];
bool g_bRepairDispenser[MAXPLAYERS+1];

bool g_bBuildSentry[MAXPLAYERS+1];
bool g_bBuildDispenser[MAXPLAYERS+1];

bool g_bHealthIsLow[MAXPLAYERS+1];
bool g_bAmmoIsLow[MAXPLAYERS+1];

float g_flWaitJumpTimer[MAXPLAYERS + 1];
//float g_flChangeWeaponTimer[MAXPLAYERS + 1];

float g_flFindNearestHealthTimer[MAXPLAYERS + 1];
float g_flFindNearestAmmoTimer[MAXPLAYERS + 1];

float g_flNearestAmmoOrigin[MAXPLAYERS + 1][3];
float g_flNearestHealthOrigin[MAXPLAYERS + 1][3];

float g_flRedFlagCapPoint[3];
float g_flBluFlagCapPoint[3];

float g_flEngineerPickNewSpotTimer[MAXPLAYERS + 1];

bool g_bPickUnUsedSentrySpot[MAXPLAYERS + 1];

float g_flSentryBuildPos[MAXPLAYERS + 1][3];
float g_flSentryBuildAngle[MAXPLAYERS + 1][3];

public Plugin myinfo = 
{
	name = "[TF2] TFBot engineer support for all maps",
	author = "EfeDursun125 / Edits By Showin",
	description = "Engineer bots now can play on all maps (and can work with other bots).",
	version = PLUGIN_VERSION,
	url = "https://steamcommunity.com/id/EfeDursun91/"
};

float g_flGoal[MAXPLAYERS + 1][3];

public void OnPluginStart()
{
	HookEvent("player_spawn", BotSpawn, EventHookMode_Post);
}

public void OnMapStart()
{
	char currentMap[PLATFORM_MAX_PATH];
	GetCurrentMap(currentMap, sizeof(currentMap));
	
	if(StrContains(currentMap, "ctf_" , false) != -1)
	{
		int tmflag;
		while((tmflag = FindEntityByClassname(tmflag, "item_teamflag")) != INVALID_ENT_REFERENCE)
		{
			int iTeamNumObj = GetEntProp(tmflag, Prop_Send, "m_iTeamNum");
			if(IsValidEntity(tmflag))
			{
				if(iTeamNumObj == 2)
				{
					GetEntPropVector(tmflag, Prop_Send, "m_vecOrigin", g_flRedFlagCapPoint);
				}
				if(iTeamNumObj == 3)
				{
					GetEntPropVector(tmflag, Prop_Send, "m_vecOrigin", g_flBluFlagCapPoint);
				}
			}
		}
	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3])
{
	if(IsValidClient(client))
	{
		if(IsFakeClient(client))
		{
			char currentMap[PLATFORM_MAX_PATH];
			GetCurrentMap(currentMap, sizeof(currentMap));
			TFClassType class = TF2_GetPlayerClass(client);
			if(IsPlayerAlive(client) && class == TFClass_Engineer && (StrContains(currentMap, "ctf_" , false) != -1 || StrContains(currentMap, "sd_" , false) != -1 || StrContains(currentMap, "pd_" , false) != -1 || StrContains(currentMap, "rd_" , false) != -1 || StrContains(currentMap, "plr_" , false) != -1 || StrContains(currentMap, "pass_" , false) != -1))
			{
				float clientEyes[3];
				float clientOrigin[3];
				GetClientEyePosition(client, clientEyes);
				GetClientAbsOrigin(client, clientOrigin);
				
				int MaxHealth = GetEntProp(client, Prop_Data, "m_iMaxHealth");
				
				int ammopack = FindNearestAmmo(client);
				int healthpack = FindNearestHealth(client);
				
				int sentry = TF2_GetObject(client, TFObject_Sentry);
				int dispenser = TF2_GetObject(client, TFObject_Dispenser);
				
				if(GetMetal(client) >= 130.0)
				{
					g_bCanBuildSentryGun[client] = true;
				}
				else
				{
					g_bCanBuildSentryGun[client] = false;
				}
				
				if(GetMetal(client) >= 100.0)
				{
					g_bCanBuildDispenser[client] = true;
				}
				else
				{
					g_bCanBuildDispenser[client] = false;
				}
				
				if(TF2_GetNumHealers(client) == 0 && (GetHealth(client) < (MaxHealth / 1.5) || TF2_IsPlayerInCondition(client, TFCond_OnFire) || TF2_IsPlayerInCondition(client, TFCond_Bleeding)))
				{
					g_bHealthIsLow[client] = true;
				}
				else
				{
					g_bHealthIsLow[client] = false;
				}
				
				if(g_flEngineerPickNewSpotTimer[client] < GetGameTime())
				{
					if(class == TFClass_Engineer)
					{
						g_bPickUnUsedSentrySpot[client] = true;
						
						g_flEngineerPickNewSpotTimer[client] = GetGameTime() + 15.0;
					}
				}
				
				if(g_flFindNearestHealthTimer[client] < GetGameTime())
				{
					if (healthpack != -1)
					{
						GetEntPropVector(healthpack, Prop_Send, "m_vecOrigin", g_flNearestHealthOrigin[client]);
						
						g_flFindNearestHealthTimer[client] = GetGameTime() + 20.0;
					}
				}
				
				if(g_flFindNearestAmmoTimer[client] < GetGameTime())
				{
					if(ammopack != -1)
					{
						GetEntPropVector(ammopack, Prop_Send, "m_vecOrigin", g_flNearestAmmoOrigin[client]);
						
						g_flFindNearestAmmoTimer[client] = GetGameTime() + 20.0;
					}
				}
				
				if(ammopack != -1)
				{
					if(IsPointVisible(clientEyes, g_flNearestAmmoOrigin[client]))
					{
						float ammopos[3];
						GetEntPropVector(ammopack, Prop_Send, "m_vecOrigin", ammopos);
						
						if(!IsPointVisible(ammopos, g_flNearestAmmoOrigin[client]))
						{
							g_flNearestAmmoOrigin[client][0] = ammopos[0];
							g_flNearestAmmoOrigin[client][1] = ammopos[1];
							g_flNearestAmmoOrigin[client][2] = ammopos[2];
						}
					}
				}
				
				if(healthpack != -1)
				{
					if(IsPointVisible(clientEyes, g_flNearestHealthOrigin[client]))
					{
						float healthpos[3];
						GetEntPropVector(healthpack, Prop_Send, "m_vecOrigin", healthpos);
						
						if(!IsPointVisible(healthpos, g_flNearestHealthOrigin[client]))
						{
							g_flNearestHealthOrigin[client][0] = healthpos[0];
							g_flNearestHealthOrigin[client][1] = healthpos[1];
							g_flNearestHealthOrigin[client][2] = healthpos[2];
						}
					}
				}
				
				if(g_bHealthIsLow[client])
				{
					if (!(PF_Exists(client))) 
					{
						PF_Create(client, 48.0, 72.0, 1000.0, 0.6, MASK_PLAYERSOLID, 300.0, 1.0, 1.5);
					}
					
					PF_SetGoalVector(client, g_flNearestHealthOrigin[client]);
					
					PF_StartPathing(client);
					
					PF_EnableCallback(client, PFCB_Approach, Approach);
					
					if(!IsPlayerAlive(client) || !PF_Exists(client))
						return Plugin_Continue;
					
					if(PF_Exists(client) && GetVectorDistance(clientOrigin, g_flNearestHealthOrigin[client]) > 30.0)
					{
						TF2_MoveTo(client, g_flGoal[client], vel, angles);
					}
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
				
				if(sentry != INVALID_ENT_REFERENCE)
				{
					g_bSentryBuilded[client] = true;
					
					int iSentryLevel = GetEntProp(sentry, Prop_Send, "m_iUpgradeLevel");
					int iSentryHealth = GetEntProp(sentry, Prop_Send, "m_iHealth");
					int iSentryMaxHealth = GetEntProp(sentry, Prop_Send, "m_iMaxHealth");
					
					int MeleeID;
					if(IsValidEntity(GetPlayerWeaponSlot(client, 2)))
					{
						MeleeID = GetEntProp(GetPlayerWeaponSlot(client, 2), Prop_Send, "m_iItemDefinitionIndex");
						if(MeleeID == 142)
						{
							g_bSentryIsMaxLevel[client] = true;
						}
						else
						{
							if(iSentryLevel < 3)
							{
								g_bSentryIsMaxLevel[client] = false;
							}
							else
							{
								g_bSentryIsMaxLevel[client] = true;
							}
						}
					}
					
					if(iSentryHealth < iSentryMaxHealth)
					{
						g_bSentryHealthIsFull[client] = false;
					}
					else
					{
						g_bSentryHealthIsFull[client] = true;
					}
				}
				else
				{
					g_bSentryBuilded[client] = false;
				}
				
				if(GetMetal(client) != -1)
				{
					if(g_bIdleTime[client])
					{
						if(GetMetal(client) < 200)
						{
							g_bAmmoIsLow[client] = true;
						}
						else
						{
							g_bAmmoIsLow[client] = false;
						}
					}
					else if(sentry != INVALID_ENT_REFERENCE)
					{
						int iSentryLevel = GetEntProp(sentry, Prop_Send, "m_iUpgradeLevel");
					
						if(iSentryLevel == 3)
						{
							if(GetMetal(client) < 100)
							{
								g_bAmmoIsLow[client] = true;
							}
							else
							{
								g_bAmmoIsLow[client] = false;
							}
						}
						else
						{
							if(GetMetal(client) == 0)
							{
								g_bAmmoIsLow[client] = true;
							}
							else
							{
								g_bAmmoIsLow[client] = false;
							}
						}
					}
					else
					{
						if(GetMetal(client) < 130)
						{
							g_bAmmoIsLow[client] = true;
						}
						else
						{
							g_bAmmoIsLow[client] = false;
						}
					}
				}
				
				if(!g_bSentryBuilded[client] && g_bCanBuildSentryGun[client])
				{
					g_bBuildSentry[client] = true;
				}
				else
				{
					g_bBuildSentry[client] = false;
				}
				
				if(g_bSentryBuilded[client] && g_bSentryIsMaxLevel[client] && g_bSentryHealthIsFull[client] && !g_bDispenserBuilded[client] && g_bCanBuildDispenser[client])
				{
					g_bBuildDispenser[client] = true;
				}
				else
				{
					g_bBuildDispenser[client] = false;
				}
				
				if(g_bSentryBuilded[client] && (!g_bSentryHealthIsFull[client] || !g_bSentryIsMaxLevel[client]))
				{
					g_bRepairSentry[client] = true;
				}
				else
				{
					g_bRepairSentry[client] = false;
				}
				
				if(g_bDispenserBuilded[client] && (!g_bDispenserHealthIsFull[client] || !g_bDispenserIsMaxLevel[client]))
				{
					g_bRepairDispenser[client] = true;
				}
				else
				{
					g_bRepairDispenser[client] = false;
				}
				
				if(g_bSentryBuilded[client] && g_bSentryHealthIsFull[client] && g_bSentryIsMaxLevel[client] && g_bDispenserBuilded[client] && g_bDispenserHealthIsFull[client] && g_bDispenserIsMaxLevel[client])
				{
					g_bIdleTime[client] = true;
				}
				else
				{
					g_bIdleTime[client] = false;
				}
				
				if(dispenser != INVALID_ENT_REFERENCE)
				{
					g_bDispenserBuilded[client] = true;
					
					int iDispenserLevel = GetEntProp(dispenser, Prop_Send, "m_iUpgradeLevel");
					int iDispenserHealth = GetEntProp(dispenser, Prop_Send, "m_iHealth");
					int iDispenserMaxHealth = GetEntProp(dispenser, Prop_Send, "m_iMaxHealth");
					
					if(iDispenserLevel < 3)
					{
						g_bDispenserIsMaxLevel[client] = false;
					}
					else
					{
						g_bDispenserIsMaxLevel[client] = true;
					}
					
					if(iDispenserHealth < iDispenserMaxHealth)
					{
						g_bDispenserHealthIsFull[client] = false;
					}
					else
					{
						g_bDispenserHealthIsFull[client] = true;
					}
				}
				else
				{
					g_bDispenserBuilded[client] = false;
				}
				
				//if(g_flChangeWeaponTimer[client] < GetGameTime())
				//{
				//	EquipWeaponSlot(client, 2);
				//	
				//	g_flChangeWeaponTimer[client] = GetGameTime() + 5.0;
				//}
				
				if(g_flWaitJumpTimer[client] < GetGameTime() && !IsClientMoving(client))
				{
					buttons |= IN_JUMP;
					
					g_flWaitJumpTimer[client] = GetGameTime() + 5.0;
				}
				
				// Make engie bots attack close enemies!
				for (int search = 1; search <= MaxClients; search++)
					{
						if (IsClientInGame(search) && IsPlayerAlive(search) && search != client && (GetClientTeam(client) != GetClientTeam(search)))
						{							
							//float clientOrigin[3];
							float searchOrigin[3];
							GetClientAbsOrigin(search, searchOrigin);
							GetClientAbsOrigin(client, clientOrigin);

							float chainDistance2;
							chainDistance2 = GetVectorDistance(clientOrigin, searchOrigin);

							if(chainDistance2 < 800.0)
							{
								TF2_RemoveCondition(client, TFCond_RestrictToMelee);
								if(IsTargetInSightRange(client, search))
								{
									//g_AttackPlayers[client] = true;
									EquipWeaponSlot(client, 0);	
									TF2_LookAtPos(client, searchOrigin, 0.05);
									buttons |= IN_ATTACK;
								}											
							}
							else if(!IsWeaponSlotActive(client, 2))
							{
								EquipWeaponSlot(client, 2);
								//g_AttackPlayers[client] = false;
							}
						}
					}
				
				if(GetEntProp(client, Prop_Send, "m_bJumping"))
				{
					buttons |= IN_DUCK;
				}
				
				if(IsWeaponSlotActive(client, 5))
				{
					if(!g_bSentryBuilded[client])
					{
						if(GetVectorDistance(clientEyes, g_flSentryBuildPos[client]) < 500.0)
						{
							TF2_LookAtPos(client, g_flSentryBuildAngle[client], 0.1);
						}
					}
				}
				
				if(StrContains(currentMap, "ctf_" , false) != -1 && !TF2_HasTheFlag(client))
				{
					if(class == TFClass_Engineer && !g_bHealthIsLow[client] && !g_bAmmoIsLow[client])
					{
							int flag;
							while((flag = FindEntityByClassname(flag, "item_teamflag")) != INVALID_ENT_REFERENCE)
							{
								int iTeamNumObj = GetEntProp(flag, Prop_Send, "m_iTeamNum");
								if(IsValidEntity(flag) && GetClientTeam(client) == iTeamNumObj)
								{
									float engiOrigin[3];
									float flagpos[3];
									GetClientAbsOrigin(client, engiOrigin);
									GetEntPropVector(flag, Prop_Send, "m_vecOrigin", flagpos);
									
									flagpos[2] += 100.0;
									
									int FlagStatus = GetEntProp(flag, Prop_Send, "m_nFlagStatus");
									
									//PrintToServer("FlagStatus %i", FlagStatus);
									
									if(g_bBuildSentry[client])
									{
										if(FlagStatus == 0 || FlagStatus == 1 || FlagStatus == 2)
										{
											if (!(PF_Exists(client))) 
											{
												PF_Create(client, 24.0, 72.0, 1000.0, 0.6, MASK_PLAYERSOLID, 300.0, 1.0, 1.5);
											}
											
											PF_SetGoalVector(client, flagpos);
											
											PF_StartPathing(client);
											
											PF_EnableCallback(client, PFCB_Approach, Approach);
											
											if(!IsPlayerAlive(client) || !PF_Exists(client))
												return Plugin_Continue;
											
											if(GetVectorDistance(engiOrigin, flagpos) < GetRandomFloat(75.0, 750.0))
											{
												if(IsWeaponSlotActive(client, 5))
												{
													buttons |= IN_ATTACK;
												}
												else
												{
													FakeClientCommandThrottled(client, "build 2");
													TF2_RemoveCondition(client, TFCond_RestrictToMelee);
												}
											}
											
											TF2_MoveTo(client, g_flGoal[client], vel, angles);
										}
									}
									
									if(g_bIdleTime[client] || g_bRepairSentry[client])
									{
										float sentrypos[3];
										GetEntPropVector(sentry, Prop_Send, "m_vecOrigin", sentrypos);
										
										float camangle[3];
										float fEntityLocation[3];
										float vec[3];
										float angle[3];
										GetEntPropVector(sentry, Prop_Send, "m_vecOrigin", fEntityLocation);
										GetEntPropVector(sentry, Prop_Data, "m_angRotation", angle);
										fEntityLocation[2] += 15.0;
										MakeVectorFromPoints(fEntityLocation, clientEyes, vec);
										GetVectorAngles(vec, camangle);
										camangle[0] *= -1.0;
										camangle[1] += 180.0;
										ClampAngle(camangle);
										
										if(GetVectorDistance(engiOrigin, sentrypos) < 150.0)
										{
											TeleportEntity(client, NULL_VECTOR, camangle, NULL_VECTOR);
											buttons |= IN_DUCK;
											if(IsWeaponSlotActive(client, 2))
											{
												buttons |= IN_ATTACK;
											}
											else
											{
												TF2_AddCondition(client, TFCond_RestrictToMelee, TFCondDuration_Infinite);
												TF2_AddCondition(client, TFCond_MeleeOnly, 0.1);
												TF2_RemoveCondition(client, TFCond_MeleeOnly);
											}
											if(GetVectorDistance(engiOrigin, sentrypos) > 50.0)
											{
												TF2_MoveTo(client, sentrypos, vel, angles);
											}
										}
										
										if (!(PF_Exists(client))) 
										{
											PF_Create(client, 24.0, 72.0, 1000.0, 0.6, MASK_PLAYERSOLID, 300.0, 1.0, 1.5);
										}
										
										PF_SetGoalEntity(client, sentry);
										
										PF_StartPathing(client);
										
										PF_EnableCallback(client, PFCB_Approach, Approach);
										
										if(!IsPlayerAlive(client) || !PF_Exists(client))
											return Plugin_Continue;
										
										if(GetVectorDistance(engiOrigin, sentrypos) > 100.0)
										{
											TF2_MoveTo(client, g_flGoal[client], vel, angles);
										}
										else
										{
											PF_StopPathing(client);
										}
									}
									
									if(g_bBuildDispenser[client])
									{
										if (!(PF_Exists(client))) 
										{
											PF_Create(client, 24.0, 72.0, 1000.0, 0.6, MASK_PLAYERSOLID, 300.0, 1.0, 1.5);
										}
										
										float sentrypos[3];
										GetEntPropVector(sentry, Prop_Send, "m_vecOrigin", sentrypos);
										
										float putdispenserpos[3];
										
										putdispenserpos[0] = sentrypos[0] + GetRandomFloat(-500.0, 500.0);
										putdispenserpos[1] = sentrypos[1] + GetRandomFloat(-500.0, 500.0);
										putdispenserpos[2] = sentrypos[2] + GetRandomFloat(-500.0, 500.0);
										
										PF_SetGoalVector(client, putdispenserpos);
										
										PF_StartPathing(client);
										
										PF_EnableCallback(client, PFCB_Approach, Approach);
										
										if(!IsPlayerAlive(client) || !PF_Exists(client))
											return Plugin_Continue;
										
										if(GetVectorDistance(engiOrigin, putdispenserpos) < GetRandomFloat(50.0, 150.0))
										{
											if(IsWeaponSlotActive(client, 5))
											{
												buttons |= IN_ATTACK;
											}
											else
											{
												FakeClientCommandThrottled(client, "build 0");
												TF2_RemoveCondition(client, TFCond_RestrictToMelee);

											}
										}
										
										TF2_MoveTo(client, g_flGoal[client], vel, angles);
									}
									
									if(g_bRepairDispenser[client])
									{
										float dispenserpos[3];
										GetEntPropVector(dispenser, Prop_Send, "m_vecOrigin", dispenserpos);
										
										float camangle[3];
										float fEntityLocation[3];
										float vec[3];
										float angle[3];
										GetEntPropVector(dispenser, Prop_Send, "m_vecOrigin", fEntityLocation);
										GetEntPropVector(dispenser, Prop_Data, "m_angRotation", angle);
										fEntityLocation[2] += 15.0;
										MakeVectorFromPoints(fEntityLocation, clientEyes, vec);
										GetVectorAngles(vec, camangle);
										camangle[0] *= -1.0;
										camangle[1] += 180.0;
										ClampAngle(camangle);
										
										if(GetVectorDistance(engiOrigin, dispenserpos) < 150.0)
										{
											TeleportEntity(client, NULL_VECTOR, camangle, NULL_VECTOR);
											buttons |= IN_DUCK;
											if(IsWeaponSlotActive(client, 2))
											{
												buttons |= IN_ATTACK;
											}
											else
											{
												TF2_AddCondition(client, TFCond_RestrictToMelee, TFCondDuration_Infinite);
												TF2_AddCondition(client, TFCond_MeleeOnly, 0.1);
												TF2_RemoveCondition(client, TFCond_MeleeOnly);
											}
											if(GetVectorDistance(engiOrigin, dispenserpos) > 50.0)
											{
												TF2_MoveTo(client, dispenserpos, vel, angles);
											}
										}
										
										if (!(PF_Exists(client))) 
										{
											PF_Create(client, 24.0, 72.0, 1000.0, 0.6, MASK_PLAYERSOLID, 300.0, 1.0, 1.5);
										}
										
										PF_SetGoalVector(client, dispenserpos);
										
										PF_StartPathing(client);
										
										PF_EnableCallback(client, PFCB_Approach, Approach);
										
										if(!IsPlayerAlive(client) || !PF_Exists(client))
											return Plugin_Continue;
										
										if(GetVectorDistance(engiOrigin, dispenserpos) > 100.0)
										{
											TF2_MoveTo(client, g_flGoal[client], vel, angles);
										}
										else
										{
											PF_StopPathing(client);
										}
									}
								}
							}
					}
				}
				else if(StrContains(currentMap, "rd_" , false) != -1)
				{
					if(class == TFClass_Engineer && !g_bHealthIsLow[client] && !g_bAmmoIsLow[client])
					{
							int robot = GetNearestEntity(client, "tf_robot_destruction_robot");
							
							if(robot != -1)
							{
								int iTeamNumObj = GetEntProp(robot, Prop_Send, "m_iTeamNum");
								if(IsValidEntity(robot) && GetClientTeam(client) == iTeamNumObj)
								{
									float engiOrigin[3];
									float robotpos[3];
									GetClientAbsOrigin(client, engiOrigin);
									GetEntPropVector(robot, Prop_Send, "m_vecOrigin", robotpos);
									
									robotpos[2] += 100.0;
									
									if(g_bBuildSentry[client])
									{
										if (!(PF_Exists(client))) 
										{
											PF_Create(client, 24.0, 72.0, 1000.0, 0.6, MASK_PLAYERSOLID, 300.0, 1.0, 1.5);
										}
										
										PF_SetGoalVector(client, robotpos);
										
										PF_StartPathing(client);
										
										PF_EnableCallback(client, PFCB_Approach, Approach);
										
										if(!IsPlayerAlive(client) || !PF_Exists(client))
											return Plugin_Continue;
										
										if(GetVectorDistance(engiOrigin, robotpos) < GetRandomFloat(75.0, 750.0) && IsPointVisible(clientEyes, robotpos))
										{
											if(IsWeaponSlotActive(client, 5))
											{
												buttons |= IN_ATTACK;
											}
											else
											{
												FakeClientCommandThrottled(client, "build 2");
												TF2_RemoveCondition(client, TFCond_RestrictToMelee);
											}
										}
										
										TF2_MoveTo(client, g_flGoal[client], vel, angles);
									}
									
									if(g_bIdleTime[client] || g_bRepairSentry[client])
									{
										float sentrypos[3];
										GetEntPropVector(sentry, Prop_Send, "m_vecOrigin", sentrypos);
										
										float camangle[3];
										float fEntityLocation[3];
										float vec[3];
										float angle[3];
										GetEntPropVector(sentry, Prop_Send, "m_vecOrigin", fEntityLocation);
										GetEntPropVector(sentry, Prop_Data, "m_angRotation", angle);
										fEntityLocation[2] += 15.0;
										MakeVectorFromPoints(fEntityLocation, clientEyes, vec);
										GetVectorAngles(vec, camangle);
										camangle[0] *= -1.0;
										camangle[1] += 180.0;
										ClampAngle(camangle);
										
										if(GetVectorDistance(engiOrigin, sentrypos) < 150.0)
										{
											TeleportEntity(client, NULL_VECTOR, camangle, NULL_VECTOR);
											buttons |= IN_DUCK;
											if(IsWeaponSlotActive(client, 2))
											{
												buttons |= IN_ATTACK;
											}
											else
											{
												TF2_AddCondition(client, TFCond_RestrictToMelee, TFCondDuration_Infinite);
												TF2_AddCondition(client, TFCond_MeleeOnly, 0.1);
												TF2_RemoveCondition(client, TFCond_MeleeOnly);
											}
											if(GetVectorDistance(engiOrigin, sentrypos) > 50.0)
											{
												TF2_MoveTo(client, sentrypos, vel, angles);
											}
										}
										
										if (!(PF_Exists(client))) 
										{
											PF_Create(client, 24.0, 72.0, 1000.0, 0.6, MASK_PLAYERSOLID, 300.0, 1.0, 1.5);
										}
										
										PF_SetGoalEntity(client, sentry);
										
										PF_StartPathing(client);
										
										PF_EnableCallback(client, PFCB_Approach, Approach);
										
										if(!IsPlayerAlive(client) || !PF_Exists(client))
											return Plugin_Continue;
										
										if(GetVectorDistance(engiOrigin, sentrypos) > 100.0)
										{
											TF2_MoveTo(client, g_flGoal[client], vel, angles);
										}
										else
										{
											PF_StopPathing(client);
										}
									}
									
									if(g_bBuildDispenser[client])
									{
										if (!(PF_Exists(client))) 
										{
											PF_Create(client, 24.0, 72.0, 1000.0, 0.6, MASK_PLAYERSOLID, 300.0, 1.0, 1.5);
										}
										
										float sentrypos[3];
										GetEntPropVector(sentry, Prop_Send, "m_vecOrigin", sentrypos);
										
										float putdispenserpos[3];
										
										putdispenserpos[0] = sentrypos[0] + GetRandomFloat(-500.0, 500.0);
										putdispenserpos[1] = sentrypos[1] + GetRandomFloat(-500.0, 500.0);
										putdispenserpos[2] = sentrypos[2] + GetRandomFloat(-500.0, 500.0);
										
										PF_SetGoalVector(client, putdispenserpos);
										
										PF_StartPathing(client);
										
										PF_EnableCallback(client, PFCB_Approach, Approach);
										
										if(!IsPlayerAlive(client) || !PF_Exists(client))
											return Plugin_Continue;
										
										if(GetVectorDistance(engiOrigin, putdispenserpos) < GetRandomFloat(50.0, 150.0))
										{
											if(IsWeaponSlotActive(client, 5))
											{
												buttons |= IN_ATTACK;
											}
											else
											{
												FakeClientCommandThrottled(client, "build 0");
												TF2_RemoveCondition(client, TFCond_RestrictToMelee);
											}
										}
										
										TF2_MoveTo(client, g_flGoal[client], vel, angles);
									}
									
									if(g_bRepairDispenser[client])
									{
										float dispenserpos[3];
										GetEntPropVector(dispenser, Prop_Send, "m_vecOrigin", dispenserpos);
										
										float camangle[3];
										float fEntityLocation[3];
										float vec[3];
										float angle[3];
										GetEntPropVector(dispenser, Prop_Send, "m_vecOrigin", fEntityLocation);
										GetEntPropVector(dispenser, Prop_Data, "m_angRotation", angle);
										fEntityLocation[2] += 15.0;
										MakeVectorFromPoints(fEntityLocation, clientEyes, vec);
										GetVectorAngles(vec, camangle);
										camangle[0] *= -1.0;
										camangle[1] += 180.0;
										ClampAngle(camangle);
										
										if(GetVectorDistance(engiOrigin, dispenserpos) < 150.0)
										{
											TeleportEntity(client, NULL_VECTOR, camangle, NULL_VECTOR);
											buttons |= IN_DUCK;
											if(IsWeaponSlotActive(client, 2))
											{
												buttons |= IN_ATTACK;
											}
											else
											{
												TF2_AddCondition(client, TFCond_RestrictToMelee, TFCondDuration_Infinite);
												TF2_AddCondition(client, TFCond_MeleeOnly, 0.1);
												TF2_RemoveCondition(client, TFCond_MeleeOnly);
											}
											if(GetVectorDistance(engiOrigin, dispenserpos) > 50.0)
											{
												TF2_MoveTo(client, dispenserpos, vel, angles);
											}
										}
										
										if (!(PF_Exists(client))) 
										{
											PF_Create(client, 24.0, 72.0, 1000.0, 0.6, MASK_PLAYERSOLID, 300.0, 1.0, 1.5);
										}
										
										PF_SetGoalVector(client, dispenserpos);
										
										PF_StartPathing(client);
										
										PF_EnableCallback(client, PFCB_Approach, Approach);
										
										if(!IsPlayerAlive(client) || !PF_Exists(client))
											return Plugin_Continue;
										
										if(GetVectorDistance(engiOrigin, dispenserpos) > 100.0)
										{
											TF2_MoveTo(client, g_flGoal[client], vel, angles);
										}
										else
										{
											PF_StopPathing(client);
										}
									}
								}
							}
					}
				}
				else if(StrContains(currentMap, "arena_" , false) != -1)
				{
					if(class == TFClass_Engineer && !g_bHealthIsLow[client] && !g_bAmmoIsLow[client])
					{
							int capturepoint = GetNearestEntity(client, "item_ammopack_*"); // :(
							
							if(capturepoint != -1)
							{
								if(IsValidEntity(capturepoint))
								{
									float engiOrigin[3];
									float capturepointpos[3];
									GetClientAbsOrigin(client, engiOrigin);
									GetEntPropVector(capturepoint, Prop_Send, "m_vecOrigin", capturepointpos);
									
									capturepointpos[2] += 100.0;
									
									if(g_bBuildSentry[client])
									{
										if (!(PF_Exists(client))) 
										{
											PF_Create(client, 24.0, 72.0, 1000.0, 0.6, MASK_PLAYERSOLID, 300.0, 1.0, 1.5);
										}
										
										PF_SetGoalVector(client, capturepointpos);
										
										PF_StartPathing(client);
										
										PF_EnableCallback(client, PFCB_Approach, Approach);
										
										if(!IsPlayerAlive(client) || !PF_Exists(client))
											return Plugin_Continue;
										
										if(GetVectorDistance(engiOrigin, capturepointpos) < GetRandomFloat(250.0, 750.0) && IsPointVisible(clientEyes, capturepointpos))
										{
											if(IsWeaponSlotActive(client, 5))
											{
												buttons |= IN_ATTACK;
											}
											else
											{
												FakeClientCommandThrottled(client, "build 2");
												TF2_RemoveCondition(client, TFCond_RestrictToMelee);
											}
										}
										
										TF2_MoveTo(client, g_flGoal[client], vel, angles);
									}
									
									if(g_bIdleTime[client] || g_bRepairSentry[client])
									{
										float sentrypos[3];
										GetEntPropVector(sentry, Prop_Send, "m_vecOrigin", sentrypos);
										
										float camangle[3];
										float fEntityLocation[3];
										float vec[3];
										float angle[3];
										GetEntPropVector(sentry, Prop_Send, "m_vecOrigin", fEntityLocation);
										GetEntPropVector(sentry, Prop_Data, "m_angRotation", angle);
										fEntityLocation[2] += 15.0;
										MakeVectorFromPoints(fEntityLocation, clientEyes, vec);
										GetVectorAngles(vec, camangle);
										camangle[0] *= -1.0;
										camangle[1] += 180.0;
										ClampAngle(camangle);
										
										if(GetVectorDistance(engiOrigin, sentrypos) < 150.0)
										{
											TeleportEntity(client, NULL_VECTOR, camangle, NULL_VECTOR);
											buttons |= IN_DUCK;
											if(IsWeaponSlotActive(client, 2))
											{
												buttons |= IN_ATTACK;
											}
											else
											{
												TF2_AddCondition(client, TFCond_RestrictToMelee, TFCondDuration_Infinite);
												TF2_AddCondition(client, TFCond_MeleeOnly, 0.1);
												TF2_RemoveCondition(client, TFCond_MeleeOnly);
											}
											if(GetVectorDistance(engiOrigin, sentrypos) > 50.0)
											{
												TF2_MoveTo(client, sentrypos, vel, angles);
											}
										}
										
										if (!(PF_Exists(client))) 
										{
											PF_Create(client, 24.0, 72.0, 1000.0, 0.6, MASK_PLAYERSOLID, 300.0, 1.0, 1.5);
										}
										
										PF_SetGoalEntity(client, sentry);
										
										PF_StartPathing(client);
										
										PF_EnableCallback(client, PFCB_Approach, Approach);
										
										if(!IsPlayerAlive(client) || !PF_Exists(client))
											return Plugin_Continue;
										
										if(GetVectorDistance(engiOrigin, sentrypos) > 100.0)
										{
											TF2_MoveTo(client, g_flGoal[client], vel, angles);
										}
										else
										{
											PF_StopPathing(client);
										}
									}
									
									if(g_bBuildDispenser[client])
									{
										if (!(PF_Exists(client))) 
										{
											PF_Create(client, 24.0, 72.0, 1000.0, 0.6, MASK_PLAYERSOLID, 300.0, 1.0, 1.5);
										}
										
										float sentrypos[3];
										GetEntPropVector(sentry, Prop_Send, "m_vecOrigin", sentrypos);
										
										float putdispenserpos[3];
										
										putdispenserpos[0] = sentrypos[0] + GetRandomFloat(-500.0, 500.0);
										putdispenserpos[1] = sentrypos[1] + GetRandomFloat(-500.0, 500.0);
										putdispenserpos[2] = sentrypos[2] + GetRandomFloat(-500.0, 500.0);
										
										PF_SetGoalVector(client, putdispenserpos);
										
										PF_StartPathing(client);
										
										PF_EnableCallback(client, PFCB_Approach, Approach);
										
										if(!IsPlayerAlive(client) || !PF_Exists(client))
											return Plugin_Continue;
										
										if(GetVectorDistance(engiOrigin, putdispenserpos) < GetRandomFloat(50.0, 150.0))
										{
											if(IsWeaponSlotActive(client, 5))
											{
												buttons |= IN_ATTACK;
											}
											else
											{
												FakeClientCommandThrottled(client, "build 0");
												TF2_RemoveCondition(client, TFCond_RestrictToMelee);
											}
										}
										
										TF2_MoveTo(client, g_flGoal[client], vel, angles);
									}
									
									if(g_bRepairDispenser[client])
									{
										float dispenserpos[3];
										GetEntPropVector(dispenser, Prop_Send, "m_vecOrigin", dispenserpos);
										
										float camangle[3];
										float fEntityLocation[3];
										float vec[3];
										float angle[3];
										GetEntPropVector(dispenser, Prop_Send, "m_vecOrigin", fEntityLocation);
										GetEntPropVector(dispenser, Prop_Data, "m_angRotation", angle);
										fEntityLocation[2] += 15.0;
										MakeVectorFromPoints(fEntityLocation, clientEyes, vec);
										GetVectorAngles(vec, camangle);
										camangle[0] *= -1.0;
										camangle[1] += 180.0;
										ClampAngle(camangle);
										
										if(GetVectorDistance(engiOrigin, dispenserpos) < 150.0)
										{
											TeleportEntity(client, NULL_VECTOR, camangle, NULL_VECTOR);
											buttons |= IN_DUCK;
											if(IsWeaponSlotActive(client, 2))
											{
												buttons |= IN_ATTACK;
											}
											else
											{
												TF2_AddCondition(client, TFCond_RestrictToMelee, TFCondDuration_Infinite);
												TF2_AddCondition(client, TFCond_MeleeOnly, 0.1);
												TF2_RemoveCondition(client, TFCond_MeleeOnly);
											}
											if(GetVectorDistance(engiOrigin, dispenserpos) > 50.0)
											{
												TF2_MoveTo(client, dispenserpos, vel, angles);
											}
										}
										
										if (!(PF_Exists(client))) 
										{
											PF_Create(client, 24.0, 72.0, 1000.0, 0.6, MASK_PLAYERSOLID, 300.0, 1.0, 1.5);
										}
										
										PF_SetGoalVector(client, dispenserpos);
										
										PF_StartPathing(client);
										
										PF_EnableCallback(client, PFCB_Approach, Approach);
										
										if(!IsPlayerAlive(client) || !PF_Exists(client))
											return Plugin_Continue;
										
										if(GetVectorDistance(engiOrigin, dispenserpos) > 100.0)
										{
											TF2_MoveTo(client, g_flGoal[client], vel, angles);
										}
										else
										{
											PF_StopPathing(client);
										}
									}
								}
							}
					}
				}
				else if(StrContains(currentMap, "pd_" , false) != -1)
				{
					if(class == TFClass_Engineer && !g_bHealthIsLow[client] && !g_bAmmoIsLow[client])
					{
							int pd_disp = GetNearestEntity(client, "pd_dispenser");
							
							if(pd_disp != -1)
							{
								int iTeamNumObj = GetEntProp(pd_disp, Prop_Send, "m_iTeamNum");
								if(IsValidEntity(pd_disp) && GetClientTeam(client) == iTeamNumObj)
								{
									float engiOrigin[3];
									float pd_disppos[3];
									GetClientAbsOrigin(client, engiOrigin);
									GetEntPropVector(pd_disp, Prop_Send, "m_vecOrigin", pd_disppos);
									
									pd_disppos[2] += 100.0;
									
									if(g_bBuildSentry[client])
									{
										if (!(PF_Exists(client))) 
										{
											PF_Create(client, 24.0, 72.0, 1000.0, 0.6, MASK_PLAYERSOLID, 300.0, 1.0, 1.5);
										}
										
										PF_SetGoalVector(client, pd_disppos);
										
										PF_StartPathing(client);
										
										PF_EnableCallback(client, PFCB_Approach, Approach);
										
										if(!IsPlayerAlive(client) || !PF_Exists(client))
											return Plugin_Continue;
										
										if(GetVectorDistance(engiOrigin, pd_disppos) < GetRandomFloat(150.0, 500.0) && IsPointVisible(clientEyes, pd_disppos))
										{
											if(IsWeaponSlotActive(client, 5))
											{
												buttons |= IN_ATTACK;
											}
											else
											{
												FakeClientCommandThrottled(client, "build 2");
												TF2_RemoveCondition(client, TFCond_RestrictToMelee);
											}
										}
										
										TF2_MoveTo(client, g_flGoal[client], vel, angles);
									}
									
									if(g_bIdleTime[client] || g_bRepairSentry[client])
									{
										float sentrypos[3];
										GetEntPropVector(sentry, Prop_Send, "m_vecOrigin", sentrypos);
										
										float camangle[3];
										float fEntityLocation[3];
										float vec[3];
										float angle[3];
										GetEntPropVector(sentry, Prop_Send, "m_vecOrigin", fEntityLocation);
										GetEntPropVector(sentry, Prop_Data, "m_angRotation", angle);
										fEntityLocation[2] += 15.0;
										MakeVectorFromPoints(fEntityLocation, clientEyes, vec);
										GetVectorAngles(vec, camangle);
										camangle[0] *= -1.0;
										camangle[1] += 180.0;
										ClampAngle(camangle);
										
										if(GetVectorDistance(engiOrigin, sentrypos) < 150.0)
										{
											TeleportEntity(client, NULL_VECTOR, camangle, NULL_VECTOR);
											buttons |= IN_DUCK;
											if(IsWeaponSlotActive(client, 2))
											{
												buttons |= IN_ATTACK;
											}
											else
											{
												TF2_AddCondition(client, TFCond_RestrictToMelee, TFCondDuration_Infinite);
												TF2_AddCondition(client, TFCond_MeleeOnly, 0.1);
												TF2_RemoveCondition(client, TFCond_MeleeOnly);
											}
											if(GetVectorDistance(engiOrigin, sentrypos) > 50.0)
											{
												TF2_MoveTo(client, sentrypos, vel, angles);
											}
										}
										
										if (!(PF_Exists(client))) 
										{
											PF_Create(client, 24.0, 72.0, 1000.0, 0.6, MASK_PLAYERSOLID, 300.0, 1.0, 1.5);
										}
										
										PF_SetGoalEntity(client, sentry);
										
										PF_StartPathing(client);
										
										PF_EnableCallback(client, PFCB_Approach, Approach);
										
										if(!IsPlayerAlive(client) || !PF_Exists(client))
											return Plugin_Continue;
										
										if(GetVectorDistance(engiOrigin, sentrypos) > 100.0)
										{
											TF2_MoveTo(client, g_flGoal[client], vel, angles);
										}
										else
										{
											PF_StopPathing(client);
										}
									}
									
									if(g_bBuildDispenser[client])
									{
										if (!(PF_Exists(client))) 
										{
											PF_Create(client, 24.0, 72.0, 1000.0, 0.6, MASK_PLAYERSOLID, 300.0, 1.0, 1.5);
										}
										
										float sentrypos[3];
										GetEntPropVector(sentry, Prop_Send, "m_vecOrigin", sentrypos);
										
										float putdispenserpos[3];
										
										putdispenserpos[0] = sentrypos[0] + GetRandomFloat(-500.0, 500.0);
										putdispenserpos[1] = sentrypos[1] + GetRandomFloat(-500.0, 500.0);
										putdispenserpos[2] = sentrypos[2] + GetRandomFloat(-500.0, 500.0);
										
										PF_SetGoalVector(client, putdispenserpos);
										
										PF_StartPathing(client);
										
										PF_EnableCallback(client, PFCB_Approach, Approach);
										
										if(!IsPlayerAlive(client) || !PF_Exists(client))
											return Plugin_Continue;
										
										if(GetVectorDistance(engiOrigin, putdispenserpos) < GetRandomFloat(50.0, 150.0))
										{
											if(IsWeaponSlotActive(client, 5))
											{
												buttons |= IN_ATTACK;
											}
											else
											{
												FakeClientCommandThrottled(client, "build 0");
												TF2_RemoveCondition(client, TFCond_RestrictToMelee);
											}
										}
										
										TF2_MoveTo(client, g_flGoal[client], vel, angles);
									}
									
									if(g_bRepairDispenser[client])
									{
										float dispenserpos[3];
										GetEntPropVector(dispenser, Prop_Send, "m_vecOrigin", dispenserpos);
										
										float camangle[3];
										float fEntityLocation[3];
										float vec[3];
										float angle[3];
										GetEntPropVector(dispenser, Prop_Send, "m_vecOrigin", fEntityLocation);
										GetEntPropVector(dispenser, Prop_Data, "m_angRotation", angle);
										fEntityLocation[2] += 15.0;
										MakeVectorFromPoints(fEntityLocation, clientEyes, vec);
										GetVectorAngles(vec, camangle);
										camangle[0] *= -1.0;
										camangle[1] += 180.0;
										ClampAngle(camangle);
										
										if(GetVectorDistance(engiOrigin, dispenserpos) < 150.0)
										{
											TeleportEntity(client, NULL_VECTOR, camangle, NULL_VECTOR);
											buttons |= IN_DUCK;
											if(IsWeaponSlotActive(client, 2))
											{
												buttons |= IN_ATTACK;
											}
											else
											{
												TF2_AddCondition(client, TFCond_RestrictToMelee, TFCondDuration_Infinite);
												TF2_AddCondition(client, TFCond_MeleeOnly, 0.1);
												TF2_RemoveCondition(client, TFCond_MeleeOnly);
											}
											if(GetVectorDistance(engiOrigin, dispenserpos) > 50.0)
											{
												TF2_MoveTo(client, dispenserpos, vel, angles);
											}
										}
										
										if (!(PF_Exists(client))) 
										{
											PF_Create(client, 24.0, 72.0, 1000.0, 0.6, MASK_PLAYERSOLID, 300.0, 1.0, 1.5);
										}
										
										PF_SetGoalVector(client, dispenserpos);
										
										PF_StartPathing(client);
										
										PF_EnableCallback(client, PFCB_Approach, Approach);
										
										if(!IsPlayerAlive(client) || !PF_Exists(client))
											return Plugin_Continue;
										
										if(GetVectorDistance(engiOrigin, dispenserpos) > 100.0)
										{
											TF2_MoveTo(client, g_flGoal[client], vel, angles);
										}
										else
										{
											PF_StopPathing(client);
										}
									}
								}
							}
					}
				}
				else if(StrContains(currentMap, "pass_" , false) != -1)
				{
					if(class == TFClass_Engineer && !g_bHealthIsLow[client] && !g_bAmmoIsLow[client])
					{
							int passtimeball = GetNearestEntity(client, "passtime_ball");
							
							if(passtimeball != -1)
							{
								if(IsValidEntity(passtimeball))
								{
									float engiOrigin[3];
									float passtimeballpos[3];
									GetClientAbsOrigin(client, engiOrigin);
									GetEntPropVector(passtimeball, Prop_Send, "m_vecOrigin", passtimeballpos);
									
									passtimeballpos[2] += 100.0;
									
									if(g_bBuildSentry[client])
									{
										if (!(PF_Exists(client))) 
										{
											PF_Create(client, 24.0, 72.0, 1000.0, 0.6, MASK_PLAYERSOLID, 300.0, 1.0, 1.5);
										}
										
										PF_SetGoalVector(client, passtimeballpos);
										
										PF_StartPathing(client);
										
										PF_EnableCallback(client, PFCB_Approach, Approach);
										
										if(!IsPlayerAlive(client) || !PF_Exists(client))
											return Plugin_Continue;
										
										if(GetVectorDistance(engiOrigin, passtimeballpos) < GetRandomFloat(150.0, 1500.0) && IsPointVisible(clientEyes, passtimeballpos))
										{
											if(IsWeaponSlotActive(client, 5))
											{
												buttons |= IN_ATTACK;
											}
											else
											{
												FakeClientCommandThrottled(client, "build 2");
												TF2_RemoveCondition(client, TFCond_RestrictToMelee);
											}
										}
										
										TF2_MoveTo(client, g_flGoal[client], vel, angles);
									}
									
									if(g_bIdleTime[client] || g_bRepairSentry[client])
									{
										float sentrypos[3];
										GetEntPropVector(sentry, Prop_Send, "m_vecOrigin", sentrypos);
										
										float camangle[3];
										float fEntityLocation[3];
										float vec[3];
										float angle[3];
										GetEntPropVector(sentry, Prop_Send, "m_vecOrigin", fEntityLocation);
										GetEntPropVector(sentry, Prop_Data, "m_angRotation", angle);
										fEntityLocation[2] += 15.0;
										MakeVectorFromPoints(fEntityLocation, clientEyes, vec);
										GetVectorAngles(vec, camangle);
										camangle[0] *= -1.0;
										camangle[1] += 180.0;
										ClampAngle(camangle);
										
										if(GetVectorDistance(engiOrigin, sentrypos) < 150.0)
										{
											TeleportEntity(client, NULL_VECTOR, camangle, NULL_VECTOR);
											buttons |= IN_DUCK;
											if(IsWeaponSlotActive(client, 2))
											{
												buttons |= IN_ATTACK;
											}
											else
											{
												TF2_AddCondition(client, TFCond_RestrictToMelee, TFCondDuration_Infinite);
												TF2_AddCondition(client, TFCond_MeleeOnly, 0.1);
												TF2_RemoveCondition(client, TFCond_MeleeOnly);
											}
											if(GetVectorDistance(engiOrigin, sentrypos) > 50.0)
											{
												TF2_MoveTo(client, sentrypos, vel, angles);
											}
										}
										
										if (!(PF_Exists(client))) 
										{
											PF_Create(client, 24.0, 72.0, 1000.0, 0.6, MASK_PLAYERSOLID, 300.0, 1.0, 1.5);
										}
										
										PF_SetGoalEntity(client, sentry);
										
										PF_StartPathing(client);
										
										PF_EnableCallback(client, PFCB_Approach, Approach);
										
										if(!IsPlayerAlive(client) || !PF_Exists(client))
											return Plugin_Continue;
										
										if(GetVectorDistance(engiOrigin, sentrypos) > 100.0)
										{
											TF2_MoveTo(client, g_flGoal[client], vel, angles);
										}
										else
										{
											PF_StopPathing(client);
										}
									}
									
									if(g_bBuildDispenser[client])
									{
										if (!(PF_Exists(client))) 
										{
											PF_Create(client, 24.0, 72.0, 1000.0, 0.6, MASK_PLAYERSOLID, 300.0, 1.0, 1.5);
										}
										
										float sentrypos[3];
										GetEntPropVector(sentry, Prop_Send, "m_vecOrigin", sentrypos);
										
										float putdispenserpos[3];
										
										putdispenserpos[0] = sentrypos[0] + GetRandomFloat(-500.0, 500.0);
										putdispenserpos[1] = sentrypos[1] + GetRandomFloat(-500.0, 500.0);
										putdispenserpos[2] = sentrypos[2] + GetRandomFloat(-500.0, 500.0);
										
										PF_SetGoalVector(client, putdispenserpos);
										
										PF_StartPathing(client);
										
										PF_EnableCallback(client, PFCB_Approach, Approach);
										
										if(!IsPlayerAlive(client) || !PF_Exists(client))
											return Plugin_Continue;
										
										if(GetVectorDistance(engiOrigin, putdispenserpos) < GetRandomFloat(50.0, 150.0))
										{
											if(IsWeaponSlotActive(client, 5))
											{
												buttons |= IN_ATTACK;
											}
											else
											{
												FakeClientCommandThrottled(client, "build 0");
												TF2_RemoveCondition(client, TFCond_RestrictToMelee);
											}
										}
										
										TF2_MoveTo(client, g_flGoal[client], vel, angles);
									}
									
									if(g_bRepairDispenser[client])
									{
										float dispenserpos[3];
										GetEntPropVector(dispenser, Prop_Send, "m_vecOrigin", dispenserpos);
										
										float camangle[3];
										float fEntityLocation[3];
										float vec[3];
										float angle[3];
										GetEntPropVector(dispenser, Prop_Send, "m_vecOrigin", fEntityLocation);
										GetEntPropVector(dispenser, Prop_Data, "m_angRotation", angle);
										fEntityLocation[2] += 15.0;
										MakeVectorFromPoints(fEntityLocation, clientEyes, vec);
										GetVectorAngles(vec, camangle);
										camangle[0] *= -1.0;
										camangle[1] += 180.0;
										ClampAngle(camangle);
										
										if(GetVectorDistance(engiOrigin, dispenserpos) < 150.0)
										{
											TeleportEntity(client, NULL_VECTOR, camangle, NULL_VECTOR);
											buttons |= IN_DUCK;
											if(IsWeaponSlotActive(client, 2))
											{
												buttons |= IN_ATTACK;
											}
											else
											{
												TF2_AddCondition(client, TFCond_RestrictToMelee, TFCondDuration_Infinite);
												TF2_AddCondition(client, TFCond_MeleeOnly, 0.1);
												TF2_RemoveCondition(client, TFCond_MeleeOnly);
											}
											if(GetVectorDistance(engiOrigin, dispenserpos) > 50.0)
											{
												TF2_MoveTo(client, dispenserpos, vel, angles);
											}
										}
										
										if (!(PF_Exists(client))) 
										{
											PF_Create(client, 24.0, 72.0, 1000.0, 0.6, MASK_PLAYERSOLID, 300.0, 1.0, 1.5);
										}
										
										PF_SetGoalVector(client, dispenserpos);
										
										PF_StartPathing(client);
										
										PF_EnableCallback(client, PFCB_Approach, Approach);
										
										if(!IsPlayerAlive(client) || !PF_Exists(client))
											return Plugin_Continue;
										
										if(GetVectorDistance(engiOrigin, dispenserpos) > 100.0)
										{
											TF2_MoveTo(client, g_flGoal[client], vel, angles);
										}
										else
										{
											PF_StopPathing(client);
										}
									}
								}
							}
					}
				}
				else if(StrContains(currentMap, "plr_" , false) != -1)
				{
					if(class == TFClass_Engineer && !g_bHealthIsLow[client] && !g_bAmmoIsLow[client])
					{
							int flag;
							while((flag = FindEntityByClassname(flag, "item_teamflag")) != INVALID_ENT_REFERENCE) // if you using plr bots plugin (and if plugin spawning flag) = this works
							{
								int iTeamNumObj = GetEntProp(flag, Prop_Send, "m_iTeamNum");
								if(IsValidEntity(flag) && GetClientTeam(client) == iTeamNumObj)
								{
									float engiOrigin[3];
									float flagpos[3];
									GetClientAbsOrigin(client, engiOrigin);
									GetEntPropVector(flag, Prop_Send, "m_vecOrigin", flagpos);
									
									flagpos[2] += 100.0;
									
									int FlagStatus = GetEntProp(flag, Prop_Send, "m_nFlagStatus");
									
									//PrintToServer("FlagStatus %i", FlagStatus);
									
									if(g_bBuildSentry[client])
									{
										if(FlagStatus == 0 || FlagStatus == 1 || FlagStatus == 2)
										{
											if (!(PF_Exists(client))) 
											{
												PF_Create(client, 24.0, 72.0, 1000.0, 0.6, MASK_PLAYERSOLID, 300.0, 1.0, 1.5);
											}
											
											PF_SetGoalVector(client, flagpos);
											
											PF_StartPathing(client);
											
											PF_EnableCallback(client, PFCB_Approach, Approach);
											
											if(!IsPlayerAlive(client) || !PF_Exists(client))
												return Plugin_Continue;
											
											if(GetVectorDistance(engiOrigin, flagpos) < GetRandomFloat(200.0, 1200.0) && IsPointVisible(clientEyes, flagpos))
											{
												if(IsWeaponSlotActive(client, 5))
												{
													buttons |= IN_ATTACK;
												}
												else
												{
													FakeClientCommandThrottled(client, "build 2");
													TF2_RemoveCondition(client, TFCond_RestrictToMelee);
												}
											}
											
											TF2_MoveTo(client, g_flGoal[client], vel, angles);
										}
									}
									
									if(g_bIdleTime[client] || g_bRepairSentry[client])
									{
										float sentrypos[3];
										GetEntPropVector(sentry, Prop_Send, "m_vecOrigin", sentrypos);
										
										float camangle[3];
										float fEntityLocation[3];
										float vec[3];
										float angle[3];
										GetEntPropVector(sentry, Prop_Send, "m_vecOrigin", fEntityLocation);
										GetEntPropVector(sentry, Prop_Data, "m_angRotation", angle);
										fEntityLocation[2] += 15.0;
										MakeVectorFromPoints(fEntityLocation, clientEyes, vec);
										GetVectorAngles(vec, camangle);
										camangle[0] *= -1.0;
										camangle[1] += 180.0;
										ClampAngle(camangle);
										
										if(GetVectorDistance(engiOrigin, sentrypos) < 150.0)
										{
											TeleportEntity(client, NULL_VECTOR, camangle, NULL_VECTOR);
											buttons |= IN_DUCK;
											if(IsWeaponSlotActive(client, 2))
											{
												buttons |= IN_ATTACK;
											}
											else
											{
												TF2_AddCondition(client, TFCond_RestrictToMelee, TFCondDuration_Infinite);
												TF2_AddCondition(client, TFCond_MeleeOnly, 0.1);
												TF2_RemoveCondition(client, TFCond_MeleeOnly);
											}
											if(GetVectorDistance(engiOrigin, sentrypos) > 50.0)
											{
												TF2_MoveTo(client, sentrypos, vel, angles);
											}
										}
										
										if (!(PF_Exists(client))) 
										{
											PF_Create(client, 24.0, 72.0, 1000.0, 0.6, MASK_PLAYERSOLID, 300.0, 1.0, 1.5);
										}
										
										PF_SetGoalEntity(client, sentry);
										
										PF_StartPathing(client);
										
										PF_EnableCallback(client, PFCB_Approach, Approach);
										
										if(!IsPlayerAlive(client) || !PF_Exists(client))
											return Plugin_Continue;
										
										if(GetVectorDistance(engiOrigin, sentrypos) > 100.0)
										{
											TF2_MoveTo(client, g_flGoal[client], vel, angles);
										}
										else
										{
											PF_StopPathing(client);
										}
									}
									
									if(g_bBuildDispenser[client])
									{
										if (!(PF_Exists(client))) 
										{
											PF_Create(client, 24.0, 72.0, 1000.0, 0.6, MASK_PLAYERSOLID, 300.0, 1.0, 1.5);
										}
										
										float sentrypos[3];
										GetEntPropVector(sentry, Prop_Send, "m_vecOrigin", sentrypos);
										
										float putdispenserpos[3];
										
										putdispenserpos[0] = sentrypos[0] + GetRandomFloat(-500.0, 500.0);
										putdispenserpos[1] = sentrypos[1] + GetRandomFloat(-500.0, 500.0);
										putdispenserpos[2] = sentrypos[2] + GetRandomFloat(-500.0, 500.0);
										
										PF_SetGoalVector(client, putdispenserpos);
										
										PF_StartPathing(client);
										
										PF_EnableCallback(client, PFCB_Approach, Approach);
										
										if(!IsPlayerAlive(client) || !PF_Exists(client))
											return Plugin_Continue;
										
										if(GetVectorDistance(engiOrigin, putdispenserpos) < GetRandomFloat(50.0, 150.0))
										{
											if(IsWeaponSlotActive(client, 5))
											{
												buttons |= IN_ATTACK;
											}
											else
											{
												FakeClientCommandThrottled(client, "build 0");
												TF2_RemoveCondition(client, TFCond_RestrictToMelee);
											}
										}
										
										TF2_MoveTo(client, g_flGoal[client], vel, angles);
									}
									
									if(g_bRepairDispenser[client])
									{
										float dispenserpos[3];
										GetEntPropVector(dispenser, Prop_Send, "m_vecOrigin", dispenserpos);
										
										float camangle[3];
										float fEntityLocation[3];
										float vec[3];
										float angle[3];
										GetEntPropVector(dispenser, Prop_Send, "m_vecOrigin", fEntityLocation);
										GetEntPropVector(dispenser, Prop_Data, "m_angRotation", angle);
										fEntityLocation[2] += 15.0;
										MakeVectorFromPoints(fEntityLocation, clientEyes, vec);
										GetVectorAngles(vec, camangle);
										camangle[0] *= -1.0;
										camangle[1] += 180.0;
										ClampAngle(camangle);
										
										if(GetVectorDistance(engiOrigin, dispenserpos) < 150.0)
										{
											TeleportEntity(client, NULL_VECTOR, camangle, NULL_VECTOR);
											buttons |= IN_DUCK;
											if(IsWeaponSlotActive(client, 2))
											{
												buttons |= IN_ATTACK;
											}
											else
											{
												TF2_AddCondition(client, TFCond_RestrictToMelee, TFCondDuration_Infinite);
												TF2_AddCondition(client, TFCond_MeleeOnly, 0.1);
												TF2_RemoveCondition(client, TFCond_MeleeOnly);
											}
											if(GetVectorDistance(engiOrigin, dispenserpos) > 50.0)
											{
												TF2_MoveTo(client, dispenserpos, vel, angles);
											}
										}
										
										if (!(PF_Exists(client))) 
										{
											PF_Create(client, 24.0, 72.0, 1000.0, 0.6, MASK_PLAYERSOLID, 300.0, 1.0, 1.5);
										}
										
										PF_SetGoalVector(client, dispenserpos);
										
										PF_StartPathing(client);
										
										PF_EnableCallback(client, PFCB_Approach, Approach);
										
										if(!IsPlayerAlive(client) || !PF_Exists(client))
											return Plugin_Continue;
										
										if(GetVectorDistance(engiOrigin, dispenserpos) > 100.0)
										{
											TF2_MoveTo(client, g_flGoal[client], vel, angles);
										}
										else
										{
											PF_StopPathing(client);
										}
									}
								}
							}
					}
				}
				else if(StrContains(currentMap, "sd_" , false) != -1)
				{
					if(class == TFClass_Engineer && !g_bHealthIsLow[client] && !g_bAmmoIsLow[client])
					{
							int flag;
							while((flag = FindEntityByClassname(flag, "item_teamflag")) != INVALID_ENT_REFERENCE)
							{
								if(IsValidEntity(flag))
								{
									float engiOrigin[3];
									float flagpos[3];
									GetClientAbsOrigin(client, engiOrigin);
									GetEntPropVector(flag, Prop_Send, "m_vecOrigin", flagpos);
									
									flagpos[2] += 100.0;
									
									int FlagStatus = GetEntProp(flag, Prop_Send, "m_nFlagStatus");
									
									//PrintToServer("FlagStatus %i", FlagStatus);
									
									if(g_bBuildSentry[client])
									{
										if(FlagStatus == 0 || FlagStatus == 1 || FlagStatus == 2)
										{
											if (!(PF_Exists(client))) 
											{
												PF_Create(client, 24.0, 72.0, 1000.0, 0.6, MASK_PLAYERSOLID, 300.0, 1.0, 1.5);
											}
											
											PF_SetGoalVector(client, flagpos);
											
											PF_StartPathing(client);
											
											PF_EnableCallback(client, PFCB_Approach, Approach);
											
											if(!IsPlayerAlive(client) || !PF_Exists(client))
												return Plugin_Continue;
											
											if(GetVectorDistance(engiOrigin, flagpos) < GetRandomFloat(75.0, 750.0))
											{
												if(IsWeaponSlotActive(client, 5))
												{
													buttons |= IN_ATTACK;
												}
												else
												{
													FakeClientCommandThrottled(client, "build 2");
													TF2_RemoveCondition(client, TFCond_RestrictToMelee);
												}
											}
											
											TF2_MoveTo(client, g_flGoal[client], vel, angles);
										}
									}
									
									if(g_bIdleTime[client] || g_bRepairSentry[client])
									{
										float sentrypos[3];
										GetEntPropVector(sentry, Prop_Send, "m_vecOrigin", sentrypos);
										
										float camangle[3];
										float fEntityLocation[3];
										float vec[3];
										float angle[3];
										GetEntPropVector(sentry, Prop_Send, "m_vecOrigin", fEntityLocation);
										GetEntPropVector(sentry, Prop_Data, "m_angRotation", angle);
										fEntityLocation[2] += 15.0;
										MakeVectorFromPoints(fEntityLocation, clientEyes, vec);
										GetVectorAngles(vec, camangle);
										camangle[0] *= -1.0;
										camangle[1] += 180.0;
										ClampAngle(camangle);
										
										if(GetVectorDistance(engiOrigin, sentrypos) < 150.0)
										{
											TeleportEntity(client, NULL_VECTOR, camangle, NULL_VECTOR);
											buttons |= IN_DUCK;
											if(IsWeaponSlotActive(client, 2))
											{
												buttons |= IN_ATTACK;
											}
											else
											{
												TF2_AddCondition(client, TFCond_RestrictToMelee, TFCondDuration_Infinite);
												TF2_AddCondition(client, TFCond_MeleeOnly, 0.1);
												TF2_RemoveCondition(client, TFCond_MeleeOnly);
											}
											if(GetVectorDistance(engiOrigin, sentrypos) > 50.0)
											{
												TF2_MoveTo(client, sentrypos, vel, angles);
											}
										}
										
										if (!(PF_Exists(client))) 
										{
											PF_Create(client, 24.0, 72.0, 1000.0, 0.6, MASK_PLAYERSOLID, 300.0, 1.0, 1.5);
										}
										
										PF_SetGoalEntity(client, sentry);
										
										PF_StartPathing(client);
										
										PF_EnableCallback(client, PFCB_Approach, Approach);
										
										if(!IsPlayerAlive(client) || !PF_Exists(client))
											return Plugin_Continue;
										
										if(GetVectorDistance(engiOrigin, sentrypos) > 100.0)
										{
											TF2_MoveTo(client, g_flGoal[client], vel, angles);
										}
										else
										{
											PF_StopPathing(client);
										}
									}
									
									if(g_bBuildDispenser[client])
									{
										if (!(PF_Exists(client))) 
										{
											PF_Create(client, 24.0, 72.0, 1000.0, 0.6, MASK_PLAYERSOLID, 300.0, 1.0, 1.5);
										}
										
										float sentrypos[3];
										GetEntPropVector(sentry, Prop_Send, "m_vecOrigin", sentrypos);
										
										float putdispenserpos[3];
										
										putdispenserpos[0] = sentrypos[0] + GetRandomFloat(-500.0, 500.0);
										putdispenserpos[1] = sentrypos[1] + GetRandomFloat(-500.0, 500.0);
										putdispenserpos[2] = sentrypos[2] + GetRandomFloat(-500.0, 500.0);
										
										PF_SetGoalVector(client, putdispenserpos);
										
										PF_StartPathing(client);
										
										PF_EnableCallback(client, PFCB_Approach, Approach);
										
										if(!IsPlayerAlive(client) || !PF_Exists(client))
											return Plugin_Continue;
										
										if(GetVectorDistance(engiOrigin, putdispenserpos) < GetRandomFloat(50.0, 150.0))
										{
											if(IsWeaponSlotActive(client, 5))
											{
												buttons |= IN_ATTACK;
											}
											else
											{
												FakeClientCommandThrottled(client, "build 0");
												TF2_RemoveCondition(client, TFCond_RestrictToMelee);
											}
										}
										
										TF2_MoveTo(client, g_flGoal[client], vel, angles);
									}
									
									if(g_bRepairDispenser[client])
									{
										float dispenserpos[3];
										GetEntPropVector(dispenser, Prop_Send, "m_vecOrigin", dispenserpos);
										
										float camangle[3];
										float fEntityLocation[3];
										float vec[3];
										float angle[3];
										GetEntPropVector(dispenser, Prop_Send, "m_vecOrigin", fEntityLocation);
										GetEntPropVector(dispenser, Prop_Data, "m_angRotation", angle);
										fEntityLocation[2] += 15.0;
										MakeVectorFromPoints(fEntityLocation, clientEyes, vec);
										GetVectorAngles(vec, camangle);
										camangle[0] *= -1.0;
										camangle[1] += 180.0;
										ClampAngle(camangle);
										
										if(GetVectorDistance(engiOrigin, dispenserpos) < 150.0)
										{
											TeleportEntity(client, NULL_VECTOR, camangle, NULL_VECTOR);
											buttons |= IN_DUCK;
											if(IsWeaponSlotActive(client, 2))
											{
												buttons |= IN_ATTACK;
											}
											else
											{
												TF2_AddCondition(client, TFCond_RestrictToMelee, TFCondDuration_Infinite);
												TF2_AddCondition(client, TFCond_MeleeOnly, 0.1);
												TF2_RemoveCondition(client, TFCond_MeleeOnly);
											}
											if(GetVectorDistance(engiOrigin, dispenserpos) > 50.0)
											{
												TF2_MoveTo(client, dispenserpos, vel, angles);
											}
										}
										
										if (!(PF_Exists(client))) 
										{
											PF_Create(client, 24.0, 72.0, 1000.0, 0.6, MASK_PLAYERSOLID, 300.0, 1.0, 1.5);
										}
										
										PF_SetGoalVector(client, dispenserpos);
										
										PF_StartPathing(client);
										
										PF_EnableCallback(client, PFCB_Approach, Approach);
										
										if(!IsPlayerAlive(client) || !PF_Exists(client))
											return Plugin_Continue;
										
										if(GetVectorDistance(engiOrigin, dispenserpos) > 100.0)
										{
											TF2_MoveTo(client, g_flGoal[client], vel, angles);
										}
										else
										{
											PF_StopPathing(client);
										}
									}
								}
							}
					}
				}
				
				if(TF2_HasTheFlag(client) && StrContains(currentMap, "ctf_" , false) != -1)
				{
					if(GetClientTeam(client) == 2)
					{
						if (!(PF_Exists(client))) 
						{
							PF_Create(client, 24.0, 72.0, 1000.0, 0.6, MASK_PLAYERSOLID, 300.0, 1.0, 1.5);
						}
						
						PF_SetGoalVector(client, g_flRedFlagCapPoint);
						
						PF_StartPathing(client);
						
						PF_EnableCallback(client, PFCB_Approach, Approach);
						
						if(!IsPlayerAlive(client) || !PF_Exists(client))
							return Plugin_Continue;
						
						TF2_MoveTo(client, g_flGoal[client], vel, angles);
					}
					else
					{
						if (!(PF_Exists(client))) 
						{
							PF_Create(client, 24.0, 72.0, 1000.0, 0.6, MASK_PLAYERSOLID, 300.0, 1.0, 1.5);
						}
						
						PF_SetGoalVector(client, g_flBluFlagCapPoint);
						
						PF_StartPathing(client);
						
						PF_EnableCallback(client, PFCB_Approach, Approach);
						
						if(!IsPlayerAlive(client) || !PF_Exists(client))
							return Plugin_Continue;
						
						TF2_MoveTo(client, g_flGoal[client], vel, angles);
					}
				}
				else if(TF2_HasTheFlag(client))
				{
					if(StrContains(currentMap, "sd_" , false) != -1)
					{
						int capzone;
						while((capzone = FindEntityByClassname(capzone, "func_capturezone")) != INVALID_ENT_REFERENCE)
						{
							if(IsValidEntity(capzone))
							{
								float cappos[3];
								GetEntPropVector(capzone, Prop_Send, "m_vecOrigin", cappos);
								
								if (!(PF_Exists(client))) 
								{
									PF_Create(client, 24.0, 72.0, 1000.0, 0.6, MASK_PLAYERSOLID, 300.0, 1.0, 1.5);
								}
								
								PF_SetGoalVector(client, cappos);
								
								PF_StartPathing(client);
								
								PF_EnableCallback(client, PFCB_Approach, Approach);
								
								if(!IsPlayerAlive(client) || !PF_Exists(client))
									return Plugin_Continue;
								
								TF2_MoveTo(client, g_flGoal[client], vel, angles);
							}
						}
					}
				}
			}
		}
	}
	
	return Plugin_Continue;
}

public int GetNearestEntity(int client, char[] classname)
{    
	float clientOrigin[3];
	float entityOrigin[3];
	float distance = -1.0;
	int nearestEntity = -1;
	int entity = -1;
	while((entity = FindEntityByClassname(entity, classname)) != INVALID_ENT_REFERENCE)
	{
		if(IsValidEntity(entity))
		{
			GetEntPropVector(entity, Prop_Data, "m_vecOrigin", entityOrigin);
			GetClientAbsOrigin(client, clientOrigin);
			
			float edict_distance = GetVectorDistance(clientOrigin, entityOrigin);
			if((edict_distance < distance) || (distance == -1.0))
			{
				distance = edict_distance;
				nearestEntity = entity;
			}
		}
	}
	return nearestEntity;
}

public Action BotSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int botid = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(IsFakeClient(botid))
	{
		if(TF2_GetPlayerClass(botid) == TFClass_Engineer)
		{
			EquipWeaponSlot(botid, 2);
			g_bPickUnUsedSentrySpot[botid] = true;
			g_flWaitJumpTimer[botid] = GetGameTime() + 10.0;
			//g_AttackPlayers[botid] = false;
		}
	}
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

stock void TF2_LookAtPos(int client, float flGoal[3], float flAimSpeed = 0.05)
{
	float flPos[3];
	GetClientEyePosition(client, flPos);

	float flAng[3];
	GetClientEyeAngles(client, flAng);
	
	// get normalised direction from target to client
	float desired_dir[3];
	MakeVectorFromPoints(flPos, flGoal, desired_dir);
	GetVectorAngles(desired_dir, desired_dir);
	
	// ease the current direction to the target direction
	flAng[0] += AngleNormalize(desired_dir[0] - flAng[0]) * flAimSpeed;
	flAng[1] += AngleNormalize(desired_dir[1] - flAng[1]) * flAimSpeed;

	TeleportEntity(client, NULL_VECTOR, flAng, NULL_VECTOR);
}

stock int AngleDifference(float angle1, float angle2)
{
	int diff = RoundToNearest((angle2 - angle1 + 180)) % 360 - 180;
	return diff < -180 ? diff + 360 : diff;
}

stock float AngleNormalize(float angle)
{
	angle = fmodf(angle, 360.0);
	if (angle > 180) 
	{
		angle -= 360;
	}
	if (angle < -180)
	{
		angle += 360;
	}
	
	return angle;
}

stock float fmodf(float number, float denom)
{
	return number - RoundToFloor(number / denom) * denom;
}

stock int TF2_GetNumHealers(int client)
{
    return GetEntProp(client, Prop_Send, "m_nNumHealers");
}

stock bool IsPointVisible(float start[3], float end[3])
{
	TR_TraceRayFilter(start, end, MASK_SOLID_BRUSHONLY, RayType_EndPoint, TraceEntityFilterStuff);
	return TR_GetFraction() >= 0.99;
}

public bool TraceEntityFilterStuff(int entity, int mask)
{
	return entity > MaxClients;
} 

stock int GetHealth(int client)
{
	return GetEntProp(client, Prop_Send, "m_iHealth");
}

stock int GetMetal(int client)
{
	return GetEntProp(client, Prop_Data, "m_iAmmo", 4, 3);
}

stock void EquipWeaponSlot(int client, int slot)
{
	int iWeapon = GetPlayerWeaponSlot(client, slot);
	if(IsValidEntity(iWeapon))
		EquipWeapon(client, iWeapon);
}

stock void EquipWeapon(int client, int weapon)
{
	char class[80];
	GetEntityClassname(weapon, class, sizeof(class));

	Format(class, sizeof(class), "use %s", class);

	FakeClientCommandThrottled(client, class);
//	SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
}

float g_flNextCommand[MAXPLAYERS + 1];
stock bool FakeClientCommandThrottled(int client, const char[] command)
{
	if(g_flNextCommand[client] > GetGameTime())
		return false;
	
	FakeClientCommand(client, command);
	
	g_flNextCommand[client] = GetGameTime() + 0.4;
	
	return true;
}

stock bool IsWeaponSlotActive(int client, int slot)
{
    return GetPlayerWeaponSlot(client, slot) == GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
}

stock void ClampAngle(float fAngles[3])
{
	while(fAngles[0] > 89.0)  fAngles[0]-=360.0;
	while(fAngles[0] < -89.0) fAngles[0]+=360.0;
	while(fAngles[1] > 180.0) fAngles[1]-=360.0;
	while(fAngles[1] <-180.0) fAngles[1]+=360.0;
}

stock int TF2_GetObject(int client, TFObjectType type)
{
	int iObject = INVALID_ENT_REFERENCE;
	while ((iObject = FindEntityByClassname(iObject, "obj_*")) != -1)
	{
		TFObjectType iObjType = TF2_GetObjectType(iObject);
		
		if(GetEntPropEnt(iObject, Prop_Send, "m_hBuilder") == client && iObjType == type 
		&& !GetEntProp(iObject, Prop_Send, "m_bPlacing")
		&& !GetEntProp(iObject, Prop_Send, "m_bDisposableBuilding"))
		{			
			return iObject;
		}
	}
	
	return iObject;
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

bool IsValidClient(int client)
{
	if(!(1 <= client <= MaxClients) || !IsClientInGame(client))
	{
		return false;
	}
	return true;
}

// Thank u Guren
stock bool IsTargetInSightRange(int client,int target, float angle=90.0, float distance=0.0, bool heightcheck=true, bool negativeangle=false)
{
	if(angle > 360.0 || angle < 0.0)
		ThrowError("Angle Max : 360 & Min : 0. %d isn't proper angle.", angle);
		
	float clientpos[3]; 
	float targetpos[3];
	float anglevector[3]; 
	float targetvector[3];
	float resultangle;
	float resultdistance;
	
	GetClientEyeAngles(client, anglevector);
	anglevector[0] = anglevector[2] = 0.0;
	GetAngleVectors(anglevector, anglevector, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(anglevector, anglevector);
	if(negativeangle)
		NegateVector(anglevector);

	GetClientAbsOrigin(client, clientpos);
	GetClientAbsOrigin(target, targetpos);
	if(heightcheck && distance > 0)
		resultdistance = GetVectorDistance(clientpos, targetpos);
	clientpos[2] = targetpos[2] = 0.0;
	MakeVectorFromPoints(clientpos, targetpos, targetvector);
	NormalizeVector(targetvector, targetvector);
	
	resultangle = RadToDeg(ArcCosine(GetVectorDotProduct(targetvector, anglevector)));
	
	if(resultangle <= angle/2)	
	{
		if(distance > 0)
		{
			if(!heightcheck)
				resultdistance = GetVectorDistance(clientpos, targetpos);
			if(distance >= resultdistance)
				return true;
			else
				return false;
		}
		else
			return true;
	}
	else
		return false;
}

bool IsClientMoving(int client){
     float buffer[3];
     GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", buffer);
     return (GetVectorLength(buffer) > 5.0);
}  