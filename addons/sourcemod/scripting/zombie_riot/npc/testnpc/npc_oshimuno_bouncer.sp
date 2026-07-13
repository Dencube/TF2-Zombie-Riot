#pragma semicolon 1
#pragma newdecls required

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

void OshimunoBouncerOnMapStart()
{
	PrecacheSoundArray(g_DeathSounds);
	PrecacheSoundArray(g_HurtSounds);
	PrecacheSoundArray(g_IdleAlertedSounds);
	PrecacheSoundArray(g_MeleeHitSounds);
	PrecacheSoundArray(g_MeleeAttackSounds);
	NPCData data;
	strcopy(data.Name, sizeof(data.Name), "Oshimuno Bouncer");
	strcopy(data.Plugin, sizeof(data.Plugin), "npc_oshimuno_bouncer");
	strcopy(data.Icon, sizeof(data.Icon), "victoria_basebreaker");
	data.IconCustom = true;
	data.Flags = 0;
	data.Category = Type_Dancer;
	data.Func = ClotSummon;
	NPC_Add(data);
}

static any ClotSummon(int client, float vecPos[3], float vecAng[3], int team)
{
	return OshimunoBouncer(vecPos, vecAng, team);
}

methodmap OshimunoBouncer < CClotBody
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
	
	public OshimunoBouncer(float vecPos[3], float vecAng[3], int ally)
	{
		OshimunoBouncer npc = view_as<OshimunoBouncer>(CClotBody(vecPos, vecAng, "models/player/heavy.mdl", "1.35", "15000", ally));
		
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

		npc.m_iWearable1 = npc.EquipItem("head", "models/workshop/weapons/c_models/c_sr3_punch/c_sr3_punch.mdl");

		npc.m_iWearable2 = npc.EquipItem("head", "models/player/items/heavy/cop_glasses.mdl");

		npc.m_iWearable3 = npc.EquipItem("head", "models/workshop/player/items/heavy/sum23_hog_heels/sum23_hog_heels.mdl");

		npc.m_iWearable4 = npc.EquipItem("head", "models/workshop/player/items/heavy/dec23_bigger_mann/dec23_bigger_mann.mdl");

		SetEntProp(npc.index, Prop_Send, "m_nSkin", 1);
		SetVariantInt(2);
		AcceptEntityInput(npc.index, "SetBodyGroup");

		npc.StartPathing();
		return npc;
	}
}

static void ClotThink(int iNPC)
{
	OshimunoBouncer npc = view_as<OshimunoBouncer>(iNPC);

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
		OshimunoBouncer_SelfDefense(npc, distance, vecTarget, gameTime); 
	}

	npc.PlayIdleSound();
}

void OshimunoBouncer_SelfDefense(OshimunoBouncer npc, float distance, float vecTarget[3], float gameTime)
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
	OshimunoBouncer npc = view_as<OshimunoBouncer>(entity);

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
	
	if(IsValidEntity(npc.m_iWearable5))
		RemoveEntity(npc.m_iWearable5);
}