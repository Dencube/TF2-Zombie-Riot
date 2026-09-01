#pragma semicolon 1
#pragma newdecls required

static const char g_DeathSounds[][] = 
{
	"vo/pyro_paincrticialdeath01.mp3",
	"vo/pyro_paincrticialdeath02.mp3",
	"vo/pyro_paincrticialdeath03.mp3",
};

static const char g_HurtSounds[][] = 
{
	"vo/pyro_painsharp01.mp3",
	"vo/pyro_painsharp02.mp3",
	"vo/pyro_painsharp03.mp3",
	"vo/pyro_painsharp04.mp3",
	"vo/pyro_painsharp05.mp3",
};

static const char g_IdleAlertedSounds[][] = 
{
	"vo/taunts/pyro_taunts01.mp3",
	"vo/taunts/pyro_taunts02.mp3",
	"vo/taunts/pyro_taunts03.mp3",
};


static char g_MeleeHitSounds[][] = 
{
	"weapons/samurai/tf_katana_slice_01.wav",
	"weapons/samurai/tf_katana_slice_02.wav",
	"weapons/samurai/tf_katana_slice_03.wav",
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

static int CONE_COLOR[3] = { 0, 255, 255 };
static bool g_ConeFillOk = false;
static int g_ConeLaser = -1;

#define CONE_FILL_MAT "laststand/fill_cone.vmt"
#define CONE_RADIUS 250.0
#define CONE_MELEE_ARC 90.0			// punch hit radius
#define CONE_HALFANGLE 30.0	    	// angle based on relative north, 22.5 = a 45 degree cone
#define CONE_LIFESPAN 0.3	    	// how long the cone lasts before disappearing
#define CONE_OUTLINE_ALPHA 200
#define CONE_FILL_ALPHA 90			// 0 disables the pie sheet entirely
#define CONE_ANIM_MIN_RATE 1.0
#define CONE_ANIM_STILL_SPEED 40.0  // HU/S under which the floor applies
#define CONE_FILL_FWD 0.7071
#define CONE_FILL_LEFT 0.0

void OshimunoTricksterOnMapStart()
{
	PrecacheSoundArray(g_DeathSounds);
	PrecacheSoundArray(g_HurtSounds);
	PrecacheSoundArray(g_IdleAlertedSounds);
	PrecacheSoundArray(g_MeleeHitSounds);
	PrecacheSoundArray(g_MeleeAttackSounds);
	PrecacheSound("weapons/flame_thrower_airblast.wav");
	g_ConeLaser = PrecacheModel("sprites/laserbeam.vmt");
	NPCData data;
	strcopy(data.Name, sizeof(data.Name), "Street Trickster");
	strcopy(data.Plugin, sizeof(data.Plugin), "npc_oshimuno_trickster");
	strcopy(data.Icon, sizeof(data.Icon), "pyro_freeze_1");
	data.IconCustom = true;
	data.Flags = 0;
	data.Category = Type_Oshimuno;
	data.Func = ClotSummon;
	NPC_Add(data);
}

static any ClotSummon(int client, float vecPos[3], float vecAng[3], int team)
{
	return OshimunoTrickster(vecPos, vecAng, team);
}

methodmap OshimunoTrickster < CClotBody
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
	public OshimunoTrickster(float vecPos[3], float vecAng[3], int ally)
	{
		OshimunoTrickster npc = view_as<OshimunoTrickster>(CClotBody(vecPos, vecAng, "models/player/pyro.mdl", "1.0", "1000", ally));

		i_NpcWeight[npc.index] = 1;
		npc.SetActivity("ACT_MP_RUN_MELEE");
		KillFeed_SetKillIcon(npc.index, "lava_axe");
		
		npc.m_iBleedType = BLEEDTYPE_NORMAL;
		npc.m_iStepNoiseType = STEPSOUND_NORMAL;
		npc.m_iNpcStepVariation = STEPTYPE_NORMAL;
		

		func_NPCDeath[npc.index] = ClotDeath;
		func_NPCOnTakeDamage[npc.index] = Generic_OnTakeDamage;
		func_NPCThink[npc.index] = ClotThink;
		
		npc.m_flSpeed = 300.0;
		npc.m_iOverlordComboAttack = 1;

		npc.m_iWearable1 = npc.EquipItem("head", "models/workshop/weapons/c_models/c_rift_fire_axe/c_rift_fire_axe.mdl");

		npc.m_iWearable2 = npc.EquipItem("head", "models/workshop/player/items/all_class/dec17_balloonihoodie/dec17_balloonihoodie_pyro.mdl");

		npc.m_iWearable3 = npc.EquipItem("head", "models/workshop/player/items/pyro/hwn2022_magical_mount/hwn2022_magical_mount.mdl");
		SetEntProp(npc.m_iWearable3, Prop_Send, "m_nSkin", 1);

		SetEntProp(npc.index, Prop_Send, "m_nSkin", 1);
		SetVariantInt(2);
		AcceptEntityInput(npc.index, "SetBodyGroup");

		npc.StartPathing();
		return npc;
	}
}

