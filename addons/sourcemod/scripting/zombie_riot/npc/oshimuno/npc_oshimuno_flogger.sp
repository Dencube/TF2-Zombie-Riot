#pragma semicolon 1
#pragma newdecls required //TODO: npc's weapon doesnt grow the more orbs he absorbs

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
	"weapons/cleaver_hit_02.wav",
	"weapons/cleaver_hit_03.wav",
	"weapons/cleaver_hit_05.wav",
	"weapons/cleaver_hit_06.wav",
	"weapons/cleaver_hit_07.wav",
};

static const char g_MeleeAttackSounds[][] =
{
	"weapons/pickaxe_swing1.wav",
	"weapons/pickaxe_swing2.wav",
	"weapons/pickaxe_swing3.wav",
};

void OshimunoFloggerOnMapStart()
{
	PrecacheSoundArray(g_DeathSounds);
	PrecacheSoundArray(g_HurtSounds);
	PrecacheSoundArray(g_IdleAlertedSounds);
	PrecacheSoundArray(g_MeleeHitSounds);
	PrecacheSoundArray(g_MeleeAttackSounds);
	NPCData data;
	strcopy(data.Name, sizeof(data.Name), "Spirit Flogger");
	strcopy(data.Plugin, sizeof(data.Plugin), "npc_oshimuno_flogger");
	strcopy(data.Icon, sizeof(data.Icon), "militia");
	data.IconCustom = true;
	data.Flags = 0;
	data.Category = Type_Oshimuno;
	data.Func = ClotSummon;
	NPC_Add(data);
}

#define INITIAL_ORB_ABSORB_CD 8.0
#define ORB_ABSORB_CD 20.0

static any ClotSummon(int client, float vecPos[3], float vecAng[3], int team)
{
	return OshimunoFlogger(vecPos, vecAng, team);
}

methodmap OshimunoFlogger < CClotBody
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
	property float m_flSpiritAbsorb
	{
		public get()							{ return fl_AbilityOrAttack[this.index][0]; }
		public set(float TempValueForProperty) 	{ fl_AbilityOrAttack[this.index][0] = TempValueForProperty; }
	}
	public OshimunoFlogger(float vecPos[3], float vecAng[3], int ally)
	{
		OshimunoFlogger npc = view_as<OshimunoFlogger>(CClotBody(vecPos, vecAng, "models/player/soldier.mdl", "1.0", "1000", ally));
		
		float gameTime = GetGameTime(npc.index);
		i_NpcWeight[npc.index] = 1;
		npc.SetActivity("ACT_MP_RUN_MELEE");
		KillFeed_SetKillIcon(npc.index, "disciplinary_action");
		
		npc.m_iBleedType = BLEEDTYPE_NORMAL;
		npc.m_iStepNoiseType = STEPSOUND_NORMAL;
		npc.m_iNpcStepVariation = STEPTYPE_NORMAL;
		

		func_NPCDeath[npc.index] = ClotDeath;
		func_NPCOnTakeDamage[npc.index] = Generic_OnTakeDamage;
		func_NPCThink[npc.index] = ClotThink;
		
		npc.m_flSpeed = 300.0;
		npc.m_iOverlordComboAttack = 0;
		npc.Anger = true;
		npc.m_flSpiritAbsorb = gameTime + INITIAL_ORB_ABSORB_CD;

		npc.m_iWearable1 = npc.EquipItem("head", "models/weapons/c_models/c_claidheamohmor/c_claidheamohmor.mdl");

		npc.m_iWearable2 = npc.EquipItem("head", "models/player/items/all_class/xcom_flattop_soldier.mdl");
		NpcColourCosmetic_ViaPaint(npc.m_iWearable2, 2452877);

		npc.m_iWearable3 = npc.EquipItem("head", "models/workshop/player/items/soldier/dec23_trench_warefarer/dec23_trench_warefarer.mdl");
		SetEntProp(npc.m_iWearable3, Prop_Send, "m_nSkin", 1);

		npc.m_iWearable4 = npc.EquipItem("head", "models/workshop/player/items/soldier/sum25_jarhead_style3/sum25_jarhead_style3.mdl");

		SetEntProp(npc.index, Prop_Send, "m_nSkin", 1);
		SetVariantInt(10);
		AcceptEntityInput(npc.index, "SetBodyGroup");

		npc.StartPathing();
		return npc;
	}
}

