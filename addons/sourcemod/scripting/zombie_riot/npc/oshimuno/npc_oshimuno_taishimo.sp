#pragma semicolon 1
#pragma newdecls required

#define TAISHIMO_LINE_WIDTH 180.0
#define TAISHIMO_LINE_LENGTH 900.0
#define TAISHIMO_LINE_PADDING 350.0
#define TAISHIMO_LINE_START 30.0
#define TAISHIMO_LINE_TIME 1.2
#define TAISHIMO_LINE_SWING_LEAD 0.75
#define TAISHIMO_LINE_SWING_DELAY 0.1953
#define TAISHIMO_LINE_IMPACT_DELAY (-0.04)
#define TAISHIMO_LINE_SPREAD 75.0
#define TAISHIMO_LINE_DAMAGE 30.0
#define TAISHIMO_LINE_FADE_TIME 0.15
#define TAISHIMO_LINE_FADE_STEP 0.045
#define TAISHIMO_LINE_DETONATE_TIME 1.0
#define TAISHIMO_LINE_COUNT 8

static const char g_DeathSounds[][] =
{
	"vo/soldier_paincrticialdeath01.mp3",
	"vo/soldier_paincrticialdeath02.mp3",
	"vo/soldier_paincrticialdeath03.mp3"
};

static const char g_HurtSounds[][] =
{
	"vo/soldier_painsharp01.mp3",
	"vo/soldier_painsharp02.mp3",
	"vo/soldier_painsharp03.mp3",
	"vo/soldier_painsharp04.mp3",
	"vo/soldier_painsharp05.mp3",
	"vo/soldier_painsharp06.mp3",
	"vo/soldier_painsharp07.mp3",
	"vo/soldier_painsharp08.mp3"
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
	"weapons/blade_slice_2.wav",
	"weapons/blade_slice_3.wav",
	"weapons/blade_slice_4.wav"
};

static const char g_MeleeAttackSounds[][] =
{
	"weapons/samurai/tf_katana_01.wav",
	"weapons/samurai/tf_katana_02.wav",
	"weapons/samurai/tf_katana_03.wav",
	"weapons/samurai/tf_katana_04.wav",
	"weapons/samurai/tf_katana_05.wav",
	"weapons/samurai/tf_katana_06.wav",
};

static const char g_RangedAttackSounds[][] =
{
	"weapons/cleaver_throw.wav",
};
static const char g_WindUpSounds[][] =
{
	"vo/taunts/engineer_taunts08.mp3",
	"vo/taunts/engineer_taunts10.mp3"
};
static const char g_WindUpEndSounds[][] =
{
	"vo/engineer_wranglekills04.mp3"
};

static int g_TaishimoLineLaser = -1;
static const char g_TaishimoLineWindUpSound[] = "misc/halloween/strongman_fast_swing_01.wav";
static const char g_TaishimoLineImpactSound[] = "misc/halloween/strongman_fast_impact_01.wav";
int OshimunoTaishimoId;
int OshimunoTaishimoIDReturn()
{
	return OshimunoTaishimoId;
}

void OshimunoTaishimoOnMapStart()
{
	NPCData data;
	PrecacheSoundArray(g_DeathSounds);
	PrecacheSoundArray(g_HurtSounds);
	PrecacheSoundArray(g_IdleAlertedSounds);
	PrecacheSoundArray(g_MeleeHitSounds);
	PrecacheSoundArray(g_MeleeAttackSounds);
	PrecacheSoundArray(g_RangedAttackSounds);
	PrecacheSoundArray(g_WindUpSounds);
	PrecacheSoundArray(g_WindUpEndSounds);
	PrecacheSound(g_TaishimoLineWindUpSound);
	PrecacheSound(g_TaishimoLineImpactSound);
	g_TaishimoLineLaser = PrecacheModel("sprites/laserbeam.vmt");
	strcopy(data.Name, sizeof(data.Name), "Taishimo");
	strcopy(data.Plugin, sizeof(data.Plugin), "npc_oshimuno_taishimo");
	strcopy(data.Icon, sizeof(data.Icon), "blackheavysoul");
	data.IconCustom = true;
	data.Flags = MVM_CLASS_FLAG_MINIBOSS|MVM_CLASS_FLAG_ALWAYSCRIT;
	data.Category = Type_Raid;
	data.Func = ClotSummon;
	OshimunoTaishimoId = NPC_Add(data);
}

static any ClotSummon(int client, float vecPos[3], float vecAng[3], int team, const char[] data)
{
	return OshimunoTaishimo(vecPos, vecAng, team, data);
}

