--!strict
local Training={}
function Training.RequiredXP(level:number,rules:any):number
    local progress = math.clamp(level, 1, rules.MaxLevel) - 1
    return math.floor(rules.XPBase + rules.XPLinear * progress + rules.XPGrowth * progress ^ rules.XPExponent)
end
function Training.Repetition(level: number, tier: number, titan: boolean, rules: any)
    local machine = rules.Machines[tier]
    local progress = math.clamp(level, 1, rules.MaxLevel) - 1
    local scale = 1 + progress * .035 + math.sqrt(progress) * .07
    return {
        Force = Training.Gain(level, titan, rules, machine),
        XP = math.floor(machine.XP * scale + .5),
        PlayerXP = rules.PlayerXPPerRep + math.floor(progress / 7) + tier - 1,
        Interval = rules.RepSeconds - machine.Speed,
    }
end
function Training.Gain(level: number, titan: boolean, rules: any, machine: any?): number
    return (1+math.floor((math.clamp(level,1,rules.MaxLevel)-1)/rules.LevelsPerGain) + (if machine then machine.Force else 0))*(if titan then 2 else 1)
end
function Training.AddXP(profile:any,amount:number,rules:any):(boolean, number)
    if profile.TrainingLevel>=rules.MaxLevel then profile.TrainingXP=0;return false, 0 end
    local granted = math.max(0, math.floor(amount))
    profile.TrainingXP += granted
    local up=false
    while profile.TrainingLevel<rules.MaxLevel and profile.TrainingXP>=Training.RequiredXP(profile.TrainingLevel,rules) do
        profile.TrainingXP-=Training.RequiredXP(profile.TrainingLevel,rules)
        profile.TrainingLevel+=1;up=true
    end
    if profile.TrainingLevel >= rules.MaxLevel then
        granted = math.max(0, granted - profile.TrainingXP)
        profile.TrainingXP = 0
    end
    return up, granted
end
return Training
