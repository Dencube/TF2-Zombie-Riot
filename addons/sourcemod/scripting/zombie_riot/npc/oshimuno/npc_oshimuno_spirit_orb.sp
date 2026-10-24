#pragma semicolon 1
#pragma newdecls required

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

void OshimunoSpiritOrbOnMapStart()
{
	PrecacheSoundArray(g_MeleeHitSounds);
	PrecacheSoundArray(g_MeleeAttackSounds);
	PrecacheModel("models/weapons/w_models/w_baseball.mdl");
	NPCData data;
	strcopy(data.Name, sizeof(data.Name), "Spirit Orb");
	strcopy(data.Plugin, sizeof(data.Plugin), "npc_oshimuno_spirit_orb");
	strcopy(data.Icon, sizeof(data.Icon), "victoria_basebreaker");
	data.IconCustom = true;
	data.Flags = 0;
	data.Category = Type_Outlaws;
	data.Func = ClotSummon;
	NPC_Add(data);
}

static any ClotSummon(int client, float vecPos[3], float vecAng[3], int team, const char[] data)
{
	return OshimunoSpiritOrb(vecPos, vecAng, team, data);
}

methodmap OshimunoSpiritOrb < CClotBody
{
	public void PlayMeleeSound()
 	{
		EmitSoundToAll(g_MeleeAttackSounds[GetRandomInt(0, sizeof(g_MeleeAttackSounds) - 1)], this.index, SNDCHAN_AUTO, NORMAL_ZOMBIE_SOUNDLEVEL, _, NORMAL_ZOMBIE_VOLUME, _);
	}
	public void PlayMeleeHitSound()
	{
		EmitSoundToAll(g_MeleeHitSounds[GetRandomInt(0, sizeof(g_MeleeHitSounds) - 1)], this.index, SNDCHAN_AUTO, NORMAL_ZOMBIE_SOUNDLEVEL, _, NORMAL_ZOMBIE_VOLUME, _);	
	}
	
	public OshimunoSpiritOrb(float vecPos[3], float vecAng[3], int ally, const char[] data)
	{
		OshimunoSpiritOrb npc = view_as<OshimunoSpiritOrb>(CClotBody(vecPos, vecAng, "models/bots/demo/bot_sentry_buster.mdl", "0.4", "1000", ally));
		SetEntityRenderMode(npc.index, RENDER_NONE); //make buster model invisible
		i_NpcWeight[npc.index] = 1;
		npc.SetActivity("ACT_MP_RUN_MELEE");
		KillFeed_SetKillIcon(npc.index, "skullbat");

		npc.m_iBleedType = BLEEDTYPE_NORMAL;
		npc.m_iStepNoiseType = STEPSOUND_NORMAL;
		npc.m_iNpcStepVariation = STEPTYPE_NORMAL;
		

		func_NPCDeath[npc.index] = ClotDeath;
		func_NPCOnTakeDamage[npc.index] = Generic_OnTakeDamage;
		func_NPCThink[npc.index] = ClotThink;
		
		npc.m_flSpeed = 200.0;
		npc.m_bDissapearOnDeath = true;
		npc.m_flWaveScale = 1.0;
		npc.m_iOverlordComboAttack = 0;

		float flPos[3], flAng[3];
		npc.GetAttachment("head", flPos, flAng);

		npc.m_iWearable1 = ParticleEffectAt_Parent(flPos, "flaregun_energyfield_blue", npc.index, "head", {0.0,0.0,20.0});
		/*npc.m_iWearable1 = npc.EquipItemSeperate("models/weapons/w_models/w_baseball.mdl" ,_,_, 1.75, 30.0, false);
		SetEntityRenderColor(npc.m_iWearable1, 0, 255, 255, 100); */ // cyan 
		
		npc.m_iWearable8 = ParticleEffectAt_Parent(flPos, "unusual_spectral_fire_parent", npc.index, "head", {0.0,0.0,22.0});

		npc.m_iWearable9 = ParticleEffectAt_Parent(flPos, "unusual_spectral_fire_sparkles", npc.index, "head", {0.0,0.0,22.0});

		if(StrContains(data, "globalscale_npc") != -1)
		{
			npc.m_iOverlordComboAttack++;
			int health = StringToInt(MinibossHealthScaling(100.0, true));
			SetEntProp(npc.index, Prop_Data, "m_iMaxHealth", health);
			SetEntProp(npc.index, Prop_Data, "m_iHealth", health);
			float wave = float(Waves_GetRoundScale()+1);
			wave *= 0.133333;
			npc.m_flWaveScale = wave;
			npc.m_flWaveScale *= MinibossScalingReturn();
			b_thisNpcIsAMiniboss[npc.index] = true;
		}
		if(StrContains(data, "globalscale_player") != -1)
		{
			npc.m_iOverlordComboAttack++;
			int health = StringToInt(MinibossHealthScaling(225.0, true));
			SetEntProp(npc.index, Prop_Data, "m_iMaxHealth", health);
			SetEntProp(npc.index, Prop_Data, "m_iHealth", health);
			float wave = float(Waves_GetRoundScale()+1);
			wave *= 0.133333;
			npc.m_flWaveScale = wave;
			npc.m_flWaveScale *= MinibossScalingReturn();
			b_thisNpcIsAMiniboss[npc.index] = true;
		}
		if(StrContains(data, "teleport_in_orb") != -1)
		{
			TeleportDiversioToRandLocation(npc.index,_,900.0, 500.0);
			float pos[3];
			GetEntPropVector(npc.index, Prop_Data, "m_vecAbsOrigin", pos);
			ParticleEffectAt(pos, "teleported_blue", 0.5);
			FreezeNpcInTime(npc.index, 0.5);
		}
		npc.StartPathing();
		return npc;
	}
}

static void ClotThink(int iNPC)
{
	OshimunoSpiritOrb npc = view_as<OshimunoSpiritOrb>(iNPC);

	float gameTime = GetGameTime(npc.index);
	if(npc.m_flNextDelayTime > gameTime)
		return;
	
	npc.m_flNextDelayTime = gameTime + DEFAULT_UPDATE_DELAY_FLOAT;
	npc.Update();

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
		OshimunoSpiritOrbSelfDefense(npc, distance, vecTarget, gameTime); 
	}
	
	if(IsValidEntity(npc.m_iTargetAlly)) // for removing ownership if owner dies
	{
		if(!IsEntityAlive(npc.m_iTargetAlly))
		{
			npc.m_iTargetAlly = INVALID_ENT_REFERENCE;
		}
	}
}

void OshimunoSpiritOrbSelfDefense(OshimunoSpiritOrb npc, float distance, float vecTarget[3], float gameTime)
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
					float damage = 55.0 * npc.m_flWaveScale;
				
					npc.PlayMeleeHitSound();
					SDKHooks_TakeDamage(target, npc.index, npc.index, damage, DMG_CLUB);
					StatusEffects_SpiritFireAddStuff(target, 2, 2.0);
					if(npc.m_iOverlordComboAttack)
						StatusEffects_SpiritFireAddStuff(target, 3, 1.0);
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
	OshimunoSpiritOrb npc = view_as<OshimunoSpiritOrb>(entity);
	
	if(IsValidEntity(npc.m_iWearable1))
		RemoveEntity(npc.m_iWearable1);

	CreateTimer(0.1, Timer_RemoveEntityParticle, npc.m_iWearable1, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(0.1, Timer_RemoveEntityParticle, npc.m_iWearable8, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(0.1, Timer_RemoveEntityParticle, npc.m_iWearable9, TIMER_FLAG_NO_MAPCHANGE);
}