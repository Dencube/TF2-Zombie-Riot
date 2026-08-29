#pragma semicolon 1
#pragma newdecls required

static const char g_DeathSounds[][] = 
{
	"vo/medic_paincrticialdeath01.mp3",
	"vo/medic_paincrticialdeath02.mp3",
	"vo/medic_paincrticialdeath03.mp3",
};

static const char g_HurtSounds[][] = 
{
	"vo/medic_painsharp01.mp3",
	"vo/medic_painsharp02.mp3",
	"vo/medic_painsharp03.mp3",
	"vo/medic_painsharp04.mp3",
};

static const char g_IdleAlertedSounds[][] = 
{
	"vo/medic_battlecry01.mp3",
	"vo/medic_battlecry02.mp3",
	"vo/medic_battlecry03.mp3",
	"vo/medic_battlecry04.mp3",
};

static const char g_MeleeAttackSounds[][] = 
{
	"weapons/pickaxe_swing1.wav",
	"weapons/pickaxe_swing2.wav",
	"weapons/pickaxe_swing3.wav",
};

static const char g_MeleeHitSounds[][] = 
{
	"mvm/melee_impacts/cbar_hitbod_robo01.wav",
	"mvm/melee_impacts/cbar_hitbod_robo02.wav",
	"mvm/melee_impacts/cbar_hitbod_robo03.wav",
};

#define INITIAL_DELAY 8.0
#define CALLING_DELAY 20.0

void OshimunoSpiritCallerOnMapStart()
{
	PrecacheSoundArray(g_DeathSounds);
	PrecacheSoundArray(g_HurtSounds);
	PrecacheSoundArray(g_IdleAlertedSounds);
	PrecacheSoundArray(g_MeleeHitSounds);
	PrecacheSoundArray(g_MeleeAttackSounds);
	NPCData data;
	strcopy(data.Name, sizeof(data.Name), "Spirit Caller");
	strcopy(data.Plugin, sizeof(data.Plugin), "npc_oshimuno_spiritcaller");
	strcopy(data.Icon, sizeof(data.Icon), "victoria_basebreaker");
	data.IconCustom = true;
	data.Flags = 0;
	data.Category = Type_Oshimuno;
	data.Func = ClotSummon;
	NPC_Add(data);
}

static any ClotSummon(int client, float vecPos[3], float vecAng[3], int team)
{
	return OshimunoSpiritCaller(vecPos, vecAng, team);
}

methodmap OshimunoSpiritCaller < CClotBody
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
	property float m_flSpiritCalling
	{
		public get()							{ return fl_AbilityOrAttack[this.index][0]; }
		public set(float TempValueForProperty) 	{ fl_AbilityOrAttack[this.index][0] = TempValueForProperty; }
	}
	public OshimunoSpiritCaller(float vecPos[3], float vecAng[3], int ally)
	{
		OshimunoSpiritCaller npc = view_as<OshimunoSpiritCaller>(CClotBody(vecPos, vecAng, "models/player/medic.mdl", "1.0", "1000", ally));
		float gameTime = GetGameTime(npc.index);
		
		i_NpcWeight[npc.index] = 1;
		npc.SetActivity("ACT_MP_RUN_MELEE_ALLCLASS");
		KillFeed_SetKillIcon(npc.index, "freedom_staff");
		
		npc.m_iBleedType = BLEEDTYPE_NORMAL;
		npc.m_iStepNoiseType = STEPSOUND_NORMAL;
		npc.m_iNpcStepVariation = STEPTYPE_NORMAL;
		

		func_NPCDeath[npc.index] = ClotDeath;
		func_NPCOnTakeDamage[npc.index] = Generic_OnTakeDamage;
		func_NPCThink[npc.index] = ClotThink;
		
		npc.m_flSpeed = 300.0;
		npc.m_flSpiritCalling = gameTime + INITIAL_DELAY; // timer for when we switch states
		npc.m_iState = 0;	//0 is normal behavior  || 1 is for hunting spirit orbs to respawn as enemies

		npc.m_iWearable1 = npc.EquipItem("head", "models/workshop_partner/weapons/c_models/c_tw_eagle/c_tw_eagle.mdl");

		npc.m_iWearable2 = npc.EquipItem("head", "models/workshop/player/items/medic/dec18_misers_muttonchops/dec18_misers_muttonchops.mdl");

		npc.m_iWearable3 = npc.EquipItem("head", "models/workshop/player/items/scout/sbox2014_ticket_boy/sbox2014_ticket_boy.mdl");
		SetEntProp(npc.m_iWearable3, Prop_Send, "m_nSkin", 1);

		npc.m_iWearable4 = npc.EquipItem("head", "models/workshop/player/items/medic/dec15_medic_winter_jacket2_emblem2/dec15_medic_winter_jacket2_emblem2.mdl");

		SetEntProp(npc.index, Prop_Send, "m_nSkin", 1);
		SetVariantInt(1);
		AcceptEntityInput(npc.index, "SetBodyGroup");

		npc.StartPathing();
		return npc;
	}
}

