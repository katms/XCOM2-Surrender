// rolls once, and applies the same hit/miss result to all targets
class SurrenderAbilityToHitCalc_AllOrNothing extends X2AbilityToHitCalc config(Surrender);

var config int PercentChanceToFail;

function RollForAbilityHit(XComGameState_Ability kAbility, AvailableTarget kTarget, out AbilityResultContext ResultContext)
{
	local int MultiIndex, RandRoll;
	local ArmorMitigationResults NoArmor;

	RandRoll = `SYNC_RAND(100);

	ResultContext.HitResult = RandRoll >= PercentChanceToFail ? eHit_Success : eHit_Miss;
	`log("Surrender result:"@RandRoll@ResultContext.HitResult);

	for (MultiIndex = 0; MultiIndex < kTarget.AdditionalTargets.Length; ++MultiIndex)
	{
		ResultContext.MultiTargetHitResults.AddItem(ResultContext.HitResult);
		ResultContext.MultiTargetArmorMitigation.AddItem(NoArmor);
		ResultContext.MultiTargetStatContestResult.AddItem(0);
	}
}


protected function int GetHitChance(XComGameState_Ability kAbility, AvailableTarget kTarget, optional bool bDebugLog=false)
{
	return 100-PercentChanceToFail;
}