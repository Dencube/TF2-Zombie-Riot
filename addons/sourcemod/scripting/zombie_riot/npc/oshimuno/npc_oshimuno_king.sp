#pragma semicolon 1
#pragma newdecls required

#define KING_DIRECTION_YAW 0.0
#define KING_MOVE_STEPS 1
#define KING_MOVE_SPEED 200.0
#define KING_LAND_DAMAGE 60.0
#define KING_RAM_DAMAGE 40.0
#define KING_FLEE_RANGE 1200.0
#define KING_SPAWN_AVOID_DIST 700.0
#define KING_PAINT 15185211

#define KING_SUMMON_MOVES_STAGE2 5
#define KING_SUMMON_MOVES_STAGE3 10
#define KING_SUMMON_MOVES_STAGE4 10
#define KING_SUMMON_TIME 5.0
#define KING_SUMMON_SETS 5

static const char g_DeathSounds[][] =
{
	"vo/demoman_paincrticialdeath01.mp3",
	"vo/demoman_paincrticialdeath02.mp3",
	"vo/demoman_paincrticialdeath03.mp3",
	"vo/demoman_paincrticialdeath04.mp3",
	"vo/demoman_paincrticialdeath05.mp3"
};

static const char g_HurtSounds[][] =
{
	"vo/demoman_painsharp01.mp3",
	"vo/demoman_painsharp02.mp3",
	"vo/demoman_painsharp03.mp3",
	"vo/demoman_painsharp04.mp3",
	"vo/demoman_painsharp05.mp3",
	"vo/demoman_painsharp06.mp3",
	"vo/demoman_painsharp07.mp3"
};

static const char g_IdleAlertedSounds[][] =
{
	"vo/demoman_battlecry01.mp3",
	"vo/demoman_battlecry02.mp3",
	"vo/demoman_battlecry03.mp3",
	"vo/demoman_battlecry04.mp3",
};

static const char g_MeleeHitSounds[][] =
{
	"weapons/blade_slice_2.wav",
	"weapons/blade_slice_3.wav",
	"weapons/blade_slice_4.wav"
};

static const char g_MeleeAttackSounds[][] =
{
	"weapons/demo_sword_swing1.wav",
	"weapons/demo_sword_swing2.wav",
	"weapons/demo_sword_swing3.wav",
};

static const char g_SummonSounds[][] =
{
	"mvm/mvm_tele_deliver.wav",
};

void OshimunoKingOnMapStart()
{
	PrecacheSoundArray(g_DeathSounds);
	PrecacheSoundArray(g_HurtSounds);
	PrecacheSoundArray(g_IdleAlertedSounds);
	PrecacheSoundArray(g_MeleeHitSounds);
	PrecacheSoundArray(g_MeleeAttackSounds);
	PrecacheSoundArray(g_SummonSounds);
	OshimunoChess_Precache();
	NPCData data;
	strcopy(data.Name, sizeof(data.Name), "King");
	strcopy(data.Plugin, sizeof(data.Plugin), "npc_oshimuno_king");
	strcopy(data.Icon, sizeof(data.Icon), "demoknight");
	data.IconCustom = false;
	data.Flags = MVM_CLASS_FLAG_MINIBOSS|MVM_CLASS_FLAG_ALWAYSCRIT;
	data.Category = Type_Raid;
	data.Func = ClotSummon;
	NPC_Add(data);
}

static any ClotSummon(int client, float vecPos[3], float vecAng[3], int team, const char[] data)
{
	return OshimunoKing(vecPos, vecAng, team, data);
}

