$if not set tophour $set tophour 25

Sets
         h       hours
/1*%tophour%/
         b       buildingtype
/
1*10000
/


         hfirst(h)  first period
         hlast(h)   last period;
         hfirst(h)  =  yes$(ord(h) eq 1);
         hlast(h)   =  yes$(ord(h) eq card(h) ) ;

$ontext
file TMP / tmp.txt /
$onecho  > tmp.txt
         i="BuildingData.xlsx"
         r14=Tmax
         o14=Tmax.inc
         r15=Tmin
         o15=Tmin.inc
$offecho
$call =xls2gms @"tmp.txt"
$offtext


Parameter C(b) KWh to T
*/
*$include coolingeff.inc
*/;

Parameter I(b) Energyloss
*/
*$include heatloss.inc
*/;

Parameter P(h) Prices
*/
*$include Prices.inc
*/;



Parameter Xmax(b) Max electricity draw
*/
*$include Elec_max.inc
*/
*;

Parameter TotalAllowedElecDraw(h) Max electricity draw
*/
*$include TotalMaxElec.inc
*/
*;

Scalar   pen              Breach Penalty
*/
*$include pen.inc
*/
*;

Parameter T0(b)  Initial Building Temperatures
*/
*$include T_init.inc
*/
*;

Parameter T_a(h) Ambient Temperature
*/
*$include T_amb.inc
*/;


$ontext
Parameter Tmax(b,h) Max temperature allowed
/
$include Tmax.inc
/
;

Parameter Tmin(b,h) Max temperature allowed
/
$include Tmin.inc
/
;
$offtext
Parameter Tmax(b,h) Max temperature allowed
Parameters Tmin(b,h) Max temperature allowed
$GDXIN ExogData
$LOADIDX T_a P TotalAllowedElecDraw pen
$GDXIN

$GDXIN BuildingData
$LOADIDX C I T0 Xmax
$GDXIN

*$ontext
$GDXIN Tmax
$LOAD Tmax
$GDXIN

$GDXIN Tmin
$LOAD Tmin
$GDXIN
*$offtext

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
         total_consumption(h)    Total Electricity Drawn;

totalcost..                      z =e= sum(h,sum(b, x(h,b)+pen*T_br_under(h,b)+pen*T_br_over(h,b)));
T_start(h,b)$(hfirst(h))..       T0(b) =e= T_act(h,b);
temp_act(h,b)..                  T_act(h,b)=e= T(h,b)+ T_br_over(h,b) - T_br_under(h,b);
temp_max(h,b)..                  T(h,b) =l= Tmax(b,h) ;
temp_min(h,b)..                  T(h,b) =g= Tmin(b,h) ;
temp_calc(h,b)$(not hlast(h))..  T_act(h+1,b) =e= T_act(h,b) - I(b)*C(b)*x(h,b) + I(b)*(T_a(h)- T_act(h,b));
elec_req(h,b)..                  x(h,b)=l=Xmax(b);
total_consumption(h)..           Totalelec(h) =e= sum(b,x(h,b));

Model EconDisp /all/ ;
Solve EconDisp using lp minimizing z ;

Parameter xL(h,b);
xL(h,b)=x.l(h,b);

Parameter T_actL(h,b);
T_actL(h,b)=T_act.l(h,b);

Parameter T_br_overL(h,b);
T_br_overL(h,b)=T_br_over.l(h,b);

Parameter T_br_underL(h,b);
T_br_underL(h,b)=T_br_under.l(h,b);

Parameter TotalelecL(h);
TotalelecL(h)=Totalelec.l(h);

Execute_UnloadIdx 'Solution_noprices' xL T_ActL T_br_overL T_br_underL TotalelecL;

$ontext
*=== First unload to GDX file (occurs during execution phase)
execute_unload "results.gdx" x.L  Totalelec.L T_act.L T_br_over.L T_br_under.L

*=== Now write to variable levels to Excel file from GDX
*=== Since we do not specify a sheet, data is placed in first sheet
execute 'gdxxrw.exe results.gdx o=ElecConsumptionseparate.xlsx var=x.L'
execute 'gdxxrw.exe results.gdx o=TotalConsumption.xlsx var=Totalelec.L'
execute 'gdxxrw.exe results.gdx o=Temperature.xlsx var=T_act.L'
execute 'gdxxrw.exe results.gdx o=TemperatureBreachOver.xlsx var=T_br_over.L'
execute 'gdxxrw.exe results.gdx o=TemperatureBreachUnder.xlsx var=T_br_under.L'
$offtext
