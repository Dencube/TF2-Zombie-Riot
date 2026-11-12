#pragma semicolon 1
#pragma newdecls required

#define ROOK_DIRECTION_YAW 0.0
#define ROOK_MOVE_STEPS 4
#define ROOK_MOVE_SPEED 600.0
#define ROOK_LAND_DAMAGE 60.0
#define ROOK_RAM_DAMAGE 40.0

#define ROOK_ROCKET_COOLDOWN 2.0
#define ROOK_ROCKET_COOLDOWN_ENRAGED 2.0
#define ROOK_ROCKET_SPEED 200.0
#define ROOK_ROCKET_DAMAGE 50.0
#define ROOK_ROCKET_LIFETIME 40.0

#define ROOK_LINE_MOVES 3
#define ROOK_LINE_LENGTH 5000.0
#define ROOK_LINE_TIME 1.0
#define ROOK_LINE_TIME_ENRAGED 1.0
#define ROOK_LINE_DAMAGE 150.0
#define ROOK_LINE_FADE_TIME 0.3

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

static const char g_RangedAttackSounds[][] =
{
	"weapons/rocket_shoot.wav",
};

static const char g_RookLineWindUpSound[] = "misc/halloween/strongman_fast_swing_01.wav";
static const char g_RookLineImpactSound[] = "misc/halloween/strongman_fast_impact_01.wav";

void OshimunoRookOnMapStart()
{
	PrecacheSoundArray(g_DeathSounds);
	PrecacheSoundArray(g_HurtSounds);
	PrecacheSoundArray(g_IdleAlertedSounds);
	PrecacheSoundArray(g_MeleeHitSounds);
	PrecacheSoundArray(g_MeleeAttackSounds);
	PrecacheSoundArray(g_RangedAttackSounds);
	PrecacheSound(g_RookLineWindUpSound);
	PrecacheSound(g_RookLineImpactSound);
	OshimunoChess_Precache();
	NPCData data;
	strcopy(data.Name, sizeof(data.Name), "Rook");
	strcopy(data.Plugin, sizeof(data.Plugin), "npc_oshimuno_rook");
	strcopy(data.Icon, sizeof(data.Icon), "heavy_steelfist");
	data.IconCustom = false;
	data.Flags = MVM_CLASS_FLAG_MINIBOSS|MVM_CLASS_FLAG_ALWAYSCRIT;
	data.Category = Type_Raid;
	data.Func = ClotSummon;
	NPC_Add(data);
}

static any ClotSummon(int client, float vecPos[3], float vecAng[3], int team, const char[] data)
{
	return OshimunoRook(vecPos, vecAng, team, data);
}

