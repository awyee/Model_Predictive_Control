%clear
tic
h_master=xlsread('ExogData.xlsx', 'Prices', 'A2:A26');
T_a_actual=xlsread('ExogData.xlsx', 'Ambient Temperature', 'B2:B26');
T_a_forecast=xlsread('ExogData.xlsx', 'Ambient Temperature', 'I2:AG26');
P_actual=xlsread('ExogData.xlsx', 'Prices', 'B2:B26');
P_forecast=xlsread('ExogData.xlsx', 'Prices', 'E2:E26');
TotalAllowedElecDraw_master=xlsread('ExogData.xlsx', 'Max_Elec_Draw', 'B2:B26');
pen=xlsread('ExogData.xlsx', 'Penalty', 'A1');
b=xlsread('BuildingData.xlsx', 'Building Characteristics', 'A2:A10001');
C=xlsread('BuildingData.xlsx', 'Cooling Coeff', 'B2:B10001');
I=xlsread('BuildingData.xlsx', 'Heatloss Coeff', 'B2:B10001');
T0=xlsread('BuildingData.xlsx', 'Initial Temperature', 'B2:B10001');
Xmax=xlsread('BuildingData.xlsx', 'Max Elec', 'B2:B10001');

Tmax_master=xlsread('BuildingData.xlsx', 'Tmax', 'B2:Z10001');
Tmax.name='Tmax';
Tmax.type='parameter';
Tmax.form='full';
Tmax.dim=2;

Tmin_master=xlsread('BuildingData.xlsx', 'Tmin', 'B2:Z10001');
Tmin.name='Tmin';
Tmin.type='parameter';
Tmin.form='full';
Tmin.dim=2;


Totalelec_master_MPC=zeros(24,25);
x_master=zeros(10000,25);
T_act_master=zeros(10000,25);
T_br_over_master=zeros(10000,25);
T_br_under_master=zeros(10000,25);
estimatedcost=zeros(24,1);
for i=1:24
cmdline=['gams AY_Final_AllHours_matlab --tophour=' num2str(26-i) ' lo=2'];
%disp(cmdline)

T_a=T_a_forecast(i:25, i);
P=P_forecast(i:25);
TotalAllowedElecDraw=TotalAllowedElecDraw_master(i:25);
Tmax.val=Tmax_master(:, i:25);
%disp (size(Tmax.val))
Tmin.val=Tmin_master(:, i:25);
%disp (size(Tmin.val))

iwgdx('ExogData', 'T_a', 'P', 'TotalAllowedElecDraw', 'pen');
iwgdx('BuildingData','C', 'I', 'T0', 'Xmax');

wgdx('Tmax.gdx', Tmax);
wgdx('Tmin.gdx', Tmin);

system (cmdline);
irgdx 'Solution';

x_master(:,i)=xL(1,:)';
T_act_master(:,i)=T_actL(1,:)';
T_br_over_master(:,i)=T_br_overL(1,:)';
T_br_under_master(:,i)=T_br_underL(1,:)';
Totalelec_master_MPC(i:25,i)=TotalelecL;
T0=T_actL(2,:)';
if i+2<=25
    TotalAllowedElecDraw_master(i+2)=min(TotalelecL(3),TotalAllowedElecDraw_master(i+2));
end
if i==1
    estimatedcost(i)=TotalelecL'*P_forecast(i:25);
else
    estimatedcost(i)=TotalelecL'*P_forecast(i:25)+diag(Totalelec_master_MPC(1:(i-1),1:(i-1)))'*P_actual(1:(i-1));
end
end
T_act_master(:,25)=T_actL(2,:)';
T_br_over_master(:,25)=T_br_overL(2,:)';
T_br_under_master(:,25)=T_br_underL(2,:)';

Final_Elec_Consumption_MPC=diag(Totalelec_master_MPC);
Avgbreach_MPC=sum(T_br_over_master)/10000;
Cost_MPC=sum(x_master).*P_actual';
toc