#pragma semicolon 1 //TODO: add a mafia wrath system on death to all attackers/last attacker
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
	"vo/heavy_painsharp05.mp3"
};


static const char g_IdleAlertedSounds[][] = 
{
	"vo/taunts/heavy_taunts16.mp3",
	"vo/taunts/heavy_taunts18.mp3",
	"vo/taunts/heavy_taunts19.mp3"
};

static const char g_RangedAttackSounds[][] = 
{
	"weapons/family_business_shoot.wav"
}; 

#define STACK_COOLDOWN 3.0

void OshimunoAvengerOnMapStart()
{
	PrecacheSoundArray(g_DeathSounds);
	PrecacheSoundArray(g_HurtSounds);
	PrecacheSoundArray(g_IdleAlertedSounds);
	PrecacheSoundArray(g_RangedAttackSounds);
	NPCData data;
	strcopy(data.Name, sizeof(data.Name), "Tarakeno Avenger");
	strcopy(data.Plugin, sizeof(data.Plugin), "npc_oshimuno_avenger");
	strcopy(data.Icon, sizeof(data.Icon), "victoria_basebreaker");
	data.IconCustom = true;
	data.Flags = 0;
	data.Category = Type_Oshimuno;
	data.Func = ClotSummon;
	NPC_Add(data);
}

static any ClotSummon(int client, float vecPos[3], float vecAng[3], int team)
{
	return OshimunoAvenger(vecPos, vecAng, team);
}

methodmap OshimunoAvenger < CClotBody
{
	property float m_flTimerCooldown
	{
		public get()							{ return fl_AbilityOrAttack[this.index][0]; }
		public set(float TempValueForProperty) 	{ fl_AbilityOrAttack[this.index][0] = TempValueForProperty; }
	}
	property int m_iAlliesDead
	{
		public get()							{ return i_OverlordComboAttack[this.index]; }
		public set(int TempValueForProperty) 	{ i_OverlordComboAttack[this.index] = TempValueForProperty; }
	}
	property int m_iAlliesDeadMax
	{
		public get()							{ return i_TimesSummoned[this.index]; }
		public set(int TempValueForProperty) 	{ i_TimesSummoned[this.index] = TempValueForProperty; }
	}
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
	public OshimunoAvenger(float vecPos[3], float vecAng[3], int ally)
	{
		OshimunoAvenger npc = view_as<OshimunoAvenger>(CClotBody(vecPos, vecAng, "models/player/heavy.mdl", "1.0", "1000", ally));
		float gameTime = GetGameTime(npc.index);

		i_NpcWeight[npc.index] = 1;
		npc.SetActivity("ACT_MP_RUN_SECONDARY");
		KillFeed_SetKillIcon(npc.index, "family_business");
		
		npc.m_iBleedType = BLEEDTYPE_NORMAL;
		npc.m_iStepNoiseType = STEPSOUND_NORMAL;
		npc.m_iNpcStepVariation = STEPTYPE_NORMAL;
		

		func_NPCDeath[npc.index] = ClotDeath;
		func_NPCOnTakeDamage[npc.index] = Generic_OnTakeDamage;
		func_NPCThink[npc.index] = ClotThink;
		func_NPCDeathForward[npc.index] = OshimunoAvengerAllyDeath;
		
		npc.m_flSpeed = 250.0;
		npc.m_flTimerCooldown = gameTime + 15.0;

		npc.m_iWearable1 = npc.EquipItem("head", "models/workshop/weapons/c_models/c_russian_riot/c_russian_riot.mdl");

		npc.m_iWearable2 = npc.EquipItem("head", "models/workshop/player/items/heavy/sum19_kapitans_kaftan/sum19_kapitans_kaftan.mdl");
		SetEntProp(npc.m_iWearable2, Prop_Send, "m_nSkin", 1);

		npc.m_iWearable3 = npc.EquipItem("head", "models/workshop/player/items/heavy/sum25_hardcore/sum25_hardcore.mdl");
		SetEntProp(npc.m_iWearable3, Prop_Send, "m_nSkin", 1);

		npc.m_iWearable4 = npc.EquipItem("head", "models/workshop/player/items/all_class/hwn2022_onimann/hwn2022_onimann_heavy.mdl");
		SetEntProp(npc.m_iWearable4, Prop_Send, "m_nSkin", 1);

		SetEntProp(npc.index, Prop_Send, "m_nSkin", 1);
		SetVariantInt(3);
		AcceptEntityInput(npc.index, "SetBodyGroup");

		npc.StartPathing();
		return npc;
	}
}

