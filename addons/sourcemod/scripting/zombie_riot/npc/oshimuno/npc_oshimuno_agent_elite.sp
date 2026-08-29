#pragma semicolon 1
#pragma newdecls required

static const char g_DeathSounds[][] = 
{
	"vo/engineer_paincrticialdeath01.mp3",
	"vo/engineer_paincrticialdeath02.mp3",
	"vo/engineer_paincrticialdeath03.mp3",
};

static const char g_HurtSounds[][] = 
{
	"vo/engineer_painsharp01.mp3",
	"vo/engineer_painsharp02.mp3",
	"vo/engineer_painsharp03.mp3",
	"vo/engineer_painsharp04.mp3",
	"vo/engineer_painsharp05.mp3",
	"vo/engineer_painsharp06.mp3",
	"vo/engineer_painsharp07.mp3",
	"vo/engineer_painsharp08.mp3",
};

static const char g_IdleAlertedSounds[][] = 
{
	"vo/engineer_battlecry01.mp3",
	"vo/engineer_battlecry03.mp3",
	"vo/engineer_battlecry04.mp3",
	"vo/engineer_battlecry05.mp3",
};

static const char g_RangedAttackSounds[][] = 
{
	"weapons/pistol/pistol_fire2.wav"
};


void OshimunoAgentEliteOnMapStart()
{
	PrecacheSoundArray(g_DeathSounds);
	PrecacheSoundArray(g_HurtSounds);
	PrecacheSoundArray(g_IdleAlertedSounds);
	PrecacheSoundArray(g_RangedAttackSounds);
	NPCData data;
	strcopy(data.Name, sizeof(data.Name), "Tarakeno Elite Agent");
	strcopy(data.Plugin, sizeof(data.Plugin), "npc_oshimuno_agent_elite");
	strcopy(data.Icon, sizeof(data.Icon), "engineer");
	data.IconCustom = true;
	data.Flags = 0;
	data.Category = Type_Dancer;
	data.Func = ClotSummon;
	NPC_Add(data);
}

static any ClotSummon(int client, float vecPos[3], float vecAng[3], int team)
{
	return OshimunoAgentElite(vecPos, vecAng, team);
}

