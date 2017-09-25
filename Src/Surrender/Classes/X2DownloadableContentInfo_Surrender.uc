//---------------------------------------------------------------------------------------
//  FILE:   XComDownloadableContentInfo_Surrender.uc                                    
//           
//	Use the X2DownloadableContentInfo class to specify unique mod behavior when the 
//  player creates a new campaign or loads a saved game.
//  
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2DownloadableContentInfo_Surrender extends X2DownloadableContentInfo;

/// <summary>
/// Called after the Templates have been created (but before they are validated) while this DLC / Mod is installed.
/// </summary>
static event OnPostTemplatesCreated()
{
	local X2CharacterTemplateManager CharMgr;
	local X2CharacterTemplate CharTemplate;
	local array<X2DataTemplate> Templates;
	local X2DataTemplate Template;

	CharMgr = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager();
	CharMgr.FindDataTemplateAllDifficulties('Soldier', Templates);

	foreach Templates(Template)
	{
		CharTemplate = X2CharacterTemplate(Template);
		if(none != CharTemplate)
		{
			CharTemplate.Abilities.AddItem(class'X2Ability_Surrender'.default.SurrenderName);
		}
	}

}

// this hook is called after the game loads all the things we need to check
static function FinalizeUnitAbilitiesForInit(XComGameState_Unit UnitState, out array<AbilitySetupData> SetupData, optional XComGameState StartState, optional XComGameState_Player PlayerState, optional bool bMultiplayerDisplay)
{
	local int i;
	i = SetupData.find('TemplateName', class'X2Ability_Surrender'.default.SurrenderName);
	if(INDEX_NONE != i && (!CaptureInEffect() || SpecialCase()))
	{
		SetupData.Remove(i,1);
	}
}

static function bool CaptureInEffect()
{
	local Sequence Seq;
	local array<SequenceObject> SeqObjs;

	// check the kismet sequence for this mission to see if soldiers are supposed to be captured here
	// this is better than hardcoding all the right story missions
	Seq = `XWORLDINFO.GetGameSequence();
	if(none != Seq)
	{
		Seq.FindSeqObjectsByClass(class'SeqAct_CaptureRemainingXCom', true, SeqObjs);
		return SeqObjs.length > 0;
	}
	return false;
}

// some mission types allow soldiers to be captured but we don't want the ability available anyway
static function bool SpecialCase()
{
	local XComGameState_BattleData BattleState;
	local name MissionName, MissionFamily;

	BattleState = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));

	if(none != BattleState)
	{
		MissionFamily = name(BattleState.MapData.ActiveMission.MissionFamily);
		MissionName = BattleState.MapData.ActiveMission.MissionName;
		if(INDEX_NONE != class'X2Condition_Surrender'.default.CannotSurrender.find(MissionName)
		|| INDEX_NONE != class'X2Condition_Surrender'.default.CannotSurrender.find(MissionFamily))
		{
			return true;
		}
	}
	return false;
}
