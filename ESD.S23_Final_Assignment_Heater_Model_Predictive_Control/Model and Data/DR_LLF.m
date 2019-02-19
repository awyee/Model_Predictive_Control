% clear
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


Totalelec_master_LLF=zeros(24,25);
x_master=zeros(10000,25);
T_act_master=zeros(10000,25);
T_br_over_master=zeros(10000,25);
T_br_under_master=zeros(10000,25);


T_act_master(:,1)=T0;
for i=1:24
    disp(i)
    cmdline=['gams AY_Final_AllHours_matlab --tophour=' num2str(26-i) ' lo=3'];
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
    
    Totalelec_master_LLF(i:25,i)=TotalelecL;
    T0=T_act_master(:,i);
    
    hour=i;

    ResDeadline=zeros(10000,1);
    for j=1:10000
        Deadlines=ones(23,1)*25;
        for k=max(24,i+1):24
            Deadlines(k-1)=DetermineDeadline(T0(j),Tmax_master(j,k+1),T_a_forecast(:,hour),I(j),C(j),Xmax(j), hour, k);
        end
        ResDeadline(j)=min(Deadlines);
    end
    
    PowerRemaining=TotalelecL(1);
    dispatch=zeros(10000,1);
    for j=0:25
        Units_on_Deadlinej=zeros(10000,1);
        Units_on_Deadlinej(ResDeadline==j)=1;
        jdispatch=Xmax.*Units_on_Deadlinej;
        if sum(jdispatch)==0
        elseif PowerRemaining>sum(jdispatch)
            dispatch=dispatch+jdispatch;
            PowerRemaining=PowerRemaining-sum(jdispatch);
            if PowerRemaining==0
                break;
            end
        else
            jdispatch=jdispatch*(PowerRemaining/sum(jdispatch));
            dispatch=dispatch+jdispatch;
            break;
        end
    end
    x_master(:,i)=dispatch;
    T_act_master(:,i+1)=T_act_master(:,i).*(ones(10000,1)-I(:))-I(:).*C(:).*dispatch(:)+I(:)*T_a_actual(i);
    T0=T_act_master(:,i+1);
    if i+2<=25
        TotalAllowedElecDraw_master(i+2)=min(TotalelecL(3),TotalAllowedElecDraw_master(i+2));
    end
    toc
end
T_act_master(:,25)=T_actL(2,:)';
T_br_over_master(:,25)=T_br_overL(2,:)';
T_br_under_master(:,25)=T_br_underL(2,:)';

Final_Elec_Consumption_LLF=diag(Totalelec_master_LLF);
T_br_over_LLF=max(zeros(10000,25), T_act_master-Tmax_master);
Avgbreach_LLF=sum(T_br_over_LLF)/10000;
Cost_LLF=sum(x_master).*P_actual';
toc