methodmap OshimunoAgentElite < CClotBody
{
	public void PlayIdleSound()
	{
		if(this.m_flNextIdleSound > GetGameTime(this.index))
			return;
		
		EmitSoundToAll(g_IdleAlertedSounds[GetRandomInt(0, sizeof(g_IdleAlertedSounds) - 1)], this.index, SNDCHAN_VOICE, NORMAL_ZOMBIE_SOUNDLEVEL, _, NORMAL_ZOMBIE_VOLUME);
		this.m_flNextIdleSound = GetGameTime(this.index) + GetRandomFloat(12.0, 24.0);
	}
	public void PlayHurtSound()
	{
		EmitSoundToAll(g_HurtSounds[GetRandomInt(0, sizeof(g_HurtSounds) - 1)], this.index, SNDCHAN_VOICE, NORMAL_ZOMBIE_SOUNDLEVEL, _, NORMAL_ZOMBIE_VOLUME);
	}
	public void PlayDeathSound() 
	{
		EmitSoundToAll(g_DeathSounds[GetRandomInt(0, sizeof(g_DeathSounds) - 1)], this.index, SNDCHAN_VOICE, NORMAL_ZOMBIE_SOUNDLEVEL, _, NORMAL_ZOMBIE_VOLUME);
	}
	public void PlayRangedSound()
	{
		EmitSoundToAll(g_RangedAttackSounds[GetRandomInt(0, sizeof(g_RangedAttackSounds) - 1)], this.index, SNDCHAN_AUTO, NORMAL_ZOMBIE_SOUNDLEVEL, _, NORMAL_ZOMBIE_VOLUME);
	}
	
	public OshimunoAgentElite(float vecPos[3], float vecAng[3], int ally)
	{
		OshimunoAgentElite npc = view_as<OshimunoAgentElite>(CClotBody(vecPos, vecAng, "models/player/engineer.mdl", "1.0", "1000", ally));
		
		i_NpcWeight[npc.index] = 1;
		npc.SetActivity("ACT_MP_RUN_SECONDARY");
		KillFeed_SetKillIcon(npc.index, "pistol");
		
		npc.m_iBleedType = BLEEDTYPE_NORMAL;
		npc.m_iStepNoiseType = STEPSOUND_NORMAL;
		npc.m_iNpcStepVariation = STEPTYPE_NORMAL;
		

		func_NPCDeath[npc.index] = ClotDeath;
		func_NPCOnTakeDamage[npc.index] = Generic_OnTakeDamage;
		func_NPCThink[npc.index] = ClotThink;
		
		npc.m_flSpeed = 270.0;
		npc.m_iState = 0; // 0 walking normally || 1 standing still to shoot
		npc.m_iOverlordComboAttack = 0; // counter for increasing attack speed

		npc.m_iWearable1 = npc.EquipItem("head", "models/workshop/weapons/c_models/c_invasion_pistol/c_invasion_pistol.mdl");
		SetEntProp(npc.m_iWearable1, Prop_Send, "m_nSkin", 1);

		npc.m_iWearable2 = npc.EquipItem("head", "models/workshop/player/items/engineer/sum24_desk_engineer_style1/sum24_desk_engineer_style1.mdl");
		SetEntProp(npc.m_iWearable2, Prop_Send, "m_nSkin", 1);

		npc.m_iWearable3 = npc.EquipItem("head", "models/workshop/player/items/engineer/eotl_winter_pants/eotl_winter_pants.mdl");
		SetEntProp(npc.m_iWearable3, Prop_Send, "m_nSkin", 1);

		npc.m_iWearable4 = npc.EquipItem("head", "models/workshop/player/items/all_class/hwn2022_onimann/hwn2022_onimann_engineer.mdl");
		SetEntProp(npc.m_iWearable4, Prop_Send, "m_nSkin", 1);

		npc.m_iWearable5 = npc.EquipItem("head", "models/workshop/player/items/all_class/hwn2024_spider_sights/hwn2024_spider_sights_engineer.mdl");
		SetEntProp(npc.m_iWearable5, Prop_Send, "m_nSkin", 1);

		SetEntProp(npc.index, Prop_Send, "m_nSkin", 1);
		SetVariantInt(1);
		AcceptEntityInput(npc.index, "SetBodyGroup");

		npc.StartPathing();
		return npc;
	}
}

static void ClotThink(int iNPC)
{
	OshimunoAgentElite npc = view_as<OshimunoAgentElite>(iNPC);

	float gameTime = GetGameTime(npc.index);
	if(npc.m_flNextDelayTime > gameTime)
		return;
	
	npc.m_flNextDelayTime = gameTime + DEFAULT_UPDATE_DELAY_FLOAT;
	npc.Update();

	if(npc.m_blPlayHurtAnimation)
	{
		npc.AddGesture("ACT_MP_GESTURE_FLINCH_CHEST", false);
		npc.PlayHurtSound();
		npc.m_blPlayHurtAnimation = false;
	}
	
	if(npc.m_flNextThinkTime > gameTime)
		return;
	
	npc.m_flNextThinkTime = gameTime + 0.1;

	int target = npc.m_iTarget;
	if(i_Target[npc.index] != -1 && !IsValidEnemy(npc.index, target))
		i_Target[npc.index] = -1;
	
	if(i_Target[npc.index] == -1 || npc.m_flGetClosestTargetTime < gameTime)
	{
		target = GetClosestTarget(npc.index);
		npc.m_iTarget = target;
		npc.m_flGetClosestTargetTime = gameTime + GetRandomRetargetTime();
	}
	
	if(target > 0)
	{
		float vecTarget[3]; WorldSpaceCenter(target, vecTarget);
		float VecSelfNpc[3]; WorldSpaceCenter(npc.index, VecSelfNpc);
		float distance = GetVectorDistance(vecTarget, VecSelfNpc, true);	
		
		if(distance < npc.GetLeadRadius())
		{
			float vPredictedPos[3]; PredictSubjectPosition(npc, target,_,_, vPredictedPos);
			npc.SetGoalVector(vPredictedPos);
		}
		else 
		{
			npc.SetGoalEntity(target);
		}
		OshimunoAgentEliteSelfDefense(npc, distance, vecTarget, gameTime); 
	}
	
	npc.PlayIdleSound();
}