methodmap OshimunoKing < CClotBody
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
	public void PlaySummonSound()
	{
		EmitSoundToAll(g_SummonSounds[GetRandomInt(0, sizeof(g_SummonSounds) - 1)], this.index, SNDCHAN_AUTO, BOSS_ZOMBIE_SOUNDLEVEL, _, BOSS_ZOMBIE_VOLUME);
	}

	public OshimunoKing(float vecPos[3], float vecAng[3], int ally, const char[] data)
	{
		OshimunoKing npc = view_as<OshimunoKing>(CClotBody(vecPos, vecAng, "models/player/demo.mdl", "1.2", "40000", ally, false, true, true,true));

		i_NpcWeight[npc.index] = 5;
		KillFeed_SetKillIcon(npc.index, "sword");
		int iActivity = npc.LookupActivity("ACT_MP_RUN_ITEM1");
		if(iActivity > 0) npc.StartActivity(iActivity);

		func_NPCDeath[npc.index] = OshimunoKing_Death;
		func_NPCOnTakeDamage[npc.index] = OshimunoKing_OnTakeDamage;
		func_NPCThink[npc.index] = OshimunoKing_Think;
		func_NPCFuncWin[npc.index] = OshimunoKing_Win;

		npc.m_iBleedType = BLEEDTYPE_NORMAL;
		npc.m_iStepNoiseType = STEPSOUND_GIANT;
		npc.m_iNpcStepVariation = STEPTYPE_NORMAL;

		npc.m_flSpeed = KING_MOVE_SPEED;
		npc.m_iChessStage = 1;
		npc.m_iMoveActions = 0;

		b_thisNpcIsARaid[npc.index] = true;
		b_ThisNpcIsImmuneToNuke[npc.index] = true;
		b_NoKnockbackFromSources[npc.index] = true;

		npc.m_iWearable1 = npc.EquipItem("head", "models/weapons/c_models/c_claymore/c_claymore.mdl");
		SetEntProp(npc.m_iWearable1, Prop_Send, "m_nSkin", 8);

		npc.m_iWearable2 = npc.EquipItem("head", "models/player/items/demo/crown.mdl");
		SetEntProp(npc.m_iWearable2, Prop_Send, "m_nSkin", 1);
		npc.m_iWearable3 = npc.EquipItem("head", "models/workshop/player/items/demo/demo_beardpipe/demo_beardpipe.mdl");
		SetEntProp(npc.m_iWearable3, Prop_Send, "m_nSkin", 1);
		NpcColourCosmetic_ViaPaint(npc.m_iWearable3, KING_PAINT);
		npc.m_iWearable4 = npc.EquipItem("head", "models/player/items/demo/ttg_glasses.mdl");
		SetEntProp(npc.m_iWearable4, Prop_Send, "m_nSkin", 1);
		NpcColourCosmetic_ViaPaint(npc.m_iWearable4, KING_PAINT);
		npc.m_iWearable5 = npc.EquipItem("head", "models/workshop/player/items/demo/xms2013_demo_plaid_boots/xms2013_demo_plaid_boots.mdl");
		SetEntProp(npc.m_iWearable5, Prop_Send, "m_nSkin", 1);
		NpcColourCosmetic_ViaPaint(npc.m_iWearable5, KING_PAINT);
		npc.m_iWearable6 = npc.EquipItem("head", "models/workshop/player/items/all_class/sbox2014_toowoomba_tunic/sbox2014_toowoomba_tunic_demo.mdl");
		SetEntProp(npc.m_iWearable6, Prop_Send, "m_nSkin", 1);
		NpcColourCosmetic_ViaPaint(npc.m_iWearable6, KING_PAINT);

		SetEntProp(npc.index, Prop_Send, "m_nSkin", 1);
		SetVariantInt(2);
		AcceptEntityInput(npc.index, "SetBodyGroup");

		OshimunoChess_Setup(npc.index, CHESS_SLOT_KING, KING_DIRECTION_YAW, KING_MOVE_STEPS, true, KING_RAM_DAMAGE, data);
		OshimunoChess_SetFleeRange(npc.index, KING_FLEE_RANGE);
		OshimunoChess_SetSpawnAvoid(npc.index, KING_SPAWN_AVOID_DIST);

		npc.StopPathing();
		return npc;
	}
}

static void NPCTalkMessage(int entity, const char[] message)
{
	PrintNPCMessageWithPrefixes(entity, "black", message);
}

static void OshimunoKing_Think(int iNPC)
{
	OshimunoKing npc = view_as<OshimunoKing>(iNPC);
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
		npc.m_iChessStage = stage;
		npc.m_iMoveActions = 0;
		OshimunoChess_ApplyStage(npc.index, stage);
	}

	if(OshimunoChess_MoveThink(npc.index, gameTime) == CHESS_MOVE_FINISHED)
	{
		OshimunoKing_MoveFinished(npc, stage, gameTime);
	}
	npc.PlayIdleSound();
}