static void ClotThink(int iNPC)
{
	OshimunoTrickster npc = view_as<OshimunoTrickster>(iNPC);

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
		OshimunoTricksterSelfDefense(npc, distance, vecTarget, VecSelfNpc, gameTime);
	}
	if(npc.m_flDoingAnimation < gameTime && npc.m_iOverlordComboAttack == 0)
	{
		if(IsValidEntity(npc.m_iWearable1))
			RemoveEntity(npc.m_iWearable1);
		npc.m_iWearable1 = npc.EquipItem("head", "models/workshop/weapons/c_models/c_rift_fire_axe/c_rift_fire_axe.mdl");
		npc.StartPathing();
		npc.m_bisWalking = true;
		npc.SetActivity("ACT_MP_RUN_MELEE");
		npc.m_flDoingAnimation = gameTime + FAR_FUTURE; //so this doesnt trigger again
	}
	npc.PlayIdleSound();
}

void OshimunoTricksterSelfDefense(OshimunoTrickster npc, float distance, float vecTarget[3], float VecSelfNpc[3], float gameTime)
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
					float damage = 80.0;
					
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
	if(distance < (NORMAL_ENEMY_MELEE_RANGE_FLOAT_SQUARED) * 2.0 && npc.m_iOverlordComboAttack == 1) // cone attack
	{
		int target = Can_I_See_Enemy(npc.index, npc.m_iTarget);
		if(IsValidEnemy(npc.index, target, false, true))
		{
			npc.m_iTarget = target;
			if(IsValidEntity(npc.m_iWearable1))
				RemoveEntity(npc.m_iWearable1);
			npc.m_iWearable1 = npc.EquipItem("head", "models/workshop/weapons/c_models/c_degreaser/c_degreaser.mdl");
			EmitSoundToAll("weapons/flame_thrower_airblast.wav", npc.index);
			npc.SetActivity("ACT_MP_RUN_PRIMARY");
			npc.StopPathing();
			npc.m_bisWalking = false;
			npc.m_iOverlordComboAttack--;
			npc.m_flNextMeleeAttack = gameTime + 1.25;
			npc.m_flDoingAnimation = gameTime + 0.75;
			
			

			float damage = 120.0;
			NPC_Ignite(target, npc.index, 8.0, -1, 2.0);
			SDKHooks_TakeDamage(target, npc.index, npc.index, damage, DMG_CLUB);

			float yawDeg;
			{
				float at[3];
				WorldSpaceCenter(target, at);
				float dx = at[0] - VecSelfNpc[0];
				float dy = at[1] - VecSelfNpc[1];
				if((dx * dx) + (dy * dy) >= 1.0)
				{
					yawDeg = ArcTangent2(dy, dx) * 180.0 / FLOAT_PI;
				}
				else
				{
					float ang[3];
					GetEntPropVector(npc.index, Prop_Data, "m_angRotation", ang);
					yawDeg = ang[1];
				}
			}
			float yawRad = yawDeg * FLOAT_PI / 180.0;
			float arcRad = CONE_MELEE_ARC * FLOAT_PI / 180.0;
			bool hit[MAXPLAYERS + 1];
			for(int client = 1; client <= MaxClients; client++)
			{
				if(!IsClientInGame(client) || !IsPlayerAlive(client) || GetClientTeam(client) != TFTeam_Red)
					continue;

				float pos[3];
				GetClientAbsOrigin(client, pos);
				float dx = pos[0] - VecSelfNpc[0];
				float dy = pos[1] - VecSelfNpc[1];
				float dz = pos[2] - VecSelfNpc[2];
				if(((dx * dx) + (dy * dy)) > (NORMAL_ENEMY_MELEE_RANGE_FLOAT_SQUARED) || dz > 120.0 || dz < -120.0)
					continue;

				if(CONE_MELEE_ARC < 180.0)
				{
					float diff = ArcTangent2(dy, dx) - yawRad;
					while(diff > FLOAT_PI) diff -= FLOAT_PI * 2.0;
					while(diff < -FLOAT_PI) diff += FLOAT_PI * 2.0;
					if(FloatAbs(diff) > arcRad)
						continue;
				}
				hit[client] = true;
			}
			OshimunoTricksterResolveCone(npc, VecSelfNpc, yawDeg, hit);
			OshimunoTricksterDrawCone(VecSelfNpc, yawDeg);
		}
	}
}

