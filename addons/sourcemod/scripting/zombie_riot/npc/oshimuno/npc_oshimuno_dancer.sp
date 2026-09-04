#pragma semicolon 1
#pragma newdecls required

static const char g_DeathSounds[][] =
{
	"vo/scout_paincrticialdeath01.mp3",
	"vo/scout_paincrticialdeath02.mp3",
	"vo/scout_paincrticialdeath03.mp3",
};

static const char g_HurtSounds[][] =
{
	"vo/scout_painsharp01.mp3",
	"vo/scout_painsharp02.mp3",
	"vo/scout_painsharp03.mp3",
	"vo/scout_painsharp04.mp3",
	"vo/scout_painsharp05.mp3",
	"vo/scout_painsharp06.mp3",
	"vo/scout_painsharp07.mp3",
	"vo/scout_painsharp08.mp3",
};

static const char g_IdleAlertedSounds[][] = 
{
	"vo/scout_battlecry01.mp3",
	"vo/scout_battlecry03.mp3",
	"vo/scout_battlecry04.mp3",
	"vo/scout_battlecry05.mp3",
};

static const char g_MeleeHitSounds[][] =
{
	"weapons/batsaber_hit_flesh1.wav",
	"weapons/batsaber_hit_flesh2.wav",
	"weapons/batsaber_hit_world1.wav",
	"weapons/batsaber_hit_world2.wav"
};

static const char g_MeleeAttackSounds[][] =
{
	"weapons/batsaber_swing1.wav",
	"weapons/batsaber_swing2.wav",
	"weapons/batsaber_swing3.wav"
};

void OshimunoDancerOnMapStart()
{
	PrecacheSoundArray(g_DeathSounds);
	PrecacheSoundArray(g_HurtSounds);
	PrecacheSoundArray(g_IdleAlertedSounds);
	PrecacheSoundArray(g_MeleeHitSounds);
	PrecacheSoundArray(g_MeleeAttackSounds);
	NPCData data;
	strcopy(data.Name, sizeof(data.Name), "Shibuya Dancer");
	strcopy(data.Plugin, sizeof(data.Plugin), "npc_oshimuno_dancer");
	strcopy(data.Icon, sizeof(data.Icon), "speedy_adivus");
	data.IconCustom = true;
	data.Flags = 0;
	data.Category = Type_Dancer;
	data.Func = ClotSummon;
	NPC_Add(data);
}

static any ClotSummon(int client, float vecPos[3], float vecAng[3], int team)
{
	return OshimunoDancer(vecPos, vecAng, team);
}

methodmap OshimunoDancer < CClotBody
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
	
	public OshimunoDancer(float vecPos[3], float vecAng[3], int ally)
	{
		OshimunoDancer npc = view_as<OshimunoDancer>(CClotBody(vecPos, vecAng, "models/player/scout.mdl", "1.0", "1000", ally));
		
		i_NpcWeight[npc.index] = 1;
		npc.SetActivity("ACT_MP_RUN_MELEE");
		KillFeed_SetKillIcon(npc.index, "boston_basher");
		
		npc.m_iBleedType = BLEEDTYPE_NORMAL;
		npc.m_iStepNoiseType = STEPSOUND_NORMAL;
		npc.m_iNpcStepVariation = STEPTYPE_NORMAL;

		

		func_NPCDeath[npc.index] = ClotDeath;
		func_NPCOnTakeDamage[npc.index] = Generic_OnTakeDamage;
		func_NPCThink[npc.index] = ClotThink;
		
		npc.m_flSpeed = 550.0;
		npc.m_flTauntLoop = 0.0;
		npc.m_bisWalking = false;
		npc.m_iState = 2; // 0 is for normally walking || 1 is for flipping || 2 is for dancing
		
		npc.m_iWearable1 = npc.EquipItem("head", "models/workshop/weapons/c_models/c_invasion_bat/c_invasion_bat.mdl");
		SetEntityRenderColor(npc.m_iWearable1, GetRandomInt(0, 255), GetRandomInt(0, 255), GetRandomInt(0, 255), 255);

		npc.m_iWearable2 = npc.EquipItem("head", "models/workshop/player/items/scout/hwn2025_buzz_kill/hwn2025_buzz_kill.mdl");

		npc.m_iWearable3 = npc.EquipItem("head", "models/workshop/player/items/scout/hwn2025_torn_terror/hwn2025_torn_terror.mdl");
		SetEntProp(npc.m_iWearable3, Prop_Send, "m_nSkin", 1);

		SetEntProp(npc.index, Prop_Send, "m_nSkin", 1);
		SetVariantInt(3);
		AcceptEntityInput(npc.index, "SetBodyGroup");
		npc.StartPathing();
		return npc;
	}
}

