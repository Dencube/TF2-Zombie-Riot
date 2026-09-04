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

void OshimunoPopstarOnMapStart()
{
	PrecacheSoundArray(g_DeathSounds);
	PrecacheSoundArray(g_HurtSounds);
	PrecacheSoundArray(g_IdleAlertedSounds);
	PrecacheSoundArray(g_MeleeHitSounds);
	PrecacheSoundArray(g_MeleeAttackSounds);
	NPCData data;
	strcopy(data.Name, sizeof(data.Name), "Popstar");
	strcopy(data.Plugin, sizeof(data.Plugin), "npc_oshimuno_popstar");
	strcopy(data.Icon, sizeof(data.Icon), "medic_uber");
	data.IconCustom = true;
	data.Flags = 0;
	data.Category = Type_Dancer;
	data.Func = ClotSummon;
	NPC_Add(data);
}

static any ClotSummon(int client, float vecPos[3], float vecAng[3], int team)
{
	return OshimunoPopstar(vecPos, vecAng, team);
}

methodmap OshimunoPopstar < CClotBody
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
	public OshimunoPopstar(float vecPos[3], float vecAng[3], int ally)
	{
		OshimunoPopstar npc = view_as<OshimunoPopstar>(CClotBody(vecPos, vecAng, "models/player/medic.mdl", "1.0", "5000", ally));

		float gameTime = GetGameTime(npc.index);
		i_NpcWeight[npc.index] = 3;
		npc.SetActivity("ACT_MP_RUN_MELEE_ALLCLASS");
		KillFeed_SetKillIcon(npc.index, "saxxy");
		
		npc.m_iBleedType = BLEEDTYPE_NORMAL;
		npc.m_iStepNoiseType = STEPSOUND_NORMAL;
		npc.m_iNpcStepVariation = STEPTYPE_NORMAL;
		

		func_NPCDeath[npc.index] = ClotDeath;
		func_NPCOnTakeDamage[npc.index] = PopstarOnTakeDamage;
		func_NPCThink[npc.index] = ClotThink;
		
		npc.m_flSpeed = 300.0;
		npc.m_iState = 0;
		npc.m_flTauntLoop = 0.0;
		NPCTalkMessage(npc.index, "Looks like we got a a brand new set of fans. Boys, give em one hell of a dance battle!");
		npc.m_flInvulDuration = gameTime + 10.0; // 0 is for standing still and dancing while invincible
		
		npc.m_iWearable1 = npc.EquipItem("head", "models/weapons/c_models/c_saxxy/c_saxxy.mdl");

		npc.m_iWearable2 = npc.EquipItem("head", "models/workshop/player/items/all_class/jul13_macho_mann_glasses/jul13_macho_mann_glasses_medic.mdl");

		npc.m_iWearable3 = npc.EquipItem("head", "models/workshop/player/items/all_class/jogon/jogon_medic.mdl");
		SetEntProp(npc.m_iWearable3, Prop_Send, "m_nSkin", 1);

		SetEntProp(npc.index, Prop_Send, "m_nSkin", 1);
		SetVariantInt(1);
		AcceptEntityInput(npc.index, "SetBodyGroup");

		npc.StartPathing();
		return npc;
	}
}

static void NPCTalkMessage(int iNPC, const char[] message)
{
	PrintNPCMessageWithPrefixes(iNPC, "turquoise", message);
}

static void ClotThink(int iNPC)
{
	OshimunoPopstar npc = view_as<OshimunoPopstar>(iNPC);

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
		OshimunoPopstarSelfDefense(npc, distance, vecTarget, gameTime); 
	}
	if(npc.m_iState == 0)
	{
		/*
		if(npc.m_flTauntLoop < gameTime) // loops the taunt if dancing
		{
			npc.AddActivityViaSequence("taunt_conga");
			npc.SetPlaybackRate(1.2);
			npc.SetCycle(0.0);
			npc.m_flTauntLoop = gameTime + 3.0;
			NPCTalkMessage(npc.index, "Let's give our brand new guests a show!");
		}
		*/
		if(npc.m_flInvulDuration > gameTime)
		{
			b_NpcIsInvulnerable[npc.index] = true;
			npc.StopPathing();
		}
		else
		{
			b_NpcIsInvulnerable[npc.index] = false;
			npc.m_iState = 1;
			NPCTalkMessage(npc.index, "A star has to lookout for all of her fans!");
			npc.StartPathing();
		}
		for(int i; i < i_MaxcountNpcTotal; i++) // EVERYONE adores the popstar
		{
			int entity = EntRefToEntIndexFast(i_ObjectsNpcsTotal[i]); 
			if(IsValidEntity(entity))
			{
				ApplyStatusEffect(npc.index, entity, "Adoration", 30.0);
			}
		}
		if(!npc.Anger)
		{
			npc.Anger = true;
			for(int i=0 ; i < 4 ; i++) //summons 4 dancers
			{
				float pos[3]; GetEntPropVector(npc.index, Prop_Data, "m_vecAbsOrigin", pos);
				float ang[3]; GetEntPropVector(npc.index, Prop_Data, "m_angRotation", ang);
				int entity = NPC_CreateByName("npc_oshimuno_bouncer", -1, pos, ang, GetTeam(npc.index));

				if(entity > MaxClients)
				{
					if(GetTeam(npc.index) != TFTeam_Red)
					NpcAddedToZombiesLeftCurrently(entity, true);
				}
			}
		}
	}
	
	npc.PlayIdleSound();
}

void OshimunoPopstarSelfDefense(OshimunoPopstar npc, float distance, float vecTarget[3], float gameTime)
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

static Action PopstarOnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if(attacker <= 0)
		return Plugin_Continue;

	if((i_HexCustomDamageTypes[victim] & ZR_DAMAGE_DO_NOT_APPLY_BURN_OR_BLEED))
	{
		damage *= 0.33;
		return Plugin_Changed;
	}
	return Plugin_Changed;
}

static void ClotDeath(int entity)
{
	OshimunoPopstar npc = view_as<OshimunoPopstar>(entity);

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