static void OshimunoTricksterResolveCone(OshimunoTrickster npc, const float apex[3], float yawDeg, const bool exclude[MAXPLAYERS + 1])
{
	float yawRad = yawDeg * FLOAT_PI / 180.0;
	float halfAngle = (CONE_HALFANGLE + 6.0) * FLOAT_PI / 180.0;
	float radiusPad = CONE_RADIUS + 24.0;

	for(int client = 1; client <= MaxClients; client++)
	{
		if(exclude[client] || !IsClientInGame(client) || !IsPlayerAlive(client) || GetClientTeam(client) != TFTeam_Red)
			continue;

		float pos[3];
		GetClientAbsOrigin(client, pos);
		float dx = pos[0] - apex[0];
		float dy = pos[1] - apex[1];
		float dz = pos[2] - apex[2];
		if(((dx * dx) + (dy * dy)) > (radiusPad * radiusPad) || dz > 120.0 || dz < -120.0)
			continue;

		float diff = ArcTangent2(dy, dx) - yawRad;
		while(diff > FLOAT_PI) diff -= FLOAT_PI * 2.0;
		while(diff < -FLOAT_PI) diff += FLOAT_PI * 2.0;
		if(FloatAbs(diff) > halfAngle)
			continue;

		float at[3];
		WorldSpaceCenter(client, at);

		float damage = 120.0;
		NPC_Ignite(client, npc.index, 8.0, -1, 2.0);
		SDKHooks_TakeDamage(client, npc.index, npc.index, damage, DMG_CLUB);
	}
}