void OshimunoAgentEliteSelfDefense(OshimunoAgentElite npc, float distance, float vecTarget[3], float gameTime)
{
	int target;
	target = npc.m_iTarget;
	if(!IsValidEnemy(npc.index,target))
	{
		if(npc.m_iState != 0)
		{
			npc.m_bisWalking = true;
			npc.m_iState = 0;
			npc.m_iOverlordComboAttack = 0;
			npc.SetActivity("ACT_MP_RUN_SECONDARY");
			npc.m_flSpeed = 270.0;
			npc.StartPathing();
		}
		return;
	}
	if(distance < (NORMAL_ENEMY_MELEE_RANGE_FLOAT_SQUARED * 8.0))
	{
		int Enemy_I_See = Can_I_See_Enemy(npc.index, npc.m_iTarget);
		
					
		if(IsValidEnemy(npc.index, Enemy_I_See))
		{
			if(npc.m_iState != 1)
			{
				npc.m_bisWalking = false;
				npc.m_iState = 1;
				npc.SetActivity("ACT_MP_STAND_SECONDARY");
				npc.m_flSpeed = 0.0;
				npc.StopPathing();
			}	
			if(npc.m_flNextRangedAttack < gameTime)
			{
				if(distance < (NORMAL_ENEMY_MELEE_RANGE_FLOAT_SQUARED * 10.0))
				{	
					npc.AddGesture("ACT_MP_ATTACK_STAND_SECONDARY", true);
					npc.PlayRangedSound();
					npc.FaceTowards(vecTarget, 20000.0);
					Handle swingTrace;
					if(npc.DoSwingTrace(swingTrace, target, { 9999.0, 9999.0, 9999.0 }))
					{
						target = TR_GetEntityIndex(swingTrace);	

						float vecHit[3];
						TR_GetEndPosition(vecHit, swingTrace);
						float origin[3], angles[3];
						view_as<CClotBody>(npc.m_iWearable1).GetAttachment("muzzle", origin, angles);
						ShootLaser(npc.m_iWearable1, "bullet_tracer02_blue_crit", origin, vecHit, false );

						if(IsValidEnemy(npc.index, target))
						{
							float damage = 12.0;
							SDKHooks_TakeDamage(target, npc.index, npc.index, damage, DMG_BULLET, -1, _, vecHit);
							CPrintToChatAll("debug-current stacks is:%i ", npc.m_iOverlordComboAttack);
							if(npc.m_iOverlordComboAttack <= 19) //increment counter
							{
								npc.m_iOverlordComboAttack++;
							}
						}
					}
					delete swingTrace;
					float AttackCooldown = 0.25 - npc.m_iOverlordComboAttack * 0.01; //the longer he stands still the faster he shoots (capped at 20 stacks and 0.05 delay)
					npc.m_flNextRangedAttack = gameTime + AttackCooldown;
				}
			}
		}
		else
		{
			if(npc.m_iState != 0)
			{
				npc.m_bisWalking = true;
				npc.m_iState = 0;
				npc.m_iOverlordComboAttack = 0;
				npc.SetActivity("ACT_MP_RUN_SECONDARY");
				npc.m_flSpeed = 270.0;
				npc.StartPathing();
			}
		}
	}
	else
	{
		if(npc.m_iState != 0)
		{
			npc.m_bisWalking = true;
			npc.m_iState = 0;
			npc.m_iOverlordComboAttack = 0;
			npc.SetActivity("ACT_MP_RUN_SECONDARY");
			npc.m_flSpeed = 270.0;
			npc.StartPathing();
		}
	}
}
static void ClotDeath(int entity)
{
	OshimunoAgentElite npc = view_as<OshimunoAgentElite>(entity);

	if(!npc.m_bGib)
		npc.PlayDeathSound();
	
	if(IsValidEntity(npc.m_iWearable1))
		RemoveEntity(npc.m_iWearable1);
	
	if(IsValidEntity(npc.m_iWearable2))
		RemoveEntity(npc.m_iWearable2);
	
	if(IsValidEntity(npc.m_iWearable3))
		RemoveEntity(npc.m_iWearable3);
	
	if(IsValidEntity(npc.m_iWearable4))
		RemoveEntity(npc.m_iWearable4);
	
	if(IsValidEntity(npc.m_iWearable9))
		RemoveEntity(npc.m_iWearable9);
}