static void ClotThink(int iNPC)
{
	OshimunoAvenger npc = view_as<OshimunoAvenger>(iNPC);

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

	if(npc.m_flTimerCooldown < gameTime && npc.m_iAlliesDead > 0) // lower anger as time goes on
	{
		if(npc.m_iAlliesDead >= 70) // above 70
		{
			npc.m_iAlliesDead -= 5;
			float flPos[3], flAng[3];
			npc.GetAttachment("eyes", flPos, flAng);
			if(!IsValidEntity(npc.m_iWearable9))
				npc.m_iWearable9 = ParticleEffectAt_Parent(flPos, "unusual_devilish_headmist_purple", npc.index, "eyes", {0.0,0.0,0.0}); // using wearable9 for unusuals
		}
		else if (npc.m_iAlliesDead >= 50) //between 70 and 50
		{
			npc.m_iAlliesDead -= 3;
			if(IsValidEntity(npc.m_iWearable9))
				CreateTimer(0.1, Timer_RemoveEntityParticle, npc.m_iWearable9, TIMER_FLAG_NO_MAPCHANGE);
		}
		else if(npc.m_iAlliesDead >= 0) //betweeen 50 and 0
		{
			npc.m_iAlliesDead -= 2;
		}

		if(npc.m_iAlliesDead < 0) // just incase it somehow goes negative
		{
			npc.m_iAlliesDead = 0;
		}
		npc.m_flTimerCooldown = gameTime + 5.0;
	}

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
		
		if(IsValidEnemy(npc.index, npc.m_iTarget))
		{
			switch(OshimunoAvengerSelfDefense(npc, gameTime, npc.m_iTarget, distance))
			{
				case 0:
				{
					npc.m_bAllowBackWalking = false;
					//Get the normal prediction code.
					if(distance < npc.GetLeadRadius()) 
					{
						float vPredictedPos[3];
						PredictSubjectPosition(npc, npc.m_iTarget,_,_, vPredictedPos);
						npc.SetGoalVector(vPredictedPos);
					}
					else 
					{
						npc.SetGoalEntity(npc.m_iTarget);
					}
				}
				case 1:
				{
					npc.m_bAllowBackWalking = true;
					float vBackoffPos[3];
					BackoffFromOwnPositionAndAwayFromEnemy(npc, npc.m_iTarget,_,vBackoffPos);
					npc.SetGoalVector(vBackoffPos, true); //update more often, we need it
				}
			}
		}
		else
		{
			npc.m_flGetClosestTargetTime = 0.0;
			npc.m_iTarget = GetClosestTarget(npc.index);
		}
		npc.PlayIdleSound();
	}
}
static int OshimunoAvengerSelfDefense(OshimunoAvenger npc, float gameTime, int target, float distance)
{
	if(npc.m_flNextRangedAttack < gameTime)
	{
		if(distance < (NORMAL_ENEMY_MELEE_RANGE_FLOAT_SQUARED * 2.5))
		{
			int Enemy_I_See = Can_I_See_Enemy(npc.index, target);
			if(IsValidEnemy(npc.index, Enemy_I_See))
			{
				npc.AddGesture("ACT_MP_ATTACK_STAND_SECONDARY");
				npc.m_iTarget = Enemy_I_See;
				float vecTarget[3]; WorldSpaceCenter(target, vecTarget);
				float damagebonus;
				damagebonus = 1.0 + float(npc.m_iAlliesDead / 100);
				npc.FaceTowards(vecTarget, 20000.0);
				Handle swingTrace;
				if(npc.DoSwingTrace(swingTrace, target, { 9999.0, 9999.0, 9999.0 }))
				{
					target = TR_GetEntityIndex(swingTrace);	
						
					float vecHit[3];
					TR_GetEndPosition(vecHit, swingTrace);
					float origin[3], angles[3];
					view_as<CClotBody>(npc.index).GetAttachment("effect_hand_r", origin, angles);
					ShootLaser(npc.index, "bullet_tracer02_blue", origin, vecHit, false );
					npc.m_flNextRangedAttack = gameTime + 0.8;

					if(IsValidEnemy(npc.index, target))
					{
						float damage = 50.0 * damagebonus;
						npc.PlayRangedSound();
						SDKHooks_TakeDamage(target, npc.index, npc.index, damage, DMG_BULLET, -1, _, vecHit);
					}
				}
				delete swingTrace;
			}
			if(distance > (NORMAL_ENEMY_MELEE_RANGE_FLOAT_SQUARED * 3.5))
			{
				//target is too far, try to close in
				return 0;
			}
			else if(distance < (NORMAL_ENEMY_MELEE_RANGE_FLOAT_SQUARED * 1.5))
			{
				if(Can_I_See_Enemy_Only(npc.index, target))
				{
					//target is too close, try to keep distance
					return 1;
				}
			}
			return 0;
		}
		else
		{
			if(distance > (NORMAL_ENEMY_MELEE_RANGE_FLOAT_SQUARED * 3.5))
			{
				//target is too far, try to close in
				return 0;
			}
			else if(distance < (NORMAL_ENEMY_MELEE_RANGE_FLOAT_SQUARED * 1.5))
			{
				if(Can_I_See_Enemy_Only(npc.index, target))
				{
					//target is too close, try to keep distance
					return 1;
				}
			}
		}
	}
	else
	{
		if(distance > (NORMAL_ENEMY_MELEE_RANGE_FLOAT_SQUARED * 3.5))
		{
			//target is too far, try to close in
			return 0;
		}
		else if(distance < (NORMAL_ENEMY_MELEE_RANGE_FLOAT_SQUARED * 1.5))
		{
			if(Can_I_See_Enemy_Only(npc.index, target))
			{
				//target is too close, try to keep distance
				return 1;
			}
		}
	}
	return 0;
}

