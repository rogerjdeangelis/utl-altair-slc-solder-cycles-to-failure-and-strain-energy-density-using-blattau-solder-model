/*---------------------------------------------------------------------------
  Adapted from utl-altair-slc-solder-cycles-to-failure-and-strain-energy-
  density-using-blattau-solder-model.sas (lines ~108-250, "1 slc datastep").

  Original writes both DATA steps into a WORKX libname pointed at a local
  Windows path (libname workx "d:wpswrkx";). Only the LIBNAME target was
  changed (WORK, the default) so the bundle runs standalone; every label,
  variable name, and the full Blattau strain-energy / Coffin-Manson fatigue
  calculation is byte-for-byte the author's.
---------------------------------------------------------------------------*/

options ls=255;

data solder_input;
 format _numeric_ E10.4;
 label
  E1      = 'Young`s modulus of component (e.g., ceramic body) {E1    }'
  E2      = 'Young`s modulus of PCB substrate (FR4)            {E2    }'
  Es      = 'Young`s modulus of solder material                {Es    }'
  Eb      = 'Young`s modulus of board pad (copper)             {Eb    }'
  nu      = 'Poisson`s ratio of PCB material                   {nu    }'
  Gs      = 'Shear modulus of solder joint                     {Gs    }'
  Gc      = 'Shear modulus of copper pad                       {Gc    }'
  a       = 'Pad edge length (half-width for foundation model) {a     }'
  LD      = 'Distance from neutral point to joint center       {LD    }'
  hs      = 'Solder joint height/thickness                     {hs    }'
  hc      = 'Copper pad thickness                              {hc    }'
  w       = 'Pad width                                         {w     }'
  d       = 'Pad length (joint area ; w×d)                     {d     }'
  dalpha  = 'CTE mismatch (component - board)                  {dalpha}'
  dT      = 'Temperature change per cycle                      {dT    }'
  K3      = 'Scaling constant with units (mm/cycle)/MPa^K4     {K3    }'
  K4      = 'Power law exponent (dimensionless)                {K4    }'
  ;

  E1     = 52e3     ;
  E2     = 22e3     ;
  Es     = 22e3     ;
  Eb     = 22e3     ;
  nu     = 0.4      ;
  Gs     = 8500     ;
  Gc     = 8500     ;
  a      = 1.27e-3  ;
  LD     = 1.5e-3   ;
  hs     = 0.036e-3 ;
  hc     = 0.018e-3 ;
  w      = 3.2e-3   ;
  d      = 1.27e-3  ;
  dT     = 22       ;
  K3     = 0.0044   ;
  K4     = 1.3227   ;
  dalpha = 8e-4     ;
  output;
;;;;
run;quit;

options ls=255;
data solder;

 label

  model   = 'BLATTAU SOLDER FATIGUE MODEL                      {model }'
  dW      = 'Delta W (strain energy density)                   {dW    }'
  Nf      = 'Nf (cycles to failure)                            {Nf    }'
  Joint   = 'Corner (LD=1.5mm)                                 {Joint }'

  E1      = 'Young`s modulus of component (e.g., ceramic body) {E1    }'
  E2      = 'Young`s modulus of PCB substrate (FR4)            {E2    }'
  Es      = 'Young`s modulus of solder material                {Es    }'
  Eb      = 'Young`s modulus of board pad (copper)             {Eb    }'
  nu      = 'Poisson`s ratio of PCB material                   {nu    }'
  Gs      = 'Shear modulus of solder joint                     {Gs    }'
  Gc      = 'Shear modulus of copper pad                       {Gc    }'
  a       = 'Pad edge length (half-width for foundation model) {a     }'
  LD      = 'Distance from neutral point to joint center       {LD    }'
  hs      = 'Solder joint height/thickness                     {hs    }'
  hc      = 'Copper pad thickness                              {hc    }'
  w       = 'Pad width                                         {w     }'
  d       = 'Pad length (joint area ; w×d)                     {d     }'
  dalpha  = 'CTE mismatch (component - board)                  {dalpha}'
  dT      = 'Temperature change per cycle                      {dT    }'
  K3      = 'Scaling constant with units (mm/cycle)/MPa^K4     {K3    }'
  K4      = 'Power law exponent (dimensionless)                {K4    }'

  /*--- INTERMEDIATE VARIABLES ---*/

  disp    = 'Total relative displacement = CTE mismatch × ?T × distance to neutral point.                {disp  }'
  As      = 'Solder joint area (w×d) and copper pad area. Used for stress = force/area calculations.     {As    }'
  Ac      = 'Solder joint area (w×d) and copper pad area. Used for stress = force/area calculations.     {Ac    }'
  C1      = 'Component axial stretch compliance (LD/E1A). Ceramic body deforms lengthwise.               {C1    }'
  C2      = 'Board axial stretch compliance (LD/E2A). PCB stretches under component pull.                {C2    }'
  Cs      = 'Solder shear compliance (hs/AsGs). Primary deformation mode in joints.                      {Cs    }'
  Cc      = 'Copper pad shear compliance (hc/AcGc). Pad peels/shears slightly.                           {Cc    }'
  Cb      = 'Board pad bending compliance ((2-nu)/9Eba). FR4 bends locally under pad.                    {Cb    }'
  F       = 'Total cyclic force = disp / total_compliance. Single force produces all deformations.       {F     }'
  dtau    = 'Shear stress range = 2×F/As. Factor of 2 converts peak force to full cycle range.           {dtau  }'
  dgamma  = 'Shear strain range = F × Cs. Solder compliance × force gives deformation.                   {dgamma}'
  dW      = 'Plastic strain energy density  [en.wikipedia](https://en.wikipedia.org/wiki/Solder_fatigue) {dW    }'
  ;

  set solder_input;

  model   = 'BLATTAU SOLDER FATIGUE'       ;
  joint   = 'Corner (LD=%.1fmm)'           ;

  /*--- CALCULATIONS ---*/

  disp   = dalpha * dT * LD                ;
  As     = w * d                           ;
  Ac     = w * d                           ;

  C1 = LD / (E1 * LD * 0.6e-3)             ;
  C2 = LD / (E2 * LD * 1.6e-3)             ;

  Cs     = hs / (As * Gs)                  ;
  Cc     = hc / (Ac * Gc)                  ;
  Cb     = (2 - nu) / (9 * Eb * a)         ;

  F      = disp / (C1 + C2 + Cs + Cc + Cb) ;
  dtau   = F / (As * 2)                    ;
  dgamma = F * Cs                          ;
  dW     = 0.5 * dgamma * dtau             ;
  Nf     = K3 / (dW ** K4)                 ;

run;

proc print data=solder label noobs;
  var model Joint dW Nf;
run;