methodmap OshimunoTaishimo < CClotBody
{
	property float m_flTransformIn
	{
		public get()							{ return fl_NextChargeSpecialAttack[this.index]; }
		public set(float TempValueForProperty) 	{ fl_NextChargeSpecialAttack[this.index] = TempValueForProperty; }
	}
	property int m_iSaiyanState
	{
		public get()							{ return i_State[this.index]; }
		public set(int TempValueForProperty) 	{ i_State[this.index] = TempValueForProperty; }
	}
	property float m_flSlashFlurry
	{
		public get()							{ return fl_AbilityOrAttack[this.index][0]; }
		public set(float TempValueForProperty) 	{ fl_AbilityOrAttack[this.index][0] = TempValueForProperty; }
	}
	property float m_flMassAoeSlashes
	{
		public get()							{ return fl_AbilityOrAttack[this.index][1]; }
		public set(float TempValueForProperty) 	{ fl_AbilityOrAttack[this.index][1] = TempValueForProperty; }
	}
	property float m_flJumpAtEnemy
	{
		public get()							{ return fl_AbilityOrAttack[this.index][2]; }
		public set(float TempValueForProperty) 	{ fl_AbilityOrAttack[this.index][2] = TempValueForProperty; }
	}
	property int m_iWhatAbilityDo
	{
		public get()							{ return i_MedkitAnnoyance[this.index]; }
		public set(int TempValueForProperty) 	{ i_MedkitAnnoyance[this.index] = TempValueForProperty; }
	}
	property float m_flLineAoeDetonate
	{
		public get()							{ return fl_AbilityOrAttack[this.index][3]; }
		public set(float TempValueForProperty) 	{ fl_AbilityOrAttack[this.index][3] = TempValueForProperty; }
	}
	property float m_flLineAoeYaw
	{
		public get()							{ return fl_AbilityOrAttack[this.index][4]; }
		public set(float TempValueForProperty) 	{ fl_AbilityOrAttack[this.index][4] = TempValueForProperty; }
	}
	property float m_flLineAoeFade
	{
		public get()							{ return fl_AbilityOrAttack[this.index][5]; }
		public set(float TempValueForProperty) 	{ fl_AbilityOrAttack[this.index][5] = TempValueForProperty; }
	}
	property float m_flLineAoeFadeDraw
	{
		public get()							{ return fl_AbilityOrAttack[this.index][6]; }
		public set(float TempValueForProperty) 	{ fl_AbilityOrAttack[this.index][6] = TempValueForProperty; }
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
	public void PlayMeleeSound()
 	{
		EmitSoundToAll(g_MeleeAttackSounds[GetRandomInt(0, sizeof(g_MeleeAttackSounds) - 1)], this.index, SNDCHAN_AUTO, NORMAL_ZOMBIE_SOUNDLEVEL, _, NORMAL_ZOMBIE_VOLUME, _);
	}
	public void PlayMeleeHitSound()
	{
		EmitSoundToAll(g_MeleeHitSounds[GetRandomInt(0, sizeof(g_MeleeHitSounds) - 1)], this.index, SNDCHAN_AUTO, NORMAL_ZOMBIE_SOUNDLEVEL, _, NORMAL_ZOMBIE_VOLUME, _);	
	}
	public void PlayRangedSound()
	{
		EmitSoundToAll(g_RangedAttackSounds[GetRandomInt(0, sizeof(g_RangedAttackSounds) - 1)], this.index, SNDCHAN_AUTO, NORMAL_ZOMBIE_SOUNDLEVEL, _, NORMAL_ZOMBIE_VOLUME);
	}
	public void PlayWindUpSounds()
	{
		EmitSoundToAll(g_WindUpSounds[GetRandomInt(0, sizeof(g_WindUpSounds) - 1)], this.index, SNDCHAN_AUTO, NORMAL_ZOMBIE_SOUNDLEVEL, _, NORMAL_ZOMBIE_VOLUME, _);	
	}
	public void PlayWindUpEndSounds()
	{
		EmitSoundToAll(g_WindUpEndSounds[GetRandomInt(0, sizeof(g_WindUpEndSounds) - 1)], this.index, SNDCHAN_AUTO, NORMAL_ZOMBIE_SOUNDLEVEL, _, NORMAL_ZOMBIE_VOLUME, _);	
	}
	
	public OshimunoTaishimo(float vecPos[3], float vecAng[3], int ally, const char[] data)
	{
		OshimunoTaishimo npc = view_as<OshimunoTaishimo>(CClotBody(vecPos, vecAng, "models/player/soldier.mdl", "1.35", "40000", ally, false, true, true,true)); //giant!
		float gameTime = GetGameTime(npc.index);

		KillFeed_SetKillIcon(npc.index, "demokatana");
		int iActivity = npc.LookupActivity("ACT_MP_RUN_MELEE");
		if(iActivity > 0) npc.StartActivity(iActivity);

		MusicEnum music;
		strcopy(music.Path, sizeof(music.Path), "#zombiesurvival/aprilfools/reteptheme_1.mp3");
		music.Time = 110;
		music.Volume = 2.0;
		music.Custom = true;
		strcopy(music.Name, sizeof(music.Name), "Retep theme");
		strcopy(music.Artist, sizeof(music.Artist), "terraria peter griffin mod");
		Music_SetRaidMusic(music);

		func_NPCDeath[npc.index] = OshimunoTaishimo_Death;
		func_NPCOnTakeDamage[npc.index] = OshimunoTaishimo_OnTakeDamage;
		func_NPCThink[npc.index] = OshimunoTaishimo_Think;
		func_NPCFuncWin[npc.index] = OshimunoTaishimo_Win;
		
		npc.m_iBleedType = BLEEDTYPE_NORMAL;
		npc.m_iStepNoiseType = STEPSOUND_GIANT;	
		npc.m_iNpcStepVariation = STEPTYPE_NORMAL;

		npc.m_flSpeed = 320.0;
		npc.m_flMeleeArmor = 1.25;
		npc.m_iOverlordComboAttack = 0;
		npc.m_flSlashFlurry = gameTime + 5.0;
		/*
		npc.m_flCongaFastDo = gameTime + 20.0;
		npc.m_flJumpAtEnemy = gameTime + 10.0;
		*/
		npc.m_flNextMeleeAttack = 0.0;

		RaidModeTime = gameTime + 200.0;
		RaidBossActive = EntIndexToEntRef(npc.index);
		RaidAllowsBuildings = false;
		RaidAllowLastman = true;
		WaveStart_SubWaveStart(gameTime + 500.0);
		GiveOneRevive();

		i_NpcWeight[npc.index] = 5;
		b_thisNpcIsARaid[npc.index] = true;
		b_angered_twice[npc.index] = false;

		npc.m_iWearable1 = npc.EquipItem("head", "models/workshop_partner/weapons/c_models/c_shogun_katana/c_shogun_katana_soldier.mdl");
		npc.m_iWearable2 = npc.EquipItem("head", "models/workshop/player/items/soldier/dec15_diplomat/dec15_diplomat.mdl");
		SetEntProp(npc.m_iWearable2, Prop_Send, "m_nSkin", 1);
		npc.m_iWearable3 = npc.EquipItem("head", "models/workshop/player/items/soldier/jul13_gangplank_garment/jul13_gangplank_garment.mdl");
		SetEntProp(npc.m_iWearable3, Prop_Send, "m_nSkin", 1);
		npc.m_iWearable4 = npc.EquipItem("head", "models/workshop/player/items/soldier/hw2013_shaolin_sash/hw2013_shaolin_sash.mdl");
		SetEntProp(npc.m_iWearable4, Prop_Send, "m_nSkin", 1);
		npc.m_iWearable5 = npc.EquipItem("head", "models/workshop/player/items/soldier/hw2013_faux_manchu/hw2013_faux_manchu.mdl");
		SetEntProp(npc.m_iWearable5, Prop_Send, "m_nSkin", 1);
		npc.m_iWearable6 = npc.EquipItem("head", "models/workshop/player/items/all_class/fall2013_hong_kong_cone/fall2013_hong_kong_cone_soldier.mdl");
		SetEntProp(npc.m_iWearable6, Prop_Send, "m_nSkin", 1);

		SetEntProp(npc.index, Prop_Send, "m_nSkin", 1);
		SetVariantInt(2);
		AcceptEntityInput(npc.index, "SetBodyGroup");

		EmitSoundToAll("npc/zombie_poison/pz_alert1.wav", _, _, _, _, 1.0);	
		EmitSoundToAll("npc/zombie_poison/pz_alert1.wav", _, _, _, _, 1.0);	

		for(int client_clear=1; client_clear<=MaxClients; client_clear++)
		{
			fl_AlreadyStrippedMusic[client_clear] = 0.0; //reset to 0
		}
		
		BlockLoseSay = false;

		bool final = StrContains(data, "final_item") != -1;
		
		if(final)
		{
			i_RaidGrantExtra[npc.index] = 6;
		}
		for(int client_check=1; client_check<=MaxClients; client_check++)
		{
			if(IsClientInGame(client_check) && !IsFakeClient(client_check))
			{
				LookAtTarget(client_check, npc.index);
				SetGlobalTransTarget(client_check);
				ShowGameText(client_check, "item_armor", 1, "%t", "Taishimo has arrived");
			}
		}

		char buffers[3][64];
		ExplodeString(data, ";", buffers, sizeof(buffers), sizeof(buffers[]));
		//the very first and 2nd char are SC for scaling
		if(buffers[0][0] == 's' && buffers[0][1] == 'c')
		{
			//remove SC
			ReplaceString(buffers[0], 64, "sc", "");
			float value = StringToFloat(buffers[0]);
			RaidModeScaling = value;

			if(RaidModeScaling < 35)
			{
				RaidModeScaling *= 0.25; //abit low, inreacing
			}
			else
			{
				RaidModeScaling *= 0.5;
			}

			if(value > 40.0)
			{
				RaidModeScaling *= 0.85;
			}
			
		}
		else
		{	
			RaidModeScaling = float(Waves_GetRoundScale()+1);
			if(RaidModeScaling < 35)
			{
				RaidModeScaling *= 0.25; //abit low, inreacing
			}
			else
			{
				RaidModeScaling *= 0.5;
			}
				
			if(Waves_GetRoundScale()+1 > 25)
			{
				RaidModeScaling *= 0.85;
			}
		}
		float amount_of_people = ZRStocks_PlayerScalingDynamic();
		if(amount_of_people > 12.0)
		{
			amount_of_people = 12.0;
		}
		amount_of_people *= 0.12;
		
		if(amount_of_people < 1.0)
			amount_of_people = 1.0;

		RaidModeScaling *= amount_of_people; //More then 9 and he raidboss gets some troubles, bufffffffff

		RemoveAllDamageAddition();

		if(StrContains(data, "timeout") != -1)
		{
			RaidModeTime = gameTime + 10.0;
		}

		npc.StartPathing();
		return npc;
	}
}

static void NPCTalkMessage(int entity, const char[] message)
{
	PrintNPCMessageWithPrefixes(entity, "black", message);
}



static void OshimunoTaishimo_Think(int iNPC)
{
	OshimunoTaishimo npc = view_as<OshimunoTaishimo>(iNPC);
	float gameTime = GetGameTime(npc.index);
	if(npc.m_flNextDelayTime > gameTime)
	{
		return;
	}
	npc.m_flNextDelayTime = gameTime + DEFAULT_UPDATE_DELAY_FLOAT;
	npc.Update();

	if(LastMann)
	{
		if(!npc.m_fbGunout)
		{
			npc.m_fbGunout = true;
			NPCTalkMessage(npc.index, "Last Noob Left.");
		}
	}
	if(i_RaidGrantExtra[npc.index] == RAIDITEM_INDEX_WIN_COND)
	{
		npc.m_bisWalking = false;
		npc.AddActivityViaSequence("selectionMenu_Idle");
		npc.SetCycle(0.01);
		func_NPCThink[npc.index] = INVALID_FUNCTION;
		
		NPCTalkMessage(npc.index, "GG EZs.");
		return;

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

	if(OshimunoTaishimoSlash_Do(npc, gameTime))
	{
		return;
	}
	if(OshimunoTaishimo_MassAoeSlashes(npc, gameTime))
	{
		return;
	}

	if(npc.m_flLineAoeDetonate)
	{
		if(npc.m_flLineAoeDetonate > gameTime)
		{
			OshimunoTaishimoLineAoeDraw(npc, gameTime);
		}
		else
		{
			OshimunoTaishimoLineAoeDetonate(npc);
			npc.PlayWindUpEndSounds();
			npc.m_flLineAoeDetonate = 0.0;
			npc.m_flLineAoeFade = gameTime + TAISHIMO_LINE_FADE_TIME;
			npc.m_flLineAoeFadeDraw = gameTime + TAISHIMO_LINE_FADE_STEP;
			int color[4];
			color[0] = 255;
			color[1] = 0;
			color[2] = 0;
			color[3] = 255;
			OshimunoTaishimoLineAoeDrawRects(npc, 0.0, color, 0.1);
			RequestFrame(TaishimoLineFadeFrame, EntIndexToEntRef(npc.index));
			npc.StartPathing();
			npc.m_bisWalking = true;
		}
		return;
	}

	if(!BlockLoseSay && RaidModeTime < gameTime)
	{
		ApplyStatusEffect(npc.index, npc.index, "Perfected Instinct", 999999.9);
		fl_Extra_Speed[npc.index] 	*= 1.25;
		if(!npc.Anger)
		{
			fl_TotalArmor[npc.index] *= 0.5;
			f_AttackSpeedNpcIncrease[npc.index] *= 0.65;
		}
		npc.Anger = true;
		npc.m_iSaiyanState = 999;
		RaidModeTime = FAR_FUTURE;
		f_AttackSpeedNpcIncrease[npc.index] *= 0.85;
		RaidModeScaling *= 1.5;
	}

	
	if(npc.m_blPlayHurtAnimation)
	{
		npc.AddGesture("ACT_MP_GESTURE_FLINCH_CHEST", false);
		npc.m_blPlayHurtAnimation = false;
		npc.PlayHurtSound();
	}

	if(!IsValidEntity(RaidBossActive))
	{
		RaidBossActive = EntIndexToEntRef(npc.index);
	}

	if(npc.m_flGetClosestTargetTime < gameTime)
	{
		npc.m_iTarget = GetClosestTarget(npc.index);
		npc.m_flGetClosestTargetTime = gameTime + GetRandomRetargetTime();
	}
	
	if(IsValidEnemy(npc.index, npc.m_iTarget))
	{
		float vecTarget[3]; WorldSpaceCenter(npc.m_iTarget, vecTarget );
		float VecSelfNpc[3]; WorldSpaceCenter(npc.index, VecSelfNpc);
		float flDistanceToTarget = GetVectorDistance(vecTarget, VecSelfNpc, true);
		int SetGoalVectorIndex = 0;
		SetGoalVectorIndex = OshimunoTaishimo_SelfDefense(npc, gameTime, npc.m_iTarget, flDistanceToTarget); 

		switch(SetGoalVectorIndex)
		{
			case 0:
			{
				npc.m_bAllowBackWalking = false;
				//Get the normal prediction code.
				if(flDistanceToTarget < npc.GetLeadRadius()) 
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

	if(npc.m_flDoingAnimation < gameTime)
	{
		OshimunoTaishimoAnimationChange(npc);
	}
}

static Action OshimunoTaishimo_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	OshimunoTaishimo npc = view_as<OshimunoTaishimo>(victim);
	float gameTime = GetGameTime(npc.index);
		
	if(attacker <= 0)
		return Plugin_Continue;

	if (npc.m_flHeadshotCooldown < gameTime)
	{
		npc.m_flHeadshotCooldown = gameTime + DEFAULT_HURTDELAY;
		npc.m_blPlayHurtAnimation = true;
	}
	return Plugin_Changed;
}
public void OshimunoTaishimo_Win(int entity)
{
	i_RaidGrantExtra[entity] = RAIDITEM_INDEX_WIN_COND;
	BlockLoseSay = true;
	NPCTalkMessage(entity, "get owned.");
}

static void OshimunoTaishimo_Death(int entity)
{
	RaidBossActive = INVALID_ENT_REFERENCE;
	if(BlockLoseSay)
		return;

	NPCTalkMessage(entity, "Nvm fuck you i made it all up.");
	NPCTalkMessage(entity, "*dies of death*");
}

void OshimunoTaishimoAnimationChange(OshimunoTaishimo npc)
{
	
	if(npc.m_iChanged_WalkCycle == 0)
	{
		npc.m_iChanged_WalkCycle = -1;
	}

	if (npc.IsOnGround())
	{
		if(npc.m_iChanged_WalkCycle != 3)
		{
		//	ResetOshimunoTaishimoWeapon(npc, 0);
			npc.m_flSpeed = 320.0;
			npc.m_bisWalking = true;
			npc.m_iChanged_WalkCycle = 3;
			npc.SetActivity("ACT_MP_RUN_MELEE");
			npc.StartPathing();
		}	
	}
	else
	{
		if(npc.m_iChanged_WalkCycle != 4)
		{
		//	ResetOshimunoTaishimoWeapon(npc, 0);
			npc.m_flSpeed = 320.0;
			npc.m_bisWalking = false;
			npc.m_iChanged_WalkCycle = 4;
			npc.SetActivity("ACT_MP_JUMP_FLOAT_MELEE");
			npc.StartPathing();
		}	
	}

}

int OshimunoTaishimo_SelfDefense(OshimunoTaishimo npc, float gameTime, int target, float distance)
{
	if(npc.m_iWhatAbilityDo == 2)
	{	
		return 0;
	}
	if(npc.m_flAttackHappens)
	{
		if(npc.m_flAttackHappens < GetGameTime(npc.index))
		{
			npc.m_flAttackHappens = 0.0;
			
			if(IsValidEnemy(npc.index, target))
			{
				int HowManyEnemeisAoeMelee = 64;
				Handle swingTrace;
				float VecEnemy[3]; WorldSpaceCenter(npc.m_iTarget, VecEnemy);
				npc.FaceTowards(VecEnemy, 15000.0);
				npc.DoSwingTrace(swingTrace, npc.m_iTarget,_,_,_,1,_,HowManyEnemeisAoeMelee);
				delete swingTrace;
				bool PlaySound = false;
				for(int counter = 1; counter <= HowManyEnemeisAoeMelee; counter++)
				{
					if(i_EntitiesHitAoeSwing_NpcSwing[counter] > 0)
					{
						if(IsValidEntity(i_EntitiesHitAoeSwing_NpcSwing[counter]))
						{
							PlaySound = true;
							int targetTrace = i_EntitiesHitAoeSwing_NpcSwing[counter];
							float vecHit[3];
							
							WorldSpaceCenter(targetTrace, vecHit);
							float damage = 15.0;
							SDKHooks_TakeDamage(targetTrace, npc.index, npc.index, damage * RaidModeScaling, DMG_CLUB, -1, _, vecHit);								
							bool Knocked = false;
										
							if(IsValidClient(targetTrace))
							{
								if(IsInvuln(targetTrace))
								{
									Knocked = true;
									Custom_Knockback(npc.index, targetTrace, 900.0, true);
									if(!NpcStats_IsEnemySilenced(npc.index))
									{
										TF2_AddCondition(targetTrace, TFCond_LostFooting, 0.5);
										TF2_AddCondition(targetTrace, TFCond_AirCurrent, 0.5);
									}
								}
							}
							if(!Knocked)
								Custom_Knockback(npc.index, targetTrace, 250.0, true); 
						}
					}
				}
				if(PlaySound)
				{
					npc.PlayMeleeHitSound();
				}
			}
		}
	}
	//Melee attack, last prio
	else if(GetGameTime(npc.index) > npc.m_flNextMeleeAttack)
	{
		if(IsValidEnemy(npc.index, target)) 
		{
			if(distance < (GIANT_ENEMY_MELEE_RANGE_FLOAT_SQUARED))
			{
				int Enemy_I_See;
									
				Enemy_I_See = Can_I_See_Enemy(npc.index, target);
						
				if(IsValidEntity(Enemy_I_See) && IsValidEnemy(npc.index, Enemy_I_See))
				{
					target = Enemy_I_See;

					npc.PlayMeleeSound();
					npc.AddGesture("ACT_MP_ATTACK_STAND_MELEE",_,_,_, 2.0);
							
					npc.m_flAttackHappens = gameTime + 0.1;
					npc.m_flNextMeleeAttack = gameTime + 0.5;
					npc.m_flDoingAnimation = gameTime + 0.6;
				}
			}
		}
		else
		{
			npc.m_flGetClosestTargetTime = 0.0;
			npc.m_iTarget = GetClosestTarget(npc.index);
		}	
	}
	return 0;
}

//200 offset
bool OshimunoTaishimoSlash_Do(OshimunoTaishimo npc, float gameTime)
{
	if(npc.m_iWhatAbilityDo != 1 && npc.m_iWhatAbilityDo != 0)
		return false;
	if(npc.m_flDoingAnimation < gameTime)
	{
		if(npc.m_flSlashFlurry < gameTime)
		{
			if(!IsValidEnemy(npc.index, npc.m_iTarget))
				return false;
			if(!Can_I_See_Enemy_Only(npc.index, npc.m_iTarget))
				return false;
			npc.m_flSlashFlurry = gameTime + 25.0;
			npc.m_flDoingAnimation = gameTime + 1.5;
			npc.m_bisWalking = false;
			npc.StopPathing();
			npc.m_iChanged_WalkCycle = 200;
			npc.AddActivityViaSequence("taunt03");
			npc.SetPlaybackRate(0.65);
			npc.SetCycle(0.05);
			npc.m_iWhatAbilityDo = 1;
		}
	}
	if(npc.m_iWhatAbilityDo != 1)
		return false;
		
	int CurrentShotAt = npc.m_iChanged_WalkCycle - 200;
	if(CurrentShotAt > 12)
	{
		npc.m_iWhatAbilityDo = 0;
		npc.m_flDoingAnimation = 0.0;
		OshimunoTaishimoLineAoeStart(npc, gameTime);
		return false;
	}
	if(npc.m_flDoingAnimation < gameTime)
	{
		npc.SetPlaybackRate(2.5);
		npc.SetCycle(0.38);
		npc.m_iChanged_WalkCycle++;
		if(IsValidEnemy(npc.index, npc.m_iTarget))
		{
			float vecTarget[3]; WorldSpaceCenter(npc.m_iTarget, vecTarget);
			float VecSelfNpc[3]; WorldSpaceCenter(npc.index, VecSelfNpc);
			float ProjectileSpeed = 1200.0;
			float SliceDamage = 50.0 * RaidModeScaling;
			npc.FaceTowards(vecTarget, 20000.0);
			float Min, Max;
			int slicers;
			switch(npc.m_iOverlordComboAttack) // switches between 3 and 4 slashes
			{
				case 0:
				{
					Min = -12.0;
					Max = 12.0;
					slicers = 3;
					for(int i=0 ; i < slicers ; i++)
					{
						float shoot_ang[3];
						shoot_ang[1] = Min + (Max - Min) * (float(i) / float(slicers - 1));

						NemalAirSlice(npc.index, npc.m_iTarget, SliceDamage, shoot_ang, 255, 50, 50, 100.0, 8, ProjectileSpeed, "raygun_projectile_red", false, true, false);
					}
					npc.m_iOverlordComboAttack = 1;
				}
				case 1:
				{
					Min = -18.0;
					Max = 18.0;
					slicers = 4;
					for(int i=0 ; i < slicers ; i++)
					{
						float shoot_ang[3];
						shoot_ang[1] = Min + (Max - Min) * (float(i) / float(slicers - 1));

						NemalAirSlice(npc.index, npc.m_iTarget, SliceDamage, shoot_ang, 255, 50, 50, 100.0, 8, ProjectileSpeed, "raygun_projectile_red", false, true, false);
					}
					npc.m_iOverlordComboAttack = 0;
				}
			}
        }
		npc.m_flDoingAnimation = gameTime + 0.7;
	}
	return true;
}
bool OshimunoTaishimo_MassAoeSlashes(OshimunoTaishimo npc, float gameTime)
{
	if(npc.m_iWhatAbilityDo != 2 && npc.m_iWhatAbilityDo != 0)
		return false;
	if(npc.m_flDoingAnimation < gameTime)
	{
		if(npc.m_flMassAoeSlashes < gameTime)
		{
			if(!IsValidEnemy(npc.index, npc.m_iTarget))
				return false;
			if(!Can_I_See_Enemy_Only(npc.index, npc.m_iTarget))
				return false;

			npc.m_flSpeed = 720.0;
			npc.m_flMassAoeSlashes = gameTime + 35.0;
			npc.m_flDoingAnimation = gameTime + 2.0;
			npc.m_bisWalking = false;
			npc.StopPathing();
			npc.m_iChanged_WalkCycle = 300;
			npc.AddActivityViaSequence("taunt05");
			npc.m_iWhatAbilityDo = 2;
		}
	}
	if(npc.m_iWhatAbilityDo != 2)
		return false;
}
static void OshimunoTaishimoLineAoeStart(OshimunoTaishimo npc, float gameTime)
{
	npc.m_flAttackHappens = 0.0;
	npc.StopPathing();
	npc.m_bisWalking = false;
	npc.m_flLineAoeDetonate = gameTime + TAISHIMO_LINE_TIME;
	CreateTimer(TAISHIMO_LINE_TIME - TAISHIMO_LINE_SWING_LEAD + TAISHIMO_LINE_SWING_DELAY, Timer_TaishimoLineSwing, EntIndexToEntRef(npc.index), TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(TAISHIMO_LINE_TIME + TAISHIMO_LINE_IMPACT_DELAY, Timer_TaishimoLineImpact, EntIndexToEntRef(npc.index), TIMER_FLAG_NO_MAPCHANGE);

	float pos[3]; GetEntPropVector(npc.index, Prop_Data, "m_vecAbsOrigin", pos);
	float ang[3]; GetEntPropVector(npc.index, Prop_Data, "m_angRotation", ang);
	for(int i=0 ; i < TAISHIMO_LINE_COUNT ; i++)
	{
		float yawRad = ang[1] * FLOAT_PI / 180.0;
		pos[0] += Cosine(yawRad) * TAISHIMO_LINE_START;
		pos[1] += Sine(yawRad) * TAISHIMO_LINE_START;
		f3_NpcSavePos[npc.index] = pos;
		npc.m_flLineAoeYaw = ang[1] + 360.0/TAISHIMO_LINE_COUNT*i;
		OshimunoTaishimoLineAoeDraw(npc, gameTime);
	}
}

static Action Timer_TaishimoLineSwing(Handle timer, any ref)
{
	int entity = EntRefToEntIndex(ref);
	if(entity <= MaxClients || !IsValidEntity(entity))
		return Plugin_Handled;

	OshimunoTaishimo npc = view_as<OshimunoTaishimo>(entity);
	if(!npc.m_flLineAoeDetonate)
		return Plugin_Handled;

	npc.AddGesture("ACT_MP_ATTACK_STAND_MELEE",_,_,_, 0.85);
	EmitSoundToAll(g_TaishimoLineWindUpSound, npc.index, SNDCHAN_STATIC, NORMAL_ZOMBIE_SOUNDLEVEL, _, NORMAL_ZOMBIE_VOLUME);
	return Plugin_Handled;
}

static Action Timer_TaishimoLineImpact(Handle timer, any ref)
{
	int entity = EntRefToEntIndex(ref);
	if(entity <= MaxClients || !IsValidEntity(entity))
		return Plugin_Handled;

	EmitSoundToAll(g_TaishimoLineImpactSound, entity, SNDCHAN_STATIC, NORMAL_ZOMBIE_SOUNDLEVEL, _, NORMAL_ZOMBIE_VOLUME);
	return Plugin_Handled;
}

static void OshimunoTaishimoLineAoeDraw(OshimunoTaishimo npc, float gameTime)
{
	float remaining = npc.m_flLineAoeDetonate - gameTime;
	if(remaining < 0.0)
		remaining = 0.0;

	int color[4];
	color[0] = 255;
	color[1] = RoundToNearest(255.0 * (remaining / TAISHIMO_LINE_TIME));
	color[2] = 0;
	color[3] = 255;

	OshimunoTaishimoLineAoeDrawRects(npc, 0.0, color, 0.15);
}

static void OshimunoTaishimoLineAoeDrawRects(OshimunoTaishimo npc, float expand, const int color[4], float life)
{
	float yawRad = npc.m_flLineAoeYaw * FLOAT_PI / 180.0;
	float fwdX = Cosine(yawRad);
	float fwdY = Sine(yawRad);
	float leftX = -fwdY;
	float leftY = fwdX;

	float anchor[3];
	anchor = f3_NpcSavePos[npc.index];
	anchor[2] += 4.0;
	anchor[0] -= fwdX * expand;
	anchor[1] -= fwdY * expand;

	float length = TAISHIMO_LINE_LENGTH + (expand * 2.0);
	float halfWidth = (TAISHIMO_LINE_WIDTH * 0.5) + expand;
	float c1[3], c2[3], c3[3], c4[3];
	c1[0] = anchor[0] + (leftX * halfWidth);
	c1[1] = anchor[1] + (leftY * halfWidth);
	c1[2] = anchor[2];
	c2[0] = anchor[0] + (leftX * halfWidth);
	c2[1] = anchor[1] + (leftY * halfWidth);
	c2[2] = anchor[2];
	c3[0] = c1[0] + (fwdX * length);
	c3[1] = c1[1] + (fwdY * length);
	c3[2] = anchor[2];
	c4[0] = c2[0] + (fwdX * length);
	c4[1] = c2[1] + (fwdY * length);
	c4[2] = anchor[2];

	TE_SetupBeamPoints(c1, c2, g_TaishimoLineLaser, -1, 0, 0, life, 4.0, 4.0, 0, 0.0, color, 0);
	TE_SendToAll();
	TE_SetupBeamPoints(c1, c3, g_TaishimoLineLaser, -1, 0, 0, life, 4.0, 4.0, 0, 0.0, color, 0);
	TE_SendToAll();
	TE_SetupBeamPoints(c2, c4, g_TaishimoLineLaser, -1, 0, 0, life, 4.0, 4.0, 0, 0.0, color, 0);
	TE_SendToAll();
	TE_SetupBeamPoints(c3, c4, g_TaishimoLineLaser, -1, 0, 0, life, 4.0, 4.0, 0, 0.0, color, 0);
	TE_SendToAll();
}

static void TaishimoLineFadeFrame(any ref)
{
	int entity = EntRefToEntIndex(ref);
	if(entity <= MaxClients || !IsValidEntity(entity))
		return;

	OshimunoTaishimo npc = view_as<OshimunoTaishimo>(entity);
	float gameTime = GetGameTime(npc.index);
	if(!npc.m_flLineAoeFade)
		return;

	if(npc.m_flLineAoeFade <= gameTime)
	{
		npc.m_flLineAoeFade = 0.0;
		return;
	}

	if(gameTime >= npc.m_flLineAoeFadeDraw)
	{
		npc.m_flLineAoeFadeDraw = gameTime + TAISHIMO_LINE_FADE_STEP;

		float frac = 1.0 - ((npc.m_flLineAoeFade - gameTime) / TAISHIMO_LINE_FADE_TIME);
		if(frac < 0.0)
			frac = 0.0;

		int color[4];
		color[0] = 255;
		color[1] = 0;
		color[2] = 0;
		color[3] = RoundToNearest(255.0 * (1.0 - frac));

		OshimunoTaishimoLineAoeDrawRects(npc, TAISHIMO_LINE_SPREAD * frac, color, 0.1);
	}
	RequestFrame(TaishimoLineFadeFrame, ref);
}

static void OshimunoTaishimoLineAoeDetonate(OshimunoTaishimo npc)
{
	float yawRad = npc.m_flLineAoeYaw * FLOAT_PI / 180.0;
	float fwdX = Cosine(yawRad);
	float fwdY = Sine(yawRad);
	float leftX = -fwdY;
	float leftY = fwdX;

	float anchor[3];
	anchor = f3_NpcSavePos[npc.index];

	float halfWidth = (TAISHIMO_LINE_WIDTH * 0.5) + 24.0;
	for(int client = 1; client <= MaxClients; client++)
	{
		if(!IsClientInGame(client) || !IsPlayerAlive(client) || GetClientTeam(client) != TFTeam_Red)
			continue;

		float pos[3];
		GetClientAbsOrigin(client, pos);
		float dx = pos[0] - anchor[0];
		float dy = pos[1] - anchor[1];
		float dz = pos[2] - anchor[2];
		if(dz > 120.0 || dz < -120.0)
			continue;

		float fwdDist = (dx * fwdX) + (dy * fwdY);
		if(fwdDist < -24.0 || fwdDist > (TAISHIMO_LINE_LENGTH + 24.0))
			continue;

		float leftDist = (dx * leftX) + (dy * leftY);
		if(FloatAbs(leftDist) > halfWidth && FloatAbs(leftDist) > halfWidth && FloatAbs(leftDist) > halfWidth)
			continue;

		float at[3];
		WorldSpaceCenter(client, at);
		EmitSoundToAll(g_MeleeAttackSounds[GetRandomInt(0, sizeof(g_MeleeAttackSounds) - 1)], client, SNDCHAN_AUTO, NORMAL_ZOMBIE_SOUNDLEVEL, _, NORMAL_ZOMBIE_VOLUME);
		SDKHooks_TakeDamage(client, npc.index, npc.index, TAISHIMO_LINE_DAMAGE * RaidModeScaling, DMG_CLUB, -1, _, at);
		float VecMe[3]; WorldSpaceCenter(npc.index, VecMe);
		float VecEnemy[3]; WorldSpaceCenter(client, VecEnemy);

		float AngleVec[3];
		MakeVectorFromPoints(VecMe, VecEnemy, AngleVec);
		GetVectorAngles(AngleVec, AngleVec);
		AngleVec[0] = -60.0;
		Custom_Knockback(npc.index, client, 1000.0, true, true, true, .OverrideLookAng = AngleVec);
		ApplyStatusEffect(npc.index, client, "Ragdolled", 1.5);	
		FreezeNpcInTime(client, 1.5);
	}
}