static void ClotThink(int iNPC)
{
	OshimunoFlogger npc = view_as<OshimunoFlogger>(iNPC);

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

	if(!npc.Anger && npc.m_iOverlordComboAttack <= 5)
	{
		for(int i; i < i_MaxcountNpcTotal; i++)
		{
			int orb = EntRefToEntIndexFast(i_ObjectsNpcsTotal[i]); 
			if(IsValidEntity(orb))
			{
				char npc_classname[60];
				NPC_GetPluginById(i_NpcInternalId[orb], npc_classname, sizeof(npc_classname));

				if(orb != INVALID_ENT_REFERENCE && (StrEqual(npc_classname, "npc_oshimuno_spirit_orb") && IsEntityAlive(orb))) // look for an unclaimed orb alive then grab it
				{
					OshimunoSpiritOrb npcOther = view_as<OshimunoSpiritOrb>(orb);
					if(!IsValidEntity(npcOther.m_iTargetAlly))
					{
						CPrintToChatAll("DEBUG: FOUND ORB");
						npcOther.m_iTargetAlly = npc.index; // orb sets this npc as its owner
						npc.m_iTargetAlly = orb; //set orb as target
						npc.m_iOverlordComboAttack++;
						npc.m_flSpiritAbsorb = gameTime + ORB_ABSORB_CD;
						npc.Anger = true;
						break;
					}
				}
			}
		}
	}
	if(npc.Anger && npc.m_flSpiritAbsorb < gameTime)
	{
		npc.Anger = false;
	}
	float healing = float(ReturnEntityMaxHealth(npc.index) / 5);
	if(IsValidAlly(npc.index, npc.m_iTargetAlly))
	{
		CPrintToChatAll("DEBUG: ABSORBED");
		SmiteNpcToDeath(npc.m_iTargetAlly);
		b_DoGibThisNpc[npc.m_iTargetAlly] = false;
		b_NoKillFeed[npc.m_iTargetAlly] = true;
		b_NpcForcepowerupspawn[npc.m_iTargetAlly] = 0;

		SetEntPropFloat(npc.m_iWearable1, Prop_Send, "m_flModelScale", GetEntPropFloat(npc.m_iWearable1, Prop_Send, "m_flModelScale") * 1.2);
		SetEntityModel(npc.m_iWearable1, "models/weapons/c_models/c_claidheamohmor/c_claidheamohmor.mdl");
		CPrintToChatAll("DEBUG: %f size scale", GetEntPropFloat(npc.m_iWearable1, Prop_Send, "m_flModelScale"));
		HealEntityGlobal(npc.index, npc.index, healing, 1.0, 0.0, HEAL_SELFHEAL);
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
		
		if(distance < npc.GetLeadRadius())
		{
			float vPredictedPos[3]; PredictSubjectPosition(npc, target,_,_, vPredictedPos);
			npc.SetGoalVector(vPredictedPos);
		}
		else 
		{
			npc.SetGoalEntity(target);
		}
		OshimunoFloggerSelfDefense(npc, distance, vecTarget, gameTime); 
	}
	
	npc.PlayIdleSound();
}

void OshimunoFloggerSelfDefense(OshimunoFlogger npc, float distance, float vecTarget[3], float gameTime)
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
				float extradamage = 1.0 + float(npc.m_iOverlordComboAttack) * 0.2;
				if(target > 0)
				{
					float damage = 105.0 * extradamage;
					
					npc.PlayMeleeHitSound();
					SDKHooks_TakeDamage(target, npc.index, npc.index, damage, DMG_CLUB);
				}
			}
			delete swingTrace;
		}
	}

	if(distance < (NORMAL_ENEMY_MELEE_RANGE_FLOAT_SQUARED) * 1.2 * float(npc.m_iOverlordComboAttack + 1) && npc.m_flNextMeleeAttack < gameTime)
	{
		int target = Can_I_See_Enemy(npc.index, npc.m_iTarget);
		if(IsValidEnemy(npc.index, target, false, true))
		{
			npc.m_iTarget = target;

			npc.AddGesture("ACT_MP_ATTACK_STAND_MELEE",_,_,_, 0.85);
			npc.PlayMeleeSound();
			
			npc.m_flAttackHappens = gameTime + 0.25;
			npc.m_flNextMeleeAttack = gameTime + 1.05;
		}
	}
}

static void ClotDeath(int entity) 
{
	OshimunoFlogger npc = view_as<OshimunoFlogger>(entity);

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