public void OshimunoAvengerAllyDeath(int self, int ally)
{
	OshimunoAvenger npc = view_as<OshimunoAvenger>(self);

	if(GetTeam(ally) != GetTeam(self))
	{
		return;
	}
	float AllyPos[3];
	GetEntPropVector(ally, Prop_Data, "m_vecAbsOrigin", AllyPos);
	float SelfPos[3];
	GetEntPropVector(self, Prop_Data, "m_vecAbsOrigin", SelfPos);
	float flDistanceToTarget = GetVectorDistance(SelfPos, AllyPos, true);
	if(flDistanceToTarget < (NORMAL_ENEMY_MELEE_RANGE_FLOAT_SQUARED * 24.0))
	{
		npc.m_iAlliesDead += 5;
		if(npc.m_iAlliesDead > 100)
		{
			npc.m_iAlliesDead = 100;
		}
		npc.m_flSpeed = 250.0 + float(npc.m_iAlliesDead / 2);
		fl_TotalArmor[npc.index] = 1.0 - float(npc.m_iAlliesDead / 250);
		CPrintToChatAll("DEBUG: ALLY DED %i ", npc.m_iAlliesDead);
	}
}

static void ClotDeath(int entity) 
{
	OshimunoAvenger npc = view_as<OshimunoAvenger>(entity);

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