static void ClotThink(int iNPC)
{
	OshimunoSpiritCaller npc = view_as<OshimunoSpiritCaller>(iNPC);

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

	if(npc.m_flSpiritCalling < gameTime)
	{
		npc.m_iState = 1;
		npc.m_flSpiritCalling = gameTime + FAR_FUTURE;
	}
	if(npc.m_iState == 1)
	{
		for(int i; i < i_MaxcountNpcTotal; i++)
		{
			int orb = EntRefToEntIndexFast(i_ObjectsNpcsTotal[i]); 
			if(IsValidEntity(orb))
			{
				char npc_classname[60];
				NPC_GetPluginById(i_NpcInternalId[orb], npc_classname, sizeof(npc_classname));

				if(orb != INVALID_ENT_REFERENCE && (StrEqual(npc_classname, "npc_oshimuno_spirit_orb") && IsEntityAlive(orb))) // look for a spirit orb alive
				{
					npc.m_iTargetAlly = orb; //set spirit orb as target
				}
			}
		}
		if(IsValidAlly(npc.index, npc.m_iTargetAlly))
		{
			float vecTarget[3]; WorldSpaceCenter(npc.m_iTargetAlly, vecTarget);
			float VecSelfNpc[3]; WorldSpaceCenter(npc.index, VecSelfNpc);
			float distance = GetVectorDistance(vecTarget, VecSelfNpc, true);
			
			float pos[3]; GetEntPropVector(npc.index, Prop_Data, "m_vecAbsOrigin", pos);
			float ang[3]; GetEntPropVector(npc.index, Prop_Data, "m_angRotation", ang);
			float healing = float(ReturnEntityMaxHealth(npc.index) / 4);
			if(distance < (NORMAL_ENEMY_MELEE_RANGE_FLOAT_SQUARED))
			{
				//touched the spirit orb we now spawn a random npc ||TODO: make it spawn more enemies
				npc.m_iState = 0;
				HealEntityGlobal(npc.index, npc.index, healing, 1.5, 0.0, HEAL_SELFHEAL);
				npc.m_flSpiritCalling = gameTime + CALLING_DELAY;

				SmiteNpcToDeath(npc.m_iTargetAlly);
				b_DoGibThisNpc[npc.m_iTargetAlly] = false;
				b_NoKillFeed[npc.m_iTargetAlly] = true;
				b_NpcForcepowerupspawn[npc.m_iTargetAlly] = 0;
				
				int entity = NPC_CreateByName("npc_oshimuno_spiritualist", -1, pos, ang, GetTeam(npc.index));
				if(entity > MaxClients)
				{	
					if(GetTeam(npc.index) != TFTeam_Red)
						NpcAddedToZombiesLeftCurrently(entity, true);
				}	
			}
			else 
			{
				npc.m_flSpeed = 420.0;
				npc.SetGoalEntity(npc.m_iTargetAlly);
			}
		}
		else // ally is somehow invalid -> return to normal
		{
			npc.m_iState = 1;
			npc.m_flSpiritCalling = gameTime + CALLING_DELAY;
		}
	}
	if(npc.m_iState == 0)
	{	
		npc.m_flSpeed = 300.0;
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
			OshimunoSpiritCallerSelfDefense(npc, distance, vecTarget, gameTime); 
		}

	}
	npc.PlayIdleSound();
}

void OshimunoSpiritCallerSelfDefense(OshimunoSpiritCaller npc, float distance, float vecTarget[3], float gameTime)
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

			npc.AddGesture("ACT_MP_ATTACK_STAND_MELEE_ALLCLASS");
			npc.PlayMeleeSound();
			
			npc.m_flAttackHappens = gameTime + 0.25;
			npc.m_flNextMeleeAttack = gameTime + 0.75;
		}
	}
}
static void ClotDeath(int entity)
{
	OshimunoSpiritCaller npc = view_as<OshimunoSpiritCaller>(entity);

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