#pragma semicolon 1
#pragma newdecls required


static const char g_DeathSounds[][] =
{
	"vo/engineer_paincrticialdeath01.mp3",
	"vo/engineer_paincrticialdeath02.mp3",
	"vo/engineer_paincrticialdeath03.mp3",
};

static const char g_HurtSounds[][] =
{
	"vo/engineer_painsharp01.mp3",
	"vo/engineer_painsharp02.mp3",
	"vo/engineer_painsharp03.mp3",
	"vo/engineer_painsharp04.mp3",
	"vo/engineer_painsharp05.mp3",
	"vo/engineer_painsharp06.mp3",
	"vo/engineer_painsharp07.mp3",
	"vo/engineer_painsharp08.mp3",
};

static const char g_IdleAlertedSounds[][] =
{
	"vo/engineer_meleedare01.mp3",
	"vo/engineer_meleedare02.mp3",
	"vo/engineer_meleedare03.mp3",
};

static const char g_MeleeHitSounds[][] =
{
	"weapons/cbar_hit1.wav",
	"weapons/cbar_hit2.wav"
};

static const char g_MeleeAttackSounds[][] =
{
	"weapons/machete_swing.wav",
};

static const char g_RangedAttackSounds[][] =
{
	"weapons/cleaver_throw.wav",
};


int OshimunoAntayotoId;
int OshimunoAntayotoIDReturn()
{
	return OshimunoAntayotoId;
}

static int g_AntayotoSlashLaser = -1;
static const char g_AntayotoAoeDetonateSound[] = "player/taunt_yeti_standee_break.wav";
static const char g_AntayotoConePlaceSound[] = "weapons/stickybomblauncher_charge_up.wav";
static const char g_AntayotoBombModel[] = "models/weapons/w_models/w_stickybomb.mdl";
static const char g_AntayotoBombExplodeSound[] = "weapons/pipe_bomb1.wav";
static float g_AntayotoRotationStart;
static int g_AntayotoRotationStage;
static int g_AntayotoHealthPhase;
static bool g_AntayotoSmokePending;
static float g_AntayotoSmokeImmuneUntil;
static float g_AntayotoSmokeHideUntil;
static float g_AntayotoConePlaceSoundLen;
static float g_AntayotoLineSmokeTime;
static int g_AntayotoKunaiThrowCount;

#define ANTAYOTO_CONE_MAX 3
static float g_AntayotoConeYawDir[ANTAYOTO_CONE_MAX];
static float g_AntayotoConeDetTime[ANTAYOTO_CONE_MAX];
static int g_AntayotoConeTotal;
static int g_AntayotoConeIndex;
static float g_AntayotoConePlaceTime;
static float g_AntayotoConeTeleDraw;
static char g_AntayotoConeSwingAnim[64];

#define ANTAYOTO_LINE_SLOTS 3
static bool g_AntayotoLineSlotChosen[ANTAYOTO_LINE_SLOTS][MAXPLAYERS + 1];
static bool g_AntayotoLineSlotActive[ANTAYOTO_LINE_SLOTS];
static float g_AntayotoLineSlotYaw[ANTAYOTO_LINE_SLOTS];
static float g_AntayotoLineSlotLen[ANTAYOTO_LINE_SLOTS];
static int g_AntayotoLineSlotCount;

static float OshimunoAntayotoWavDuration(const char[] soundPath)
{
	char fullPath[PLATFORM_MAX_PATH];
	FormatEx(fullPath, sizeof(fullPath), "sound/%s", soundPath);
	File file = OpenFile(fullPath, "rb", true);
	if(file == null)
		return 0.0;

	int header[3];
	if(file.Read(header, 3, 4) != 3 || header[0] != 0x46464952 || header[2] != 0x45564157)
	{
		delete file;
		return 0.0;
	}

	int byteRate = 0;
	int dataSize = 0;
	int chunk[2];
	while(file.Read(chunk, 2, 4) == 2)
	{
		if(chunk[0] == 0x20746D66)
		{
			if(chunk[1] < 16)
				break;

			int fmt[4];
			if(file.Read(fmt, 4, 4) != 4)
				break;

			byteRate = fmt[2];
			file.Seek(chunk[1] - 16 + (chunk[1] & 1), SEEK_CUR);
		}
		else if(chunk[0] == 0x61746164)
		{
			dataSize = chunk[1];
			break;
		}
		else
		{
			file.Seek(chunk[1] + (chunk[1] & 1), SEEK_CUR);
		}
	}
	delete file;
	if(byteRate <= 0 || dataSize <= 0)
		return 0.0;

	return float(dataSize) / float(byteRate);
}

void OshimunoAntayotoOnMapStart()
{
	PrecacheSoundArray(g_DeathSounds);
	PrecacheSoundArray(g_HurtSounds);
	PrecacheSoundArray(g_IdleAlertedSounds);
	PrecacheSoundArray(g_MeleeHitSounds);
	PrecacheSoundArray(g_MeleeAttackSounds);
	PrecacheSoundArray(g_RangedAttackSounds);
	PrecacheSound(g_AntayotoAoeDetonateSound);
	PrecacheSound(g_AntayotoConePlaceSound);
	PrecacheSound(g_AntayotoBombExplodeSound);
	g_AntayotoConePlaceSoundLen = OshimunoAntayotoWavDuration(g_AntayotoConePlaceSound);
	if(g_AntayotoConePlaceSoundLen <= 0.0)
	{
		LogMessage("Antayoto: could not read wav length for %s; cone place sound plays at normal pitch and is only cut at detonation.", g_AntayotoConePlaceSound);
	}
	PrecacheSoundCustom("#zombiesurvival/aprilfools/reteptheme_1.mp3");
	g_AntayotoSlashLaser = PrecacheModel("sprites/laserbeam.vmt");
	PrecacheModel(g_AntayotoBombModel);
	NPCData data;
	strcopy(data.Name, sizeof(data.Name), "Antayoto");
	strcopy(data.Plugin, sizeof(data.Plugin), "npc_oshimuno_antayoto");
	strcopy(data.Icon, sizeof(data.Icon), "blackheavysoul");
	data.IconCustom = true;
	data.Flags = MVM_CLASS_FLAG_MINIBOSS|MVM_CLASS_FLAG_ALWAYSCRIT;
	data.Category = Type_Raid;
	data.Func = ClotSummon;
	OshimunoAntayotoId = NPC_Add(data);
}
 
static any ClotSummon(int client, float vecPos[3], float vecAng[3], int team, const char[] data)
{
	return OshimunoAntayoto(vecPos, vecAng, team, data);
}

