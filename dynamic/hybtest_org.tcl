# OpenSees - OpenFresco
#
# ------------------------
# RC column
# 
# Units: N, m, sec
#
# Written: yos
# Date: May, 2012

# ------------------------------
# Start of model generation
# ------------------------------

# Create ModelBuilder (with two-dimensions and 3 DOF/node)
model BasicBuilder -ndm 2 -ndf 3

# Load OpenFresco package
# -----------------------
# (make sure all dlls are in the same folder as openSees.exe)
loadPackage OpenFresco

# Create nodes
# ------------

# Create RC nodes
#    tag        X       Y
node    1      0.0     0.0
node    2      0.0     1.0

set TopID 2

# Define isolator
set K12 2000000.0; #[N/m]

# Define natural period
set Tperiod 2.0; #[sec]

# Define nodal mass
set pi 3.14159265358979
set Msup [expr pow($Tperiod/2./$pi,2.0)*$K12]; # [kg]
puts "Mass = $Msup (kg)"

#        tag    MX      MY      RZ
mass  $TopID  $Msup   0.0    0.0

# Define single point constraints
#    tag   DX   DY   RZ

fix 1   1     1     1
fix 2   0     1     1

# Define materials for nonlinear columns
# ------------------------------------------
set IDMat  1
uniaxialMaterial Elastic $IDMat $K12

# Define experimental control
# ------------------------
#expControl SimUniaxialMaterials 1 $IDMat
# pseudodynamic
#expControl NIDAQmx 1 400. 200. 0.5 1.
# fast
expControl NIDAQmx 1 400. 200. 0.5 -1

# Define experimental setup
# ------------------------
# expSetup OneActuator $tag <-control $ctrlTag> $dir <-ctrlDispFact $f> ...
expSetup OneActuator 1 -control 1 1 -sizeTrialOut 1 1 -trialDispFact 1000.0 -outDispFact 0.001 -outForceFact 1000.

# Define experimental site
# ------------------------
expSite LocalSite 1 1

# Define column elements
# ----------------------
expElement twoNodeLink 1 1 2 -dir 1 -site 1 -initStif $K12 -orient 1 0 0 0 1 0 -iMod
#expElement twoNodeLink 1 1 2 -dir 1 -site 1 -initStif $K12 -orient 1 0 0 0 1 0
#expElement twoNodeLink 1 1 2 -dir 1 -site 1 -initStif $K12

# ------------------------------
# End of model generation
# ------------------------------


# ------------------------------
# Start of analysis generation
# ------------------------------

# Define dynamic loads
# --------------------

# Set time series to be passed to uniform excitation
set deltaT 0.01
set eqN 1
timeSeries Path 1001 -filePath input/eq$eqN.dat -dt $deltaT -factor 0.0016

# Create UniformExcitation load pattern
#                         tag dir 
pattern UniformExcitation  2   1  -accel 1001

# ----------------------------------------------------
# End of additional modelling for dynamic loads
# ----------------------------------------------------

# ------------------------------
# Start of recorder generation
# ------------------------------

# Create a recorder to monitor nodal displacements
recorder Node -file "eq$eqN/dspout2.dat" -time -node 2 -dof 1 disp

# Create a recorder to monitor nodal acceleration
recorder Node -file "eq$eqN/accout2.dat" -timeSeries 1001 -time -node 2 -dof 1 accel

# Create a recorder to monitor element forces
recorder Node -file "eq$eqN/reaction2.dat" -time -node 1 -dof 1 reaction
recorder Element -file "eq$eqN/frcoutex12.dat" -time -ele 1 globalForce
recorder Element -file "eq$eqN/defforce2.dat" -time -ele 1 deformationsANDforces

# --------------------------------
# End of recorder generation
# ---------------------------------


# ---------------------------------------------------------
# Start of modifications to analysis for transient analysis
# ---------------------------------------------------------

# Delete the old analysis and all it's component objects
wipeAnalysis

# Create the system of equation, a banded general storage scheme
system UmfPack
#system BandSPD

# Create the constraint handler, a plain handler as homogeneous boundary
constraints Transformation
#constraints Plain

# Create the solution algorithm, a Newton-Raphson algorithm
algorithm Linear

# Create the DOF numberer, the reverse Cuthill-McKee algorithm
numberer RCM
#numberer Plain

# Create the integration scheme, the Newmark with alpha =0.5 and beta =.25
#integrator NewmarkExplicit 0.5
integrator HHTGeneralizedExplicit 0.0 0.5
#integrator AlphaOS 0.3

# Create the analysis object
analysis Transient

# ---------------------------------------------------------
# End of modifications to analysis for transient analysis
# ---------------------------------------------------------

# ------------------------------
# Finally perform the analysis
# ------------------------------

# set some variables
set tFinal [expr 40.0]

set tCurrent [getTime]
set ok 0

# Perform the transient analysis
set tTot [time {
while {$ok == 0 && $tCurrent < $tFinal} {
    
    set ok [analyze 1 [expr $deltaT/1.0]]
    
    set tCurrent [getTime]
}
}]
puts "Elapsed Time = $tTot \n"

# Print a message to indicate if analysis succesfull or not
if {$ok == 0} {
   puts "Transient analysis completed SUCCESSFULLY";
} else {
   puts "Transient analysis completed FAILED";   }

wipe
