#pragma semicolon 1
#pragma newdecls required

static const char g_DeathSounds[][] =
{
	"vo/medic_paincrticialdeath01.mp3",
	"vo/medic_paincrticialdeath02.mp3",
	"vo/medic_paincrticialdeath03.mp3"
};

static const char g_IdleAlertedSounds[][] =
{
	"vo/medic_battlecry01.mp3",
	"vo/medic_battlecry02.mp3",
	"vo/medic_battlecry03.mp3",
	"vo/medic_battlecry04.mp3",
};

static const char g_HurtSounds[][] =
{
	"vo/medic_painsharp01.mp3",
	"vo/medic_painsharp02.mp3",
	"vo/medic_painsharp03.mp3",
	"vo/medic_painsharp04.mp3"
};

static const char g_MeleeHitSounds[][] =
{
	"weapons/fist_hit_world1.wav",
	"weapons/fist_hit_world2.wav",
};

static const char g_MeleeAttackSounds[][] =
{
	"weapons/boxing_gloves_swing1.wav",
	"weapons/boxing_gloves_swing2.wav",
	"weapons/boxing_gloves_swing4.wav"
};

void OshimunoWrestlerOnMapStart()
{
	PrecacheSoundArray(g_DeathSounds);
	PrecacheSoundArray(g_HurtSounds);
	PrecacheSoundArray(g_IdleAlertedSounds);
	PrecacheSoundArray(g_MeleeHitSounds);
	PrecacheSoundArray(g_MeleeAttackSounds);
	NPCData data;
	strcopy(data.Name, sizeof(data.Name), "Wrestler");
	strcopy(data.Plugin, sizeof(data.Plugin), "npc_oshimuno_wrestler");
	strcopy(data.Icon, sizeof(data.Icon), "victoria_basebreaker");
	data.IconCustom = true;
	data.Flags = 0;
	data.Category = Type_Dancer;
	data.Func = ClotSummon;
	NPC_Add(data);
}

static any ClotSummon(int client, float vecPos[3], float vecAng[3], int team, const char[] data)
{
	return OshimunoWrestler(vecPos, vecAng, team, data);
}

methodmap OshimunoWrestler < CClotBody
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
	
	public OshimunoWrestler(float vecPos[3], float vecAng[3], int ally, const char[] data)
	{
		OshimunoWrestler npc = view_as<OshimunoWrestler>(CClotBody(vecPos, vecAng, "models/player/medic.mdl", "1.35", "5000 ", ally));
		
		i_NpcWeight[npc.index] = 3;
		npc.SetActivity("ACT_MP_RUN_MELEE");
		KillFeed_SetKillIcon(npc.index, "hot_hand");
		
		npc.m_iBleedType = BLEEDTYPE_NORMAL;
		npc.m_iStepNoiseType = STEPSOUND_NORMAL;
		npc.m_iNpcStepVariation = STEPTYPE_NORMAL;
		

		func_NPCDeath[npc.index] = ClotDeath;
		func_NPCOnTakeDamage[npc.index] = WrestlerOnTakeDamage;
		func_NPCThink[npc.index] = ClotThink;
		
		npc.m_flSpeed = 300.0;
		 	
		npc.m_iWearable1 = npc.EquipItem("head", "models/workshop/player/items/medic/hwn2016_burly_beast/hwn2016_burly_beast.mdl");

		npc.m_iWearable2 = npc.EquipItem("head", "models/workshop/player/items/all_class/jul13_macho_mann_glasses/jul13_macho_mann_glasses_medic.mdl");

		npc.m_iWearable3 = npc.EquipItem("head", "models/workshop/player/items/all_class/jogon/jogon_medic.mdl");
		SetEntProp(npc.m_iWearable3, Prop_Send, "m_nSkin", 1);

		SetEntProp(npc.index, Prop_Send, "m_nSkin", 1);
		SetVariantInt(1);
		AcceptEntityInput(npc.index, "SetBodyGroup");

		if(data[0])
		{
			npc.m_iOverlordComboAttack = StringToInt(data);
		}
		else
		{
			npc.m_iOverlordComboAttack = 50;
		}

		npc.StartPathing();
		return npc;
	}
}

static void ClotThink(int iNPC)
{
	OshimunoWrestler npc = view_as<OshimunoWrestler>(iNPC);

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
		OshimunoWrestlerSelfDefense(npc, distance, vecTarget, gameTime); 
	}
	
	npc.PlayIdleSound();
}

void OshimunoWrestlerSelfDefense(OshimunoWrestler npc, float distance, float vecTarget[3], float gameTime)
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
					float damage = 100.0;
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

			npc.AddGesture("ACT_MP_ATTACK_STAND_MELEE_ALLCLASS",_,_,_, 0.85);
			npc.PlayMeleeSound();

			npc.m_flAttackHappens = gameTime + 0.25;
			npc.m_flNextMeleeAttack = gameTime + 1.5;
		}
	}
}

static Action WrestlerOnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{	
	OshimunoWrestler npc = view_as<OshimunoWrestler>(victim);
	
	if(attacker <= 0)
		return Plugin_Continue;

	if((i_HexCustomDamageTypes[victim] & ZR_DAMAGE_DO_NOT_APPLY_BURN_OR_BLEED))
	{
		damage *= 0.33;
		return Plugin_Changed;
	}

	if(npc.m_iOverlordComboAttack)
	{
		damage -= float(npc.m_iOverlordComboAttack);
		if(damage < 1.0)
		{
			damage = 1.0;
		}
	}
	return Plugin_Changed;
}

static void ClotDeath(int entity)
{
	OshimunoWrestler npc = view_as<OshimunoWrestler>(entity);

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