static void ClotThink(int iNPC)
{
	OshimunoDancer npc = view_as<OshimunoDancer>(iNPC);
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
		OshimunoDancerSelfDefense(npc, distance, vecTarget, gameTime);
		OshimunoDancerSpeed(npc, distance, gameTime);
	}
	if(npc.m_flTauntLoop < gameTime && npc.m_iState == 2) // loops the taunt if dancing
	{
		npc.AddActivityViaSequence("taunt_conga");
		npc.SetPlaybackRate(1.2);
		npc.SetCycle(0.0);
		npc.m_flTauntLoop = gameTime + 3.0;
	}
	npc.PlayIdleSound();
}

void OshimunoDancerSelfDefense(OshimunoDancer npc, float distance, float vecTarget[3], float gameTime)
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
void OshimunoDancerSpeed(OshimunoDancer npc, float distance, float gameTime)
{
	if(npc.m_iState == 2) // while dancing
	{
		if(distance < (NORMAL_ENEMY_MELEE_RANGE_FLOAT_SQUARED) * 8.0) // flip once we get close enough
		{
			npc.SetActivity("ACT_MP_RUN_MELEE"); // prevent animation bug
			npc.m_iState = 1;
			npc.m_flSpeed = 300.0;
			npc.m_flDoingAnimation = gameTime + 1.0;
		}
	}
	if(npc.m_iState != 2) // while not dancing....
	{
		if(npc.m_flDoingAnimation > gameTime && npc.m_iState == 1) // during flip
		{
			npc.SetPlaybackRate(1.0);	
			npc.SetCycle(0.1);
			npc.StopPathing();
			npc.m_iState = 0;
			npc.AddActivityViaSequence("taunt_the_trackmans_touchdown");
		}
		if(npc.m_flDoingAnimation < gameTime && npc.m_iState == 0) // after the flip
		{
			npc.m_bisWalking = true;
			npc.SetActivity("ACT_MP_RUN_MELEE");
			npc.StartPathing();
			npc.m_iState = -1; // setting to -1 so this doesnt run anymore cuz its not needed
		}
	}
}
/*
public Action DancerOnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{	
	OshimunoDancer npc = view_as<OshimunoDancer>(victim); // something is broken here and it doesnt work properly || TODO: fix later
	if(CheckInHud())
		return Plugin_Changed;
	if(f_TimeFrozenStill[victim] > GetGameTime(victim))
		return Plugin_Changed;
	float HitChance = 0.3; //70% dodge chance while dancing
	if(GetRandomFloat(0.0, 1.0) < HitChance && npc.m_iState != 0) // dont do dodge chance if not dancing
		return Plugin_Changed;
	float chargerPos[3];
	GetEntPropVector(victim, Prop_Data, "m_vecAbsOrigin", chargerPos);
	chargerPos[2] += 90.0;
	TE_ParticleInt(g_particleMissText, chargerPos);
	TE_SendToAll();
	int Rand = GetRandomInt(0, sizeof(MissSound) - 1);
	EmitSoundToAll(MissSound[Rand], victim, _, 80);
	damage = 0.0;
	return Plugin_Changed;
}
*/
static void ClotDeath(int entity)
{
	OshimunoDancer npc = view_as<OshimunoDancer>(entity);

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
