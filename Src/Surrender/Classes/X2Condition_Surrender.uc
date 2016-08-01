// return AA_Success if the squad is out of concealment and (where applicable) if stasis isn't active

class X2Condition_Surrender extends X2Condition;

var bool ForbidStasis;

event name CallMeetsCondition(XComGameState_BaseObject kTarget)
{
	// assume the target is a friendly

	local XComGameStateHistory History;
	local XComGameState_Player PlayerState;
	local XComGameState_Unit Unit, StasisedAlly;
	local Sequence Seq;
	local array<SequenceObject> SeqObjs;
	
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
		Seq.FindSeqObjectsByClass(class'SeqAct_CaptureRemainingXCom', true, SeqObjs);
		if(0 == SeqObjs.length)
		{
			return 'AA_AbilityUnavailabile';
		}
	}
	// todo: test passes for base defense (where surrendering it redundant)
	// and the second-to-last mission of the game (I don't know why), fix them as well


	History = `XCOMHISTORY;

	// cannot surrender if ADVENT doesn't know we're here
	PlayerState = XComGameState_Player(History.GetGameStateForObjectID(Unit.ControllingPlayer.ObjectID));
	if(PlayerState.bSquadIsConcealed)
	{
		return 'AA_UnitHasNotBeenRevealed';
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