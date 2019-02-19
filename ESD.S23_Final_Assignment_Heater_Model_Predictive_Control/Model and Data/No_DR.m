%clear
tic
h=xlsread('ExogData.xlsx', 'Prices', 'A2:A26');
T_a=xlsread('ExogData.xlsx', 'Ambient Temperature', 'B2:B26');
P=xlsread('ExogData.xlsx', 'Prices', 'B2:B26');
TotalAllowedElecDraw=xlsread('ExogData.xlsx', 'Max_Elec_Draw', 'B2:B26');
pen=xlsread('ExogData.xlsx', 'Penalty', 'A1');
b=xlsread('BuildingData.xlsx', 'Building Characteristics', 'A2:A10001');
C=xlsread('BuildingData.xlsx', 'Cooling Coeff', 'B2:B10001');
I=xlsread('BuildingData.xlsx', 'Heatloss Coeff', 'B2:B10001');
T0=xlsread('BuildingData.xlsx', 'Initial Temperature', 'B2:B10001');
Xmax=xlsread('BuildingData.xlsx', 'Max Elec', 'B2:B10001');

Tmax.name='Tmax';
Tmax.type='parameter';
Tmax.val=xlsread('BuildingData.xlsx', 'Tmax', 'B2:Z10001');
Tmax.form='full';
Tmax.dim=2;

Tmin.name='Tmin';
Tmin.type='parameter';
Tmin.val=xlsread('BuildingData.xlsx', 'Tmin', 'B2:Z10001');
Tmin.form='full';
Tmin.dim=2;

iwgdx('ExogData', 'h', 'T_a', 'P', 'TotalAllowedElecDraw', 'pen');
iwgdx('BuildingData','b', 'C', 'I', 'T0', 'Xmax');
DR_max=TotalAllowedElecDraw;
wgdx('Tmax.gdx', Tmax);
wgdx('Tmin.gdx', Tmin);

 system 'gams AY_Final_AllHours_matlab_noprices --tophour=25 lo=3';
 irgdx 'Solution_noprices';

Final_Elec_Consumption_NoDR=TotalelecL;
Avgbreach_NoDR=sum(T_br_overL)/10000;
Cost_NoDR=sum(xL').*P_actual';
toc