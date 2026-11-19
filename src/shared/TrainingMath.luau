--!strict
local Training={}
function Training.RequiredXP(level:number,rules:any):number
    return math.floor(rules.XPBase*math.clamp(level,1,rules.MaxLevel)^rules.XPExponent)
end
function Training.Gain(level:number,titan:boolean,rules:any):number
    return (1+math.floor((math.clamp(level,1,rules.MaxLevel)-1)/rules.LevelsPerGain))*(if titan then 2 else 1)
end
function Training.AddXP(profile:any,amount:number,rules:any):boolean
    if profile.TrainingLevel>=rules.MaxLevel then profile.TrainingXP=0;return false end
    profile.TrainingXP+=math.max(0,math.floor(amount))
    local up=false
    while profile.TrainingLevel<rules.MaxLevel and profile.TrainingXP>=Training.RequiredXP(profile.TrainingLevel,rules) do
        profile.TrainingXP-=Training.RequiredXP(profile.TrainingLevel,rules)
        profile.TrainingLevel+=1;up=true
    end
    if profile.TrainingLevel>=rules.MaxLevel then profile.TrainingXP=0 end
    return up
end
return Training
