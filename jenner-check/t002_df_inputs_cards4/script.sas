/*---------------------------------------------------------------------------
  Adapted from utl-altair-slc-solder-cycles-to-failure-and-strain-energy-
  density-using-blattau-solder-model.sas (lines ~320-354, "2 slc simple
  python" input staging step).

  Original target was workx.df_inputs (libname workx "d:wpswrkx";); only the
  LIBNAME target was changed to WORK so the bundle runs standalone. The
  INFORMAT/INPUT column list and the single CARDS4 data row (a SAC305
  ball-grid-array component + thermal-cycle profile) are the author's own.
---------------------------------------------------------------------------*/

options validvarname=upcase;

data df_inputs;
 informat
   component_size_x 8.
   component_size_y 8.
   solder_height 8.
   pad_diameter 8.
   dnp 8.
   solder_material $6.
   component_cte 8.
   board_cte 8.
   cte_mismatch 8.
   min_temperature 8.
   max_temperature 8.
   delta_temperature 8.
   weibull_beta 8.
  ;
 input
   component_size_x
   component_size_y
   solder_height
   pad_diameter dnp
   solder_material
   component_cte
   board_cte
   cte_mismatch
   min_temperature
   max_temperature
   delta_temperature
   weibull_beta
   ;
cards4;
20 20 0.6 0.8 7.5 SAC305 2.6 16 13.4 -20 40 60 3
;;;;
run;

proc print data=df_inputs noobs;
run;