methodmap OshimunoRook < CClotBody
{
	property int m_iChessStage
	{
		public get()							{ return i_State[this.index]; }
		public set(int TempValueForProperty) 	{ i_State[this.index] = TempValueForProperty; }
	}
	property int m_iMoveActions
	{
		public get()							{ return i_OverlordComboAttack[this.index]; }
		public set(int TempValueForProperty) 	{ i_OverlordComboAttack[this.index] = TempValueForProperty; }
	}
	property float m_flRocketCD
	{
		public get()							{ return fl_AbilityOrAttack[this.index][0]; }
		public set(float TempValueForProperty) 	{ fl_AbilityOrAttack[this.index][0] = TempValueForProperty; }
	}
	property float m_flLineAoeDetonate
	{
		public get()							{ return fl_AbilityOrAttack[this.index][1]; }
		public set(float TempValueForProperty) 	{ fl_AbilityOrAttack[this.index][1] = TempValueForProperty; }
	}
	property float m_flLineAoeTime
	{
		public get()							{ return fl_AbilityOrAttack[this.index][2]; }
		public set(float TempValueForProperty) 	{ fl_AbilityOrAttack[this.index][2] = TempValueForProperty; }
	}
	property float m_flLineAoeDraw
	{
		public get()							{ return fl_AbilityOrAttack[this.index][3]; }
		public set(float TempValueForProperty) 	{ fl_AbilityOrAttack[this.index][3] = TempValueForProperty; }
	}
	property float m_flLineAoeFade
	{
		public get()							{ return fl_AbilityOrAttack[this.index][4]; }
		public set(float TempValueForProperty) 	{ fl_AbilityOrAttack[this.index][4] = TempValueForProperty; }
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

	public OshimunoRook(float vecPos[3], float vecAng[3], int ally, const char[] data)
	{
		OshimunoRook npc = view_as<OshimunoRook>(CClotBody(vecPos, vecAng, "models/player/heavy.mdl", "1.2", "40000", ally, false, true, true,true));

		i_NpcWeight[npc.index] = 5;
		KillFeed_SetKillIcon(npc.index, "steel_fists");
		int iActivity = npc.LookupActivity("ACT_MP_RUN_MELEE");
		if(iActivity > 0) npc.StartActivity(iActivity);

		func_NPCDeath[npc.index] = OshimunoRook_Death;
		func_NPCOnTakeDamage[npc.index] = OshimunoRook_OnTakeDamage;
		func_NPCThink[npc.index] = OshimunoRook_Think;
		func_NPCFuncWin[npc.index] = OshimunoRook_Win;

		npc.m_iBleedType = BLEEDTYPE_NORMAL;
		npc.m_iStepNoiseType = STEPSOUND_GIANT;
		npc.m_iNpcStepVariation = STEPTYPE_NORMAL;

		npc.m_flSpeed = ROOK_MOVE_SPEED;
		npc.m_iChessStage = 1;
		npc.m_iMoveActions = 0;
		npc.m_flRocketCD = 0.0;
		npc.m_flLineAoeDetonate = 0.0;
		npc.m_flLineAoeTime = 0.0;
		npc.m_flLineAoeDraw = 0.0;
		npc.m_flLineAoeFade = 0.0;

		b_thisNpcIsARaid[npc.index] = true;
		b_ThisNpcIsImmuneToNuke[npc.index] = true;
		b_NoKnockbackFromSources[npc.index] = true;

		npc.m_iWearable1 = npc.EquipItem("head", "models/weapons/c_models/c_fists_of_steel/c_fists_of_steel.mdl");

		npc.m_iWearable2 = npc.EquipItem("head", "models/player/items/mvm_loot/heavy/robo_ushanka.mdl");
		SetEntProp(npc.m_iWearable2, Prop_Send, "m_nSkin", 1);
		npc.m_iWearable3 = npc.EquipItem("head", "models/workshop/player/items/heavy/robo_heavy_boltedscraptowel/robo_heavy_boltedscraptowel.mdl");
		SetEntProp(npc.m_iWearable3, Prop_Send, "m_nSkin", 1);
		npc.m_iWearable4 = npc.EquipItem("head", "models/workshop/player/items/heavy/sbox2014_war_goggles/sbox2014_war_goggles.mdl");
		SetEntProp(npc.m_iWearable4, Prop_Send, "m_nSkin", 1);
		npc.m_iWearable5 = npc.EquipItem("head", "models/workshop/player/items/heavy/sbox2014_sammy_cap/sbox2014_sammy_cap.mdl");
		SetEntProp(npc.m_iWearable5, Prop_Send, "m_nSkin", 1);
		npc.m_iWearable6 = npc.EquipItem("head", "models/workshop/player/items/heavy/hwn2016_mad_mask/hwn2016_mad_mask.mdl");
		SetEntProp(npc.m_iWearable6, Prop_Send, "m_nSkin", 1);
		npc.m_iWearable7 = npc.EquipItem("head", "models/workshop/player/items/heavy/sum23_heavy_metal/sum23_heavy_metal.mdl");
		SetEntProp(npc.m_iWearable7, Prop_Send, "m_nSkin", 1);
		npc.m_iWearable8 = npc.EquipItem("head", "models/workshop/player/items/heavy/dec24_battle_balaclava_style1/dec24_battle_balaclava_style1.mdl");
		SetEntProp(npc.m_iWearable8, Prop_Send, "m_nSkin", 1);

		SetEntProp(npc.index, Prop_Send, "m_nSkin", 1);
		SetVariantInt(3);
		AcceptEntityInput(npc.index, "SetBodyGroup");

		OshimunoChess_Setup(npc.index, CHESS_SLOT_ROOK, ROOK_DIRECTION_YAW, ROOK_MOVE_STEPS, false, ROOK_RAM_DAMAGE, data);

		npc.StopPathing();
		return npc;
	}
}

static void OshimunoRook_Think(int iNPC)
{
	OshimunoRook npc = view_as<OshimunoRook>(iNPC);
	float gameTime = GetGameTime(npc.index);
	if(npc.m_flNextDelayTime > gameTime)
	{
		OshimunoChess_Stunned(npc.index);
		return;
	}
	npc.m_flNextDelayTime = gameTime + DEFAULT_UPDATE_DELAY_FLOAT;
	npc.Update();

	if(i_RaidGrantExtra[npc.index] == RAIDITEM_INDEX_WIN_COND)
	{
		OshimunoChess_Halt(npc.index);
		npc.m_bisWalking = false;
		npc.AddActivityViaSequence("selectionMenu_Idle");
		npc.SetCycle(0.01);
		func_NPCThink[npc.index] = INVALID_FUNCTION;
		return;
	}

	OshimunoChess_FightThink(npc.index);

	if(npc.m_blPlayHurtAnimation)
	{
		npc.AddGesture("ACT_MP_GESTURE_FLINCH_CHEST", false);
		npc.m_blPlayHurtAnimation = false;
		npc.PlayHurtSound();
	}

	int stage = OshimunoChess_Stage();
	if(npc.m_iChessStage != stage)
	{
		OshimunoRook_StageChange(npc, stage, gameTime);
	}

	OshimunoRook_LineAoe(npc, gameTime);
	OshimunoRook_Rockets(npc, stage, gameTime);

	if(OshimunoChess_MoveThink(npc.index, gameTime) == CHESS_MOVE_FINISHED)
	{
		OshimunoRook_MoveFinished(npc, stage, gameTime);
	}
	npc.PlayIdleSound();
}

static Action OshimunoRook_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	OshimunoRook npc = view_as<OshimunoRook>(victim);
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

public void OshimunoRook_Win(int entity)
{
	i_RaidGrantExtra[entity] = RAIDITEM_INDEX_WIN_COND;
	BlockLoseSay = true;
}

static void OshimunoRook_Death(int entity)
{
	OshimunoRook npc = view_as<OshimunoRook>(entity);

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

	if(IsValidEntity(npc.m_iWearable6))
		RemoveEntity(npc.m_iWearable6);

	if(IsValidEntity(npc.m_iWearable7))
		RemoveEntity(npc.m_iWearable7);

	if(IsValidEntity(npc.m_iWearable8))
		RemoveEntity(npc.m_iWearable8);

	OshimunoChess_BossDied(entity);
}

static void OshimunoRook_StageChange(OshimunoRook npc, int stage, float gameTime)
{
	npc.m_iChessStage = stage;
	npc.m_iMoveActions = 0;
	OshimunoChess_ApplyStage(npc.index, stage);

	if(stage >= 2)
	{
		npc.m_flRocketCD = gameTime + (stage >= 4 ? ROOK_ROCKET_COOLDOWN_ENRAGED : ROOK_ROCKET_COOLDOWN);
	}
}

static void OshimunoRook_MoveFinished(OshimunoRook npc, int stage, float gameTime)
{
	npc.AddGesture("ACT_MP_ATTACK_STAND_MELEE",_,_,_, 0.85);
	npc.PlayMeleeSound();
	if(OshimunoChess_LandingDamage(npc.index, ROOK_LAND_DAMAGE * RaidModeScaling) > 0)
	{
		npc.PlayMeleeHitSound();
	}

	if(stage >= 3)
	{
		npc.m_iMoveActions++;
		if(npc.m_iMoveActions >= ROOK_LINE_MOVES)
		{
			npc.m_iMoveActions = 0;
			OshimunoRook_LineAoeStart(npc, stage, gameTime);
		}
	}
}

static void OshimunoRook_Rockets(OshimunoRook npc, int stage, float gameTime)
{
	if(stage < 2 || npc.m_flLineAoeDetonate != 0.0 || npc.m_flRocketCD > gameTime)
		return;

	npc.m_flRocketCD = gameTime + (stage >= 4 ? ROOK_ROCKET_COOLDOWN_ENRAGED : ROOK_ROCKET_COOLDOWN);

	float pos[3];
	GetEntPropVector(npc.index, Prop_Data, "m_vecAbsOrigin", pos);
	for(int dir = 0; dir < 4; dir++)
	{
		float yawRad = (ROOK_DIRECTION_YAW + (90.0 * float(dir))) * FLOAT_PI / 180.0;
		float vecTarget[3];
		vecTarget[0] = pos[0] + (Cosine(yawRad) * 1000.0);
		vecTarget[1] = pos[1] + (Sine(yawRad) * 1000.0);
		vecTarget[2] = pos[2] + 54.0;
		int rocket = npc.FireRocket(vecTarget, ROOK_ROCKET_DAMAGE * RaidModeScaling, ROOK_ROCKET_SPEED);
		if(rocket != -1)
		{
			CreateTimer(ROOK_ROCKET_LIFETIME, Timer_RemoveEntity, EntIndexToEntRef(rocket), TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	npc.PlayRangedSound();
}

static void OshimunoRook_LineAoeStart(OshimunoRook npc, int stage, float gameTime)
{
	float fuse = (stage >= 4 ? ROOK_LINE_TIME_ENRAGED : ROOK_LINE_TIME);
	npc.m_flLineAoeDetonate = gameTime + fuse;
	npc.m_flLineAoeTime = fuse;
	npc.m_flLineAoeDraw = 0.0;
	npc.m_flLineAoeFade = 0.0;

	float pos[3];
	GetEntPropVector(npc.index, Prop_Data, "m_vecAbsOrigin", pos);
	f3_NpcSavePos[npc.index] = pos;

	OshimunoChess_PauseMoves(npc.index, gameTime + fuse);
	if(npc.m_flRocketCD < gameTime)
		npc.m_flRocketCD = gameTime;

	npc.m_flRocketCD += fuse;
	EmitSoundToAll(g_RookLineWindUpSound, npc.index, SNDCHAN_STATIC, NORMAL_ZOMBIE_SOUNDLEVEL, _, NORMAL_ZOMBIE_VOLUME);
}

static void OshimunoRook_LineAoe(OshimunoRook npc, float gameTime)
{
	if(npc.m_flLineAoeDetonate)
	{
		if(npc.m_flLineAoeDetonate > gameTime)
		{
			if(npc.m_flLineAoeDraw < gameTime)
			{
				npc.m_flLineAoeDraw = gameTime + 0.1;
				float remaining = npc.m_flLineAoeDetonate - gameTime;
				int color[4];
				color[0] = 255;
				color[1] = RoundToNearest(255.0 * (remaining / npc.m_flLineAoeTime));
				color[2] = 0;
				color[3] = 255;
				OshimunoRook_LineAoeDraw(npc, color, 0.15);
			}
		}
		else
		{
			OshimunoRook_LineAoeDetonate(npc);
			npc.m_flLineAoeDetonate = 0.0;
			npc.m_flLineAoeFade = gameTime + ROOK_LINE_FADE_TIME;
			npc.m_flLineAoeDraw = 0.0;
		}
		return;
	}
	if(npc.m_flLineAoeFade)
	{
		if(npc.m_flLineAoeFade <= gameTime)
		{
			npc.m_flLineAoeFade = 0.0;
		}
		else if(npc.m_flLineAoeDraw < gameTime)
		{
			npc.m_flLineAoeDraw = gameTime + 0.1;
			int color[4];
			color[0] = 255;
			color[1] = 0;
			color[2] = 0;
			color[3] = RoundToNearest(255.0 * ((npc.m_flLineAoeFade - gameTime) / ROOK_LINE_FADE_TIME));
			OshimunoRook_LineAoeDraw(npc, color, 0.15);
		}
	}
}

static void OshimunoRook_LineAoeDraw(OshimunoRook npc, const int color[4], float life)
{
	OshimunoChess_DrawCross(f3_NpcSavePos[npc.index], ROOK_DIRECTION_YAW, ROOK_LINE_LENGTH, OshimunoChess_TileSize() * 0.5, color, life);
}

static void OshimunoRook_LineAoeDetonate(OshimunoRook npc)
{
	OshimunoChess_ResetBlast();
	int hits = 0;
	for(int dir = 0; dir < 4; dir++)
	{
		hits += OshimunoChess_DamageRect(npc.index, f3_NpcSavePos[npc.index], ROOK_DIRECTION_YAW + (90.0 * float(dir)), 0.0, ROOK_LINE_LENGTH, OshimunoChess_TileSize() * 0.5, ROOK_LINE_DAMAGE * RaidModeScaling);
	}

	npc.AddGesture("ACT_MP_ATTACK_STAND_MELEE",_,_,_, 0.85);
	EmitSoundToAll(g_RookLineImpactSound, npc.index, SNDCHAN_STATIC, NORMAL_ZOMBIE_SOUNDLEVEL, _, NORMAL_ZOMBIE_VOLUME);
	if(hits > 0)
	{
		npc.PlayMeleeHitSound();
	}
}
