--!strict
return {
    MeterPeriod = 3.8, ChargeTimeout = 30, PerfectThreshold = 0.94,
    ZoneLength = 300, MaxDistance = 1800, MinFlightSeconds = 3.5, MaxFlightSeconds = 7,
    Milestones = {
        {Level = 1, Strength = 0}, {Level = 2, Strength = 25}, {Level = 11, Strength = 180},
        {Level = 20, Strength = 580}, {Level = 33, Strength = 1500}, {Level = 50, Strength = 4000},
    },
    -- Check the rarest tier first. The ordinary encounter uses the remaining probability.
    RarityDenominators = {Incomum = 9, Rara = 80, Epica = 5000, Mitica = 2500000, Lendaria = 10000000000, Secreta = 1000000000000000},
    RegionalArt = {},
    LaunchOrigin = Vector3.new(0, 2, -130), Direction = Vector3.new(0, 0, -1),
    LinePosition = Vector3.new(0, 2, -120), LineWidth = 58, LineDepth = 22,
    WindupSeconds = 0.55,
    CaptureIntroSeconds = 3.1,
}
