# OpenSees - OpenFresco
#
# ------------------------
# RC column
# 
# Units: N, m, sec
#
# Written: yos
# Date: May, 2012

wipe

# ------------------------------
# Start of model generation
# ------------------------------

# Create ModelBuilder (with two-dimensions and 3 DOF/node)
model BasicBuilder -ndm 2 -ndf 3

# Load OpenFresco package
# -----------------------
# (make sure all dlls are in the same folder as openSees.exe)
#loadPackage OpenFresco

# Create nodes
# ------------

# Create RC nodes
#    tag        X       Y
node    1      0.0     0.0
node    2      0.0     1.0

set TopID 2

# Define isolator
set K12 250000.0; #[N/m]

# Define natural period
set Tperiod 0.5; #[sec]

# Define nodal mass
set pi 3.14159265358979
set Msup [expr pow($Tperiod/2./$pi,2.0)*227700]; # [kg]
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
#uniaxialMaterial Elastic $IDMat $K12 
#uniaxialMaterial Steel02 $IDMat 3350 $K12 0.10 20 0.925 0.15
#uniaxialMaterial Hysteretic $IDMat 1200.0 10.0 1200.0 20.0 -1200.0 -10.0 -1200.0 -20.0 1.0 1.0 0.0 0.0
uniaxialMaterial MultiLinear $IDMat 10 10000 20 15000 50 20000 


# Define column elements
# ----------------------
element twoNodeLink 1 1 2 -mat $IDMat -dir 1 -orient 1 0 0 0 1 0

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
#timeSeries Path 1001 -filePath input/eq$eqN.dat -dt $deltaT -factor 0.0016
timeSeries Path 1001 -filePath input/eq$eqN.dat -dt $deltaT -factor 1


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
recorder Node -file "sim/dspout.dat" -time -node 2 -dof 1 disp

# Create a recorder to monitor nodal acceleration
recorder Node -file "sim/accout.dat" -timeSeries 1001 -time -node 2 -dof 1 accel



# Create a recorder to monitor element forces
recorder Node -file "sim/reaction.dat" -time -node 1 -dof 1 reaction
recorder Node -file "sim/reaction_y.dat" -time -node 2 -dof 1 reaction
recorder Element -file "sim/frcoutex1.dat" -time -ele 1 globalForce
recorder Element -file "sim/defforce.dat" -time -ele 1 deformationsANDforces

#recorder display "Displaced shape" 10 10 1000 500 -wipe
#prp 200. 50. 1;
#vup  0  1 0;
#vpn  0  0 1;
#display 1 5 5

# --------------------------------
# End of recorder generation
# ---------------------------------


# ---------------------------------------------------------
# Start of modifications to analysis for transient analysis
# ---------------------------------------------------------

# Delete the old analysis and all it's component objects
#wipeAnalysis

# Create the system of equation, a banded general storage scheme
#system UmfPack
system BandSPD

# Create the constraint handler, a plain handler as homogeneous boundary
#constraints Transformation
constraints Plain

# Create the solution algorithm, a Newton-Raphson algorithm
algorithm Linear

# Create the DOF numberer, the reverse Cuthill-McKee algorithm
#numberer RCM
numberer Plain

# Create the integration scheme, the Newmark with alpha =0.5 and beta =.25
integrator NewmarkExplicit 0.5
#integrator HHTGeneralizedExplicit 0.0 0.5
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
while {$ok == 0 && $tCurrent < $tFinal} {
    
    set ok [analyze 1 [expr $deltaT/1.0]]
    
    set tCurrent [getTime]
}

# Print a message to indicate if analysis succesfull or not
if {$ok == 0} {
   puts "Transient analysis completed SUCCESSFULLY";
} else {
   puts "Transient analysis completed FAILED";   }

wipe
