function parrm=perceive_parrm(stim_data,fs,plotit)
% parrm=perceive_parrm(stim_data,fs,plotit)
% This function checks whether PARRM is in the path
% (https://github.com/neuromotion/PARRM) and runs it
% see Dastin-Van Rijn EM et al., Cell Reports, 2021 https://doi.org/10.1016/j.crmeth.2021.100010

%% Defaults
if ~exist('fs','var');fs = 250;end
if ~exist('plotit','var');plotit=1;end
parrm.ns = length(stim_data);

if PeriodicFilter(0,1,0,0)
    disp('')
    disp('--Run PARRM--')
parrm.winSize=2500; % Width of the window in sample space for PARRM filter
parrm.skipSize=20; % Number of samples to ignore in each window in sample space
parrm.winDir='both'; % Filter using samples from the past and future
parrm.guessPeriod=250/120; % Starting point for period grid search

% Find the period of stimulation
disp('--FindPeriodLFP--')
parrm.Period=FindPeriodLFP(stim_data,[1,length(stim_data)-1],parrm.guessPeriod);
parrm.perDist=0.01; % Window in period space for which samples will be averaged
% Create the linear filter
disp('--Calculate Filter--')
parrm.PARRM=PeriodicFilter(parrm.Period,parrm.winSize,parrm.perDist,parrm.skipSize,parrm.winDir);
% Filter using the linear filter and remove edge effects
disp('--Clean data--')
parrm.cleandata=((filter2(parrm.PARRM.',stim_data','same')-stim_data')./(1-filter2(parrm.PARRM.',ones(size(stim_data')),'same'))+stim_data')';


%% plot
if plotit
    t = linspace(0,parrm.ns/fs,parrm.ns);
    [~,f,rpow]=perceive_fft(stim_data(find(~isnan(stim_data))),fs,fs*2);
    [~,f,rnpow]=perceive_fft(parrm.cleandata(find(~isnan(parrm.cleandata))),fs,fs*2);
    
    figure;  
    subplot(2,2,1:2)
    plot(f,log(rpow),f,log(rnpow),'linewidth',2);
  legend({'original','cleaned'},'Location','north'); xlabel('Frequency [Hz]')
    ylabel('Relative spectral power [log(%)]');
    title(['PARRM']);
    
    subplot(2,2,3:4);
    plot(t,stim_data,'color','r');    hold on
    plot(t,parrm.cleandata,'color','k');
    legend({'original','cleaned'},'Location','northwest');
    ylabel('Amplitude');xlabel('Time [s]')
end

else 
    warning('PARRM not in path.')
    parrm.cleandata =nan(size(stim_data));
end