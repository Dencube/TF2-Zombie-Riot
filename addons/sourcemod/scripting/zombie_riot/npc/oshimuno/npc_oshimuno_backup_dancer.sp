#pragma semicolon 1
#pragma newdecls required

#define REVIVE_DURATION 12.0

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
	"vo/heavy_meleedare13.mp3",
	"vo/heavy_meleedare12.mp3",
	"vo/heavy_meleedare07.mp3",
	"vo/heavy_meleedare06.mp3",
	"vo/heavy_meleedare05.mp3",
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

void OshimunoBackupDancerOnMapStart()
{
	PrecacheSoundArray(g_DeathSounds);
	PrecacheSoundArray(g_HurtSounds);
	PrecacheSoundArray(g_IdleAlertedSounds);
	PrecacheSoundArray(g_MeleeHitSounds);
	PrecacheSoundArray(g_MeleeAttackSounds);
	NPCData data;
	strcopy(data.Name, sizeof(data.Name), "Shibuya Backup Dancer");
	strcopy(data.Plugin, sizeof(data.Plugin), "npc_oshimuno_backup_dancer");
	strcopy(data.Icon, sizeof(data.Icon), "heavy_steelfist");
	data.IconCustom = true;
	data.Flags = 0;
	data.Category = Type_Dancer;
	data.Func = ClotSummon;
	NPC_Add(data);
}

static any ClotSummon(int client, float vecPos[3], float vecAng[3], int team)
{
	return OshimunoBackupDancer(vecPos, vecAng, team);
}

methodmap OshimunoBackupDancer < CClotBody
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
	property float m_flTauntLoop
	{
		public get()							{ return fl_AbilityOrAttack[this.index][0]; }
		public set(float TempValueForProperty) 	{ fl_AbilityOrAttack[this.index][0] = TempValueForProperty; }
	}
	property float m_flInvulDuration
	{
		public get()							{ return fl_AbilityOrAttack[this.index][1]; }
		public set(float TempValueForProperty) 	{ fl_AbilityOrAttack[this.index][1] = TempValueForProperty; }
	}
	public OshimunoBackupDancer(float vecPos[3], float vecAng[3], int ally)
	{
		OshimunoBackupDancer npc = view_as<OshimunoBackupDancer>(CClotBody(vecPos, vecAng, "models/player/soldier.mdl", "1.35", "5000", ally));
		
		i_NpcWeight[npc.index] = 3;
		npc.SetActivity("ACT_MP_RUN_MELEE");
		KillFeed_SetKillIcon(npc.index, "fists");
		
		npc.m_iBleedType = BLEEDTYPE_NORMAL;
		npc.m_iStepNoiseType = STEPSOUND_NORMAL;
		npc.m_iNpcStepVariation = STEPTYPE_NORMAL;
		

		func_NPCDeath[npc.index] = ClotDeath;
		func_NPCOnTakeDamage[npc.index] = OshimunoBackupDancerOnTakeDamage;
		func_NPCThink[npc.index] = ClotThink;
		
		npc.m_flSpeed = 300.0;
		npc.m_iOverlordComboAttack = 0;
		npc.m_flInvulDuration = 0.0;
		npc.m_flTauntLoop = 0.0;

		npc.m_iWearable1 = npc.EquipItem("head", "models/workshop/player/items/soldier/short2014_soldier_fedhair/short2014_soldier_fedhair.mdl");

		npc.m_iWearable2 = npc.EquipItem("head", "models/workshop/player/items/soldier/short2014_man_in_slacks/short2014_man_in_slacks.mdl");

		npc.m_iWearable3 = npc.EquipItem("head", "models/workshop/player/items/soldier/spr18_veterans_attire/spr18_veterans_attire.mdl");
		SetEntProp(npc.m_iWearable3, Prop_Send, "m_nSkin", 1);

		SetEntProp(npc.index, Prop_Send, "m_nSkin", 1);
		SetVariantInt(2);
		AcceptEntityInput(npc.index, "SetBodyGroup");

		npc.StartPathing();
		return npc;
	}
}