static void OshimunoTricksterDrawCone(const float apex[3], float yawDeg)
{
	int color[4];
	color[0] = CONE_COLOR[0];
	color[1] = CONE_COLOR[1];
	color[2] = CONE_COLOR[2];
	color[3] = CONE_OUTLINE_ALPHA;

	float from[3];
	from = apex;
	from[2] += 5.0;

	float halfAngle = CONE_HALFANGLE * FLOAT_PI / 180.0;
	float yawRad = yawDeg * FLOAT_PI / 180.0;
	float prev[3];
	for(int step; step <= 6; step++)
	{
		float ang = yawRad - halfAngle + ((halfAngle * 2.0) * (float(step) / 6.0));
		float at[3];
		at[0] = from[0] + (Cosine(ang) * CONE_RADIUS);
		at[1] = from[1] + (Sine(ang) * CONE_RADIUS);
		at[2] = from[2];

		if(step == 0 || step == 6)
		{
			TE_SetupBeamPoints(from, at, g_ConeLaser, -1, 0, 0, CONE_LIFESPAN, 4.0, 4.0, 0, 0.0, color, 0);
			TE_SendToAll();
		}
		if(step)
		{
			TE_SetupBeamPoints(prev, at, g_ConeLaser, -1, 0, 0, CONE_LIFESPAN, 4.0, 4.0, 0, 0.0, color, 0);
			TE_SendToAll();
		}
		prev = at;
	}
	if(CONE_FILL_ALPHA <= 0 || !g_ConeFillOk)
		return;

	int spr = CreateEntityByName("env_sprite_oriented");
	if(spr <= MaxClients || !IsValidEntity(spr))
		return;

	char buffer[48];
	DispatchKeyValue(spr, "model", CONE_FILL_MAT);
	FormatEx(buffer, sizeof(buffer), "%.3f", (CONE_RADIUS * 0.5) / 32.0);
	DispatchKeyValue(spr, "scale", buffer);
	DispatchKeyValue(spr, "rendermode", "1");	
	FormatEx(buffer, sizeof(buffer), "%d %d %d", CONE_COLOR[0], CONE_COLOR[1], CONE_COLOR[2]);
	DispatchKeyValue(spr, "rendercolor", buffer);
	IntToString(CONE_FILL_ALPHA, buffer, sizeof(buffer));
	DispatchKeyValue(spr, "renderamt", buffer);
	DispatchKeyValue(spr, "spawnflags", "1");	
	float ang[3];
	ang[0] = 90.0;
	ang[1] = yawDeg + 45.0;
	FormatEx(buffer, sizeof(buffer), "%.0f %.0f 0", ang[0], ang[1]);
	DispatchKeyValue(spr, "angles", buffer);
	DispatchSpawn(spr);
	float fwdRad = yawDeg * FLOAT_PI / 180.0;
	float leftRad = (yawDeg + 90.0) * FLOAT_PI / 180.0;
	float at[3];
	at[0] = apex[0] + (Cosine(fwdRad) * CONE_RADIUS * CONE_FILL_FWD)
		+ (Cosine(leftRad) * CONE_RADIUS * CONE_FILL_LEFT);
	at[1] = apex[1] + (Sine(fwdRad) * CONE_RADIUS * CONE_FILL_FWD)
		+ (Sine(leftRad) * CONE_RADIUS * CONE_FILL_LEFT);
	at[2] = apex[2] + 4.0;
	TeleportEntity(spr, at, ang, NULL_VECTOR);
	SetEdictFlags(spr, (GetEdictFlags(spr) & ~(FL_EDICT_DONTSEND | FL_EDICT_PVSCHECK)) | FL_EDICT_ALWAYS);

	CreateTimer(CONE_LIFESPAN, Timer_ConeKillFill, EntIndexToEntRef(spr));
}

public Action Timer_ConeKillFill(Handle timer, any ref)
{
	int spr = EntRefToEntIndex(view_as<int>(ref));
	if(spr > MaxClients && IsValidEntity(spr))
		RemoveEntity(spr);
	return Plugin_Stop;
}

stock void ConeKeepAnimSpeed(int iNPC)
{
	if(CONE_ANIM_MIN_RATE <= 0.0)
		return;

	OshimunoTrickster npc = view_as<OshimunoTrickster>(iNPC);
	if(npc.GetGroundSpeed() >= CONE_ANIM_STILL_SPEED)
		return;

	if(npc.GetPlaybackRate() < CONE_ANIM_MIN_RATE)
		npc.SetPlaybackRate(CONE_ANIM_MIN_RATE, true);	
}

static void ClotDeath(int entity)
{
	OshimunoTrickster npc = view_as<OshimunoTrickster>(entity);

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
