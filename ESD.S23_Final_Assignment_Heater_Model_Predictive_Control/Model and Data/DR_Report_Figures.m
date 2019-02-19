
close all
FigHandle = figure('Position', [100, 100, 1400, 400]);
plot(1:24,zeros(24,1), '--r', 1:24,Avgbreach_MPC(2:25), ':sg',1:24,Avgbreach_LLF(2:25), '-.ob')
legend ('Optimal', 'MPC', 'LLF')
legend('boxon')
xlabel('Hour')
ylabel('Average Temperature Breach (degree C)')
xlim([0 24])
grid on

FigHandle = figure('Position', [100, 100, 1400, 400]);
plot(  1:24,Final_Elec_Consumption_NoDR(1:24), 'k', 1:24,Final_Elec_Consumption_Opt(1:24), '--r',1:24,Final_Elec_Consumption_MPC(1:24), ':sg',1:24,Final_Elec_Consumption_LLF(1:24), '-.ob', 14:20, DR_max(15:21), 'c')
legend ('Base Case:No Demand Response', 'Optimal DR', 'MPC DR', 'LLF DR', 'Demand Response Cap')
legend('boxon')
xlabel('Hour')
ylabel('Consumption (MWh)')
xlim([0 24])
grid on

FigHandle = figure('Position', [100, 100, 700, 400]);
plot(1:24,P_actual(2:25),1:24,P_forecast(2:25))
legend ('Day-Ahead Price', 'Real-Time Price')
legend('boxon')
xlabel('Hour')
ylabel('Price ($)')
xlim([0 24])
grid on

FigHandle = figure('Position', [100, 100, 700, 400]);
plot(1:24,T_a_actual(2:25),1:24,T_a_forecast(2:25,1))
legend ('Hour 1 Temperature Forecast', 'Actual Temperature')
legend('boxon')
xlabel('Hour')
ylabel('Price ($)')
xlim([0 24])
grid on