static int GetPopstarAlive(int entity)
{
	int PopstarAlive;
	int a, entity1;
	// Count trees
	while((entity1 = FindEntityByNPC(a)) != -1)
	{
		if(IsValidEntity(entity1) && i_NpcInternalId[entity1] == OshimunoPopstar_ID() && GetTeam(entity) == GetTeam(entity1))
		{
			PopstarAlive++;
		}
	}
	return PopstarAlive;
}

static void ClotThink(int iNPC)
{
	OshimunoBackupDancer npc = view_as<OshimunoBackupDancer>(iNPC);

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
		OshimunoBackupDancerSelfDefense(npc, distance, vecTarget, gameTime); 
	}
	if(npc.m_flInvulDuration)
	{
		if(npc.m_flInvulDuration < gameTime)
		{
			b_NpcIsInvulnerable[npc.index] = false;
			npc.m_flInvulDuration = 0.0;
			npc.StartPathing();
		}
		else
		{
			if(npc.m_flTauntLoop < gameTime) // loops the taunt
			{
				npc.AddActivityViaSequence("taunt_manrobic");
				npc.SetPlaybackRate(1.2);
				npc.SetCycle(0.0);
				npc.m_flTauntLoop = gameTime + 3.0;
			}
		}
	}
	npc.PlayIdleSound();
}

void OshimunoBackupDancerSelfDefense(OshimunoBackupDancer npc, float distance, float vecTarget[3], float gameTime)
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
					float damage;
					npc.m_iOverlordComboAttack++;
					if(npc.m_iOverlordComboAttack == 3) // get unusual right before stronger hit
					{
						float flPos[3], flAng[3];

						npc.GetAttachment("eyes", flPos, flAng);
						npc.m_iWearable9 = ParticleEffectAt_Parent(flPos, "unusual_icrown_plasma_blue", npc.index, "eyes", {0.0,0.0,0.0}); // using wearable9 for unusuals
					}
					if(npc.m_iOverlordComboAttack == 4) // after 4 hits do a stronger hit
					{
						damage = 300.0;
						Custom_Knockback(npc.index, target, 1200.0, true, true);
						if(!HasSpecificBuff(target, "Solid Stance"))
							ApplyStatusEffect(npc.index, target, "Solid Stance", 2.5);
						CreateTimer(0.1, Timer_RemoveEntityParticle, npc.m_iWearable9, TIMER_FLAG_NO_MAPCHANGE);
						npc.m_iOverlordComboAttack = 0;
					}
					else // normal hit
					{
						damage = 100.0;
					}
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
			npc.m_flNextMeleeAttack = gameTime + 1.5;
		}
	}
}

static Action OshimunoBackupDancerOnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{	
	OshimunoBackupDancer npc = view_as<OshimunoBackupDancer>(victim);
	float gameTime = GetGameTime(npc.index);
	if(GetPopstarAlive(npc.index) > 0  && GetEntProp(npc.index, Prop_Data, "m_iHealth") <= 1) //enrage below 50% hp
	{
		b_NpcIsInvulnerable[npc.index] = true;
		npc.StopPathing();
		npc.m_iState = 1;
		float healing = float(ReturnEntityMaxHealth(npc.index)); // heal to max hp over 12s
		HealEntityGlobal(npc.index, npc.index, healing, 1.0, REVIVE_DURATION, HEAL_ABSOLUTE);
		NPCStats_RemoveAllDebuffs(npc.index, 1.0);
		npc.m_flInvulDuration = gameTime + REVIVE_DURATION;
	}
	return Plugin_Changed;
}

static void ClotDeath(int entity)
{
	OshimunoBackupDancer npc = view_as<OshimunoBackupDancer>(entity);

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