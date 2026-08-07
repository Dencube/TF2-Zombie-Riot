#pragma semicolon 1
#pragma newdecls required //TODO:dont know how to remove the engineer's hat even tho he has different cosmetics on

static const char g_DeathSounds[][] =
{
	"vo/heavy_paincrticialdeath01.mp3",
	"vo/heavy_paincrticialdeath02.mp3",
	"vo/heavy_paincrticialdeath03.mp3"
};

static const char g_HurtSounds[][] =
{
	"vo/heavy_painsharp01.mp3",
	"vo/heavy_painsharp02.mp3",
	"vo/heavy_painsharp03.mp3",
	"vo/heavy_painsharp04.mp3",
	"vo/heavy_painsharp05.mp3",
};

static const char g_IdleAlertedSounds[][] =
{
	"vo/taunts/soldier_taunts19.mp3",
	"vo/taunts/soldier_taunts20.mp3",
	"vo/taunts/soldier_taunts21.mp3",
	"vo/taunts/soldier_taunts18.mp3"
};

static const char g_MeleeHitSounds[][] =
{
	"weapons/cbar_hit1.wav",
	"weapons/cbar_hit2.wav"
};

static const char g_MeleeAttackSounds[][] =
{
	"weapons/pickaxe_swing1.wav",
	"weapons/pickaxe_swing2.wav",
	"weapons/pickaxe_swing3.wav"
};

static float LiberiBuff[MAXENTITIES];

void OshimunoDJOnMapStart()
{
	PrecacheSoundArray(g_DeathSounds);
	PrecacheSoundArray(g_HurtSounds);
	PrecacheSoundArray(g_IdleAlertedSounds);
	PrecacheSoundArray(g_MeleeHitSounds);
	PrecacheSoundArray(g_MeleeAttackSounds);
	NPCData data;
	strcopy(data.Name, sizeof(data.Name), "Oshimuno DJ");
	strcopy(data.Plugin, sizeof(data.Plugin), "npc_oshimuno_dj");
	strcopy(data.Icon, sizeof(data.Icon), "victoria_basebreaker");
	data.IconCustom = true;
	data.Flags = 0;
	data.Category = Type_Outlaws;
	data.Func = ClotSummon;
	NPC_Add(data);
}

static any ClotSummon(int client, float vecPos[3], float vecAng[3], int team)
{
	return OshimunoDJ(vecPos, vecAng, team);
}

methodmap OshimunoDJ < CClotBody
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
	public void PlayMeleeSound()
 	{
		EmitSoundToAll(g_MeleeAttackSounds[GetRandomInt(0, sizeof(g_MeleeAttackSounds) - 1)], this.index, SNDCHAN_AUTO, NORMAL_ZOMBIE_SOUNDLEVEL, _, NORMAL_ZOMBIE_VOLUME, _);
	}
	public void PlayMeleeHitSound()
	{
		EmitSoundToAll(g_MeleeHitSounds[GetRandomInt(0, sizeof(g_MeleeHitSounds) - 1)], this.index, SNDCHAN_AUTO, NORMAL_ZOMBIE_SOUNDLEVEL, _, NORMAL_ZOMBIE_VOLUME, _);	
	}
	
	public OshimunoDJ(float vecPos[3], float vecAng[3], int ally)
	{
		OshimunoDJ npc = view_as<OshimunoDJ>(CClotBody(vecPos, vecAng, "models/player/engineer.mdl", "1.0", "1000", ally));
		
		i_NpcWeight[npc.index] = 1;
		npc.SetActivity("ACT_MP_RUN_MELEE");
		KillFeed_SetKillIcon(npc.index, "pickaxe");
		
		npc.m_iBleedType = BLEEDTYPE_NORMAL;
		npc.m_iStepNoiseType = STEPSOUND_NORMAL;
		npc.m_iNpcStepVariation = STEPTYPE_NORMAL;
		

		func_NPCDeath[npc.index] = ClotDeath;
		func_NPCOnTakeDamage[npc.index] = Generic_OnTakeDamage;
		func_NPCThink[npc.index] = ClotThink;
		
		npc.m_flSpeed = 300.0;
		npc.m_iOverlordComboAttack = 0;
		Is_a_Medic[npc.index] = true;

		npc.m_iWearable1 = npc.EquipItem("head", "models/workshop/player/items/engineer/hwn2022_cabinet_mann/hwn2022_cabinet_mann.mdl");

		npc.m_iWearable2 = npc.EquipItem("head", "models/workshop/player/items/engineer/hwn2025_technicians_tunic/hwn2025_technicians_tunic.mdl");

		SetEntProp(npc.index, Prop_Send, "m_nSkin", 1);
		SetVariantInt(2);
		AcceptEntityInput(npc.index, "SetBodyGroup");

		npc.StartPathing();
		return npc;
	}
}

