function ecg=perceive_ecg(data,fs,plotit)
% ecg = perceive_ecg(data,fs,plotit)
% data = raw signal (required)
% fs = sampling rate (default = 250)
% plotit = create plots (default = 1)
%% Defaults
if ~exist('fs','var');fs = 250;end
if ~exist('plotit','var');plotit=1;end
ns = length(data);
%% First pass using cross-correlation
dwindow=round(fs); % segment window size (500 ms)
dmove = fs; % moving window size (100 ms)
i=[1+dwindow:dmove:ns-dwindow-1]'; % segment indices
for a = 1:length(i)
    x(a,:) = data([i(a)-dwindow:i(a)+dwindow]); % epoch data
end
disp(['...running cross-correlation on ' num2str(a) ' segments...'])

ndata = zeros(1,4*dwindow); % template for adjust to xcorr lags (4*segment window size)
nt=linspace(-2*dwindow/fs,size(ndata,2)/fs-2*dwindow/fs,size(ndata,2)); % time axis
ndata(1,perceive_sc(nt,0):perceive_sc(nt,0)+size(x,2)-1)=x(1,:); % initialize with first segment
n=0; % run through remaining segments and find xcorr lags, align data
for a = 2:size(x,1)
    [r,l]=xcorr(nanmean(ndata,1),x(a,:),fs);[~,mi]=max(r);tlag = l(mi);
    if tlag >0;n=n+1;ndata(n,tlag:tlag+size(x,2)-1)=x(a,:);end
end
mdata = nanmean(ndata); % average aligned data
%% find ECG peak characteristics in xcorr aligned data
[absm,imax]=findpeaks(abs(mdata),'SortStr','descend','NPeaks',15); np=0.05;iim=[];iin=[];
while isempty(iim) || isempty(iin)
    np=np+.025;pkrange=imax(1)-round(fs*np):imax(1)+round(fs*np);
    [~,iim,wm]=findpeaks(mdata(pkrange),'SortStr','descend','NPeaks',1);
    [~,iin,wn]=findpeaks(-mdata(pkrange),'SortStr','descend','NPeaks',1);
end
iim=iim+pkrange(1)-1;iin=iin+pkrange(1)-1;pdif=absm(1)./nansum(absm(2:end))*100;
if iin(1)<iim(1)
    ii1 = iin(1);ii2 = iim(1);w1=wn(1);w2 = wm(1);
else
    ii1=iim(1);ii2=iin(1);w1=wm(1);w2=wn(1);
end
ecg_cut=ii1-round(w1(1)):ii2+round(w2(1));
ecg.proc.template1 = mdata(ecg_cut); % first template
disp('...ecg template 1 generated...')
%% Run temporal correlation across samples
corrdata=[];
for a = 1:ns-size(ecg_cut,2)-1
    corrdata(:,a) = data(1,a:a+size(ecg_cut,2)-1)';
