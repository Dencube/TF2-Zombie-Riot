#pragma semicolon 1
#pragma newdecls required

#define CHESS_SLOT_KING 0
#define CHESS_SLOT_ROOK 1
#define CHESS_SLOT_BISHOP 2
#define CHESS_SLOT_MAX 3

#define CHESS_MOVE_IDLE 0
#define CHESS_MOVE_DASHING 1
#define CHESS_MOVE_FINISHED 2

#define CHESS_MAX_STEPS 4

#define CHESS_RAID_TIME 220.0
#define CHESS_RAID_TIME_PER_KILL 40.0

#define CHESS_MOVE_ARRIVE_DIST 6.0
#define CHESS_MOVE_ARRIVE_TIME 0.03
#define CHESS_MOVE_STALL_TIME 1.0
#define CHESS_MOVE_STUCK_FAILS 4
#define CHESS_MOVE_PHASE_ALPHA 77

#define CHESS_PATH_HULL 32.0
#define CHESS_PATH_HEIGHT 120.0
#define CHESS_PATH_STEPUP 18.0
#define CHESS_PATH_PROBE_LOW 72.0
#define CHESS_PATH_PROBE_HIGH 300.0
#define CHESS_PATH_PROBE_DOWN 300.0
#define CHESS_PATH_LEVELS 4
#define CHESS_PATH_LEVEL_MERGE 64.0
#define CHESS_PATH_FLOOR_MERGE 24.0
#define CHESS_PATH_FADE_TIME 0.5
#define CHESS_LAND_FADE_TIME 1.0

#define CHESS_AOE_PAD 24.0
#define CHESS_AOE_HEIGHT 120.0

#define CHESS_RAM_PAD 8.0
#define CHESS_RAM_KNOCKBACK 900.0

#define CHESS_SPAWN_SAMPLES 30
#define CHESS_SPAWN_MAX_DIST 4000.0
#define CHESS_SPAWN_MIN_DIST 1000.0
#define CHESS_SPAWN_FLOOR_TOLERANCE 120.0

#define CHESS_AVOID_SPAWNS_MAX 64

#define CHESS_ORB_PARTICLE "dxhr_lightningball_parent_blue"
#define CHESS_ORB_HEIGHT 60.0
#define CHESS_ORB_HEALTH_DIVIDE 10
#define CHESS_ORB_CIRCLE_RADIUS 100.0
#define CHESS_BLESSING_TIME 999999.0

static const float g_ChessTileSize[] = { 200.0, 300.0, 400.0, 400.0 };
static const float g_ChessMoveDelay[] = { 1.0, 0.75, 0.5, 0.5 };
static const float g_ChessModelScale[] = { 1.2, 1.4, 1.6, 1.8 };
static const float g_ChessDeathHealthMulti[] = { 3.0, 4.0 };

static const float g_ChessHealthMulti[] = { 1.0, 1.0, 1.0 };
static const char g_ChessPlugin[][] =
{
	"npc_oshimuno_king",
	"npc_oshimuno_rook",
	"npc_oshimuno_bishop"
};

static const char g_ChessRamSound[] = "plats/tram_hit4.wav";
static const char g_ChessStageSound[] = "mvm/mvm_tank_horn.wav";
static const char g_ChessOrbExplodeSound[] = "weapons/explode1.wav";
static const char g_ChessBlessingSound[] = "items/powerup_pickup_king.wav";

static bool g_ChessTelegraphDestination = true;

static int g_ChessLaser = -1;
static bool g_ChessFightActive;
static bool g_ChessEnraged;
static int g_ChessDeaths;
static int g_ChessMinStage;
static int g_ChessOrbPhase;
static float g_ChessOrbCenter[3];
static float g_ChessOrbRingDraw;
static float g_ChessFightThinkTime;
static bool g_ChessSummonPending;
static int g_ChessSummonerRef = INVALID_ENT_REFERENCE;
static int g_ChessSerialCounter;

static int g_ChessBossRef[CHESS_SLOT_MAX] = { -1, ... };
static bool g_ChessBossJoined[CHESS_SLOT_MAX];
static bool g_ChessBossDead[CHESS_SLOT_MAX];
static float g_ChessBossDeathPos[CHESS_SLOT_MAX][3];
static int g_ChessOrbHealth[CHESS_SLOT_MAX];
static int g_ChessBaseHealth[CHESS_SLOT_MAX];
static int g_ChessOrbMarker[CHESS_SLOT_MAX] = { -1, ... };
static int g_ChessOrbRef[CHESS_SLOT_MAX] = { -1, ... };

static int g_ChessPieceSlot[MAXENTITIES];
static float g_ChessPieceYaw[MAXENTITIES];
static int g_ChessPieceSteps[MAXENTITIES];
static bool g_ChessPieceFlee[MAXENTITIES];
static float g_ChessPieceRamDamage[MAXENTITIES];
static float g_ChessPieceSpawnAvoid[MAXENTITIES];
static float g_ChessPieceFleeRange[MAXENTITIES];
static bool g_ChessFleeNow;
static float g_ChessAvoidPos[CHESS_AVOID_SPAWNS_MAX][3];
static int g_ChessAvoidCount;
static float g_ChessAvoidFrom;

static int g_ChessMoveState[MAXENTITIES];
static float g_ChessMoveNext[MAXENTITIES];
static float g_ChessMoveStart[MAXENTITIES][3];
static float g_ChessMoveDest[MAXENTITIES][3];
static float g_ChessMoveLast[MAXENTITIES][3];
static float g_ChessMoveYaw[MAXENTITIES];
static float g_ChessMoveTile[MAXENTITIES];
static int g_ChessMoveSteps[MAXENTITIES];
static float g_ChessMoveTileZ[MAXENTITIES][CHESS_MAX_STEPS + 1];
static float g_ChessMoveTimeout[MAXENTITIES];
static float g_ChessMoveBestDist[MAXENTITIES];
static int g_ChessMoveAlpha[MAXENTITIES];
static float g_ChessMoveDraw[MAXENTITIES];
static int g_ChessMoveSerial[MAXENTITIES];
static int g_ChessMoveFails[MAXENTITIES];
static float g_ChessPathFade[MAXENTITIES];
static float g_ChessLandFade[MAXENTITIES];
static float g_ChessLandPos[MAXENTITIES][3];
static float g_ChessLandTile[MAXENTITIES];
static float g_ChessFadeDraw[MAXENTITIES];

static int g_ChessRamHit[CHESS_SLOT_MAX][MAXENTITIES];
static bool g_ChessBlastHit[MAXENTITIES];

void OshimunoChess_Precache()
{
	g_ChessLaser = PrecacheModel("sprites/laserbeam.vmt");
	PrecacheSound(g_ChessRamSound);
	PrecacheSound(g_ChessStageSound);
	PrecacheSound(g_ChessOrbExplodeSound);
	PrecacheSound(g_ChessBlessingSound);
	PrecacheSound("npc/zombie_poison/pz_alert1.wav");
}

int OshimunoChess_Stage()
{
	if(g_ChessEnraged)
		return 4;

	int stage = 1 + g_ChessDeaths;
	if(stage > 3)
		stage = 3;

	if(stage < g_ChessMinStage)
		stage = g_ChessMinStage;

	return stage;
}

float OshimunoChess_TileSize()
{
	return g_ChessTileSize[OshimunoChess_Stage() - 1];
}

static bool OshimunoChessEntAlive(int ref)
{
	int entity = EntRefToEntIndex(ref);
	return (entity > MaxClients && IsValidEntity(entity) && !b_NpcHasDied[entity]);
}

static bool OshimunoChessBossAlive(int slot)
{
	return (g_ChessBossJoined[slot] && !g_ChessBossDead[slot] && OshimunoChessEntAlive(g_ChessBossRef[slot]));
}

