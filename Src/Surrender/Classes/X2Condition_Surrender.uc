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
	
	Unit = XComGameState_Unit(kTarget);
	if(none == Unit)
	{
		return 'AA_NotAUnit';
	}


	History = `XCOMHISTORY;

	// cannot surrender if ADVENT doesn't know we're here
	PlayerState = XComGameState_Player(History.GetGameStateForObjectID(Unit.ControllingPlayer.ObjectID));
	if(PlayerState.bSquadIsConcealed)
	{
		return 'AA_UnitHasNotBeenRevealed';
	}

	return 'AA_Success';
}