end
r = corr(corrdata,ecg.proc.template1').^2; 
ecg.proc.r = r;
disp('...first temporal correlation done...')
%% adjust r threshold to maximize HR associated peak identification
h=max(findpeaks(r))-.05:-0.01:0.01;
thr=[];
for a=1:length(h)
    [~,ix]=findpeaks(r,'MinPeakHeight',h(a),'MaxPeakWidth',round(0.1*fs));
    if ~isempty(ix);dd=60./(diff(ix)/fs);thr(a)=nansum(dd>55&dd<120)./std(dd);end
end
[~,ithr]=max(thr);ecg.proc.thresh=h(ithr);
disp('...first threshold adjusted...')
%% find peaks from temporal correlations
[~,i]=findpeaks(r,'MinPeakHeight',ecg.proc.thresh,'MinPeakDistance',round(fs/2));
%% start over using the found peaks by aligning to the found peaks
for a = 1:length(i)
    try ndata2(a,:)=data(i(a)-round(.05*fs):i(a)+round(.1*fs));end
end
ecg.proc.template2 = nanmean(ndata2);
disp('...realigned and generated template 2...')
%% run temporal correlation on second template
corrdata=[];
for a = 1:ns-size(ecg.proc.template2,2)-1
    corrdata(:,a) = data(1,a:a+size(ecg.proc.template2,2)-1)';
end
r2 = corr(corrdata,ecg.proc.template2').^2; 
ecg.proc.r2 = r2;
disp('...temporal correlation on second template done...')
%% readjust threshold
h=max(findpeaks(r2))-.05:-0.01:0.2;thr=[];
for a=1:length(h)
    [~,ix]=findpeaks(r2,'MinPeakHeight',h(a),'MaxPeakWidth',round(0.1*fs));
    if ~isempty(ix),dd=60./(diff(ix)/fs);thr2(a)=nansum(dd>55&dd<120)./std(dd);end
end
[~,ithr2]=max(thr2);ecg.proc.thresh2=h(ithr2);
%% find peaks based on second threshold
[pks,i]=findpeaks(r2,'MinPeakHeight',ecg.proc.thresh2,'MaxPeakWidth',round(0.1*fs));
disp('...final ECG artefact detection done...')
%% save info
ecg.stats.intervals = 60./(diff(i)./fs);
ecg.hr=60/(nanmedian(diff(i))/fs);
ecg.nandata = data;
ecg.cleandata=data;
cbins = zeros(size(data));
for a = 1:length(pks)
    tss=size(ecg.proc.template2,2);
    ic=i(a):i(a)+tss-1;
    mirrorrange=[i(a):-1:i(a)-round(tss/2)+2 i(a)+tss+round(tss/2)-1:i(a)+tss];
    try
        ecg.cleandata(ic)=data(mirrorrange);
    catch
        ecg.cleandata(ic)=0;
    end
    ecg.stats.n = numel(pks);
    cbins(ic)=1;
end
ecg.nandata(find(cbins))=nan;
ecg.ecgbins = cbins;
ecg.stats.pctartefact = nansum(cbins)/ns*100;
ecg.stats.msartefact = nansum(cbins)/fs;
ecg.stats.ecglength = length(ecg.proc.template1)/fs;
%% decide on detection
detstring = {'Unreliable or no ECG','Consistent ECG'};
if (ecg.hr<55 || ecg.hr>120) || ecg.stats.n <= 0.5*ns/fs || (ii2-ii1)/fs > 0.075 || pdif < 20
    disp('No reliable ECG detection possible.')
    ecg.detected = 0;
else
    ecg.detected = 1;
end
disp([detstring{ecg.detected+1} ' detected.'])
%% plot
if plotit
    t = linspace(0,ns/fs,ns);
    [~,f,rpow]=perceive_fft(data(~isnan(data)),fs,fs*2);
    [~,f,rnpow]=perceive_fft(ecg.cleandata(~isnan(ecg.cleandata)),fs,fs*2);
    nt2 = linspace(-.05,.1,size(ecg.proc.template2,2));
    
    figure
    
    subplot(2,2,1);
    plot(nt2,ndata2','linewidth',0.1,'color',[.9 .9 .9]);
    hold on
    plot(nt2,ecg.proc.template2,'color','k');
    xlabel('Time [s]');ylabel('Amplitude');xlim([-.02 .1]);
    title([detstring{ecg.detected+1} ' detected.'])
    
    subplot(2,2,2)
    plot(f,rpow,f,rnpow,'linewidth',2);
    xlim([4 30]);legend('original','cleaned'); xlabel('Frequency [Hz]')
    ylabel('Relative spectral power [%]');title([' HR: ' num2str(ecg.hr,3) '/min  N = ' num2str(ecg.stats.n,3)]);
    
    subplot(2,2,3:4);
    plot(t,data,'color','r');    hold on
    plot(t,ecg.cleandata,'color','k');
    legend('original','cleaned');ylabel('Amplitude');xlabel('Time [s]')
end