static void ClotThink(int iNPC)
{
	OshimunoDJ npc = view_as<OshimunoDJ>(iNPC);
	if(npc.m_iOverlordComboAttack == 2 && IsValidAlly(npc.index, npc.m_iTargetAlly))
	{
		fl_TotalArmor[iNPC] = 0.45;
		//stun target
		float Injured[3];
		GetEntPropVector(npc.index, Prop_Data, "m_vecAbsOrigin", Injured); 
		Injured[2] += 30.0;
		b_NoGravity[npc.m_iTargetAlly] = true;
		b_DoNotUnStuck[npc.m_iTargetAlly] = true;
		ApplyStatusEffect(npc.m_iTargetAlly, npc.m_iTargetAlly, "Solid Stance", 999999.0);	
		
		SDKCall_SetLocalOrigin(npc.m_iTargetAlly, Injured); //keep teleporting just incase.
		LiberiBuff[npc.m_iTargetAlly] = GetGameTime() + 0.09;
		FreezeNpcInTime(npc.m_iTargetAlly, 0.09);
		b_NpcIsInvulnerable[npc.m_iTargetAlly] = true;
		SDKUnhook(npc.m_iTargetAlly, SDKHook_ThinkPost, LiberiBuffThink);
		SDKHook(npc.m_iTargetAlly, SDKHook_ThinkPost, LiberiBuffThink);
	}
	else
	{
		fl_TotalArmor[iNPC] = 1.0;
	}
	if(npc.m_flNextDelayTime > GetGameTime(npc.index))
	{
		return;
	}
	npc.m_flNextDelayTime = GetGameTime(npc.index) + DEFAULT_UPDATE_DELAY_FLOAT;
	npc.Update();

	if(npc.m_blPlayHurtAnimation)
	{
		npc.AddGesture("ACT_MP_GESTURE_FLINCH_CHEST", false);
		npc.m_blPlayHurtAnimation = false;
		npc.PlayHurtSound();
	}
	
	if(npc.m_flNextThinkTime > GetGameTime(npc.index))
	{
		return;
	}
	npc.m_flNextThinkTime = GetGameTime(npc.index) + 0.1;

	if(npc.m_iOverlordComboAttack == 0 || npc.m_iOverlordComboAttack == 1)
	{
		npc.m_iTargetAlly = GetClosestAlly(npc.index);
		if(IsValidAlly(npc.index, npc.m_iTargetAlly))
		{
			npc.m_iOverlordComboAttack = 1;
		}
		else
		{
			npc.m_iOverlordComboAttack = -1;
		}
	}

	if(npc.m_iOverlordComboAttack == 1)
	{
		if(IsValidAlly(npc.index, npc.m_iTargetAlly))
		{
			float vecTarget[3]; WorldSpaceCenter(npc.m_iTargetAlly, vecTarget );
		
			float VecSelfNpc[3]; WorldSpaceCenter(npc.index, VecSelfNpc);
			float flDistanceToTarget = GetVectorDistance(vecTarget, VecSelfNpc, true);

			if(flDistanceToTarget < (NORMAL_ENEMY_MELEE_RANGE_FLOAT_SQUARED))
			{
				//mounted ally, do logic!
				npc.m_iOverlordComboAttack = 2;
			}
			else 
			{
				npc.m_flSpeed = 400.0;
				npc.SetGoalEntity(npc.m_iTargetAlly);
			}
		}
		else
		{
			npc.m_iOverlordComboAttack = -1;
		}
		return;
	}
	else
	{
		npc.m_flSpeed = 200.0;
		if(npc.m_flGetClosestTargetTime < GetGameTime(npc.index))
		{
			npc.m_iTarget = GetClosestTarget(npc.index);
			npc.m_flGetClosestTargetTime = GetGameTime(npc.index) + GetRandomRetargetTime();
		}
		
		if(IsValidEnemy(npc.index, npc.m_iTarget))
		{
			float vecTarget[3]; WorldSpaceCenter(npc.m_iTarget, vecTarget );
		
			float VecSelfNpc[3]; WorldSpaceCenter(npc.index, VecSelfNpc);
			float flDistanceToTarget = GetVectorDistance(vecTarget, VecSelfNpc, true);
			if(flDistanceToTarget < npc.GetLeadRadius()) 
			{
				float vPredictedPos[3];
				PredictSubjectPosition(npc, npc.m_iTarget,_,_, vPredictedPos);
				npc.SetGoalVector(vPredictedPos);
				//Throw valid ally
				if(npc.m_iOverlordComboAttack == 2)
				{
					if(IsValidAlly(npc.index, npc.m_iTargetAlly))
					{
						LiberiBuff[npc.m_iTargetAlly] = 0.0;
						npc.AddGesture("ACT_MP_ATTACK_STAND_MELEE_SECONDARY",_,_,_,0.75);
						npc.FaceTowards(vPredictedPos, 20000.0);
						PluginBot_Jump(npc.m_iTargetAlly, vecTarget);
						npc.m_iTargetAlly = 0;
					}
					else
					{

					}
				}
				npc.m_iOverlordComboAttack = -1;
			}
			else 
			{
				npc.SetGoalEntity(npc.m_iTarget);
			}
			OshimunoDJ_SelfDefense(npc, GetGameTime(npc.index), vecTarget, flDistanceToTarget);
		}
		else
		{
			npc.m_flGetClosestTargetTime = 0.0;
			npc.m_iTarget = GetClosestTarget(npc.index);
		}
	}
}

