*$ontext
file TMP / tmp.txt /
$onecho  > tmp.txt
         i="BuildingData.xlsx"
         r11=Indices
         o11=Indices.inc
         r12=coolingcoeff
         o12=coolingeff.inc
         r13=heatloss
         o13=heatloss.inc
         r14=Tmax
         o14=Tmax.inc
         r15=Tmin
         o15=Tmin.inc
         r16=Elec_max
         o16=Elec_max.inc
         r17=T_init
         o17=T_init.inc
$offecho
$call =xls2gms @"tmp.txt"

file TMP2 / tmp.txt /
$onecho  > tmp.txt
         i="ExogData.xlsx"
         r21=Prices
         o21=Prices.inc
         r22=T_amb
         o22=T_amb.inc
         r23=MaxElec
         o23=TotalMaxElec.inc
         r24=Pen
         o24=Pen.inc
         r25=hours
         o25=hours.inc
$offecho
$call =xls2gms @"tmp.txt"
*$offtext
Sets
         h       hours
/
$include hours.inc
/
         b       buildingtype
/
$include Indices.inc
/
         hfirst(h)  first period
         hlast(h)   last period;

         hfirst(h)  =  yes$(ord(h) eq 1);
         hlast(h)   =  yes$(ord(h) eq card(h) ) ;


Parameter C(b) KWh to T
/
$include coolingeff.inc
/;

Parameter I(b) Energyloss
/
$include heatloss.inc
/;

Parameter P(h) Prices
/
$include Prices.inc
/;

Parameter T_a(h) Ambient Temperature
/
$include T_amb.inc
/;

Parameter Xmax(b) Max electricity draw
/
$include Elec_max.inc
/
;

Parameter TotalAllowedElecDraw(h) Max electricity draw
/
$include TotalMaxElec.inc
/
;

Table Tmax(b,h) Max temperature allowed
$include Tmax.inc
;

Table Tmin(b,h) Max temperature allowed
$include Tmin.inc
;

Scalar   pen              Breach Penalty
/
$include pen.inc
/
;

Parameter T0(b)  Initial Building Temperatures
/
$include T_init.inc
/
;

Positive Variable
x(h,b)           Cooling Electricity Consumption
T(h,b)           Constrained Temperature of building
T_br_over(h,b)   Breach temperature overage
T_br_under(h,b)  Breach temperature overage
T_act(h,b)       Actual Temperature of Building
Totalelec(h)     Total Electricity Consumted

Variables
z                Total Cost

Equations
         totalcost               Total Cost Function
         T_start (h,b)           Initial Temperature Settings
         temp_act(h,b)           Caculate Actual Temperature
         temp_max(h,b)           Temperature Constraint
         temp_min(h,b)           Temperature Constraint
         temp_calc(h,b)          Temperature Calculation
         elec_req(h,b)           Individual Electricity Constraints
         total_consumption(h)    Total Electricity Drawn
         elec_draw(h)            Limited Draw;

totalcost..                      z =e= sum(h,sum(b, P(h)*x(h,b)+pen*T_br_under(h,b)+pen*T_br_over(h,b)));
T_start(h,b)$(hfirst(h))..       T0(b) =e= T_act(h,b);
temp_act(h,b)..                  T_act(h,b)=e= T(h,b)+ T_br_over(h,b) - T_br_under(h,b);
temp_max(h,b)..                  T(h,b) =l= Tmax(b,h) ;
temp_min(h,b)..                  T(h,b) =g= Tmin(b,h) ;
temp_calc(h,b)$(not hlast(h))..  T_act(h+1,b) =e= T_act(h,b) - I(b)*C(b)*x(h,b) + I(b)*(T_a(h)- T_act(h,b));
elec_req(h,b)..                  x(h,b)=l=Xmax(b);
total_consumption(h)..           Totalelec(h) =e= sum(b,x(h,b));
elec_draw(h)..                   TotalAllowedElecDraw(h) =g= Totalelec(h);

Model EconDisp /all/ ;
Solve EconDisp using lp minimizing z ;


*=== First unload to GDX file (occurs during execution phase)
execute_unload "results.gdx" x.L  Totalelec.L T_act.L T_br_over.L T_br_under.L

*=== Now write to variable levels to Excel file from GDX
*=== Since we do not specify a sheet, data is placed in first sheet
execute 'gdxxrw.exe results.gdx o=ElecConsumptionseparate.xlsx var=x.L'
execute 'gdxxrw.exe results.gdx o=TotalConsumption.xlsx var=Totalelec.L'
execute 'gdxxrw.exe results.gdx o=Temperature.xlsx var=T_act.L'
execute 'gdxxrw.exe results.gdx o=TemperatureBreachOver.xlsx var=T_br_over.L'
execute 'gdxxrw.exe results.gdx o=TemperatureBreachUnder.xlsx var=T_br_under.L'