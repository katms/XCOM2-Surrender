// return AA_Success if the squad is out of concealment and (where applicable) if stasis isn't active

class X2Condition_Surrender extends X2Condition;

var bool ForbidStasis;

event name CallMeetsCondition(XComGameState_BaseObject kTarget)
{
	// assume the target is a friendly

	local XComGameStateHistory History;
	local XComGameState_Player PlayerState;
	local XComGameState_Unit Unit, StasisedAlly;
	
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
		return 'AA_AbilityUnavailable';
	}

	// make sure no allies are in stasis
	if(ForbidStasis)
	{
		// check if any units are 1) in stasis, 2) an ally, 3) not mindcontrolled
		// if for some reason a mind-controlled ally is in stasis,
		// allow it because they don't surrender, only get mind control removed
		foreach History.IterateByClassType(class'XComGameState_Unit', StasisedAlly)
		{
			// is calling IsFriendlyUnit on itself a problem
			if(StasisedAlly.IsInStasis() && StasisedAlly.IsFriendlyUnit(Unit) && !StasisedAlly.IsMindControlled())
			{
				return 'AA_UnitIsInStasis';
			}
		}
	}

	return 'AA_Success';
}