void OshimunoDJ_SelfDefense(OshimunoDJ npc, float distance, float vecTarget[3], float gameTime)
{
	if(npc.m_flAttackHappens)
	{
		if(npc.m_flAttackHappens < gameTime)
		{
			npc.m_flAttackHappens = 0.0;
			
			Handle swingTrace;
			npc.FaceTowards(vecTarget, 15000.0);
			if(npc.DoSwingTrace(swingTrace, npc.m_iTarget, _, _, _, _))
			{
				int target = TR_GetEntityIndex(swingTrace);
				if(target > 0)
				{
					float damage = 60.0;
					
					npc.PlayMeleeHitSound();
					SDKHooks_TakeDamage(target, npc.index, npc.index, damage, DMG_CLUB);
				}
			}
			delete swingTrace;
		}
	}

	if(distance < (NORMAL_ENEMY_MELEE_RANGE_FLOAT_SQUARED) && npc.m_flNextMeleeAttack < gameTime)
	{
		int target = Can_I_See_Enemy(npc.index, npc.m_iTarget);
		if(IsValidEnemy(npc.index, target, false, true))
		{
			npc.m_iTarget = target;

			npc.AddGesture("ACT_MP_ATTACK_STAND_MELEE",_,_,_, 0.85);
			npc.PlayMeleeSound();
			
			npc.m_flAttackHappens = gameTime + 0.25;
			npc.m_flNextMeleeAttack = gameTime + 0.75;
		}
	}
}

static void ClotDeath(int entity)
{
	OshimunoDJ npc = view_as<OshimunoDJ>(entity);

	if(!npc.m_bGib)
		npc.PlayDeathSound();
	
	if(IsValidEntity(npc.m_iWearable1))
		RemoveEntity(npc.m_iWearable1);
	
	if(IsValidEntity(npc.m_iWearable2))
		RemoveEntity(npc.m_iWearable2);
}

static void LiberiBuffThink(int entity)
{
	if(GetGameTime() > LiberiBuff[entity])
	{
		b_NpcIsInvulnerable[entity] = false;
		b_NoGravity[entity] = false;
		b_DoNotUnStuck[entity] = false;
		RemoveSpecificBuff(entity, "Solid Stance");
		
		SDKUnhook(entity, SDKHook_ThinkPost, LiberiBuffThink);	
	}
}