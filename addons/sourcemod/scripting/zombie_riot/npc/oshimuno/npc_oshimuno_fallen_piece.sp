#pragma semicolon 1
#pragma newdecls required

#define FALLEN_PIECE_MODEL "models/bots/demo/bot_sentry_buster.mdl"
#define FALLEN_PIECE_MODEL_SCALE "1.0"
#define FALLEN_PIECE_SPEED 150.0

static const char g_HurtSounds[][] =
{
	"weapons/fx/rics/arrow_impact_metal.wav",
	"weapons/fx/rics/arrow_impact_metal2.wav",
	"weapons/fx/rics/arrow_impact_metal4.wav",
};

void OshimunoFallenPieceOnMapStart()
{
	PrecacheSoundArray(g_HurtSounds);
	PrecacheModel(FALLEN_PIECE_MODEL);
	NPCData data;
	strcopy(data.Name, sizeof(data.Name), "Fallen Piece");
	strcopy(data.Plugin, sizeof(data.Plugin), "npc_oshimuno_fallen_piece");
	strcopy(data.Icon, sizeof(data.Icon), "sentry_buster");
	data.IconCustom = false;
	data.Flags = 0;
	data.Category = Type_Hidden;
	data.Func = ClotSummon;
	NPC_Add(data);
}

static any ClotSummon(int client, float vecPos[3], float vecAng[3], int team)
{
	return OshimunoFallenPiece(vecPos, vecAng, team);
}

methodmap OshimunoFallenPiece < CClotBody
{
	public void PlayHurtSound()
	{
		if(this.m_flNextHurtSound > GetGameTime(this.index))
			return;

		this.m_flNextHurtSound = GetGameTime(this.index) + 0.4;
		EmitSoundToAll(g_HurtSounds[GetRandomInt(0, sizeof(g_HurtSounds) - 1)], this.index, SNDCHAN_AUTO, NORMAL_ZOMBIE_SOUNDLEVEL, _, NORMAL_ZOMBIE_VOLUME);
	}

	public OshimunoFallenPiece(float vecPos[3], float vecAng[3], int ally)
	{
		OshimunoFallenPiece npc = view_as<OshimunoFallenPiece>(CClotBody(vecPos, vecAng, FALLEN_PIECE_MODEL, FALLEN_PIECE_MODEL_SCALE, "1000", ally));
		SetEntityRenderMode(npc.index, RENDER_NONE);
		i_NpcWeight[npc.index] = 1;
		npc.SetActivity("ACT_MP_RUN_MELEE");

		npc.m_iBleedType = BLEEDTYPE_METAL;
		npc.m_iStepNoiseType = STEPSOUND_NORMAL;
		npc.m_iNpcStepVariation = STEPTYPE_NONE;

		func_NPCDeath[npc.index] = ClotDeath;
		func_NPCOnTakeDamage[npc.index] = ClotOnTakeDamage;
		func_NPCThink[npc.index] = ClotThink;

		npc.m_flSpeed = FALLEN_PIECE_SPEED;
		npc.m_bDissapearOnDeath = true;
		npc.m_bTeamGlowDefault = false;
		b_ThisNpcIsImmuneToNuke[npc.index] = true;
		b_NoKnockbackFromSources[npc.index] = true;
		OshimunoChess_OrbSetup(npc.index);

		float flPos[3];
		GetEntPropVector(npc.index, Prop_Data, "m_vecAbsOrigin", flPos);
		flPos[2] += CHESS_ORB_HEIGHT;
		npc.m_iWearable1 = ParticleEffectAt_Parent(flPos, CHESS_ORB_PARTICLE, npc.index, "", {0.0,0.0,0.0});

		npc.StopPathing();
		return npc;
	}
}

static void ClotThink(int iNPC)
{
	OshimunoFallenPiece npc = view_as<OshimunoFallenPiece>(iNPC);

	f_StuckOutOfBoundsCheck[npc.index] = GetGameTime() + 10.0;

	float gameTime = GetGameTime(npc.index);
	if(npc.m_flNextDelayTime > gameTime)
	{
		npc.SetVelocity({0.0, 0.0, 0.0});
		return;
	}

	npc.m_flNextDelayTime = gameTime + DEFAULT_UPDATE_DELAY_FLOAT;
	npc.Update();

	OshimunoChess_FightThink(npc.index);

	if(npc.m_blPlayHurtAnimation)
	{
		npc.PlayHurtSound();
		npc.m_blPlayHurtAnimation = false;
	}

	if(npc.m_flNextThinkTime > gameTime)
		return;

	npc.m_flNextThinkTime = gameTime + 0.1;

	float vecCenter[3];
	if(OshimunoChess_OrbThink(npc.index, vecCenter))
	{
		float vecMe[3];
		GetEntPropVector(npc.index, Prop_Data, "m_vecAbsOrigin", vecMe);
		float vecVel[3];
		SubtractVectors(vecCenter, vecMe, vecVel);
		NormalizeVector(vecVel, vecVel);
		ScaleVector(vecVel, npc.GetRunSpeed());
		npc.SetVelocity(vecVel);
	}
	else
	{
		npc.SetVelocity({0.0, 0.0, 0.0});
	}
}

static Action ClotOnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	OshimunoFallenPiece npc = view_as<OshimunoFallenPiece>(victim);

	if(attacker <= 0)
		return Plugin_Continue;

	if (npc.m_flHeadshotCooldown < GetGameTime(npc.index))
	{
		npc.m_flHeadshotCooldown = GetGameTime(npc.index) + DEFAULT_HURTDELAY;
		npc.m_blPlayHurtAnimation = true;
	}
	return Plugin_Changed;
}

static void ClotDeath(int entity)
{
	OshimunoFallenPiece npc = view_as<OshimunoFallenPiece>(entity);

	float vecPos[3];
	GetEntPropVector(npc.index, Prop_Data, "m_vecAbsOrigin", vecPos);
	vecPos[2] += CHESS_ORB_HEIGHT;
	ParticleEffectAt(vecPos, "ExplosionCore_MidAir", 1.0);

	if(IsValidEntity(npc.m_iWearable1))
		RemoveEntity(npc.m_iWearable1);

	OshimunoChess_OrbDied(entity);
}
