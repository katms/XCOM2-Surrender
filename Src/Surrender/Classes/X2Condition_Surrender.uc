// return AA_Success if the squad is out of concealment

class X2Condition_Surrender extends X2Condition
	config(Surrender);

var config array<name> CannotSurrender;

event name CallMeetsCondition(XComGameState_BaseObject kTarget)
{
	// assume the target is a friendly

	local XComGameStateHistory History;
	local XComGameState_Player PlayerState;
	local XComGameState_Unit Unit;
	local Sequence Seq;
	local array<SequenceObject> SeqObjs;
	local XComGameState_BattleData BattleState;
	local name MissionName, MissionFamily;
	
	Unit = XComGameState_Unit(kTarget);
	if(none == Unit)
	{
		return 'AA_NotAUnit';
	}

	// check the kismet sequence for this mission to see if soldiers are supposed to be captured here
	// this is better than hardcoding all the right story missions
	// todo: figure out where to put this check so that it only gets run once per mission
	Seq = `XWORLDINFO.GetGameSequence();
	if(none != Seq)
	{
		Seq.FindSeqObjectsByClass(class'SeqAct_CaptureRemainingXCom', true, SeqObjs);
		if(0 == SeqObjs.length)
		{
			return 'AA_AbilityUnavailabile';
		}
	}

	History = `XCOMHISTORY;


	// the above kismet sequence test passes for base defense (where surrendering is redundant),
	// and the second-to-last mission of the game (I don't know why)
	// check if it's those missions

	BattleState = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));
	
	if(none != BattleState)
	{
		MissionFamily = name(BattleState.MapData.ActiveMission.MissionFamily);
		MissionName = BattleState.MapData.ActiveMission.MissionName;
		if(INDEX_NONE != CannotSurrender.find(MissionName) || INDEX_NONE != CannotSurrender.find(MissionFamily))
		{
			return 'AA_AbilityUnavailable';
		}
	}
	

	// cannot surrender if ADVENT doesn't know we're here
	PlayerState = XComGameState_Player(History.GetGameStateForObjectID(Unit.ControllingPlayer.ObjectID));
	if(PlayerState.bSquadIsConcealed)
	{
		return 'AA_UnitHasNotBeenRevealed';
	}

	return 'AA_Success';
}