methodmap OshimunoAntayoto < CClotBody
{
	property float m_flConeWindUp
	{
		public get()							{ return fl_NextChargeSpecialAttack[this.index]; }
		public set(float TempValueForProperty) 	{ fl_NextChargeSpecialAttack[this.index] = TempValueForProperty; }
	}
	property float m_flSlashAoeDetonate
	{
		public get()							{ return fl_AbilityOrAttack[this.index][1]; }
		public set(float TempValueForProperty) 	{ fl_AbilityOrAttack[this.index][1] = TempValueForProperty; }
	}
	property float m_flSlashAoeYaw
	{
		public get()							{ return fl_AbilityOrAttack[this.index][2]; }
		public set(float TempValueForProperty) 	{ fl_AbilityOrAttack[this.index][2] = TempValueForProperty; }
	}
	property float m_flSlashAoeFade
	{
		public get()							{ return fl_AbilityOrAttack[this.index][3]; }
		public set(float TempValueForProperty) 	{ fl_AbilityOrAttack[this.index][3] = TempValueForProperty; }
	}
	property float m_flSlashAoeFadeDraw
	{
		public get()							{ return fl_AbilityOrAttack[this.index][4]; }
		public set(float TempValueForProperty) 	{ fl_AbilityOrAttack[this.index][4] = TempValueForProperty; }
	}
	property float m_flBombThrowCD
	{
		public get()							{ return fl_AbilityOrAttack[this.index][5]; }
		public set(float TempValueForProperty) 	{ fl_AbilityOrAttack[this.index][5] = TempValueForProperty; }
	}
	property float m_flTeleportAwayCD
	{
		public get()							{ return fl_AbilityOrAttack[this.index][6]; }
		public set(float TempValueForProperty) 	{ fl_AbilityOrAttack[this.index][6] = TempValueForProperty; }
	}
	property int m_iWhatAbilityDo
	{
		public get()							{ return i_MedkitAnnoyance[this.index]; }
		public set(int TempValueForProperty) 	{ i_MedkitAnnoyance[this.index] = TempValueForProperty; }
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

	public OshimunoAntayoto(float vecPos[3], float vecAng[3], int ally, const char[] data)
	{
		OshimunoAntayoto npc = view_as<OshimunoAntayoto>(CClotBody(vecPos, vecAng, "models/player/spy.mdl", "1.15", "40000", ally, false, true, true,true)); //giant!
		float gameTime = GetGameTime(npc.index);

		g_AntayotoRotationStart = gameTime;
		g_AntayotoRotationStage = 0;
		g_AntayotoHealthPhase = 0;
		g_AntayotoSmokePending = false;
		g_AntayotoSmokeImmuneUntil = 0.0;
		g_AntayotoSmokeHideUntil = 0.0;
		g_AntayotoLineSmokeTime = 0.0;
		g_AntayotoKunaiThrowCount = 0;
		g_AntayotoConeTotal = 0;
		g_AntayotoConeIndex = 0;
		g_AntayotoLineSlotCount = 1;
		OshimunoAntayotoBombsReset();
		for(int slot_wipe = 0; slot_wipe < ANTAYOTO_LINE_SLOTS; slot_wipe++)
		{
			g_AntayotoLineSlotActive[slot_wipe] = false;
			for(int client_wipe = 1; client_wipe <= MaxClients; client_wipe++)
			{
				g_AntayotoLineSlotChosen[slot_wipe][client_wipe] = false;
			}
		}
		b_NoHealthbar[npc.index] = false;
		b_NpcIsInvulnerable[npc.index] = false;
		b_ThisEntityIgnoredBeingCarried[npc.index] = false;

		i_NpcWeight[npc.index] = 3;
		KillFeed_SetKillIcon(npc.index, "back_scratcher");
		
		int iActivity = npc.LookupActivity("ACT_MP_RUN_MELEE");
		if(iActivity > 0) npc.StartActivity(iActivity);

		npc.m_iWearable1 = npc.EquipItem("head", "models/workshop_partner/weapons/c_models/c_shogun_kunai/c_shogun_kunai.mdl");
		npc.m_iWearable2 = npc.EquipItem("head", "models/player/items/spy/spy_rose.mdl");
		SetEntProp(npc.m_iWearable2, Prop_Send, "m_nSkin", 1);
		npc.m_iWearable3 = npc.EquipItem("head", "models/workshop/player/items/all_class/fall2013_hong_kong_cone/fall2013_hong_kong_cone_spy.mdl");
		SetEntProp(npc.m_iWearable3, Prop_Send, "m_nSkin", 1);
		npc.m_iWearable4 = npc.EquipItem("head", "models/workshop/player/items/all_class/spr18_robin_walkers/spr18_robin_walkers_spy.mdl");
		SetEntProp(npc.m_iWearable4, Prop_Send, "m_nSkin", 1);
		npc.m_iWearable5 = npc.EquipItem("head", "models/workshop/player/items/spy/sum24_tuxedo_royale_style1/sum24_tuxedo_royale_style1.mdl");
		SetEntProp(npc.m_iWearable5, Prop_Send, "m_nSkin", 1);
		npc.m_iWearable6 = npc.EquipItem("head", "models/workshop/player/items/spy/dec25_aristocravat/dec25_aristocravat.mdl");
		SetEntProp(npc.m_iWearable6, Prop_Send, "m_nSkin", 1);

		SetEntProp(npc.index, Prop_Send, "m_nSkin", 1);
		SetVariantInt(2);
		AcceptEntityInput(npc.index, "SetBodyGroup");
		
		npc.m_flNextMeleeAttack = 0.0;
		
		npc.m_iBleedType = BLEEDTYPE_NORMAL;
		npc.m_iStepNoiseType = STEPSOUND_GIANT;	
		npc.m_iNpcStepVariation = STEPTYPE_NORMAL;
		npc.m_flMeleeArmor = 1.25;	
		
		func_NPCDeath[npc.index] = OshimunoAntayoto_Death;
		func_NPCOnTakeDamage[npc.index] = OshimunoAntayoto_OnTakeDamage;
		func_NPCThink[npc.index] = OshimunoAntayoto_Think;
		func_NPCFuncWin[npc.index] = OshimunoAntayoto_Win;

		RaidModeTime = gameTime + 200.0;
		RaidBossActive = EntIndexToEntRef(npc.index);
		RaidAllowsBuildings = false;
		RaidAllowLastman = true;
		
		MusicEnum music;
		strcopy(music.Path, sizeof(music.Path), "#zombiesurvival/aprilfools/reteptheme_1.mp3");
		music.Time = 110;
		music.Volume = 2.0;
		music.Custom = true;
		strcopy(music.Name, sizeof(music.Name), "Retep theme");
		strcopy(music.Artist, sizeof(music.Artist), "terraria peter griffin mod");
		Music_SetRaidMusic(music);

		NPCTalkMessage(npc.index, "INTRO DIALOGUE!");

		WaveStart_SubWaveStart(gameTime + 270.0);
		GiveOneRevive();
		RemoveAllDamageAddition();
		npc.StartPathing();
		npc.m_flSpeed = 320.0;

		BlockLoseSay = false;
		
		EmitSoundToAll("npc/zombie_poison/pz_alert1.wav", _, _, _, _, 1.0);	
		EmitSoundToAll("npc/zombie_poison/pz_alert1.wav", _, _, _, _, 1.0);	
		b_thisNpcIsARaid[npc.index] = true;
		b_angered_twice[npc.index] = false;
		for(int client_clear=1; client_clear<=MaxClients; client_clear++)
		{
			fl_AlreadyStrippedMusic[client_clear] = 0.0; //reset to 0
		}
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
				ShowGameText(client_check, "item_armor", 1, "Antayoto Arrived");
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
		return npc;
	}
}

static void NPCTalkMessage(int entity, const char[] message)
{
	PrintNPCMessageWithPrefixes(entity, "black", message);
}

static void OshimunoAntayoto_Think(int iNPC)
{
	OshimunoAntayoto npc = view_as<OshimunoAntayoto>(iNPC);
	float gameTime = GetGameTime(npc.index);
	if(npc.m_flNextDelayTime > gameTime)
	{
		return;
	}
	npc.m_flNextDelayTime =gameTime + DEFAULT_UPDATE_DELAY_FLOAT;
	npc.Update();

	OshimunoAntayoto_BombsThink(npc, gameTime);

	if(LastMann)
	{
		if(!npc.m_fbGunout)
		{
			npc.m_fbGunout = true;
			NPCTalkMessage(npc.index, "lastmann message.");
		}
	}
	if(i_RaidGrantExtra[npc.index] == RAIDITEM_INDEX_WIN_COND)
	{
		npc.m_bisWalking = false;
		OshimunoAntayotoSetInvisible(npc, false);
		npc.AddActivityViaSequence("selectionMenu_Idle");
		npc.SetCycle(0.01);
		func_NPCThink[npc.index] = INVALID_FUNCTION;
		
		NPCTalkMessage(npc.index, "win message.");
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
	if(OshimunoAntayoto_Rotation(npc, gameTime))
	{
		return;
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
		SetGoalVectorIndex = OshimunoAntayoto_SelfDefense(npc, gameTime, npc.m_iTarget, flDistanceToTarget); 

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
		OshimunoAntayotoAnimationChange(npc);
	}
}

static Action OshimunoAntayoto_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	OshimunoAntayoto npc = view_as<OshimunoAntayoto>(victim);
		
	if(npc.m_iWhatAbilityDo == 5 || npc.m_iWhatAbilityDo == 6 || g_AntayotoSmokeImmuneUntil != 0.0)
	{
		damage = 0.0;
		return Plugin_Handled;
	}

	if(attacker <= 0)
		return Plugin_Continue;

	if(npc.m_flHeadshotCooldown < GetGameTime(npc.index))
	{
		npc.m_flHeadshotCooldown = GetGameTime(npc.index) + DEFAULT_HURTDELAY;
		npc.m_blPlayHurtAnimation = true;
	}
	return Plugin_Changed;
}
public void OshimunoAntayoto_Win(int entity)
{
	i_RaidGrantExtra[entity] = RAIDITEM_INDEX_WIN_COND;
	BlockLoseSay = true;
	NPCTalkMessage(entity, "get owned.");
}

static void OshimunoAntayoto_Death(int entity)
{
	RaidBossActive = INVALID_ENT_REFERENCE;
	OshimunoAntayotoBombsReset();
	g_AntayotoSmokeImmuneUntil = 0.0;
	g_AntayotoSmokeHideUntil = 0.0;
	StopSound(entity, SNDCHAN_STATIC, g_AntayotoConePlaceSound);
	b_NoHealthbar[entity] = false;
	b_NpcIsInvulnerable[entity] = false;
	b_ThisEntityIgnoredBeingCarried[entity] = false;
	if(BlockLoseSay)
		return;

	NPCTalkMessage(entity, "Nvm fuck you i made it all up.");
	NPCTalkMessage(entity, "*dies of death*");
}

void OshimunoAntayotoAnimationChange(OshimunoAntayoto npc)
{
	
	if(npc.m_iChanged_WalkCycle == 0)
	{
		npc.m_iChanged_WalkCycle = -1;
	}

	if(npc.IsOnGround())
	{
		if(npc.m_iChanged_WalkCycle != 3)
		{
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
			npc.m_flSpeed = 320.0;
			npc.m_bisWalking = false;
			npc.m_iChanged_WalkCycle = 4;
			npc.SetActivity("ACT_MP_JUMP_FLOAT_MELEE");
			npc.StartPathing();
		}	
	}

}

int OshimunoAntayoto_SelfDefense(OshimunoAntayoto npc, float gameTime, int target, float distance)
{
	if(npc.m_iWhatAbilityDo == 2)
	{	
		return 0;
	}
	if(npc.m_flAttackHappens)
	{
		if(npc.m_flAttackHappens < gameTime)
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

							float damage = 12.0;

							SDKHooks_TakeDamage(targetTrace, npc.index, npc.index, damage * RaidModeScaling, DMG_CLUB, -1, _, vecHit);								

							bool Knocked = false;
										
							if(IsValidClient(targetTrace))
							{
								if (IsInvuln(targetTrace))
								{
									Knocked = true;
									Custom_Knockback(npc.index, targetTrace, 900.0, true);
									TF2_AddCondition(targetTrace, TFCond_LostFooting, 0.5);
									TF2_AddCondition(targetTrace, TFCond_AirCurrent, 0.5);
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
					npc.AddGesture("ACT_MP_ATTACK_STAND_MELEE",_,_,_,3.0);
							
					npc.m_flAttackHappens = gameTime + 0.1;
					npc.m_flNextMeleeAttack = gameTime + 0.15;
					npc.m_flDoingAnimation = gameTime + 0.1;
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

//cone stuff

#define ANTAYOTO_SLASH_WIDTH 100.0
#define ANTAYOTO_SLASH_LENGTH 800.0
#define ANTAYOTO_SLASH_GAP 100.0
#define ANTAYOTO_SLASH_START 50.0
#define ANTAYOTO_SLASH_TIME 1.5
#define ANTAYOTO_SLASH_SWING_LEAD 0.75
#define ANTAYOTO_SLASH_SWING_DELAY 0.1953
#define ANTAYOTO_SLASH_IMPACT_DELAY (-0.04)
#define ANTAYOTO_SLASH_FADE_TIME 0.15
#define ANTAYOTO_SLASH_SPREAD 75.0
#define ANTAYOTO_SLASH_FADE_STEP 0.045
#define ANTAYOTO_SLASH_DAMAGE 100.0

#define ANTAYOTO_ROTATION_STEP 10.0
#define ANTAYOTO_THROW_STATE_DURATION 2.0
#define ANTAYOTO_INITIAL_THROW 0.5
#define ANTAYOTO_KUNAI_THROW_COOLDOWN 0.3
#define ANTAYOTO_KUNAI_DAMAGE 35.0
#define ANTAYOTO_KUNAI_SPEED 1000.0
#define ANTAYOTO_KUNAI_LEAD 150.0
#define ANTAYOTO_CONE_ANIM_TIME 0.5
#define ANTAYOTO_CONE_HOLD_TIME 2.0
#define ANTAYOTO_CONE_LENGTH 800.0
#define ANTAYOTO_CONE_HALF_ANGLE 45.0
#define ANTAYOTO_CONE_DAMAGE 500.0
#define ANTAYOTO_CONE_FADE_TIME 0.15
#define ANTAYOTO_CONE_SPREAD 75.0
#define ANTAYOTO_CONE_TELEGRAPH_ALPHA 255
#define ANTAYOTO_CONE_STAGGER 2.0
#define ANTAYOTO_CONE_ANIM_RATE 1.0
#define ANTAYOTO_CONE_ANIM_RATE2 1.2
#define ANTAYOTO_LINE_DETONATE_TIME 1.0
#define ANTAYOTO_LINE_MIN_LENGTH 800.0
#define ANTAYOTO_LINE_PADDING 300.0
#define ANTAYOTO_LINE_SMOKE_PERIOD 0.75
#define ANTAYOTO_LINE_SMOKE_LIFE 0.75
#define ANTAYOTO_LINE_SMOKE_WINDDOWN 3
#define ANTAYOTO_BOMB_COUNT 4
#define ANTAYOTO_BOMB_DISTANCE 300.0
#define ANTAYOTO_BOMB_SPEED 800.0
#define ANTAYOTO_BOMB_FUSE 3.0
#define ANTAYOTO_BOMB_RADIUS 200.0
#define ANTAYOTO_BOMB_DAMAGE 100.0
#define ANTAYOTO_BOMB_SCALE 3.0
#define ANTAYOTO_SMOKE_HIDE_TIME 4.0
#define ANTAYOTO_SMOKE_CLEAR_LEAD 3.0

static int g_AntayotoBombState[ANTAYOTO_BOMB_COUNT];
static int g_AntayotoBombProp[ANTAYOTO_BOMB_COUNT] = { -1, ... };
static float g_AntayotoBombPos[ANTAYOTO_BOMB_COUNT][3];
static float g_AntayotoBombTime[ANTAYOTO_BOMB_COUNT];
static float g_AntayotoBombDraw[ANTAYOTO_BOMB_COUNT];
static bool OshimunoAntayoto_Rotation(OshimunoAntayoto npc, float gameTime)
{
	int health = GetEntProp(npc.index, Prop_Data, "m_iHealth");
	int maxHealth = GetEntProp(npc.index, Prop_Data, "m_iMaxHealth");
	if(g_AntayotoHealthPhase == 0 && float(health) <= (float(maxHealth) * 0.66))
	{
		g_AntayotoHealthPhase = 1;
		g_AntayotoSmokePending = true;
	}
	else if(g_AntayotoHealthPhase == 1 && float(health) <= (float(maxHealth) * 0.33))
	{
		g_AntayotoHealthPhase = 2;
		g_AntayotoSmokePending = true;
	}
	switch(npc.m_iWhatAbilityDo)
	{
		case 3:
		{
			return OshimunoAntayoto_KunaiJump(npc, gameTime);
		}
		case 4:
		{
			return OshimunoAntayoto_ConeNuke(npc, gameTime);
		}
		case 5:
		{
			return OshimunoAntayoto_LinePhase(npc, gameTime);
		}
		case 6:
		{
			return OshimunoAntayoto_SmokeHide(npc, gameTime);
		}
	}
	if(npc.m_iWhatAbilityDo != 0)
		return false;
	if(g_AntayotoSmokePending)
	{
		OshimunoAntayoto_SmokeEscape(npc, gameTime);
		return true;
	}
	if(!IsValidEnemy(npc.index, npc.m_iTarget))
		return false;
	float elapsed = gameTime - g_AntayotoRotationStart;
	switch(g_AntayotoRotationStage)
	{
		case 0:
		{
			if(elapsed >= (ANTAYOTO_ROTATION_STEP * 1.0))
			{
				g_AntayotoRotationStage = 1;
				OshimunoAntayoto_KunaiJumpStart(npc, gameTime);
				return true;
			}
		}
		case 1:
		{
			if(elapsed >= (ANTAYOTO_ROTATION_STEP * 2.0))
			{
				g_AntayotoRotationStage = 2;
				OshimunoAntayoto_ConeNukeStart(npc, gameTime);
				return true;
			}
		}
		case 2:
		{
			if(elapsed >= (ANTAYOTO_ROTATION_STEP * 3.0))
			{
				g_AntayotoRotationStage = 3;
				OshimunoAntayoto_KunaiJumpStart(npc, gameTime);
				return true;
			}
		}
		case 3:
		{
			if(elapsed >= (ANTAYOTO_ROTATION_STEP * 4.0))
			{
				g_AntayotoRotationStage = 4;
				OshimunoAntayoto_ConeNukeStart(npc, gameTime);
				return true;
			}
		}
		case 4:
		{
			if(elapsed >= (ANTAYOTO_ROTATION_STEP * 5.0))
			{
				g_AntayotoRotationStage = 5;
				OshimunoAntayoto_KunaiJumpStart(npc, gameTime);
				return true;
			}
		}
		case 5:
		{
			if(elapsed >= (ANTAYOTO_ROTATION_STEP * 6.0))
			{
				g_AntayotoRotationStage = 6;
				OshimunoAntayoto_LinePhaseStart(npc, gameTime);
				return true;
			}
		}
	}
	return false;
}

static void OshimunoAntayotoKunaiAimAt(int target, float aimPos[3])
{
	WorldSpaceCenter(target, aimPos);
	float vecLead[3];
	GetEntPropVector(target, Prop_Data, "m_vecAbsVelocity", vecLead);
	if(GetVectorLength(vecLead, true) > 1.0)
	{
		NormalizeVector(vecLead, vecLead);
		aimPos[0] += vecLead[0] * ANTAYOTO_KUNAI_LEAD;
		aimPos[1] += vecLead[1] * ANTAYOTO_KUNAI_LEAD;
		aimPos[2] += vecLead[2] * ANTAYOTO_KUNAI_LEAD;
	}
}

static void OshimunoAntayotoThrowKunai(OshimunoAntayoto npc, float aimPos[3])
{
	int projectile = npc.FireArrow(aimPos, ANTAYOTO_KUNAI_DAMAGE, ANTAYOTO_KUNAI_SPEED, "models/workshop_partner/weapons/c_models/c_shogun_kunai/c_shogun_kunai.mdl", 1.5);
	int trail = Trail_Attach(projectile, ARROW_TRAIL, 80, 0.16, 15.0, 6.0, 1);
	i_WandParticle[projectile] = EntIndexToEntRef(trail);
	CreateTimer(6.0, Timer_RemoveEntity, EntIndexToEntRef(trail), TIMER_FLAG_NO_MAPCHANGE);
	SetParent(projectile, trail);
}

static void OshimunoAntayoto_KunaiJumpStart(OshimunoAntayoto npc, float gameTime)
{
	float vBackoffPos[3];
	BackoffFromOwnPositionAndAwayFromEnemy(npc, npc.m_iTarget,_,vBackoffPos);
	vBackoffPos[2] += 275.0;
	PluginBot_Jump(npc.index, vBackoffPos);
	npc.m_iWhatAbilityDo = 3;
	npc.m_iChanged_WalkCycle = 600;
	g_AntayotoKunaiThrowCount = 0;
	npc.m_flTeleportAwayCD = gameTime + ANTAYOTO_THROW_STATE_DURATION;
	npc.m_flBombThrowCD = gameTime + ANTAYOTO_INITIAL_THROW;
	npc.m_flNextMeleeAttack = gameTime + ANTAYOTO_THROW_STATE_DURATION;
}

static bool OshimunoAntayoto_KunaiJump(OshimunoAntayoto npc, float gameTime)
{
	if(npc.m_flTeleportAwayCD < gameTime)
	{
		npc.m_iWhatAbilityDo = 0;
		npc.m_iChanged_WalkCycle = 0;
		return false;
	}
	if(npc.m_flBombThrowCD < gameTime && IsValidEnemy(npc.index, npc.m_iTarget))
	{
		float EnemyPos[3];
		OshimunoAntayotoKunaiAimAt(npc.m_iTarget, EnemyPos);
		npc.FaceTowards(EnemyPos, 15000.0);
		float VecSelfNpc[3];
		WorldSpaceCenter(npc.index, VecSelfNpc);
		float vecThrowDir[3];
		SubtractVectors(EnemyPos, VecSelfNpc, vecThrowDir);
		float vecThrowAng[3];
		GetVectorAngles(vecThrowDir, vecThrowAng);
		float vecSetAng[3];
		GetEntPropVector(npc.index, Prop_Data, "m_angRotation", vecSetAng);
		vecSetAng[1] = vecThrowAng[1];
		TeleportEntity(npc.index, NULL_VECTOR, vecSetAng, NULL_VECTOR);
		OshimunoAntayotoThrowKunai(npc, EnemyPos);
		g_AntayotoKunaiThrowCount++;
		bool sideVolley = false;
		if(g_AntayotoHealthPhase >= 2)
		{
			sideVolley = (g_AntayotoKunaiThrowCount == 1 || g_AntayotoKunaiThrowCount == 3 || g_AntayotoKunaiThrowCount == 5);
		}
		else if(g_AntayotoHealthPhase >= 1)
		{
			sideVolley = (g_AntayotoKunaiThrowCount == 1 || g_AntayotoKunaiThrowCount == 4);
		}
		if(sideVolley)
		{
			for(int client = 1; client <= MaxClients; client++)
			{
				if(client == npc.m_iTarget)
					continue;
				if(!IsClientInGame(client) || !IsPlayerAlive(client) || GetClientTeam(client) != TFTeam_Red)
					continue;
				float sidePos[3];
				OshimunoAntayotoKunaiAimAt(client, sidePos);
				OshimunoAntayotoThrowKunai(npc, sidePos);
			}
		}
		npc.m_flBombThrowCD = gameTime + ANTAYOTO_KUNAI_THROW_COOLDOWN;
		npc.PlayRangedSound();
	}
	if(npc.m_flDoingAnimation < gameTime)
	{
		OshimunoAntayotoAnimationChange(npc);
	}
	return true;
}

static void OshimunoAntayoto_ConeNukeStart(OshimunoAntayoto npc, float gameTime)
{
	float vecTarget[3];
	WorldSpaceCenter(npc.m_iTarget, vecTarget);
	npc.FaceTowards(vecTarget, 15000.0);
	npc.m_iWhatAbilityDo = 4;
	npc.m_iChanged_WalkCycle = 500;
	npc.m_bisWalking = false;
	npc.StopPathing();
	OshimunoAntayotoSetKunaiVisible(npc, false);
	strcopy(g_AntayotoConeSwingAnim, sizeof(g_AntayotoConeSwingAnim), "layer_secondrate_sorcery_spy");
	npc.AddActivityViaSequence(g_AntayotoConeSwingAnim);
	npc.SetPlaybackRate(ANTAYOTO_CONE_ANIM_RATE);
	npc.SetCycle(0.01);
	npc.m_flDoingAnimation = gameTime + ANTAYOTO_CONE_ANIM_TIME;
	npc.m_flConeWindUp = 0.0;
	npc.PlayMeleeSound();
}

static void OshimunoAntayotoConePlayAnim(OshimunoAntayoto npc, float rate)
{
	npc.AddActivityViaSequence(g_AntayotoConeSwingAnim);
	npc.SetPlaybackRate(rate);
	npc.SetCycle(0.01);
}

static bool OshimunoAntayoto_ConeNuke(OshimunoAntayoto npc, float gameTime)
{
	if(npc.m_iChanged_WalkCycle == 500)
	{
		npc.SetPlaybackRate(ANTAYOTO_CONE_ANIM_RATE);
		if(IsValidEnemy(npc.index, npc.m_iTarget))
		{
			float vecTarget[3];
			WorldSpaceCenter(npc.m_iTarget, vecTarget);
			npc.FaceTowards(vecTarget, 15000.0);
		}
		if(npc.m_flDoingAnimation < gameTime)
		{
			npc.m_iChanged_WalkCycle = 501;
			npc.m_flConeWindUp = gameTime + ANTAYOTO_CONE_HOLD_TIME;
			npc.m_flSlashAoeFadeDraw = 0.0;
			int placePitch = 100;
			if(g_AntayotoConePlaceSoundLen > 0.0)
			{
				float pitchF = 100.0 * g_AntayotoConePlaceSoundLen / ANTAYOTO_CONE_HOLD_TIME;
				if(pitchF < 50.0)
					pitchF = 50.0;
				if(pitchF > 255.0)
					pitchF = 255.0;
				placePitch = RoundToNearest(pitchF);
			}
			EmitSoundToAll(g_AntayotoConePlaceSound, npc.index, SNDCHAN_STATIC, NORMAL_ZOMBIE_SOUNDLEVEL, _, NORMAL_ZOMBIE_VOLUME, placePitch);
			float pos[3];
			GetEntPropVector(npc.index, Prop_Data, "m_vecAbsOrigin", pos);
			float ang[3];
			GetEntPropVector(npc.index, Prop_Data, "m_angRotation", ang);
			f3_NpcSavePos[npc.index] = pos;
			npc.m_flSlashAoeYaw = ang[1];
			g_AntayotoConePlaceTime = gameTime;
			g_AntayotoConeTeleDraw = 0.0;
			g_AntayotoConeIndex = 0;
			g_AntayotoConeTotal = 1;
			g_AntayotoConeYawDir[0] = ang[1];
			g_AntayotoConeDetTime[0] = gameTime + ANTAYOTO_CONE_HOLD_TIME;
			if(g_AntayotoHealthPhase >= 1)
			{
				g_AntayotoConeTotal = 2;
				g_AntayotoConeYawDir[1] = ang[1] + 180.0;
				g_AntayotoConeDetTime[1] = g_AntayotoConeDetTime[0] + ANTAYOTO_CONE_STAGGER;
			}
			if(g_AntayotoHealthPhase >= 2)
			{
				g_AntayotoConeTotal = 3;
				g_AntayotoConeYawDir[2] = ang[1] + (GetRandomInt(0, 1) == 0 ? 90.0 : -90.0);
				g_AntayotoConeDetTime[2] = g_AntayotoConeDetTime[1] + ANTAYOTO_CONE_STAGGER;
			}
		}
		return true;
	}

	OshimunoAntayotoConeDrawPending(npc, gameTime);

	if(npc.m_iChanged_WalkCycle == 501)
	{
		npc.SetPlaybackRate(ANTAYOTO_CONE_ANIM_RATE);
		if(g_AntayotoConeDetTime[0] > gameTime)
			return true;
		OshimunoAntayotoConeDetonateIndex(npc, 0, gameTime);
		g_AntayotoConeIndex = 1;
		if(g_AntayotoConeIndex >= g_AntayotoConeTotal)
		{
			OshimunoAntayotoConeFinish(npc);
			return false;
		}
		OshimunoAntayotoConeFaceYaw(npc, g_AntayotoConeYawDir[g_AntayotoConeIndex]);
		OshimunoAntayotoConePlayAnim(npc, ANTAYOTO_CONE_ANIM_RATE2);
		npc.m_iChanged_WalkCycle = 502;
		return true;
	}
	if(npc.m_iChanged_WalkCycle == 502)
	{
		int cone = g_AntayotoConeIndex;
		OshimunoAntayotoConeFaceYaw(npc, g_AntayotoConeYawDir[cone]);
		npc.SetPlaybackRate(ANTAYOTO_CONE_ANIM_RATE2);
		if(g_AntayotoConeDetTime[cone] > gameTime)
			return true;
		OshimunoAntayotoConeDetonateIndex(npc, cone, gameTime);
		g_AntayotoConeIndex++;
		if(g_AntayotoConeIndex >= g_AntayotoConeTotal)
		{
			OshimunoAntayotoConeFinish(npc);
			return false;
		}
		OshimunoAntayotoConeFaceYaw(npc, g_AntayotoConeYawDir[g_AntayotoConeIndex]);
		OshimunoAntayotoConePlayAnim(npc, ANTAYOTO_CONE_ANIM_RATE2);
		return true;
	}
	return false;
}

static void OshimunoAntayotoConeDetonate(OshimunoAntayoto npc, float yawDeg)
{
	StopSound(npc.index, SNDCHAN_STATIC, g_AntayotoConePlaceSound);
	float yawRad = yawDeg * FLOAT_PI / 180.0;
	float fwdX = Cosine(yawRad);
	float fwdY = Sine(yawRad);
	float anchor[3];
	anchor = f3_NpcSavePos[npc.index];
	float minDot = Cosine(ANTAYOTO_CONE_HALF_ANGLE * FLOAT_PI / 180.0);
	bool PlaySound = false;
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

		float flatDist = SquareRoot((dx * dx) + (dy * dy));
		if(flatDist > ANTAYOTO_CONE_LENGTH)
			continue;

		if(flatDist > 1.0)
		{
			float dot = ((dx * fwdX) + (dy * fwdY)) / flatDist;
			if(dot < minDot)
				continue;
		}

		float maxHealth = float(SDKCall_GetMaxHealth(client));
		float missing = 0.0;
		if(maxHealth > 0.0)
		{
			missing = 1.0 - (float(GetClientHealth(client)) / maxHealth);
		}
		if(missing < 0.0)
			missing = 0.0;

		float damage = ANTAYOTO_CONE_DAMAGE * (1.0 + missing);
		float at[3];
		WorldSpaceCenter(client, at);
		PlaySound = true;
		SDKHooks_TakeDamage(client, npc.index, npc.index, damage, DMG_CLUB, -1, _, at);
	}
	EmitSoundToAll(g_AntayotoAoeDetonateSound, npc.index, SNDCHAN_STATIC, NORMAL_ZOMBIE_SOUNDLEVEL, _, NORMAL_ZOMBIE_VOLUME);
	if(PlaySound)
	{
		npc.PlayMeleeHitSound();
	}
}

static void OshimunoAntayotoConeDrawPending(OshimunoAntayoto npc, float gameTime)
{
	if(g_AntayotoConeTeleDraw > gameTime)
		return;

	g_AntayotoConeTeleDraw = gameTime + 0.1;
	for(int cone = g_AntayotoConeIndex; cone < g_AntayotoConeTotal; cone++)
	{
		float total = g_AntayotoConeDetTime[cone] - g_AntayotoConePlaceTime;
		float remaining = g_AntayotoConeDetTime[cone] - gameTime;
		if(remaining < 0.0)
			remaining = 0.0;

		int color[4];
		color[0] = 255;
		color[1] = (total > 0.0) ? RoundToNearest(255.0 * (remaining / total)) : 0;
		color[2] = 0;
		color[3] = ANTAYOTO_CONE_TELEGRAPH_ALPHA;
		OshimunoAntayotoConeDrawShape(npc, g_AntayotoConeYawDir[cone], 0.0, color, 0.15);
	}
}

static void OshimunoAntayotoConeDetonateIndex(OshimunoAntayoto npc, int cone, float gameTime)
{
	OshimunoAntayotoConeDetonate(npc, g_AntayotoConeYawDir[cone]);
	npc.m_flSlashAoeYaw = g_AntayotoConeYawDir[cone];
	npc.m_flSlashAoeFade = gameTime + ANTAYOTO_CONE_FADE_TIME;
	npc.m_flSlashAoeFadeDraw = 0.0;
	int color[4];
	color[0] = 255;
	color[1] = 0;
	color[2] = 0;
	color[3] = 255;
	OshimunoAntayotoConeDrawShape(npc, g_AntayotoConeYawDir[cone], 0.0, color, 0.1);
	RequestFrame(OshimunoAntayotoConeFadeFrame, EntIndexToEntRef(npc.index));
}

static void OshimunoAntayotoConeFaceYaw(OshimunoAntayoto npc, float yawDeg)
{
	float yawRad = yawDeg * FLOAT_PI / 180.0;
	float facePos[3];
	facePos = f3_NpcSavePos[npc.index];
	facePos[0] += Cosine(yawRad) * 200.0;
	facePos[1] += Sine(yawRad) * 200.0;
	npc.FaceTowards(facePos, 15000.0);
}

static void OshimunoAntayotoConeFinish(OshimunoAntayoto npc)
{
	OshimunoAntayotoSetKunaiVisible(npc, true);
	npc.SetPlaybackRate(1.0);
	npc.m_iChanged_WalkCycle = 0;
	npc.m_iWhatAbilityDo = 0;
	npc.m_flConeWindUp = 0.0;
	npc.m_flDoingAnimation = 0.0;
	npc.StartPathing();
	npc.m_bisWalking = true;
}

static void OshimunoAntayotoConeDrawShape(OshimunoAntayoto npc, float yawDeg, float expand, const int color[4], float life)
{
	float anchor[3];
	anchor = f3_NpcSavePos[npc.index];
	anchor[2] += 4.0;
	float bisectRad = yawDeg * FLOAT_PI / 180.0;
	anchor[0] -= Cosine(bisectRad) * expand;
	anchor[1] -= Sine(bisectRad) * expand;
	float length = ANTAYOTO_CONE_LENGTH + (expand * 2.0);
	float halfAngle = ANTAYOTO_CONE_HALF_ANGLE + ((expand / ANTAYOTO_CONE_LENGTH) * (180.0 / FLOAT_PI));
	float startYaw = yawDeg - halfAngle;
	float prev[3];
	for(int segment = 0; segment <= 8; segment++)
	{
		float yawRad = (startYaw + ((halfAngle * 2.0) * (float(segment) / 8.0))) * FLOAT_PI / 180.0;
		float point[3];
		point[0] = anchor[0] + (Cosine(yawRad) * length);
		point[1] = anchor[1] + (Sine(yawRad) * length);
		point[2] = anchor[2];
		if(segment == 0 || segment == 8)
		{
			TE_SetupBeamPoints(anchor, point, g_AntayotoSlashLaser, -1, 0, 0, life, 4.0, 4.0, 0, 0.0, color, 0);
			TE_SendToAll();
		}
		if(segment > 0)
		{
			TE_SetupBeamPoints(prev, point, g_AntayotoSlashLaser, -1, 0, 0, life, 4.0, 4.0, 0, 0.0, color, 0);
			TE_SendToAll();
		}
		prev = point;
	}
}

static void OshimunoAntayotoConeFadeFrame(any ref)
{
	int entity = EntRefToEntIndex(ref);
	if(entity <= MaxClients || !IsValidEntity(entity))
		return;

	OshimunoAntayoto npc = view_as<OshimunoAntayoto>(entity);
	float gameTime = GetGameTime(npc.index);
	if(!npc.m_flSlashAoeFade)
		return;

	if(npc.m_flSlashAoeFade <= gameTime)
	{
		npc.m_flSlashAoeFade = 0.0;
		return;
	}

	if(gameTime >= npc.m_flSlashAoeFadeDraw)
	{
		npc.m_flSlashAoeFadeDraw = gameTime + ANTAYOTO_SLASH_FADE_STEP;

		float frac = 1.0 - ((npc.m_flSlashAoeFade - gameTime) / ANTAYOTO_CONE_FADE_TIME);
		if(frac < 0.0)
			frac = 0.0;
		if(frac > 1.0)
			frac = 1.0;

		int color[4];
		color[0] = RoundToNearest(255.0 * (1.0 - frac));
		color[1] = 0;
		color[2] = 0;
		color[3] = RoundToNearest(255.0 * (1.0 - frac));

		OshimunoAntayotoConeDrawShape(npc, npc.m_flSlashAoeYaw, ANTAYOTO_CONE_SPREAD * frac, color, 0.1);
	}
	RequestFrame(OshimunoAntayotoConeFadeFrame, ref);
}

static void OshimunoAntayoto_LinePhaseStart(OshimunoAntayoto npc, float gameTime)
{
	npc.m_iWhatAbilityDo = 5;
	npc.m_iChanged_WalkCycle = 700;
	npc.m_bisWalking = false;
	npc.StopPathing();
	npc.m_flSlashAoeDetonate = 0.0;
	npc.m_flDoingAnimation = 0.0;
	g_AntayotoLineSmokeTime = 0.0;
	g_AntayotoLineSlotCount = 1;
	if(g_AntayotoHealthPhase >= 2)
	{
		g_AntayotoLineSlotCount = 3;
	}
	else if(g_AntayotoHealthPhase >= 1)
	{
		g_AntayotoLineSlotCount = 2;
	}
	for(int slot = 0; slot < ANTAYOTO_LINE_SLOTS; slot++)
	{
		g_AntayotoLineSlotActive[slot] = false;
		for(int client_wipe = 1; client_wipe <= MaxClients; client_wipe++)
		{
			g_AntayotoLineSlotChosen[slot][client_wipe] = false;
		}
	}
	OshimunoAntayotoSetInvisible(npc, true);
	ApplyStatusEffect(npc.index, npc.index, "Intangible", 999999.0);
	f_CheckIfStuckPlayerDelay[npc.index] = FAR_FUTURE;
	b_ThisEntityIgnoredBeingCarried[npc.index] = true;
	b_NoHealthbar[npc.index] = true;
}

static bool OshimunoAntayoto_LinePhase(OshimunoAntayoto npc, float gameTime)
{
	if(g_AntayotoLineSmokeTime < gameTime)
	{
		g_AntayotoLineSmokeTime = gameTime + ANTAYOTO_LINE_SMOKE_PERIOD;
		float smokePos[3];
		WorldSpaceCenter(npc.index, smokePos);
		ParticleEffectAt(smokePos, "grenade_smoke", ANTAYOTO_LINE_SMOKE_LIFE);
	}
	if(npc.m_flSlashAoeDetonate)
	{
		if(npc.m_flSlashAoeDetonate > gameTime)
		{
			OshimunoAntayotoLineDraw(npc, gameTime);
		}
		else
		{
			for(int slot = 0; slot < g_AntayotoLineSlotCount; slot++)
			{
				if(g_AntayotoLineSlotActive[slot])
				{
					OshimunoAntayotoLineDetonate(npc, slot);
				}
			}
			EmitSoundToAll(g_AntayotoAoeDetonateSound, _, _, _, _, 1.0);
			npc.m_flSlashAoeDetonate = 0.0;
			npc.m_flSlashAoeFade = gameTime + ANTAYOTO_SLASH_FADE_TIME;
			npc.m_flSlashAoeFadeDraw = 0.0;
			int color[4];
			color[0] = 255;
			color[1] = 0;
			color[2] = 0;
			color[3] = 255;
			for(int slot = 0; slot < g_AntayotoLineSlotCount; slot++)
			{
				if(g_AntayotoLineSlotActive[slot])
				{
					OshimunoAntayotoLineDrawShape(npc, slot, 0.0, color, 0.1);
				}
			}
			RequestFrame(OshimunoAntayotoLineFadeFrame, EntIndexToEntRef(npc.index));
			npc.m_flDoingAnimation = gameTime + (ANTAYOTO_SLASH_FADE_TIME * 2.0);
		}
		return true;
	}
	if(npc.m_flDoingAnimation > gameTime)
		return true;

	float pos[3];
	GetEntPropVector(npc.index, Prop_Data, "m_vecAbsOrigin", pos);
	f3_NpcSavePos[npc.index] = pos;

	bool anyPicked = false;
	int maxCount = 0;
	for(int slot = 0; slot < g_AntayotoLineSlotCount; slot++)
	{
		g_AntayotoLineSlotActive[slot] = false;

		int candidates[MAXPLAYERS + 1];
		int count = 0;
		for(int client = 1; client <= MaxClients; client++)
		{
			if(g_AntayotoLineSlotChosen[slot][client])
				continue;
			if(!IsClientInGame(client) || !IsPlayerAlive(client) || GetClientTeam(client) != TFTeam_Red)
				continue;
			candidates[count] = client;
			count++;
		}
		if(count <= 0)
			continue;

		if(count > maxCount)
			maxCount = count;

		int pick = candidates[GetRandomInt(0, count - 1)];
		g_AntayotoLineSlotChosen[slot][pick] = true;

		float at[3];
		GetClientAbsOrigin(pick, at);
		float dx = at[0] - pos[0];
		float dy = at[1] - pos[1];
		float length = SquareRoot((dx * dx) + (dy * dy)) + ANTAYOTO_LINE_PADDING;
		if(length < ANTAYOTO_LINE_MIN_LENGTH)
		{
			length = ANTAYOTO_LINE_MIN_LENGTH;
		}
		g_AntayotoLineSlotLen[slot] = length;

		float yawDeg;
		if(((dx * dx) + (dy * dy)) >= 1.0)
		{
			yawDeg = ArcTangent2(dy, dx) * 180.0 / FLOAT_PI;
		}
		else
		{
			float ang[3];
			GetEntPropVector(npc.index, Prop_Data, "m_angRotation", ang);
			yawDeg = ang[1];
		}
		g_AntayotoLineSlotYaw[slot] = yawDeg;
		g_AntayotoLineSlotActive[slot] = true;
		anyPicked = true;
	}
	if(!anyPicked)
	{
		OshimunoAntayoto_LinePhaseEnd(npc, gameTime);
		return false;
	}

	if(maxCount <= ANTAYOTO_LINE_SMOKE_WINDDOWN)
	{
		g_AntayotoLineSmokeTime = FAR_FUTURE;
	}

	npc.m_flSlashAoeDetonate = gameTime + ANTAYOTO_LINE_DETONATE_TIME;
	OshimunoAntayotoLineDraw(npc, gameTime);
	return true;
}

static void OshimunoAntayoto_LinePhaseEnd(OshimunoAntayoto npc, float gameTime)
{
	OshimunoAntayotoSetInvisible(npc, false);
	RemoveSpecificBuff(npc.index, "Intangible");
	f_CheckIfStuckPlayerDelay[npc.index] = 1.0;
	b_ThisEntityIgnoredBeingCarried[npc.index] = false;
	b_NoHealthbar[npc.index] = false;
	npc.m_iWhatAbilityDo = 0;
	npc.m_iChanged_WalkCycle = 0;
	npc.m_flDoingAnimation = 0.0;
	npc.StartPathing();
	npc.m_bisWalking = true;
	g_AntayotoRotationStage = 0;
	g_AntayotoRotationStart = gameTime;
}

static void OshimunoAntayotoLineDraw(OshimunoAntayoto npc, float gameTime)
{
	float remaining = npc.m_flSlashAoeDetonate - gameTime;
	if(remaining < 0.0)
		remaining = 0.0;

	int color[4];
	color[0] = 255;
	color[1] = RoundToNearest(255.0 * (remaining / ANTAYOTO_LINE_DETONATE_TIME));
	color[2] = 0;
	color[3] = 255;

	for(int slot = 0; slot < g_AntayotoLineSlotCount; slot++)
	{
		if(g_AntayotoLineSlotActive[slot])
		{
			OshimunoAntayotoLineDrawShape(npc, slot, 0.0, color, 0.15);
		}
	}
}

static void OshimunoAntayotoLineDrawShape(OshimunoAntayoto npc, int slot, float expand, const int color[4], float life)
{
	float yawRad = g_AntayotoLineSlotYaw[slot] * FLOAT_PI / 180.0;
	float fwdX = Cosine(yawRad);
	float fwdY = Sine(yawRad);
	float leftX = -fwdY;
	float leftY = fwdX;

	float anchor[3];
	anchor = f3_NpcSavePos[npc.index];
	anchor[2] += 4.0;
	anchor[0] -= fwdX * expand;
	anchor[1] -= fwdY * expand;

	float length = g_AntayotoLineSlotLen[slot] + (expand * 2.0);
	float halfWidth = (ANTAYOTO_SLASH_WIDTH * 0.5) + expand;
	float c1[3], c2[3], c3[3], c4[3];
	c1[0] = anchor[0] + (leftX * halfWidth);
	c1[1] = anchor[1] + (leftY * halfWidth);
	c1[2] = anchor[2];
	c2[0] = anchor[0] - (leftX * halfWidth);
	c2[1] = anchor[1] - (leftY * halfWidth);
	c2[2] = anchor[2];
	c3[0] = c1[0] + (fwdX * length);
	c3[1] = c1[1] + (fwdY * length);
	c3[2] = anchor[2];
	c4[0] = c2[0] + (fwdX * length);
	c4[1] = c2[1] + (fwdY * length);
	c4[2] = anchor[2];

	TE_SetupBeamPoints(c1, c2, g_AntayotoSlashLaser, -1, 0, 0, life, 4.0, 4.0, 0, 0.0, color, 0);
	TE_SendToAll();
	TE_SetupBeamPoints(c1, c3, g_AntayotoSlashLaser, -1, 0, 0, life, 4.0, 4.0, 0, 0.0, color, 0);
	TE_SendToAll();
	TE_SetupBeamPoints(c2, c4, g_AntayotoSlashLaser, -1, 0, 0, life, 4.0, 4.0, 0, 0.0, color, 0);
	TE_SendToAll();
	TE_SetupBeamPoints(c3, c4, g_AntayotoSlashLaser, -1, 0, 0, life, 4.0, 4.0, 0, 0.0, color, 0);
	TE_SendToAll();
}

static void OshimunoAntayotoLineDetonate(OshimunoAntayoto npc, int slot)
{
	float yawRad = g_AntayotoLineSlotYaw[slot] * FLOAT_PI / 180.0;
	float fwdX = Cosine(yawRad);
	float fwdY = Sine(yawRad);
	float leftX = -fwdY;
	float leftY = fwdX;

	float anchor[3];
	anchor = f3_NpcSavePos[npc.index];

	float halfWidth = (ANTAYOTO_SLASH_WIDTH * 0.5) + 24.0;
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
		if(fwdDist < -24.0 || fwdDist > (g_AntayotoLineSlotLen[slot] + 24.0))
			continue;

		float leftDist = (dx * leftX) + (dy * leftY);
		if(FloatAbs(leftDist) > halfWidth)
			continue;

		float at[3];
		WorldSpaceCenter(client, at);
		npc.PlayMeleeHitSound();
		SDKHooks_TakeDamage(client, npc.index, npc.index, ANTAYOTO_SLASH_DAMAGE, DMG_CLUB, -1, _, at);
	}
}

static void OshimunoAntayotoLineFadeFrame(any ref)
{
	int entity = EntRefToEntIndex(ref);
	if(entity <= MaxClients || !IsValidEntity(entity))
		return;

	OshimunoAntayoto npc = view_as<OshimunoAntayoto>(entity);
	float gameTime = GetGameTime(npc.index);
	if(!npc.m_flSlashAoeFade)
		return;

	if(npc.m_flSlashAoeFade <= gameTime)
	{
		npc.m_flSlashAoeFade = 0.0;
		return;
	}

	if(gameTime >= npc.m_flSlashAoeFadeDraw)
	{
		npc.m_flSlashAoeFadeDraw = gameTime + ANTAYOTO_SLASH_FADE_STEP;

		float frac = 1.0 - ((npc.m_flSlashAoeFade - gameTime) / ANTAYOTO_SLASH_FADE_TIME);
		if(frac < 0.0)
			frac = 0.0;

		int color[4];
		color[0] = RoundToNearest(255.0 * (1.0 - frac));
		color[1] = 0;
		color[2] = 0;
		color[3] = RoundToNearest(255.0 * (1.0 - frac));

		for(int slot = 0; slot < g_AntayotoLineSlotCount; slot++)
		{
			if(g_AntayotoLineSlotActive[slot])
			{
				OshimunoAntayotoLineDrawShape(npc, slot, ANTAYOTO_SLASH_SPREAD * frac, color, 0.1);
			}
		}
	}
	RequestFrame(OshimunoAntayotoLineFadeFrame, ref);
}

static void OshimunoAntayotoSetInvisible(OshimunoAntayoto npc, bool invisible)
{
	int alpha = invisible ? 0 : 255;
	RenderMode mode = invisible ? RENDER_TRANSCOLOR : RENDER_NORMAL;
	SetEntityRenderMode(npc.index, mode);
	SetEntityRenderColor(npc.index, 255, 255, 255, alpha);
	if(IsValidEntity(npc.m_iWearable1))
	{
		SetEntityRenderMode(npc.m_iWearable1, mode);
		SetEntityRenderColor(npc.m_iWearable1, 255, 255, 255, alpha);
	}
	if(IsValidEntity(npc.m_iWearable2))
	{
		SetEntityRenderMode(npc.m_iWearable2, mode);
		SetEntityRenderColor(npc.m_iWearable2, 255, 255, 255, alpha);
	}
	if(IsValidEntity(npc.m_iWearable3))
	{
		SetEntityRenderMode(npc.m_iWearable3, mode);
		SetEntityRenderColor(npc.m_iWearable3, 255, 255, 255, alpha);
	}
	if(IsValidEntity(npc.m_iWearable4))
	{
		SetEntityRenderMode(npc.m_iWearable4, mode);
		SetEntityRenderColor(npc.m_iWearable4, 255, 255, 255, alpha);
	}
	if(IsValidEntity(npc.m_iWearable5))
	{
		SetEntityRenderMode(npc.m_iWearable5, mode);
		SetEntityRenderColor(npc.m_iWearable5, 255, 255, 255, alpha);
	}
	if(IsValidEntity(npc.m_iWearable6))
	{
		SetEntityRenderMode(npc.m_iWearable6, mode);
		SetEntityRenderColor(npc.m_iWearable6, 255, 255, 255, alpha);
	}
}

static void OshimunoAntayotoSetKunaiVisible(OshimunoAntayoto npc, bool visible)
{
	if(!IsValidEntity(npc.m_iWearable1))
		return;
	int alpha = visible ? 255 : 0;
	RenderMode mode = visible ? RENDER_NORMAL : RENDER_TRANSCOLOR;
	SetEntityRenderMode(npc.m_iWearable1, mode);
	SetEntityRenderColor(npc.m_iWearable1, 255, 255, 255, alpha);
}

static void OshimunoAntayoto_SmokeEscape(OshimunoAntayoto npc, float gameTime)
{
	g_AntayotoSmokePending = false;

	float flPosSmoke[3];
	WorldSpaceCenter(npc.index, flPosSmoke);
	ParticleEffectAt(flPosSmoke, "grenade_smoke", 2.0);

	for(int entitycount; entitycount<MAXENTITIES; entitycount++)
	{
		if(IsValidEntity(entitycount) && entitycount != npc.index && (!b_NpcHasDied[entitycount]))
		{
			if(GetTeam(entitycount) == GetTeam(npc.index) && IsEntityAlive(entitycount))
			{
				float pos1[3];
				GetEntPropVector(npc.index, Prop_Data, "m_vecAbsOrigin", pos1);
				static float pos2[3];
				GetEntPropVector(entitycount, Prop_Data, "m_vecAbsOrigin", pos2);
				if(GetVectorDistance(pos1, pos2, true) < (500 * 500))
				{
					if(!Can_I_See_Ally(npc.index, entitycount))
						continue;
					ApplyStatusEffect(npc.index, entitycount, "Smoke Screen", 10.0);
				}
			}
		}
	}

	float vecLaunchPos[3];
	GetEntPropVector(npc.index, Prop_Data, "m_vecAbsOrigin", vecLaunchPos);
	for(int bomb; bomb < ANTAYOTO_BOMB_COUNT; bomb++)
	{
		float vecBombTarget[3];
		vecBombTarget = vecLaunchPos;
		switch(bomb)
		{
			case 0:
			{
				vecBombTarget[0] += ANTAYOTO_BOMB_DISTANCE;
			}
			case 1:
			{
				vecBombTarget[0] -= ANTAYOTO_BOMB_DISTANCE;
			}
			case 2:
			{
				vecBombTarget[1] += ANTAYOTO_BOMB_DISTANCE;
			}
			case 3:
			{
				vecBombTarget[1] -= ANTAYOTO_BOMB_DISTANCE;
			}
		}
		OshimunoAntayotoBombLaunch(npc, vecLaunchPos, vecBombTarget, bomb, gameTime);
	}

	TeleportEntity(npc.index, NULL_VECTOR, NULL_VECTOR, {0.0, 0.0, 0.0});
	g_AntayotoSmokeHideUntil = gameTime + ANTAYOTO_SMOKE_HIDE_TIME;
	g_AntayotoSmokeImmuneUntil = g_AntayotoSmokeHideUntil;
	g_AntayotoLineSmokeTime = 0.0;
	npc.m_iWhatAbilityDo = 6;
	npc.m_iChanged_WalkCycle = 800;
	npc.m_bisWalking = false;
	npc.StopPathing();
	OshimunoAntayotoSetInvisible(npc, true);
	ApplyStatusEffect(npc.index, npc.index, "Intangible", 999999.0);
	f_CheckIfStuckPlayerDelay[npc.index] = FAR_FUTURE;
	b_ThisEntityIgnoredBeingCarried[npc.index] = true;
	b_NoHealthbar[npc.index] = true;
	g_AntayotoRotationStart += ANTAYOTO_SMOKE_HIDE_TIME;
}

static bool OshimunoAntayoto_SmokeHide(OshimunoAntayoto npc, float gameTime)
{
	if(gameTime < g_AntayotoSmokeHideUntil)
	{
		if(gameTime < (g_AntayotoSmokeHideUntil - ANTAYOTO_SMOKE_CLEAR_LEAD) && g_AntayotoLineSmokeTime < gameTime)
		{
			g_AntayotoLineSmokeTime = gameTime + ANTAYOTO_LINE_SMOKE_PERIOD;
			float smokePos[3];
			WorldSpaceCenter(npc.index, smokePos);
			ParticleEffectAt(smokePos, "grenade_smoke", ANTAYOTO_LINE_SMOKE_LIFE);
		}
		return true;
	}

	OshimunoAntayotoSetInvisible(npc, false);
	RemoveSpecificBuff(npc.index, "Intangible");
	f_CheckIfStuckPlayerDelay[npc.index] = 1.0;
	b_ThisEntityIgnoredBeingCarried[npc.index] = false;
	b_NoHealthbar[npc.index] = false;
	g_AntayotoSmokeHideUntil = 0.0;
	g_AntayotoSmokeImmuneUntil = 0.0;
	npc.m_iWhatAbilityDo = 0;
	npc.m_iChanged_WalkCycle = 0;
	npc.m_flDoingAnimation = 0.0;
	npc.StartPathing();
	npc.m_bisWalking = true;
	return false;
}

static bool OshimunoAntayotoTraceFilter(int entity, int contentsMask, any data)
{
	return entity == 0;
}

static void OshimunoAntayotoBombLaunch(OshimunoAntayoto npc, float vecLaunchPos[3], float vecBombTarget[3], int slot, float gameTime)
{
	float vecStart[3];
	vecStart = vecLaunchPos;
	vecStart[2] += 48.0;
	float vecEnd[3];
	vecEnd = vecBombTarget;
	vecEnd[2] += 48.0;
	Handle trace = TR_TraceRayFilterEx(vecStart, vecEnd, MASK_PLAYERSOLID, RayType_EndPoint, OshimunoAntayotoTraceFilter, npc.index);
	TR_GetEndPosition(vecEnd, trace);
	delete trace;

	float vecDown[3];
	vecDown = vecEnd;
	vecDown[2] -= 1024.0;
	trace = TR_TraceRayFilterEx(vecEnd, vecDown, MASK_PLAYERSOLID, RayType_EndPoint, OshimunoAntayotoTraceFilter, npc.index);
	bool hitGround = TR_DidHit(trace);
	float vecGround[3];
	TR_GetEndPosition(vecGround, trace);
	delete trace;
	if(!hitGround)
	{
		vecGround = vecEnd;
	}

	float vecArrowTarget[3];
	vecArrowTarget = vecGround;
	vecArrowTarget[2] += 8.0;
	npc.FireArrow(vecArrowTarget, ANTAYOTO_BOMB_DAMAGE, ANTAYOTO_BOMB_SPEED, g_AntayotoBombModel, ANTAYOTO_BOMB_SCALE);

	float flight = GetVectorDistance(vecStart, vecArrowTarget) / ANTAYOTO_BOMB_SPEED;
	g_AntayotoBombState[slot] = 1;
	g_AntayotoBombPos[slot] = vecGround;
	g_AntayotoBombTime[slot] = gameTime + flight;
	g_AntayotoBombDraw[slot] = 0.0;
}

static void OshimunoAntayoto_BombsThink(OshimunoAntayoto npc, float gameTime)
{
	for(int bomb; bomb < ANTAYOTO_BOMB_COUNT; bomb++)
	{
		if(g_AntayotoBombState[bomb] == 1)
		{
			if(g_AntayotoBombTime[bomb] < gameTime)
			{
				int prop = CreateEntityByName("prop_dynamic_override");
				if(IsValidEntity(prop))
				{
					DispatchKeyValue(prop, "model", g_AntayotoBombModel);
					DispatchKeyValue(prop, "solid", "0");
					DispatchSpawn(prop);
					SetEntPropFloat(prop, Prop_Send, "m_flModelScale", ANTAYOTO_BOMB_SCALE);
					float vecProp[3];
					vecProp = g_AntayotoBombPos[bomb];
					vecProp[2] += 2.0;
					TeleportEntity(prop, vecProp, NULL_VECTOR, NULL_VECTOR);
					g_AntayotoBombProp[bomb] = EntIndexToEntRef(prop);
				}
				g_AntayotoBombState[bomb] = 2;
				g_AntayotoBombTime[bomb] = gameTime + ANTAYOTO_BOMB_FUSE;
				g_AntayotoBombDraw[bomb] = 0.0;
			}
		}
		else if(g_AntayotoBombState[bomb] == 2)
		{
			if(g_AntayotoBombTime[bomb] > gameTime)
			{
				if(g_AntayotoBombDraw[bomb] < gameTime)
				{
					g_AntayotoBombDraw[bomb] = gameTime + 0.1;
					float vecRing[3];
					vecRing = g_AntayotoBombPos[bomb];
					int ringGreen = RoundToNearest(255.0 * ((g_AntayotoBombTime[bomb] - gameTime) / ANTAYOTO_BOMB_FUSE));
					spawnRing_Vectors(vecRing, 0.1, 0.0, 0.0, 1.0, "materials/sprites/laserbeam.vmt", 255, ringGreen, 0, 255, 1, 0.2, 8.0, 1.5, 1, ANTAYOTO_BOMB_RADIUS * 2.0);
				}
			}
			else
			{
				OshimunoAntayotoBombDetonate(npc, bomb);
			}
		}
	}
}

static void OshimunoAntayotoBombDetonate(OshimunoAntayoto npc, int bomb)
{
	float vecPos[3];
	vecPos = g_AntayotoBombPos[bomb];
	Explode_Logic_Custom(ANTAYOTO_BOMB_DAMAGE, npc.index, npc.index, -1, vecPos, ANTAYOTO_BOMB_RADIUS, _, _, true);
	float vecParticle[3];
	vecParticle = vecPos;
	vecParticle[2] += 45.0;
	ParticleEffectAt(vecParticle, "ExplosionCore_MidAir", 1.0);
	int prop = EntRefToEntIndex(g_AntayotoBombProp[bomb]);
	if(prop > MaxClients && IsValidEntity(prop))
	{
		EmitSoundToAll(g_AntayotoBombExplodeSound, prop, SNDCHAN_AUTO, NORMAL_ZOMBIE_SOUNDLEVEL, _, NORMAL_ZOMBIE_VOLUME);
		RemoveEntity(prop);
	}
	g_AntayotoBombProp[bomb] = -1;
	g_AntayotoBombState[bomb] = 0;
}

static void OshimunoAntayotoBombsReset()
{
	for(int bomb; bomb < ANTAYOTO_BOMB_COUNT; bomb++)
	{
		int prop = EntRefToEntIndex(g_AntayotoBombProp[bomb]);
		if(prop > MaxClients && IsValidEntity(prop))
		{
			RemoveEntity(prop);
		}
		g_AntayotoBombState[bomb] = 0;
		g_AntayotoBombProp[bomb] = -1;
	}
}
/*
//Wwalk Cycle offset is 300
bool OshimunoAntayoto_CongaVeryFastDo(OshimunoAntayoto npc, float gameTime)
{
	if(npc.m_iWhatAbilityDo != 2 && npc.m_iWhatAbilityDo != 0)
		return false;
	if(npc.m_flDoingAnimation < gameTime)
	{
		if(npc.m_flCongaFastDo < gameTime)
		{
			if(!IsValidEnemy(npc.index, npc.m_iTarget))
				return false;
			if(!Can_I_See_Enemy_Only(npc.index, npc.m_iTarget))
				return false;

			npc.m_flSpeed = 720.0;
			npc.m_flCongaFastDo = gameTime + 35.0;
			npc.m_flDoingAnimation = gameTime + 0.25;
			npc.m_bisWalking = false;
			npc.StartPathing();
			npc.m_iChanged_WalkCycle = 300;
			npc.AddActivityViaSequence("taunt_conga");
			npc.SetPlaybackRate(2.5);
			npc.SetCycle(0.05);
			npc.m_iWhatAbilityDo = 2;
			f_NpcAdjustFriction[npc.index] = 0.2;
			ApplyStatusEffect(npc.index, npc.index, "Intangible", 999999.0);
			f_CheckIfStuckPlayerDelay[npc.index] = FAR_FUTURE; //She CANT stuck you, so dont make players not unstuck in cant bve stuck ? what ?
			b_ThisEntityIgnoredBeingCarried[npc.index] = true; //cant be targeted AND wont do npc collsiions
		}
	}
	if(npc.m_iWhatAbilityDo != 2)
		return false;
		
	int CurrentShotAt = npc.m_iChanged_WalkCycle - 300;
	if(CurrentShotAt > 20)
	{
		f_NpcAdjustFriction[npc.index] = 1.0;
		RemoveSpecificBuff(npc.index, "Intangible");
		f_CheckIfStuckPlayerDelay[npc.index] = 1.0; //She CANT stuck you, so dont make players not unstuck in cant bve stuck ? what ?
		b_ThisEntityIgnoredBeingCarried[npc.index] = false; //cant be targeted AND wont do npc collsiions
		npc.m_iWhatAbilityDo = 0;
		npc.m_flDoingAnimation = 0.0;
		return false;
	}
	if(npc.m_flDoingAnimation < gameTime)
	{		
		npc.m_iChanged_WalkCycle++;
		i_ExplosiveProjectileHexArray[npc.index] |= EP_DEALS_CLUB_DAMAGE;
		float radius = 160.0, damage = 20.0 * RaidModeScaling;
		float Loc[3];
		GetEntPropVector(npc.index, Prop_Data, "m_vecAbsOrigin", Loc);
		Explode_Logic_Custom(damage, npc.index, npc.index, -1, _, radius, _, _, true);
		spawnRing_Vectors(Loc, 0.1, 0.0, 0.0, 1.0, "materials/sprites/laserbeam.vmt", 255, 200, 200, 255, 1, 0.2, 8.0, 1.5, 1, radius*2.0);
		spawnRing_Vectors(Loc, 0.1, 0.0, 0.0, 25.0, "materials/sprites/laserbeam.vmt", 255, 200, 200, 255, 1, 0.2, 8.0, 1.5, 1, radius*2.0);
		spawnRing_Vectors(Loc, 0.1, 0.0, 0.0, 45.0, "materials/sprites/laserbeam.vmt", 255, 200, 200, 255, 1, 0.2, 8.0, 1.5, 1, radius*2.0);
		spawnRing_Vectors(Loc, 0.1, 0.0, 0.0, 65.0, "materials/sprites/laserbeam.vmt", 255, 200, 200, 255, 1, 0.2, 8.0, 1.5, 1, radius*2.0);

		npc.m_flDoingAnimation = gameTime + 0.25;
	}
	return false;
}


//Wwalk Cycle offset is 400
bool OshimunoAntayoto_JumpOfDeath(OshimunoAntayoto npc, float gameTime)
{
	if(npc.m_iWhatAbilityDo != 3 && npc.m_iWhatAbilityDo != 0)
		return false;
	if(npc.m_flDoingAnimation < gameTime)
	{
		if(npc.m_flJumpAtEnemy < gameTime)
		{
			if(!IsValidEnemy(npc.index, npc.m_iTarget))
				return false;
			if(!Can_I_See_Enemy_Only(npc.index, npc.m_iTarget))
				return false;

			npc.m_flJumpAtEnemy = gameTime + 35.0;
			npc.m_flDoingAnimation = gameTime + 1.0;
			npc.m_bisWalking = false;
			npc.StopPathing();
			npc.AddActivityViaSequence("taunt_table_flip_outro");
			npc.SetPlaybackRate(0.65);
			npc.SetCycle(0.01);
			npc.m_iChanged_WalkCycle = 400;
			npc.m_iWhatAbilityDo = 3;
			EmitSoundToAll("mvm/mvm_cpoint_klaxon.wav", npc.index, SNDCHAN_STATIC, 120, _, 1.0);
			EmitSoundToAll("mvm/mvm_cpoint_klaxon.wav", npc.index, SNDCHAN_STATIC, 120, _, 1.0);
		}
	}
	if(npc.m_iWhatAbilityDo != 3)
		return false;
		
	if(npc.m_iChanged_WalkCycle == 400)
	{
		if(!IsValidEnemy(npc.index, npc.m_iTarget))
			return true;
		float vecTarget[3]; WorldSpaceCenter(npc.m_iTarget, vecTarget );
		npc.FaceTowards(vecTarget, 15000.0);
		if(npc.m_flDoingAnimation < gameTime)
		{
			npc.SetPlaybackRate(0.0);
			npc.m_iChanged_WalkCycle = 401;
			npc.m_flDoingAnimation = gameTime + 4.0;
			npc.m_flGravityMulti = 0.65;
			PluginBot_Jump(npc.index, vecTarget, 4000.0, .timemodify = 4.0);
			npc.PlaySuperJumpSound();
			float flPos[3];
			float flAng[3];
			npc.GetAttachment("effect_hand_R", flPos, flAng);
			npc.m_iWearable5 = ParticleEffectAt_Parent(flPos, "raygun_projectile_red_crit", npc.index, "effect_hand_R", {0.0,0.0,0.0});
			

			npc.GetAttachment("effect_hand_L", flPos, flAng);
			npc.m_iWearable4 = ParticleEffectAt_Parent(flPos, "raygun_projectile_red_crit", npc.index, "effect_hand_L", {0.0,0.0,0.0});

		}
		return true;
	}
	
	if ((npc.IsOnGround() || npc.m_flDoingAnimation < gameTime) && (npc.m_iChanged_WalkCycle == 401))
	{
		float damageDealt = 600.0 * RaidModeScaling;

		npc.AddActivityViaSequence("taunt_yeti_layer");
		npc.SetPlaybackRate(1.0);
		npc.SetCycle(0.75);
		npc.m_iChanged_WalkCycle = 402;
		npc.m_flDoingAnimation = gameTime + 1.5;
		static float flMyPos[3];
		GetEntPropVector(npc.index, Prop_Data, "m_vecAbsOrigin", flMyPos);
		flMyPos[2] += 15.0;
		Explode_Logic_Custom(damageDealt, npc.index, npc.index, -1, flMyPos,300.0, 1.0, _, true, 20);
		TE_Particle("asplode_hoodoo", flMyPos, NULL_VECTOR, NULL_VECTOR, _, _, _, _, _, _, _, _, _, _, 0.0);
		EmitSoundToAll(SOUND_WAND_LIGHTNING_ABILITY_PAP_SMITE, 0, SNDCHAN_AUTO, 100, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, flMyPos);
		EmitSoundToAll(SOUND_WAND_LIGHTNING_ABILITY_PAP_SMITE, 0, SNDCHAN_AUTO, 100, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, flMyPos);
		npc.m_flGravityMulti = 1.0;
		if(IsValidEntity(npc.m_iWearable5))
			RemoveEntity(npc.m_iWearable5);
		if(IsValidEntity(npc.m_iWearable4))
			RemoveEntity(npc.m_iWearable4);
	}
	if (npc.m_iChanged_WalkCycle == 402 && npc.m_flDoingAnimation < gameTime)
	{
		npc.m_iChanged_WalkCycle = 0;
		npc.m_iWhatAbilityDo = 0;
	}
	return true;
}
*/