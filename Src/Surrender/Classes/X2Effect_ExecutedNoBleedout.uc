class X2Effect_ExecutedNoBleedout extends X2Effect_Executed;

// todo: get rid of redundant notices (killed, then no longer bleeding out, then killed, again)
simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local XComGameState_Unit TargetUnit;
	local int KillAmount;
	
	super.OnEffectAdded(ApplyEffectParameters, kNewTargetState, NewGameState, NewEffectState);

	// kill unit even if they can bleed out
	TargetUnit = XComGameState_Unit(kNewTargetState);
	KillAmount = TargetUnit.GetCurrentStat(eStat_HP) + TargetUnit.GetCurrentStat(eStat_ShieldHP);

	TargetUnit.TakeEffectDamage(self, KillAmount, 0, 0, ApplyEffectParameters, NewGameState);
}