static int OshimunoChessBossesAlive()
{
	int alive = 0;
	for(int slot; slot < CHESS_SLOT_MAX; slot++)
	{
		if(OshimunoChessBossAlive(slot))
			alive++;
	}
	return alive;
}

static bool OshimunoChessAnyoneLeft()
{
	for(int slot; slot < CHESS_SLOT_MAX; slot++)
	{
		if(OshimunoChessEntAlive(g_ChessBossRef[slot]) || OshimunoChessEntAlive(g_ChessOrbRef[slot]))
			return true;
	}
	return false;
}

static void OshimunoChessRemoveMarker(int slot)
{
	int marker = EntRefToEntIndex(g_ChessOrbMarker[slot]);
	if(marker > MaxClients && IsValidEntity(marker))
		RemoveEntity(marker);

	g_ChessOrbMarker[slot] = INVALID_ENT_REFERENCE;
}

static void OshimunoChessStartFight(int entity, const char[] data)
{
	float gameTime = GetGameTime();

	g_ChessFightActive = true;
	g_ChessEnraged = false;
	g_ChessDeaths = 0;
	g_ChessOrbPhase = 0;
	g_ChessOrbRingDraw = 0.0;
	g_ChessFightThinkTime = 0.0;
	for(int slot; slot < CHESS_SLOT_MAX; slot++)
	{
		OshimunoChessRemoveMarker(slot);
		g_ChessBossRef[slot] = INVALID_ENT_REFERENCE;
		g_ChessOrbRef[slot] = INVALID_ENT_REFERENCE;
		g_ChessBossJoined[slot] = false;
		g_ChessBossDead[slot] = false;
		g_ChessOrbHealth[slot] = 0;
		g_ChessBaseHealth[slot] = 0;
	}

	g_ChessMinStage = 1;
	if(StrContains(data, "stage2") != -1)
		g_ChessMinStage = 2;
	else if(StrContains(data, "stage3") != -1)
		g_ChessMinStage = 3;
	else if(StrContains(data, "stage4") != -1)
		g_ChessEnraged = true;

	g_ChessSummonPending = (StrContains(data, "solo") == -1);
	g_ChessSummonerRef = EntIndexToEntRef(entity);

	RaidModeTime = gameTime + CHESS_RAID_TIME;
	RaidBossActive = EntIndexToEntRef(entity);
	RaidAllowsBuildings = false;
	RaidAllowLastman = true;
	WaveStart_SubWaveStart(gameTime + 500.0);
	GiveOneRevive();
	RemoveAllDamageAddition();
	BlockLoseSay = false;

	EmitSoundToAll("npc/zombie_poison/pz_alert1.wav", _, _, _, _, 1.0);
	EmitSoundToAll("npc/zombie_poison/pz_alert1.wav", _, _, _, _, 1.0);
	for(int client_check=1; client_check<=MaxClients; client_check++)
	{
		if(IsClientInGame(client_check) && !IsFakeClient(client_check))
		{
			SetGlobalTransTarget(client_check);
			ShowGameText(client_check, "item_armor", 1, "%s", "King, Rook and Bishop have arrived");
		}
	}

	char buffers[3][64];
	ExplodeString(data, ";", buffers, sizeof(buffers), sizeof(buffers[]));
	if(buffers[0][0] == 's' && buffers[0][1] == 'c')
	{
		ReplaceString(buffers[0], 64, "sc", "");
		float value = StringToFloat(buffers[0]);
		RaidModeScaling = value;

		if(RaidModeScaling < 35)
		{
			RaidModeScaling *= 0.25;
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
			RaidModeScaling *= 0.25;
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

	RaidModeScaling *= amount_of_people;

	if(StrContains(data, "timeout") != -1)
	{
		RaidModeTime = gameTime + 10.0;
	}
	if(g_ChessEnraged)
	{
		RaidModeTime = FAR_FUTURE;
	}
}

void OshimunoChess_Setup(int entity, int slot, float yaw, int steps, bool flee, float ramDamage, const char[] data)
{
	if(!g_ChessFightActive || !OshimunoChessAnyoneLeft())
		OshimunoChessStartFight(entity, data);

	g_ChessBossRef[slot] = EntIndexToEntRef(entity);
	g_ChessBossJoined[slot] = true;
	g_ChessBossDead[slot] = false;
	g_ChessBaseHealth[slot] = 0;

	g_ChessPieceSlot[entity] = slot;
	g_ChessPieceYaw[entity] = yaw;
	g_ChessPieceSteps[entity] = steps;
	g_ChessPieceFlee[entity] = flee;
	g_ChessPieceRamDamage[entity] = ramDamage;
	g_ChessPieceSpawnAvoid[entity] = 0.0;
	g_ChessPieceFleeRange[entity] = 0.0;

	g_ChessMoveState[entity] = CHESS_MOVE_IDLE;
	g_ChessMoveNext[entity] = GetGameTime(entity) + g_ChessMoveDelay[OshimunoChess_Stage() - 1];
	g_ChessMoveSerial[entity] = 0;
	g_ChessMoveFails[entity] = 0;
	g_ChessMoveDraw[entity] = 0.0;
	g_ChessMoveAlpha[entity] = 255;
	g_ChessPathFade[entity] = 0.0;
	g_ChessLandFade[entity] = 0.0;
	g_ChessFadeDraw[entity] = 0.0;
	b_ThisEntityIgnoredBeingCarried[entity] = false;
}

static void OshimunoChessSummonPartners(int entity)
{
	float pos[3]; GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", pos);
	float ang[3]; GetEntPropVector(entity, Prop_Data, "m_angRotation", ang);
	int mySlot = g_ChessPieceSlot[entity];
	float health = float(ReturnEntityMaxHealth(entity));

	for(int slot; slot < CHESS_SLOT_MAX; slot++)
	{
		if(g_ChessBossJoined[slot])
			continue;

		int spawn = NPC_CreateByName(g_ChessPlugin[slot], -1, pos, ang, GetTeam(entity), "partner");
		if(spawn > MaxClients)
		{
			NpcStats_CopyStats(entity, spawn);
			if(GetTeam(entity) != TFTeam_Red)
				NpcAddedToZombiesLeftCurrently(spawn, true);

			int spawnHealth = RoundToCeil(health * g_ChessHealthMulti[slot] / g_ChessHealthMulti[mySlot]);
			SetEntProp(spawn, Prop_Data, "m_iHealth", spawnHealth);
			SetEntProp(spawn, Prop_Data, "m_iMaxHealth", spawnHealth);
			fl_Extra_Damage[spawn] = fl_Extra_Damage[entity];
			fl_Extra_Speed[spawn] = fl_Extra_Speed[entity];
			fl_Extra_MeleeArmor[spawn] = fl_Extra_MeleeArmor[entity];
			fl_Extra_RangedArmor[spawn] = fl_Extra_RangedArmor[entity];
			view_as<CClotBody>(spawn).m_bThisNpcIsABoss = true;
			GiveNpcOutLineLastOrBoss(spawn, true);
		}
	}
}

static bool OshimunoChessSeenByPlayers(float pos[3])
{
	float f3_PositionTemp[3];
	f3_PositionTemp = pos;
	f3_PositionTemp[2] += 40.0;
	for(int client_check=1; client_check<=MaxClients; client_check++)
	{
		if(IsClientInGame(client_check) && IsPlayerAlive(client_check) && GetClientTeam(client_check)==2 && TeutonType[client_check] == TEUTON_NONE && dieingstate[client_check] == 0)
		{
			if(Can_I_See_Enemy_Only(client_check, client_check, f3_PositionTemp))
				return true;
		}
	}
	return false;
}

static void OshimunoChessPlaceBosses(int entity)
{
	float candPos[CHESS_SPAWN_SAMPLES][3];
	float candZ[CHESS_SPAWN_SAMPLES];
	bool candSeen[CHESS_SPAWN_SAMPLES];
	int count = 0;
	float minDist = CHESS_SPAWN_MIN_DIST;
	for(int tries; tries < 3; tries++)
	{
		for(int i; i < CHESS_SPAWN_SAMPLES; i++)
		{
			if(count >= CHESS_SPAWN_SAMPLES)
				break;

			float VectorSave[3];
			VectorSave[1] = 1.0;
			int Decicion = TeleportDiversioToRandLocation(entity, true, CHESS_SPAWN_MAX_DIST, minDist, false, false, VectorSave);
			if(Decicion == 3)
				break;

			if(Decicion != 1)
				continue;

			candPos[count] = VectorSave;
			candZ[count] = VectorSave[2];
			candSeen[count] = OshimunoChessSeenByPlayers(VectorSave);
			count++;
		}
		if(count >= (CHESS_SLOT_MAX * 2))
			break;

		minDist *= 0.5;
	}

	int bosses[CHESS_SLOT_MAX];
	int bossCount = 0;
	for(int slot; slot < CHESS_SLOT_MAX; slot++)
	{
		if(OshimunoChessBossAlive(slot))
		{
			bosses[bossCount] = EntRefToEntIndex(g_ChessBossRef[slot]);
			bossCount++;
		}
	}
	if(count < 1 || bossCount < 1)
		return;

	SortFloats(candZ, count);
	float floorZ = candZ[count / 4] + CHESS_SPAWN_FLOOR_TOLERANCE;

	int pool[CHESS_SPAWN_SAMPLES];
	int poolCount = 0;
	for(int pass; pass < 3; pass++)
	{
		poolCount = 0;
		for(int i; i < count; i++)
		{
			if(pass < 2 && candPos[i][2] > floorZ)
				continue;

			if(pass < 1 && candSeen[i])
				continue;

			pool[poolCount] = i;
			poolCount++;
		}
		if(poolCount >= bossCount)
			break;
	}

	int want = bossCount;
	if(want > poolCount)
		want = poolCount;

	int pick[CHESS_SLOT_MAX] = { -1, ... };
	float best = -1.0;
	if(want >= 3)
	{
		for(int a; a < poolCount; a++)
		{
			for(int b = a + 1; b < poolCount; b++)
			{
				float distAB = GetVectorDistance(candPos[pool[a]], candPos[pool[b]], true);
				for(int c = b + 1; c < poolCount; c++)
				{
					float lowest = distAB;
					float distAC = GetVectorDistance(candPos[pool[a]], candPos[pool[c]], true);
					float distBC = GetVectorDistance(candPos[pool[b]], candPos[pool[c]], true);
					if(distAC < lowest)
						lowest = distAC;

					if(distBC < lowest)
						lowest = distBC;

					if(lowest > best)
					{
						best = lowest;
						pick[0] = pool[a];
						pick[1] = pool[b];
						pick[2] = pool[c];
					}
				}
			}
		}
	}
	else if(want == 2)
	{
		for(int a; a < poolCount; a++)
		{
			for(int b = a + 1; b < poolCount; b++)
			{
				float distAB = GetVectorDistance(candPos[pool[a]], candPos[pool[b]], true);
				if(distAB > best)
				{
					best = distAB;
					pick[0] = pool[a];
					pick[1] = pool[b];
				}
			}
		}
	}
	else if(want == 1)
	{
		pick[0] = pool[0];
	}

	for(int i; i < bossCount; i++)
	{
		if(pick[i] == -1)
			continue;

		TeleportEntity(bosses[i], candPos[pick[i]], NULL_VECTOR, NULL_VECTOR);
		RemoveSpawnProtectionLogic(bosses[i], true);
	}
}

static void OshimunoChessUpdateRaidTarget()
{
	if(OshimunoChessEntAlive(RaidBossActive))
		return;

	for(int slot; slot < CHESS_SLOT_MAX; slot++)
	{
		if(OshimunoChessBossAlive(slot))
		{
			RaidBossActive = g_ChessBossRef[slot];
			return;
		}
	}
	for(int slot; slot < CHESS_SLOT_MAX; slot++)
	{
		if(OshimunoChessEntAlive(g_ChessOrbRef[slot]))
		{
			RaidBossActive = g_ChessOrbRef[slot];
			return;
		}
	}
}

static void OshimunoChessEndFight()
{
	g_ChessFightActive = false;
	g_ChessSummonPending = false;
	RaidBossActive = INVALID_ENT_REFERENCE;
	for(int slot; slot < CHESS_SLOT_MAX; slot++)
	{
		OshimunoChessRemoveMarker(slot);
	}
}

static void OshimunoChessEnrage()
{
	g_ChessEnraged = true;
	RaidModeTime = FAR_FUTURE;

	int keep = -1;
	for(int slot; slot < CHESS_SLOT_MAX; slot++)
	{
		if(OshimunoChessBossAlive(slot))
		{
			keep = slot;
			break;
		}
	}
	int killed = 0;
	for(int slot; slot < CHESS_SLOT_MAX; slot++)
	{
		if(slot == keep || !OshimunoChessBossAlive(slot))
			continue;

		RequestFrame(KillNpc, g_ChessBossRef[slot]);
		killed++;
	}
	if(keep != -1 && killed > 0)
		OshimunoChessBuffBoss(keep, g_ChessDeathHealthMulti[sizeof(g_ChessDeathHealthMulti) - 1]);

	EmitSoundToAll(g_ChessStageSound, _, _, _, _, 1.0);
	CPrintToChatAll("{crimson}Time is up, the board is cleared for one last piece.");
}

void OshimunoChess_FightThink(int entity)
{
	if(!g_ChessFightActive)
		return;

	if(g_ChessSummonPending && EntRefToEntIndex(g_ChessSummonerRef) == entity)
	{
		g_ChessSummonPending = false;
		OshimunoChessSummonPartners(entity);
		OshimunoChessPlaceBosses(entity);
	}

	float gameTime = GetGameTime();
	if(g_ChessFightThinkTime == gameTime)
		return;

	g_ChessFightThinkTime = gameTime;
	OshimunoChessUpdateRaidTarget();

	if(g_ChessOrbPhase == 1)
	{
		if(g_ChessOrbRingDraw < gameTime)
		{
			g_ChessOrbRingDraw = gameTime + 0.1;
			float vecRing[3];
			vecRing = g_ChessOrbCenter;
			spawnRing_Vectors(vecRing, CHESS_ORB_CIRCLE_RADIUS * 2.0, 0.0, 0.0, 6.0, "materials/sprites/laserbeam.vmt", 170, 60, 255, 255, 1, 0.15, 8.0, 0.1, 1);
		}
		return;
	}

	if(!g_ChessEnraged && !BlockLoseSay && g_ChessOrbPhase == 0 && RaidModeTime < gameTime)
	{
		OshimunoChessEnrage();
	}
}

void OshimunoChess_ApplyStage(int entity, int stage)
{
	SetEntPropFloat(entity, Prop_Send, "m_flModelScale", g_ChessModelScale[stage - 1]);
	EmitSoundToAll(g_ChessStageSound, entity, SNDCHAN_STATIC, BOSS_ZOMBIE_SOUNDLEVEL, _, BOSS_ZOMBIE_VOLUME);

	float next = GetGameTime(entity) + g_ChessMoveDelay[stage - 1];
	if(g_ChessMoveState[entity] == CHESS_MOVE_IDLE && g_ChessMoveNext[entity] > next)
		g_ChessMoveNext[entity] = next;
}

void OshimunoChess_PauseMoves(int entity, float until)
{
	if(g_ChessMoveNext[entity] < until)
		g_ChessMoveNext[entity] = until;
}

static void OshimunoChessBeam(float start[3], float end[3], const int color[4], float life)
{
	TE_SetupBeamPoints(start, end, g_ChessLaser, -1, 0, 0, life, 4.0, 4.0, 0, 0.0, color, 0);
	TE_SendToAll();
}

void OshimunoChess_DrawRect(float anchor[3], float yawDeg, float alongMin, float alongMax, float halfWidth, const int color[4], float life)
{
	float yawRad = yawDeg * FLOAT_PI / 180.0;
	float fwdX = Cosine(yawRad);
	float fwdY = Sine(yawRad);
	float leftX = -fwdY;
	float leftY = fwdX;

	float c1[3], c2[3], c3[3], c4[3];
	c1[0] = anchor[0] + (fwdX * alongMin) + (leftX * halfWidth);
	c1[1] = anchor[1] + (fwdY * alongMin) + (leftY * halfWidth);
	c1[2] = anchor[2] + 4.0;
	c2[0] = anchor[0] + (fwdX * alongMin) - (leftX * halfWidth);
	c2[1] = anchor[1] + (fwdY * alongMin) - (leftY * halfWidth);
	c2[2] = anchor[2] + 4.0;
	c3[0] = anchor[0] + (fwdX * alongMax) + (leftX * halfWidth);
	c3[1] = anchor[1] + (fwdY * alongMax) + (leftY * halfWidth);
	c3[2] = anchor[2] + 4.0;
	c4[0] = anchor[0] + (fwdX * alongMax) - (leftX * halfWidth);
	c4[1] = anchor[1] + (fwdY * alongMax) - (leftY * halfWidth);
	c4[2] = anchor[2] + 4.0;

	OshimunoChessBeam(c1, c2, color, life);
	OshimunoChessBeam(c1, c3, color, life);
	OshimunoChessBeam(c2, c4, color, life);
	OshimunoChessBeam(c3, c4, color, life);
}

void OshimunoChess_DrawCross(float anchor[3], float yawDeg, float length, float halfWidth, const int color[4], float life)
{
	for(int dir = 0; dir < 4; dir++)
	{
		float yawRad = (yawDeg + (90.0 * float(dir))) * FLOAT_PI / 180.0;
		float fwdX = Cosine(yawRad);
		float fwdY = Sine(yawRad);
		float leftX = -fwdY;
		float leftY = fwdX;

		float c1[3], c2[3], c3[3], c4[3];
		c1[0] = anchor[0] + (fwdX * halfWidth) + (leftX * halfWidth);
		c1[1] = anchor[1] + (fwdY * halfWidth) + (leftY * halfWidth);
		c1[2] = anchor[2] + 4.0;
		c2[0] = anchor[0] + (fwdX * halfWidth) - (leftX * halfWidth);
		c2[1] = anchor[1] + (fwdY * halfWidth) - (leftY * halfWidth);
		c2[2] = anchor[2] + 4.0;
		c3[0] = anchor[0] + (fwdX * length) + (leftX * halfWidth);
		c3[1] = anchor[1] + (fwdY * length) + (leftY * halfWidth);
		c3[2] = anchor[2] + 4.0;
		c4[0] = anchor[0] + (fwdX * length) - (leftX * halfWidth);
		c4[1] = anchor[1] + (fwdY * length) - (leftY * halfWidth);
		c4[2] = anchor[2] + 4.0;

		OshimunoChessBeam(c1, c3, color, life);
		OshimunoChessBeam(c3, c4, color, life);
		OshimunoChessBeam(c4, c2, color, life);
	}
}

static void OshimunoChessDrawPath(int entity, int alpha, float life, bool landed = false)
{
	float yawRad = g_ChessMoveYaw[entity] * FLOAT_PI / 180.0;
	float fwdX = Cosine(yawRad);
	float fwdY = Sine(yawRad);
	float leftX = -fwdY;
	float leftY = fwdX;
	float tile = g_ChessMoveTile[entity];
	float half = tile * 0.5;

	int color[4];
	color[0] = 255;
	color[1] = 255;
	color[2] = 0;
	color[3] = alpha;

	int last = g_ChessMoveSteps[entity];
	if(landed || !g_ChessTelegraphDestination)
		last--;

	for(int index = 0; index <= last; index++)
	{
		float centerX = g_ChessMoveStart[entity][0] + (fwdX * tile * float(index));
		float centerY = g_ChessMoveStart[entity][1] + (fwdY * tile * float(index));
		float height = g_ChessMoveTileZ[entity][index] + 4.0;

		float c1[3], c2[3], c3[3], c4[3];
		c1[0] = centerX - (fwdX * half) + (leftX * half);
		c1[1] = centerY - (fwdY * half) + (leftY * half);
		c1[2] = height;
		c2[0] = centerX - (fwdX * half) - (leftX * half);
		c2[1] = centerY - (fwdY * half) - (leftY * half);
		c2[2] = height;
		c3[0] = centerX + (fwdX * half) + (leftX * half);
		c3[1] = centerY + (fwdY * half) + (leftY * half);
		c3[2] = height;
		c4[0] = centerX + (fwdX * half) - (leftX * half);
		c4[1] = centerY + (fwdY * half) - (leftY * half);
		c4[2] = height;

		OshimunoChessBeam(c1, c2, color, life);
		OshimunoChessBeam(c1, c3, color, life);
		OshimunoChessBeam(c2, c4, color, life);
		if(index == last && !landed)
			OshimunoChessBeam(c3, c4, color, life);
	}
}

static void OshimunoChessFadeThink(int entity, float gameTime)
{
	if(!g_ChessPathFade[entity] && !g_ChessLandFade[entity])
		return;

	if(g_ChessFadeDraw[entity] > gameTime)
		return;

	g_ChessFadeDraw[entity] = gameTime + 0.1;

	if(g_ChessPathFade[entity])
	{
		float remaining = g_ChessPathFade[entity] - gameTime;
		if(remaining <= 0.0)
		{
			g_ChessPathFade[entity] = 0.0;
		}
		else
		{
			OshimunoChessDrawPath(entity, RoundToNearest(255.0 * (remaining / CHESS_PATH_FADE_TIME)), 0.15, true);
		}
	}
	if(g_ChessLandFade[entity])
	{
		float remaining = g_ChessLandFade[entity] - gameTime;
		if(remaining <= 0.0)
		{
			g_ChessLandFade[entity] = 0.0;
		}
		else
		{
			int color[4];
			color[0] = 255;
			color[1] = 0;
			color[2] = 0;
			color[3] = RoundToNearest(255.0 * (remaining / CHESS_LAND_FADE_TIME));
			float half = g_ChessLandTile[entity] * 0.5;
			OshimunoChess_DrawRect(g_ChessLandPos[entity], g_ChessPieceYaw[entity], -half, half, half, color, 0.15);
		}
	}
}

void OshimunoChess_ResetBlast()
{
	Zero(g_ChessBlastHit);
}

static bool OshimunoChessRectHit(int entity, int victim, float anchor[3], float fwdX, float fwdY, float alongMin, float alongMax, float halfWidth, float damage, int damagetype)
{
	if(g_ChessBlastHit[victim])
		return false;

	if(!IsValidEnemy(entity, victim, true, true))
		return false;

	float pos[3];
	GetEntPropVector(victim, Prop_Data, "m_vecAbsOrigin", pos);
	float dx = pos[0] - anchor[0];
	float dy = pos[1] - anchor[1];
	float dz = pos[2] - anchor[2];
	if(dz > CHESS_AOE_HEIGHT || dz < -CHESS_AOE_HEIGHT)
		return false;

	float fwdDist = (dx * fwdX) + (dy * fwdY);
	if(fwdDist < (alongMin - CHESS_AOE_PAD) || fwdDist > (alongMax + CHESS_AOE_PAD))
		return false;

	float leftDist = (dx * -fwdY) + (dy * fwdX);
	if(FloatAbs(leftDist) > (halfWidth + CHESS_AOE_PAD))
		return false;

	g_ChessBlastHit[victim] = true;
	float at[3];
	WorldSpaceCenter(victim, at);
	SDKHooks_TakeDamage(victim, entity, entity, damage, damagetype, -1, _, at);
	return true;
}

int OshimunoChess_DamageRect(int entity, float anchor[3], float yawDeg, float alongMin, float alongMax, float halfWidth, float damage, int damagetype = DMG_CLUB)
{
	float yawRad = yawDeg * FLOAT_PI / 180.0;
	float fwdX = Cosine(yawRad);
	float fwdY = Sine(yawRad);

	int hits = 0;
	for(int client = 1; client <= MaxClients; client++)
	{
		if(!IsClientInGame(client) || !IsPlayerAlive(client))
			continue;

		if(OshimunoChessRectHit(entity, client, anchor, fwdX, fwdY, alongMin, alongMax, halfWidth, damage, damagetype))
			hits++;
	}
	for(int entitycount; entitycount<i_MaxcountNpcTotal; entitycount++)
	{
		int ally = EntRefToEntIndexFast(i_ObjectsNpcsTotal[entitycount]);
		if(ally <= MaxClients || !IsValidEntity(ally) || b_NpcHasDied[ally])
			continue;

		if(OshimunoChessRectHit(entity, ally, anchor, fwdX, fwdY, alongMin, alongMax, halfWidth, damage, damagetype))
			hits++;
	}
	return hits;
}

int OshimunoChess_LandingDamage(int entity, float damage)
{
	OshimunoChess_ResetBlast();
	float half = g_ChessLandTile[entity] * 0.5;
	return OshimunoChess_DamageRect(entity, g_ChessLandPos[entity], g_ChessPieceYaw[entity], -half, half, half, damage);
}

static void OshimunoChessRamTouched(int entity, int enemy)
{
	if(!IsValidEnemy(entity, enemy, true, true))
		return;

	int slot = g_ChessPieceSlot[entity];
	if(g_ChessRamHit[slot][enemy] == g_ChessMoveSerial[entity])
		return;

	g_ChessRamHit[slot][enemy] = g_ChessMoveSerial[entity];

	float targPos[3];
	WorldSpaceCenter(enemy, targPos);
	float VecMe[3];
	WorldSpaceCenter(entity, VecMe);
	SDKHooks_TakeDamage(enemy, entity, entity, g_ChessPieceRamDamage[entity] * RaidModeScaling, DMG_CLUB, -1, _, targPos);
	EmitSoundToAll(g_ChessRamSound, entity, SNDCHAN_STATIC, 80, _, 0.8);

	float AngleVec[3];
	MakeVectorFromPoints(VecMe, targPos, AngleVec);
	GetVectorAngles(AngleVec, AngleVec);
	AngleVec[0] = -45.0;
	if(enemy <= MaxClients)
	{
		f_AntiStuckPhaseThrough[enemy] = GetGameTime() + 1.0;
		ApplyStatusEffect(enemy, enemy, "Intangible", 1.0);
		Custom_Knockback(entity, enemy, CHESS_RAM_KNOCKBACK, true, true, .OverrideLookAng = AngleVec);
		TF2_AddCondition(enemy, TFCond_LostFooting, 0.5);
		TF2_AddCondition(enemy, TFCond_AirCurrent, 0.5);
	}
	else
	{
		Custom_Knockback(entity, enemy, CHESS_RAM_KNOCKBACK * 0.5, true, true, .OverrideLookAng = AngleVec);
	}
}

static void OshimunoChessRamThink(int entity, float pos[3])
{
	static float hullcheckmaxs[3];
	static float hullcheckmins[3];
	hullcheckmaxs[0] = 30.0 + CHESS_RAM_PAD;
	hullcheckmaxs[1] = 30.0 + CHESS_RAM_PAD;
	hullcheckmaxs[2] = 120.0;
	hullcheckmins[0] = -30.0 - CHESS_RAM_PAD;
	hullcheckmins[1] = -30.0 - CHESS_RAM_PAD;
	hullcheckmins[2] = 0.0;

	ResetTouchedentityResolve();
	ResolvePlayerCollisions_Npc_Internal(g_ChessMoveLast[entity], pos, hullcheckmins, hullcheckmaxs, entity);

	for (int entity_traced = 0; entity_traced < MAXENTITIES; entity_traced++)
	{
		if(!TouchedNpcResolve(entity_traced))
			break;

		OshimunoChessRamTouched(entity, ConvertTouchedResolve(entity_traced));
	}
	ResetTouchedentityResolve();
}

static void OshimunoChessHull(float mins[3], float maxs[3])
{
	mins[0] = -CHESS_PATH_HULL;
	mins[1] = -CHESS_PATH_HULL;
	mins[2] = 0.0;
	maxs[0] = CHESS_PATH_HULL;
	maxs[1] = CHESS_PATH_HULL;
	maxs[2] = CHESS_PATH_HEIGHT;
}

static bool OshimunoChessFloorAt(float vecSpot[3], float beneath, float vecGround[3])
{
	CNavArea area = TheNavMesh.GetNavArea(vecSpot, beneath);
	if(area == NULL_AREA)
		return false;

	int NavAttribs = area.GetAttributes();
	if(NavAttribs & NAV_MESH_AVOID)
		return false;

	vecGround[0] = vecSpot[0];
	vecGround[1] = vecSpot[1];
	vecGround[2] = area.GetZ(vecSpot[0], vecSpot[1]);
	return true;
}

static bool OshimunoChessFloorUsable(int entity, float vecGround[3])
{
	float mins[3], maxs[3];
	OshimunoChessHull(mins, maxs);

	float top[3], bottom[3];
	top = vecGround;
	top[2] += CHESS_PATH_STEPUP;
	bottom = vecGround;
	bottom[2] -= CHESS_PATH_STEPUP;

	Handle trace = TR_TraceHullFilterEx(top, bottom, mins, maxs, MASK_NPCSOLID, TraceRayHitWorldOnly, entity);
	bool startSolid = TR_StartSolid(trace);
	bool didHit = TR_DidHit(trace);
	TR_GetEndPosition(vecGround, trace);
	delete trace;
	if(startSolid || !didHit)
		return false;

	return !IsBoxHazard(vecGround, mins, maxs);
}

static void OshimunoChessAddLevel(float levels[CHESS_PATH_LEVELS], int &levelCount, float height)
{
	if(levelCount >= CHESS_PATH_LEVELS)
		return;

	for(int i = 0; i < levelCount; i++)
	{
		if(FloatAbs(levels[i] - height) < CHESS_PATH_LEVEL_MERGE)
			return;
	}
	levels[levelCount] = height;
	levelCount++;
}

static bool OshimunoChessInsideWorld(int entity, float pos[3])
{
	float mins[3], maxs[3];
	OshimunoChessHull(mins, maxs);
	mins[2] = CHESS_PATH_STEPUP;

	Handle trace = TR_TraceHullFilterEx(pos, pos, mins, maxs, MASK_NPCSOLID, TraceRayHitWorldOnly, entity);
	bool didHit = TR_DidHit(trace);
	delete trace;
	return didHit;
}

static void OshimunoChessSetAlphaSingle(int entity, int alpha)
{
	int red, green, blue, old;
	GetEntityRenderColor(entity, red, green, blue, old);
	SetEntityRenderMode(entity, alpha >= 255 ? RENDER_NORMAL : RENDER_TRANSCOLOR);
	SetEntityRenderColor(entity, red, green, blue, alpha);
}

static void OshimunoChessSetAlpha(int entity, int alpha)
{
	if(g_ChessMoveAlpha[entity] == alpha)
		return;

	g_ChessMoveAlpha[entity] = alpha;
	OshimunoChessSetAlphaSingle(entity, alpha);
	for(int i = 0; i < sizeof(i_Wearable[]); i++)
	{
		int wearable = EntRefToEntIndex(i_Wearable[entity][i]);
		if(wearable > MaxClients && IsValidEntity(wearable))
			OshimunoChessSetAlphaSingle(wearable, alpha);
	}
}

static void OshimunoChessSetPhasing(int entity, bool phasing)
{
	b_IgnoreAllCollisionNPC[entity] = phasing;
	b_NoGravity[entity] = phasing;
	b_DoNotUnStuck[entity] = phasing;
	b_ThisEntityIgnoredBeingCarried[entity] = phasing;
	if(!phasing)
		OshimunoChessSetAlpha(entity, 255);
}

void OshimunoChess_SetFleeRange(int entity, float distance)
{
	g_ChessPieceFleeRange[entity] = distance;
}

void OshimunoChess_SetSpawnAvoid(int entity, float distance)
{
	g_ChessPieceSpawnAvoid[entity] = distance;
}

static void OshimunoChessCollectSpawns()
{
	g_ChessAvoidCount = 0;
	for(int i = 0; i < ZR_MAX_SPAWNERS; i++)
	{
		if(g_ChessAvoidCount >= CHESS_AVOID_SPAWNS_MAX)
			break;

		int spawner = i_ObjectsSpawners[i];
		if(spawner <= MaxClients || !IsValidEntity(spawner))
			continue;

		char classname[32];
		GetEntityClassname(spawner, classname, sizeof(classname));
		if(!StrEqual(classname, "info_player_teamspawn") || GetTeam(spawner) == TFTeam_Red)
			continue;

		GetEntPropVector(spawner, Prop_Data, "m_vecAbsOrigin", g_ChessAvoidPos[g_ChessAvoidCount]);
		g_ChessAvoidCount++;
	}
}

static float OshimunoChessSpawnDist(float pos[3])
{
	float nearestSpawn = 0.0;
	for(int i = 0; i < g_ChessAvoidCount; i++)
	{
		float spawnDist = GetVectorDistance(pos, g_ChessAvoidPos[i]);
		if(i == 0 || spawnDist < nearestSpawn)
			nearestSpawn = spawnDist;
	}
	return nearestSpawn;
}

static bool OshimunoChessLinedUp(int entity, float pos[3], float target[3], float tile)
{
	float dz = target[2] - pos[2];
	if(dz > CHESS_AOE_HEIGHT || dz < -CHESS_AOE_HEIGHT)
		return false;

	float dx = target[0] - pos[0];
	float dy = target[1] - pos[1];
	float half = tile * 0.5;
	float reach = tile * (float(g_ChessPieceSteps[entity]) + 0.5);
	for(int dir = 0; dir < 4; dir++)
	{
		float yawRad = (g_ChessPieceYaw[entity] + (90.0 * float(dir))) * FLOAT_PI / 180.0;
		float fwdX = Cosine(yawRad);
		float fwdY = Sine(yawRad);
		float fwdDist = (dx * fwdX) + (dy * fwdY);
		if(fwdDist < -half || fwdDist > reach)
			continue;

		float leftDist = (dx * -fwdY) + (dy * fwdX);
		if(FloatAbs(leftDist) > half)
			continue;

		return true;
	}
	return false;
}

static float OshimunoChessScore(int entity, float pos[3], float tile, int nearest, float targetPos[][3], int targetCount)
{
	float dist = GetVectorDistance(pos, targetPos[nearest]);
	if(g_ChessFleeNow)
	{
		if(g_ChessAvoidCount > 0)
		{
			float spawnDist = OshimunoChessSpawnDist(pos);
			if(spawnDist < g_ChessPieceSpawnAvoid[entity] && spawnDist < g_ChessAvoidFrom)
				return dist - 10000000.0;
		}
		return dist;
	}

	if(OshimunoChessLinedUp(entity, pos, targetPos[nearest], tile))
		return 2000000.0 - dist;

	float bestOther = -1.0;
	for(int i = 0; i < targetCount; i++)
	{
		if(i == nearest)
			continue;

		if(!OshimunoChessLinedUp(entity, pos, targetPos[i], tile))
			continue;

		float other = GetVectorDistance(pos, targetPos[i]);
		if(bestOther < 0.0 || other < bestOther)
			bestOther = other;
	}
	if(bestOther >= 0.0)
		return 1000000.0 - bestOther;

	return -dist;
}

static bool OshimunoChessStartMove(CClotBody npc, float gameTime)
{
	int entity = npc.index;
	float tile = g_ChessTileSize[OshimunoChess_Stage() - 1];
	int steps = g_ChessPieceSteps[entity];

	float origin[3];
	GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", origin);

	float targetPos[MAXPLAYERS + 1][3];
	int targetCount = 0;
	int nearest = -1;
	float nearestDist = 0.0;
	for(int client = 1; client <= MaxClients; client++)
	{
		if(!IsClientInGame(client) || !IsPlayerAlive(client))
			continue;

		if(!IsValidEnemy(entity, client))
			continue;

		GetClientAbsOrigin(client, targetPos[targetCount]);
		float dist = GetVectorDistance(origin, targetPos[targetCount], true);
		if(nearest == -1 || dist < nearestDist)
		{
			nearest = targetCount;
			nearestDist = dist;
		}
		targetCount++;
	}
	if(nearest == -1)
		return false;

	g_ChessFleeNow = (g_ChessPieceFlee[entity] && OshimunoChessBossesAlive() > 1);
	if(g_ChessFleeNow && g_ChessPieceFleeRange[entity] > 0.0 && nearestDist > (g_ChessPieceFleeRange[entity] * g_ChessPieceFleeRange[entity]))
		g_ChessFleeNow = false;

	g_ChessAvoidCount = 0;
	if(g_ChessFleeNow && g_ChessPieceSpawnAvoid[entity] > 0.0)
	{
		OshimunoChessCollectSpawns();
		g_ChessAvoidFrom = OshimunoChessSpawnDist(origin);
	}

	float levels[CHESS_PATH_LEVELS];
	int levelCount = 0;
	OshimunoChessAddLevel(levels, levelCount, origin[2]);
	OshimunoChessAddLevel(levels, levelCount, targetPos[nearest][2]);
	for(int i = 0; i < targetCount; i++)
	{
		OshimunoChessAddLevel(levels, levelCount, targetPos[i][2]);
	}

	int bestDir = -1;
	int bestStep = -1;
	float bestScore = 0.0;
	float bestPos[3];
	for(int dir = 0; dir < 4; dir++)
	{
		float yawRad = (g_ChessPieceYaw[entity] + (90.0 * float(dir))) * FLOAT_PI / 180.0;
		float fwdX = Cosine(yawRad);
		float fwdY = Sine(yawRad);
		for(int step = 0; step < steps; step++)
		{
			float seen[CHESS_PATH_LEVELS * 2];
			int seenCount = 0;
			for(int layer = 0; layer < levelCount; layer++)
			{
				for(int probe = 0; probe < 2; probe++)
				{
					float above = (probe ? CHESS_PATH_PROBE_HIGH : CHESS_PATH_PROBE_LOW);
					float vecSpot[3];
					vecSpot[0] = origin[0] + (fwdX * tile * float(step + 1));
					vecSpot[1] = origin[1] + (fwdY * tile * float(step + 1));
					vecSpot[2] = levels[layer] + above;
					float vecGround[3];
					if(!OshimunoChessFloorAt(vecSpot, above + CHESS_PATH_PROBE_DOWN, vecGround))
						continue;

					bool repeat = false;
					for(int i = 0; i < seenCount; i++)
					{
						if(FloatAbs(seen[i] - vecGround[2]) < CHESS_PATH_FLOOR_MERGE)
						{
							repeat = true;
							break;
						}
					}
					if(repeat)
						continue;

					seen[seenCount] = vecGround[2];
					seenCount++;
					if(!OshimunoChessFloorUsable(entity, vecGround))
						continue;

					float score = OshimunoChessScore(entity, vecGround, tile, nearest, targetPos, targetCount);
					if(bestDir == -1 || score > bestScore)
					{
						bestDir = dir;
						bestStep = step;
						bestScore = score;
						bestPos = vecGround;
					}
				}
			}
		}
	}
	if(bestDir == -1)
	{
		g_ChessMoveFails[entity]++;
		return false;
	}

	g_ChessMoveState[entity] = CHESS_MOVE_DASHING;
	g_ChessMoveStart[entity] = origin;
	g_ChessMoveLast[entity] = origin;
	g_ChessMoveDest[entity] = bestPos;
	g_ChessMoveYaw[entity] = g_ChessPieceYaw[entity] + (90.0 * float(bestDir));
	g_ChessMoveTile[entity] = tile;
	g_ChessMoveSteps[entity] = bestStep + 1;
	for(int step = 0; step <= (bestStep + 1); step++)
	{
		g_ChessMoveTileZ[entity][step] = origin[2] + ((bestPos[2] - origin[2]) * (float(step) / float(bestStep + 1)));
	}

	g_ChessSerialCounter++;
	g_ChessMoveSerial[entity] = g_ChessSerialCounter;
	g_ChessMoveFails[entity] = 0;
	g_ChessMoveDraw[entity] = 0.0;
	g_ChessPathFade[entity] = 0.0;

	g_ChessMoveBestDist[entity] = GetVectorDistance(origin, bestPos) + 2.0;
	g_ChessMoveTimeout[entity] = gameTime + CHESS_MOVE_STALL_TIME;

	OshimunoChessSetPhasing(entity, true);
	npc.GetLocomotionInterface().Run();
	return true;
}

static void OshimunoChessFinishMove(CClotBody npc, float gameTime)
{
	int entity = npc.index;
	float pos[3];
	pos = g_ChessMoveDest[entity];
	OshimunoChessRamThink(entity, pos);

	g_ChessMoveState[entity] = CHESS_MOVE_IDLE;
	npc.SetVelocity({0.0, 0.0, 0.0});
	SDKCall_SetLocalOrigin(entity, pos);
	OshimunoChessSetPhasing(entity, false);

	g_ChessMoveNext[entity] = gameTime + g_ChessMoveDelay[OshimunoChess_Stage() - 1];
	g_ChessPathFade[entity] = gameTime + CHESS_PATH_FADE_TIME;
	g_ChessLandFade[entity] = gameTime + CHESS_LAND_FADE_TIME;
	g_ChessLandPos[entity] = pos;
	g_ChessLandTile[entity] = g_ChessMoveTile[entity];
	g_ChessFadeDraw[entity] = 0.0;
}

static int OshimunoChessDashThink(CClotBody npc, float gameTime)
{
	int entity = npc.index;
	float pos[3];
	GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", pos);

	OshimunoChessRamThink(entity, pos);
	g_ChessMoveLast[entity] = pos;
	f_StuckOutOfBoundsCheck[entity] = GetGameTime() + 10.0;

	float vecMove[3];
	SubtractVectors(g_ChessMoveDest[entity], pos, vecMove);
	float remaining = GetVectorLength(vecMove);
	if(remaining < (g_ChessMoveBestDist[entity] - 1.0))
	{
		g_ChessMoveBestDist[entity] = remaining;
		g_ChessMoveTimeout[entity] = gameTime + CHESS_MOVE_STALL_TIME;
	}

	float speed = npc.GetRunSpeed();
	if(speed < 1.0)
		g_ChessMoveTimeout[entity] = gameTime + CHESS_MOVE_STALL_TIME;

	if(remaining <= CHESS_MOVE_ARRIVE_DIST || remaining <= (speed * CHESS_MOVE_ARRIVE_TIME) || g_ChessMoveTimeout[entity] < gameTime)
	{
		OshimunoChessFinishMove(npc, gameTime);
		return CHESS_MOVE_FINISHED;
	}

	NormalizeVector(vecMove, vecMove);
	ScaleVector(vecMove, speed);
	npc.SetVelocity(vecMove);

	float goal[3];
	goal = g_ChessMoveDest[entity];
	goal[2] = pos[2];
	npc.FaceTowards(goal, 15000.0);

	OshimunoChessSetAlpha(entity, OshimunoChessInsideWorld(entity, pos) ? CHESS_MOVE_PHASE_ALPHA : 255);

	if(g_ChessMoveDraw[entity] < gameTime)
	{
		g_ChessMoveDraw[entity] = gameTime + 0.1;
		OshimunoChessDrawPath(entity, 255, 0.15);
	}
	return CHESS_MOVE_DASHING;
}

void OshimunoChess_Stunned(int entity)
{
	if(g_ChessMoveState[entity] != CHESS_MOVE_DASHING)
		return;

	f_StuckOutOfBoundsCheck[entity] = GetGameTime() + 10.0;
	view_as<CClotBody>(entity).SetVelocity({0.0, 0.0, 0.0});
}

void OshimunoChess_Halt(int entity)
{
	if(g_ChessMoveState[entity] != CHESS_MOVE_DASHING)
		return;

	OshimunoChessFinishMove(view_as<CClotBody>(entity), GetGameTime(entity));
}

int OshimunoChess_MoveThink(int entity, float gameTime)
{
	CClotBody npc = view_as<CClotBody>(entity);
	OshimunoChessFadeThink(entity, gameTime);

	int slot = g_ChessPieceSlot[entity];
	if(g_ChessBaseHealth[slot] < 1)
		g_ChessBaseHealth[slot] = ReturnEntityMaxHealth(entity);

	if(g_ChessMoveState[entity] == CHESS_MOVE_DASHING)
		return OshimunoChessDashThink(npc, gameTime);

	if(g_ChessMoveNext[entity] > gameTime)
		return CHESS_MOVE_IDLE;

	if(OshimunoChessStartMove(npc, gameTime))
		return CHESS_MOVE_DASHING;

	g_ChessMoveNext[entity] = gameTime + 0.5;
	if(g_ChessMoveFails[entity] >= CHESS_MOVE_STUCK_FAILS)
	{
		g_ChessMoveFails[entity] = 0;
		float vecOld[3];
		WorldSpaceCenter(entity, vecOld);
		if(TeleportDiversioToRandLocation(entity, true, 2000.0, 500.0) == 1)
		{
			float vecNew[3];
			WorldSpaceCenter(entity, vecNew);
			ParticleEffectAt(vecOld, "teleported_blue", 0.5);
			ParticleEffectAt(vecNew, "teleported_blue", 0.5);
		}
	}
	return CHESS_MOVE_IDLE;
}

static void OshimunoChessStartOrbPhase(int team)
{
	g_ChessOrbPhase = 1;
	g_ChessOrbRingDraw = 0.0;
	RaidModeTime = FAR_FUTURE;

	float center[3];
	center[0] = 0.0;
	center[1] = 0.0;
	center[2] = 0.0;
	float highest = 0.0;
	int count = 0;
	for(int slot; slot < CHESS_SLOT_MAX; slot++)
	{
		if(!g_ChessBossJoined[slot] || !g_ChessBossDead[slot])
			continue;

		center[0] += g_ChessBossDeathPos[slot][0];
		center[1] += g_ChessBossDeathPos[slot][1];
		center[2] += g_ChessBossDeathPos[slot][2];
		if(count == 0 || g_ChessBossDeathPos[slot][2] > highest)
			highest = g_ChessBossDeathPos[slot][2];

		count++;
	}
	if(count < 1)
	{
		OshimunoChessEndFight();
		return;
	}
	center[0] /= float(count);
	center[1] /= float(count);
	center[2] /= float(count);

	float vecStart[3], vecEnd[3];
	vecStart = center;
	vecStart[2] = highest + 20.0;
	vecEnd = center;
	vecEnd[2] = center[2] - 2000.0;
	Handle trace = TR_TraceRayFilterEx(vecStart, vecEnd, MASK_NPCSOLID, RayType_EndPoint, HitOnlyWorld, 0);
	if(TR_DidHit(trace) && !TR_StartSolid(trace))
	{
		TR_GetEndPosition(center, trace);
	}
	delete trace;

	CNavArea area = TheNavMesh.GetNearestNavArea(center, false, 4000.0, false, true);
	if(area != NULL_AREA)
	{
		float vecClose[3];
		area.GetClosestPointOnArea(center, vecClose);
		center = vecClose;
	}
	g_ChessOrbCenter = center;

	int created = 0;
	for(int slot; slot < CHESS_SLOT_MAX; slot++)
	{
		OshimunoChessRemoveMarker(slot);
		if(!g_ChessBossJoined[slot] || !g_ChessBossDead[slot])
			continue;

		float pos[3];
		pos = g_ChessBossDeathPos[slot];
		float ang[3];
		ang[0] = 0.0;
		ang[1] = 0.0;
		ang[2] = 0.0;
		int orb = NPC_CreateByName("npc_oshimuno_fallen_piece", -1, pos, ang, team);
		if(orb > MaxClients)
		{
			if(team != TFTeam_Red)
				NpcAddedToZombiesLeftCurrently(orb, true);

			SetEntProp(orb, Prop_Data, "m_iHealth", g_ChessOrbHealth[slot]);
			SetEntProp(orb, Prop_Data, "m_iMaxHealth", g_ChessOrbHealth[slot]);
			g_ChessOrbRef[slot] = EntIndexToEntRef(orb);
			created++;
		}
	}
	if(created < 1)
	{
		OshimunoChessEndFight();
		return;
	}

	OshimunoChessUpdateRaidTarget();
	CPrintToChatAll("{crimson}The fallen pieces are drawn back together, destroy them before they reach the circle!");
}

static void OshimunoChessBuffBoss(int slot, float multi)
{
	int boss = EntRefToEntIndex(g_ChessBossRef[slot]);
	if(g_ChessBaseHealth[slot] < 1)
		g_ChessBaseHealth[slot] = ReturnEntityMaxHealth(boss);

	float health = float(g_ChessBaseHealth[slot]) * multi;
	if(health > 2000000000.0)
		health = 2000000000.0;

	SetEntProp(boss, Prop_Data, "m_iMaxHealth", RoundToCeil(health));
	SetEntProp(boss, Prop_Data, "m_iHealth", RoundToCeil(health));

	float vecBoss[3];
	WorldSpaceCenter(boss, vecBoss);
	ParticleEffectAt(vecBoss, "teleported_blue", 0.5);
}

static void OshimunoChessBuffSurvivors()
{
	int index = g_ChessDeaths - 1;
	if(index < 0)
		return;

	if(index >= sizeof(g_ChessDeathHealthMulti))
		index = sizeof(g_ChessDeathHealthMulti) - 1;

	for(int slot; slot < CHESS_SLOT_MAX; slot++)
	{
		if(OshimunoChessBossAlive(slot))
			OshimunoChessBuffBoss(slot, g_ChessDeathHealthMulti[index]);
	}
}

void OshimunoChess_BossDied(int entity)
{
	int slot = g_ChessPieceSlot[entity];
	g_ChessMoveState[entity] = CHESS_MOVE_IDLE;
	OshimunoChessSetPhasing(entity, false);
	if(!g_ChessFightActive || BlockLoseSay)
		return;

	if(EntRefToEntIndex(g_ChessBossRef[slot]) != entity || g_ChessBossDead[slot])
		return;

	g_ChessBossDead[slot] = true;
	g_ChessDeaths++;
	GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", g_ChessBossDeathPos[slot]);
	if(g_ChessBaseHealth[slot] < 1)
		g_ChessBaseHealth[slot] = ReturnEntityMaxHealth(entity);

	g_ChessOrbHealth[slot] = g_ChessBaseHealth[slot] / CHESS_ORB_HEALTH_DIVIDE;
	if(g_ChessOrbHealth[slot] < 1)
		g_ChessOrbHealth[slot] = 1;

	float vecMarker[3];
	vecMarker = g_ChessBossDeathPos[slot];
	vecMarker[2] += CHESS_ORB_HEIGHT;
	int marker = ParticleEffectAt(vecMarker, CHESS_ORB_PARTICLE, -1.0);
	if(marker > MaxClients)
		g_ChessOrbMarker[slot] = EntIndexToEntRef(marker);

	if(OshimunoChessBossesAlive() < 1)
	{
		OshimunoChessStartOrbPhase(GetTeam(entity));
		return;
	}

	if(!g_ChessEnraged)
	{
		RaidModeTime += CHESS_RAID_TIME_PER_KILL;
		OshimunoChessBuffSurvivors();
	}
	OshimunoChessUpdateRaidTarget();
}

void OshimunoChess_OrbSetup(int entity)
{
	b_IgnoreAllCollisionNPC[entity] = true;
	b_NoGravity[entity] = true;
	b_DoNotUnStuck[entity] = true;
	f_NoUnstuckVariousReasons[entity] = FAR_FUTURE;
}

bool OshimunoChess_OrbThink(int entity, float center[3])
{
	if(!g_ChessFightActive || g_ChessOrbPhase != 1)
		return false;

	center = g_ChessOrbCenter;
	float pos[3];
	GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", pos);
	float dx = pos[0] - center[0];
	float dy = pos[1] - center[1];
	float dz = pos[2] - center[2];
	if(((dx * dx) + (dy * dy)) > (CHESS_ORB_CIRCLE_RADIUS * CHESS_ORB_CIRCLE_RADIUS) || FloatAbs(dz) > CHESS_ORB_CIRCLE_RADIUS)
		return true;

	g_ChessOrbPhase = 2;
	for(int slot; slot < CHESS_SLOT_MAX; slot++)
	{
		if(!OshimunoChessEntAlive(g_ChessOrbRef[slot]))
			continue;

		float vecOrb[3];
		WorldSpaceCenter(EntRefToEntIndex(g_ChessOrbRef[slot]), vecOrb);
		ParticleEffectAt(vecOrb, "ExplosionCore_MidAir", 1.0);
		RequestFrame(KillNpc, g_ChessOrbRef[slot]);
	}
	EmitSoundToAll(g_ChessOrbExplodeSound, _, _, _, _, 1.0);
	CPrintToChatAll("{crimson}The pieces reached the circle and shattered.");
	OshimunoChessEndFight();
	return false;
}

void OshimunoChess_OrbDied(int entity)
{
	if(!g_ChessFightActive || g_ChessOrbPhase != 1)
		return;

	for(int slot; slot < CHESS_SLOT_MAX; slot++)
	{
		if(EntRefToEntIndex(g_ChessOrbRef[slot]) != entity && OshimunoChessEntAlive(g_ChessOrbRef[slot]))
		{
			OshimunoChessUpdateRaidTarget();
			return;
		}
	}

	g_ChessOrbPhase = 2;
	for(int client = 1; client <= MaxClients; client++)
	{
		if(!IsClientInGame(client) || GetClientTeam(client) != 2)
			continue;

		ApplyStatusEffect(client, client, "Grand Master's Blessing", CHESS_BLESSING_TIME);
	}

	float vecCircle[3];
	vecCircle = g_ChessOrbCenter;
	spawnRing_Vectors(vecCircle, CHESS_ORB_CIRCLE_RADIUS * 2.0, 0.0, 0.0, 6.0, "materials/sprites/laserbeam.vmt", 170, 60, 255, 255, 1, 0.5, 12.0, 0.1, 1, CHESS_ORB_CIRCLE_RADIUS * 8.0);
	vecCircle[2] += 45.0;
	ParticleEffectAt(vecCircle, "ExplosionCore_MidAir", 1.0);
	EmitSoundToAll(g_ChessOrbExplodeSound, _, _, _, _, 1.0);
	EmitSoundToAll(g_ChessBlessingSound, _, _, _, _, 1.0);
	CPrintToChatAll("{purple}♔ Every piece was destroyed, you have been granted the Grand Master's Blessing.");
	OshimunoChessEndFight();
}