static Action OshimunoKing_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	OshimunoKing npc = view_as<OshimunoKing>(victim);
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

public void OshimunoKing_Win(int entity)
{
	i_RaidGrantExtra[entity] = RAIDITEM_INDEX_WIN_COND;
	BlockLoseSay = true;
	NPCTalkMessage(entity, "Checkmate.");
}

static void OshimunoKing_Death(int entity)
{
	OshimunoKing npc = view_as<OshimunoKing>(entity);

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

	OshimunoChess_BossDied(entity);
}

static void OshimunoKing_MoveFinished(OshimunoKing npc, int stage, float gameTime)
{
	npc.AddGesture("ACT_MP_ATTACK_STAND_ITEM1",_,_,_, 0.85);
	npc.PlayMeleeSound();
	if(OshimunoChess_LandingDamage(npc.index, KING_LAND_DAMAGE * RaidModeScaling) > 0)
	{
		npc.PlayMeleeHitSound();
	}

	if(stage < 2)
		return;

	int needed = KING_SUMMON_MOVES_STAGE2;
	if(stage == 3)
		needed = KING_SUMMON_MOVES_STAGE3;
	else if(stage >= 4)
		needed = KING_SUMMON_MOVES_STAGE4;

	npc.m_iMoveActions++;
	if(npc.m_iMoveActions >= needed)
	{
		npc.m_iMoveActions = 0;
		OshimunoChess_PauseMoves(npc.index, gameTime + KING_SUMMON_TIME);
		OshimunoKing_SummonSet(npc, stage, GetRandomInt(0, KING_SUMMON_SETS - 1));
	}
}

static void OshimunoKing_SummonSet(OshimunoKing npc, int stage, int which)
{
	npc.PlaySummonSound();
	switch(stage)
	{
		case 2: // stage 2
		{
			switch(which)
			{
				case 0:
				{
					OshimunoKingSpawnEnemy(npc.index, "npc_oshimuno_grunt", 20000, 6); // npcname,hp,amount
					OshimunoKingSpawnEnemy(npc.index, "npc_oshimuno_ninja", 15000, 4);
					OshimunoKingSpawnEnemy(npc.index, "npc_oshimuno_trash_man", 300000, 1, true); // npcname,hp,amount,boss?yes/no
				}
				case 1:
				{

				}
				case 2:
				{

				}
				case 3:
				{

				}
				case 4:
				{

				}
			}
		}
		case 3: //stage 3
		{
			switch(which)
			{
				case 0:
				{

				}
				case 1:
				{

				}
				case 2:
				{

				}
				case 3:
				{

				}
				case 4:
				{

				}
			}
		}
		case 4: //enrage
		{
			switch(which)
			{
				case 0:
				{

				}
				case 1:
				{

				}
				case 2:
				{

				}
				case 3:
				{

				}
				case 4:
				{

				}
			}
		}
	}
}

stock void OshimunoKingSpawnEnemy(int king, char[] plugin_name, int health = 0, int count, bool is_a_boss = false)
{
	Enemy enemy;
	enemy.Index = NPC_GetByPlugin(plugin_name);
	if(health != 0)
	{
		enemy.Health = health;
	}
	enemy.Is_Boss = view_as<int>(is_a_boss);
	enemy.Is_Immune_To_Nuke = true;
	enemy.ExtraMeleeRes = 1.0;
	enemy.ExtraRangedRes = 1.0;
	enemy.ExtraSpeed = 1.0;
	enemy.ExtraDamage = 1.0;
	enemy.ExtraSize = 1.0;
	enemy.Team = GetTeam(king);

	if(!Waves_InFreeplay())
	{
		for(int i; i<count; i++)
		{
			Waves_AddNextEnemy(enemy);
		}
	}
	else
	{
		int postWaves = CurrentRound[Rounds_Default] - Waves_GetMaxRound();
		Freeplay_AddEnemy(postWaves, enemy, count, true);
		if(count > 0)
		{
			for(int a; a < count; a++)
			{
				Waves_AddNextEnemy(enemy);
			}
		}
	}

	Zombies_Currently_Still_Ongoing += count;
}
