--!strict
return {
    RepSeconds = 1.8, QTEEvery = 3, QTESeconds = 2, PlayerXPPerRep = 3,
    Machines = {
        {Name = "Barra de treino", Cost = 0, Level = 1, Force = 0, XP = 8, Speed = 0},
        {Name = "Barra reforçada", Cost = 120, Level = 2, Force = 1, XP = 11, Speed = .05},
        {Name = "Estação turbo", Cost = 550, Level = 4, Force = 3, XP = 15, Speed = .1},
        {Name = "Estação cristal", Cost = 2500, Level = 8, Force = 5, XP = 21, Speed = .16},
        {Name = "Estação cósmica", Cost = 11000, Level = 14, Force = 8, XP = 29, Speed = .22},
        {Name = "Barra vulcânica", Cost = 55000, Level = 23, Force = 12, XP = 42, Speed = .29},
        {Name = "Estação do eclipse", Cost = 220000, Level = 36, Force = 17, XP = 58, Speed = .36},
        {Name = "Estação estelar", Cost = 950000, Level = 52, Force = 23, XP = 80, Speed = .43},
    },
    XPBase = 24, XPLinear = 12, XPGrowth = 3, XPExponent = 1.95,
    MaxLevel = 100, LevelsPerGain = 2, MaxStrength = 10000, RequestCooldown = .5,
}
