#pragma semicolon 1
#pragma newdecls required

void OshimunoBreakBoomboxOnMapStart()
{
	NPCData data;
	strcopy(data.Name, sizeof(data.Name), "DEATH TO MY BOOMBOXES"); // its truly remarkable
	strcopy(data.Plugin, sizeof(data.Plugin), "npc_oshimuno_break_boombox");
	strcopy(data.Icon, sizeof(data.Icon), "victoria_basebreaker");
	data.IconCustom = true;
	data.Flags = 0;
	data.Category = Type_Hidden;
	data.Func = ClotSummon;
	NPC_Add(data);
}

static any ClotSummon(int client, float vecPos[3], float vecAng[3], int team)
{
	return OshimunoBreakBoombox(vecPos, vecAng, team);
}

methodmap OshimunoBreakBoombox < CClotBody
{
	public OshimunoBreakBoombox(float vecPos[3], float vecAng[3], int ally)
	{	
		ally = TFTeam_Stalkers;
		OshimunoBreakBoombox npc = view_as<OshimunoBreakBoombox>(CClotBody(vecPos, vecAng, "models/player/pyro.mdl", "1.0", "999999", ally));

		i_NpcWeight[npc.index] = 1;

		npc.m_iBleedType = BLEEDTYPE_NORMAL;
		npc.m_iStepNoiseType = STEPSOUND_NORMAL;
		npc.m_iNpcStepVariation = STEPTYPE_NORMAL;
		

		func_NPCDeath[npc.index] = ClotDeath;
		func_NPCOnTakeDamage[npc.index] = Generic_OnTakeDamage;
		func_NPCThink[npc.index] = ClotThink;
		
		npc.m_flSpeed = 0.0;
		b_ThisNpcIsImmuneToNuke[npc.index] = true;
		b_DoNotUnStuck[npc.index] = true;
		b_NoKnockbackFromSources[npc.index] = true;
		b_NpcIsInvulnerable[npc.index] = true;
		b_ThisEntityIgnored[npc.index] = true;
		MakeObjectIntangeable(npc.index);
		b_NoHealthbar[npc.index]=true;
		npc.m_bTeamGlowDefault = false;
		npc.m_bNoKillFeed = true;
		npc.m_bDissapearOnDeath = true;
		return npc;
	}
}

static void ClotThink(int iNPC)
{
	OshimunoBreakBoombox npc = view_as<OshimunoBreakBoombox>(iNPC);

	float gameTime = GetGameTime(npc.index);
	if(npc.m_flNextDelayTime > gameTime)
		return;
	
	npc.m_flNextDelayTime = gameTime + DEFAULT_UPDATE_DELAY_FLOAT;
	npc.Update();

	if(npc.m_blPlayHurtAnimation)
	{
		npc.AddGesture("ACT_MP_GESTURE_FLINCH_CHEST", false);
		npc.m_blPlayHurtAnimation = false;
	}
	
	if(npc.m_flNextThinkTime > gameTime)
		return;
	
	npc.m_flNextThinkTime = gameTime + 0.1;
	for(int i; i < i_MaxcountNpcTotal; i++)
	{
		int boombox = EntRefToEntIndexFast(i_ObjectsNpcsTotal[i]); 
		if(IsValidEntity(boombox))
		{
			char npc_classname[60];
			NPC_GetPluginById(i_NpcInternalId[boombox ], npc_classname, sizeof(npc_classname));

			if(boombox != INVALID_ENT_REFERENCE && (StrEqual(npc_classname, "npc_oshimuno_boombox") && IsEntityAlive(boombox))) // look for all boomboxes
			{
				SmiteNpcToDeath(boombox); // low_tier_god.mp3
			}
		}
		else
		{
			SmiteNpcToDeath(npc.index); //mission done
		}
	}
}

static void ClotDeath(int entity)
{
	OshimunoBreakBoombox npc = view_as<OshimunoBreakBoombox>(entity);
	
	if(IsValidEntity(npc.m_iWearable1))
		RemoveEntity(npc.m_iWearable1);
	
}
