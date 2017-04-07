needsPackage "MonodromySolver"
needsPackage "ReactionNetworks"

FF = CC

-- creates a polynomial system from a chemical reaction network
createPolySystem = method()
createPolySystem (ReactionNetwork, InexactFieldFamily):= (Rn, FF) -> (
    S := createRing(Rn, FF);
    createPolySystem(Rn,FF,toList(length Rn.ConcentrationRates : 1_FF))
    )
createPolySystem'overdetermined = (Rn, FF, L) -> (
    S := createRing(Rn, FF);
    CEforms := matrix{conservationEquations(Rn,FF)};
    SubList := toList(apply(0..length Rn.ConcentrationRates-1, i -> 
	    value(Rn.ConcentrationRates#i) => L#i));
    CE := sub(CEforms, SubList) - CEforms;    
    SSE := steadyStateEquations Rn;
    R := CC[Rn.ReactionRates][Rn.ConcentrationRates];	       	   
    M := sub((transpose CE || SSE), R);
    polySystem M
    )
createPolySystem (ReactionNetwork, InexactFieldFamily, List) := (Rn, FF, L) -> (
    squareUp createPolySystem'overdetermined(Rn,FF,L)
    )

-- n copies of oneSiteModificationA
multipleModificationA = n -> (
    A := oneSiteModificationA();
    for i from 2 to n do 
    A = glue(A, sub(oneSiteModificationA(), {"S_0" => "2S_"|(i-1), "S_1" => "S_"|i}));
    A
    )

N = reactionNetwork ({"A+R-->RA", "A+RD-->RDA", "A+RT-->RTA", "E+R-->RE",
	"E+RD-->RDE", "E+RT-->RTE", "R-->RD", "R-->RT", "RA-->A+R", "RD-->R",
	"RDA-->A+RD", "RDE-->E+RD", "RDE-->RE", "RE-->E+R", "RE-->RTE", "RE-->RDE",
	"RT-->R", "RT-->RD", "RTA-->A+RT", "RTA-->RDA", "RTE-->E+RT", "RTE-->RDE", "RTE-->RE"
	})
--R = createRing(N,QQ)


DHFR = reactionNetwork ({"E+H2F <--> EH2F", "E+NH <--> ENH", "EH2F+NH <--> ENHH2F", 
	"ENHH2F <--> ENH+H2F", "ENHH2F <--> ENH4F", "EH4F+N <--> ENH4F", "ENH4F <--> EN+H4F",
	"EN <--> E+N", "EH4F <--> E+H4F", "ENH+H4F <--> ENHH4F", "ENHH4F <--> EH4F+NH",
	"EH2F+N <--> ENH2F", "ENH2F <--> EN+H2F"
	})
--R = createRing(DHFR, QQ)

GC = reactionNetwork ({"G+ATP-->G6P+ADP+H", "G6P<-->F6P", "F6P+ATP<-->FBP+ADP+H", 
	"FBP<-->DHAP", "FEP<-->GAP", "DHAP<-->GAP", "GAP+NAD+P<-->BPG+NADH+H",
	"BPG+ADP<-->TrPG+ATP", "TrPG<-->TwPG", "TwPG<-->PEP+HOH",
	"PEP+ADP+H-->Pyr+ATP", "G+2ADP+2P+2NAD-->2Pyr+2ATP+2NADH+2HOH+2H"}
	) 
R = createRing(GC,QQ)
F = join(subRandomInitVals GC, subRandomReactionRates GC)
I = ideal F
S = QQ[GC.ConcentrationRates]
J = sub(I, S)
dim J
degree J

K4 = reactionNetwork({"3Y+Z --> 2Y+2Z", "3Y+Z --> 4Z", "3Y+Z --> Y+3Z", 
	"2Y+2Z --> Y+3Z", "2Y+2Z --> 4Z", "Y+3Z --> 4Z"})

end
restart
load "example-large-CRN.m2"

setRandomSeed 0
-- system for n copies of oneSiteModificationA
n = 7
An = multipleModificationA n
N
DHFR
GC
H = createPolySystem(DHFR, FF)
(p0, x0) = createSeedPair(H,"initial parameters" => "one")
elapsedTime (V,npaths) = monodromySolve(H,p0,{x0},NumberOfEdges => 5)
length V.PartialSols

L = apply(numgens createRing(DHFR,FF), i->random FF)
specPolys = specializeSystem (p0,createPolySystem'overdetermined(DHFR,FF,L));
R = CC[x_1..x_(numgens ring first specPolys)]
toR = map(R,ring first specPolys,vars R)
elapsedTime NV = numericalIrreducibleDecomposition(ideal (specPolys/toR),Software=>BERTINI)
length components NV

